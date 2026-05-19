# Play Integrity サーバー検証 設計ドキュメント

**ステータス**: 設計 v0.2 (2026-05-19、S1 完了 + オーナー作業全 7 項目完了、S2 着手準備完了)
**対象**: Cloudflare Worker `solara-api` の `/auth/integrity/*` + `/protected/*` middleware の Android 経路
**前提**: `project_solara_launch_checklist.md` Phase 1 認証ミドルウェア + Phase 2 Flutter クライアント
**関連**:
- `app_attest_design.md` v3.0 (iOS 側、Apple App Attest)
- `revenuecat_webhook.md` v2.2 (RC エンタイトルメント検証 middleware、Play Integrity 統合後も互換)
- `project_solara_security_principles.md` 原則 1〜3
- `../../docs/app_development_lessons.md` §1.3 ケーススタディ + §5.6 鍵交換ハイブリッド方式 + §5.7 設計と公式 UI 乖離

## 変更履歴

### v0.2 (2026-05-19、S1 オーナー作業完了)
- §6 Self-managed key 管理を **実際の Play Console フローに更新** (ハイブリッド方式: RSA 鍵ペア生成 → public.pem upload → 暗号化応答鍵 download → 復号)
- §6.1 verification key 形式を **PEM 想定 → base64 (DER SubjectPublicKeyInfo) に訂正** (実 UI で確認、`crypto.subtle.importKey('spki', ...)` で扱う)
- §11 オーナー作業を全 7 項目チェック付きに展開、完了マークと作業時の TIPS を追加
- §10 R 項目: R2 (Play Console 鍵取得) を ✅ 解決済、R5 (Classic payload 仕様) を「公式 doc 再読 + S2 で確証」に維持

### v0.1 (2026-05-19、S1 完了)
- Q1-Q4 オーナー判断確定 (Classic + Self-managed + DEVICE + PLAY_RECOGNIZED)
- R1-R6 を「実装中 / 計測後確定」3 分類で明示
- 10-step 検証フロー + DO スキーマ追加 + middleware 統合 + 段階リリース機構 + 6 セッションロードマップ

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

### 6.1 key 種別 (v0.2 実 Play Console 確認後)
| 鍵 | 形式 | 取得値 | Worker 側 import |
|---|---|---|---|
| Encryption key (DECRYPTION_KEY) | AES-256 base64 | 44 char (末尾 `=` パディング 1) | `crypto.subtle.importKey('raw', base64Decode(key), 'AES-KW', ...)` |
| Verification key (VERIFICATION_KEY) | ECDSA P-256 公開鍵 **base64 (DER SubjectPublicKeyInfo)** | 124 char (末尾 `=` パディング 1) | `crypto.subtle.importKey('spki', base64Decode(key), {name:'ECDSA',namedCurve:'P-256'}, ...)` |

🔴 **v0.1 からの訂正**: Verification key は PEM 形式と想定していたが、**実際の Play Console は base64 (DER SubjectPublicKeyInfo) で出力**。PEM ヘッダー (`-----BEGIN PUBLIC KEY-----`) は付かない。Workers Web Crypto では `format: 'spki'` で扱う (PEM の場合は手動で base64 decode + headers strip が必要だったが不要に)。

両方 Play Console > **アプリの完全性 > Play Integrity API の設定 > クラシック リクエスト > レスポンスの暗号化 > 鉛筆アイコンで編集 > 「レスポンスの暗号鍵を自分で管理、ダウンロードする」を選択** から取得。

### 6.2 取得手順 (Self-managed key、ハイブリッド方式)

Google は AES-256 + ECDSA 鍵を直接ダウンロードさせず、クライアント側で生成した RSA 公開鍵で暗号化したファイルを返す (= 「Google サーバー保管中の漏洩を排除する」追加層、`app_development_lessons.md` §5.6 ハイブリッド方式)。

