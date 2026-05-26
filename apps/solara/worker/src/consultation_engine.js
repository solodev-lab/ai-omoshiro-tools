/**
 * Solara Stella 相談 — 計算パイプライン (秘伝)。Phase 1。
 *
 * 設計: memory project_solara_consultation_full_integration.md
 *
 * 役割: client から「誕生データ + 自宅座標 + 5問の答え + preset」だけ (約1KB) を
 * 受け取り、Worker 側で**全部**計算する (秘匿アーキ最終確定 2026-05-23)。
 *   1. 影響プール構築 (テーマ絞り ACG 線 + 天頂/天底帯, natal+transit+progressed,
 *      旅行は期間内 ≤3 日サンプリング)
 *   2. scope 別 候補プール (具体地点 / 方角 / 半径 / 地域 / 自国内 / 世界)
 *   3. 候補スコアリング (近接ファクター + signature 抽出)
 *   4. 多様性選択 (案C + 正直フォールバック, excluded で 1 枚ずつ前進)
 *   5. 候補別リロケハウス (astro.js Placidus 流用, 出生時刻不明は省略)
 *   6. 時間帯 (現地太陽時 = UTC + 経度/15 → 朝昼夜)
 *   7. 内的季節 (進行の月サイン+ハウス / 進行の太陽サイン, SA は節目フラグだけ)
 *   8. 出生時刻不明 degrade (軽い読み禁止: データが減るだけで品質は落とさない)
 *
 * 本モジュールは**語らない** (吉凶禁止・narrative なし)。構造化した素材を返し、
 * Phase 2 (Gemini プロンプト) が Stella の言葉にする。
 *
 * Solara 設計思想 ([[project_solara_design_philosophy]]):
 *   Soft (trine/sextile) と Hard (square) は独立 2 エネルギー。total/吉凶に潰さない。
 *   ファクターは quality (soft/hard/neutral) を保ったまま返す。
 */

import * as Astronomy from 'astronomy-engine';
import {
  buildAstroLinesAt,
  solarArcPlanets,
  haversineKm,
  minDistanceKmToLine,
  eclipticToEquatorial,
  gmstHoursFromUtc,
  astroLineFortunePlanets,
  ASPECT_QUALITY,
} from './astro_lines.js';
import {
  BODY_KEYS,
  calcAllPlanetsKeyed,
  calcAscendant,
  calcMC,
  calcHouses,
  calcProgressedDate,
  makeUTCDate,
  makeUTCDateFromTzName,
} from './astro.js';
import { worldCities, worldCityRegionGroups } from './world_cities.js';

// ── 定数・チューニング ──────────────────────────────────────

const VALID_THEMES = new Set(['love', 'money', 'work', 'communication', 'healing', 'newStart']);
const VALID_MODES = new Set(['migration', 'travel', 'daily']);

/** 線への近さの減衰オーブ (km)。0km で 1.0、LINE_ORB_KM で 0。Lewis 標準の「数百km圏」に整合。 */
const LINE_ORB_KM = 800;
/** 帯 (天頂/天底) の緯度オーブ (度)。daily_transits.js の ORB=5° と整合 (1°≒111km)。 */
const BAND_ORB_DEG = 5.0;

/** フレーム別の重み (natal を基準に動的フレームをやや弱める)。 */
const FRAME_WEIGHT = { natal: 1.0, transit: 0.85, progressed: 0.78, solarArc: 0.7 };
/** アスペクト別の重み。Soft/Hard は独立=同格 (trine と square を同値)。conjunction 最強、sextile は minor。 */
const ASPECT_WEIGHT = { conjunction: 1.0, trine: 0.72, square: 0.72, sextile: 0.55 };
/** 帯の重み (本線ヒットよりは柔らかいが、移住の地理差別化 backbone)。 */
const BAND_WEIGHT = 0.6;

/** これ未満を「テーマ線が遠い静かな場」(正直フォールバック) とみなす閾値。 */
const QUIET_THRESHOLD = 0.18;
/** full スコアリングにかける候補の上限 (粗ランク後)。CPU を読める範囲に保つ。 */
const FULL_SCORE_LIMIT = 48;
/** 1 候補が保持する近接ファクターの上限。 */
const MAX_FACTORS_PER_CANDIDATE = 8;

// ── 表示用 日本語ラベル (エビデンス文字列生成。narrative は Phase 2) ──

