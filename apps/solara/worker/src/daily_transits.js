/**
 * Solara Daily Transits — Cyclo*Carto*Graphy at fixed location.
 *
 * F1 (2026-04-29): ユーザーの拠点 (自宅 / 職場 等) から見て、
 * 各トランジット惑星が 4 アングル (ASC/MC/DSC/IC) を通過する時刻を1日分計算する。
 *
 * 設計: project_solara_design_philosophy.md
 *   - 「動き出す時刻」を伝えるためのデータレイヤー。
 *   - 「ラッキータイム」「アンラッキータイム」とは言わない。
 *   - その時刻に在るエネルギーを事実として伝える。
 *
 * 数学:
 *   - MC 通過: planet's hour_angle = 0 (upper culmination)
 *   - IC 通過: planet's hour_angle = 12h (lower culmination)
 *   - ASC 通過: rising time (Astronomy.SearchRiseSet direction = +1)
 *   - DSC 通過: setting time (direction = -1)
 *
 * astronomy-engine API:
 *   - Astronomy.SearchHourAngle(body, observer, hourAngle, startTime, direction)
 *   - Astronomy.SearchRiseSet(body, observer, direction, startTime, limitDays)
 */
import * as Astronomy from 'astronomy-engine';

const BODY_KEYS = ['sun','moon','mercury','venus','mars','jupiter','saturn','uranus','neptune','pluto'];
const BODIES = [
  Astronomy.Body.Sun, Astronomy.Body.Moon, Astronomy.Body.Mercury,
  Astronomy.Body.Venus, Astronomy.Body.Mars, Astronomy.Body.Jupiter,
  Astronomy.Body.Saturn, Astronomy.Body.Uranus, Astronomy.Body.Neptune, Astronomy.Body.Pluto
];

// V2 (2026-04-29): イベント時刻のトランジット惑星 → ナタル惑星アスペクト
// Solara 設計思想 に従い soft / hard / neutral を独立に保持。
// V2.2 (2026-04-29): orb は client (Sanctuary 設定) から渡される。
// デフォルトはマイナーも含む完全セット。client から orbs を渡せば上書きされる。
const DEFAULT_ASPECTS = [
  { type: 'conjunction',  angle: 0,   orb: 4, quality: 'neutral' },
  { type: 'sextile',      angle: 60,  orb: 3, quality: 'soft' },
  { type: 'square',       angle: 90,  orb: 4, quality: 'hard' },
  { type: 'trine',        angle: 120, orb: 4, quality: 'soft' },
  { type: 'quincunx',     angle: 150, orb: 2, quality: 'tense' },
  { type: 'opposition',   angle: 180, orb: 4, quality: 'hard' },
  { type: 'semisextile',  angle: 30,  orb: 1, quality: 'tense' },
  { type: 'semisquare',   angle: 45,  orb: 1, quality: 'hard' },
];

/// client から orb 上書き map を受け取り、ASPECTS 配列を組み立てる。
/// orbsOverride: { conjunction: 2, square: 3, ... } の形式。
/// 未指定 type は DEFAULT_ASPECTS の値を使う。
/// orb=0 の type は除外（Sanctuary でゼロ設定されたら検出しない意図）。
function buildAspects(orbsOverride) {
  return DEFAULT_ASPECTS.map(a => {
    const orb = (orbsOverride && typeof orbsOverride[a.type] === 'number')
      ? orbsOverride[a.type]
      : a.orb;
    return { ...a, orb };
  }).filter(a => a.orb > 0);
}

function angDist360(a, b) {
  let d = ((a - b) % 360 + 360) % 360;
  if (d > 180) d = 360 - d;
  return d;
}

function eclipticLon(body, time) {
  if (body === Astronomy.Body.Moon) return Astronomy.EclipticGeoMoon(time).lon;
  if (body === Astronomy.Body.Sun) return Astronomy.SunPosition(time).elon;
  return Astronomy.Ecliptic(Astronomy.GeoVector(body, time, true)).elon;
}

/**
 * 1イベント時刻における transit body と natal 各惑星のアスペクトを検出する。
 * @param {object} body - astronomy-engine Body
 * @param {Astronomy.AstroTime} time - イベント時刻
 * @param {object} natal - 例: { sun: 12.5, moon: 89.3, ... } (黄経deg)
 * @param {Array} aspects - ASPECTS 配列（orbs 上書き済み）
 * @returns {Array<{natalPlanet, type, quality, orb}>}
 */
function detectAspects(body, time, natal, aspects) {
  const transitLon = eclipticLon(body, time);
  const results = [];
  for (const [planet, lon] of Object.entries(natal)) {
    if (typeof lon !== 'number') continue;
    const d = angDist360(transitLon, lon);
    let best = null;
    for (const a of aspects) {
      const delta = Math.abs(d - a.angle);
      if (delta <= a.orb && (best === null || delta < best._delta)) {
        best = { natalPlanet: planet, type: a.type, quality: a.quality,
                 orb: Math.round(delta * 100) / 100, _delta: delta };
      }
    }
    if (best) {
      delete best._delta;
      results.push(best);
    }
  }
  // タイト順にソート（orb小さい順）
  results.sort((a, b) => a.orb - b.orb);
  return results;
}

