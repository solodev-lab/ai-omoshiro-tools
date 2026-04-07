/**
 * Local test for astro calculations (Node.js)
 * Run: node test.js
 */
import { computeChart, computePredictions } from './src/astro.js';

// オーナーの出生データ（horoscope.htmlのデフォルト値）
const birthParams = {
  birthDate: '1977-10-24',
  birthTime: '06:56',
  birthTz: 9,
  birthLat: 35.4233,
  birthLng: 136.7607,
};

console.log('=== /astro/chart (natal) ===');
const chart = computeChart(birthParams);
console.log('Natal planets:');
for (const [k, v] of Object.entries(chart.natal)) {
  const sign = ['Ari','Tau','Gem','Can','Leo','Vir','Lib','Sco','Sag','Cap','Aqu','Pis'][Math.floor(v / 30)];
  const deg = (v % 30).toFixed(2);
  console.log(`  ${k.padEnd(8)} ${v.toFixed(2).padStart(7)}° = ${sign} ${deg}°`);
}
console.log(`ASC: ${chart.asc}°  MC: ${chart.mc}°  DSC: ${chart.dsc}°  IC: ${chart.ic}°`);
console.log(`House system: ${chart.houseSystem}`);
console.log(`Houses: ${chart.houses.map(h => h.toFixed(1)).join(', ')}`);
console.log(`Aspects found: ${chart.aspects.length}`);
chart.aspects.slice(0, 5).forEach(a => {
  console.log(`  ${a.p1key}-${a.p2key} ${a.type} (${a.diff}°) [${a.label}]`);
});
if (chart.aspects.length > 5) console.log(`  ... and ${chart.aspects.length - 5} more`);
console.log('Patterns:', JSON.stringify({
  grandtrine: chart.patterns.grandtrine.length,
  tsquare: chart.patterns.tsquare.length,
  yod: chart.patterns.yod.length
}));

console.log('\n=== /astro/chart (transit) ===');
const transitChart = computeChart({
  ...birthParams,
  mode: 'transit',
  transitDate: new Date().toISOString(),
});
console.log('Transit planets:');
if (transitChart.transit) {
  for (const [k, v] of Object.entries(transitChart.transit)) {
    console.log(`  ${k.padEnd(8)} ${v.toFixed(2).padStart(7)}°`);
  }
}
console.log(`Cross aspects (N-T): ${transitChart.aspects.filter(a => a.label === 'N-T').length}`);

console.log('\n=== /astro/predict ===');
const pred = computePredictions({ ...birthParams, daysAhead: 30 });
console.log(`Predictions (30 days): ${pred.predictions.length}`);
pred.predictions.slice(0, 3).forEach(p => {
  console.log(`  ${p.type}: ${p.transitBody} → ${p.natalPair.join('+')} in ${p.hoursUntil}h (${p.dateEstimate.slice(0, 10)})`);
});

console.log('\nAll tests passed!');