const PLANET_JP = {
  sun: '太陽', moon: '月', mercury: '水星', venus: '金星', mars: '火星',
  jupiter: '木星', saturn: '土星', uranus: '天王星', neptune: '海王星', pluto: '冥王星',
};
const ANGLE_LATIN = { mc: 'MC', ic: 'IC', asc: 'ASC', dsc: 'DSC' };
const ASPECT_JP = { conjunction: '合', trine: 'トライン', square: 'スクエア', sextile: 'セクスタイル' };
const SIGN_JP = ['牡羊', '牡牛', '双子', '蟹', '獅子', '乙女', '天秤', '蠍', '射手', '山羊', '水瓶', '魚'];
const HOUSE_THEME_JP = {
  1: '自己', 2: '所有・才能', 3: '対話', 4: '家庭・根', 5: '創造・恋愛', 6: '日常・健康',
  7: 'パートナー', 8: '共有・変容', 9: '探求・遠方', 10: '社会・キャリア', 11: '仲間', 12: '潜在・内省',
};

// ── 小ヘルパ ────────────────────────────────────────────────

function dateNoonUTC(yyyyMmDd) {
  return new Date(`${yyyyMmDd}T12:00:00Z`);
}

function obliquityForDate(utc) {
  const jd = utc.getTime() / 86400000 + 2440587.5;
  const T = (jd - 2451545.0) / 36525.0;
  return 23.4393 - 0.013 * T;
}

/** 黄経 lon がどのハウスに入るか (houses=12 cusp 黄経, 1..12 を返す)。 */
function houseOf(lon, houses) {
  const L = ((lon % 360) + 360) % 360;
  for (let i = 0; i < 12; i++) {
    const a = ((houses[i] % 360) + 360) % 360;
    const b = ((houses[(i + 1) % 12] % 360) + 360) % 360;
    let span = (b - a + 360) % 360;
    if (span === 0) span = 360;
    const off = (L - a + 360) % 360;
    if (off < span) return i + 1;
  }
  return 12;
}

/** 現地太陽時 (UTC時刻 + 経度/15) の時間帯バケット。時計表示はしない (設計: 現地の時間帯のみ)。 */
function timeOfDayBucket(localHour) {
  const h = ((localHour % 24) + 24) % 24;
  // 2026-05-25 オーナー指定の 5 帯 (明け方は廃止。5 帯で 24h を隙間なくカバー)。
  if (h >= 5 && h < 10) return 'morning';  // 朝 5-10
  if (h >= 10 && h < 15) return 'midday';  // 昼 10-15
  if (h >= 15 && h < 19) return 'evening'; // 夕方 15-19
  if (h >= 19 && h < 23) return 'night';   // 夜 19-23
  return 'lateNight';                      // 夜更け 23-5 (日をまたぐ)
}

const BUCKET_JP = {
  morning: '朝', midday: '昼', evening: '夕方', night: '夜', lateNight: '夜更け',
};

/** ある UTC 瞬間を、経度 lng の現地太陽時の時間帯バケットに変換。 */
function bucketFromUtcAt(utc, lng) {
  const utcHour = utc.getUTCHours() + utc.getUTCMinutes() / 60;
  return timeOfDayBucket(utcHour + lng / 15);
}

// ── 1. 影響プール ───────────────────────────────────────────

/**
 * テーマ惑星の declination から天頂/天底帯を作る (緯度効果、時刻非依存)。
 * @returns {Array<{planet, kind:'zenith'|'nadir', bandLat, frame}>}
 */
function buildBands(planetLons, themePlanets, frame) {
  const bands = [];
  for (const planet of themePlanets) {
    const lon = planetLons[planet];
    if (lon == null) continue;
    const { dec } = eclipticToEquatorial(lon);
    bands.push({ planet, kind: 'zenith', bandLat: dec, frame });
    bands.push({ planet, kind: 'nadir', bandLat: -dec, frame });
  }
  return bands;
}

/** when から transit を計算する代表 UTC 瞬間 (旅行 range は ≤3 日サンプリング)。 */
function transitInstants(mode, when) {
  if (mode === 'daily') {
    if (when && when.kind === 'date' && when.date) return [dateNoonUTC(when.date)];
    return [new Date()];
  }
  if (mode === 'travel') {
    if (when && when.kind === 'range' && when.start && when.end) {
      return sampleDays(when.start, when.end, 3);
    }
    if (when && when.date) return [dateNoonUTC(when.date)];
    return [new Date()];
  }
  return []; // migration: transit を使わない
}

