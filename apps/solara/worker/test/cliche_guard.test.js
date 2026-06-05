/**
 * cliche_guard (src/cliche_guard.js) のテスト。
 * 英語生成のクリシェ検出 + 再生成ディレクティブ生成を検証する。
 * 実行: cd apps/solara/worker && node --test test/cliche_guard.test.js
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { clichesIn, clicheRetryDirective } from '../src/cliche_guard.js';

test('clichesIn: 代表的なクリシェを検出する', () => {
  assert.deepEqual(clichesIn('the rich tapestry of connection', 'en'), ['tapestry']);
  assert.deepEqual(clichesIn('a quiet unfolding of affection', 'en'), ['unfold/unfolding']);
  assert.deepEqual(clichesIn('pour your true self into these bonds', 'en'), ['true self/selves']);
  assert.deepEqual(clichesIn('a path to deeper understanding', 'en'), ['deeper understanding']);
  assert.deepEqual(clichesIn('a sense of good fortune', 'en'), ['good fortune']);
});

test('clichesIn: 複数ヒットは重複排除して返す', () => {
  const hits = clichesIn('woven through the tapestry, trust the universe and embrace change', 'en');
  assert.ok(hits.includes('woven'));
  assert.ok(hits.includes('tapestry'));
  assert.ok(hits.includes('trust the universe'));
  assert.ok(hits.includes('embrace vulnerability/change'));
});

test('clichesIn: クリーンな文は空配列', () => {
  assert.deepEqual(clichesIn('there is room to lower your guard a little; what is real in you can be seen', 'en'), []);
});

test('clichesIn: 日本語 (lang=ja) は適用外で常に空', () => {
  assert.deepEqual(clichesIn('tapestry good fortune unfolding', 'ja'), []);
});

test('clichesIn: 大文字小文字を無視する', () => {
  assert.deepEqual(clichesIn('SERENDIPITY awaits', 'en'), ['serendipity']);
});

test('clichesIn: 空入力は空配列', () => {
  assert.deepEqual(clichesIn('', 'en'), []);
  assert.deepEqual(clichesIn(null, 'en'), []);
});

test('clicheRetryDirective: ヒット語を名指しした書き直し指示を返す', () => {
  const d = clicheRetryDirective(['tapestry', 'good fortune']);
  assert.match(d, /REWRITE REQUIRED/);
  assert.match(d, /tapestry, good fortune/);
});

test('clicheRetryDirective: 空配列は空文字', () => {
  assert.equal(clicheRetryDirective([]), '');
});
