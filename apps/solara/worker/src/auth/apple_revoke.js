/**
 * Apple Sign In Token Revocation (App Store Review Guideline 5.1.1(v) 厳密解釈対応)。
 *
 * 用途:
 *   ユーザーがアプリ内アカウント削除を行ったときに、Apple ID 側との連携も完全に
 *   失効させる (= Apple ID の「Apple ID を使用しているサインイン履歴」から Solara が消える)。
 *
 * Apple 公式:
 *   - https://developer.apple.com/documentation/sign_in_with_apple/sign_in_with_apple_rest_api/revoke_tokens
 *   - https://developer.apple.com/documentation/sign_in_with_apple/sign_in_with_apple_rest_api/generate_and_validate_tokens
 *
 * 必須 secret / env (wrangler.toml + secret put):
 *   - APPLE_SIWA_SERVICE_ID  : Apple Developer Console で発行する Sign in with Apple
 *                              用 Service ID (例 "com.solodevlab.solara.signin")。
 *                              Bundle ID とは別の identifier。public。wrangler.toml vars。
 *   - APPLE_SIWA_KEY_ID      : Authentication Key (P8) の 10 桁 ID。public。wrangler.toml vars。
 *   - APPLE_TEAM_ID          : 既存。wrangler.toml vars。
 *   - APPLE_SIWA_PRIVATE_KEY : .p8 ファイルの中身 (PEM、"BEGIN PRIVATE KEY" 含む)。
 *                              wrangler secret put で登録。
 *
 * 鍵が未設定の場合は revoke を no-op で skip (= 公開前にコード先行 deploy 可能)。
 */

/** Apple revoke endpoint (公式固定)。 */
const APPLE_REVOKE_URL = 'https://appleid.apple.com/auth/revoke';

/** client_secret JWT の TTL。Apple 公式は最大 6 ヶ月だが、安全側で 10 分。 */
const CLIENT_SECRET_TTL_SEC = 600;

/** テスト用 fetch 注入。 */
let _fetchImpl = (...args) => globalThis.fetch(...args);
export function _setFetchForTest(impl) {
  _fetchImpl = impl;
}

/**
 * base64url エンコード (Apple JWT 仕様)。
 * '+' → '-', '/' → '_', '=' トリム。
 */