/** [start,end] (yyyy-mm-dd) を最大 max 日に均等サンプリング (正午UTC)。 */
function sampleDays(start, end, max) {
  const s = dateNoonUTC(start).getTime();
  const e = dateNoonUTC(end).getTime();
  if (e <= s) return [new Date(s)];
  const totalDays = Math.round((e - s) / 86400000);
  if (totalDays + 1 <= max) {
    const out = [];
    for (let d = 0; d <= totalDays; d++) out.push(new Date(s + d * 86400000));
    return out;
  }
  // 端 + 等間隔で max 個
  const out = [];
  for (let i = 0; i < max; i++) {
    const frac = i / (max - 1);
    out.push(new Date(s + Math.round(frac * totalDays) * 86400000));
  }
  return out;
}

/** 移住の「いつ」(horizon) → 進行を進める未来日。 */
function migrationHorizonDate(when) {
  const now = new Date();
  const kind = (when && when.kind) || 'undecided';
  if (kind === 'date' && when.date) return dateNoonUTC(when.date);
  const years = { undecided: 0, within6mo: 0.5, within1yr: 1, in3yr: 3, in5yrPlus: 5 }[kind] ?? 0;
  return new Date(now.getTime() + years * 365.25 * 86400000);
}

/**
 * 影響プールを構築する。テーマ惑星に絞った ACG 線 + 天頂/天底帯を、
 * フレーム横断 (natal + transit/progressed) で集める。
 * 出生時刻不明 (timeUnknown) のとき natal ACG 線は経度を決められないので**省略**するが、
 * natal 帯 (緯度効果=declination ベース、時刻非依存) は残す = 地理差別化の backbone。
 */
function buildInfluencePool({ birthUTC, mode, when, theme, timeUnknown, natalLons }) {
  const themePlanets = astroLineFortunePlanets[theme] || astroLineFortunePlanets.all;
  const lines = [];
  const bands = [];

  // ── natal フレーム ──
  if (!timeUnknown) {
    const gmstN = gmstHoursFromUtc(birthUTC);
    lines.push(...buildAstroLinesAt({ planets: natalLons, gmstHours: gmstN, frame: 'natal', onlyPlanets: themePlanets }));
  }
  // natal 帯は時刻非依存 → 常に入れる (移住で時刻不明でも候補を差別化できる backbone)
  bands.push(...buildBands(natalLons, themePlanets, 'natal'));

  // ── transit フレーム (daily / travel) ──
  const instants = transitInstants(mode, when);
  for (const t of instants) {
    const tLons = calcAllPlanetsKeyed(t);
    const gmstT = gmstHoursFromUtc(t);
    lines.push(...buildAstroLinesAt({ planets: tLons, gmstHours: gmstT, frame: 'transit', onlyPlanets: themePlanets }));
    bands.push(...buildBands(tLons, themePlanets, 'transit'));
  }

  // ── progressed フレーム (migration) ──
  if (mode === 'migration') {
    const horizon = migrationHorizonDate(when);
    const progDate = calcProgressedDate(birthUTC, horizon);
    const progLons = calcAllPlanetsKeyed(progDate);
    if (!timeUnknown) {
      const gmstP = gmstHoursFromUtc(progDate);
      lines.push(...buildAstroLinesAt({ planets: progLons, gmstHours: gmstP, frame: 'progressed', onlyPlanets: themePlanets }));
    }
    bands.push(...buildBands(progLons, themePlanets, 'progressed'));
  }

  return { lines, bands, themePlanets };
}

// ── 2. 候補プール ───────────────────────────────────────────

/** home に最も近い都市の国コードを推定 (scope=自国内 用、client は home 座標しか送らない)。 */
function homeCountry(home) {
  if (!home || home.lat == null) return null;
  let best = null;
  let bestD = Infinity;
  for (const c of worldCities) {
    const d = haversineKm(home, { lat: c.lat, lng: c.lng });
    if (d < bestD) { bestD = d; best = c; }
  }
  return best ? best.country : null;
}

const BEARING_DEFS = [
  { code: 'N', deg: 0 }, { code: 'NE', deg: 45 }, { code: 'E', deg: 90 }, { code: 'SE', deg: 135 },
  { code: 'S', deg: 180 }, { code: 'SW', deg: 225 }, { code: 'W', deg: 270 }, { code: 'NW', deg: 315 },
];
const BEARING_JP = { N: '北', NE: '北東', E: '東', SE: '南東', S: '南', SW: '南西', W: '西', NW: '北西' };

