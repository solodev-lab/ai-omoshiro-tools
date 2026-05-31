/**
 * Stella 相談 計算パイプライン (Phase 1) のテスト。
 * 設計: project_solara_consultation_full_integration.md「実装ロードマップ Phase 1」。
 *
 * 検証対象 (src/consultation_engine.js):
 *   - 時間帯バケット (現地太陽時) / houseOf / sampleDays / migrationHorizonDate
 *   - 候補プール (bearing=16方位/world/region/point/radius) / homeCountry / offsetByBearing
 *   - scoreCandidate (近接ファクター + Soft/Hard 保持 + compositeStrength + aspectStrength + honestQuiet)
 *   - 回転レンズ selectCandidate (1回目=合成最強 / 2回目=アスペクト再合成 / 3回目以降=ランダム
 *     + 正直フォールバック + 案Y 枯渇 noCandidateReason + excluded 前進)
 *   - runConsultationPipeline (daily/travel/migration, 出生時刻不明 degrade)
 *
 * 実行: cd apps/solara/worker && node --test test/consultation_engine.test.js
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { runConsultationPipeline, _internal } from '../src/consultation_engine.js';
import { calcAllPlanetsKeyed, makeUTCDateFromTzName } from '../src/astro.js';

const {
  houseOf, timeOfDayBucket, bucketFromUtcAt,
  sampleDays, migrationHorizonDate, transitInstants,
  buildCandidatePool, homeCountry, offsetByBearing,
  bearingDegFromTo, bearing16, countriesInGroup,
  scoreCandidate, compositeStrengthOf, aspectStrengthOf,
  selectCandidate, suggestionsFor,
} = _internal;

const BIRTH = { date: '1990-06-15', time: '14:30', lat: 35.68, lng: 139.65, tzName: 'Asia/Tokyo' };
const HOME = { lat: 35.68, lng: 139.65 };

// ── D1 モック (Phase B: cities テーブルの bounding-box / 人口フロア+LIMIT を JS で再現) ──
const D1_FIXTURE = [
  // 東京近郊 (HOME=35.68,139.65 から 50km 圏内、≥6 件 → not sparse)
  { name: '東京', ascii: 'Tokyo', lat: 35.68, lng: 139.69, country: 'JP', region: '東京都', population: 9000000 },
  { name: 'さいたま', ascii: 'Saitama', lat: 35.86, lng: 139.65, country: 'JP', region: '埼玉県', population: 1300000 },
  { name: '川崎', ascii: 'Kawasaki', lat: 35.53, lng: 139.70, country: 'JP', region: '神奈川県', population: 1500000 },
  { name: '横浜', ascii: 'Yokohama', lat: 35.44, lng: 139.64, country: 'JP', region: '神奈川県', population: 3700000 },
  { name: '千葉', ascii: 'Chiba', lat: 35.61, lng: 140.11, country: 'JP', region: '千葉県', population: 980000 },
  { name: '立川', ascii: 'Tachikawa', lat: 35.69, lng: 139.41, country: 'JP', region: '東京都', population: 184000 },
  { name: '鎌倉', ascii: 'Kamakura', lat: 35.31, lng: 139.55, country: 'JP', region: '神奈川県', population: 172000 },
  // 50km 圏外 (国内)
  { name: '大阪', ascii: 'Osaka', lat: 34.69, lng: 135.50, country: 'JP', region: '大阪府', population: 2700000 },
  { name: '札幌', ascii: 'Sapporo', lat: 43.06, lng: 141.35, country: 'JP', region: '北海道', population: 1900000 },
  // 海外 大都市
  { name: 'パリ', ascii: 'Paris', lat: 48.85, lng: 2.35, country: 'FR', region: null, population: 2100000 },
  { name: 'ニューヨーク', ascii: 'New York', lat: 40.71, lng: -74.0, country: 'US', region: null, population: 8400000 },
  { name: 'ロンドン', ascii: 'London', lat: 51.50, lng: -0.12, country: 'GB', region: null, population: 9000000 },
  // 全フロア未満の小村 (赤道直下、孤立 sparse テスト兼 人口フロア除外テスト)
  { name: '小村A', ascii: 'Komura A', lat: 0.0, lng: 0.0, country: 'XX', region: null, population: 1500 },
];

/** my engine が発行する 3 種の SQL (bounding-box / country IN / world) を解釈する偽 D1。 */
function makeFakeD1(rows) {
  return {
    prepare(sql) {
      return {
        bind(...args) {
          return {
            // eslint-disable-next-line require-await
            async all() {
              let out;
              if (sql.includes('lat BETWEEN')) {
                const [latMin, latMax, lngMin, lngMax, limit] = args;
                out = rows.filter((r) => r.lat >= latMin && r.lat <= latMax && r.lng >= lngMin && r.lng <= lngMax);
                out.sort((a, b) => b.population - a.population);
                out = out.slice(0, limit);
              } else if (sql.includes('country IN (')) {
                const limit = args[args.length - 1];
                const floor = args[args.length - 2];
                const countries = args.slice(0, args.length - 2);
                out = rows.filter((r) => countries.includes(r.country) && r.population >= floor);
                out.sort((a, b) => b.population - a.population);
                out = out.slice(0, limit);
              } else {
                const [floor, limit] = args;
                out = rows.filter((r) => r.population >= floor);
                out.sort((a, b) => b.population - a.population);
                out = out.slice(0, limit);
              }
              return { results: out };
            },
          };
        },
      };
    },
  };
}

