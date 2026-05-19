# App Attest サーバー検証 設計ドキュメント

**ステータス**: ドラフト v1.1 (2026-05-19 起案、同日 R2-R5/R7/R8 確定で大幅更新)
**対象**: Cloudflare Worker `solara-api` の `/auth/attest` + `/protected/*` ミドルウェア
**前提**: `project_solara_launch_checklist.md` Phase 1 認証ミドルウェア
**関連**: `project_solara_security_principles.md` 原則 1〜3

### v1 → v1.1 の変更点 (2026-05-19)
- R2 Apple Root CA フィンガープリント確定 (`1CB9823BA28BA6AD2D33A006941DE2AE4F513EF1D4E831B9F7E0FA7B6242C932`、**有効期限 2045-03-15** → 半年更新タスク削除)
- R3 rpId 式確定 (`SHA-256("<teamId>.<bundleId>")` ★★★)
- R4 AAGUID 確定 (production = `'appattest'`+NULL×7、development = `'appattestdevelop'`)
- R5 OID ASN.1 ネスト深さの懸念は実装パターン (`getExtension().toString('asn')` 末尾 suffix 比較) で **回避** ★★★
- R7 テスト fixtures 入手元確定 (appattest-checker-node の `tests/` ディレクトリ、Apache-2.0 流用可)
- R8 clientDataHash 定義確定 (attestation: SHA-256(challenge) / assertion: caller が SHA-256(payload))
- **§6.4 ECDSA 検証**: `nodejs_compat` + `node:crypto.createVerify` を使えば **DER→IEEE-P1363 変換不要** (実装簡素化)
- **§13 新規追加**: 実装方針 2 択 (自前 vs npm 流用) を提示

---

## 0. 凡例

各事実に確度ラベル:

- **★★★** Apple/Cloudflare/RevenueCat 公式 or 一次ソース複数で確認済
- **★★** 信頼できる二次ソース (大手ブログ・OSS実装) で確認済、Apple公式は SPA で本文取れず未直接確認
- **★** 推測 / 既存実装に倣う / 実装中に最終確認が必要
- **❓** 公開前にオーナー or 実機で確認必須

オーナーの「推測の断定禁止」ルール (`critical_rules.md`) に従い、確度を分けて記述する。

---

## 1. ゴールとスコープ

### 1.1 防御目標

`/protected/*` (Gemini を呼ぶ Pro 機能) に対する以下の攻撃を遮断する:

| # | 攻撃 | 対策 |
|---|---|---|
| A1 | curl 直叩きで Gemini 枯渇 | App Attest assertion 検証で正規 iOS バイナリ限定 |
| A2 | アプリ改変 `isPro=true` | Worker 側 RevenueCat 再検証 (本ドキュメント対象外、別エンドポイント) |
| A3 | Replay attack (同じ assertion を再送) | counter 単調増加チェック (Durable Object 永続化) |
| A4 | 偽 Solara クローン (別 bundleId 署名済) | App ID hash (rpId) 検証 |

### 1.2 非ゴール (本ドキュメント対象外)

- Android Play Integrity 検証 → 別ドキュメント `play_integrity_design.md` (未着手)
- RevenueCat Webhook + エンタイトルメントキャッシュ → 別ドキュメント
- per-appUserId rate limit → 別ドキュメント
- freerasp の RASP 配線 → Phase 2 Flutter 側 (完了済)

---

## 2. 用語

| 用語 | 意味 |
|---|---|
| **keyId** | iOS `DCAppAttestService.generateKey()` で得る端末固有キー識別子 (Base64) |
| **attestation** | `attestKey(keyId, clientDataHash)` で得る初回証明オブジェクト (CBOR) |
| **assertion** | `generateAssertion(keyId, clientDataHash)` で得る毎リクエスト署名 (CBOR) |
| **clientDataHash** | サーバーが発行した challenge (またはリクエスト payload) の SHA-256 |
| **authData / authenticatorData** | WebAuthn 流の認証データバイト列 (rpIdHash 32 + flags 1 + signCount 4 + AAGUID 16 + ...) |
| **credCert** | x5c[0]、Apple App Attest CA 発行の端末用証明書、公開鍵を含む |
| **rpId** | Relying Party ID = `"<teamId>.<bundleId>"` 文字列 (例: `"XXXXXXX.com.solodevlab.solara"`)。authData[0..31] = SHA-256(rpId) ★★★ (`appattest-checker-node` README + 実装で確定) |
| **AAGUID** | 認証器種別 GUID (16B)。development = `appattestdevelop` (16B UTF-8) / production = `'appattest'` (9B) + NULL バイト 7 個 ★★★ |