/** 球面で origin から方位 bearingDeg に distanceKm 進んだ点 (consultation_engine.dart と同式)。 */
function offsetByBearing(origin, bearingDeg, distanceKm) {
  const R = 6371.0;
  const br = (bearingDeg * Math.PI) / 180;
  const lat1 = (origin.lat * Math.PI) / 180;
  const lng1 = (origin.lng * Math.PI) / 180;
  const d = distanceKm / R;
  const lat2 = Math.asin(Math.sin(lat1) * Math.cos(d) + Math.cos(lat1) * Math.sin(d) * Math.cos(br));
  const lng2 = lng1 + Math.atan2(Math.sin(br) * Math.sin(d) * Math.cos(lat1), Math.cos(d) - Math.sin(lat1) * Math.sin(lat2));
  return { lat: (lat2 * 180) / Math.PI, lng: (((lng2 * 180) / Math.PI + 540) % 360) - 180 };
}

function cityToCandidate(c) {
  return { name: c.nameJP, nameEN: c.nameEN, lat: c.lat, lng: c.lng, country: c.country, region: c.region, population: c.population };
}

/**
 * scope から候補地点プールを作る。
 * 'point'   → 指定地点 1 件 (具体地点 / タップ / 検索店舗)。
 * 'bearing' → home から 8 方角 × radiusKm の点 (daily)。
 * 'radius'  → home から radiusKm 以内の都市。
 * 'region'  → regionGroup (日本/北米/...) の都市。
 * 'country' → home の国の都市 (自国内)。
 * 'world'   → 全都市。
 */
function buildCandidatePool({ scope, home, mode }) {
  const kind = (scope && scope.kind) || (mode === 'daily' ? 'bearing' : 'world');

  if (kind === 'point' && scope.point) {
    const p = scope.point;
    return [{
      name: p.name || null, nameEN: p.name || null,
      lat: p.lat, lng: p.lng, country: null, region: null, population: 0,
      placeType: p.placeType || null, isPoint: true,
      placeKind: p.placeKind || null, // 'named'(検索) | 'saved'(登録地) | null
    }];
  }

  if (kind === 'bearing') {
    const radiusKm = (scope && scope.radiusKm) || 50;
    return BEARING_DEFS.map((b) => {
      const pt = offsetByBearing(home, b.deg, radiusKm);
      return { name: BEARING_JP[b.code], nameEN: b.code, lat: pt.lat, lng: pt.lng, country: null, region: null, population: 0, bearing: b.code };
    });
  }

  if (kind === 'radius') {
    const radiusKm = (scope && scope.radiusKm) || 300;
    return worldCities
      .filter((c) => haversineKm(home, { lat: c.lat, lng: c.lng }) <= radiusKm)
      .map(cityToCandidate);
  }

  if (kind === 'region' && scope.regionGroup) {
    return worldCities
      .filter((c) => worldCityRegionGroups[c.country] === scope.regionGroup)
      .map(cityToCandidate);
  }

  if (kind === 'country') {
    const cc = (scope && scope.country) || homeCountry(home);
    return worldCities.filter((c) => c.country === cc).map(cityToCandidate);
  }

  // world (既定)
  return worldCities.map(cityToCandidate);
}

// ── 3. 候補スコアリング ─────────────────────────────────────

/** 候補地点の近接ファクター (線 + 帯) を集めて strength 降順に。 */
function scoreCandidate(point, pool) {
  const factors = [];

  for (const line of pool.lines) {
    const dist = minDistanceKmToLine(point, line);
    const near = Math.max(0, 1 - dist / LINE_ORB_KM);
    if (near <= 0) continue;
    const strength = (FRAME_WEIGHT[line.frame] || 0.8) * (ASPECT_WEIGHT[line.aspect] || 0.6) * near;
    factors.push({
      kind: 'line', planet: line.planet, angle: line.angle, aspect: line.aspect,
      frame: line.frame, quality: ASPECT_QUALITY[line.aspect] || 'neutral',
      distanceKm: Math.round(dist), strength,
    });
  }

  for (const band of pool.bands) {
    const delta = Math.abs(point.lat - band.bandLat);
    const near = Math.max(0, 1 - delta / BAND_ORB_DEG);
    if (near <= 0) continue;
    const strength = (FRAME_WEIGHT[band.frame] || 0.8) * BAND_WEIGHT * near;
    factors.push({
      kind: 'band', planet: band.planet, angle: band.kind === 'zenith' ? 'mc' : 'ic',
      aspect: band.kind, frame: band.frame, quality: 'neutral',
      latDeltaDeg: Math.round(delta * 100) / 100, strength,
    });
  }

  // 同一 planet+angle+aspect+frame は最強の 1 本だけ残す (線の複数セグメント重複を防ぐ)
  const bestByKey = new Map();
  for (const f of factors) {
    const k = `${f.kind}_${f.planet}_${f.angle}_${f.aspect}_${f.frame}`;
    const prev = bestByKey.get(k);
    if (!prev || f.strength > prev.strength) bestByKey.set(k, f);
  }
  const uniq = [...bestByKey.values()].sort((a, b) => b.strength - a.strength);
  const trimmed = uniq.slice(0, MAX_FACTORS_PER_CANDIDATE);
  const topStrength = trimmed.length ? trimmed[0].strength : 0;

  return {
    ...point,
    factors: trimmed,
    topStrength,
    honestQuiet: topStrength < QUIET_THRESHOLD,
  };
}

