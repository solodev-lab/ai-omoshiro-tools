/**
 * Place Name Search — Google Places API (New) primary → Nominatim fallback
 *
 * Google Places (New): https://places.googleapis.com/v1/places:searchText
 *   - 月10,000 req/月 無料枠 (Essentials SKU)
 *   - 駅・建物・カフェ等のPOI検索が高精度
 *   - X-Goog-FieldMask で取得フィールドを制限してコスト削減
 *
 * Nominatim: https://nominatim.openstreetmap.org/search
 *   - 完全無料、1 req/sec
 *   - Google が key 未設定 / API 失敗時の最終フォールバック
 *
 * オーナー判断 (2026-04-30): Google を優先に切替
 *   理由: 駅名・ランドマーク・カフェ等POIに強い、住所表記が綺麗、海外精度も高い
 *   コスト: β段階 (~月100人 × 月20回検索) は無料枠の20%、本番初期ぎりぎり、
 *           本番拡大で月$100-200 課金見込み
 */

const NOMINATIM_URL = 'https://nominatim.openstreetmap.org/search';
const NOMINATIM_UA = 'SolaraApp/1.0 (solodev-lab.com)';

const GOOGLE_TEXT_SEARCH_URL =
  'https://places.googleapis.com/v1/places:searchText';

// Google Places (New) で取得するフィールド。最小限に絞ってコスト削減。
// places.id / displayName / formattedAddress / location / types
// で「Text Search Essentials」SKU に収まる (Essentials = $5/1000req、無料 10k/月)
const GOOGLE_FIELD_MASK =
  'places.id,places.displayName,places.formattedAddress,places.location,places.types';

export async function searchPlace(query, env, options = {}) {
  // Google Places (New) を優先
  if (env && env.GOOGLE_PLACES_KEY) {
    try {
      const googleResults = await searchGooglePlacesNew(
        query,
        env.GOOGLE_PLACES_KEY,
        options,
      );
      if (googleResults.length > 0) {
        return { source: 'google', results: googleResults };
      }
    } catch (err) {
      // Google API失敗 → Nominatim にフォールバック (ログのみ)
      console.error('Google Places search failed:', err);
    }
  }

  // Fallback: Nominatim
  const nominatimResults = await searchNominatim(query);
  return { source: 'nominatim', results: nominatimResults };
}

async function searchNominatim(query) {
  const params = new URLSearchParams({
    q: query,
    format: 'json',
    limit: '5',
    addressdetails: '1',
  });

  const resp = await fetch(`${NOMINATIM_URL}?${params}`, {
    headers: { 'User-Agent': NOMINATIM_UA, 'Accept-Language': 'ja,en' },
  });

  if (!resp.ok) return [];

  const data = await resp.json();
  return data.map(item => ({
    name: item.display_name,
    lat: parseFloat(item.lat),
    lng: parseFloat(item.lon),
    type: item.type,
    country: item.address?.country || '',
    countryCode: item.address?.country_code || '',
  }));
}

/**
 * Google Places API (New) Text Search を呼び出す。
 * 入力: クエリ文字列 (例: "渋谷", "東京 カフェ", "Los Angeles")
 * 出力: 最大10件の候補 [{name, lat, lng, type, country, countryCode}]
 *
 * 旧 Find Place from Text (Legacy) は使わない。Places API (New) は
 * - エンドポイントが異なる (places.googleapis.com)
 * - リクエストが POST + JSON body
 * - フィールド指定が X-Goog-FieldMask ヘッダ
 * - レスポンス schema が places[] (camelCase)
 */
async function searchGooglePlacesNew(query, apiKey, { lat, lng, radius = 15000 } = {}) {
  const reqBody = {
    textQuery: query,
    languageCode: 'ja',
    pageSize: 20,
  };

  // マップ中心座標が渡されていれば locationBias を付与（半径15km円形）
  // → カフェ等POI検索でマップ中心付近の結果を優先
  // → 海外地名検索（"Los Angeles" 等）も bias は弱い指示なので Google が広く判断する
  if (typeof lat === 'number' && typeof lng === 'number') {
    reqBody.locationBias = {
      circle: {
        center: { latitude: lat, longitude: lng },
        radius,
      },
    };
  }

  const resp = await fetch(GOOGLE_TEXT_SEARCH_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': apiKey,
      'X-Goog-FieldMask': GOOGLE_FIELD_MASK,
    },
    body: JSON.stringify(reqBody),
  });

  if (!resp.ok) {
    const errText = await resp.text().catch(() => '');
    throw new Error(
      `Google Places (New) ${resp.status}: ${errText.slice(0, 200)}`,
    );
  }

  const data = await resp.json();
  if (!data.places || !Array.isArray(data.places)) return [];

  return data.places.map(p => {
    const loc = p.location || {};
    const types = Array.isArray(p.types) ? p.types : [];
    // 国コードは types から推測できないため空に。詳細不要なため Place Details は呼ばない。
    return {
      name: p.displayName?.text || p.formattedAddress || '',
      address: p.formattedAddress || '',
      lat: typeof loc.latitude === 'number' ? loc.latitude : null,
      lng: typeof loc.longitude === 'number' ? loc.longitude : null,
      type: types[0] || 'place',
      country: '',
      countryCode: '',
      placeId: p.id || '',
    };
  }).filter(r => r.lat != null && r.lng != null);
}