// ── 時間帯バケット ──────────────────────────────────────────

test('timeOfDayBucket: 境界が設計どおり (5帯: 朝5-10/昼10-15/夕方15-19/夜19-23/夜更け23-5)', () => {
  // 夜更け 23-5 (日をまたぐ)
  assert.equal(timeOfDayBucket(4), 'lateNight');
  assert.equal(timeOfDayBucket(23.5), 'lateNight');
  assert.equal(timeOfDayBucket(0), 'lateNight');
  // 朝 5-10
  assert.equal(timeOfDayBucket(5), 'morning');
  assert.equal(timeOfDayBucket(9.9), 'morning');
  // 昼 10-15
  assert.equal(timeOfDayBucket(10), 'midday');
  assert.equal(timeOfDayBucket(12), 'midday');
  // 夕方 15-19
  assert.equal(timeOfDayBucket(15), 'evening');
  assert.equal(timeOfDayBucket(18), 'evening');
  // 夜 19-23
  assert.equal(timeOfDayBucket(19), 'night');
  assert.equal(timeOfDayBucket(22.9), 'night');
});

test('bucketFromUtcAt: 経度で現地時間帯がずれる (旅行先=現地時間)', () => {
  // 12:00 UTC。経度 +135 (日本) → 現地 21:00 = 夜 / 経度 -120 (西海岸) → 現地 04:00 = 夜更け(23-5)
  const noonUtc = new Date('2026-07-10T12:00:00Z');
  assert.equal(bucketFromUtcAt(noonUtc, 135), 'night');
  assert.equal(bucketFromUtcAt(noonUtc, -120), 'lateNight');
});

// ── houseOf ─────────────────────────────────────────────────

test('houseOf: 等分ハウスで黄経→室を正しく判定', () => {
  // ASC=0° の等分ハウス: cusp = 0,30,60,...
  const houses = Array.from({ length: 12 }, (_, i) => i * 30);
  assert.equal(houseOf(15, houses), 1);
  assert.equal(houseOf(45, houses), 2);
  assert.equal(houseOf(359, houses), 12);
  assert.equal(houseOf(0, houses), 1);
});

test('houseOf: 0°跨ぎの cusp でも正しく循環', () => {
  // ASC=350° から 30°刻み: cusp = 350,20,50,...
  const houses = Array.from({ length: 12 }, (_, i) => (350 + i * 30) % 360);
  assert.equal(houseOf(355, houses), 1); // 350..20 が 1室
  assert.equal(houseOf(10, houses), 1);
  assert.equal(houseOf(25, houses), 2); // 20..50 が 2室
});

// ── sampleDays / horizon / transitInstants ──────────────────

test('sampleDays: 期間≤3日は全日、>3日は端含む3日に均等サンプリング', () => {
  const short = sampleDays('2026-07-10', '2026-07-12', 3);
  assert.equal(short.length, 3);
  const long = sampleDays('2026-07-01', '2026-07-31', 3);
  assert.equal(long.length, 3);
  assert.equal(long[0].toISOString().slice(0, 10), '2026-07-01');
  assert.equal(long[2].toISOString().slice(0, 10), '2026-07-31');
});

test('migrationHorizonDate: 年限が未来日に展開 / date 指定はその日', () => {
  const now = Date.now();
  const in3 = migrationHorizonDate({ kind: 'in3yr' });
  const yrs = (in3.getTime() - now) / (365.25 * 86400000);
  assert.ok(yrs > 2.9 && yrs < 3.1, `~3yr, got ${yrs}`);
  const fixed = migrationHorizonDate({ kind: 'date', date: '2030-01-01' });
  assert.equal(fixed.toISOString().slice(0, 10), '2030-01-01');
  const undecided = migrationHorizonDate({ kind: 'undecided' });
  assert.ok(Math.abs(undecided.getTime() - now) < 5000); // ほぼ今
});

test('transitInstants: daily=1 / travel range≤3 / migration=空', () => {
  assert.equal(transitInstants('daily', { kind: 'date', date: '2026-07-10' }).length, 1);
  assert.ok(transitInstants('travel', { kind: 'range', start: '2026-07-01', end: '2026-07-31' }).length <= 3);
  assert.equal(transitInstants('migration', { kind: 'in3yr' }).length, 0);
});

// ── 候補プール ──────────────────────────────────────────────

// ── 候補プール フォールバック (D1 binding 無し = 従来 worldCities / 合成方位) ──

