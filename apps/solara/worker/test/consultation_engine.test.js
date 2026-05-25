/**
 * Stella 相談 計算パイプライン (Phase 1) のテスト。
 * 設計: project_solara_consultation_full_integration.md「実装ロードマップ Phase 1」。
 *
 * 検証対象 (src/consultation_engine.js):
 *   - 時間帯バケット (現地太陽時) / houseOf / sampleDays / migrationHorizonDate
 *   - 候補プール (bearing/world/region/point/radius) / homeCountry / offsetByBearing
 *   - scoreCandidate (近接ファクター + Soft/Hard 保持 + honestQuiet)
 *   - diversifyOrder / selectCandidate (案C + 正直フォールバック + excluded 前進)
 *   - runConsultationPipeline (daily/travel/migration, 出生時刻不明 degrade)
 *
 * 実行: cd apps/solara/worker && node --test test/consultation_engine.test.js
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { runConsultationPipeline, _internal } from '../src/consultation_engine.js';

const {
  houseOf, timeOfDayBucket, bucketFromUtcAt,
  sampleDays, migrationHorizonDate, transitInstants,
  buildCandidatePool, homeCountry, offsetByBearing,
  scoreCandidate, diversifyOrder, selectCandidate,
} = _internal;

const BIRTH = { date: '1990-06-15', time: '14:30', lat: 35.68, lng: 139.65, tzName: 'Asia/Tokyo' };
const HOME = { lat: 35.68, lng: 139.65 };

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

test('buildCandidatePool: bearing=8方角 / world=全都市 / point=1件', () => {
  const bearings = buildCandidatePool({ scope: { kind: 'bearing', radiusKm: 50 }, home: HOME, mode: 'daily' });
  assert.equal(bearings.length, 8);
  assert.ok(bearings.every((b) => b.bearing));

  const world = buildCandidatePool({ scope: { kind: 'world' }, home: HOME, mode: 'migration' });
  assert.ok(world.length > 700);

  const point = buildCandidatePool({ scope: { kind: 'point', point: { lat: 34.69, lng: 135.5, name: 'カフェX', placeType: 'cafe' } }, home: HOME, mode: 'daily' });
  assert.equal(point.length, 1);
  assert.equal(point[0].isPoint, true);
  assert.equal(point[0].placeType, 'cafe');
});

test('buildCandidatePool: region は regionGroup で絞り込む / radius は距離で絞る', () => {
  const jp = buildCandidatePool({ scope: { kind: 'region', regionGroup: '日本' }, home: HOME, mode: 'migration' });
  assert.ok(jp.length > 50 && jp.every((c) => c.country === 'JP'));

  const near = buildCandidatePool({ scope: { kind: 'radius', radiusKm: 100 }, home: HOME, mode: 'travel' });
  const far = buildCandidatePool({ scope: { kind: 'radius', radiusKm: 1000 }, home: HOME, mode: 'travel' });
  assert.ok(near.length < far.length);
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

// ── diversifyOrder / selectCandidate ────────────────────────

function fakeCand(name, planet, angle, quality, strength) {
  return { name, nameEN: name, factors: [{ planet, angle, quality, strength, distanceKm: Math.round((1 - strength) * 800) }], topStrength: strength, honestQuiet: strength < 0.18 };
}

test('diversifyOrder: 1番手=最強、以降は別 signature 族を優先', () => {
  const scored = [
    fakeCand('A', 'venus', 'mc', 'neutral', 0.9),
    fakeCand('B', 'venus', 'mc', 'neutral', 0.85), // A と同族
    fakeCand('C', 'mars', 'asc', 'soft', 0.6),     // 別族
  ];
  const ordered = diversifyOrder(scored);
  assert.equal(ordered[0].name, 'A'); // 最強
  assert.equal(ordered[1].name, 'C'); // 別族を B より優先
  assert.equal(ordered[2].name, 'B'); // 同族は最後 (正直に強さ順)
});

test('diversifyOrder: 全部同族なら素直に強さ順 (作られた多様性をしない)', () => {
  const scored = [
    fakeCand('A', 'venus', 'mc', 'neutral', 0.9),
    fakeCand('B', 'venus', 'mc', 'neutral', 0.8),
    fakeCand('C', 'venus', 'mc', 'neutral', 0.7),
  ];
  const ordered = diversifyOrder(scored);
  assert.deepEqual(ordered.map((c) => c.name), ['A', 'B', 'C']);
});

test('selectCandidate: excluded を飛ばして次を返す / 全除外で exhausted', () => {
  const scored = [
    fakeCand('A', 'venus', 'mc', 'neutral', 0.9),
    fakeCand('C', 'mars', 'asc', 'soft', 0.6),
  ];
  const first = selectCandidate(scored, []);
  assert.equal(first.candidate.name, 'A');
  const second = selectCandidate(scored, ['A']);
  assert.equal(second.candidate.name, 'C');
  const none = selectCandidate(scored, ['A', 'C']);
  assert.equal(none.candidate, null);
});

test('selectCandidate: 具体地点 (isPoint) は単一候補で常に返す', () => {
  const scored = [{ name: 'カフェX', nameEN: 'cafeX', isPoint: true, factors: [], topStrength: 0, honestQuiet: true }];
  const r = selectCandidate(scored, ['カフェX']);
  assert.equal(r.single, true);
  assert.equal(r.candidate.name, 'カフェX'); // 既出でも返す
});

// ── runConsultationPipeline (統合) ──────────────────────────

test('pipeline daily: 候補 + factors + timeWindow + innerSeason + evidence を返す', () => {
  const r = runConsultationPipeline({
    birth: BIRTH, home: HOME, theme: 'love', mode: 'daily',
    when: { kind: 'date', date: '2026-07-10' }, scope: { kind: 'bearing', radiusKm: 50 },
    isFirst: true, excluded: [],
  });
  assert.ok(r.candidate);
  assert.ok(r.candidate.bearing); // 方角候補
  assert.ok(Array.isArray(r.candidate.factors));
  assert.ok(r.innerSeason.progMoonSignJP);
  assert.ok(r.innerSeason.progMoonHouse >= 1 && r.innerSeason.progMoonHouse <= 12);
  assert.ok(Array.isArray(r.evidence.factors) && r.evidence.factors.length > 0);
  // daily は時刻不明でないので note なし
  assert.equal(r.evidence.note, null);
});

test('pipeline diversity: excluded で別の候補に進む', () => {
  const base = {
    birth: BIRTH, home: HOME, theme: 'work', mode: 'daily',
    when: { kind: 'date', date: '2026-07-10' }, scope: { kind: 'bearing', radiusKm: 100 },
  };
  const first = runConsultationPipeline({ ...base, isFirst: true, excluded: [] });
  const second = runConsultationPipeline({ ...base, isFirst: false, excluded: [first.candidate.name] });
  assert.ok(second.candidate);
  assert.notEqual(second.candidate.name, first.candidate.name);
});

test('pipeline migration: transit 不使用 (factor は natal/progressed のみ) + リロケハウス', () => {
  const r = runConsultationPipeline({
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

test('pipeline 出生時刻不明 migration: ハウス/リロケを使わず帯で読む + 注記', () => {
  const r = runConsultationPipeline({
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

test('pipeline 出生時刻不明 daily: フル品質 (注記なし) — 設計 B', () => {
  const r = runConsultationPipeline({
    birth: { ...BIRTH, time: null, timeUnknown: true }, home: HOME, theme: 'love', mode: 'daily',
    when: { kind: 'date', date: '2026-07-10' }, scope: { kind: 'bearing', radiusKm: 50 },
    isFirst: true, excluded: [],
  });
  assert.ok(r.candidate);
  assert.equal(r.evidence.note, null); // おでかけは時刻不明でも注記なし
});

test('pipeline point scope: 指定地点を single で返す (placeType 引き継ぎ)', () => {
  const r = runConsultationPipeline({
    birth: BIRTH, home: HOME, theme: 'love', mode: 'daily',
    when: { kind: 'today' }, scope: { kind: 'point', point: { lat: 34.69, lng: 135.5, name: 'カフェX', placeType: 'cafe' } },
    isFirst: true, excluded: [],
  });
  assert.equal(r.single, true);
  assert.equal(r.candidate.placeType, 'cafe');
  assert.equal(r.candidate.name, 'カフェX');
});

test('pipeline: world migration が CPU 予算内 (<3s)', () => {
  const t0 = Date.now();
  runConsultationPipeline({
    birth: BIRTH, home: HOME, theme: 'work', mode: 'migration',
    when: { kind: 'in5yrPlus' }, scope: { kind: 'world' }, isFirst: true, excluded: [],
  });
  const ms = Date.now() - t0;
  assert.ok(ms < 3000, `pipeline took ${ms}ms`);
});

test('pipeline: 不正 theme / mode は throw', () => {
  assert.throws(() => runConsultationPipeline({ birth: BIRTH, home: HOME, theme: 'bogus', mode: 'daily' }));
  assert.throws(() => runConsultationPipeline({ birth: BIRTH, home: HOME, theme: 'love', mode: 'bogus' }));
});
