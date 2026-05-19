# Play Integrity サーバー検証 設計ドキュメント

**ステータス**: 設計 v0.1 (2026-05-19、S1 完了)
**対象**: Cloudflare Worker `solara-api` の `/auth/integrity/*` + `/protected/*` middleware の Android 経路
**前提**: `project_solara_launch_checklist.md` Phase 1 認証ミドルウェア + Phase 2 Flutter クライアント
**関連**:
- `app_attest_design.md` v3.0 (iOS 側、Apple App Attest)
- `revenuecat_webhook.md` v2.2 (RC エンタイトルメント検証 middleware、Play Integrity 統合後も互換)
- `project_solara_security_principles.md` 原則 1〜3

## 0. なぜ Play Integrity か

Solara は JP 公開で iOS/Android 両ストア配信を予定。Apple App Attest は iOS でしか動かないため、Android 端末からの `/protected/*` 呼出は現状すべて bypass されて Gemini を叩ける状態。Apple 3.2.2 + Play ポリシー違反リスクに加え、Pro 機能ゲートが Android で実質効かない。

Apple App Attest と対称的な検証層を Android にも置く = **Play Integrity API v1 Classic request + Self-managed key + Workers 自前 decode**。

## 1. オーナー判断 確定 (Q1-Q4)

| # | 項目 | 確定 | 理由 |
|---|---|---|---|
| Q1 | request 種別 | **Classic request** | server-issued nonce で App Attest の challenge と同形パターン、replay 防止が DO で素直、middleware ロジック共通化 |
| Q2 | decode 方式 | **Self-managed key (Workers 自前 JWE A256KW + JWS ES256 decode)** | Google サーバー decode は ① 障害連鎖 ② 100-300ms レイテンシ ③ 10k/day quota 消費。Apple App Attest と同じ「Workers 完結」哲学 |
| Q3 | deviceIntegrity 閾値 | **`MEETS_DEVICE_INTEGRITY` 必須** | minSdk 31 (Android 12) 下限維持。STRONG は「セキュリティパッチ 1 年以内」要件で古いパッチ端末を追加で弾き、サポート負荷増 |
| Q4 | appIntegrity 閾値 | **`PLAY_RECOGNIZED` 必須** | サイドロード排除、Pro 機能ゲートの基本要件 |

## 2. アーキテクチャ概要

```
Flutter (Android 端末)
    │
    │ ① POST /auth/integrity/challenge
    ▼
Worker /auth/integrity/challenge
    └─ DO IntegrityNonce 表に random 32B INSERT (TTL 5min) → base64url で返却
    │
    │ ② nonce 受領
    ▼
Flutter
    │ app_attest_integrity.androidPrepareIntegrityServer(nonce)
    │ → IntegrityTokenResponse (JWE+JWS 形式)
    │
    │ ③ POST /protected/* with X-PlayIntegrity-Token + body __appUserId
    ▼
Worker /protected/* middleware (Android 経路)
    ├─ DO IntegrityNonce から該当 nonce を consume (one-time)
    ├─ JWE A256KW decode (Worker Web Crypto)
    ├─ JWS ES256 verify (Google 公開鍵で署名検証)
    ├─ verdict (appIntegrity/deviceIntegrity/accountDetails) 評価
    ├─ requestHash == SHA256(body) 一致確認
    └─ RevenueCat entitlement lookup → Free/Pro quota (App Attest と完全共通)
```

iOS は引き続き Apple App Attest 経路。**Flutter 側 OS 判定で片方のみ動作**。

## 3. ファイル構成 (実装後の最終形)

```
apps/solara/worker/src/auth/
  play_integrity.js        # 新規 — token decode + verdict 評価 (~250 行)
  google_play_keys.js      # 新規 — Self-managed key 定数 + key rotation 入口 (~60 行)
  integrity_state.js       # 新規 OR attestation_state.js に統合
  jose_wrapper.js          # 新規 — jose v6 で JWE/JWS の Solara 用 wrapper (~50 行)

apps/solara/lib/utils/
  app_attest_client.dart   # 既存 — iOS/Android 両 OS 対応に拡張 (rename 検討: IntegrityClient)

apps/solara/docs/
  play_integrity_design.md # 本ドキュメント
```

## 4. Worker 検証フロー (10 step、Apple App Attest 9 step に対応)

