/**
 * Fortune ハンドラ (src/fortune.js) のテスト。
 *
 * 2026-05-27 追加: 「1日1回・固定」のサーバ側キャッシュ (DO fortune_readings) の挙動を中心に検証する。
 *
 * 主な検証:
 *   - cache hit (DO に該当行あり) → Gemini 呼ばずキャッシュ値を返す
 *   - cache miss → Gemini 呼出 → DO に書き戻す
 *   - 別 (category, lang, date) は独立キー
 *   - appUserId なし / 不正 date は cache スキップ (Gemini 直叩き)
 *   - Pro 化で 別 category 追加は新規 Gemini 呼出
 *
 * 実行: cd apps/solara/worker && node --test test/fortune.test.js
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { handleFortune, stripTransitLabel } from '../src/fortune.js';

test('stripTransitLabel: 日本語は「トランジットの」接頭辞を除去し惑星名だけ残す', () => {
  assert.equal(
    stripTransitLabel('トランジットの月が出生の火星を刺激し、プログレスの金星が支える。', 'ja'),
    '月が出生の火星を刺激し、プログレスの金星が支える。',
  );
  // 「トランジット」単独も除去。出生/プログレスは残す。
  assert.equal(stripTransitLabel('トランジット火星が活性化。', 'ja'), '火星が活性化。');
  assert.equal(stripTransitLabel('出生の月とプログレスの太陽。', 'ja'), '出生の月とプログレスの太陽。');
});

test('stripTransitLabel: 英語は transit/transiting を除去し natal/progressed は残す', () => {
  assert.equal(
    stripTransitLabel('Transiting Moon meets natal Mars, progressed Venus supports.', 'en'),
    'Moon meets natal Mars, progressed Venus supports.',
  );
});

const DEFAULT_BODY = {
  category: 'overall',
  lang: 'ja',
  natal: { sun: 10, moon: 100 },
  aspects: [],
  transitAspects: [{ natal: 'sun', moving: 'jupiter', type: 'trine', quality: 'soft' }],
  progressedAspects: [],
  patterns: {},
  date: '2026-05-27',
  __appUserId: 'user-abc-123',
};

/** Mock の callDo を返すヘルパー。store はテスト用の (key → value) Map。 */
function makeMockCallDo(store = new Map()) {
  const calls = [];
  const callDo = async (_env, path, payload) => {
    calls.push({ path, payload });
    if (path === '/fortune-reading-get') {
      const key = `${payload.appUserId}|${payload.localDate}|${payload.category}|${payload.lang || 'ja'}`;
      const v = store.get(key);
      if (!v) return { status: 200, body: { found: false } };
      return { status: 200, body: { found: true, ...v } };
    }
    if (path === '/fortune-reading-set') {
      const key = `${payload.appUserId}|${payload.localDate}|${payload.category}|${payload.lang || 'ja'}`;
      // ON CONFLICT DO NOTHING — 既存があれば上書きしない
      if (!store.has(key)) {
        store.set(key, { reading: payload.reading, advice: payload.advice, score: payload.score });
      }
      return { status: 200, body: { ok: true } };
    }
    return { status: 404, body: { error: 'unknown_path' } };
  };
  return { callDo, calls, store };
}

/** Gemini fetch をモックする env (実際の Gemini を叩かないため)。 */
function makeMockEnv({ geminiResponse = null } = {}) {
  const env = {
    GEMINI_API_KEY: 'mock-key',
    // ATTESTATION_DO は deps.callDo で差し替えるので不要
  };
  // Gemini 呼出の fetch を mock (callGemini は env.GEMINI_API_KEY をチェックするだけで fetch を直接叩く)
  // → globalThis.fetch を差し替える
  const fetchCalls = [];
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async (url, init) => {
    fetchCalls.push({ url, init });
    const body = geminiResponse || {
      candidates: [{ content: { parts: [{ text: JSON.stringify({
        reading: 'mocked reading 200 文字相当のサンプルテキスト。今日のトランジット主役。',
        advice: 'mocked advice テキスト',
      }) }] } }],
    };
    return {
      ok: true,
      status: 200,
      json: async () => body,
      text: async () => JSON.stringify(body),
    };
  };
  return {
    env,
    fetchCalls,
    restore() { globalThis.fetch = originalFetch; },
  };
}

// ── cache 動作 ──────────────────────────────────────────────

test('handleFortune: cache miss → Gemini 呼出 + DO 保存', async (t) => {
  const { callDo, calls, store } = makeMockCallDo();
  const { env, fetchCalls, restore } = makeMockEnv();
  t.after(() => restore());

  const r = await handleFortune({ ...DEFAULT_BODY }, env, { callDo });

  // get → miss だったので set される
  assert.equal(calls.filter((c) => c.path === '/fortune-reading-get').length, 1);
  assert.equal(calls.filter((c) => c.path === '/fortune-reading-set').length, 1);
  // Gemini も 1 回呼ばれる
  assert.equal(fetchCalls.length, 1);
  // DO に保存された
  const key = 'user-abc-123|2026-05-27|overall|ja';
  assert.ok(store.has(key));
  // レスポンスに reading/advice が乗っている
  assert.match(r.reading, /mocked reading/);
});