---

## 3. データフロー

```
┌────────────┐  ① challenge 要求            ┌──────────────────┐
│            │ ────────────────────────►   │                  │
│  iOS App   │                              │  Worker          │
│  (Solara)  │ ◄────────────────────────   │  /auth/challenge │
│            │  ② 32B random challenge      │                  │
└────┬───────┘    (KV 5分 TTL)              └──────┬───────────┘
     │                                              │
     │ DCAppAttestService.generateKey() → keyId    │
     │ DCAppAttestService.attestKey(keyId,         │
     │   SHA256(challenge))                        │
     ▼                                              ▼
     ③ POST /auth/attest                  ┌──────────────────┐
        { keyId, challengeId,              │ Worker           │
          attestation_b64 }                │ /auth/attest     │
     ───────────────────────────────────►  │                  │
                                            │ 9 ステップ検証   │
                                            │ → DO 保存:       │
                                            │  {keyId, pubKey, │
                                            │   counter:0}     │
     ◄───────────────────────────────────  │                  │
     ④ { ok: true }                        └──────────────────┘

  (以降、毎 /protected/* リクエスト)

     DCAppAttestService.generateAssertion(
       keyId, SHA256(payload))
     │
     ▼
     ⑤ POST /protected/<endpoint>          ┌──────────────────┐
        X-App-Attest-KeyId: <keyId>        │ Worker           │
        X-App-Attest-Assertion: <b64>      │ /protected/*     │
        body: <payload JSON>               │ middleware       │
     ───────────────────────────────────►  │                  │
                                            │ 1. DO から pubKey│
                                            │    + lastCounter │
                                            │    取得          │
                                            │ 2. assertion     │
                                            │    検証 (6step)  │
                                            │ 3. counter++     │
                                            │    DO 更新       │
                                            │ 4. 通過 →        │
                                            │    handler 呼出  │
                                            └──────────────────┘
```

---

## 4. Attestation 検証 (9 ステップ)

Apple `Validating apps that connect to your server` ★★ + appattest-checker-node v1.0.3 + node-app-attest の交差検証で確定。

### 入力
- `attestation_b64`: Base64URL の CBOR バイト列
- `keyId_b64`: Base64 の SHA-256 ハッシュ (32B)
- `challenge`: ステップ① でサーバー発行 (KV から復元)

### CBOR デコード結果

```js
{
  fmt: "apple-appattest",   // ★★ 必ずこの文字列
  attStmt: {
    x5c: [credCertDER, intermediateCertDER],  // ★★ [0]=leaf, [1]=intermediate
    receipt: <bytes>,        // App Store Server API 連動用 (現状未使用)
  },
  authData: <bytes>,         // ★★ 後述レイアウト
}
```

### authData バイトレイアウト ★★

| オフセット | 長さ | 内容 |
|---|---|---|
| 0..31 | 32 | rpIdHash = SHA-256(`"<teamId>.<bundleId>"` UTF-8) ★★★ |
| 32 | 1 | flags |
| 33..36 | 4 | signCount (big-endian uint32) ← `Buffer.readInt32BE(33)` ★★★ |
| 37..52 | 16 | AAGUID (production = `appattest`+NULL×7、development = `appattestdevelop`) ★★★ |
| 53..54 | 2 | credentialId length (big-endian uint16、必ず `0x00 0x20` = 32) ★★★ |
| 55..86 | 32 | credentialId (= SHA-256(uncompressed P-256 public key 65B)) ★★★ |
| 87.. | var | credentialPublicKey (COSE_Key, CBOR) |

### 9 ステップ