/**
 * 1日分のトランジット通過時刻を計算する。
 *
 * V2 (2026-04-29): natal を受け取った場合、各イベント時刻における
 * トランジット惑星 → ナタル惑星のアスペクトも併記する。
 * V2.1 (2026-04-29): startTimeIso を受けると正確な local-day 境界に対応。
 *
 * @param {object} params
 * @param {number} params.lat - 観測点の緯度
 * @param {number} params.lng - 観測点の経度
 * @param {string} [params.date] - 対象日 (ISO yyyy-mm-dd)。省略時は today UTC。
 * @param {string} [params.startTimeIso] - 厳密な走査開始時刻 (ISO 8601)。
 *     これが優先される。クライアントが「ユーザーの local 00:00 を UTC に変換」
 *     して渡すことで、JST 等のローカル日境界で正確に1日分を抽出できる。
 * @param {object} [params.natal] - 黄経マップ {sun, moon, ...} を渡すと
 *     各イベントに aspects 配列が追加される。
 * @returns {{ date: string, location: {lat, lng}, transits: Array<{planet, events: Array}> }}
 */
export function computeDailyTransits({ lat, lng, date, startTimeIso, natal, orbs }) {
  if (typeof lat !== 'number' || typeof lng !== 'number') {
    throw new Error('lat / lng required (numbers)');
  }
  // 対象開始時刻: startTimeIso > date > today UTC の優先順
  let targetDate;
  if (startTimeIso) {
    targetDate = new Date(startTimeIso);
    if (isNaN(targetDate.getTime())) {
      throw new Error('startTimeIso is not a valid ISO 8601 datetime');
    }
  } else if (date) {
    targetDate = new Date(date + 'T00:00:00Z');
  } else {
    targetDate = new Date();
  }

  // V2.2: client から orbs を受け取って ASPECTS を組み立てる。
  // 未指定なら DEFAULT_ASPECTS のまま。
  const aspectsTable = buildAspects(orbs);
  const startTime = new Astronomy.AstroTime(targetDate);
  const observer = new Astronomy.Observer(lat, lng, 0);
  const limitDays = 1.05; // 24h 少し余裕
  const hasNatal = natal && typeof natal === 'object';

  function buildEvent(angle, t, hor, body, time) {
    const ev = {
      angle,
      time: t.toISOString(),
      altitude: round2(hor.altitude),
      azimuth: round2(hor.azimuth),
    };
    if (hasNatal) {
      try { ev.aspects = detectAspects(body, time, natal, aspectsTable); }
      catch (_) { ev.aspects = []; }
    }
    return ev;
  }

  const transits = [];
  for (let i = 0; i < BODIES.length; i++) {
    const body = BODIES[i];
    const planetKey = BODY_KEYS[i];
    const events = [];

    // ── MC (upper culmination, hour angle = 0) ──
    try {
      const mcInfo = Astronomy.SearchHourAngle(body, observer, 0, startTime, +1);
      if (mcInfo && mcInfo.time) {
        const t = mcInfo.time.date;
        if (t.getTime() - targetDate.getTime() <= limitDays * 86400000) {
          events.push(buildEvent('MC', t, mcInfo.hor, body, mcInfo.time));
        }
      }
    } catch (_) { /* 計算失敗は無視、他のアングルだけ返す */ }

    // ── IC (lower culmination, hour angle = 12) ──
    try {
      const icInfo = Astronomy.SearchHourAngle(body, observer, 12, startTime, +1);
      if (icInfo && icInfo.time) {
        const t = icInfo.time.date;
        if (t.getTime() - targetDate.getTime() <= limitDays * 86400000) {
          events.push(buildEvent('IC', t, icInfo.hor, body, icInfo.time));
        }
      }
    } catch (_) { /* ignore */ }

    // ── ASC (rising) ──
    try {
      const ascTime = Astronomy.SearchRiseSet(body, observer, +1, startTime, limitDays);
      if (ascTime) {
        const hor = { altitude: 0, azimuth: getAzimuth(body, observer, ascTime) };
        events.push(buildEvent('ASC', ascTime.date, hor, body, ascTime));
      }
    } catch (_) { /* ignore (極夜・極昼で発生しない場合がある) */ }

    // ── DSC (setting) ──
    try {
      const dscTime = Astronomy.SearchRiseSet(body, observer, -1, startTime, limitDays);
      if (dscTime) {
        const hor = { altitude: 0, azimuth: getAzimuth(body, observer, dscTime) };
        events.push(buildEvent('DSC', dscTime.date, hor, body, dscTime));
      }
    } catch (_) { /* ignore */ }

    // 時刻順にソート（UI で時系列表示するため）
    events.sort((a, b) => new Date(a.time).getTime() - new Date(b.time).getTime());

    transits.push({ planet: planetKey, events });
  }

  return {
    date: targetDate.toISOString().slice(0, 10),
    location: { lat, lng },
    transits,
  };
}

function getAzimuth(body, observer, time) {
  const equ = Astronomy.Equator(body, time, observer, true, true);
  const hor = Astronomy.Horizon(time, observer, equ.ra, equ.dec, 'normal');
  return hor.azimuth;
}

function round2(v) {
  return Math.round(v * 100) / 100;
}
