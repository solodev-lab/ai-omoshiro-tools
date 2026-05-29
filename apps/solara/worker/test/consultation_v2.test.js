/**
 * Stella 相談 V2 (Phase 2: Gemini ナレーション層) のテスト。
 * 設計: project_solara_consultation_full_integration.md「実装ロードマップ Phase 2」。
 *
 * 検証対象 (src/consultation_v2.js):
 *   - placeReference (この地点 / 店舗名+種類 / 方角 / 都市名)
 *   - buildConsultationPrompt (吉凶禁止/読心禁止/km本文禁止/文体ハイブリッド/isFirst枠)
 *   - humanizeTimeWindow / timeWindowPromptText (時計表示なし)
 *   - handleConsultationV2 (Gemini mock でパース・isFirst 枠・静的フォールバック・exhausted)
 *
 * Gemini は注入 (deps.callGeminiFn) で mock。ネットワークに出ない。
 * 実行: cd apps/solara/worker && node --test test/consultation_v2.test.js
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { handleConsultationV2, _internal } from '../src/consultation_v2.js';

const { placeReference, buildConsultationPrompt, humanizeTimeWindow, timeWindowPromptText } = _internal;

const BIRTH = { date: '1990-06-15', time: '14:30', lat: 35.68, lng: 139.65, tzName: 'Asia/Tokyo' };
const HOME = { lat: 35.68, lng: 139.65 };
const ENV = { GEMINI_API_KEY: 'test-key' };

/** 妥当な JSON を返す mock Gemini。プロンプトを捕捉できる。 */
function mockGemini(captured) {
  return async (key, prompt) => {
    if (captured) captured.prompt = prompt;
    return JSON.stringify({
      innerSeason: '今のあなたは根に意識が向かう内的な季節。',
      intro: 'このテーマで候補を見てみましょう。',
      outro: 'ここに並んだ候補は世界の全部ではありません。見えていない場所もあります。',
      candidate: {
        characterHeadline: '金星が前に立つ場',
        energyLabels: ['金星 MC・愛と調和の軸'],
        narrative: '観察ブロックである。語りかけのブロックです。',
      },
    });
  };
}

// ── placeReference ──────────────────────────────────────────

test('placeReference: 座標のみ → 「この地点」(地名に言い換えない)', () => {
  const r = placeReference({ lat: 35, lng: 139, isPoint: true });
  assert.equal(r.ref, 'この地点');
  assert.match(r.guidance, /言い換えない/);
});

test('placeReference: 店舗 (placeType) → 店名 + 種類', () => {
  const r = placeReference({ name: '青いカフェ', placeType: 'cafe' });
  assert.equal(r.ref, '青いカフェ (カフェ)');
  assert.match(r.guidance, /発明しない/);
});

test('placeReference: 方角 → 「○の方角」(地名を出さない)', () => {
  const r = placeReference({ bearing: 'SW' });
  assert.equal(r.ref, '南西の方角');
  assert.match(r.guidance, /地名・都市名は出さない/);
});

test('placeReference: 都市名 → そのまま', () => {
  const r = placeReference({ name: '京都', country: 'JP' });
  assert.equal(r.ref, '京都');
});

test('placeReference: placeKind=named (検索の具体地点) → 店名そのまま、都市名に丸めない', () => {
  const r = placeReference({ name: 'JR名古屋高島屋', placeKind: 'named' });
  assert.equal(r.ref, 'JR名古屋高島屋');
  assert.match(r.guidance, /そのまま使う/);
  assert.match(r.guidance, /丸めたりしない/);
});

test('placeReference: placeKind=saved (登録地) → 「(登録名)」という場所', () => {
  const r = placeReference({ name: 'マイ秘密基地', placeKind: 'saved' });
  assert.equal(r.ref, '「マイ秘密基地」という場所');
  assert.match(r.guidance, /登録名で呼ぶ/);
});

test('placeReference: placeType > placeKind=named (店舗種別がある検索結果は種類も併記)', () => {
  // SearchHit に種別が乗ったケース (placeType も placeKind='named' も両方ある)
  // → placeType 分岐が先で「店名 (種類)」になる。これは要望どおり (名前を捨てない)。
  const r = placeReference({ name: '青いカフェ', placeType: 'cafe', placeKind: 'named' });
  assert.equal(r.ref, '青いカフェ (カフェ)');
});

// ── timeWindow ──────────────────────────────────────────────

