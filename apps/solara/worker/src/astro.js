/**
 * Solara Astro Engine — Cloudflare Worker
 * Ported from: horoscope.html + shared/astro-math.js
 * Dependency: astronomy-engine (npm)
 */
import * as Astronomy from 'astronomy-engine';

// ── Math Helpers ──
const toRad = d => d * Math.PI / 180;
const toDeg = r => r * 180 / Math.PI;
function norm360(d) { d = d % 360; return d < 0 ? d + 360 : d; }
function angDist(a, b) { const d = Math.abs(norm360(a) - norm360(b)); return d > 180 ? 360 - d : d; }

// ── Bodies ──
const BODY_KEYS = ['sun','moon','mercury','venus','mars','jupiter','saturn','uranus','neptune','pluto'];
const BODIES = [
  Astronomy.Body.Sun, Astronomy.Body.Moon, Astronomy.Body.Mercury,
  Astronomy.Body.Venus, Astronomy.Body.Mars, Astronomy.Body.Jupiter,
  Astronomy.Body.Saturn, Astronomy.Body.Uranus, Astronomy.Body.Neptune, Astronomy.Body.Pluto
];

const IDX_PERSONAL = [0, 1, 2, 3, 4];
const IDX_SOCIAL = [5, 6];

// ── Default Aspect Types ──
const DEFAULT_ASPECTS = [
  { key: 'conjunction',   angle: 0,   orb: 2, quality: 'neutral' },
  { key: 'opposition',    angle: 180, orb: 2, quality: 'hard' },
  { key: 'trine',         angle: 120, orb: 2, quality: 'soft' },
  { key: 'square',        angle: 90,  orb: 2, quality: 'hard' },
  { key: 'sextile',       angle: 60,  orb: 2, quality: 'soft' },
  { key: 'quincunx',      angle: 150, orb: 2, quality: 'neutral' },
  { key: 'semisextile',   angle: 30,  orb: 1, quality: 'soft',  minor: true },
  { key: 'semisquare',    angle: 45,  orb: 1, quality: 'hard',  minor: true },
];

const DEFAULT_PATTERN_ORBS = {
  grandtrine: 3, tsquare_opp: 3, tsquare_sq: 2.5,
  yod_sextile: 2.5, yod_quincunx: 1.5
};

// ── Planet Calculations ──
function eclLon(body, date) {
  if (body === Astronomy.Body.Moon) return Astronomy.EclipticGeoMoon(date).lon;
  if (body === Astronomy.Body.Sun) return Astronomy.SunPosition(date).elon;
  return Astronomy.Ecliptic(Astronomy.GeoVector(body, date, true)).elon;
}

function calcAllPlanets(date) {
  const result = {};
  for (let i = 0; i < BODIES.length; i++) {
    result[i] = eclLon(BODIES[i], date);
  }
  return result;
}

function calcAllPlanetsKeyed(date) {
  const result = {};
  for (let i = 0; i < BODIES.length; i++) {
    result[BODY_KEYS[i]] = Math.round(eclLon(BODIES[i], date) * 100) / 100;
  }
  return result;
}

// ── ASC / MC ──
function calcAscendant(date, lat, lng) {
  const g = Astronomy.SiderealTime(date);
  const lst = norm360(g * 15 + lng);
  const lstR = lst * Math.PI / 180;
  const jd = (date.getTime() / 86400000) + 2440587.5;
  const T = (jd - 2451545) / 36525;
  const eps = (23.4393 - 0.013 * T) * Math.PI / 180;
  const latR = lat * Math.PI / 180;
  return norm360(Math.atan2(
    -Math.cos(lstR),
    Math.sin(eps) * Math.tan(latR) + Math.cos(eps) * Math.sin(lstR)
  ) * 180 / Math.PI + 180);
}

function calcMC(date, lng) {
  const g = Astronomy.SiderealTime(date);
  const lst = norm360(g * 15 + lng);
  const lstR = lst * Math.PI / 180;
  const jd = (date.getTime() / 86400000) + 2440587.5;
  const T = (jd - 2451545) / 36525;
  const eps = (23.4393 - 0.013 * T) * Math.PI / 180;
  return norm360(Math.atan2(
    Math.sin(lstR),
    Math.cos(lstR) * Math.cos(eps)
  ) * 180 / Math.PI);
}

