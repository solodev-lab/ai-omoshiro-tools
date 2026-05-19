# App Attest サーバー検証 設計ドキュメント

**ステータス**: 確定 v3.0 (S1-S6 全完了、Flutter + Worker 両側コード完成、残: TestFlight 実機 E2E + 本番 deploy のオーナー作業のみ。詳細は §17/§18)
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

### v1.1 → v1.2 の変更点 (2026-05-19)
- Q1-Q5 オーナー判断確定 (§11 を「決着済み」に置換):
  - Q1: 詳細エラーコード採用 / Q2: 5min TTL / Q3: **初回公開から middleware ON** (Stage 1 スキップ確定) / Q4: production only / Q5: Root CA 更新不要 (v1.1 で解決済)
- Q3 波及: launch_checklist.md Phase 6 Stage 1/Stage 2 を **「初回から Pro 解禁付き JP 公開」に統合**。Pro 無効化フラグ実装不要、`/protected/*` middleware は初日から本実装

### v1.2 → v1.3 の変更点 (2026-05-19、徹底再調査の結果)
- 案 A/B 評価が **二重に間違っていたことを発見**:
  - node-app-attest は **Workers 非対応** (`node:crypto.X509Certificate` 使用、workerd issue #1304 で未サポート確定)
  - appattest-checker-node は Workers 互換だが 1.5 年メンテ停止
- **案 B' ハイブリッド** (= @peculiar/x509 のみ npm、CBOR + 検証ロジック + DO は自前 = node-app-attest 写経) を新規追加 → オーナー判断で確定
- R5 OID ASN.1 ネスト深さは **3 段** で確定 (node-app-attest 実装 `value[0].value[0].valueHex` + Apple Forum C++ Botan 実装と一致 ★★★)
- production 知見追加 (adjoe blog): DCError.invalidInput/invalidKey 時の Flutter 側リトライ要件、challenge 5 分 TTL 実運用根拠
- §13 実装方針 §14 ロールアウトを案 B' 前提に書き換え

### v2.0 → v2.1 の変更点 (2026-05-19、S6-A 完了: Flutter `AppAttestClient` 基盤)

**`apps/solara/pubspec.yaml` 追加**:
- `app_attest_integrity: ^1.0.0` (bam.tech、pub points 150、stable 1.0.0 採用。memory `^2.0.0-dev.1` は古情報で訂正)
- `crypto: ^3.0.6` (Flutter 側 payload SHA-256 計算用、debug 確認も含む)

**`apps/solara/lib/utils/solara_api.dart` 追加**:
- `solaraChallengeUrl = '$solaraWorkerBase/auth/challenge'`

**`apps/solara/lib/utils/app_attest_client.dart` 新規** (~200 行):
- `AppAttestClient` シングルトン (`AppAttestClient.instance`)
- `initialize()`: SharedPreferences (`solara_appattest_key_id_v1`) から keyId 復元 or 新規 attest
- `_attestNewKey()`: Worker `/auth/challenge` → `iOSgenerateAttestation(String challengeB64)` → Worker `/auth/attest`
  - 設計訂正: package API は `String` 引数 (Uint8List 不可)、戻り値も `String` (base64)
- `addHeaders(headers, payloadBytes)`: `verify(clientData: base64(bytes), iOSkeyID: keyId)` → `X-AppAttest-{KeyId,Assertion}` ヘッダ注入
- `postProtected(url, payload)`: jsonEncode → utf8.encode で bytes 確定 → addHeaders + http.post (設計 v1.8 §16.2 規約準拠)
- `reattestOnFailure()`: DCError.invalidKey 等の 401 リトライ用、SharedPreferences 削除 + 新規 attest
- `_shouldBypass`: kIsWeb || !Platform.isIOS || kDebugMode で bypass (実機 release のみ有効)

**`apps/solara/lib/main.dart` 統合**:
- `AppAttestClient.instance.initialize()` を SolaraAuth.load() 直後に unawaited で呼ぶ
- 失敗してもアプリ起動は止めない (= bypass モードで通過、Worker side log_only で何とかなる)

**flutter analyze**: No issues found! (型チェック clean)

**残作業 (= 別 commit で段階的)**:
- 既存 4 protected/* endpoint 呼び出し置換 (fortune/tarot/relocation/consultation の各 dart file) を `postProtected()` wrapper 経由に書き換え
  - 一括置換だと既存動作を壊すリスクあるので、1 endpoint ずつテスト + commit 推奨
  - middleware が log_only モードなので、ヘッダ無しでも当面動く (= 順序を急がない)

**実機テスト未確認の懸念**:
- `app_attest_integrity` package が `clientData` (base64 string) を **base64 decode → SHA-256** するか、**生 string を SHA-256** するか pub.dev README で明示なし。前者前提で実装、後者ならズレる。**TestFlight 実機テスト (S6-B) で実際の assertion verify 通過するか必須確認**

### v1.9 → v2.0 の変更点 (2026-05-19、S5 完了: 本番 worker 配線)

**`apps/solara/worker/wrangler.toml` 更新**:
- `compatibility_flags = ["nodejs_compat"]` 追加 (node:crypto createHash/createVerify 用)
- `[[durable_objects.bindings]]` + `[[migrations]]` で `AttestationState` を SQLite-backed DO として登録 (tag v1)
- `[vars]` に追加: APPLE_TEAM_ID, APPLE_BUNDLE_ID (両方 public 情報), APP_ATTEST_ENFORCEMENT (`log_only` default), APP_ATTEST_QUOTA_FREE (5), APP_ATTEST_QUOTA_PRO (100), APP_ATTEST_CHALLENGE_TTL_SEC (300)

**`apps/solara/worker/src/index.js` 更新** (+~200 行):
- `import { verifyAttestation, verifyAssertion } from './auth/app_attest.js'`
- `export { AttestationState } from './auth/attestation_state.js'` (Worker entry から DO class を re-export)
- `callDo(env, path, body)` ヘルパー追加 (DO 6 endpoint への共通呼び出し)
- `getEnforcement(env)` helper (disabled/log_only/enforced)
- `handleAuthChallenge(env, origin)`: random 32B 生成 → DO INSERT → `{challengeId, challenge: base64, ttlSec}` 返却
- `handleAuthAttest(request, env, origin)`: 4 step (challenge consume → verifyAttestation → DO 永続化)
- `protectedMiddleware(request, env)` 本実装: 5 step (DO から公開鍵取得 → body clone で payload bytes 取得 → verifyAssertion → signCount bump → quota check)
- `dispatchAuth` を `(request, env, url, origin)` シグネチャに変更、`/auth/challenge` 追加、stub 関数を本実装に置換

**`APP_ATTEST_ENFORCEMENT` 段階リリース機構**:
- `"disabled"`: middleware 完全スキップ (緊急 kill switch)
- `"log_only"`: 検証走るが失敗しても通す + `console.warn` (初回 deploy 推奨、Flutter 側未対応時の安全運用)
- `"enforced"`: 失敗時 401 (Flutter 側完成 + 1 週間モニタ後に切替)

**実機検証 (wrangler dev local)**:
- `/public/health` → 200 ✅
- `/auth/whoami` → 200 stub ✅
- `/auth/challenge` → 200 `{challengeId, challenge: base64, ttlSec: 300}` ✅ (DO INSERT 成功確認)
- `/auth/attest` with 不在 challengeId → 401 `invalid_challenge` ✅ (DO consume 404)
- `/auth/attest` with 実 challenge + 不正 attestation → 401 (verifyAttestation fail) ✅
- `/protected/fortune` with no headers → log_only モードで通過 + `[middleware:log_only] would block 401 missing_attestation_headers` warning ✅ (fortune は GEMINI_API_KEY 未設定で 500 だが middleware 配線とは無関係)

**bundle 増分**: R1 minimal 565 KiB → **本番 worker 794 KiB / gzip 156.29 KiB = Workers Free 1MB の 16%** (既存 worker handler 群 + astronomy-engine 込みで +230 KiB、依然超余裕)

**bindings 全 登録確認**: ATTESTATION_DO (Durable Object) + 6 env vars (APPLE_TEAM_ID / APPLE_BUNDLE_ID / APP_ATTEST_ENFORCEMENT / QUOTA_FREE / QUOTA_PRO / 既存)

### v1.8 → v1.9 の変更点 (2026-05-19、S4 完了: verifyAssertion + DO)

**実装完了**:
- `src/auth/app_attest.js` に `verifyAssertion` 追加 (~80 行):
  - CBOR decode → ECDSA P-256 DER signature verify (`createVerify('SHA256').update(nonce).verify(pem, derSig)`) → rpId 一致 → signCount 抽出
  - Step 5/6 は caller 責任 (DO で signCount monotonic 比較、Apple step 6 は v1.8 §16.3 で不採用)
  - 失敗時は throw せず `{ok: false, error: '<code>'}` を return (Q1 詳細エラーコード)
- `src/auth/attestation_state.js` 新規 (~190 行): SQLite-backed Durable Object
  - 3 表 (attestations + challenges + user_quota) を 1 instance に集約
  - 6 endpoint (`/challenge-{create,consume}` `/attestation-{store,get,bump-counter}` `/quota-check-and-bump`)
  - challenge consume / signCount monotonic / quota limit はすべて DO の single-thread で race-free

**テスト**:
- `test/app_attest.test.js` verifyAssertion 7 テスト追加 (正常系 + payload 改竄 + bundle/team 改竄 + 別公開鍵 + 不正 CBOR + 入力バリデーション 5 種) → **app_attest 27/27 PASS**
- r1_check に DO 統合 smoke test endpoint 追加 → wrangler dev 経由で **11 操作全 PASS**:
  - challenge 1 回限り使用 (404 で replay 防止確認)
  - signCount monotonic (409 で後退拒否確認)
  - per-user rate limit 上限 3 で 4 回目 429 (Layer C 動作確認)

**bundle 増分**: 552 → **565 KiB / gzip 91.62 KiB** = Workers Free 1MB の 9.0% (verifyAssertion + DO で +13 KiB)

### v1.7 → v1.8 の変更点 (2026-05-19、S4 着手前の追加設計判断)

**Firebase App Check 代替案検討 → 不採用 (現状継続)**:
オーナー指示で「もっと簡潔で画期的な方法」を公式情報中心に再調査。Firebase App Check が実装大幅簡素化 (Worker 50 行 + Flutter 30 行) の候補として有力だったが、**Apple サーバー依存頻度が逆転する点** (現状: 1 端末 1 回 / Firebase: 毎時 30 分) + 7 日 TTL 0% verified 障害事例 + ロックインリスクで不採用。

**§16.2 payload 正規化規約 新設 (= verifyAssertion の信頼性根幹)**:
Flutter ↔ Worker で SHA-256 する bytes が完全一致しないと assertion 検証が全失敗する (Firebase 0% verified の構造類似)。規約:
1. Flutter: `jsonEncode(map) → utf8.encode → Uint8List` で payload bytes を確定、その bytes をそのまま HTTP body に
2. Worker middleware: `request.arrayBuffer()` で raw bytes を取得 (`request.json()` でも同等のはずだが念のため raw)
3. middleware → handler への passing は bodyBytes を context に積んで再利用 (二重 read 禁止)
4. CI チェック: 既知 JSON 文字列で Dart 側と JS 側の SHA-256 hex が完全一致することを Flutter test + Node test 両方で確認

**§16.3 Apple step 6 (challenge inclusion) 不採用の根拠を明文化**:
Apple 公式 step 6 「embedded challenge in client data == earlier challenge」を厳格に満たさない (= payload に server-issued challenge を含めない、signCount monotonic + DO consume で replay 防止)。理由:
- step 6 の脅威モデルは「中間者が challenge を盗み別 payload で assertion 生成」だが、これは **Secure Enclave 内 private key へのアクセスが前提**で実質不可能。攻撃成功時は challenge inclusion でも防げない
- 既存防御 (signCount monotonic + DO consume + signature verify) で replay は完全防御
- latency +1 round-trip を引き換えに防げる攻撃が存在しないので **UX 悪化のみが残るアンチパターン**
- Apple 審査リジェクト時の応答テンプレ: payload に request 固有 nonce (タイムスタンプ + UUID) を含めて step 6 を満たす実装に切替可能 (~1 セッション対応)

**Layer C: per-user rate limit を S4 統合 (オーナー判断 2026-05-19)**:
DO に `user_quota` 表を追加。attestations + challenges + user_quota の 3 表を 1 DO instance (`idFromName('global')`) で管理。Free=日 5 リクエスト / Pro=日 100 リクエスト等の上限。launch_checklist Phase 1 別タスクから S4 統合へ前倒し (= attestation 突破時の被害最大化を防ぐ最重要層)。Layer A (Apple step 6 厳格) と比べて ROI 圧倒的高い。

**Layer D / Layer E (オーナー側 / 後続セッション)**:
- Layer D (Cloudflare Bot Fight Mode): オーナー Cloudflare Dashboard で 1 クリック有効化 (リスクゼロ、効果大)
- Layer E (異常検知アラート): launch_checklist Phase 6 に追加、本番 deploy 後の運用

### v1.6 → v1.7 の変更点 (2026-05-19、時刻チェック C+D 追加 + 私の誤記訂正)

オーナー指摘「signatureOnly: true は問題ある?対策できる?」を受けて再評価:

**誤記訂正 (v1.6 → v1.7)**:
- v1.6 で「node-app-attest と appattest-checker-node は両方 signature only」と書いたが、これは半分嘘
  - node-app-attest: `node:crypto.X509.verify(publicKey)` → 確かに signature only ✅
  - appattest-checker-node: `@peculiar/x509` の `cert.verify({publicKey})` を **デフォルト動作のまま使用** → 時刻チェック ON ❌ (私の v1.6 記述ミス)
- つまり私の `signatureOnly: true` 採用は **業界標準を半分しか満たしておらず**、appattest-checker-node より「ゆるい」設定だった

**案 C+D 採用 (Step 1.5 新規)**:
- (C) 未来発行 credCert/subCa を block: `notBefore > now + 5分 skew` → `fail_credcert_future_issued` / `fail_subca_future_issued` で 401 (= 偽証明書の兆候を捕まえる)
- (D) 期限切れ credCert/subCa は通すが `console.warn` で警告ログ: Cloudflare Workers ログから本番監視で異常検知可能。Firebase + App Check の 0% verified 障害パターンを避けつつ運用観測点を残す
- clock skew 許容 5 分 (時計ズレで偽陽性を防ぐ)
- これで appattest-checker-node より「未来発行 block」分だけ厳しく、「expired を通す」分はゆるい (が監視可能) という中間地点に到達

**実装**: `app_attest.js` Step 1 直後に Step 1.5 セクション追加 (16 行)、`verifyAttestation` に optional `now` パラメータ追加 (テスト時刻 mock 用、本番は `Date.now()` default)

**テスト追加**: 17/17 → **20/20 PASS** (`時刻チェック C` 未来発行 block、clock skew 5 分許容、`時刻チェック D` expired credCert で console.warn 発火確認)

### v1.5 → v1.6 の変更点 (2026-05-19、セッション 3 verifyAttestation 実装)
- **auth/app_attest.js verifyAttestation 実装完了** (~210 行、9 step、node-app-attest 写経パターンを @peculiar/x509 で書き直し)
- **auth/apple_root_ca.js**: Apple Root CA PEM + AAGUID 定数 (production / development) + 6 helper (concat/equal/toHex/toBase64/readUint16BE/readUint32BE) を 95 行で集約
- **17/17 test PASS** (production + development fixture + 改竄ケース 6 種 + 入力バリデーション 5 種 + receipt 改竄が ok:true で返る設計確認)
- **重要発見: @peculiar/x509 の `Certificate.verify` はデフォルトで notBefore/notAfter 時刻チェックする**。fixture は credCert notAfter = 2024-12-21 で expired のためチェーン検証が落ちた → `signatureOnly: true` オプションを追加して signature のみ検証に切替 (node-app-attest が使う node:crypto.X509.verify と同じ動作)。本番でも採用 (実利が薄い + Apple iOS 側で attestation 再取得を強制する機構あり)
- **R3 Workers 実機確認**: r1_check Worker に `/r1/verify_attestation` POST エンドポイント追加 → wrangler dev 起動 → fixture を POST → production / development 両方とも ok: true, environment 正しく識別、publicKeyPem は正しい P-256 SPKI PEM
- **bundle 増分**: 540 → **552 KiB / gzip 88.72 KiB** (verifyAttestation + cbor + apple_root_ca で +13 KiB)、Workers Free 1MB の 8.7%
- 新ファイル: `worker/src/auth/{apple_root_ca.js, app_attest.js}`、`worker/test/app_attest.test.js`
- 変更: `worker/r1_check/src/index.js` に `/r1/verify_attestation` 追加

### v1.4 → v1.5 の変更点 (2026-05-19、セッション 2 実機検証)
- **R1 突破**: minimal Worker (`apps/solara/worker/r1_check/`) で `@peculiar/x509` + 自前 CBOR + `node:crypto.createVerify` の 3 操作が wrangler dev で動作確認 → 案 B' 確定 (フォールバック pkijs 不要)
- **bundle 実測**: 既存 worker 229 KiB → R1 + @peculiar/x509 込み 540 KiB / gzip 86 KiB = **Workers Free 1MB 制限の 9%** (R6 から bundle 部分を切り出し、R6' = CPU 制限のみ残オープン)
- **auth/cbor.js 実装**: 119 行 Apple subset デコーダ (major 0/2/3/4/5、length encoding 0..2^32)、Buffer 非依存
- **cbor 単体テスト 26/26 PASS**: 基本 + length encoding + エラー 7 種 + 実 attestation fixture (production/development) の AAGUID バイト一致 + assertion fixture の DER 署名 SEQUENCE marker 確認
- 設計 §10 R1 を `✅ 実機検証通過`、R6 を bundle 部分 (✅) と CPU 部分 (R6' 🔴) に分割
- 新ファイル: `worker/src/auth/cbor.js`、`worker/test/cbor.test.js`、`worker/test/fixtures/{attestation-production.json, attestation-development.json, assertion.json, NODE_APP_ATTEST_LICENSE}`、`worker/r1_check/{src/index.js, wrangler.toml, README.md}`、`worker/.gitignore`
- 依存追加: `@peculiar/x509@^1.14.3` (worker/package.json + package-lock.json)

### v1.3 → v1.4 の変更点 (2026-05-19、challenge race condition 解決 + Team ID 確定)
- **🔴 challenge 保管を KV → DO に変更** (Firebase + App Check の 0% verified 障害と同じ構造的バグを未然回避):
  - KV は eventual consistency 最大 60 秒 → クライアントが challenge 受け取り直後 (1-2秒) に別 PoP 経由で `/auth/attest` を叩くと「書き込みがまだ伝播していない」事故
  - DO は single-threaded actor で強整合性 → write 直後の read で必ず取れる
  - 同じ DO instance (`idFromName('global')`) に counter と challenge を統合管理 (追加コストゼロ)
  - **consumed マーク**で replay 防止も自然成立
- §6.1 DO スキーマに `challenges` テーブル追加
- §3 データフロー図の `/auth/challenge` を KV → DO に書き換え
- §11 に Q6 「challenge 保管方法」決着 (DO 採用、KV 不採用)
- §16 確定値に Apple Team ID `TY5JW393Q5` + Bundle ID + rpId テストベクトル追加 (前 commit、v1.3 範囲)
- §15 セッション 2 開始前チェックリストの Team ID 共有を完了マーク (前 commit)
- §15 fixture ライセンス確認漏れ (MIT、v1.3 の Apache-2.0 誤記訂正) を追記 (前 commit)

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
│            │  ② { challengeId,            │  → DO INSERT:    │
└────┬───────┘     challenge: base64(32B) } │   challenges 表  │
     │            (DO 強整合、5分 TTL)       │   (5min 後 expire)│
     │                                      └──────┬───────────┘
     │ DCAppAttestService.generateKey() → keyId    │
     │ DCAppAttestService.attestKey(keyId,         │
     │   SHA256(challenge))                        │
     ▼                                              ▼
     ③ POST /auth/attest                  ┌──────────────────┐
        { keyId, challengeId,              │ Worker           │
          attestation_b64 }                │ /auth/attest     │
     ───────────────────────────────────►  │                  │
                                            │ a. DO から       │
                                            │    challenge 取得 │
                                            │    (consumed=NULL)│
                                            │ b. 9 ステップ検証 │
                                            │ c. DO 更新:       │
                                            │   - attestations  │
                                            │     {keyId,pubKey,│
                                            │      counter:0}   │
                                            │   - challenges    │
                                            │     consumed_at   │
                                            │     (replay 防止) │
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
- **スキーマ (v1.8 で user_quota 表追加、計 3 表)**:
  ```sql
  -- 端末ごとの attestation 永続化 (1 端末 1 行、書き込み = 初回 attest 時のみ)
  CREATE TABLE attestations (
    key_id TEXT PRIMARY KEY,
    public_key_pem TEXT NOT NULL,
    counter INTEGER NOT NULL DEFAULT 0,
    rp_id TEXT NOT NULL,
    aaguid TEXT NOT NULL,  -- 'production' or 'development'
    created_at INTEGER NOT NULL,
    last_used_at INTEGER NOT NULL
  );

  -- v1.4 追加: server 発行 challenge の強整合性管理
  -- KV だと eventual consistency 60s でクライアントが受け取った直後の検証が失敗する
  -- (Firebase + App Check の 0% verified 障害事例と同じパターン)
  CREATE TABLE challenges (
    challenge_id TEXT PRIMARY KEY,        -- UUID v4
    challenge_bytes BLOB NOT NULL,        -- 32B random
    expires_at INTEGER NOT NULL,          -- unix ms、now() + 300_000
    consumed_at INTEGER                   -- 使用済み記録 (replay 防止)、NULL=未使用
  );
  CREATE INDEX idx_challenges_expires ON challenges(expires_at);

  -- v1.8 追加: Layer C per-user rate limit (attestation 突破時の被害最大化防止)
  -- key_id ごとに day_bucket (YYYY-MM-DD) 単位でカウント。
  -- Free=5/日、Pro=100/日 (Worker 側で isPro を判定して上限値選択)。
  -- 月跨ぎで自動 cleanup (毎回 INSERT 時に古い day_bucket を DELETE)。
  CREATE TABLE user_quota (
    key_id TEXT NOT NULL,
    day_bucket TEXT NOT NULL,             -- 'YYYY-MM-DD' (UTC)
    count INTEGER NOT NULL DEFAULT 0,
    last_used_at INTEGER NOT NULL,
    PRIMARY KEY (key_id, day_bucket)
  );
  CREATE INDEX idx_user_quota_day ON user_quota(day_bucket);
  ```
- **challenge cleanup**: `/auth/challenge` の INSERT 前に `DELETE FROM challenges WHERE expires_at < ?` を実行 (毎リクエスト cleanup、DO alarm 不要)
  - 大量の expired 行が溜まる懸念は、5 分 TTL × 1500 DAU の challenge 発行頻度なら最大 ~50 行で無視可能
  - 万一の暴走対策として `idx_challenges_expires` インデックスで DELETE 高速化
- **DO 名前空間**: 全 keyId を 1 DO instance に詰める案 (`namespace.idFromName('global')`) vs keyId ごとに分ける案 (`namespace.idFromName(keyId)`)。前者はシンプルだが contention、後者は完全分散だが 1 keyId あたり DO instance が立つコスト。
  - **決定: 前者 (`global`)**。理由: Solara の同時刻 attestation 件数は <100/sec 想定、single DO で捌ける。後者は DO instance 数が DAU 規模に比例して billing リスク。

### 6.2 CBOR ライブラリ: 自前実装 (Apple subset のみ) ★★

- **理由**:
  - npm の `cbor` は Node.js Buffer 前提でサイズ ~150KB、Workers でも動くが Buffer polyfill 要
  - App Attest CBOR は限定 subset (map / array / byte string / text string / unsigned int の 5 型) のみ
  - 自前で書けば ~80 行、Workers bundle 最小、polyfill 不要、全 logic 把握
- **テスト**: node-app-attest tests/fixtures の attestation/assertion 実バイトで decode 結果一致確認

### 6.3 X.509 / ASN.1: @peculiar/x509 (案 B' 採用部分) ★★★

- **採用**: `@peculiar/x509@^1.9.6` (Cloudflare 自身が PeculiarVentures ライブラリのユーザー、Workers 互換性事実上保証)
- **役割**:
  - 証明書チェーン検証 (`cert.verify({publicKey: issuer.publicKey}, crypto)`)
  - credCert からの公開鍵抽出 (PEM/SPKI format)
  - 拡張 OID 取得 (`getExtension('1.2.840.113635.100.8.2').toString('asn')`)
- **bundle 推定**: ~120KB (gzip)
- **fallback**: 動かなければ `pkijs + asn1js` (MIERUNE fork で Workers 動作実績)
- **NG な選択肢**: `node:crypto.X509Certificate` (Workers 未対応) → 故に node-app-attest 直接利用は不可

### 6.4 ECDSA 検証: `node:crypto.createVerify` (DER 変換不要) ★★★

- `wrangler.toml` に `compatibility_flags = ["nodejs_compat"]` を入れる
- `createVerify('SHA256').update(nonce).verify(publicKeyPem, derSig)` で **DER 署名を直接 verify** 可能
- 公開鍵タイプ (ECDSA P-256) と署名フォーマット (DER) を Node 内部で自動判定
- v1 で書いた「DER→IEEE-P1363 64B 変換ヘルパー (40 行)」は **不要**

**代替** (純 WebCrypto ルート、`nodejs_compat` で `createVerify` が想定外動作した場合のみ):
- 自前 DER→P1363 変換 (~40 行) + `crypto.subtle.verify({name: 'ECDSA', hash: 'SHA-256'}, key, rawSig, nonce)`

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

## 7. ファイル構成 (案 B' 確定版)

```
apps/solara/worker/
├── src/
│   ├── index.js                      (既存、middleware 配線追加のみ)
│   ├── auth/                         (新設ディレクトリ)
│   │   ├── app_attest.js             (公開 API: verifyAttestation, verifyAssertion、~200 行
│   │   │                              node-app-attest 写経パターンを @peculiar/x509 で書き直し)
│   │   ├── cbor.js                   (Apple subset CBOR デコーダー ~80行、Buffer 非依存)
│   │   ├── apple_root_ca.js          (PEM 定数 + AAGUID 定数 ~30行)
│   │   └── attestation_state.js      (Durable Object クラス、~80行)
│   └── (既存ファイル群)
├── wrangler.toml                     (durable_objects + migrations + nodejs_compat フラグ追記)
├── package.json                      (@peculiar/x509 のみ追加)
└── test/
    ├── app_attest_attestation.test.js  (node-app-attest fixtures 流用)
    ├── app_attest_assertion.test.js
    └── cbor.test.js
```

**合計実装規模**: ~390 行 (テスト除く)
- app_attest.js: ~200 行
- cbor.js: ~80 行
- attestation_state.js: ~80 行
- apple_root_ca.js: ~30 行

**依存追加**: `@peculiar/x509@^1.9.6` のみ (推移依存 `@peculiar/asn1-schema` + `@peculiar/asn1-x509` も同 org)
**bundle 増加**: ~120KB (gzip)

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

## 9. ロールアウト計画 (旧 v1、§14 で v1.3 に置換済)

ロールアウト計画は §14 を参照。本セクションは履歴目的で残置。

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

### ✅ R5 [確定 2026-05-19]: OID ASN.1 ネスト深さ = **3 段**

- node-app-attest 実装で明示: `extension.parsedValue.valueBlock.value[0].valueBlock.value[0].valueBlock.valueHex` ([verifyAttestation.js:138-141](https://github.com/uebelack/node-app-attest/blob/main/src/verifyAttestation.js))
- 構造: `SEQUENCE { [0] EXPLICIT SEQUENCE { OCTET STRING nonce } }` = 3 段
- Apple Forum の C++ Botan 実装 (3 段、`decoder.get_next_object()` × 3) とも一致 ★★★
- 案 B' 採用なら **2 つの実装手** から選択可能:
  - **(a) 3 段直接アクセス**: pkijs 流 `value[0].value[0].valueHex` パス
  - **(b) suffix 比較**: `@peculiar/x509` の `getExtension(oid).toString('asn')` 末尾を `"OCTET STRING : <hex>"` で `endsWith` (appattest-checker-node 流、より堅牢)
- **採用**: (b) suffix 比較 (ネスト深さの将来変更にも追随、コード短い)

### ✅ R7 [確定 2026-05-19]: テスト fixtures 入手元

- [appattest-checker-node の `tests/` ディレクトリ](https://github.com/srinivas1729/appattest-checker-node/tree/main/tests) (Apache-2.0)
- `tests/assertion.test.ts` + `tests/attestation.test.ts` から fixture バイト列を抽出可能
- セッション 2 で `tools/extract_fixtures.py` を作って一括取得

### ✅ R8 [確定 2026-05-19]: clientDataHash 定義

- **Attestation**: `clientDataHash = SHA-256(challenge)` (challenge は server 発行の random 32B、それを SHA-256 する) ★★★
- **Assertion**: caller が `SHA-256(request payload bytes)` を計算してライブラリに渡す ★★★
- 根拠: [attestation.ts:172](https://github.com/srinivas1729/appattest-checker-node/blob/main/src/attestation.ts) `const clientDataHash = await getSHA256(inputs.challenge);` + [assertion.ts README](https://github.com/srinivas1729/appattest-checker-node) `clientDataHash = // SHA-256 of request contents including challenge provided to client`
- 注意点: assertion 時、challenge をリクエスト payload に含めるかどうかは設計判断 (含めるべき。replay 防止のため)

### ✅ R1 [実機検証通過 2026-05-19 セッション 2]: @peculiar/x509 + 自前CBOR + node:crypto.createVerify は Workers で動作

- **minimal Worker** (`apps/solara/worker/r1_check/`) を wrangler 4.92.0 + @peculiar/x509@1.14.3 で `wrangler dev --local` 起動 → `curl /r1/all` で 3 操作全パス確認
- **X.509**: `@peculiar/x509` で Apple Root CA を parse + 自己署名 verify 成功 (subject=issuer 一致、公開鍵アルゴリズム = ECDSA P-384 ★★★ 設計推測と一致)
- **CBOR**: 自前デコーダ 15 行が `{a:1, b:[2,3]}` を正しく decode
- **createVerify**: `createSign('SHA256').sign(privKey)` で **71 バイト DER 署名** (`0x30` SEQUENCE で始まる) → `createVerify('SHA256').verify(pubKey, derSig)` で `verifyOk: true`
- **結論**: 案 B' のすべての中核操作が `nodejs_compat` 下で動作。フォールバック (pkijs) は不要

### ✅ R6 [初期計測通過 2026-05-19 セッション 2]: bundle size は Workers Free 1MB 制限の 8.5%

- 既存 worker (`src/index.js` + astronomy-engine 等): **229.58 KiB / gzip 65.46 KiB**
- R1 minimal Worker (@peculiar/x509 + 自前 cbor + node:crypto): **540.05 KiB / gzip 85.78 KiB**
- 本実装後の予想合計: ~540 KiB / gzip ~90 KiB = Workers Free 1MB 制限 (圧縮後) の **~9%**
- 残課題: 10ms CPU 制限は本番 deploy 後 1 週間モニタ (再ラベル R6')

### 🔴 R6' [実装後計測]: Workers Free プラン 10ms CPU 制限 (R6 から bundle 部分を切り出し)

- 証明書チェーン検証 (P-384 × 1 + P-256 × 1 = 2 段) + ECDSA verify + SHA-256 数回 = 1-5ms 想定
- DO への DB 操作は別 CPU 時間で計上
- **検証方法**: 本番 deploy 後 1 週間モニタ
- **対応**: 10ms 超過頻発なら Paid プラン $5/月 移行 (launch_checklist Phase 0 で記載済)

---

## 11. 決着済み判断 (オーナー確定 2026-05-19)

| # | 項目 | 確定内容 | 実装影響 |
|---|---|---|---|
| **Q1** | 検証失敗時のレスポンス | **詳細エラーコード** (`{error: 'nonce_mismatch'}` 形式) | `verifyAttestation` の `VerifyAttestationError` enum 11 種をそのままレスポンス body に格納。HTTP status は一律 401 |
| **Q2** | challenge の TTL | **5 分** (Apple Sample Code 推奨に準拠) | `/auth/challenge` で発行する random 32B を Workers KV に `expirationTtl: 300` で保存 |
| **Q3** | リリース時の middleware ON/OFF | **初回公開から ON** ★ (Stage 1 スキップ確定 — 「すぐ Pro 解禁する」オーナー判断) | Pro 無効化フラグ実装不要、`/protected/*` middleware は初日から本実装で稼働。launch_checklist Phase 6 も同時更新 |
| **Q4** | development AAGUID 受け入れ | **production only** | `appInfo.developmentEnv = false` 固定で deploy。TestFlight 内部テスターも production AAGUID で問題なし |
| **Q5** | Apple Root CA 更新運用 | **不要** (v1.1 で R2 確定により解決済) | 有効期限 2045-03-15 で 19 年放置可能。release_checklist への追加タスクなし。Apple が前倒し失効した場合のみ wrangler deploy で差し替え |
| **Q6** (v1.4 追加) | challenge 保管方法 | **Durable Object** (KV 不採用) | KV の eventual consistency 60s で「クライアント受け取り直後の検証失敗」事故を構造的に回避 (Firebase + App Check の 0% verified 障害と同じパターン)。同一 DO instance に counter と統合管理、追加コストゼロ。`consumed_at` マークで replay 防止が自然成立 |

### Q3 (初回 ON) の波及

- launch_checklist.md Phase 6 を「Stage 1 = JP 無料機能のみ 2 週間 + Stage 2 = JP Pro 解禁アップデート」から「**Stage 1 = JP Pro 解禁付き初回公開**」に統合
- メリット: Pro 機能アップデート審査が不要、収益化早期化、Pro 無効化フラグ実装不要
- リスク: 初回審査で paywall 全 9 項目 + 自動更新表記 + 法務 3 点が一斉チェック → リジェクト確率上がる
- 対応: TestFlight 内部テストで paywall フロー全パスを通してから本申請

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
- **node-app-attest** (44 stars, MIT, **写経元・実装パターンの原典**): https://github.com/uebelack/node-app-attest
  - 依存: asn1js@^3.0.7 + cbor@^10.0.11 + pkijs@^3.3.3 + `node:crypto.X509Certificate`
  - メンテ状況: 🟢 活発 (2026-03 最新 commit、dependabot active、coverage 100%、Node 24 CI)
  - Workers 直接利用: ❌ 不可 (`node:crypto.X509Certificate` 未対応)
  - **本実装は node-app-attest 写経パターンを @peculiar/x509 で書き換え (Apache-2.0 ライセンス互換、要 LICENSE 表記)**
- appattest-checker-node (v1.0.3 = 2024-10、Apache-2.0、参考): https://github.com/srinivas1729/appattest-checker-node
  - 依存: @peculiar/x509@^1.9.6 + cbor@^9.0.1
  - メンテ状況: 🟡 1.5 年停止 (採用却下、設計参考として残置)
  - Workers 互換: ⭕ @peculiar/x509 + webcrypto 採用
- webauthn4j-appattest (Java、設計参考): https://github.com/webauthn4j/webauthn4j/pull/326
  - Apple App Attest を WebAuthn と分離する設計判断の根拠
- bas-d/appattest (Go、設計参考): https://github.com/bas-d/appattest
- @peculiar/x509 (採用 npm 依存): https://github.com/PeculiarVentures/x509
- MIERUNE/firebase-auth-cloudflare-workers-x509 (Workers + PKI.js 本番運用実績): https://github.com/MIERUNE/firebase-auth-cloudflare-workers-x509

### 二次ソース (詳細手順解説)
- adjoe Engineering blog (production 知見): https://adjoe.io/company/engineer-blog/prevent-fraud-on-ios-with-apple-devicecheck-and-app-attest/
- Restless Labs blog: https://blog.restlesslabs.com/john/ios-app-attest
- Medium (abhishek kureriya): https://abhishek-kureriya.medium.com/part2-validating-apps-integrity-key-in-backend-3775009f5dc7
- Medium (Wesley Matlock): https://medium.com/@wesleymatlock/%EF%B8%8F-ios-app-attest-devicecheck-building-real-trust-into-your-app-without-losing-your-mind-c98bc39eb142

### 既知の本番障害事例
- Firebase + App Check: 7日 TTL 後に全 device 0% verified に崩壊 → 中間トークン方式の地雷
- Apple infrastructure 障害 (2025-07-25): attestation サイズ膨張で firewall ブロック → max request length 設定要注意

---

## 13. 実装方針 (v1.3 確定: 案 B' ハイブリッド)

### 経緯

| 版 | 推奨 | 評価 |
|---|---|---|
| v1.1 | 案A (appattest-checker-node そのまま npm 流用) | メンテ停止リスクを過小評価していた |
| v1.2 | 同上 | Q1-Q5 確定のみ、方針未変更 |
| **v1.3** | **案 B' (ハイブリッド)** | 徹底再調査で 2 つの誤評価発覚 → 是正 |

### v1.3 の決定根拠 (徹底調査 2026-05-19)

| ライブラリ | メンテ状況 | Workers 互換 | 採否 |
|---|---|---|---|
| `appattest-checker-node` | 1.5 年停止 (2024-10 で commit 止まり、stars 20、fork 1) | ⭕ `@peculiar/x509` 採用 | ❌ 不採用 (メンテ停止) |
| `node-app-attest` | 🟢 活発 (2026-03 dependabot active、stars 44、coverage 100%) | **❌ `node:crypto.X509Certificate` 使用、Workers 未対応** | ❌ 不採用 (Workers 非対応) |
| `@peculiar/x509` | 🟢 活発 (PeculiarVentures org、Cloudflare 等の大手採用) | ⭕ Workers 動作実績 (MIERUNE firebase-auth fork) | ✅ 採用 (案 B' の唯一の npm 依存) |

### 案 B' = 「X.509 だけ枯れた library に任せ、残り全部 self-contained」

**npm 依存**: `@peculiar/x509@^1.9.6` 1 本のみ
**自前実装**: CBOR デコーダー + Attestation 9 step + Assertion 6 step + Durable Object + Apple Root CA 定数

### 実装パターン (node-app-attest 写経、Apache-2.0)

```js
// auth/app_attest.js (~200 行)
import { X509Certificate } from '@peculiar/x509';
import { decodeCbor } from './cbor.js';
import { APPLE_ROOT_CA_PEM, APPATTEST_PROD_HEX, APPATTEST_DEV_HEX } from './apple_root_ca.js';
import { createHash, createVerify, webcrypto } from 'node:crypto';

const APPLE_ROOT_CA = new X509Certificate(APPLE_ROOT_CA_PEM);

export async function verifyAttestation({attestation, challenge, keyId, bundleIdentifier, teamIdentifier, allowDevelopmentEnvironment}) {
  // 1. CBOR decode
  const decoded = decodeCbor(attestation);
  if (decoded.fmt !== 'apple-appattest') throw new Error('fail_fmt');
  const { x5c, receipt } = decoded.attStmt;
  const { authData } = decoded;

  // 2. Certificate chain verify
  const credCert = new X509Certificate(x5c[0]);
  const intermediate = new X509Certificate(x5c[1]);
  if (!await intermediate.verify({publicKey: APPLE_ROOT_CA.publicKey}, webcrypto)) throw new Error('fail_intermediate_cert');
  if (!await credCert.verify({publicKey: intermediate.publicKey}, webcrypto)) throw new Error('fail_credcert');

  // 3. Nonce verify (clientDataHash = SHA256(challenge), nonce = SHA256(authData || clientDataHash))
  const clientDataHash = createHash('sha256').update(challenge).digest();
  const nonce = createHash('sha256').update(Buffer.concat([authData, clientDataHash])).digest('hex');
  const extAsn = credCert.getExtension('1.2.840.113635.100.8.2').toString('asn');
  if (!extAsn.endsWith(`OCTET STRING : ${nonce}`)) throw new Error('fail_nonce');

  // 4-9. rpId / signCount / AAGUID / credentialId verify ...
  // (node-app-attest verifyAttestation.js:148-200 を写経、@peculiar/x509 API に合わせて書き換え)

  return { publicKeyPem: credCert.publicKey.export('pem'), receipt };
}
```

### challenge ライフサイクル擬似コード (v1.4 で確定)

```js
// POST /auth/challenge
async function handleChallenge(env) {
  const challengeId = crypto.randomUUID();
  const challengeBytes = crypto.getRandomValues(new Uint8Array(32));
  const expiresAt = Date.now() + 5 * 60 * 1000;  // 5 min

  const doStub = env.ATTESTATION_DO.get(env.ATTESTATION_DO.idFromName('global'));
  await doStub.fetch('https://do/challenge-create', {
    method: 'POST',
    body: JSON.stringify({ challengeId, challengeBytes: [...challengeBytes], expiresAt }),
  });
  return jsonOk({ challengeId, challenge: btoa(String.fromCharCode(...challengeBytes)) });
}

// Durable Object 側 (擬似)
async function challengeCreate(req) {
  const { challengeId, challengeBytes, expiresAt } = await req.json();
  // 毎回 cleanup (expired 行削除)
  this.sql.exec('DELETE FROM challenges WHERE expires_at < ?', Date.now());
  // INSERT 新 challenge
  this.sql.exec(
    'INSERT INTO challenges (challenge_id, challenge_bytes, expires_at) VALUES (?, ?, ?)',
    challengeId, new Uint8Array(challengeBytes), expiresAt,
  );
  return new Response('ok');
}

// POST /auth/attest (該当部分のみ)
async function handleAttest(req, env) {
  const { challengeId, attestation: attB64, keyId } = await req.json();
  const doStub = env.ATTESTATION_DO.get(env.ATTESTATION_DO.idFromName('global'));

  // 1. challenge を DO から取得 (consumed_at IS NULL 確認、replay 防止)
  const chRes = await doStub.fetch('https://do/challenge-consume', {
    method: 'POST',
    body: JSON.stringify({ challengeId }),
  });
  if (!chRes.ok) return jsonError(401, 'invalid_challenge', origin);
  const { challengeBytes } = await chRes.json();

  // 2. attestation 検証 (9 step)
  const result = await verifyAttestation({
    attestation: base64ToBytes(attB64),
    challenge: new Uint8Array(challengeBytes),
    keyId,
    bundleIdentifier: env.APPLE_BUNDLE_ID,
    teamIdentifier: env.APPLE_TEAM_ID,
    allowDevelopmentEnvironment: false,  // Q4 production only
  });
  if (result.verifyError) return jsonError(401, result.verifyError, origin);

  // 3. attestation を DO に永続化
  await doStub.fetch('https://do/attestation-store', {
    method: 'POST',
    body: JSON.stringify({ keyId, publicKeyPem: result.publicKeyPem }),
  });
  return jsonOk({ ok: true }, origin);
}

// DO 側 challenge-consume (single-threaded、race condition なし)
async function challengeConsume(req) {
  const { challengeId } = await req.json();
  const row = this.sql.exec(
    'SELECT challenge_bytes FROM challenges WHERE challenge_id = ? AND expires_at > ? AND consumed_at IS NULL',
    challengeId, Date.now(),
  ).one();
  if (!row) return new Response('not found', { status: 404 });
  this.sql.exec(
    'UPDATE challenges SET consumed_at = ? WHERE challenge_id = ?',
    Date.now(), challengeId,
  );
  return Response.json({ challengeBytes: [...new Uint8Array(row.challenge_bytes)] });
}
```

### 案 B' を選ぶ 5 つの理由 (オーナー判断確定)

1. **「確実に安全に」哲学に合致**: X.509 という地雷地帯だけ枯れた library に任せ、残り全部は自分で読んで自分で書く
2. **依存停止リスク最小**: `@peculiar/x509` は PeculiarVentures org の中核プロジェクトで、Microsoft/Google/Cloudflare 採用、長期サポート確実
3. **Workers 互換性確実**: 同 org のライブラリは MIERUNE fork で本番運用実績
4. **node-app-attest 実装パターン (production-grade、Apache-2.0) を写経できる**: 自前バグ混入リスク低減
5. **debugging 容易**: 自前部分 ~390 行は全把握、X.509 だけ既知の library


---

## 14. ロールアウト計画 v1.3 (案 B' 確定版)

```
セッション 1 ✅ (今回): 設計ドキュメント v1.3 + R2-R8 確定 + Apple Root CA 取得 +
                       案 B' (ハイブリッド) 確定
セッション 2: R1 検証 (minimal Worker で @peculiar/x509 + 自前 CBOR + createVerify
              の 3 操作動作確認、~30 行) → 動けば案 B' 確定、ダメなら pkijs に
              フォールバック検討 + auth/cbor.js 単体実装 + テスト (node-app-attest
              fixtures 流用)
セッション 3: auth/app_attest.js verifyAttestation 実装 (~150 行、node-app-attest
              写経パターン) + 単体テスト全 9 step
セッション 4: auth/app_attest.js verifyAssertion 実装 (~50 行) + auth/
              attestation_state.js Durable Object 実装 (~80 行) + DO migration +
              単体テスト
セッション 5: /auth/challenge + /auth/attest + /protected/* middleware 配線 +
              index.js 更新 + 既存 endpoint 連動テスト
セッション 6: TestFlight 実 iOS E2E (オーナー作業含む) + 本番 deploy + 1 週間モニタ
              (R6 = 10ms CPU 制限確認)
セッション 7: ドキュメント整理 + launch_checklist 更新 + メモリ更新
```

**累積工数見積もり**: 6 セッション × 2-3h = **12-18h** (R1 が一発で通れば 5 セッションも可)

セッション 2 で R1 を実機検証することで、案 B' でいくか、案 B' fallback (pkijs) でいくか早期決定。それ以降のセッションは確実に進む。

---

## 15. 承認状態 v1.3

- [x] **Q1-Q5 オーナー判断確定** (2026-05-19、§11 参照)
- [x] **案 B' ハイブリッド確定** (2026-05-19、§13 参照、徹底再調査の結果)
- [x] **Apple Team ID + Bundle ID 取得済** (2026-05-19、§16 参照)
- [x] ロールアウト計画 v1.3 (§14) 承認待ち → オーナーレビューで OK なら確定
- [ ] 実装着手 → セッション 2 開始 (R1 検証 + auth/cbor.js 実装 + 単体テスト)

### セッション 2 開始前のチェックリスト
- [x] オーナー: Apple Team ID 共有 (`TY5JW393Q5`)
- [x] 私: challenge race condition の解決を設計に追記 (v1.4、challenge も DO で管理) ← 本 commit で対応
- [ ] オーナー: Solara Flutter 側 freerasp の release keystore SHA-256 投入 (App Attest 検証とは独立だが Phase 2 RASP の懸案)
- [ ] 私: minimal Worker のサンプルコード準備 (R1 検証用、~30 行)
- [ ] 私: node-app-attest tests/fixtures ファイル一覧抽出 + ライセンス確認 (MIT、設計v1.3 誤記訂正)

---

## 16. 確定値 (実装で使う定数)

### Apple Developer 情報
| 項目 | 値 | 確認元 |
|---|---|---|
| Apple Team ID | **`TY5JW393Q5`** | オーナー確認 (Apple Developer Portal) 2026-05-19 |
| Bundle ID | **`com.solodevlab.solara`** | `ios/Runner.xcodeproj/project.pbxproj:375` + `apps/solara/docs/store_products_setup.md` |
| App ID (rpId 文字列) | **`TY5JW393Q5.com.solodevlab.solara`** | 上記の連結、32 バイト UTF-8 |

### rpId テストベクトル (Attestation/Assertion Step 5 で使用)
| 形式 | 値 |
|---|---|
| SHA-256(rpId) hex | `1d3d5f939a468294cb3577c05efb50c00effbea231245d237945367ccb29aa19` |
| SHA-256(rpId) base64 | `HT1fk5pGgpTLNXfAXvtQwA7/vqIxJF0jeUU2fMspqhk=` |

実 iOS から取得した attestation の `authData[0..31]` (= 32 バイト) と上記が**バイト完全一致**するはず。一致しなければ rpId 計算が間違っている (Step 5 失敗)。単体テストにこの値を hardcode する。

### Apple Root CA
| 項目 | 値 |
|---|---|
| SHA-256(DER) | `1CB9823BA28BA6AD2D33A006941DE2AE4F513EF1D4E831B9F7E0FA7B6242C932` |
| 取得元 | `https://www.apple.com/certificateauthority/Apple_App_Attestation_Root_CA.pem` |
| 保存場所 | `apps/solara/docs/Apple_App_Attestation_Root_CA.pem` (798B) |
| 有効期限 | 2045-03-15 (19 年放置可能) |

### AAGUID
| 環境 | バイト列 (hex) | UTF-8 解釈 |
|---|---|---|
| production | `61707061747465737400000000000000` | `appattest\x00\x00\x00\x00\x00\x00\x00` |
| development | `617070617474657374646576656c6f70` | `appattestdevelop` |

### 実装時の保管方針
- `apps/solara/worker/wrangler.toml` の `[vars]` セクションに記載 (Team ID/Bundle ID は public 情報):
  ```toml
  [vars]
  APPLE_TEAM_ID = "TY5JW393Q5"
  APPLE_BUNDLE_ID = "com.solodevlab.solara"
  ```
- Worker コード内では `env.APPLE_TEAM_ID` で参照、各 verify 呼び出しに渡す
- Apple Root CA PEM は `apps/solara/worker/src/auth/apple_root_ca.js` 内に **コード hardcode** (~10 行の template string)

---

## 17. Deploy 手順 (オーナー作業)

### 前提
- Apple Developer Program 加入済 (法人 arrayu 株式会社、Team ID `TY5JW393Q5`)
- Cloudflare アカウント設定済 (`solara-api.solodev-lab.com` カスタムドメイン)
- `wrangler login` 済 (`npx wrangler whoami` で確認)
- `apps/solara/worker/node_modules/` が `npm install` 済 (S2 で確認)

### Step 1: Apple Developer Portal で App Attest entitlement 追加 🚨 必須

App Attest を iOS 側で使うには、Bundle ID の **App Attest capability** を有効化する必要。これがないと `DCAppAttestService.attestKey()` が `DCError.featureUnsupported` を返す。

1. https://developer.apple.com/account → Certificates, Identifiers & Profiles → Identifiers
2. `com.solodevlab.solara` を選択
3. Capabilities セクションで **App Attest** にチェック
4. Save
5. 既存の provisioning profile を Update / 再生成 (Xcode の Signing & Capabilities でも自動で再生成可)

### Step 2: Worker 本番 deploy

```bash
cd apps/solara/worker
npx wrangler deploy
```

初回 deploy で:
- DO migration v1 が走り `AttestationState` SQLite クラスが作成される
- `APP_ATTEST_ENFORCEMENT = "log_only"` で起動 (= attestation 失敗しても通過 + warning)
- 既存の `/public/*` `/auth/*` 動作は不変

確認:
```bash
curl https://solara-api.solodev-lab.com/public/health
# → {"status":"ok","service":"solara-api"}

curl -X POST https://solara-api.solodev-lab.com/auth/challenge
# → {"challengeId":"...","challenge":"<base64>","ttlSec":300}
```

### Step 3: Flutter TestFlight ビルド + 配信

```bash
cd apps/solara
flutter build ipa --release --obfuscate --split-debug-info=build/symbols/ios/$(grep version pubspec.yaml | head -1 | awk '{print $2}')
```

Xcode で `apps/solara/build/ios/archive/Runner.xcarchive` を Organizer → Distribute App → TestFlight & App Store。

TestFlight で実機テスター 3-5 人にインストール。

### Step 4: 実機 E2E 確認

TestFlight アプリで以下を確認:
1. **初回起動**: SharedPreferences に keyId 保存 (Console.app で `[AppAttest] new keyId stored` ログ確認)
2. **/protected/fortune 等の Pro 機能 (or Free でも Fortune は通る)** を叩く
3. Cloudflare Workers Real-time Logs で:
   - `[middleware:log_only] would block` warning が出ていない (= attestation 通過)
   - もしくは出ていても 200 で fortune の結果が返っている

### Step 5: 1 週間モニタ後 enforced へ切替

```bash
# wrangler.toml の [vars] APP_ATTEST_ENFORCEMENT を "enforced" に書き換え + deploy
# または:
npx wrangler deploy --var APP_ATTEST_ENFORCEMENT:enforced
```

切替後、Cloudflare Workers Logs を 24 時間モニタ。401 急増があれば即時 `disabled` で kill switch。

---

## 18. 運用ガイド

### 監視すべきログ
- `[middleware:log_only] would block 401 <error>` ← log_only 期間中の attestation 失敗カウント。多すぎたら Flutter 側未対応 / 古いアプリ version が混ざってる
- `[app_attest] subCa expired` / `credCert expired` warning ← Apple Root CA 失効疑い (極稀)、有効期限と照合
- 500 `attestation_verify_exception` / `assertion_verify_exception` ← @peculiar/x509 / node:crypto の throw。これが頻発したら Apple SDK 変更疑い

### kill switch 操作
攻撃 / 障害時の緊急対応:
```bash
npx wrangler deploy --var APP_ATTEST_ENFORCEMENT:disabled
```
即時 middleware OFF。状況落ち着いたら log_only → enforced に戻す。

### Apple Root CA の更新
- 2045-03-15 まで有効、それまで何もしなくて良い
- 万一 Apple が前倒し失効した場合:
  1. https://www.apple.com/certificateauthority/Apple_App_Attestation_Root_CA.pem から新 PEM 取得
  2. `apps/solara/worker/src/auth/apple_root_ca.js` の `APPLE_ROOT_CA_PEM` 定数差し替え
  3. SHA-256 フィンガープリント値を `apps/solara/worker/test/cbor.test.js` 等で hardcode していたら更新
  4. `npx wrangler deploy`

### DO データの cleanup
- challenges 表は INSERT 時に毎回 `expired_at < now()` 行を DELETE するので放置可
- user_quota 表も 7 日より古い day_bucket を毎回 cleanup するので放置可
- attestations 表は端末ごとに 1 行、放置可 (= 端末アンインストール後も残るが影響なし)
- 万一 DO の SQLite が肥大化した場合は Cloudflare Dashboard から DO instance を delete + 次回 attest で復元される

### 端末側 attestation の失効
- `DCError.invalidKey` が iOS 側で発生したら `AppAttestClient.reattestOnFailure()` を呼ぶ
- これで keyId 再生成 + Worker /auth/attest 再登録 (= DO の attestations 表に INSERT OR REPLACE で上書き)

### per-user quota の調整
```bash
# Free 上限を 10 に引き上げる例
npx wrangler deploy --var APP_ATTEST_QUOTA_FREE:10
```
深夜帯にバズって全 user の quota 枯渇等の事象観測時に動的調整。

---

## 19. 累計サマリー (S1-S6 全完了)

### Worker 側
- `apps/solara/worker/src/auth/`: cbor.js (119) + apple_root_ca.js (95) + app_attest.js (290) + attestation_state.js (190) = **694 行**
- `apps/solara/worker/test/`: cbor.test.js (26) + app_attest.test.js (27) + DO smoke 11 = **64 ケース全 PASS**
- `apps/solara/worker/src/index.js`: middleware 配線 + 段階リリース機構 (+~200 行)
- `apps/solara/worker/wrangler.toml`: DO binding + nodejs_compat + 6 env vars
- bundle: 794 KiB / **gzip 156 KiB** = Workers Free 1MB の 16%

### Flutter 側
- `apps/solara/lib/utils/app_attest_client.dart`: AppAttestClient シングルトン (~200 行)
- `apps/solara/lib/main.dart`: initialize() 配線
- `apps/solara/lib/utils/{fortune,consultation}_api.dart`: 既存 4 endpoint 置換
- pubspec.yaml: `app_attest_integrity ^1.0.0` + `crypto ^3.0.6` 追加
- flutter analyze: clean / flutter test consultation: 30/30 PASS

### 残作業 (オーナー)
1. Apple Developer Portal で App Attest entitlement 追加
2. `cd apps/solara/worker && npx wrangler deploy` (本番 deploy)
3. TestFlight 実機 E2E
4. 1 週間モニタ後 enforced 切替