/** 候補集合を粗ランク (最寄り conjunction 線 + 帯) で上位だけに絞ってから full スコア。 */
function scorePool(candidates, pool) {
  if (candidates.length <= FULL_SCORE_LIMIT) {
    return candidates.map((c) => scoreCandidate(c, pool)).sort(byRank);
  }
  // 粗ランク: テーマ conjunction 線への最短距離 (cheap)
  const conjLines = pool.lines.filter((l) => l.aspect === 'conjunction');
  const coarse = candidates.map((c) => {
    let best = Infinity;
    for (const l of conjLines) {
      const d = minDistanceKmToLine(c, l);
      if (d < best) best = d;
    }
    for (const b of pool.bands) {
      const d = Math.abs(c.lat - b.bandLat) * 111; // 度→km 概算
      if (d < best) best = d;
    }
    return { c, best };
  });
  coarse.sort((a, b) => a.best - b.best);
  const top = coarse.slice(0, FULL_SCORE_LIMIT).map((x) => x.c);
  return top.map((c) => scoreCandidate(c, pool)).sort(byRank);
}

function byRank(a, b) {
  if (b.topStrength !== a.topStrength) return b.topStrength - a.topStrength;
  // 同点は最寄り線距離 (factors[0]) が近い方を上位に
  const da = a.factors[0]?.distanceKm ?? Infinity;
  const db = b.factors[0]?.distanceKm ?? Infinity;
  return da - db;
}

// ── 4. 多様性選択 (案C + 正直フォールバック) ─────────────────

/** 候補の「signature 族」= planet + angle + quality (違う種類の招待を見分ける単位)。 */
function signatureFamily(candidate) {
  const f = candidate.factors[0];
  if (!f) return 'quiet';
  return `${f.planet}_${f.angle}_${f.quality}`;
}

/**
 * 多様性順に並べ替える (案C): 1 番手=最強。以降は「まだ出していない signature 族」を
 * 強い順に拾う。新しい族が無ければ素直に強さ順 (正直フォールバック=作られた多様性をしない)。
 */
function diversifyOrder(scored) {
  if (scored.length <= 1) return scored.slice();
  const remaining = scored.slice(); // すでに強さ順
  const out = [];
  const usedFamilies = new Set();

  while (remaining.length) {
    let pickIdx = 0; // 既定=残りの最強 (正直フォールバック)
    for (let i = 0; i < remaining.length; i++) {
      if (!usedFamilies.has(signatureFamily(remaining[i]))) { pickIdx = i; break; }
    }
    const picked = remaining.splice(pickIdx, 1)[0];
    usedFamilies.add(signatureFamily(picked));
    out.push(picked);
  }
  return out;
}

/**
 * excluded (既出候補名) を飛ばして次の 1 候補を返す。
 * 具体地点 (isPoint) は 1 件しかないので多様性は効かせず常にその地点を返す。
 */
function selectCandidate(scored, excluded) {
  if (!scored.length) return { candidate: null, ordered: [], remainingAfter: 0 };
  const exSet = new Set((excluded || []).map(String));
  const isExcluded = (c) => exSet.has(String(c.name)) || (c.nameEN && exSet.has(String(c.nameEN)));

  // 具体地点: 唯一の候補。既出でもその地点を返す (UI が「これ以上は無い」を判断)。
  if (scored.length === 1 && scored[0].isPoint) {
    return { candidate: scored[0], ordered: scored, remainingAfter: 0, single: true };
  }

  const ordered = diversifyOrder(scored);
  const fresh = ordered.filter((c) => !isExcluded(c));
  const candidate = fresh.length ? fresh[0] : null;
  return { candidate, ordered, remainingAfter: Math.max(0, fresh.length - 1) };
}

// ── 5. 候補別リロケハウス ───────────────────────────────────

