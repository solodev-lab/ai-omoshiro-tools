/**
 * Solara Astro Lines (Worker port) — Stella 相談 Phase 1。
 *
 * lib/utils/astro_lines.dart を JS に忠実移植したもの。アストロカートグラフィ
 * (Jim Lewis 流) の 4 アングル本線 + アスペクト線を地球曲面に計算する。
 * 数式・定数 (obliquity 23.4393 / Meeus GMST) は Dart 版と完全一致させ、
 * Map が描いている線と相談エンジンの線が同一になるようにする
 * (= エビデンスチップに出す占星術ファクターが画面と矛盾しない)。
 *
 * 各惑星 × 4 アングル (mc/ic/asc/dsc) × 3 アスペクトパス (conjunction / square /
 * trine+sextile) = 120 本。frame (natal/transit/progressed/solarArc) ごとに呼ぶ。
 *
 * 線オブジェクト形:
 *   { planet, angle, aspect, frame, segments: [[{lat,lng},...]],
 *     zenith?: {lat,lng}, nadir?: {lat,lng} }
 */

const OBLIQUITY_DEG = 23.4393; // J2000 平均値、astro_houses.dart / astro_lines.dart と統一

const PLANET_KEYS = [
  'sun', 'moon', 'mercury', 'venus', 'mars',
  'jupiter', 'saturn', 'uranus', 'neptune', 'pluto',
];

const toRad = (d) => (d * Math.PI) / 180;
const toDeg = (r) => (r * 180) / Math.PI;

/** 0..360 に正規化 (astro_math.dart normalize360 と同じ)。 */
function normalize360(d) {
  return ((d % 360) + 360) % 360;
}

/** 経度を -180..180 に正規化 (flutter_map の LatLng 用)。 */
function normLng(d) {
  return ((((d + 180) % 360) + 360) % 360) - 180;
}

function clamp(v, lo, hi) {
  return v < lo ? lo : v > hi ? hi : v;
}

/**
 * 任意 UTC 時刻から GMST (時間, 0..24)。Meeus 標準公式。
 *   JD = 2440587.5 + ms/86400000 ; d = JD - 2451545.0
 *   GMST = 18.697374558 + 24.06570982441908 * d  (時間)
 * astro_lines.dart gmstHoursFromUtc と同一。
 * @param {Date} utc
 */
function gmstHoursFromUtc(utc) {
  const jd = utc.getTime() / 86400000 + 2440587.5;
  const d = jd - 2451545.0;
  const g = 18.697374558 + 24.06570982441908 * d;
  return ((g % 24) + 24) % 24;
}

/** 黄経 (β=0 仮定) → 赤道座標 (RA, Dec)。astro_lines.dart _eclipticToEquatorial と同一。 */
function eclipticToEquatorial(lambdaDeg) {
  const lR = toRad(lambdaDeg);
  const eR = toRad(OBLIQUITY_DEG);
  const dec = Math.asin(Math.sin(eR) * Math.sin(lR));
  const ra = Math.atan2(Math.cos(eR) * Math.sin(lR), Math.cos(lR));
  return { ra: normalize360(toDeg(ra)), dec: toDeg(dec) };
}

/** MC/IC ライン: 固定経度の縦線。子午線跨がないので 1 セグメント。 */
function meridianLine(raDeg, gmstHours, { antiMeridian, latMin = -75, latMax = 75 }) {
  let lng = raDeg - gmstHours * 15;
  if (antiMeridian) lng += 180;
  lng = normLng(lng);
  const pts = [];
  for (let lat = latMin; lat <= latMax + 0.1; lat += 5) {
    pts.push({ lat, lng });
  }
  return [pts];
}

/**
 * ASC/DSC ライン (地平線): cos(H) = -tan(δ)·tan(φ)。
 * ascending=true → ASC (H=-h, 東半球) / false → DSC (H=+h, 西半球)。
 * 子午線跨ぎ (|Δlng|>180) でセグメント分割。astro_lines.dart _horizonLine と同一。
 */
function horizonLine({ raDeg, decDeg, gmstHours, ascending, latMin = -75, latMax = 75, latStep = 2.0 }) {
  const raR = toRad(raDeg);
  const decR = toRad(decDeg);
  const tanDec = Math.tan(decR);
  const segments = [];
  let current = [];
  let prevLng = null;

  for (let lat = latMin; lat <= latMax + 0.01; lat += latStep) {
    const tanLat = Math.tan(toRad(lat));
    const cosH = -tanDec * tanLat;
    if (cosH < -1 || cosH > 1) {
      // この緯度では地平線を横切らない (周極) → セグメント終了
      if (current.length >= 2) segments.push(current);
      current = [];
      prevLng = null;
      continue;
    }
    const h = Math.acos(clamp(cosH, -1, 1)); // 0..π
    const hSigned = ascending ? -h : h;
    const lstR = raR + hSigned;
    const lst = normalize360(toDeg(lstR));
    const lng = normLng(lst - gmstHours * 15);

    if (prevLng !== null && Math.abs(lng - prevLng) > 180) {
      if (current.length >= 2) segments.push(current);
      current = [];
    }
    current.push({ lat, lng });
    prevLng = lng;
  }
  if (current.length >= 2) segments.push(current);
  return segments;
}

/**
 * アスペクトパス。惑星黄経を shift° ずらした点が「アングルに重なる」位置 =
 * 実惑星はそのアングルから shift° 離れている = アスペクト線。
 *   shift 0   → conjunction (本線、天頂/天底マーカー付き)
 *   shift +90 → square
 *   shift +120→ mc/asc=trine, ic/dsc=sextile (ic=mc+180° で 120°→60° 側)
 */