test('buildCandidatePool フォールバック: bearing=16合成方位 / world=全都市 / point=1件 (D1 無し)', async () => {
  const bearings = await buildCandidatePool({ scope: { kind: 'bearing', radiusKm: 50 }, home: HOME, mode: 'daily' });
  assert.equal(bearings.source, 'fallback-bearing');
  assert.equal(bearings.candidates.length, 16);
  assert.ok(bearings.candidates.every((b) => b.bearing));
  // 22.5°刻みの中間方位ラベルが含まれる (16方位化の回帰防止)
  const names = bearings.candidates.map((b) => b.name);
  assert.ok(names.includes('北北東') && names.includes('西南西'));

  const world = await buildCandidatePool({ scope: { kind: 'world' }, home: HOME, mode: 'migration' });
  assert.equal(world.source, 'fallback-world');
  assert.ok(world.candidates.length > 700);

  const point = await buildCandidatePool({ scope: { kind: 'point', point: { lat: 34.69, lng: 135.5, name: 'カフェX', placeType: 'cafe' } }, home: HOME, mode: 'daily' });
  assert.equal(point.candidates.length, 1);
  assert.equal(point.candidates[0].isPoint, true);
  assert.equal(point.candidates[0].placeType, 'cafe');
});

test('buildCandidatePool フォールバック: region は regionGroup / radius は距離で絞る (D1 無し)', async () => {
  const jp = await buildCandidatePool({ scope: { kind: 'region', regionGroup: '日本' }, home: HOME, mode: 'migration' });
  assert.ok(jp.candidates.length > 50 && jp.candidates.every((c) => c.country === 'JP'));

  const near = await buildCandidatePool({ scope: { kind: 'radius', radiusKm: 100 }, home: HOME, mode: 'travel' });
  const far = await buildCandidatePool({ scope: { kind: 'radius', radiusKm: 1000 }, home: HOME, mode: 'travel' });
  assert.ok(near.candidates.length < far.candidates.length);

  // 旅行/移住の距離帯バンド (minKm): 下限未満 (隣町) を弾く。
  const within = await buildCandidatePool({ scope: { kind: 'radius', radiusKm: 500 }, home: HOME, mode: 'travel' });
  const band = await buildCandidatePool({ scope: { kind: 'radius', radiusKm: 500, minKm: 300 }, home: HOME, mode: 'travel' });
  assert.ok(band.candidates.length < within.candidates.length, 'バンドは「以内」より少ない');
});

test('buildCandidatePool D1: radius の minKm バンドで近場(隣町)を弾き遠方だけ残す', async () => {
  const DB = makeFakeD1(D1_FIXTURE);
  // 「以内」(minKm 無し) は近場 (東京) も遠方 (大阪) も含む。
  const within = await buildCandidatePool({ scope: { kind: 'radius', radiusKm: 1000 }, home: HOME, mode: 'travel', env: { DB } });
  assert.equal(within.source, 'd1-local');
  assert.ok(within.candidates.some((c) => c.name === '東京'));
  assert.ok(within.candidates.some((c) => c.name === '大阪'));
  // バンド [100, 1000]: <100km の隣町 (東京/横浜/鎌倉) を除外、遠方 (大阪/札幌) は残す。
  const band = await buildCandidatePool({ scope: { kind: 'radius', radiusKm: 1000, minKm: 100 }, home: HOME, mode: 'travel', env: { DB } });
  assert.equal(band.source, 'd1-local');
  assert.ok(!band.candidates.some((c) => c.name === '東京'), '隣町(東京)は弾く');
  assert.ok(!band.candidates.some((c) => c.name === '横浜'), '隣町(横浜)は弾く');
  assert.ok(!band.candidates.some((c) => c.name === '鎌倉'), '隣町(鎌倉)は弾く');
  assert.ok(band.candidates.some((c) => c.name === '大阪'), 'バンド内(大阪)は残す');
  assert.ok(band.candidates.some((c) => c.name === '札幌'), 'バンド内(札幌)は残す');
});

// ── 候補プール D1 (Phase B: 実在の町 bounding-box / 人口フロア+LIMIT) ──

test('buildCandidatePool D1: おでかけ=近傍の実在の町 (方角ラベル付き・bearing 立てない・50km 外を除外)', async () => {
  const DB = makeFakeD1(D1_FIXTURE);
  const r = await buildCandidatePool({ scope: { kind: 'bearing', radiusKm: 50 }, home: HOME, mode: 'daily', env: { DB } });
  assert.equal(r.source, 'd1-local');
  assert.equal(r.sparse, false); // 50km 圏内 7 件 ≥ 6
  assert.ok(r.candidates.some((c) => c.name === '鎌倉'));
  const kama = r.candidates.find((c) => c.name === '鎌倉');
  assert.equal(kama.bearing, undefined); // 方角だけの読みに落とさない (町名を名指しさせる)
  assert.ok(kama.directionFromHome); // 表示用 方角ラベル「南西」等はある
  assert.equal(typeof kama.distanceKm, 'number');
  // 50km 圏外 (大阪/札幌/海外) は含まれない
  assert.ok(!r.candidates.some((c) => c.name === '大阪' || c.name === '札幌' || c.name === 'パリ'));
});

test('buildCandidatePool D1: 近傍に町が乏しいと sparse=true (枯渇とは別、ヒント用)', async () => {
  const DB = makeFakeD1(D1_FIXTURE);
  const r = await buildCandidatePool({ scope: { kind: 'bearing', radiusKm: 50 }, home: { lat: 0.0, lng: 0.0 }, mode: 'daily', env: { DB } });
  assert.equal(r.source, 'd1-local');
  assert.ok(r.nearbyCount < 6);
  assert.equal(r.sparse, true);
});