/**
 * 候補地点でのリロケーションチャート (古典: natal 惑星は固定、ASC/MC/houses だけ再計算)。
 * 各テーマ惑星がどのハウスに入るかを返す = 「この土地で金星が 7 室」(秘伝)。
 * 出生時刻不明なら null (ハウスは時刻必須)。
 */
function relocationHousesAt(birthUTC, lat, lng, natalLons, themePlanets, timeUnknown) {
  if (timeUnknown) return null;
  const asc = calcAscendant(birthUTC, lat, lng);
  const mc = calcMC(birthUTC, lng);
  const obliquity = obliquityForDate(birthUTC);
  const houses = calcHouses(mc, asc, lat, obliquity, 'placidus');
  const planetHouses = {};
  for (const p of themePlanets) {
    const lon = natalLons[p];
    if (lon != null) planetHouses[p] = houseOf(lon, houses);
  }
  return { asc: Math.round(asc * 100) / 100, mc: Math.round(mc * 100) / 100, houses, planetHouses };
}

// ── 6. 時間帯 (現地太陽時の角通過) ──────────────────────────

const BODY_BY_KEY = {};
for (let i = 0; i < BODY_KEYS.length; i++) {
  BODY_BY_KEY[BODY_KEYS[i]] = [
    Astronomy.Body.Sun, Astronomy.Body.Moon, Astronomy.Body.Mercury, Astronomy.Body.Venus,
    Astronomy.Body.Mars, Astronomy.Body.Jupiter, Astronomy.Body.Saturn, Astronomy.Body.Uranus,
    Astronomy.Body.Neptune, Astronomy.Body.Pluto,
  ][i];
}

/** 指定日に planet が candidate 地点で angle を通過する UTC 時刻 (無ければ null)。 */
function angleCrossingUtc(planetKey, lat, lng, dayUTC, angle) {
  const body = BODY_BY_KEY[planetKey];
  if (!body) return null;
  const observer = new Astronomy.Observer(lat, lng, 0);
  const start = new Astronomy.AstroTime(dayUTC);
  try {
    if (angle === 'mc') return Astronomy.SearchHourAngle(body, observer, 0, start, +1)?.time?.date ?? null;
    if (angle === 'ic') return Astronomy.SearchHourAngle(body, observer, 12, start, +1)?.time?.date ?? null;
    if (angle === 'asc') return Astronomy.SearchRiseSet(body, observer, +1, start, 1.05)?.date ?? null;
    if (angle === 'dsc') return Astronomy.SearchRiseSet(body, observer, -1, start, 1.05)?.date ?? null;
  } catch (_) { /* 極夜等で発生しない場合がある */ }
  return null;
}

/**
 * 選ばれた候補の時間帯を計算する (設計: 時計+TZ無し・現地の時間帯のみ)。
 *   daily   → その地点の transit テーマ惑星が角を通過する時間帯 1 つ。
 *   travel  → 朝/昼/夜のリズム (角通過を時間帯で散らす、最大 3)。
 *   migration → null (永続なので時刻無関係)。
 */
function timeWindowFor({ mode, when, candidate }) {
  if (mode === 'migration') return null;
  const instants = transitInstants(mode, when);
  if (!instants.length) return null;

  // candidate の transit ファクター (planet+angle) を強い順に
  const transitFactors = candidate.factors.filter((f) => f.frame === 'transit' && f.kind === 'line');

  if (mode === 'daily') {
    const day = instants[0];
    const f = transitFactors[0];
    if (f) {
      const t = angleCrossingUtc(f.planet, candidate.lat, candidate.lng, day, f.angle);
      if (t) return { kind: 'single', bucket: bucketFromUtcAt(t, candidate.lng), planet: f.planet, angle: f.angle };
    }
    // ファクターが無ければ現在の現地時間帯だけ返す
    return { kind: 'single', bucket: bucketFromUtcAt(day, candidate.lng), planet: null, angle: null };
  }

  // travel: 角通過を時間帯で散らす
  const day = instants[0];
  const seen = new Set();
  const rhythm = [];
  for (const f of transitFactors) {
    const t = angleCrossingUtc(f.planet, candidate.lat, candidate.lng, day, f.angle);
    if (!t) continue;
    const bucket = bucketFromUtcAt(t, candidate.lng);
    if (seen.has(bucket)) continue;
    seen.add(bucket);
    rhythm.push({ bucket, planet: f.planet, angle: f.angle });
    if (rhythm.length >= 3) break;
  }
  return rhythm.length ? { kind: 'rhythm', items: rhythm } : null;
}

// ── 7. 内的季節 (進行) ──────────────────────────────────────