test('handleFortune: cache hit → Gemini 呼ばずキャッシュ値を返す', async (t) => {
  const store = new Map([
    ['user-abc-123|2026-05-27|overall|ja', { reading: '保存済 reading', advice: '保存済 advice', score: 72 }],
  ]);
  const { callDo, calls } = makeMockCallDo(store);
  const { env, fetchCalls, restore } = makeMockEnv();
  t.after(() => restore());

  const r = await handleFortune({ ...DEFAULT_BODY }, env, { callDo });

  // get のみ呼ばれて set は呼ばれない
  assert.equal(calls.filter((c) => c.path === '/fortune-reading-get').length, 1);
  assert.equal(calls.filter((c) => c.path === '/fortune-reading-set').length, 0);
  // Gemini は呼ばれない
  assert.equal(fetchCalls.length, 0);
  // キャッシュ値が返る
  assert.equal(r.reading, '保存済 reading');
  assert.equal(r.advice, '保存済 advice');
  assert.equal(r.score, 72);
  assert.equal(r.cached, true);
});

test('handleFortune: 同一ユーザ同一日でも別 category は独立キー (Free→Pro 昇格)', async (t) => {
  const { callDo, calls, store } = makeMockCallDo();
  const { env, restore } = makeMockEnv();
  t.after(() => restore());

  // 1 回目: overall
  await handleFortune({ ...DEFAULT_BODY, category: 'overall' }, env, { callDo });
  // 2 回目: 同日 same user で love (Pro 昇格)
  await handleFortune({ ...DEFAULT_BODY, category: 'love' }, env, { callDo });

  // どちらも cache miss → Gemini 2 回呼ばれ、DO に 2 行
  assert.equal(calls.filter((c) => c.path === '/fortune-reading-set').length, 2);
  assert.ok(store.has('user-abc-123|2026-05-27|overall|ja'));
  assert.ok(store.has('user-abc-123|2026-05-27|love|ja'));
});

test('handleFortune: 別言語 (ja/en) は独立キー', async (t) => {
  const { callDo, store } = makeMockCallDo();
  const { env, restore } = makeMockEnv();
  t.after(() => restore());

  await handleFortune({ ...DEFAULT_BODY, lang: 'ja' }, env, { callDo });
  await handleFortune({ ...DEFAULT_BODY, lang: 'en' }, env, { callDo });

  // 別 lang = 別キーで両方保存される
  assert.ok(store.has('user-abc-123|2026-05-27|overall|ja'));
  assert.ok(store.has('user-abc-123|2026-05-27|overall|en'));
});

test('handleFortune: 翌日になると新規生成 (date 違いで独立)', async (t) => {
  const { callDo, store } = makeMockCallDo();
  const { env, fetchCalls, restore } = makeMockEnv();
  t.after(() => restore());

  await handleFortune({ ...DEFAULT_BODY, date: '2026-05-27' }, env, { callDo });
  await handleFortune({ ...DEFAULT_BODY, date: '2026-05-28' }, env, { callDo });

  assert.equal(fetchCalls.length, 2);
  assert.ok(store.has('user-abc-123|2026-05-27|overall|ja'));
  assert.ok(store.has('user-abc-123|2026-05-28|overall|ja'));
});

// ── キャッシュ不適格時 ──────────────────────────────────────

test('handleFortune: appUserId なし → cache スキップ、Gemini 直叩き', async (t) => {
  const { callDo, calls } = makeMockCallDo();
  const { env, fetchCalls, restore } = makeMockEnv();
  t.after(() => restore());

  const body = { ...DEFAULT_BODY };
  delete body.__appUserId;
  await handleFortune(body, env, { callDo });

  // DO は一切呼ばれない
  assert.equal(calls.length, 0);
  // Gemini は呼ばれる
  assert.equal(fetchCalls.length, 1);
});

test('handleFortune: date が YYYY-MM-DD 以外 → cache スキップ', async (t) => {
  const { callDo, calls } = makeMockCallDo();
  const { env, fetchCalls, restore } = makeMockEnv();
  t.after(() => restore());

  await handleFortune({ ...DEFAULT_BODY, date: '5/27/2026' }, env, { callDo });

  assert.equal(calls.length, 0); // DO 呼ばれない
  assert.equal(fetchCalls.length, 1); // Gemini は呼ばれる
});

// ── プロフィール変更してもキャッシュは効く (= 「変更しない事にする」の根拠) ──

test('handleFortune: プロフィール (natal/aspects) が違っても同一 (user, date, category, lang) なら同じ結果', async (t) => {
  const store = new Map([
    ['user-abc-123|2026-05-27|overall|ja', { reading: '元の reading', advice: '元の advice', score: 60 }],
  ]);
  const { callDo, calls } = makeMockCallDo(store);
  const { env, fetchCalls, restore } = makeMockEnv();
  t.after(() => restore());

  // プロフィール変更 (natal や aspects が違う) で再 fetch しても
  const r = await handleFortune({
    ...DEFAULT_BODY,
    natal: { sun: 999, moon: 999 }, // 全然違う出生図
    aspects: [{ p1: 'sun', p2: 'mars', type: 'square', quality: 'hard' }],
    transitAspects: [], // 違うトランジット
  }, env, { callDo });

  // DO get で hit → Gemini 呼ばれない → 元の reading が返る
  assert.equal(fetchCalls.length, 0);
  assert.equal(r.reading, '元の reading');
  // set も呼ばれない (上書きしない)
  assert.equal(calls.filter((c) => c.path === '/fortune-reading-set').length, 0);
});

// ── 不正カテゴリ ────────────────────────────────────────────

test('handleFortune: 不正 category は throw', async (t) => {
  const { callDo } = makeMockCallDo();
  const { env, restore } = makeMockEnv();
  t.after(() => restore());

  await assert.rejects(
    () => handleFortune({ ...DEFAULT_BODY, category: 'bogus' }, env, { callDo }),
    /Unknown category/,
  );
});