test('buildCandidatePool D1: 世界=人口フロアで小村を除外し人口順 (LIMIT は env で可変)', async () => {
  const DB = makeFakeD1(D1_FIXTURE);
  const world = await buildCandidatePool({ scope: { kind: 'world' }, home: HOME, mode: 'migration', env: { DB } });
  assert.equal(world.source, 'd1-world');
  assert.ok(!world.candidates.some((c) => c.name === '小村A')); // 人口 30万未満は除外
  assert.ok(world.candidates[0].population >= world.candidates[1].population); // 人口降順

  const capped = await buildCandidatePool({ scope: { kind: 'world' }, home: HOME, mode: 'migration', env: { DB, CONSULTATION_WIDE_LIMIT: '2' } });
  assert.equal(capped.candidates.length, 2); // 上位 N=2 で頭打ち

  const highFloor = await buildCandidatePool({ scope: { kind: 'world' }, home: HOME, mode: 'migration', env: { DB, CONSULTATION_WORLD_MIN_POP: '5000000' } });
  assert.ok(highFloor.candidates.every((c) => c.population >= 5000000));
});

test('buildCandidatePool D1: 自国/地域は人口フロア + 国フィルタ', async () => {
  const DB = makeFakeD1(D1_FIXTURE);
  const jp = await buildCandidatePool({ scope: { kind: 'country', country: 'JP' }, home: HOME, mode: 'migration', env: { DB } });
  assert.equal(jp.source, 'd1-country');
  assert.ok(jp.candidates.length > 0 && jp.candidates.every((c) => c.country === 'JP'));

  const region = await buildCandidatePool({ scope: { kind: 'region', regionGroup: '日本' }, home: HOME, mode: 'migration', env: { DB } });
  assert.equal(region.source, 'd1-region');
  assert.ok(region.candidates.length > 0 && region.candidates.every((c) => c.country === 'JP'));
});

test('buildCandidatePool D1: D1 エラー時は従来プールに degrade (おでかけ/広域を 500 にしない)', async () => {
  const throwingDB = {
    prepare: () => ({
      bind: () => ({
        // eslint-disable-next-line require-await
        async all() { throw new Error('d1 down'); },
      }),
    }),
  };
  // 局所 (おでかけ) → 合成 16 方位フォールバック
  const local = await buildCandidatePool({ scope: { kind: 'bearing', radiusKm: 50 }, home: HOME, mode: 'daily', env: { DB: throwingDB } });
  assert.equal(local.source, 'fallback-bearing');
  assert.equal(local.candidates.length, 16);
  // 広域 (世界) → worldCities フォールバック
  const world = await buildCandidatePool({ scope: { kind: 'world' }, home: HOME, mode: 'migration', env: { DB: throwingDB } });
  assert.equal(world.source, 'fallback-world');
  assert.ok(world.candidates.length > 700);
});

test('countriesInGroup / bearing16: 領域→国コード集合、方位度→16方位コード', () => {
  assert.ok(countriesInGroup('日本').includes('JP'));
  assert.ok(countriesInGroup('北米').includes('US'));
  assert.equal(bearing16(0), 'N');
  assert.equal(bearing16(45), 'NE');
  assert.equal(bearing16(22.5), 'NNE');
  assert.equal(bearing16(180), 'S');
  // home の真北の点は方位≈0 (N)
  assert.equal(bearing16(bearingDegFromTo(HOME, { lat: HOME.lat + 1, lng: HOME.lng })), 'N');
});

test('homeCountry: 東京の home → JP', () => {
  assert.equal(homeCountry(HOME), 'JP');
});

test('offsetByBearing: 北へ100kmで緯度が上がる', () => {
  const p = offsetByBearing(HOME, 0, 100);
  assert.ok(p.lat > HOME.lat);
  assert.ok(Math.abs(p.lng - HOME.lng) < 0.01); // 真北は経度ほぼ不変
});

// ── scoreCandidate (Soft/Hard 保持 + honestQuiet) ───────────

test('scoreCandidate: 線オーブ内は factor 化、Soft/Hard quality を保持', () => {
  // 候補の真上に trine 線 (soft) と square 線 (hard) を置いた合成プール
  const pt = { lat: 35, lng: 139 };
  const onLine = [[{ lat: 35, lng: 139 }, { lat: 36, lng: 139 }]];
  const pool = {
    lines: [
      { planet: 'venus', angle: 'mc', aspect: 'trine', frame: 'natal', segments: onLine },
      { planet: 'mars', angle: 'asc', aspect: 'square', frame: 'natal', segments: onLine },
    ],
    bands: [],
  };
  const r = scoreCandidate(pt, pool);
  assert.equal(r.factors.length, 2);
  const q = new Set(r.factors.map((f) => f.quality));
  assert.ok(q.has('soft') && q.has('hard')); // total に潰さず独立保持
  assert.ok(!r.honestQuiet); // 真上=強い
});

test('scoreCandidate: 全ファクターがオーブ外なら honestQuiet=true (正直フォールバック)', () => {
  const pt = { lat: 0, lng: 0 };
  const farLine = [[{ lat: 80, lng: 170 }]]; // 遠い (>800km)
  const pool = { lines: [{ planet: 'venus', angle: 'mc', aspect: 'conjunction', frame: 'natal', segments: farLine }], bands: [] };
  const r = scoreCandidate(pt, pool);
  assert.equal(r.factors.length, 0);
  assert.equal(r.honestQuiet, true);
});