// ── House Systems ──
function calcHousesPlacidus(mc, asc, lat, obliquity) {
  const epsR = toRad(obliquity);
  const cosEps = Math.cos(epsR), sinEps = Math.sin(epsR);
  const tanLat = Math.tan(toRad(lat));
  const houses = new Array(12);
  houses[0] = asc;
  houses[9] = mc;
  houses[6] = norm360(asc + 180);
  houses[3] = norm360(mc + 180);

  const mcR = toRad(mc);
  const ramc = norm360(toDeg(Math.atan2(Math.sin(mcR) * cosEps, Math.cos(mcR))));

  function placidusCusp(house) {
    let lon = (house <= 12) ? norm360(mc + (house - 10) * 30) : norm360(asc + (house - 1) * 30);
    for (let iter = 0; iter < 50; iter++) {
      let sinDecl = Math.sin(toRad(lon)) * sinEps;
      sinDecl = Math.max(-1, Math.min(1, sinDecl));
      const decl = Math.asin(sinDecl);
      const adArg = Math.max(-1, Math.min(1, tanLat * Math.tan(decl)));
      const AD = toDeg(Math.asin(adArg));
      let targetRA;
      if (house === 11) targetRA = ramc + (90 + AD) / 3;
      else if (house === 12) targetRA = ramc + 2 * (90 + AD) / 3;
      else if (house === 2) targetRA = ramc - 240 + 2 * AD / 3;
      else targetRA = ramc - 210 + AD / 3;
      const raR = toRad(targetRA);
      const newLon = norm360(toDeg(Math.atan2(Math.sin(raR), Math.cos(raR) * cosEps)));
      if (Math.abs(newLon - lon) < 0.001 || Math.abs(newLon - lon) > 359.999) break;
      lon = newLon;
    }
    return lon;
  }

  houses[10] = placidusCusp(11);
  houses[11] = placidusCusp(12);
  houses[1] = placidusCusp(2);
  houses[2] = placidusCusp(3);
  houses[4] = norm360(houses[10] + 180);
  houses[5] = norm360(houses[11] + 180);
  houses[7] = norm360(houses[1] + 180);
  houses[8] = norm360(houses[2] + 180);
  return houses;
}

function calcHousesWholeSigns(asc) {
  const signStart = Math.floor(asc / 30) * 30;
  return Array.from({ length: 12 }, (_, i) => norm360(signStart + i * 30));
}

function calcHousesEqual(asc) {
  return Array.from({ length: 12 }, (_, i) => norm360(asc + i * 30));
}

function calcHouses(mc, asc, lat, obliquity, system) {
  if (system === 'whole_sign') return calcHousesWholeSigns(asc);
  if (Math.abs(lat) > 66) return calcHousesEqual(asc);
  return calcHousesPlacidus(mc, asc, lat, obliquity);
}

// ── Progressed Date ──
function calcProgressedDate(birthDate, currentDate) {
  const msPerDay = 86400000;
  const daysLived = (currentDate.getTime() - birthDate.getTime()) / msPerDay;
  return new Date(birthDate.getTime() + (daysLived / 365.25) * msPerDay);
}

// ── Aspect Detection ──
function collectAspects(p1, p2, isCross, label, orbs) {
  const aspects = buildAspectTypes(orbs);
  const found = [];
  for (let i = 0; i < 10; i++) {
    const jStart = isCross ? 0 : i + 1;
    for (let j = jStart; j < 10; j++) {
      const diff = angDist(p1[i], p2[j]);
      for (const asp of aspects) {
        if (Math.abs(diff - asp.angle) <= asp.orb) {
          found.push({
            p1: i, p1key: BODY_KEYS[i],
            p2: j, p2key: BODY_KEYS[j],
            type: asp.key, quality: asp.quality,
            angle: asp.angle, diff: Math.round(diff * 100) / 100,
            label,
            minor: asp.minor || false
          });
        }
      }
    }
  }
  return found;
}