| # | 内容 | 失敗時 |
|---|---|---|
| 1 | x5c[0] と x5c[1] を Apple App Attest Root CA でチェーン検証 | 400 invalid_cert_chain |
| 2 | clientDataHash = SHA-256(challenge), nonce = SHA-256(authData ‖ clientDataHash) | (計算のみ) |
| 3 | credCert の拡張 OID `1.2.840.113635.100.8.2` を抽出。`@peculiar/x509` の場合は `getExtension(OID).toString('asn')` の末尾が `"OCTET STRING : <nonce hex>"` と suffix 一致するかチェック ★★★ (ネスト深さを気にしなくて済む実装パターン) | 400 nonce_mismatch |
| 4 | credCert.publicKey.rawData の末尾 65B (= uncompressed EC point `0x04 ‖ X ‖ Y`) を SHA-256 → keyId (base64) と一致 ★★★ | 400 keyid_mismatch |
| 5 | authData[0..31] == SHA-256(UTF-8(`"<teamId>.<bundleId>"`)) ★★★ | 400 rpid_mismatch |
| 6 | authData.signCount (readInt32BE@33) == 0 ★★★ | 400 counter_not_zero |
| 7 | authData[37..52] のうち production なら最初 9B が `'appattest'` / development なら全 16B が `'appattestdevelop'` ★★★ | 400 aaguid_mismatch |
| 8 | authData[53..54] == `0x00 0x20` (len=32) かつ authData[55..86] == keyId (base64 decode) ★★★ | 400 credential_id_mismatch |
| 9 | credCert.publicKey を PEM/SPKI で抽出し DO に永続化 `{keyId → {publicKeyPem, counter: 0, createdAt}}` | (成功時) |

### 地雷ポイント (確定情報で更新)