// ── 合成スコア (compositeStrength / aspectStrength) ──────────

test('compositeStrengthOf: 減衰総和で線数インフレを防ぐ (強1本 > 弱多数 / 厚い場 > 単線)', () => {
  const one = compositeStrengthOf([{ strength: 0.9 }]);
  const manyWeak = compositeStrengthOf(Array.from({ length: 8 }, () => ({ strength: 0.2 })));
  assert.ok(one > manyWeak, `強1本(${one}) が 弱8本(${manyWeak}) を上回る`);
  // 独立した中強度3本の「厚い場」は単線(0.5)をやや上回る (テーマ地理差別化の backbone)
  const thick = compositeStrengthOf([{ strength: 0.5 }, { strength: 0.5 }, { strength: 0.5 }]);
  assert.ok(thick > 0.5 && thick < 1.0, `厚い場(${thick})`);
});

test('aspectStrengthOf: trine/square を主役に conjunction と帯を脇に (2回目レンズ)', () => {
  const trine = aspectStrengthOf([{ kind: 'line', aspect: 'trine', strength: 0.6 }]);
  const conj = aspectStrengthOf([{ kind: 'line', aspect: 'conjunction', strength: 0.6 }]);
  const band = aspectStrengthOf([{ kind: 'band', aspect: 'zenith', strength: 0.6 }]);
  assert.ok(trine > conj, `トライン(${trine}) > 合(${conj})`);
  assert.ok(conj > band, `合(${conj}) > 帯(${band})`);
});

// ── 回転レンズ selectCandidate ──────────────────────────────

function fakeCand(name, planet, angle, aspect, quality, strength, aspectStrength) {
  const f = { kind: 'line', planet, angle, aspect, quality, strength, distanceKm: Math.round((1 - strength) * 800) };
  return {
    name, nameEN: name, factors: [f],
    topStrength: strength, compositeStrength: strength,
    aspectStrength: aspectStrength ?? strength,
    honestQuiet: strength < 0.18,
  };
}

test('selectCandidate 1回目(attempt0): 多線合成最強(=先頭 lively)を返す', () => {
  const scored = [
    fakeCand('A', 'venus', 'mc', 'conjunction', 'neutral', 0.9, 0.3),
    fakeCand('C', 'mars', 'asc', 'trine', 'soft', 0.6, 0.6),
  ];
  const r = selectCandidate(scored, [], 0);
  assert.equal(r.candidate.name, 'A');
  assert.equal(r.lens, 'composite');
});

test('selectCandidate 2回目(attempt1): アスペクト再合成で並べ替える (合成順と別の土地)', () => {
  const scored = [
    fakeCand('A', 'venus', 'mc', 'conjunction', 'neutral', 0.95, 0.30), // 合成1位/アスペクト弱
    fakeCand('B', 'mars', 'asc', 'square', 'hard', 0.70, 0.70),         // 合成2位/アスペクト強
    fakeCand('C', 'venus', 'dsc', 'trine', 'soft', 0.60, 0.65),
  ];
  // 1回目で A を出した後 (excluded=['A'])、2回目=アスペクトレンズ → B (aspect最強)
  const r = selectCandidate(scored, ['A'], 1);
  assert.equal(r.lens, 'aspect');
  assert.equal(r.candidate.name, 'B');
});

test('selectCandidate 3回目以降(attempt2): lively からランダム (乱数注入で検証)', () => {
  const two = [
    fakeCand('X', 'sun', 'mc', 'trine', 'soft', 0.5, 0.5),
    fakeCand('Y', 'moon', 'asc', 'trine', 'soft', 0.4, 0.4),
  ];
  assert.equal(selectCandidate(two, [], 2, () => 0).candidate.name, 'X');     // 乱数0→先頭
  assert.equal(selectCandidate(two, [], 2, () => 0.99).candidate.name, 'Y');  // 乱数~1→末尾
  assert.equal(selectCandidate(two, [], 2, () => 0).lens, 'random');
});

test('selectCandidate 1回目で全部静か: 正直フォールバックで最強の静かな場を返す (枯渇にしない)', () => {
  const quiet = [
    fakeCand('Q1', 'venus', 'mc', 'trine', 'soft', 0.15, 0.15),
    fakeCand('Q2', 'mars', 'asc', 'trine', 'soft', 0.10, 0.10),
  ];
  const r = selectCandidate(quiet, [], 0);
  assert.ok(r.candidate);              // null にしない (= クレジット消費する読み)
  assert.equal(r.candidate.name, 'Q1');
  assert.equal(r.lens, 'composite');
});

test('selectCandidate 枯渇(案Y): emptyPool / noFresh / allQuiet を区別', () => {
  assert.equal(selectCandidate([], [], 0).noCandidateReason, 'emptyPool');

  const lively = [fakeCand('A', 'venus', 'mc', 'trine', 'soft', 0.6, 0.6)];
  const noFresh = selectCandidate(lively, ['A'], 1);
  assert.equal(noFresh.candidate, null);
  assert.equal(noFresh.noCandidateReason, 'noFresh');

  // 2回目以降に lively が尽き、静かな場しか残らない
  const mixed = [
    fakeCand('A', 'venus', 'mc', 'trine', 'soft', 0.6, 0.6),
    fakeCand('Q', 'mars', 'asc', 'trine', 'soft', 0.10, 0.10), // honestQuiet
  ];
  const allQuiet = selectCandidate(mixed, ['A'], 1);
  assert.equal(allQuiet.candidate, null);
  assert.equal(allQuiet.noCandidateReason, 'allQuiet');
});