function buildAspectTypes(orbs) {
  if (!orbs) return DEFAULT_ASPECTS;
  return DEFAULT_ASPECTS.map(a => ({
    ...a,
    orb: orbs[a.key] !== undefined ? orbs[a.key] : a.orb
  }));
}

// ── Pattern Detection ──
function detectPatterns(natal, secondary, mode, patternOrbs) {
  const po = { ...DEFAULT_PATTERN_ORBS, ...patternOrbs };
  const patterns = { grandtrine: [], tsquare: [], yod: [] };
  const pool = [];
  for (let i = 0; i < 10; i++) pool.push({ lon: natal[i], source: 'N', idx: i });
  if (secondary) {
    const src = mode === 'transit' ? 'T' : 'P';
    for (let i = 0; i < 10; i++) pool.push({ lon: secondary[i], source: src, idx: i });
  }

  const countNatal = arr => arr.filter(p => p.source === 'N').length;
  const hasPersonal = arr => arr.some(p => IDX_PERSONAL.includes(p.idx));
  function isDuplicate(list, trio) {
    const key = trio.map(p => p.source + p.idx).sort().join(',');
    return list.some(e => e.planets.map(p => p.source + p.idx).sort().join(',') === key);
  }

  const len = pool.length;

  // Grand Trine: 120deg x3
  for (let i = 0; i < len; i++) {
    for (let j = i + 1; j < len; j++) {
      if (Math.abs(angDist(pool[i].lon, pool[j].lon) - 120) > po.grandtrine) continue;
      for (let k = j + 1; k < len; k++) {
        if (Math.abs(angDist(pool[i].lon, pool[k].lon) - 120) > po.grandtrine) continue;
        if (Math.abs(angDist(pool[j].lon, pool[k].lon) - 120) > po.grandtrine) continue;
        const trio = [pool[i], pool[j], pool[k]];
        if (countNatal(trio) < 2 || !hasPersonal(trio) || isDuplicate(patterns.grandtrine, trio)) continue;
        patterns.grandtrine.push({ planets: trio.map(formatPoolEntry) });
      }
    }
  }

  // T-Square: 180deg + 2x90deg
  for (let i = 0; i < len; i++) {
    for (let j = i + 1; j < len; j++) {
      if (Math.abs(angDist(pool[i].lon, pool[j].lon) - 180) > po.tsquare_opp) continue;
      for (let k = 0; k < len; k++) {
        if (k === i || k === j) continue;
        if (Math.abs(angDist(pool[i].lon, pool[k].lon) - 90) > po.tsquare_sq) continue;
        if (Math.abs(angDist(pool[j].lon, pool[k].lon) - 90) > po.tsquare_sq) continue;
        const trio = [pool[i], pool[j], pool[k]];
        if (countNatal(trio) < 2 || !hasPersonal(trio) || isDuplicate(patterns.tsquare, trio)) continue;
        patterns.tsquare.push({ planets: trio.map(formatPoolEntry), apex: formatPoolEntry(pool[k]) });
      }
    }
  }

  // Yod: 60deg + 2x150deg
  for (let i = 0; i < len; i++) {
    for (let j = i + 1; j < len; j++) {
      if (Math.abs(angDist(pool[i].lon, pool[j].lon) - 60) > po.yod_sextile) continue;
      for (let k = 0; k < len; k++) {
        if (k === i || k === j) continue;
        if (Math.abs(angDist(pool[i].lon, pool[k].lon) - 150) > po.yod_quincunx) continue;
        if (Math.abs(angDist(pool[j].lon, pool[k].lon) - 150) > po.yod_quincunx) continue;
        const trio = [pool[i], pool[j], pool[k]];
        if (countNatal(trio) < 2 || !hasPersonal(trio) || isDuplicate(patterns.yod, trio)) continue;
        patterns.yod.push({ planets: trio.map(formatPoolEntry), apex: formatPoolEntry(pool[k]) });
      }
    }
  }

  return patterns;
}

