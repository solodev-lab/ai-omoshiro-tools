/**
 * Place Name Search の rankPreference (中心点/知名度) 切替テスト。
 *
 * 検証対象 (src/search.js searchGooglePlacesNew):
 *   - rank='distance' (中心点) → reqBody.rankPreference = 'DISTANCE'
 *   - rank='relevance' (知名度) / 未指定 → rankPreference を付けない (Google 既定)
 *   - どちらでも pageSize は 20 のまま (件数を増やさない = 課金は 1 検索 1 req)
 *   - locationBias は lat/lng があれば付く
 *
 * fetch を mock してネットワークに出ない。
 * 実行: cd apps/solara/worker && node --test test/search.test.js
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { searchPlace } from '../src/search.js';

const ENV = { GOOGLE_PLACES_KEY: 'test-key' };

// Google Places (New) の成功レスポンスを返す fetch mock。
// 送信された body を captured に積む。
function mockFetch(captured) {
  return async (url, init) => {
    captured.push({ url, body: JSON.parse(init.body) });
    return {
      ok: true,
      status: 200,
      async json() {
        return {
          places: [
            {
              id: 'p1',
              displayName: { text: 'テストカフェ' },
              formattedAddress: '名古屋市東区',
              location: { latitude: 35.18, longitude: 136.91 },
              types: ['cafe'],
            },
          ],
        };
      },
      async text() {
        return '';
      },
    };
  };
}

test('rank=distance → rankPreference: DISTANCE を付ける', async () => {
  const captured = [];
  const orig = globalThis.fetch;
  globalThis.fetch = mockFetch(captured);
  try {
    const res = await searchPlace('カフェ', ENV, {
      lat: 35.17,
      lng: 136.88,
      rank: 'distance',
    });
    assert.equal(res.source, 'google');
    assert.equal(captured.length, 1);
    assert.equal(captured[0].body.rankPreference, 'DISTANCE');
    assert.equal(captured[0].body.pageSize, 20); // 件数は増やさない
    assert.ok(captured[0].body.locationBias, 'locationBias が付く');
  } finally {
    globalThis.fetch = orig;
  }
});

test('rank=relevance → rankPreference を付けない (Google 既定=知名度)', async () => {
  const captured = [];
  const orig = globalThis.fetch;
  globalThis.fetch = mockFetch(captured);
  try {
    await searchPlace('カフェ', ENV, {
      lat: 35.17,
      lng: 136.88,
      rank: 'relevance',
    });
    assert.equal(
      'rankPreference' in captured[0].body,
      false,
      'relevance では rankPreference を付けない',
    );
    assert.equal(captured[0].body.pageSize, 20);
  } finally {
    globalThis.fetch = orig;
  }
});

test('rank 未指定 → rankPreference を付けない (旧クライアント互換)', async () => {
  const captured = [];
  const orig = globalThis.fetch;
  globalThis.fetch = mockFetch(captured);
  try {
    await searchPlace('カフェ', ENV, { lat: 35.17, lng: 136.88 });
    assert.equal('rankPreference' in captured[0].body, false);
  } finally {
    globalThis.fetch = orig;
  }
});

test('lat/lng なし → locationBias を付けない', async () => {
  const captured = [];
  const orig = globalThis.fetch;
  globalThis.fetch = mockFetch(captured);
  try {
    await searchPlace('東京タワー', ENV, { rank: 'distance' });
    assert.equal('locationBias' in captured[0].body, false);
    // rank は座標が無くても付く (Google が判断)
    assert.equal(captured[0].body.rankPreference, 'DISTANCE');
  } finally {
    globalThis.fetch = orig;
  }
});
