# App Attest サーバー検証 設計ドキュメント

**ステータス**: ドラフト v1 (2026-05-19 起案)
**対象**: Cloudflare Worker `solara-api` の `/auth/attest` + `/protected/*` ミドルウェア
**前提**: `project_solara_launch_checklist.md` Phase 1 認証ミドルウェア
**関連**: `project_solara_security_principles.md` 原則 1〜3

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
| **rpId** | Relying Party ID = `<teamId>.<bundleId>` (例: `XXXXXXX.com.solodevlab.solara`) ❓ |
| **AAGUID** | 認証器種別 GUID。development = `appattestdevelop` (16B UTF-8), production = `appattest` + 7 NULL バイト (16B) ★★ |

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
| 0..31 | 32 | rpIdHash = SHA-256(`<teamId>.<bundleId>`) ❓ |
| 32 | 1 | flags |
| 33..36 | 4 | signCount (big-endian uint32) |
| 37..52 | 16 | AAGUID |
| 53..54 | 2 | credentialId length (big-endian uint16) |
| 55..(55+len-1) | var | credentialId (= SHA-256(publicKey)) |
| (残り) | var | credentialPublicKey (COSE_Key, CBOR) |

### 9 ステップ

| # | 内容 | 失敗時 |
|---|---|---|
| 1 | x5c[0] と x5c[1] を Apple App Attest Root CA でチェーン検証 | 400 invalid_cert_chain |
| 2 | clientDataHash = SHA-256(challenge), nonce = SHA-256(authData ‖ clientDataHash) | (計算のみ) |
| 3 | credCert の拡張 OID `1.2.840.113635.100.8.2` を抽出 → DER の SEQUENCE → \[0\] OCTET STRING を取り出し、上記 nonce と バイト一致 ★★ | 400 nonce_mismatch |
| 4 | credCert から公開鍵抽出 → DER (SPKI) → SHA-256(uncompressed EC point) = keyId と一致 | 400 keyid_mismatch |
| 5 | authData の rpIdHash == SHA-256(`<teamId>.<bundleId>`) | 400 rpid_mismatch |
| 6 | authData.signCount == 0 ★★ | 400 counter_not_zero |
| 7 | authData.AAGUID == (production: `appattest\x00\x00\x00\x00\x00\x00\x00` / development: `appattestdevelop`) ★★ | 400 aaguid_mismatch |
| 8 | authData.credentialId == keyId ★★ | 400 credential_id_mismatch |
| 9 | 公開鍵 (P-256 EC) を JWK 形式で抽出して DO に永続化 `{keyId → {publicKeyJwk, counter: 0, createdAt}}` | (成功時) |

### 地雷ポイント

- **★ OID 値の二重ネスト**: SEQUENCE の中にさらに SEQUENCE があり、その中に OCTET STRING がある場合と、SEQUENCE 直下に OCTET STRING がある場合の両方が観測されている (Apple Developer Forums の C++ Botan 実装は 3 段ネストで decoder.get_next_object() を 3 回呼んでいる)。実装時は両方のパスを試すか、ASN.1 dumper で実 attestation を見る。
- **★★ Receipt は今回保存しない**: 初回実装では受領した receipt をそのまま DO に保存する想定だが、Apple Server-to-Server API (App Store Receipt 検証) は別仕事なので Phase 2 で。Receipt サイズは ~5KB なので 1GB DO で問題なし。
- **❓ rpId の正確な式**: 公式ドキュメントの直接確認はできず。**Apple Developer Forum + 二次ソースでは `<teamId>.<bundleId>` 形式が一般的**だが、bundleId 単体説もある。実装時に SHA-256 を両方計算して照合する単体テストを書く。

---

## 5. Assertion 検証 (毎リクエスト 6 ステップ)

### 入力
- `assertion_b64`: Base64 CBOR
- `keyId_b64`: ヘッダから
- `payload`: リクエスト body (raw bytes)

### CBOR デコード結果

```js
{
  signature: <bytes>,           // ECDSA P-256 SHA-256, DER 形式 ★
  authenticatorData: <bytes>,   // rpIdHash 32 + flags 1 + signCount 4 (= 37B)
}
```

### 6 ステップ

| # | 内容 |
|---|---|
| 1 | DO から `{publicKeyJwk, lastCounter}` を keyId で取得。なければ 401 unregistered_key |
| 2 | clientDataHash = SHA-256(payload), nonce = SHA-256(authenticatorData ‖ clientDataHash) |
| 3 | nonce を ECDSA-P256-SHA256 で publicKey + signature で verify ★ |
| 4 | authenticatorData の rpIdHash == 期待値 |
| 5 | authenticatorData.signCount > lastCounter (strict greater) |
| 6 | DO の counter を新値で更新 (transaction) |

### 大地雷: 署名フォーマット変換 ★★

- **Apple は DER (SEQUENCE { r INTEGER, s INTEGER })** で署名 (libfido / WebAuthn と同じ)
- **WebCrypto `subtle.verify` は IEEE-P1363 raw 64B (r ‖ s) のみ** 受け付ける (W3C 仕様準拠)
- → **DER → raw 64B の変換ヘルパーを自前実装** か、`node:crypto.createVerify('SHA256').verify(pubKeyPem, sig, 'der')` を `nodejs_compat` 経由で使う