/**
 * 内的季節 (案A): 進行の月 (サイン+ハウス) を中心に、進行の太陽サイン、SA 節目フラグ。
 * ハウスは natal (出生地) チャートで読む = 場所に依らない「今のあなた」の状態。
 * 出生時刻不明ならハウスは省略 (サインは出る)。narrative は Phase 2。
 */
function innerSeason({ birthUTC, birthLat, birthLng, natalLons, mode, when, timeUnknown }) {
  // 内的季節を「いつの自分」で読むか: 移住の未来ホライズンならその頃、それ以外は今。
  const asOf = mode === 'migration' ? migrationHorizonDate(when) : new Date();
  const progDate = calcProgressedDate(birthUTC, asOf);
  const progLons = calcAllPlanetsKeyed(progDate);

  const moonLon = progLons.moon;
  const sunLon = progLons.sun;
  const progMoonSign = Math.floor((((moonLon % 360) + 360) % 360) / 30);
  const progSunSign = Math.floor((((sunLon % 360) + 360) % 360) / 30);

  let progMoonHouse = null;
  if (!timeUnknown) {
    const asc = calcAscendant(birthUTC, birthLat, birthLng);
    const mc = calcMC(birthUTC, birthLng);
    const houses = calcHouses(mc, asc, birthLat, obliquityForDate(birthUTC), 'placidus');
    progMoonHouse = houseOf(moonLon, houses);
  }

  // ソーラーアーク: SA 惑星が natal 惑星にタイト (≤1°) に当たったら「節目」フラグ
  const sa = solarArcPlanets({ natal: natalLons, progressed: progLons });
  let turningPoint = null;
  for (const sp of BODY_KEYS) {
    const saLon = sa[sp];
    if (saLon == null) continue;
    for (const np of BODY_KEYS) {
      if (np === sp) continue;
      const nLon = natalLons[np];
      if (nLon == null) continue;
      const d = Math.abs((((saLon - nLon) % 360) + 360) % 360);
      const sep = Math.min(d, 360 - d);
      if (sep <= 1.0) { turningPoint = { saPlanet: sp, natalPlanet: np, orb: Math.round(sep * 100) / 100 }; break; }
    }
    if (turningPoint) break;
  }

  return {
    asOfDate: progDate.toISOString().slice(0, 10),
    progMoonSign, progMoonSignJP: SIGN_JP[progMoonSign],
    progMoonHouse,
    progSunSign, progSunSignJP: SIGN_JP[progSunSign],
    turningPoint,
  };
}

// ── 8. エビデンス組み立て ───────────────────────────────────

/** ファクター 1 つを占星術ファクター文字列に (重み・選び方は出さない)。 */
function factorLabel(f) {
  const planet = PLANET_JP[f.planet] || f.planet;
  const framePrefix = f.frame === 'transit' ? '経過の' : f.frame === 'progressed' ? '進行の' : '';
  if (f.kind === 'band') {
    const bandJP = f.aspect === 'zenith' ? '天頂帯' : '天底帯';
    return `${framePrefix}${planet}${bandJP}`;
  }
  const angle = ANGLE_LATIN[f.angle] || f.angle;
  const asp = ASPECT_JP[f.aspect] || f.aspect;
  return `${framePrefix}${planet}${angle}${asp}`;
}

function buildEvidence({ candidate, relocation, innerSeasonData, timeUnknown, mode }) {
  const factors = [];
  const km = [];
  for (const f of candidate.factors) {
    factors.push(factorLabel(f));
    if (f.kind === 'line' && f.distanceKm != null) km.push({ factor: factorLabel(f), km: f.distanceKm });
  }
  // 候補別リロケハウス (秘伝: テーマ惑星の入る室)
  if (relocation && relocation.planetHouses) {
    for (const [p, h] of Object.entries(relocation.planetHouses)) {
      factors.push(`${PLANET_JP[p] || p}が${h}室 (${HOUSE_THEME_JP[h] || ''})`);
    }
  }
  // 内的季節
  if (innerSeasonData) {
    const houseStr = innerSeasonData.progMoonHouse ? `${innerSeasonData.progMoonHouse}室` : '';
    factors.push(`進行の月: ${innerSeasonData.progMoonSignJP}座${houseStr}`);
  }
  let note = null;
  if (timeUnknown) {
    note = mode === 'migration'
      ? '出生時刻不明のため、ハウス・角・リロケハウスは使用しておりません。出生時刻を入れると室まで読めます。'
      : null; // おでかけ・旅行は時刻不明でもフル品質 → 注記なし (設計 B)
  }
  return { factors, km, note };
}