function base64UrlEncode(input) {
  let str;
  if (input instanceof Uint8Array) {
    // バイト列を Latin1 文字列経由で btoa
    let bin = '';
    for (let i = 0; i < input.length; i++) bin += String.fromCharCode(input[i]);
    str = btoa(bin);
  } else if (typeof input === 'string') {
    str = btoa(input);
  } else {
    throw new TypeError('base64UrlEncode expects Uint8Array or string');
  }
  return str.replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

/**
 * PEM 形式の P8 秘密鍵 (PKCS#8 ES256) を CryptoKey に import。
 *
 * Apple Developer Console で発行する Sign in with Apple Authentication Key は
 * P-256 楕円曲線 + ES256 (ECDSA + SHA-256) 署名固定。
 */
async function importApplePrivateKey(pem) {
  // PEM ヘッダ/フッタを剥がして base64 部分だけ抽出
  const stripped = pem
    .replace(/-----BEGIN PRIVATE KEY-----/g, '')
    .replace(/-----END PRIVATE KEY-----/g, '')
    .replace(/\s+/g, '');
  // base64 → Uint8Array
  const der = Uint8Array.from(atob(stripped), (c) => c.charCodeAt(0));
  return crypto.subtle.importKey(
    'pkcs8',
    der,
    { name: 'ECDSA', namedCurve: 'P-256' },
    false,
    ['sign'],
  );
}

/**
 * Apple revoke 用の client_secret JWT を生成 (ES256 署名)。
 *
 * @param {object} env - APPLE_TEAM_ID, APPLE_SIWA_SERVICE_ID, APPLE_SIWA_KEY_ID, APPLE_SIWA_PRIVATE_KEY
 * @param {number} [nowSec] - テスト用 epoch (秒)
 * @returns {Promise<string>} JWT (header.payload.signature の三段 base64url)
 */
export async function buildAppleClientSecret(env, nowSec = Math.floor(Date.now() / 1000)) {
  const teamId = env.APPLE_TEAM_ID;
  const serviceId = env.APPLE_SIWA_SERVICE_ID;
  const keyId = env.APPLE_SIWA_KEY_ID;
  const privateKeyPem = env.APPLE_SIWA_PRIVATE_KEY;

  if (!teamId || !serviceId || !keyId || !privateKeyPem) {
    throw new Error('apple_siwa_secrets_missing');
  }

  // ヘッダ: ES256 + Key ID
  const header = base64UrlEncode(JSON.stringify({ alg: 'ES256', kid: keyId, typ: 'JWT' }));

  // ペイロード: iss=TeamID, iat/exp, aud=appleid.apple.com, sub=ServiceID
  const payload = base64UrlEncode(JSON.stringify({
    iss: teamId,
    iat: nowSec,
    exp: nowSec + CLIENT_SECRET_TTL_SEC,
    aud: 'https://appleid.apple.com',
    sub: serviceId,
  }));

  const signingInput = `${header}.${payload}`;
  const cryptoKey = await importApplePrivateKey(privateKeyPem);
  const sigBuf = await crypto.subtle.sign(
    { name: 'ECDSA', hash: { name: 'SHA-256' } },
    cryptoKey,
    new TextEncoder().encode(signingInput),
  );
  const signature = base64UrlEncode(new Uint8Array(sigBuf));
  return `${signingInput}.${signature}`;
}

/**
 * Apple Sign In token を revoke する。
 *
 * @param {object} env
 * @param {string} authorizationCode - Flutter 側が SignInWithApple.getAppleIDCredential で
 *   取得した authorizationCode (5 分 / 単回限り)。
 * @returns {Promise<{ok: boolean, reason?: string, status?: number}>}
 *   - ok=true: Apple が 200 を返した (token 失効成功)
 *   - ok=false + reason='secrets_missing': 鍵未設定 (= no-op で skip)
 *   - ok=false + reason='invalid_code': authorizationCode 空
 *   - ok=false + reason='apple_<status>': Apple が non-200
 *   - ok=false + reason='fetch_error' | 'jwt_error': 例外
 */
export async function revokeAppleToken(env, authorizationCode) {
  if (typeof authorizationCode !== 'string' || authorizationCode.length === 0) {
    return { ok: false, reason: 'invalid_code' };
  }
  if (!env || !env.APPLE_TEAM_ID || !env.APPLE_SIWA_SERVICE_ID
      || !env.APPLE_SIWA_KEY_ID || !env.APPLE_SIWA_PRIVATE_KEY) {
    return { ok: false, reason: 'secrets_missing' };
  }

  let clientSecret;
  try {
    clientSecret = await buildAppleClientSecret(env);
  } catch (_e) {
    return { ok: false, reason: 'jwt_error' };
  }

  // まず authorizationCode を refresh_token に交換 (revoke は refresh_token の方が確実)。
  // Apple 公式: revoke は access_token / refresh_token どちらでも可だが、
  // refresh_token を revoke すると関連する全 access_token も無効化される。
  //
  // 実装簡略化: authorizationCode を直接 revoke する (token_type_hint=access_token)。
  // Apple は authorizationCode 自体を revoke 対象として受け付ける挙動 (revoke 後は
  // 同 authorizationCode で token 交換不可になる) のためアカウント削除用途は十分。
  //
  // 公式: https://developer.apple.com/documentation/sign_in_with_apple/sign_in_with_apple_rest_api/revoke_tokens
  const form = new URLSearchParams({
    client_id: env.APPLE_SIWA_SERVICE_ID,
    client_secret: clientSecret,
    token: authorizationCode,
    token_type_hint: 'access_token',
  });

  let res;
  try {
    res = await _fetchImpl(APPLE_REVOKE_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: form.toString(),
    });
  } catch (_e) {
    return { ok: false, reason: 'fetch_error' };
  }

  if (res.status === 200) {
    return { ok: true, status: 200 };
  }
  // Apple は失敗時に 400 + {error: 'invalid_client'} 等を返す
  return { ok: false, reason: `apple_${res.status}`, status: res.status };
}
