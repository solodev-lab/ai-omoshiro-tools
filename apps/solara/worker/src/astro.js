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
function makeUTCDate(dateStr, timeStr, tzHours) {
  const [y, m, d] = dateStr.split('-').map(Number);
  const [h, min] = timeStr.split(':').map(Number);
  return new Date(Date.UTC(y, m - 1, d, h - tzHours, min, 0, 0));
}

// ── Public API: /astro/chart ──
export function computeChart(params) {
  const {
    birthDate, birthTime, birthTz = 9,
    birthLat, birthLng,
    transitDate, mode = 'natal',
    houseSystem = 'placidus',
    orbs, patternOrbs
  } = params;

  const birth = makeUTCDate(birthDate, birthTime, birthTz);
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
  const { birthDate, birthTime, birthTz = 9, daysAhead = 60 } = params;
  const birth = makeUTCDate(birthDate, birthTime, birthTz);
  const natal = calcAllPlanets(birth);
  return { predictions: predictPatternCompletions(natal, daysAhead) };
}