function formatPoolEntry(p) {
  return { key: BODY_KEYS[p.idx], source: p.source, lon: Math.round(p.lon * 100) / 100 };
}

// ── 60-Day Prediction ──
function predictPatternCompletions(natal, daysAhead) {
  daysAhead = daysAhead || 60;
  const predictions = [];
  const now = new Date();

  function scanTransit(targetDeg, patternType, ni, nj) {
    for (let body = 0; body < 10; body++) {
      let prevLon = null;
      for (let day = 0; day <= daysAhead; day++) {
        const checkDate = new Date(now.getTime() + day * 86400000);
        const lon = eclLon(BODIES[body], checkDate);
        const dist = angDist(lon, targetDeg);
        if (prevLon !== null) {
          const prevDist = angDist(prevLon, targetDeg);
          if (dist <= 3 && prevDist > dist) {
            let hoursFromNow = (day - 1) * 24 + (prevDist / (prevDist + dist)) * 24;
            if (hoursFromNow < 0) hoursFromNow = 0;
            predictions.push({
              type: patternType,
              natalPair: [BODY_KEYS[ni], BODY_KEYS[nj]],
              completeDegree: Math.round(targetDeg * 100) / 100,
              transitBody: BODY_KEYS[body],
              dateEstimate: new Date(now.getTime() + hoursFromNow * 3600000).toISOString(),
              hoursUntil: Math.round(hoursFromNow * 10) / 10
            });
            break;
          }
        }
        prevLon = lon;
      }
    }
  }

  for (let i = 0; i < 10; i++) {
    for (let j = i + 1; j < 10; j++) {
      if (!IDX_PERSONAL.includes(i) && !IDX_PERSONAL.includes(j)) continue;
      const dij = angDist(natal[i], natal[j]);

      if (Math.abs(dij - 120) <= 3) {
        const t1 = norm360(natal[i] + 120);
        const t2 = norm360(natal[i] - 120);
        if (Math.abs(angDist(t1, natal[j]) - 120) <= 5) scanTransit(t1, 'grandtrine', i, j);
        if (Math.abs(angDist(t2, natal[j]) - 120) <= 5) scanTransit(t2, 'grandtrine', i, j);
      }
      if (Math.abs(dij - 180) <= 3) {
        const mid = norm360((natal[i] + natal[j]) / 2);
        scanTransit(norm360(mid), 'tsquare', i, j);
        scanTransit(norm360(mid + 180), 'tsquare', i, j);
      }
      if (Math.abs(dij - 60) <= 2.5) {
        const t1 = norm360(natal[i] + 150);
        const t2 = norm360(natal[i] - 150);
        if (Math.abs(angDist(t1, natal[j]) - 150) <= 2.5) scanTransit(t1, 'yod', i, j);
        if (Math.abs(angDist(t2, natal[j]) - 150) <= 2.5) scanTransit(t2, 'yod', i, j);
      }
    }
  }

  predictions.sort((a, b) => a.hoursUntil - b.hoursUntil);
  return predictions;
}

// ── Date Helper ──
// 固定offset版 (レガシー互換)
function makeUTCDate(dateStr, timeStr, tzHours) {
  const [y, m, d] = dateStr.split('-').map(Number);
  const [h, min] = timeStr.split(':').map(Number);
  return new Date(Date.UTC(y, m - 1, d, h - tzHours, min, 0, 0));
}

// IANA TZ名版 (DST考慮、Intl ベース)
// "2025-07-10 15:00" + "America/Los_Angeles" → その瞬間の実UTC Date を返す
// 夏は PDT (UTC-7)、冬は PST (UTC-8) を IANA DB から自動判定
function makeUTCDateFromTzName(dateStr, timeStr, tzName) {
  const [y, m, d] = dateStr.split('-').map(Number);
  const [h, min] = timeStr.split(':').map(Number);
  // 1) 指定された local wall-clock 時刻をまず UTC として解釈
  const asIfUtc = Date.UTC(y, m - 1, d, h, min, 0, 0);
  // 2) その Date を tzName で formatToParts すると、tz での wall-clock が得られる
  //    両者の差分が 「その瞬間の tz オフセット (ms)」
  const offsetMs = getTzOffsetMs(new Date(asIfUtc), tzName);
  // 3) wall-clock 時刻から offset を引いて UTC 瞬間を確定
  return new Date(asIfUtc - offsetMs);
}