test('humanizeTimeWindow: single / rhythm を JP ラベル化', () => {
  assert.equal(humanizeTimeWindow({ kind: 'single', bucket: 'evening', planet: 'venus', angle: 'mc' }).label, '夕方');
  const r = humanizeTimeWindow({ kind: 'rhythm', items: [{ bucket: 'morning' }, { bucket: 'night' }] });
  assert.deepEqual(r.items.map((i) => i.label), ['朝', '夜']);
  assert.equal(humanizeTimeWindow(null), null);
});

test('timeWindowPromptText: 時計の数字・TZ名を含まない (現地時間帯のみ)', () => {
  const txt = timeWindowPromptText({ kind: 'single', bucket: 'night', planet: 'moon', angle: 'ic' });
  assert.doesNotMatch(txt, /\d{1,2}:\d{2}/); // 05:02 のような時計表示なし
  assert.doesNotMatch(txt, /JST|UTC/);
  assert.match(txt, /夜/);
});

// ── buildConsultationPrompt ─────────────────────────────────

function fakePipe({ isFirst = true, honestQuiet = false, factors = null } = {}) {
  return {
    isFirst,
    candidate: {
      name: 'この地点', lat: 34.69, lng: 135.5, isPoint: true,
      factors: factors || [
        { kind: 'line', planet: 'venus', angle: 'mc', aspect: 'trine', frame: 'natal', quality: 'soft', distanceKm: 80 },
        { kind: 'line', planet: 'mars', angle: 'asc', aspect: 'square', frame: 'transit', quality: 'hard', distanceKm: 210 },
      ],
      honestQuiet,
      relocation: { planetHouses: { venus: 7 } },
    },
    timeWindow: { kind: 'single', bucket: 'evening', planet: 'venus', angle: 'mc' },
    innerSeason: { progMoonSignJP: '蟹', progMoonHouse: 4, progSunSignJP: '蟹', turningPoint: null },
    evidence: { factors: [], km: [], note: null },
  };
}