### Step 1: Client → Worker `/auth/integrity/challenge` (POST)
- Worker: `crypto.getRandomValues(Uint8Array(32))` で nonce 生成
- DO `integrity_nonces` 表に INSERT (`expires_at = now + 5min`)
- 返却: `{ nonceId: <uuid>, nonce: <base64url 32B>, ttlSec: 300 }`
- Flutter は `nonce` を `androidPrepareIntegrityServer(nonce)` に渡す

### Step 2: Worker `/protected/*` middleware で token 受領
- HTTP header `X-PlayIntegrity-Token: <jwe.jws compact form>`
- HTTP header `X-PlayIntegrity-NonceId: <uuid>` (DO 検索キー)

### Step 3: nonce consume (one-time use、Apple challenge と同様)
- DO `integrity_nonces` から `nonceId` で SELECT (expired/consumed なら 404 → 401)
- consumed_at をマーク

### Step 4: JWE A256KW decode (encryption key で復号)
- `jose.compactDecrypt(jweToken, ENCRYPTION_KEY)` で plaintext (= JWS compact) を取り出す
- `ENCRYPTION_KEY` は Play Console > App integrity > Settings からダウンロードした AES-256 鍵 (Base64)
- Workers 内で `crypto.subtle.importKey('raw', keyBytes, 'AES-KW', ...)` で読み込み

### Step 5: JWS ES256 verify (Google ECDSA 公開鍵で署名検証)
- `jose.compactVerify(jwsToken, VERIFICATION_KEY)` で payload を取り出す
- `VERIFICATION_KEY` は Play Console から取得した ECDSA P-256 公開鍵 (PEM)
- Workers 内で `crypto.subtle.importKey('spki', keyBytes, {name: 'ECDSA', namedCurve: 'P-256'}, ...)` で読み込み

### Step 6: payload (verdict) parse
```json
{
  "requestDetails": {
    "requestPackageName": "com.solodevlab.solara",
    "timestampMillis": 1700000000000,
    "nonce": "<base64url 32B>"   // Step 1 で発行した値
  },
  "appIntegrity": {
    "appRecognitionVerdict": "PLAY_RECOGNIZED",
    "packageName": "com.solodevlab.solara",
    "certificateSha256Digest": ["..."],
    "versionCode": "..."
  },
  "deviceIntegrity": {
    "deviceRecognitionVerdict": ["MEETS_DEVICE_INTEGRITY", ...]
  },
  "accountDetails": {
    "appLicensingVerdict": "LICENSED"
  }
}
```

### Step 7: nonce 一致 + timestamp ±5min
- `payload.requestDetails.nonce` が Step 1 で発行した値と一致
- `Math.abs(now - payload.requestDetails.timestampMillis) < 300_000` (5 分窓)
- `payload.requestDetails.requestPackageName === "com.solodevlab.solara"`

### Step 8: appIntegrity 評価
- `appRecognitionVerdict === "PLAY_RECOGNIZED"` 必須 (Q4)
- `packageName === "com.solodevlab.solara"` 必須
- `certificateSha256Digest` に Play 配信用 SHA-256 が含まれる (= 自前署名・サイドロード排除)

### Step 9: deviceIntegrity 評価
- `deviceRecognitionVerdict` に `"MEETS_DEVICE_INTEGRITY"` が含まれる (Q3)
- 不在なら → root/エミュ/未承認端末 → 401

### Step 10: 既存 entitlement / quota フロー (RevenueCat 連動、App Attest と完全共通)
- body `__appUserId` 抽出 → DO `user_entitlements` lookup → Pro/Free quota 切替
- App Attest 経路と middleware ロジック共通化 (= 統合 middleware で OS 判定 + 検証関数だけ切替)

## 5. Durable Object スキーマ追加

既存 `AttestationState` DO に 1 表追加 (1 instance 集約継続、migration 不要):

```sql
CREATE TABLE IF NOT EXISTS integrity_nonces (
  nonce_id TEXT PRIMARY KEY,
  nonce_bytes BLOB NOT NULL,
  expires_at INTEGER NOT NULL,
  consumed_at INTEGER
);
CREATE INDEX IF NOT EXISTS idx_integrity_nonces_expires ON integrity_nonces(expires_at);
```

API (App Attest `challenges` と並列):
- `POST /integrity-nonce-create body: {nonceId, nonceBytes, expiresAt}`
- `POST /integrity-nonce-consume body: {nonceId, now} → {nonceBytes} or 404`

## 6. Self-managed key 管理

### 6.1 key 種別
| 鍵 | 形式 | 用途 |
|---|---|---|
| Encryption key | AES-256-KW (Base64) | JWE A256KW decode |
| Verification key | ECDSA P-256 公開鍵 (PEM) | JWS ES256 verify |

