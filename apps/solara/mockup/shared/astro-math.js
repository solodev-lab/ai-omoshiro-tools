/* ===== Solara Shared Astro Math Utilities ===== */
/* Used by: index.html (Map), horoscope.html (Horo) */

function toRad(d) { return d * Math.PI / 180; }
function toDeg(r) { return r * 180 / Math.PI; }
function norm360(d) { d = d % 360; return d < 0 ? d + 360 : d; }
function angDist(a, b) { var d = Math.abs(norm360(a) - norm360(b)); return d > 180 ? 360 - d : d; }

/** Ecliptic longitude for any body */
function eclLon(body, date) {
  if (body === Astronomy.Body.Moon) return Astronomy.EclipticGeoMoon(date).lon;
  if (body === Astronomy.Body.Sun) return Astronomy.SunPosition(date).elon;
  return Astronomy.Ecliptic(Astronomy.GeoVector(body, date, true)).elon;
}

/** Standard body list for iteration */
var ASTRO_BODIES = [
  { key: 'sun',     body: Astronomy.Body.Sun },
  { key: 'moon',    body: Astronomy.Body.Moon },
  { key: 'mercury', body: Astronomy.Body.Mercury },
  { key: 'venus',   body: Astronomy.Body.Venus },
  { key: 'mars',    body: Astronomy.Body.Mars },
  { key: 'jupiter', body: Astronomy.Body.Jupiter },
  { key: 'saturn',  body: Astronomy.Body.Saturn },
  { key: 'uranus',  body: Astronomy.Body.Uranus },
  { key: 'neptune', body: Astronomy.Body.Neptune },
  { key: 'pluto',   body: Astronomy.Body.Pluto }
];

/** Calculate ecliptic longitudes for all 10 bodies */
function calcPlanets(date) {
  var r = {};
  ASTRO_BODIES.forEach(function(b) {
    r[b.key] = { angle: Math.round(norm360(eclLon(b.body, date)) * 100) / 100 };
  });
  return r;
}

/** Secondary progression date (1 day = 1 year) */
function progDate(birth, now) {
  var d = (now - birth) / 86400000;
  return new Date(+birth + d / 365.25 * 86400000);
}

/** Ascendant calculation (GMST method) */
function calcAscendant(date, lat, lng) {
  var g = Astronomy.SiderealTime(date);
  var lst = norm360(g * 15 + lng);
  var lstR = lst * Math.PI / 180;
  var jd = (date.getTime() / 86400000) + 2440587.5;
  var T = (jd - 2451545) / 36525;
  var eps = (23.4393 - 0.013 * T) * Math.PI / 180;
  var latR = lat * Math.PI / 180;
  return norm360(Math.atan2(
    -Math.cos(lstR),
    Math.sin(eps) * Math.tan(latR) + Math.cos(eps) * Math.sin(lstR)
  ) * 180 / Math.PI + 180);
}

/** MC (Midheaven) calculation */
function calcMC(date, lng) {
  var g = Astronomy.SiderealTime(date);
  var lst = norm360(g * 15 + lng);
  var lstR = lst * Math.PI / 180;
  var jd = (date.getTime() / 86400000) + 2440587.5;
  var T = (jd - 2451545) / 36525;
  var eps = (23.4393 - 0.013 * T) * Math.PI / 180;
  return norm360(Math.atan2(
    Math.sin(lstR),
    Math.cos(lstR) * Math.cos(eps)
  ) * 180 / Math.PI);
}

/** Load profile from localStorage (returns null if not set) */
function loadSolaraProfile() {
  try { return JSON.parse(localStorage.getItem('solara_profile')); }
  catch (e) { return null; }
}

/** Zodiac sign data */
var ZODIAC_SIGNS = ['Ari','Tau','Gem','Can','Leo','Vir','Lib','Sco','Sag','Cap','Aqu','Pis'];
var ZODIAC_NAMES_JP = ['牡羊座','牡牛座','双子座','蟹座','獅子座','乙女座','天秤座','蠍座','射手座','山羊座','水瓶座','魚座'];
var ZODIAC_EN = ['Aries','Taurus','Gemini','Cancer','Leo','Virgo','Libra','Scorpio','Sagittarius','Capricorn','Aquarius','Pisces'];
var ZODIAC_COLORS = ['#FF4444','#4CAF50','#FFD700','#C0C0C0','#FF8C00','#8BC34A','#E91E63','#9C27B0','#9C27B0','#607D8B','#00BCD4','#3F51B5'];

/** Planet display data */
var PLANET_GLYPHS = ['☉','☽','☿','♀','♂','♃','♄','♅','♆','♇'];
var PLANET_NAMES_JP = ['太陽','月','水星','金星','火星','木星','土星','天王星','海王星','冥王星'];
var PLANET_KEYS = ['sun','moon','mercury','venus','mars','jupiter','saturn','uranus','neptune','pluto'];

/** Planet group classification */
var PLANET_GROUPS = {
  personal: ['sun', 'moon', 'mercury', 'venus', 'mars'],
  social: ['jupiter', 'saturn'],
  generational: ['uranus', 'neptune', 'pluto']
};

/** Fortune category planet associations */
var FORTUNE_PLANETS = {
  healing: ['moon', 'neptune', 'venus'],
  money: ['jupiter', 'venus', 'sun'],
  love: ['venus', 'mars', 'moon'],
  work: ['saturn', 'sun', 'mars', 'jupiter'],
  communication: ['mercury', 'sun', 'venus']
};