test('prompt: 設計思想ガード (吉凶禁止/読心禁止/km本文禁止/文体ハイブリッド) を含む', () => {
  const p = buildConsultationPrompt({ pipe: fakePipe(), theme: 'love', mode: 'daily', withWhom: '', wish: '' });
  assert.match(p, /吉凶判定をしない/);
  assert.match(p, /読心の禁止/);
  assert.match(p, /距離 \(km/);
  assert.match(p, /文体ハイブリッド/);
  assert.match(p, /Soft.*Hard|独立した 2 エネルギー/);
});

test('prompt: isFirst=true は innerSeason/intro/outro スキーマを含む', () => {
  const p = buildConsultationPrompt({ pipe: fakePipe({ isFirst: true }), theme: 'love', mode: 'daily', withWhom: '', wish: '' });
  assert.match(p, /"innerSeason":/);
  assert.match(p, /"intro":/);
  assert.match(p, /"outro":/);
});

test('prompt: isFirst=false は candidate だけ (intro/outro を出さない指示)', () => {
  const p = buildConsultationPrompt({ pipe: fakePipe({ isFirst: false }), theme: 'love', mode: 'daily', withWhom: '', wish: '' });
  assert.doesNotMatch(p, /"intro":/);
  assert.match(p, /追加候補/);
});

test('prompt: honestQuiet は「静かな場を正直に」ガードを足す', () => {
  const p = buildConsultationPrompt({ pipe: fakePipe({ honestQuiet: true }), theme: 'love', mode: 'travel', withWhom: '', wish: '' });
  assert.match(p, /静かな場|捏造/);
});

test('prompt: withWhom / wish の自由記述がラベル付きで入る', () => {
  const p = buildConsultationPrompt({ pipe: fakePipe(), theme: 'love', mode: 'daily', withWhom: '妻と', wish: '距離を縮めたい' });
  assert.match(p, /妻と/);
  assert.match(p, /距離を縮めたい/);
});

// ── handleConsultationV2 (統合, Gemini mock) ────────────────

test('handler: isFirst → candidate + intro/outro/innerSeason を返す', async () => {
  const cap = {};
  const r = await handleConsultationV2(
    { birth: BIRTH, home: HOME, theme: 'love', mode: 'daily', when: { kind: 'date', date: '2026-07-10' }, scope: { kind: 'point', point: { lat: 34.69, lng: 135.5, name: '青いカフェ', placeType: 'cafe' } }, isFirst: true, excluded: [] },
    ENV, { callGeminiFn: mockGemini(cap) },
  );
  assert.equal(r.model, 'gemini-2.5-flash');
  assert.equal(r.candidate.name, '青いカフェ');
  assert.equal(r.candidate.placeType, 'cafe');
  assert.ok(r.candidate.narrative.length > 0);
  assert.ok(r.candidate.characterHeadline.length > 0);
  assert.ok(r.intro && r.outro && r.innerSeason);
  assert.equal(r.candidate.timeWindow.label, BUCKET_LABEL(r.candidate.timeWindow.bucket));
  // プロンプトに店舗名+種類が入っている
  assert.match(cap.prompt, /青いカフェ \(カフェ\)/);
});

function BUCKET_LABEL(b) {
  return { morning: '朝', midday: '昼', evening: '夕方', night: '夜', lateNight: '夜更け' }[b];
}

test('handler: when.timeBand=night 指定時、UI timeWindow.label もユーザー選択 (夜) に一致する', async () => {
  // narrative はユーザー指定時間帯を主役にする仕様 (prompt:178-181)。
  // 同時に UI ラベルもユーザー指定に合わせる (= 本文「夜」/ラベル「昼」のズレ防止)。
  const cap = {};
  const r = await handleConsultationV2(
    {
      birth: BIRTH, home: HOME, theme: 'communication', mode: 'daily',
      when: { kind: 'date', date: '2026-07-10', timeBand: 'night' },
      scope: { kind: 'point', point: { lat: 35.18, lng: 136.91, name: '名古屋' } },
      isFirst: true, excluded: [],
    },
    ENV, { callGeminiFn: mockGemini(cap) },
  );
  assert.equal(r.candidate.timeWindow.kind, 'single');
  assert.equal(r.candidate.timeWindow.bucket, 'night');
  assert.equal(r.candidate.timeWindow.label, '夜');
  // narrative プロンプトにも userTimeBand が「主役にする」として渡る
  assert.match(cap.prompt, /相談者の予定時間帯: 夜/);
});

test('handler: when.timeBand 未指定なら従来通りエンジン計算の bucket を返す', async () => {
  const r = await handleConsultationV2(
    {
      birth: BIRTH, home: HOME, theme: 'love', mode: 'daily',
      when: { kind: 'date', date: '2026-07-10' },
      scope: { kind: 'point', point: { lat: 35.68, lng: 139.69, name: '東京' } },
      isFirst: true, excluded: [],
    },
    ENV, { callGeminiFn: mockGemini() },
  );
  assert.equal(r.candidate.timeWindow.kind, 'single');
  // bucket は VALID_BANDS のいずれか (エンジン計算結果)
  assert.ok(['morning', 'midday', 'evening', 'night', 'lateNight'].includes(r.candidate.timeWindow.bucket));
  assert.equal(r.candidate.timeWindow.label, BUCKET_LABEL(r.candidate.timeWindow.bucket));
});

test('handler: 不正な timeBand は無視してエンジン計算 bucket にフォールバック', async () => {
  const r = await handleConsultationV2(
    {
      birth: BIRTH, home: HOME, theme: 'love', mode: 'daily',
      when: { kind: 'date', date: '2026-07-10', timeBand: 'bogus' },
      scope: { kind: 'point', point: { lat: 35.68, lng: 139.69, name: '東京' } },
      isFirst: true, excluded: [],
    },
    ENV, { callGeminiFn: mockGemini() },
  );
  assert.ok(['morning', 'midday', 'evening', 'night', 'lateNight'].includes(r.candidate.timeWindow.bucket));
});

test('handler: isFirst=false は intro/outro/innerSeason を付けない', async () => {
  const r = await handleConsultationV2(
    { birth: BIRTH, home: HOME, theme: 'work', mode: 'daily', when: { kind: 'date', date: '2026-07-10' }, scope: { kind: 'bearing', radiusKm: 100 }, isFirst: false, excluded: [] },
    ENV, { callGeminiFn: mockGemini() },
  );
  assert.ok(r.candidate);
  assert.equal(r.intro, undefined);
  assert.equal(r.outro, undefined);
  assert.equal(r.innerSeason, undefined);
});

test('handler: Gemini 例外 → 静的フォールバック (fallback:true, candidate あり)', async () => {
  const throwing = async () => { throw new Error('gemini down'); };
  const r = await handleConsultationV2(
    { birth: BIRTH, home: HOME, theme: 'love', mode: 'daily', when: { kind: 'date', date: '2026-07-10' }, scope: { kind: 'bearing', radiusKm: 50 }, isFirst: true, excluded: [] },
    ENV, { callGeminiFn: throwing },
  );
  assert.equal(r.fallback, true);
  assert.equal(r.model, 'fallback');
  assert.ok(r.candidate && r.candidate.characterHeadline);
  assert.ok(r.intro !== undefined); // isFirst なので intro 枠あり
  assert.ok(r.evidence); // 構造データは常に付く
});

test('handler: GEMINI_API_KEY 無し → 静的フォールバック', async () => {
  const r = await handleConsultationV2(
    { birth: BIRTH, home: HOME, theme: 'love', mode: 'daily', when: { kind: 'date', date: '2026-07-10' }, scope: { kind: 'bearing', radiusKm: 50 }, isFirst: true, excluded: [] },
    { /* no key */ }, { callGeminiFn: mockGemini() },
  );
  assert.equal(r.model, 'fallback');
  assert.equal(r.fallback, true);
});

test('handler: excluded で出し尽くすと exhausted', async () => {
  const allBearings = [
    '北', '北北東', '北東', '東北東', '東', '東南東', '南東', '南南東',
    '南', '南南西', '南西', '西南西', '西', '西北西', '北西', '北北西',
  ];
  const r = await handleConsultationV2(
    { birth: BIRTH, home: HOME, theme: 'love', mode: 'daily', when: { kind: 'date', date: '2026-07-10' }, scope: { kind: 'bearing', radiusKm: 50 }, isFirst: false, excluded: allBearings },
    ENV, { callGeminiFn: mockGemini() },
  );
  assert.equal(r.exhausted, true);
});

test('handler D1: おでかけ=実在の町 (candidateMeta に方角ラベル + 本文は町名を名指し / poolSource=d1-local)', async () => {
  // bounding-box クエリに対し東京近郊の実在の町を返す偽 D1。
  const fakeDB = {
    prepare: () => ({
      bind: () => ({
        async all() {
          return { results: [
            { name: '鎌倉', ascii: 'Kamakura', lat: 35.31, lng: 139.55, country: 'JP', region: '神奈川県', population: 172000 },
            { name: '横浜', ascii: 'Yokohama', lat: 35.44, lng: 139.64, country: 'JP', region: '神奈川県', population: 3700000 },
          ] };
        },
      }),
    }),
  };
  const captured = {};
  const r = await handleConsultationV2(
    { birth: BIRTH, home: HOME, theme: 'love', mode: 'daily', when: { kind: 'date', date: '2026-07-10' }, scope: { kind: 'bearing', radiusKm: 50 }, isFirst: false, excluded: [] },
    { ...ENV, DB: fakeDB }, { callGeminiFn: mockGemini(captured) },
  );
  // Gemini 成功パスは candidateMeta を out.candidate にマージする (candidateMeta は削除)。
  assert.equal(r.meta.poolSource, 'd1-local');
  assert.ok(['鎌倉', '横浜'].includes(r.candidate.name)); // 合成方位ではなく実在の町名
  assert.ok(r.candidate.directionFromHome); // 表示用「南西」等
  assert.ok(!r.candidate.bearing); // 方角だけの読みに落とさない
  assert.equal(typeof r.candidate.distanceKm, 'number');
  // placeReference は実在の町なので「町名をそのまま使う」分岐 → プロンプトに町名が出る
  assert.ok(captured.prompt.includes(r.candidate.name));
});

test('handler: 非 ja lang は throw', async () => {
  await assert.rejects(() => handleConsultationV2(
    { birth: BIRTH, home: HOME, theme: 'love', mode: 'daily', lang: 'en' }, ENV, { callGeminiFn: mockGemini() },
  ));
});

test('handler: 不正 JSON (パース不能) → 静的フォールバック', async () => {
  const garbage = async () => 'これはJSONではありません';
  const r = await handleConsultationV2(
    { birth: BIRTH, home: HOME, theme: 'money', mode: 'migration', when: { kind: 'in1yr' }, scope: { kind: 'region', regionGroup: '日本' }, isFirst: true, excluded: [] },
    ENV, { callGeminiFn: garbage },
  );
  assert.equal(r.fallback, true);
});