両方 Play Console > App integrity > Settings > "Manage and download my keys" から取得。

### 6.2 Workers での保管
- **Encryption key**: secret 必須 (= 漏れたら任意の偽 token を作られる)
  - `wrangler secret put PLAY_INTEGRITY_ENCRYPTION_KEY`
- **Verification key**: public 情報だが頻繁に変わらないため `vars` で十分
  - `wrangler.toml` の `[vars]` に直書き、または別 secret として管理
  - Solara は secret 管理を簡素化するため両方 secret に統一

### 6.3 key rotation
- Play Console で key 再生成可能 (= attacker が encryption key を入手したら必須)
- rotation 手順: `wrangler secret put` で上書き → Play Console 側も同じ値に更新 → 既存 token は invalid 化
- 平常時は **rotation 不要** (Apple Root CA と同じく長期固定で OK)

## 7. Flutter 側実装

### 7.1 `app_attest_integrity` 拡張
既存の `AppAttestClient` (lib/utils/app_attest_client.dart) を OS 判定で分岐:

```dart
// 既存 (iOS only)
if (Platform.isIOS) {
  await _attest.iOSgenerateAttestation(challengeB64);
}

// 新規 (Android only)
if (Platform.isAndroid) {
  // app_attest_integrity の Android API (R4 で実 API 確証)
  await _attest.androidPrepareIntegrityServer(nonceB64);
}
```

ヘッダー注入も OS 判定:
```dart
if (Platform.isIOS) {
  headers['X-AppAttest-KeyId'] = _keyId!;
  headers['X-AppAttest-Assertion'] = assertionB64;
}
if (Platform.isAndroid) {
  headers['X-PlayIntegrity-Token'] = jweJwsToken;
  headers['X-PlayIntegrity-NonceId'] = _nonceId!;
}
```

リネーム候補: `AppAttestClient` → `IntegrityClient`、ただし変更影響を最小化するため **本実装フェーズ後に decide** (今は API 互換維持で OS 分岐だけ追加)。

### 7.2 nonce ライフサイクル
- iOS: keyId は端末永続 (SharedPreferences、1 端末 1 keyId)
- Android: nonce は呼出ごと使い捨て (= 毎回 Worker `/auth/integrity/challenge` を叩く)

iOS は起動時 1 回 attest、Android は **毎回 token 取得**。これは Play Integrity の仕様 (短命 token + Google サーバー側 quota) で、Apple App Attest との大きな違い。

### 7.3 quota への影響
Solara `/protected/*` 1 呼出につき:
- iOS: assertion 生成 (端末ローカル、Apple サーバー不要)
- Android: token 生成 (Google サーバー 1 req 消費、10k/day quota)

Free 5/日、Pro 100/日想定なら Android DAU 1500 × 平均 2 req = 3,000/day → 10k quota 内で十分余裕。ただし Pro ユーザーが 100/日上限まで使うと quota 圧迫リスク → R3 で実装後計測。

## 8. middleware 統合 (iOS/Android 自動切替)

`apps/solara/worker/src/index.js` の `protectedMiddleware` を OS 判定で 2 経路分岐:

```js
async function protectedMiddleware(request, env) {
  // ... (mode 評価、body 取得)

  const isApple = !!request.headers.get('X-AppAttest-KeyId');
  const isAndroid = !!request.headers.get('X-PlayIntegrity-Token');

  if (isApple && isAndroid) return fail(400, 'both_attest_headers');
  if (!isApple && !isAndroid) return fail(401, 'missing_attest_headers');

  // 経路 1: iOS App Attest (既存)
  if (isApple) {
    const r = await verifyAppleAssertionFlow(request, env, payloadBytes);
    if (r.error) return fail(r.status, r.error);
  }

  // 経路 2: Android Play Integrity (新規)
  if (isAndroid) {
    const r = await verifyPlayIntegrityFlow(request, env, payloadBytes);
    if (r.error) return fail(r.status, r.error);
  }

  // 共通: entitlement lookup + quota (RevenueCat 連動、両 OS 同じ)
  // ...
}
```

## 9. 段階リリース機構

App Attest と独立した env var で制御:
```
PLAY_INTEGRITY_ENFORCEMENT = "disabled" | "log_only" | "enforced"
```
- 初期値 `log_only` (Flutter Android 実装 → TestFlight Android テスト → 1 週間モニタ → `enforced` 切替)
- App Attest と独立 = iOS は enforced、Android は log_only、というスケジュール差を吸収