test('selectCandidate: 具体地点 (isPoint) は単一候補で常に返す', () => {
  const scored = [{ name: 'カフェX', nameEN: 'cafeX', isPoint: true, factors: [], topStrength: 0, compositeStrength: 0, aspectStrength: 0, honestQuiet: true }];
  const r = selectCandidate(scored, ['カフェX'], 5);
  assert.equal(r.single, true);
  assert.equal(r.candidate.name, 'カフェX'); // 既出でも返す
});

test('suggestionsFor: scope に応じた正直な代替提案コード (案Y)', () => {
  assert.ok(suggestionsFor({ kind: 'radius' }).includes('widenRadius'));
  assert.ok(suggestionsFor({ kind: 'country' }).includes('world'));
  assert.ok(suggestionsFor({ kind: 'bearing' }).includes('point'));
  assert.ok(!suggestionsFor({ kind: 'point' }).includes('point'));
});

// ── runConsultationPipeline (統合) ──────────────────────────

test('pipeline daily: 候補 + factors + timeWindow + innerSeason + evidence を返す', async () => {
  const r = await runConsultationPipeline({
    birth: BIRTH, home: HOME, theme: 'love', mode: 'daily',
    when: { kind: 'date', date: '2026-07-10' }, scope: { kind: 'bearing', radiusKm: 50 },
    isFirst: true, excluded: [],
  });
  assert.ok(r.candidate);
  assert.ok(r.candidate.bearing); // 方角候補 (D1 無し=フォールバックの合成方位)
  assert.ok(Array.isArray(r.candidate.factors));
  assert.ok(r.innerSeason.progMoonSignJP);
  assert.ok(r.innerSeason.progMoonHouse >= 1 && r.innerSeason.progMoonHouse <= 12);
  assert.ok(Array.isArray(r.evidence.factors) && r.evidence.factors.length > 0);
  // daily は時刻不明でないので note なし
  assert.equal(r.evidence.note, null);
});

test('pipeline diversity: excluded で別の候補に進む', async () => {
  const base = {
    birth: BIRTH, home: HOME, theme: 'work', mode: 'daily',
    when: { kind: 'date', date: '2026-07-10' }, scope: { kind: 'bearing', radiusKm: 100 },
  };
  const first = await runConsultationPipeline({ ...base, isFirst: true, excluded: [] });
  const second = await runConsultationPipeline({ ...base, isFirst: false, excluded: [first.candidate.name] });
  assert.ok(second.candidate);
  assert.notEqual(second.candidate.name, first.candidate.name);
});

test('pipeline avoid (C-2): avoid は別候補にするが attempt/レンズは進めない (1回目=合成最強のまま)', async () => {
  const base = {
    birth: BIRTH, home: HOME, theme: 'work', mode: 'daily',
    when: { kind: 'date', date: '2026-07-10' }, scope: { kind: 'bearing', radiusKm: 100 },
  };
  const first = await runConsultationPipeline({ ...base, isFirst: true, excluded: [] });
  // first を avoid に入れて「新規相談」(excluded 空 = attempt 0)
  const avoided = await runConsultationPipeline({
    ...base, isFirst: true, excluded: [], avoid: [first.candidate.name],
  });
  assert.ok(avoided.candidate);
  assert.notEqual(avoided.candidate.name, first.candidate.name); // avoid した土地は出ない
  assert.equal(avoided.meta.attempt, 0); // avoid は attempt に数えない
  assert.equal(avoided.meta.lens, 'composite'); // 1 回目=合成最強レンズのまま
});

test('pipeline avoid 安全策 (C-2): avoid で全滅しても新規相談(attempt0)は必ず 1 枚出す', async () => {
  const base = {
    birth: BIRTH, home: HOME, theme: 'love', mode: 'daily',
    when: { kind: 'date', date: '2026-07-10' }, scope: { kind: 'bearing', radiusKm: 50 },
  };
  const allBearings = [
    '北', '北北東', '北東', '東北東', '東', '東南東', '南東', '南南東',
    '南', '南南西', '南西', '西南西', '西', '西北西', '北西', '北北西',
  ];
  const r = await runConsultationPipeline({ ...base, isFirst: true, excluded: [], avoid: allBearings });
  assert.ok(r.candidate); // avoid を無視してでも 1 枚返す (fresh 相談で「何も無い」を避ける)

  // ただし「出し直し」(attempt>=1) は avoid 全滅なら従来どおり枯渇 (案Y)
  const exhausted = await runConsultationPipeline({
    ...base, isFirst: false, excluded: [r.candidate.name], avoid: allBearings,
  });
  assert.ok(!exhausted.candidate);
  assert.equal(exhausted.exhausted, true);
});