// 任意 Date (UTC瞬間) に対する、tzName での offset (ms) を Intl 経由で取得
function getTzOffsetMs(date, tzName) {
  try {
    const dtf = new Intl.DateTimeFormat('en-US', {
      timeZone: tzName,
      year: 'numeric', month: '2-digit', day: '2-digit',
      hour: '2-digit', minute: '2-digit', second: '2-digit',
      hour12: false,
    });
    const parts = dtf.formatToParts(date);
    const v = {};
    for (const p of parts) v[p.type] = p.value;
    const asIfUtc = Date.UTC(
      parseInt(v.year), parseInt(v.month) - 1, parseInt(v.day),
      parseInt(v.hour) % 24, parseInt(v.minute), parseInt(v.second)
    );
    return asIfUtc - date.getTime();
  } catch (_) {
    return 0; // 不正tzName → UTC扱い
  }
}

// ── Public API: /astro/chart ──
export function computeChart(params) {
  const {
    birthDate, birthTime, birthTz = 9, birthTzName,
    birthLat, birthLng,
    transitDate, mode = 'natal',
    houseSystem = 'placidus',
    orbs, patternOrbs
  } = params;

  // birthTzName (IANA) があれば優先、無ければ固定offset birthTz にfallback
  const birth = birthTzName
      ? makeUTCDateFromTzName(birthDate, birthTime, birthTzName)
      : makeUTCDate(birthDate, birthTime, birthTz);
  const natal = calcAllPlanets(birth);
  const natalKeyed = calcAllPlanetsKeyed(birth);

  const asc = Math.round(calcAscendant(birth, birthLat, birthLng) * 100) / 100;
  const mc = Math.round(calcMC(birth, birthLng) * 100) / 100;

  const jd = (birth.getTime() / 86400000) + 2440587.5;
  const T = (jd - 2451545.0) / 36525.0;
  const obliquity = 23.4393 - 0.013 * T;
  const houses = calcHouses(mc, asc, birthLat, obliquity, houseSystem)
    .map(h => Math.round(h * 100) / 100);

  let secondary = null;
  let secondaryKeyed = null;
  if (mode !== 'natal' && transitDate) {
    const tDate = new Date(transitDate);
    if (mode === 'transit') {
      secondary = calcAllPlanets(tDate);
      secondaryKeyed = calcAllPlanetsKeyed(tDate);
    } else if (mode === 'progressed') {
      const pDate = calcProgressedDate(birth, tDate);
      secondary = calcAllPlanets(pDate);
      secondaryKeyed = calcAllPlanetsKeyed(pDate);
    }
  }

  // Aspects
  let aspects = collectAspects(natal, natal, false, 'N-N', orbs);
  if (secondary) {
    const crossLabel = mode === 'transit' ? 'N-T' : 'N-P';
    aspects = aspects.concat(collectAspects(natal, secondary, true, crossLabel, orbs));
  }

  // Patterns
  const patterns = detectPatterns(natal, secondary, mode, patternOrbs);

  const result = {
    natal: natalKeyed,
    asc, mc,
    dsc: Math.round(norm360(asc + 180) * 100) / 100,
    ic: Math.round(norm360(mc + 180) * 100) / 100,
    houses,
    houseSystem: (houseSystem === 'whole_sign') ? 'whole_sign'
      : (Math.abs(birthLat) > 66) ? 'equal' : 'placidus',
    aspects,
    patterns
  };

  if (secondaryKeyed) {
    result[mode] = secondaryKeyed;
  }

  return result;
}

// ── Public API: /astro/predict ──
export function computePredictions(params) {
  const { birthDate, birthTime, birthTz = 9, birthTzName, daysAhead = 60 } = params;
  const birth = birthTzName
      ? makeUTCDateFromTzName(birthDate, birthTime, birthTzName)
      : makeUTCDate(birthDate, birthTime, birthTz);
  const natal = calcAllPlanets(birth);
  return { predictions: predictPatternCompletions(natal, daysAhead) };
}