```powershell
# Step 1: クライアント側で RSA 2048-bit 鍵ペア生成
mkdir C:\Users\<user>\solara-integrity-keys
cd C:\Users\<user>\solara-integrity-keys
& "C:\Program Files\Git\usr\bin\openssl.exe" genrsa -aes128 -out private.pem 2048
# → passphrase 入力 (2 回)、忘れないものをパスワードマネージャー保管

& "C:\Program Files\Git\usr\bin\openssl.exe" rsa -in private.pem -pubout -out public.pem
# → passphrase 入力 (1 回)、public.pem 451B + private.pem 1886B 生成

# Step 2: public.pem を Play Console にアップロード (UI でファイル選択)
# Play Console が暗号化応答ファイル (例: com.solodevlab.solara.enc) を自動 download
# Move-Item で作業ディレクトリに移動

# Step 3: 復号して平文鍵を取り出す
& "C:\Program Files\Git\usr\bin\openssl.exe" pkeyutl -decrypt -inkey private.pem `
  -pkeyopt rsa_padding_mode:oaep -in com.solodevlab.solara.enc -out api_keys.txt
# → passphrase 入力、api_keys.txt に
#   DECRYPTION_KEY=<44 char base64>
#   VERIFICATION_KEY=<124 char base64>

# Step 4: Worker secret に投入
cd E:\AppCreate\apps\solara\worker
npx wrangler secret put PLAY_INTEGRITY_ENCRYPTION_KEY  # DECRYPTION_KEY の右辺のみ貼り付け
npx wrangler secret put PLAY_INTEGRITY_VERIFICATION_KEY  # VERIFICATION_KEY の右辺のみ貼り付け

# Step 5: 平文鍵を削除 (= Worker 投入後は不要、Play Console から再復号可能)
Remove-Item api_keys.txt
Remove-Item com.solodevlab.solara.enc