const ASPECT_PASSES = [
  { shift: 0.0, mc: 'conjunction', ic: 'conjunction', asc: 'conjunction', dsc: 'conjunction' },
  { shift: 90.0, mc: 'square', ic: 'square', asc: 'square', dsc: 'square' },
  { shift: 120.0, mc: 'trine', ic: 'sextile', asc: 'trine', dsc: 'sextile' },
];

/** アスペクト種別 → Soft/Hard/Neutral 質 (Solara 設計: Soft/Hard 独立)。 */
const ASPECT_QUALITY = {
  conjunction: 'neutral',
  trine: 'soft',
  sextile: 'soft',
  square: 'hard',
};

/**
 * 任意フレーム × 任意 GMST のアストロライン 120 本を計算。
 * astro_lines.dart buildAstroLinesAt と同一。
 * @param {object} p
 * @param {Object<string,number>} p.planets 10 惑星の黄経 (度)
 * @param {number} p.gmstHours そのフレームの GMST (時間)
 * @param {string} p.frame 'natal'|'transit'|'progressed'|'solarArc'
 * @param {string[]} [p.onlyPlanets] 指定時はその惑星だけ計算 (theme 絞り込みで CPU 節約)
 */
function buildAstroLinesAt({ planets, gmstHours, frame, latMin = -75, latMax = 75, latStep = 2.0, onlyPlanets = null }) {
  const lines = [];
  const wanted = onlyPlanets ? new Set(onlyPlanets) : null;

  for (const planet of PLANET_KEYS) {
    if (wanted && !wanted.has(planet)) continue;
    const lon = planets[planet];
    if (lon == null) continue;

    for (const pass of ASPECT_PASSES) {
      const coord = eclipticToEquatorial((lon + pass.shift) % 360);
      const isConj = pass.shift === 0;
      const mcLng = normLng(coord.ra - gmstHours * 15);

      // MC line + zenith point (conjunction のみ)
      lines.push({
        planet, angle: 'mc', aspect: pass.mc, frame,
        segments: meridianLine(coord.ra, gmstHours, { antiMeridian: false, latMin, latMax }),
        zenith: isConj ? { lat: coord.dec, lng: mcLng } : null,
      });
      // IC line + nadir point (conjunction のみ)
      const icLng = normLng(mcLng + 180);
      lines.push({
        planet, angle: 'ic', aspect: pass.ic, frame,
        segments: meridianLine(coord.ra, gmstHours, { antiMeridian: true, latMin, latMax }),
        nadir: isConj ? { lat: -coord.dec, lng: icLng } : null,
      });
      // ASC line
      lines.push({
        planet, angle: 'asc', aspect: pass.asc, frame,
        segments: horizonLine({ raDeg: coord.ra, decDeg: coord.dec, gmstHours, ascending: true, latMin, latMax, latStep }),
      });
      // DSC line
      lines.push({
        planet, angle: 'dsc', aspect: pass.dsc, frame,
        segments: horizonLine({ raDeg: coord.ra, decDeg: coord.dec, gmstHours, ascending: false, latMin, latMax, latStep }),
      });
    }
  }
  return lines;
}

/**
 * natal + progressed から Solar Arc 方向の惑星位置を導出。
 * 全惑星に arc (= prog.sun - natal.sun) を加算。astro_lines.dart solarArcPlanets と同一。
 */
function solarArcPlanets({ natal, progressed }) {
  const natalSun = natal.sun;
  const progSun = progressed.sun;
  if (natalSun == null || progSun == null) return {};
  const arc = (((progSun - natalSun) % 360) + 360) % 360;
  const result = {};
  for (const [k, v] of Object.entries(natal)) {
    result[k] = (v + arc) % 360;
  }
  return result;
}

/** 2 点の Haversine 距離 (km)。astro_lines.dart _haversineKm と同一。 */
function haversineKm(a, b) {
  const R = 6371.0;
  const lat1 = toRad(a.lat);
  const lat2 = toRad(b.lat);
  const dLat = lat2 - lat1;
  const dLng = toRad(b.lng - a.lng);
  const h = Math.sin(dLat / 2) * Math.sin(dLat / 2)
    + Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLng / 2) * Math.sin(dLng / 2);
  return 2 * R * Math.asin(Math.min(1.0, Math.sqrt(h)));
}

/** 1 本のラインの全セグメント点と地点との最小距離 (km)。astro_lines.dart と同一 (サンプル点最近接)。 */
function minDistanceKmToLine(p, line) {
  let minDist = Infinity;
  for (const seg of line.segments) {
    for (const pt of seg) {
      const d = haversineKm(p, pt);
      if (d < minDist) minDist = d;
    }
  }
  return minDist;
}

/** FORTUNE カテゴリ → ハイライト対象の惑星セット。astro_lines.dart astroLineFortunePlanets と同一。 */
const astroLineFortunePlanets = {
  all: ['sun', 'moon', 'mercury', 'venus', 'mars', 'jupiter', 'saturn', 'uranus', 'neptune', 'pluto'],
  love: ['venus', 'mars', 'moon'],
  money: ['jupiter', 'venus', 'sun'],
  work: ['saturn', 'mars', 'jupiter', 'sun'],
  communication: ['mercury', 'venus', 'moon'],
  healing: ['moon', 'neptune', 'venus'],
  newStart: ['uranus', 'sun', 'jupiter'],
};

export {
  OBLIQUITY_DEG,
  PLANET_KEYS,
  ASPECT_QUALITY,
  normalize360,
  normLng,
  gmstHoursFromUtc,
  eclipticToEquatorial,
  buildAstroLinesAt,
  solarArcPlanets,
  haversineKm,
  minDistanceKmToLine,
  astroLineFortunePlanets,
};