// ══════════════════════════════════════════════════
// MONTH CELESTIAL EVENTS — ingress / retrograde / eclipse
// ══════════════════════════════════════════════════

const SIGN_JP = ['牡羊座','牡牛座','双子座','蟹座','獅子座','乙女座','天秤座','蠍座','射手座','山羊座','水瓶座','魚座'];
const SIGN_EN = ['Aries','Taurus','Gemini','Cancer','Leo','Virgo','Libra','Scorpio','Sagittarius','Capricorn','Aquarius','Pisces'];
const PLANET_JP = {sun:'太陽', moon:'月', mercury:'水星', venus:'金星', mars:'火星', jupiter:'木星', saturn:'土星', uranus:'天王星', neptune:'海王星', pluto:'冥王星'};
const PLANET_EN = {sun:'Sun', moon:'Moon', mercury:'Mercury', venus:'Venus', mars:'Mars', jupiter:'Jupiter', saturn:'Saturn', uranus:'Uranus', neptune:'Neptune', pluto:'Pluto'};

// ── 二分探索で ingress の正確な日時を求める ──
function binarySearchIngress(body, d1, d2, targetSign) {
  let lo = d1.getTime(), hi = d2.getTime();
  for (let i = 0; i < 30; i++) { // 30回で十分 (ms精度)
    const mid = new Date((lo + hi) / 2);
    const sign = Math.floor(norm360(eclLon(body, mid)) / 30);
    if (sign >= targetSign) hi = mid.getTime();
    else lo = mid.getTime();
    if (hi - lo < 60000) break; // 1分精度で打切り
  }
  return new Date(hi);
}

// ── 逆行検出: 1時間前後の経度差が負 → 逆行中 ──
function isRetrograde(body, date) {
  const h1 = new Date(date.getTime() - 3600000);
  const h2 = new Date(date.getTime() + 3600000);
  const l1 = eclLon(body, h1);
  const l2 = eclLon(body, h2);
  let diff = l2 - l1;
  if (diff > 180) diff -= 360;
  if (diff < -180) diff += 360;
  return diff < 0;
}

// ── 逆行転換日検出: 1日刻みで状態変化を探す ──
function findRetrogradeChanges(body, startDate, endDate) {
  const changes = [];
  let prev = isRetrograde(body, startDate);
  const prevState0 = prev;
  const dayMs = 86400000;
  for (let t = startDate.getTime() + dayMs; t <= endDate.getTime(); t += dayMs) {
    const d = new Date(t);
    const cur = isRetrograde(body, d);
    if (cur !== prev) {
      // 二分探索で正確な日を特定
      let lo = t - dayMs, hi = t;
      for (let i = 0; i < 20; i++) {
        const mid = (lo + hi) / 2;
        const midState = isRetrograde(body, new Date(mid));
        if (midState === cur) hi = mid;
        else lo = mid;
        if (hi - lo < 60000) break;
      }
      changes.push({ date: new Date(hi), retrograde: cur });
      prev = cur;
    }
  }
  return { changes, startState: prevState0 };
}