test('pipeline migration: transit 不使用 (factor は natal/progressed のみ) + リロケハウス', async () => {
  const r = await runConsultationPipeline({
    birth: BIRTH, home: HOME, theme: 'money', mode: 'migration',
    when: { kind: 'date', date: '2030-01-01' }, scope: { kind: 'world' },
    isFirst: true, excluded: [],
  });
  assert.ok(r.candidate);
  assert.ok(r.candidate.factors.every((f) => f.frame !== 'transit'));
  // 時刻ありなのでリロケハウスが付く
  assert.ok(r.candidate.relocation && r.candidate.relocation.planetHouses);
  assert.equal(r.timeWindow, null); // 移住は時間帯なし
});

test('pipeline 出生時刻不明 migration: ハウス/リロケを使わず帯で読む + 注記', async () => {
  const r = await runConsultationPipeline({
    birth: { ...BIRTH, time: null, timeUnknown: true }, home: HOME, theme: 'healing', mode: 'migration',
    when: { kind: 'in1yr' }, scope: { kind: 'region', regionGroup: '日本' },
    isFirst: true, excluded: [],
  });
  assert.ok(r.candidate);
  assert.equal(r.candidate.relocation, null); // 時刻不明 → リロケなし
  assert.equal(r.innerSeason.progMoonHouse, null); // ハウスなし (サインは出る)
  assert.ok(r.innerSeason.progMoonSignJP);
  assert.ok(r.meta.poolBands > 0); // 帯は backbone として残る
  // natal ACG 線は時刻不明で省略 → factor は band か progressed(時刻不明なので無)/natalband
  assert.ok(r.candidate.factors.every((f) => !(f.frame === 'natal' && f.kind === 'line')));
  assert.ok(r.evidence.note && r.evidence.note.includes('出生時刻'));
});

test('pipeline 出生時刻不明 daily: フル品質 (注記なし) — 設計 B', async () => {
  const r = await runConsultationPipeline({
    birth: { ...BIRTH, time: null, timeUnknown: true }, home: HOME, theme: 'love', mode: 'daily',
    when: { kind: 'date', date: '2026-07-10' }, scope: { kind: 'bearing', radiusKm: 50 },
    isFirst: true, excluded: [],
  });
  assert.ok(r.candidate);
  assert.equal(r.evidence.note, null); // おでかけは時刻不明でも注記なし
});

test('pipeline point scope: 指定地点を single で返す (placeType 引き継ぎ)', async () => {
  const r = await runConsultationPipeline({
    birth: BIRTH, home: HOME, theme: 'love', mode: 'daily',
    when: { kind: 'today' }, scope: { kind: 'point', point: { lat: 34.69, lng: 135.5, name: 'カフェX', placeType: 'cafe' } },
    isFirst: true, excluded: [],
  });
  assert.equal(r.single, true);
  assert.equal(r.candidate.placeType, 'cafe');
  assert.equal(r.candidate.name, 'カフェX');
});

// pipeline → placeReference の end-to-end 伝達 (2026-05-27 回帰防止)
// buildCandidatePool で乗せた placeKind が runConsultationPipeline の最終 return で
// 列挙忘れにより消えるバグの再発防止。'named'/'saved' は consultation_v2.placeReference
// の分岐キーで、これが消えると検索の店名が「都市名で呼んでよい」分岐に丸められる。
test('pipeline point scope: placeKind=named (検索) を candidate に保持', async () => {
  const r = await runConsultationPipeline({
    birth: BIRTH, home: HOME, theme: 'love', mode: 'daily',
    when: { kind: 'today' },
    scope: { kind: 'point', point: { lat: 35.17, lng: 136.88, name: 'JR名古屋高島屋', placeKind: 'named' } },
    isFirst: true, excluded: [],
  });
  assert.equal(r.candidate.name, 'JR名古屋高島屋');
  assert.equal(r.candidate.placeKind, 'named');
});

test('pipeline point scope: placeKind=saved (登録地) を candidate に保持', async () => {
  const r = await runConsultationPipeline({
    birth: BIRTH, home: HOME, theme: 'healing', mode: 'daily',
    when: { kind: 'today' },
    scope: { kind: 'point', point: { lat: 35.68, lng: 139.65, name: 'マイ秘密基地', placeKind: 'saved' } },
    isFirst: true, excluded: [],
  });
  assert.equal(r.candidate.name, 'マイ秘密基地');
  assert.equal(r.candidate.placeKind, 'saved');
});

test('pipeline point scope: placeKind 未指定 (従来) は null', async () => {
  const r = await runConsultationPipeline({
    birth: BIRTH, home: HOME, theme: 'love', mode: 'daily',
    when: { kind: 'today' },
    scope: { kind: 'point', point: { lat: 34.69, lng: 135.5, name: '地図タップ地点' } },
    isFirst: true, excluded: [],
  });
  assert.equal(r.candidate.placeKind, null);
});

test('pipeline: world migration が CPU 予算内 (<3s)', async () => {
  const t0 = Date.now();
  await runConsultationPipeline({
    birth: BIRTH, home: HOME, theme: 'work', mode: 'migration',
    when: { kind: 'in5yrPlus' }, scope: { kind: 'world' }, isFirst: true, excluded: [],
  });
  const ms = Date.now() - t0;
  assert.ok(ms < 3000, `pipeline took ${ms}ms`);
});