## 10. R 項目 (実装中 / 実装後計測)

| # | 項目 | 解決時期 |
|---|---|---|
| R1 | Workers Web Crypto JWE A256KW + JWS ES256 decode のパフォーマンス (Workers Free 10ms 制限内?) | 実装直後 (S2 で minimal Worker 検証) |
| R2 | Play Console > App integrity > Settings > "Manage and download my keys" 手順 (オーナー作業、鍵取得確証) | S2 着手前 (オーナー) |
| R3 | Free 10k/day で Solara Android DAU 跳ね返り (実 traffic で確認) | 本番 deploy 後 1 週間モニタ |
| R4 | `app_attest_integrity` v1.0.0 の `androidPrepareIntegrityServer` 実 API + 戻り値構造 (= JWE+JWS compact string か?) | S2 で GitHub ソース確認 + 実機検証 |
| R5 | requestHash の Standard 仕様で Classic は何を渡すか (公式仕様で nonce のみ使用、requestHash は Standard 限定) | S2 docs §16 で payload spec 確証 |
| R6 | Workers bundle 増加実測 (jose v6 追加で gzip 24% 想定が実際の値) | S2 deploy 後計測 |

## 11. オーナー作業 (S2 着手前に必要なもの)

### 11.1 Play Console 設定 (公開前必須)
1. Play Console > Solara アプリ > **App integrity** > **App integrity settings**
2. **Integrity API responses (Classic + Standard)** セクション
3. **Response encryption** を **Manage and download my response encryption keys** に切替
4. Encryption key (AES-256, base64) と Verification key (ECDSA P-256, PEM) を生成 → ローカル保存
5. **Google Cloud project link** を確認 (Cloud Console で同一プロジェクトに connect 済か)
6. **API quota** 初期 10k/day を確認、必要に応じて増量申請 (公開後)

### 11.2 Worker secret 投入
```powershell
cd apps/solara/worker
echo "<encryption key base64>" | npx wrangler secret put PLAY_INTEGRITY_ENCRYPTION_KEY
echo "<verification key PEM (one line)>" | npx wrangler secret put PLAY_INTEGRITY_VERIFICATION_KEY
```

### 11.3 wrangler.toml に追加 vars
```toml
PLAY_INTEGRITY_ENFORCEMENT = "log_only"
PLAY_INTEGRITY_NONCE_TTL_SEC = "300"
ANDROID_PACKAGE_NAME = "com.solodevlab.solara"
```

## 12. 実装ロードマップ (S2-S6、約 6-8 セッション)

```
S1 ✅: 本設計ドキュメント完成 + Q1-Q4 確定 + R1-R6 明示
S2  : R4 解決 (app_attest_integrity の Android API 実コード確認 + 戻り値型)
      + jose v6 を package.json 追加 + minimal Worker で JWE+JWS round-trip 検証
      + bundle 計測 (R6)
S3  : auth/play_integrity.js 実装 (Step 4-9 = decode + verify + verdict 評価)
      + 単体テスト (fixtures は Play Integrity 公式 sample から流用 or 実機 token 採取)
S4  : DO integrity_nonces 表 + /auth/integrity/challenge 実装
      + middleware 統合 (経路分岐 + 共通フロー保持)
      + 単体テスト
S5  : Flutter AppAttestClient を OS 分岐対応に拡張
      + Android 実機テスト (or Android Emulator + Play services)
      + flutter analyze + 既存 test 維持
S6  : docs 仕上げ (deploy 手順 §13 + 運用ガイド §14)
      + launch_checklist 更新 + メモリ整理
      + オーナー作業 (Play Console + Worker secret) → 本番 deploy
```

App Attest と同等の重さを想定 (6-8 セッション、計 15-20h)。

## 13. v0.1 から v0.2 への次タスク

S1 完了直後:
1. 本ドキュメントへのオーナー review (Q1-Q4 確定、R1-R6 確認)
2. R2 (Play Console 鍵取得) のオーナー手元確認 → blockerなければ S2 着手
3. S2: jose v6 動作確認 + Web Crypto 互換性検証 (minimal Worker)

## 関連ドキュメント

- `app_attest_design.md` (iOS 側、9 step + 案 B' ハイブリッド)
- `revenuecat_webhook.md` (RC エンタイトルメント連動、Play Integrity 経路でも同じ middleware 共通フロー)
- `apps/solara/docs/architecture.md` (将来更新時に Android セキュリティ層を追記)