// ── 月内の全天体イベント計算 ──
export function computeMonthEvents(year, month) {
  const startDate = new Date(Date.UTC(year, month - 1, 1, 0, 0, 0));
  const endDate = new Date(Date.UTC(year, month, 0, 23, 59, 59));
  const events = [];

  // ── 1. Ingress (月をまたぐ sign 変化を検出) ──
  for (let i = 0; i < BODIES.length; i++) {
    const body = BODIES[i];
    const key = BODY_KEYS[i];
    if (key === 'sun' || key === 'moon') continue; // 太陽/月は毎月跨ぐので除外 (別扱い)
    const startLon = norm360(eclLon(body, startDate));
    const endLon = norm360(eclLon(body, endDate));
    const startSign = Math.floor(startLon / 30);
    const endSign = Math.floor(endLon / 30);
    // 通常経路 (prograde) での変化
    if (startSign !== endSign && Math.abs(endLon - startLon) < 60) {
      const ingressDate = binarySearchIngress(body, startDate, endDate, endSign);
      events.push({
        type: 'ingress',
        planet: key,
        planetEN: PLANET_EN[key],
        planetJP: PLANET_JP[key],
        sign: SIGN_EN[endSign],
        signJP: SIGN_JP[endSign],
        date: ingressDate.toISOString(), // UTC ISO (クライアント側で toLocal 変換)
        // 日付抜きテンプレート (クライアント側でローカル日付を挿入)
        descTemplate: '{planet} enters {sign}',
        descTemplateJP: '{planet}が{sign}へ移行',
      });
    }
  }

  // ── 2. Retrograde (start / end) ──
  for (const key of ['mercury','venus','mars','jupiter','saturn','uranus','neptune','pluto']) {
    const body = BODIES[BODY_KEYS.indexOf(key)];
    const { changes } = findRetrogradeChanges(body, startDate, endDate);
    for (const ch of changes) {
      const lon = norm360(eclLon(body, ch.date));
      const sign = Math.floor(lon / 30);
      const m = ch.date.getUTCMonth() + 1;
      const d = ch.date.getUTCDate();
      if (ch.retrograde) {
        events.push({
          type: 'retrograde',
          planet: key,
          planetEN: PLANET_EN[key],
          planetJP: PLANET_JP[key],
          sign: SIGN_EN[sign],
          signJP: SIGN_JP[sign],
          date: ch.date.toISOString(),
          descTemplate: '{planet} Retrograde begins in {sign}',
          descTemplateJP: '{planet}が{sign}で逆行開始',
        });
      } else {
        events.push({
          type: 'retrograde_end',
          planet: key,
          planetEN: PLANET_EN[key],
          planetJP: PLANET_JP[key],
          sign: SIGN_EN[sign],
          signJP: SIGN_JP[sign],
          date: ch.date.toISOString(),
          descTemplate: '{planet} stations direct in {sign}',
          descTemplateJP: '{planet}が{sign}で順行へ',
        });
      }
    }
  }

  // ── 3. Eclipses (Solar / Lunar) ──
  try {
    // Lunar Eclipse
    let lunar = Astronomy.SearchLunarEclipse(startDate);
    while (lunar && lunar.peak.date <= endDate) {
      if (lunar.peak.date >= startDate) {
        const lon = norm360(eclLon(Astronomy.Body.Moon, lunar.peak.date));
        const sign = Math.floor(lon / 30);
        events.push({
          type: 'eclipse',
          planet: 'moon',
          planetEN: 'Moon',
          planetJP: '月',
          sign: SIGN_EN[sign],
          signJP: SIGN_JP[sign],
          date: lunar.peak.date.toISOString(),
          descTemplate: 'Lunar Eclipse in {sign}',
          descTemplateJP: '{sign}の月食',
        });
      }
      lunar = Astronomy.NextLunarEclipse(lunar.peak.date);
      if (!lunar || lunar.peak.date > endDate) break;
    }
  } catch (_) { /* skip if search fails */ }

  try {
    // Solar Eclipse (Global)
    let solar = Astronomy.SearchGlobalSolarEclipse(startDate);
    while (solar && solar.peak.date <= endDate) {
      if (solar.peak.date >= startDate) {
        const lon = norm360(eclLon(Astronomy.Body.Sun, solar.peak.date));
        const sign = Math.floor(lon / 30);
        events.push({
          type: 'eclipse',
          planet: 'sun',
          planetEN: 'Sun',
          planetJP: '太陽',
          sign: SIGN_EN[sign],
          signJP: SIGN_JP[sign],
          date: solar.peak.date.toISOString(),
          descTemplate: 'Solar Eclipse in {sign}',
          descTemplateJP: '{sign}の日食',
        });
      }
      solar = Astronomy.NextGlobalSolarEclipse(solar.peak.date);
      if (!solar || solar.peak.date > endDate) break;
    }
  } catch (_) { /* skip if search fails */ }

  // 日付順ソート
  events.sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime());

  return { year, month, events };
}