# 保管するもの: private.pem (passphrase 暗号化済) + passphrase のみ
```

### 6.3 Workers での保管
- **Encryption key (PLAY_INTEGRITY_ENCRYPTION_KEY)**: secret 必須 (= 漏れたら任意の偽 token を作られる)
- **Verification key (PLAY_INTEGRITY_VERIFICATION_KEY)**: public 情報だが secret 管理に統一 (= 漏洩リスクなし、運用簡素化)

### 6.4 key rotation
- Play Console で key 再生成可能 (= attacker が encryption key を入手したら必須)
- rotation 手順: Play Console で「キーをダウンロード」再実行 → private.pem で復号 → `wrangler secret put` で上書き
- 既存 token は invalid 化 (= rotation 時はクライアント側も再 attest 必要)
- 平常時は **rotation 不要** (Apple Root CA と同じく長期固定で OK)

### 6.5 重要な落とし穴
- **PowerShell `>` リダイレクトは UTF-16LE になる罠**: `openssl ... > file.txt` ではなく `openssl ... -out file.txt` (openssl 自身) で ASCII 出力させる
- **OpenSSL 単体インストール不要**: Git for Windows 同梱の `C:\Program Files\Git\usr\bin\openssl.exe` で十分 (PowerShell からは `&` call operator + フルパス実行)
- **平文鍵をローカルに残さない**: `api_keys.txt` は wrangler secret 投入後即削除。Play Console から何度でも再ダウンロード + 復号可能なため、平文を残すリスク > 失うリスク
- **base64 末尾 `=` パディングは必須**: 抜くと復号失敗、必ず含めて貼り付け

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

| # | 項目 | 解決時期 | 状態 |
|---|---|---|---|
| R1 | Workers Web Crypto JWE A256KW + JWS ES256 decode のパフォーマンス (Workers Free 10ms 制限内?) | 実装直後 (S2 で minimal Worker 検証) | ⏳ S2 |
| R2 | Play Console > アプリの完全性 > Play Integrity API > クラシック リクエスト > レスポンスの暗号化 > 自分で管理 切替 + 鍵取得 (オーナー作業) | S2 着手前 | ✅ **解決 2026-05-19** (DECRYPTION_KEY 44 char + VERIFICATION_KEY 124 char、wrangler secret 投入完了) |
| R3 | Free 10k/day で Solara Android DAU 跳ね返り (実 traffic で確認) | 本番 deploy 後 1 週間モニタ | ⏳ deploy 後 |
| R4 | `app_attest_integrity` v1.0.0 の `androidPrepareIntegrityServer` 実 API + 戻り値構造 (= JWE+JWS compact string か?) | S2 で GitHub ソース確認 + 実機検証 | ⏳ S2 |
| R5 | Classic payload 仕様 (requestHash は Standard 限定、Classic では nonce のみ。公式 doc 再読 + S2 で確証) | S2 docs §16 で payload spec 確証 | ⏳ S2 |
| R6 | Workers bundle 増加実測 (jose v6 追加で gzip 24% 想定が実際の値) | S2 deploy 後計測 | ⏳ S2 |
| R7 (新規) | base64 (DER SubjectPublicKeyInfo) verification key の `crypto.subtle.importKey('spki', ...)` で正常 import できるか | S2 minimal worker | ⏳ S2 |

## 11. オーナー作業 (チェックリスト、2026-05-19 S1 完了)

### 11.1 Play Console 設定
- [x] **Cloud project link**: Play Console > Solara > アプリの完全性 > Play Integrity API > Cloud プロジェクトをリンク → 既存 `Solara-api` を選択
- [x] **Response encryption 切替**: クラシック リクエスト > レスポンスの暗号化 > 鉛筆アイコン > 「レスポンスの暗号鍵を自分で管理、ダウンロードする」を選択
- [x] **RSA 鍵ペア生成**: `openssl genrsa -aes128 -out private.pem 2048` + `openssl rsa -in private.pem -pubout -out public.pem` (Git for Windows 同梱の openssl で実行)
- [x] **public.pem upload**: Play Console UI で公開鍵をアップロード → 暗号化応答ファイル (com.solodevlab.solara.enc) 自動 download
- [x] **復号**: `openssl pkeyutl -decrypt -inkey private.pem -pkeyopt rsa_padding_mode:oaep -in com.solodevlab.solara.enc -out api_keys.txt` で DECRYPTION_KEY / VERIFICATION_KEY 取出
- [x] **wrangler secret 投入**: `PLAY_INTEGRITY_ENCRYPTION_KEY` (44 char) + `PLAY_INTEGRITY_VERIFICATION_KEY` (124 char)
- [x] **平文鍵削除**: `api_keys.txt` + `com.solodevlab.solara.enc` 削除、`private.pem` (passphrase 暗号化済) と passphrase のみ保管

### 11.2 残作業 (S2 以降)
- [ ] wrangler.toml に vars 追加 (S2 で実装と同時):
  ```toml
  PLAY_INTEGRITY_ENFORCEMENT = "log_only"
  PLAY_INTEGRITY_NONCE_TTL_SEC = "300"
  ANDROID_PACKAGE_NAME = "com.solodevlab.solara"
  ```
- [ ] S2-S6 実装後、`PLAY_INTEGRITY_ENFORCEMENT = "log_only"` で初回 deploy → 1 週間モニタ → `enforced` 切替
- [ ] **API quota** 初期 10k/day を確認、必要に応じて増量申請 (公開後、R3 計測結果次第)

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

## 13. v0.2 から v0.3 への次タスク (S2 着手)

S2 のスコープ:
1. **R4 解決**: `app_attest_integrity` (bam.tech) GitHub ソース確認で `androidPrepareIntegrityServer(nonce)` の戻り値構造 + token 取得タイミング確証
2. **jose v6 を Worker package.json に追加** → `npm install` → bundle 増加実測 (R6)
3. **minimal Worker** で JWE A256KW decode + JWS ES256 verify の round-trip 検証 (R1 + R7):
   - 既知の token (= Google 公式 sample or 実機採取) を decode して期待値と比較
   - Workers Free 10ms CPU 制限内に収まるか計測
   - base64 (DER SubjectPublicKeyInfo) verification key で `crypto.subtle.importKey('spki', ...)` が動くか確認
4. **設計 v0.3 にバンプ**: R1/R4/R6/R7 解決後の実数値を反映、S3 着手前提整える

## 関連ドキュメント

- `app_attest_design.md` (iOS 側、9 step + 案 B' ハイブリッド)
- `revenuecat_webhook.md` (RC エンタイトルメント連動、Play Integrity 経路でも同じ middleware 共通フロー)
- `apps/solara/docs/architecture.md` (将来更新時に Android セキュリティ層を追記)