test('pipeline: 不正 theme / mode は reject (async)', async () => {
  await assert.rejects(() => runConsultationPipeline({ birth: BIRTH, home: HOME, theme: 'bogus', mode: 'daily' }));
  await assert.rejects(() => runConsultationPipeline({ birth: BIRTH, home: HOME, theme: 'love', mode: 'bogus' }));
});

// ── 30 分後デルタ (Pro おでかけ時刻指定) ──────────────────────

const DELTA_DIRS = new Set(['approaching', 'receding', 'entering', 'leaving', 'steady']);

test('transitInstants: when.atUtcMs を尊重する (daily)', () => {
  const ms = Date.UTC(2026, 0, 1, 3, 30, 0);
  const got = transitInstants('daily', { kind: 'today', atUtcMs: ms });
  assert.equal(got.length, 1);
  assert.equal(got[0].getTime(), ms);
});

test('transitInstants: atUtcMs 無しは従来 (today=now / date=正午)', () => {
  assert.equal(transitInstants('daily', { kind: 'date', date: '2026-06-15' })[0].getTime(),
    new Date('2026-06-15T12:00:00Z').getTime());
});

test('computeTimeDelta: changes は許可された dir、deltaMin を返す', () => {
  const birthUTC = makeUTCDateFromTzName('1990-06-15', '14:30', 'Asia/Tokyo');
  const natalLons = calcAllPlanetsKeyed(birthUTC);
  const instantT = new Date(Date.UTC(2026, 5, 15, 6, 0, 0)); // 15:00 JST
  const pool = _internal.buildInfluencePool({
    birthUTC, mode: 'daily', when: { atUtcMs: instantT.getTime() },
    theme: 'love', timeUnknown: false, natalLons,
  });
  const candidate = { lat: 35.68, lng: 139.65 };
  const delta = _internal.computeTimeDelta({
    candidate, pool, themePlanets: pool.themePlanets, instantT, deltaMin: 30,
  });
  assert.equal(delta.deltaMin, 30);
  assert.ok(Array.isArray(delta.changes));
  assert.equal(typeof delta.hasMotion, 'boolean');
  for (const ch of delta.changes) {
    assert.ok(DELTA_DIRS.has(ch.dir), `unexpected dir: ${ch.dir}`);
    assert.ok(ch.planet && ch.angle, 'planet/angle がある');
  }
});

test('computeTimeDelta: 大きく時間を進めると線が動く (12h で motion 検出)', () => {
  const birthUTC = makeUTCDateFromTzName('1990-06-15', '14:30', 'Asia/Tokyo');
  const natalLons = calcAllPlanetsKeyed(birthUTC);
  const instantT = new Date(Date.UTC(2026, 5, 15, 6, 0, 0));
  const pool = _internal.buildInfluencePool({
    birthUTC, mode: 'daily', when: { atUtcMs: instantT.getTime() },
    theme: 'all', timeUnknown: false, natalLons,
  });
  const candidate = { lat: 35.68, lng: 139.65 };
  // 12 時間 = GMST 180° 進行 → 角ラインが地球規模で sweep。何かしら入れ替わる。
  const delta = _internal.computeTimeDelta({
    candidate, pool, themePlanets: pool.themePlanets, instantT, deltaMin: 720,
  });
  assert.ok(delta.changes.length > 0, '12時間後は近接テーマ線の集合が変わる');
  assert.ok(delta.hasMotion, '大きな時間差では hasMotion=true');
});

test('pipeline: daily + when.atUtcMs で candidate.timeDelta が出る', async () => {
  const atUtcMs = Date.UTC(2026, 5, 15, 6, 0, 0);
  const pipe = await runConsultationPipeline({
    birth: BIRTH, home: HOME, theme: 'love', mode: 'daily',
    when: { kind: 'today', atUtcMs },
    scope: { kind: 'point', point: { lat: 35.68, lng: 139.65, name: 'テスト地点' } },
    isFirst: true, excluded: [],
  });
  assert.ok(pipe.candidate, '候補が出る');
  assert.ok(pipe.candidate.timeDelta, 'timeDelta が非null');
  assert.equal(pipe.candidate.timeDelta.deltaMin, 30);
  assert.ok(Array.isArray(pipe.candidate.timeDelta.changes));
  for (const ch of pipe.candidate.timeDelta.changes) {
    assert.ok(DELTA_DIRS.has(ch.dir));
  }
});

test('pipeline: when.atUtcMs 無しなら timeDelta は null', async () => {
  const pipe = await runConsultationPipeline({
    birth: BIRTH, home: HOME, theme: 'love', mode: 'daily',
    when: { kind: 'today' },
    scope: { kind: 'point', point: { lat: 35.68, lng: 139.65, name: 'テスト地点' } },
    isFirst: true, excluded: [],
  });
  assert.ok(pipe.candidate);
  assert.equal(pipe.candidate.timeDelta, null);
});

test('pipeline: migration では timeDelta を出さない (atUtcMs があっても daily 限定)', async () => {
  const pipe = await runConsultationPipeline({
    birth: BIRTH, home: HOME, theme: 'work', mode: 'migration',
    when: { kind: 'in3yr', atUtcMs: Date.UTC(2026, 5, 15, 6, 0, 0) },
    scope: { kind: 'world' }, isFirst: true, excluded: [],
  });
  assert.ok(pipe.candidate);
  assert.equal(pipe.candidate.timeDelta, null);
});
