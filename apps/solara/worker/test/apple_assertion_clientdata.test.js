/**
 * validateAppleAssertionClientData (index.js _internal) の単体テスト。
 *
 * iOS assertion 経路 v3.1 (リクエスト毎チャレンジ方式) で、clientData JSON の
 * challenge / ts / uid 検証を担う純関数。DO/crypto 非依存なので Node から直接呼べる。
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { _internal } from '../src/index.js';

const { validateAppleAssertionClientData } = _internal;

const NOW = 1_700_000_000_000;
const CHALLENGE = 'HT1fk5pGgpTLNXfAXvtQwA7/vqIxJF0jeUU2fMspqhk=';

function clientData({ challenge = CHALLENGE, uid = 'apple:abc', ts = NOW } = {}) {
  return JSON.stringify({ challenge, uid, ts });
}

test('正常系: challenge/ts/uid 一致で ok', () => {
  const r = validateAppleAssertionClientData({
    clientDataStr: clientData(),
    consumedChallengeB64: CHALLENGE,
    bodyUid: 'apple:abc',
    now: NOW,
  });
  assert.deepEqual(r, { ok: true });
});

test('uid 両方空 (匿名前) でも ok', () => {
  const r = validateAppleAssertionClientData({
    clientDataStr: clientData({ uid: '' }),
    consumedChallengeB64: CHALLENGE,
    bodyUid: null,
    now: NOW,
  });
  assert.deepEqual(r, { ok: true });
});

test('不正な JSON → invalid_apple_clientdata', () => {
  const r = validateAppleAssertionClientData({
    clientDataStr: 'not json',
    consumedChallengeB64: CHALLENGE,
    bodyUid: 'apple:abc',
    now: NOW,
  });
  assert.equal(r.ok, false);
  assert.equal(r.error, 'invalid_apple_clientdata');
});

test('object でない JSON (数値) → invalid_apple_clientdata', () => {
  const r = validateAppleAssertionClientData({
    clientDataStr: '123',
    consumedChallengeB64: CHALLENGE,
    bodyUid: 'apple:abc',
    now: NOW,
  });
  assert.equal(r.error, 'invalid_apple_clientdata');
});

test('challenge 不一致 → challenge_mismatch (リプレイ/すり替え検出)', () => {
  const r = validateAppleAssertionClientData({
    clientDataStr: clientData({ challenge: 'AAAA' }),
    consumedChallengeB64: CHALLENGE,
    bodyUid: 'apple:abc',
    now: NOW,
  });
  assert.equal(r.error, 'challenge_mismatch');
});

test('challenge フィールド欠落 → challenge_mismatch', () => {
  const r = validateAppleAssertionClientData({
    clientDataStr: JSON.stringify({ uid: 'apple:abc', ts: NOW }),
    consumedChallengeB64: CHALLENGE,
    bodyUid: 'apple:abc',
    now: NOW,
  });
  assert.equal(r.error, 'challenge_mismatch');
});

test('ts が古すぎる (5分超) → clientdata_stale', () => {
  const r = validateAppleAssertionClientData({
    clientDataStr: clientData({ ts: NOW - 6 * 60 * 1000 }),
    consumedChallengeB64: CHALLENGE,
    bodyUid: 'apple:abc',
    now: NOW,
  });
  assert.equal(r.error, 'clientdata_stale');
});

test('ts が未来すぎる (5分超) → clientdata_stale', () => {
  const r = validateAppleAssertionClientData({
    clientDataStr: clientData({ ts: NOW + 6 * 60 * 1000 }),
    consumedChallengeB64: CHALLENGE,
    bodyUid: 'apple:abc',
    now: NOW,
  });
  assert.equal(r.error, 'clientdata_stale');
});

test('ts が非数値 → clientdata_stale', () => {
  const r = validateAppleAssertionClientData({
    clientDataStr: JSON.stringify({ challenge: CHALLENGE, uid: 'apple:abc', ts: 'x' }),
    consumedChallengeB64: CHALLENGE,
    bodyUid: 'apple:abc',
    now: NOW,
  });
  assert.equal(r.error, 'clientdata_stale');
});

test('uid 不一致 → uid_mismatch (なりすまし検出)', () => {
  const r = validateAppleAssertionClientData({
    clientDataStr: clientData({ uid: 'apple:attacker' }),
    consumedChallengeB64: CHALLENGE,
    bodyUid: 'apple:victim',
    now: NOW,
  });
  assert.equal(r.error, 'uid_mismatch');
});

test('clientData.uid 空だが body uid あり → uid_mismatch', () => {
  const r = validateAppleAssertionClientData({
    clientDataStr: clientData({ uid: '' }),
    consumedChallengeB64: CHALLENGE,
    bodyUid: 'apple:abc',
    now: NOW,
  });
  assert.equal(r.error, 'uid_mismatch');
});