ヘルパー実装案 (40 行):
```js
function derToP1363(derSig) {
  // SEQUENCE 0x30, len, INTEGER 0x02, len_r, r..., INTEGER 0x02, len_s, s...
  // r, s をそれぞれ左 0 埋めで 32B にして連結 (= 64B)
}
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

### 6.5 Apple Root CA の持ち方: コード埋め込み ★★

- `https://www.apple.com/certificateauthority/Apple_App_Attestation_Root_CA.pem` を取得 → DER 化 → JS 定数として埋め込み
- **理由**:
  - Root CA は ~10年単位で安定 (Apple 公開鍵証明書方針)
  - fetch すると Worker cold start が遅くなる + 失敗時の fallback 設計が複雑
  - 失効時は wrangler deploy で即差し替え可能
- **更新監視**: 半年に 1 回 Apple Certificate Authority ページを目視確認 (release_checklist に追加)

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

## 9. ロールアウト計画

```
セッション 1 (今回): 設計ドキュメント (このファイル) ← 完了
セッション 2: CBOR デコーダー + DER→P1363 ヘルパー + Apple Root CA 定数 + 単体テスト
              (純粋関数のみ、外部依存なし、テストファースト)
セッション 3: @peculiar/x509 導入 + 証明書チェーン検証 + nonce 抽出 + 単体テスト
              (npm 依存追加、Wrangler dev 起動確認)
セッション 4: Durable Object 実装 + attestation 永続化 + /auth/attest 本実装
              (DO migration 検証、wrangler deploy --dry-run)
セッション 5: assertion verify + protectedMiddleware 配線 + 既存 endpoint 連動テスト
              (本番 deploy 一歩手前、staging 環境想定)
セッション 6: TestFlight 連動 E2E (オーナー作業含む、実 iOS から attestation 取得)
              実 attestation で各ステップ通過確認、本番 deploy
セッション 7: ドキュメント整理、メモリ更新、launch_checklist 更新
```

**累積工数見積もり**: 5-6 セッション × 2-3h = **12-18h** (security_principles の「4日 = 32h」より楽観だが、設計を先に固めた効果で短縮可能と判断。地雷で延びたら最大 24h まで許容)

---

## 10. リスクと未確認項目 🔴

### R1: @peculiar/x509 の Workers 実機動作 ★

- npm の README には Workers 言及なし
- 内部実装は WebCrypto + asn1js なので動くはず
- **検証方法**: セッション 3 冒頭で minimal Worker (証明書 verify 1 行) を Wrangler dev で動かす
- **代替**: pkijs に切り替え (同じ作者の PeculiarVentures)

### R2: Apple Root CA のフィンガープリント未確定 ★

- 二次ソースで URL は `Apple_App_Attestation_Root_CA.pem` と確認できたが、SHA-256 フィンガープリントを公式から直接引用できていない
- **検証方法**: セッション 2 で curl で取得 → openssl x509 -fingerprint で計算 → 単体テストに hardcode

### R3: rpId の正確な式 (teamId.bundleId vs bundleId 単体) ❓

- 二次ソース (Medium 等) は teamId.bundleId 派が多いが Apple 公式の本文を直接読めず
- **検証方法**: 実 attestation の authData[0..31] を SHA256(候補) と比較する単体テストを両パターンで書く

### R4: AAGUID production の正確なバイト列 ★★

- 二次ソースで `appattest` + 7 NULL バイト = 16B と確認
- ただし「7 NULL」と「9 NULL」のソース両方を見かけた疑念
- **検証方法**: `Buffer.from('appattest').length` = 9 → 残り 7 = 16B で確定 ★★★ (これは計算で確定できる)

### R5: OID 1.2.840.113635.100.8.2 の ASN.1 ネスト深さ ❓

- Apple Forum の C++ Botan 実装は 3 段ネスト (`SEQUENCE → CONSTRUCTED → OCTET STRING`)
- 一方 Medium 解説では 2 段 (`SEQUENCE → OCTET STRING`)
- **検証方法**: 実 credCert を OpenSSL `asn1parse` で dump → 実装に反映

### R6: Workers Free プラン 10ms CPU 制限 ★★

- 証明書チェーン検証 (RSA 2048 or ECDSA P-256 × 2 段) + ECDSA verify は 1-3ms 想定
- DO への DB 操作は別 CPU 時間で計上
- **検証方法**: Wrangler dev でログ計測、本番 deploy 後 1 週間モニタ
- **対応**: 10ms 超過頻発なら Paid プラン $5/月 移行 (launch_checklist Phase 0 で記載済)

### R7: テスト用 attestation 入手 ★

- 開発初期は実 iOS デバイスがない時点で単体テストを書きたい
- **対策**: appattest-checker-node の fixtures (Apache-2.0) を流用、後で実機データに差し替え

### R8: clientDataHash の正確な定義 ★

- 「サーバー発行 challenge の SHA-256」というのが本ドキュメントの理解だが、Apple の "client data" は WebAuthn 由来で JSON 形式の可能性もある
- **検証方法**: appattest-checker-node のソース実装で確認 (`SHA256(rawChallenge)` で良いはず)

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

## 13. 承認

- [ ] オーナーレビュー (Q1〜Q5 の判断、ロールアウト計画の承認)
- [ ] 実装着手 → セッション 2 開始

オーナーが承認 (or 修正指示) したら、次セッションで `auth/cbor.js` + `auth/ecdsa_der.js` + `auth/apple_root_ca.js` の 3 ファイル + それぞれの単体テストから着手する。