// ── 9. オーケストレータ ─────────────────────────────────────

/**
 * 相談リクエスト → 構造化した候補素材 (Phase 2 が narrative にする)。
 * @param {object} request 設計の最小入力 (約1KB)
 * @returns {object} { candidate, evidence, innerSeason, timeWindow, isFirst, fallbackHonest, meta }
 */
export function runConsultationPipeline(request) {
  const {
    birth, home, theme, mode,
    when = null, scope = null,
    isFirst = true, excluded = [],
  } = request || {};

  if (!VALID_THEMES.has(theme)) throw new Error(`Invalid theme: ${theme}`);
  if (!VALID_MODES.has(mode)) throw new Error(`Invalid mode: ${mode}`);
  if (!birth || birth.date == null) throw new Error('birth.date required');

  const timeUnknown = !!birth.timeUnknown || birth.time == null || birth.time === '';
  // 時刻不明は正午仮定でごまかさない (設計 B): 計算上は 12:00 を置くが timeUnknown フラグで
  // ハウス/角を一切使わない。サイン・帯・遅い惑星アスペクトのみで読む。
  const birthTime = timeUnknown ? '12:00' : birth.time;
  const birthUTC = birth.tzName
    ? makeUTCDateFromTzName(birth.date, birthTime, birth.tzName)
    : makeUTCDate(birth.date, birthTime, birth.tz ?? 9);

  const natalLons = calcAllPlanetsKeyed(birthUTC);

  // 1. 影響プール
  const pool = buildInfluencePool({ birthUTC, mode, when, theme, timeUnknown, natalLons });

  // 2-3. 候補プール → スコア
  const rawCandidates = buildCandidatePool({ scope, home, mode });
  const scored = scorePool(rawCandidates, pool);

  // 4. 多様性選択 (excluded で前進)
  const { candidate, remainingAfter, single } = selectCandidate(scored, excluded);
  if (!candidate) {
    return {
      candidate: null, exhausted: true, remainingAfter: 0,
      meta: { mode, theme, timeUnknown, poolLines: pool.lines.length, poolBands: pool.bands.length },
    };
  }

  // 5. 候補別リロケハウス
  const relocation = relocationHousesAt(birthUTC, candidate.lat, candidate.lng, natalLons, pool.themePlanets, timeUnknown);

  // 6. 時間帯
  const timeWindow = timeWindowFor({ mode, when, candidate });

  // 7. 内的季節
  const innerSeasonData = innerSeason({
    birthUTC, birthLat: birth.lat, birthLng: birth.lng, natalLons, mode, when, timeUnknown,
  });

  // 8. エビデンス
  const evidence = buildEvidence({ candidate, relocation, innerSeasonData, timeUnknown, mode });

  return {
    isFirst: !!isFirst,
    candidate: {
      name: candidate.name, nameEN: candidate.nameEN,
      lat: candidate.lat, lng: candidate.lng,
      country: candidate.country, region: candidate.region,
      bearing: candidate.bearing || null, placeType: candidate.placeType || null,
      // 'named' (検索) / 'saved' (登録地) / null。consultation_v2.placeReference の
      // 分岐キー。buildCandidatePool で候補に乗せた placeKind を最終出力に保持する
      // (列挙忘れで消えると、検索の店名が「都市名で呼んでよい」分岐に落ちる)。
      placeKind: candidate.placeKind || null,
      factors: candidate.factors,
      topStrength: Math.round(candidate.topStrength * 1000) / 1000,
      honestQuiet: candidate.honestQuiet,
      relocation,
    },
    evidence,
    innerSeason: innerSeasonData,
    timeWindow,
    fallbackHonest: candidate.honestQuiet,
    remainingAfter,
    single: !!single,
    meta: {
      mode, theme, timeUnknown,
      poolLines: pool.lines.length, poolBands: pool.bands.length,
      candidatesScored: scored.length,
    },
  };
}

// テスト用に内部関数を公開
export const _internal = {
  dateNoonUTC, houseOf, timeOfDayBucket, bucketFromUtcAt, BUCKET_JP,
  buildBands, transitInstants, sampleDays, migrationHorizonDate,
  buildInfluencePool, buildCandidatePool, homeCountry, offsetByBearing,
  scoreCandidate, scorePool, signatureFamily, diversifyOrder, selectCandidate,
  relocationHousesAt, timeWindowFor, innerSeason, factorLabel, buildEvidence,
  PLANET_JP, SIGN_JP,
};