- **★★★ OID ネスト深さ問題は実装パターンで回避**: `@peculiar/x509` の `getExtension(oid).toString('asn')` で ASN.1 を文字列展開し、`endsWith("OCTET STRING : <hex>")` で suffix 比較する [appattest-checker-node 実装パターン](https://github.com/srinivas1729/appattest-checker-node/blob/main/src/attestation.ts) を採用。これによりネストが 2 段でも 3 段でも 4 段でも同じコードで通る。自前 ASN.1 パース時は要注意。
- **★★ Receipt は当面保存しない**: Apple Server-to-Server API (App Store Receipt 検証) は別仕事なので Phase 2 で。Receipt は ~5KB なので将来 DO 保存に余裕あり。
- **★★ keyId は base64 (not base64url)**: `appattest-checker-node` の実装は `Buffer.toString('base64')` で比較。Apple iOS が `base64EncodedString()` で返す形式と一致 ★★★。

---

## 5. Assertion 検証 (毎リクエスト 6 ステップ)

### 入力
- `assertion_b64`: Base64 CBOR
- `keyId_b64`: ヘッダから
- `payload`: リクエスト body (raw bytes)

### CBOR デコード結果

```js
{
  signature: <bytes>,           // ECDSA P-256 SHA-256, DER 形式 ★★★
  authenticatorData: <bytes>,   // rpIdHash 32 + flags 1 + signCount 4 (= 37B 以上)
}
```

### 6 ステップ

| # | 内容 |
|---|---|
| 1 | DO から `{publicKeyPem, lastCounter}` を keyId で取得。なければ 401 unregistered_key |
| 2 | clientDataHash = SHA-256(payload) (caller 責任、本 Worker では request body raw bytes を SHA-256) ★★★ |
| 3 | nonce = SHA-256(authenticatorData ‖ clientDataHash) ★★★ |
| 4 | `createVerify('SHA256').update(nonce).verify(publicKeyPem, signature)` で ECDSA verify ★★★ ([appattest-checker-node assertion.ts:106-119](https://github.com/srinivas1729/appattest-checker-node/blob/main/src/assertion.ts) で `'RSA-SHA256'` 指定だが、Node は鍵タイプから ECDSA を自動判定) |
| 5 | authenticatorData[0..31] == SHA-256(`"<teamId>.<bundleId>"`) ★★★ |
| 6 | authenticatorData.signCount > lastCounter (strict greater) → DO の counter を新値で更新 (transaction) |

### 推奨実装: `nodejs_compat` + `createVerify` (DER 変換不要) ★★★

- Apple は **DER (SEQUENCE { r INTEGER, s INTEGER })** で署名 (WebAuthn と同じ)
- Workers の **WebCrypto `subtle.verify` は IEEE-P1363 raw 64B のみ** 受け付ける (W3C 仕様準拠)
- ただし `wrangler.toml` に `compatibility_flags = ["nodejs_compat"]` を入れて **`node:crypto.createVerify('SHA256').verify(pubKeyPem, sig)` を使えば DER 署名を直接 verify できる** (Node の `dsaEncoding: 'der'` がデフォルト)
- → **v1 で書いた「DER→raw 64B 変換ヘルパー必須」は撤回**。`createVerify` 採用で 40 行不要に

### 代替実装 (純 WebCrypto ルート、念のため)

`nodejs_compat` が想定通り動かない場合の fallback として:

```js
function derToP1363(derSig) {
  // SEQUENCE 0x30, len, INTEGER 0x02, len_r, r..., INTEGER 0x02, len_s, s...
  // r, s をそれぞれ左 0 埋めで 32B にして連結 (= 64B)
}
const rawSig = derToP1363(sig);
const key = await crypto.subtle.importKey('spki', pubKeyDer, {name: 'ECDSA', namedCurve: 'P-256'}, false, ['verify']);
const ok = await crypto.subtle.verify({name: 'ECDSA', hash: 'SHA-256'}, key, rawSig, nonce);
```

### Race condition

- DO は single-threaded actor なので、同じ keyId への counter 更新は直列化される (★★★)
- 別 keyId は別 DO instance に分散 → スケール可能

---

## 6. 技術選定

### 6.1 永続化: Durable Object (SQLite-backed) ★★★

- **理由**: counter の単調増加チェックに race-free な single-threaded actor が必須。KV は eventual consistency で最大 60 秒の伝播遅延 → replay attack 窓ができる (Cloudflare 公式)。
- **Free プラン**: SQLite-backed DO は 2025 GA、Free で 1GB / DO まで使える。Solara DAU 1500 想定でも 1 DO で十分。
- **スキーマ**:
  ```sql
  CREATE TABLE attestations (
    key_id TEXT PRIMARY KEY,
    public_key_jwk TEXT NOT NULL,
    counter INTEGER NOT NULL DEFAULT 0,
    rp_id TEXT NOT NULL,
    aaguid TEXT NOT NULL,  -- 'production' or 'development'
    created_at INTEGER NOT NULL,
    last_used_at INTEGER NOT NULL
  );
  ```
- **DO 名前空間**: 全 keyId を 1 DO instance に詰める案 (`namespace.idFromName('global')`) vs keyId ごとに分ける案 (`namespace.idFromName(keyId)`)。前者はシンプルだが contention、後者は完全分散だが 1 keyId あたり DO instance が立つコスト。
  - **決定: 前者 (`global`)**。理由: Solara の同時刻 attestation 件数は <100/sec 想定、single DO で捌ける。後者は DO instance 数が DAU 規模に比例して billing リスク。

### 6.2 CBOR ライブラリ: 自前実装 (Apple subset のみ) ★

- **理由**:
  - `cbor` npm パッケージは Node.js Buffer 前提でサイズも大きい (~150KB)。Workers でも動くが Buffer polyfill が要る。
  - App Attest が使う CBOR は限られた subset (map / array / bytes / text / unsigned int) のみ。
  - 自前で書けば ~80 行、Workers bundle size 最小、polyfill 不要。
- **代替**: もし自前実装で詰まったら `cbor-x` (Workers 動作報告あり★) にスイッチ
- **比較**: `appattest-checker-node` は `cbor@9` を使用 (Buffer 前提 → Workers では `nodejs_compat` 必要)

### 6.3 X.509 / ASN.1: ハイブリッド ★

- **選択肢A**: `@peculiar/x509@1.9.6` (appattest-checker-node が使用) → WebCrypto ベースで Workers 互換性高い。bundle ~120KB。
- **選択肢B**: `pkijs@3.3.3` + `asn1js@3.0.7` (node-app-attest が使用) → 同じく WebCrypto ベース、Workers OK 報告あり。
- **選択肢C**: 自前 ASN.1 パーサー (~150 行)
- **決定 (暫定)**: **@peculiar/x509** を採用。理由:
  - 1 ライブラリで証明書チェーン検証 + 公開鍵抽出 + 拡張パースが全部できる
  - PeculiarVentures はブラウザ前提設計で Workers でも動作実績多数 (Web Crypto Pure)
  - appattest-checker-node が 1 年以上本番運用している実績
- **実装時の確認**: Wrangler dev で実 attestation バイトを通して E2E テスト、X.509 verify が成功するか
- **fallback**: もし `@peculiar/x509` で Workers 起動できなければ `pkijs` に切り替え

### 6.4 ECDSA 検証: WebCrypto + DER→P1363 ヘルパー ★★★

- Workers `crypto.subtle.verify` は IEEE-P1363 raw 64B のみ → 自前変換ヘルパー必須

### 6.5 Apple Root CA の持ち方: コード埋め込み ★★★

- `https://www.apple.com/certificateauthority/Apple_App_Attestation_Root_CA.pem` から取得 → コード定数として埋め込み
- **取得済証明書情報** (2026-05-19 取得、`apps/solara/docs/Apple_App_Attestation_Root_CA.pem` に保存):
  - Subject = Issuer = `CN=Apple App Attestation Root CA, O=Apple Inc., ST=California` (self-signed)
  - **SHA-256 (DER) = `1CB9823BA28BA6AD2D33A006941DE2AE4F513EF1D4E831B9F7E0FA7B6242C932`** (テストで hardcode 検証)
  - **notBefore = 2020-03-18, notAfter = 2045-03-15 (19 年有効)** → v1 で書いた「半年に1回手動更新」は **不要**、リリース後 2045 年まで放置可能
  - 公開鍵: ECDSA P-384 (`ecdsa-with-SHA384` 署名アルゴリズム想定)
- **更新監視**: release_checklist 追加は不要。**2044 年頃に Apple が次世代 Root を公開したら差し替え** (= 20 年スパン)
- **失効リスク**: Apple が前倒し失効した場合 → wrangler deploy で即差し替え可能

---

## 7. ファイル構成

```
apps/solara/worker/
├── src/
│   ├── index.js                      (既存、middleware 配線追加のみ)
│   ├── auth/                         (新設ディレクトリ)
│   │   ├── app_attest.js             (公開 API: verifyAttestation, verifyAssertion)
│   │   ├── cbor.js                   (Apple subset CBOR デコーダー ~80行)
│   │   ├── ecdsa_der.js              (DER → P1363 変換ヘルパー ~40行)
│   │   ├── apple_root_ca.js          (PEM/DER 定数 + 公開鍵 ~30行)
│   │   └── attestation_state.js      (Durable Object クラス)
│   └── (既存ファイル群)
├── wrangler.toml                     (durable_objects + migrations 追記)
├── package.json                      (@peculiar/x509 追加)
└── test/
    ├── app_attest_attestation.test.js  (Apple サンプル attestation で検証)
    ├── app_attest_assertion.test.js
    ├── cbor.test.js
    └── ecdsa_der.test.js
```

### 既存 `index.js` の変更ポイント

| 場所 | 変更 |
|---|---|
| 上部 import | `import { verifyAssertion } from './auth/app_attest.js'` 追加 |
| `protectedMiddleware` | 現状の no-op を本実装に差し替え |
| `handleAttestStub` | `verifyAttestation` 本実装に差し替え |
| `dispatchAuth` | `POST /auth/challenge` 追加 (KV 5分 TTL の random 32B) |
| 末尾 | `export { AttestationState }` (Durable Object クラス) |

### wrangler.toml 追記

```toml
[durable_objects]
bindings = [
  { name = "ATTESTATION_DO", class_name = "AttestationState" }
]

[[migrations]]
tag = "v1"
new_sqlite_classes = ["AttestationState"]   # SQLite-backed
```

---

## 8. テスト戦略

### 8.1 単体テスト (Wrangler / vitest)

| 対象 | 方法 |
|---|---|
| CBOR デコーダー | 既知ベクトル (Apple サンプル attestation の hex) を入力 → 期待 map を出力 |
| DER→P1363 変換 | OpenSSL で生成した DER 署名と raw 署名のペアでラウンドトリップ |
| Apple Root CA 公開鍵 | フィンガープリント (SHA-256) を hardcode した値と一致 |
| Attestation 9 ステップ | 既知の attestation バイト + challenge + keyId → 成功、改竄版で各失敗 |
| Assertion 6 ステップ | 同上 |

### 8.2 既知ベクトル入手

- Apple Sample Code (Establishing Your App's Integrity) の attestation bytes ❓
- appattest-checker-node リポジトリの fixtures (Apache-2.0 ライセンスなので流用可能)
- node-app-attest リポジトリの tests
- TestFlight Sandbox 端末で実 attestation を取得 (オーナー作業 → Phase 1 末)

### 8.3 E2E (TestFlight 連動)

1. Wrangler dev で local Worker 起動
2. iOS Simulator + Solara debug ビルドで `/auth/challenge` → `attestKey` → `/auth/attest`
3. 成功なら 200、DO に entry 1 件
4. `/protected/fortune` を assertion 付きで呼ぶ → 200
5. 同じ assertion 再送 → 401 (replay 防止確認)
6. signCount を巻き戻して送信 → 401 (counter 検証確認)

---

## 9. ロールアウト計画 (旧 v1、§14 で v1.1 に置換済)

v1.1 のロールアウト計画は §14 を参照。本セクションは履歴目的で残置。

---

## 10. リスクと未確認項目 🔴 (v1.1 で R2-R5/R7/R8 を確定済)

### ✅ R2 [確定 2026-05-19]: Apple Root CA フィンガープリント

- **SHA-256 (DER) = `1CB9823BA28BA6AD2D33A006941DE2AE4F513EF1D4E831B9F7E0FA7B6242C932`**
- 取得元: `https://www.apple.com/certificateauthority/Apple_App_Attestation_Root_CA.pem`
- 保存場所: `apps/solara/docs/Apple_App_Attestation_Root_CA.pem`
- 有効期限 2045-03-15

### ✅ R3 [確定 2026-05-19]: rpId 式

- **`SHA-256(UTF-8("<teamId>.<bundleId>"))`** で確定
- 根拠: [appattest-checker-node README + attestation.ts](https://github.com/srinivas1729/appattest-checker-node) の `appId: '<team-id>.<bundle-id>'`
- Solara の場合: `"<APPLE_TEAM_ID>.com.solodevlab.solara"` (TEAM_ID はオーナーが App Store Connect で確認)

### ✅ R4 [確定 2026-05-19]: AAGUID

- production = `'appattest'` (9B ASCII) + NULL バイト 7 個 = 16B
- development = `'appattestdevelop'` (16B ASCII)
- 実装は production 時 authData[37..45] (9B) だけ照合すれば OK ([appattest-checker-node attestation.ts:117-122](https://github.com/srinivas1729/appattest-checker-node/blob/main/src/attestation.ts))

### ✅ R5 [確定 2026-05-19]: OID ASN.1 ネスト深さ問題は実装パターンで回避

- `@peculiar/x509` の `getExtension(oid).toString('asn')` 出力末尾の `"OCTET STRING : <hex>"` を suffix 比較
- ネスト 2 段でも 3 段でも 4 段でも同じコードで通る ([attestation.ts:165-176](https://github.com/srinivas1729/appattest-checker-node/blob/main/src/attestation.ts))
- 自前 ASN.1 パーサールートを採用する場合のみ要注意 → 採用しないので問題なし

### ✅ R7 [確定 2026-05-19]: テスト fixtures 入手元

- [appattest-checker-node の `tests/` ディレクトリ](https://github.com/srinivas1729/appattest-checker-node/tree/main/tests) (Apache-2.0)
- `tests/assertion.test.ts` + `tests/attestation.test.ts` から fixture バイト列を抽出可能
- セッション 2 で `tools/extract_fixtures.py` を作って一括取得

### ✅ R8 [確定 2026-05-19]: clientDataHash 定義

- **Attestation**: `clientDataHash = SHA-256(challenge)` (challenge は server 発行の random 32B、それを SHA-256 する) ★★★
- **Assertion**: caller が `SHA-256(request payload bytes)` を計算してライブラリに渡す ★★★
- 根拠: [attestation.ts:172](https://github.com/srinivas1729/appattest-checker-node/blob/main/src/attestation.ts) `const clientDataHash = await getSHA256(inputs.challenge);` + [assertion.ts README](https://github.com/srinivas1729/appattest-checker-node) `clientDataHash = // SHA-256 of request contents including challenge provided to client`
- 注意点: assertion 時、challenge をリクエスト payload に含めるかどうかは設計判断 (含めるべき。replay 防止のため)

### 🔴 R1 [未確定]: @peculiar/x509 + cbor + node:crypto の Workers 実機動作

- npm の README には Workers 言及なし
- 全部 WebCrypto / 純 JS ベースなので動くはず、ただし `nodejs_compat` フラグ + Buffer polyfill が必要
- **検証方法**: セッション 2 冒頭で minimal Worker (`@peculiar/x509` で 1 本 verify + `cbor.decodeFirst` で 1 件 + `createVerify` で ECDSA verify) を `wrangler dev` で動かす
- **代替プラン**:
  - A. `pkijs + asn1js` (uebelack/node-app-attest が使う組合せ) に切り替え
  - B. 自前 ASN.1 + 自前 cbor (~250 行) に切り替え

### 🔴 R6 [実装後計測]: Workers Free プラン 10ms CPU 制限

- 証明書チェーン検証 (P-384 × 1 + P-256 × 1 = 2 段) + ECDSA verify + SHA-256 数回 = 1-5ms 想定
- DO への DB 操作は別 CPU 時間で計上
- **検証方法**: 本番 deploy 後 1 週間モニタ
- **対応**: 10ms 超過頻発なら Paid プラン $5/月 移行 (launch_checklist Phase 0 で記載済)

---

## 11. オープン課題 (オーナー判断必要)

| # | 課題 | 案 |
|---|---|---|
| Q1 | 検証失敗時のレスポンス | 401 単一 vs 詳細エラーコード (`{error: 'nonce_mismatch'}`)。後者はデバッグ便利だが攻撃者にもヒント |
| Q2 | challenge の TTL | 5 分 vs 10 分。長くすると盗難リスク、短いと iOS 側 attestation 生成遅延でタイムアウト |
| Q3 | 段階リリース時の grace period | 既存ユーザーは attestation なしで一定期間素通し? 即拒否? |
| Q4 | development AAGUID の受け入れ | 本番 Worker は production AAGUID のみ受け入れ (現状方針)。ただし TestFlight 内部テスターも production になるはずなので問題なし ★ |
| Q5 | Apple Root CA 更新 | 半年に 1 回手動チェック vs 自動 fetch + cache |

**推奨**:
- Q1: 詳細エラーコード (社内デバッグ価値 > 攻撃者ヒント)
- Q2: 5 分 (Apple Sample Code 推奨)
- Q3: Stage 1 (JP・無料機能のみ) は middleware OFF、Stage 2 (Pro 解禁) で ON
- Q4: production only
- Q5: 手動 + release_checklist に半年タスク追加

---

## 12. 参考資料 (一次ソース)

### Apple
- Validating apps that connect to your server: https://developer.apple.com/documentation/devicecheck/validating-apps-that-connect-to-your-server (SPA, WebFetch では本文取得不可)
- Establishing your app's integrity: https://developer.apple.com/documentation/devicecheck/establishing-your-app-s-integrity (同上)
- Apple App Attestation Root CA: https://www.apple.com/certificateauthority/Apple_App_Attestation_Root_CA.pem
- App Attest server implementation thread: https://developer.apple.com/forums/thread/738923

### Cloudflare
- Web Crypto: https://developers.cloudflare.com/workers/runtime-apis/web-crypto/
- Node.js compat 2025: https://blog.cloudflare.com/nodejs-workers-2025/
- Durable Objects SQLite: https://developers.cloudflare.com/durable-objects/api/sqlite-storage-api/
- KV consistency: https://developers.cloudflare.com/kv/concepts/how-kv-works/
- workerd issue #1304 (X509Certificate): https://github.com/cloudflare/workerd/issues/1304

### 参考 OSS 実装
- appattest-checker-node (v1.0.3, Apache-2.0): https://github.com/srinivas1729/appattest-checker-node
  - 依存: @peculiar/x509@^1.9.6 + cbor@^9.0.1 + json-stable-stringify
- uebelack/node-app-attest (44 stars, JS): https://github.com/uebelack/node-app-attest
  - 依存: asn1js@^3.0.7 + cbor@^10.0.11 + pkijs@^3.3.3

### 二次ソース (詳細手順解説)
- Restless Labs blog: https://blog.restlesslabs.com/john/ios-app-attest
- Medium (abhishek kureriya): https://abhishek-kureriya.medium.com/part2-validating-apps-integrity-key-in-backend-3775009f5dc7

---

## 13. 実装方針: 自前 vs npm 流用 (v1.1 で新規追加)

R2-R8 確定で「appattest-checker-node が Solara で要る機能をほぼそのまま実装している」ことが判明。実装方針として 2 つの選択肢:

### 案A: appattest-checker-node を npm 依存として導入 ★推奨

```bash
cd apps/solara/worker
npm install appattest-checker-node@^1.0.3
```

Worker 実装は ~50 行で済む:

```js
import { verifyAttestation, verifyAssertion, setAppAttestRootCertificate } from 'appattest-checker-node';
// 起動時に Apple Root CA 差し替え (ライブラリ同梱版が古い時の保険)
setAppAttestRootCertificate(APPLE_ROOT_CA_PEM);

async function protectedMiddleware(request, env) {
  const keyId = request.headers.get('X-AppAttest-KeyId');
  const assertionB64 = request.headers.get('X-AppAttest-Assertion');
  if (!keyId || !assertionB64) return jsonError(401, 'missing_attestation', origin);

  const record = await getAttestation(env, keyId); // DO から
  if (!record) return jsonError(401, 'unregistered_key', origin);

  const bodyBytes = new Uint8Array(await request.clone().arrayBuffer());
  const clientDataHash = await sha256(bodyBytes);

  const result = await verifyAssertion(
    Buffer.from(clientDataHash),
    record.publicKeyPem,
    APP_ID,  // "<teamId>.<bundleId>"
    Buffer.from(assertionB64, 'base64'),
  );
  if ('verifyError' in result) return jsonError(401, result.verifyError, origin);
  if (result.signCount <= record.signCount) return jsonError(401, 'replay', origin);

  await updateSignCount(env, keyId, result.signCount); // DO 更新
  return null; // 通過
}
```

**メリット**:
- 実装行数 ~50 行で済む (自前なら ~400 行)
- メンテナンス負荷ゼロ (security patch も npm update)
- Apple/iOS の細かい仕様変更に追随済み
- テストも流用可能

**デメリット**:
- 依存追加 (`@peculiar/x509` + `cbor` + 推移依存)
- Workers 動作確認 (R1) が必要
- bundle size 増 (推定 +200-300KB)
- ライブラリのメンテが止まったら自分でフォーク必要

**前提**: R1 (Workers 動作) クリアが必要。**セッション 2 冒頭で minimal Worker (3 関数だけ呼ぶ) を `wrangler dev` で起動できれば案A 確定**。

### 案B: 自前実装 (v1 計画通り)

```
auth/cbor.js              ~80 行
auth/ecdsa_der.js         (案A なら不要、案B でも nodejs_compat なら不要)
auth/apple_root_ca.js     ~30 行
auth/app_attest.js        ~250 行
auth/attestation_state.js ~80 行 (DO)
合計                       ~440 行 (テスト除く)
```

**メリット**:
- 依存ゼロ、bundle 最小
- 全ロジック自分でコントロール
- ライブラリ消失リスクなし

**デメリット**:
- 実装工数 5-6 セッション → 7 セッション
- 自前バグ混入リスク (App Attest は地雷多)
- メンテ負荷

### 推奨: 案A を試して、ダメだったら案B にフォールバック

理由:
1. **オーナーの「確実に安全に」と「時間かけて良い」の両立**: 案A は確実 (本番稼働実績ある実装) + 時間短縮
2. 案A の失敗パターンは限定的 (Workers で `@peculiar/x509` か `cbor@9` か `node:crypto.createVerify` のどれかが落ちる)。各々スワップ可能
3. 案B は案A のソース読解で既に手書きパターンを得ており、いつでもフォールバック可能

---

## 14. ロールアウト計画 v1.1 (案A 採用前提、案B なら +2 セッション)

```
セッション 1 ✅ (今回): 設計ドキュメント + R2-R8 確定 + Apple Root CA 取得
セッション 2: R1 検証 (minimal Worker で 3 関数動作確認) + Durable Object 実装 + apps/solara/worker/package.json に依存追加
セッション 3: /auth/challenge + /auth/attest 本実装 + 単体テスト (fixtures 流用)
セッション 4: /protected/* middleware 配線 + 既存 endpoint 連動テスト
セッション 5: TestFlight 実 iOS E2E (オーナー作業含む)
セッション 6: ドキュメント整理 + launch_checklist 更新 + メモリ更新
```

**累積工数見積もり (v1.1)**: 5 セッション × 2-3h = **10-15h** (案A) / 12-18h (案B)
v1 の 12-18h より短縮 (R2-R8 確定 + 案A 採用で)。

---

## 15. 承認

- [ ] オーナーレビュー
  - Q1-Q5 (§11) の判断
  - 案A (推奨) vs 案B の選択
  - ロールアウト計画 v1.1 の承認
- [ ] 実装着手 → セッション 2 開始 (R1 検証 + DO 実装)
