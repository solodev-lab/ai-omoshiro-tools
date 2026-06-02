/**
 * Relocation アングル近接 (A案) のテスト。
 *
 * 検証対象 (src/relocation.js):
 *   - handleRelocation のルーティング (model:'angle' → 新分岐 / 変化なし → Gemini 呼ばず空)
 *   - buildAnglePrompt (ハウス移動ヘッドライン / closer・farther / アングル星座変化 /
 *     吉凶禁止指示 / JSON schema / 度合い語の閾値が Dart と一致)
 *
 * buildAnglePrompt は純関数 (Gemini 不使用) なのでネットワークに出ない。
 * 実行: cd apps/solara/worker && node --test test/relocation_angle.test.js
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { handleRelocation, _internal } from '../src/relocation.js';

const { buildAnglePrompt, magnitudeWordJP, magnitudeWordEN } = _internal;

test('handleRelocation: 変化が空なら Gemini を呼ばず空レスポンス', async () => {
  const res = await handleRelocation(
    { model: 'angle', planets: [], angles: [] },
    {}, // env (GEMINI_API_KEY 無し) でも呼ばれないので OK
  );
  assert.deepEqual(res, { planets: [], angles: [], summary: '', lang: 'ja' });
});

test('handleRelocation: planets[] が来たら angle 分岐 (空なら空)', async () => {
  // model 省略でも planets[] があれば新分岐に入る (後方互換のため)。
  const res = await handleRelocation({ planets: [], angles: [] }, {});
  assert.equal(res.summary, '');
  assert.ok(Array.isArray(res.planets));
});

test('buildAnglePrompt: 何も無ければ null', () => {
  assert.equal(buildAnglePrompt({ planets: [], angles: [], lang: 'ja' }), null);
});

test('buildAnglePrompt: ハウス移動はヘッドライン文言', () => {
  const p = buildAnglePrompt({
    planets: [
      { planet: 'sun', natalHouse: 10, reloHouse: 9, nearestAngle: 'mc', deltaDeg: 1.2, direction: 'farther' },
    ],
    angles: [],
    lang: 'ja',
  });
  assert.ok(p.includes('ハウス移動'));
  assert.ok(p.includes('太陽'));
  assert.ok(p.includes('キャリア') || p.includes('社会的地位'));
});

test('buildAnglePrompt: closer / farther を表現', () => {
  const p = buildAnglePrompt({
    planets: [
      { planet: 'venus', natalHouse: 5, reloHouse: 5, nearestAngle: 'dsc', deltaDeg: -4.0, direction: 'closer' },
      { planet: 'mars', natalHouse: 7, reloHouse: 7, nearestAngle: 'asc', deltaDeg: 8.0, direction: 'farther' },
    ],
    angles: [],
    lang: 'ja',
  });
  assert.ok(p.includes('近づく'));
  assert.ok(p.includes('遠ざかる'));
  assert.ok(p.includes('金星'));
  assert.ok(p.includes('火星'));
  // 吉凶禁止の指示が含まれる
  assert.ok(p.includes('吉凶'));
});

test('buildAnglePrompt: アングル星座変化を含む + JSON schema', () => {
  const p = buildAnglePrompt({
    planets: [
      { planet: 'moon', natalHouse: 4, reloHouse: 4, nearestAngle: 'ic', deltaDeg: -1.0, direction: 'closer' },
    ],
    angles: [{ angle: 'asc', fromSign: 3, toSign: 4 }], // 蟹→獅子
    lang: 'ja',
  });
  assert.ok(p.includes('蟹座'));
  assert.ok(p.includes('獅子座'));
  assert.ok(p.includes('"planets"'));
  assert.ok(p.includes('"angles"'));
  assert.ok(p.includes('"summary"'));
  assert.ok(p.includes('"planet": "moon"'));
  assert.ok(p.includes('"angle": "asc"'));
});

test('buildAnglePrompt: 英語', () => {
  const p = buildAnglePrompt({
    planets: [
      { planet: 'sun', natalHouse: 10, reloHouse: 10, nearestAngle: 'mc', deltaDeg: -3.0, direction: 'closer' },
    ],
    angles: [],
    lang: 'en',
  });
  assert.ok(p.includes('CLOSER'));
  assert.ok(p.includes('MC'));
  assert.ok(p.includes('"summary"'));
});

test('度合い語の閾値 (プロンプトの度合い表現用)', () => {
  assert.equal(magnitudeWordJP(0.3), 'ごくわずかに');
  assert.equal(magnitudeWordJP(1.0), 'わずかに');
  assert.equal(magnitudeWordJP(4.0), 'はっきりと');
  assert.equal(magnitudeWordJP(10.0), '大きく');
  assert.equal(magnitudeWordEN(0.3), 'very slightly');
  assert.equal(magnitudeWordEN(1.0), 'slightly');
  assert.equal(magnitudeWordEN(4.0), 'noticeably');
  assert.equal(magnitudeWordEN(10.0), 'greatly');
});
