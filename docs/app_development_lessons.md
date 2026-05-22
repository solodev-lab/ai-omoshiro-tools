# アプリ開発の知見集 — セキュリティクリティカル機能の設計から本番投入まで

**対象**: 個人開発者 / 小規模チームが、Apple/Google ストア向けのアプリで認証・課金・サーバー検証など「失敗が許されない」機能を実装するときの方法論
**ケーススタディ**:
- Solara Apple App Attest 実装 (2026-05、7 セッション、~12-15h、Worker ~700 行 + Flutter ~210 行 + テスト 64 ケース全 PASS)
- Solara RevenueCat Webhook + Pro エンタイトルメント検証 middleware 統合 (2026-05、1 セッション、Worker +700 行 + Flutter +50 行 + テスト 26 ケース PASS、累計 79/79)
- Solara Play Integrity (Android) 実装 v1.1 完成 (2026-05、S1-S7 = 7 セッション、Worker `auth/play_integrity.js` + DO `integrity_nonces` + middleware OS 分岐 + Flutter OS 分岐、worker 126/126 PASS、**実機 R8 突破**)。S7 で「Standard request の token は Self-managed key で復号できない」と実機判明し、Google `decodeIntegrityToken` API 方式に方針転換 (= §4.2 ROI 表の判定逆転、本書最大の訂正)
**反対側**: このドキュメントは「動くコードの書き方」ではなく「**判断ミスをどう減らすか**」の話

---

## 0. なぜこのドキュメントが必要か

セキュリティクリティカル機能 (App Attest、サブスク検証、E2E 暗号化、認証フロー等) には共通する罠がある:

1. **設計を急いで実装に入ると、本番化直前に基礎から壊れる**
2. **「業界標準」「動く実装がある」を根拠にすると、調査が不十分なまま方針が固まる**
3. **多層防御を闇雲に積むと、層が増えるほど偽陽性と運用負荷が増える**
4. **外部 SaaS (Firebase 等) は「簡素」に見えて、別軸の依存リスクを増やすことがある**
5. **AI アシスタントの推奨は「楽な選択」に流れる傾向があり、オーナーの問いかけがないと素案で固まる**

これらは Solara の App Attest 実装で実際に起きた失敗と、それを修正したオーナーの問いかけパターンから得た知見。

---

## 1. ケーススタディ

### 1.1 Solara Apple App Attest (7 セッション)

| 項目 | 当初見積もり | 実績 |
|---|---|---|
| 期間 | 4 日 (32h) | ~12-15h (7 セッション × 1.5-2h) |
| 設計修正回数 | 0-1 回想定 | **8 回** (v1.0 → v3.0) |
| ライブラリ採用判断 | 1 回で確定 | **4 回切替** (案 A → 案 B' → C+D + Firebase 検討) |
| テストケース | 想定なし | 64 ケース全 PASS |
| ドキュメント | 設計書 1 つ | 設計書 v3.0 + 汎用ノウハウ集 (本書) |

セッション構成 (= 設計を先に固めた効果で工数 50% 短縮):

| # | 内容 | 教訓 |
|---|---|---|
| 1 | 設計確定 (R/Q 項目決着、ライブラリ選定、アーキテクチャ) | コード書く前に未確認項目を全部つぶす |
| 2 | 最も基礎の純粋関数 (CBOR デコーダ) + 単体テスト + 実機動作確認 | 「動くか」を最小コードで早期検証 |
| 3 | 中核ロジック (証明書チェーン検証) + 改竄テスト | 実 fixture でデバッグ可能な状態に |
| 4 | 補助ロジック (assertion verify) + 永続化 (DO) + smoke test | 永続化は実機テスト必須 |
| 5 | 本番統合 + 段階リリース機構 (log_only) | 本番化前の安全装置を必ず入れる |
| 6 | クライアント側統合 + 既存コード置換 | 既存テストが壊れないか毎回確認 |
| 7 | ドキュメント整理 + 運用ガイド + メモリ最終化 | 「将来の自分」のための再利用性確保 |

### 1.2 Solara RevenueCat Webhook + Pro エンタイトルメント検証 middleware (1 セッション)

App Attest 完成後、その middleware を拡張して RC エンタイトルメント連動の Free/Pro quota 切替を実装。設計が先に固まっていたため 1 セッションで完了。

| 項目 | 実績 |
|---|---|
| 期間 | 1 セッション (~2.5h) |
| Worker 追加 | +700 行 (`webhooks/revenuecat.js` 268 行 / `auth/entitlement_cache.js` 80 行 / `attestation_state.js` +171 行 / `index.js` 拡張) |
| Flutter 追加 | +50 行 (`purchases_service.dart` getter / `app_attest_client.dart` body 注入) |
| テスト | 26 ケース PASS (timing-safe + event 種別マップ + auth 分岐 + DO 連動 + cache TTL) |
| 累計 Worker テスト | 79/79 PASS |
| 設計判断 (D1-D10) | constant-time Bearer + DO 統合 + 60s メモリ cache + body `__appUserId` + Webhook 単独 + Pro/Free quota 切替 + event 種別 4 マップ + 未知=inactive + 冪等性 + out-of-order ガード |

得た知見:
- **DO 表追加は migration 不要** (`CREATE TABLE IF NOT EXISTS` で自動)、SQLite-backed DO の強み
- **App Attest assertion は payload SHA-256 で署名する** → body の予約フィールドに任意の管理用 ID を入れると改ざん耐性を持つ
- **Webhook 冪等性は event_id 単位の INSERT OR IGNORE** で実現、`alreadyProcessed: true` を伝搬
- **out-of-order ガード**: `last_event_at > now` の event は無視 (RC は順序保証しない)
- **secret 未設定で 503** = 公開前ガード (= 想定外 deploy で偽 webhook を通さない)
- **Worker instance メモリ cache 60s TTL** で DO 連打抑制、Webhook 受信 instance は INSERT 直後 clear、cross-instance は eventual

**ストア設定フェーズの知見 (両ストア商品作成 + RC ダッシュボード配線、Android 1 + iOS 1 セッション)**: コード実装とは別に「アプリ外設定」が要る。手順は `apps/solara/docs/store_products_setup.md` に集約。
- **iOS は Flutter コード変更ゼロで足りた** (Android で RC 配線済なら): `purchases_service` は entitlement (`cosmic_pro`) + `offering.monthly/annual` を RC 経由で読むだけで、**商品 ID をコードに持たず RC に置く設計**のため、ストア + RC ダッシュボード設定だけで iOS が有効化される (`build_release.py` も `--rc-ios-key` 対応済)
- **In-App Purchase Key (P8) が StoreKit2 の正規ルート**。Shared Secret は P8 があれば不要。**App Store Connect API Key を入れると RC が商品を自動 import** できる
- **商品ステータス「メタデータ不足」は RC import / Sandbox テストに影響しない** (審査用スクショ未入力なだけ。スクショは公開直前で可)
- **Android の RTDN ↔ iOS の App Store サーバ通知**が対になる。RC はどちらも「RC が出す URL をストア側に貼る」方式
- **ストア設定 + RC 配線は Windows の Web だけで先行完了できる** (Mac 待ちで止めなくてよい)。さらに **iOS の実機購入テストも Mac 不要**で完走できると 2026-05-21 に実証した (Codemagic でビルド→TestFlight、TestFlight は本番アカウント+Sandbox 課金のハイブリッド環境なので iPhone 実機だけで課金検証可能)。詳細は §10

### 1.3 Solara Play Integrity (Android) 実装 v1.1 完成 (S1-S7 = 7 セッション、実機 R8 突破)

Apple App Attest と対称の Android セキュリティ層。設計フェーズで Q1-Q4 を先にオーナー判断、R 項目を 3 分類して S1 で設計確定 + 鍵取得まで完了。S2-S6 で実装、**S7 で実機検証中に設計の中核 (decode 方式) が崩れ、方針転換して R8 突破**した。

| 項目 | 実績 |
|---|---|
| 期間 | S1-S7 = 7 セッション |
| 設計 docs | `apps/solara/docs/play_integrity_design.md` v1.1 (Q1-Q4 確定、R1-R8、12-step 検証、Deploy 手順) |
| ライブラリ | Flutter `app_attest_integrity` v1.0.0 (StandardIntegrityManager 専用) / Worker `jose` v6.2.3 |
| Q1-Q4 オーナー判断 | **Standard request** (※当初 Classic から訂正) + DEVICE_INTEGRITY + PLAY_RECOGNIZED |
| decode 方式 | **Google `decodeIntegrityToken` API** (※当初 Self-managed key から S7 で訂正) |
| 実装 | Worker `auth/play_integrity.js` (12-step verify + SA JWT 署名 + OAuth2 + decode) + DO `integrity_nonces` 表 + middleware OS 分岐 + Flutter `app_attest_client.dart` Android 分岐 |
| テスト | worker 126/126 PASS (Google decode mock + SA JWT 経路 29 ケース) |
| 実機検証 | decode-test で `ok:true` / PLAY_RECOGNIZED / MEETS_DEVICE_INTEGRITY / LICENSED 確認 = **R8 突破** |
| bundle | gzip 171.34 KiB (Workers Free 1MB に対し残 83%) |

#### 🔴 最重要教訓: Play Integrity の「request 種別」と「decode 方式」は密結合 (S7 の方針転換)

**起きたこと**: 設計 v0.5 まで「Self-managed encryption key を Workers で持てば、Classic でも Standard でも token を自前 decode できる」と公式 docs を読んで判断していた。S7 の実機検証で、採取した token は `CqUC...` で始まる **Google 独自 protobuf** で、`jose.compactDecrypt` が `JWEInvalid: Invalid Compact JWE` を返した。

**正しい事実 (公式 docs 再読で確定)**:
- **Classic request** の token → JWE (暗号化 JWT)。Self-managed key で **local decode 可能**
- **Standard request** の token → Google 独自 protobuf。**Google `decodeIntegrityToken` API でのみ復号可能** (Self-managed key は無関係)
- Flutter プラグイン `app_attest_integrity` v1.0.0 が **Standard 専用** だったため、token は必然的に Standard 形式 = 自前 decode 不可能だった

**なぜ気づけなかったか**: 「Self-managed key」の docs ページ (= Classic 文脈) と「Standard request」の docs ページが別々で、前者を読んで「decode は request 種別に依存しない」と誤って一般化した。R8 を「概算解決」とラベルし、実機確認を S5 まで先送りしていた。

**修正の判断 (= オーナーの介入が効いた)**: エラーを見て即「設計を捨てて作り直す」のではなく、オーナーが「**今までの調査は効率のために行ったもの。すぐ捨てず、まず原因と最新情報を調べろ**」と制止。調査の結果、既存の枠組み (middleware OS 分岐 / DO nonce / clientData binding / Step 8-12) は**全て再利用でき、decode 部分だけ差し替えれば済む**と判明。`jose` も捨てず、用途を `compactDecrypt` → `SignJWT`+`importPKCS8` (Service Account JWT 署名) に転用した。結果、書き直しは最小限で R8 突破。

**横展開する教訓**:
1. **「概算解決」「実機確認は後で」とラベルした R 項目は、本番化前に必ず実物で潰す** (先送りすると最も高くつく所で崩れる)
2. **公式 docs が機能ごとにページ分割されている時、「このページの説明が他機能にも適用される」と一般化しない** (= §2.4 業界標準を言い訳にしないの変種)
3. **エラーが出ても既存設計を即破棄しない**: 既存の調査・設計は理由があって積まれている。差分で直せる範囲を見極めてから判断する (memory: `feedback_investigate_before_discard.md`)

得た知見 (S1-S6 から継続):
- **Apple App Attest と Play Integrity は middleware で経路分岐できる**: header の有無 (`X-AppAttest-KeyId` / `X-PlayIntegrity-Token`) で iOS/Android 自動判定、検証関数だけ切替、entitlement lookup + quota は共通フロー
- **Standard request でも server-issued nonce は使える (ハイブリッド)**: プラグインが Standard 専用でも、自前 nonce を `clientData` JSON に埋め込み DO で one-time consume すれば Classic 同等の replay 防止になる。token の `requestHash` = `base64(sha256(clientData))` で clientData との束縛を検証
- **verdict payload の型は STRING に注意**: `timestampMillis` / `versionCode` は文字列、`Number()` 明示変換。`deviceRecognitionVerdict` は空配列 `[]` あり得る (= 端末攻撃検知)、`Array.isArray && length>0 && includes` の 3 段防御
- **`jose` は decode 専用ライブラリではない**: Self-managed decode を捨てても、Service Account の RS256 JWT 署名 (OAuth2 token 取得) に同じ lib を転用できた = ライブラリは「目的」でなく「機能」で評価すると無駄が減る
- **設計の言葉と公式 UI の実際は乖離する**: Verification key を「PEM」と想定したが実際は base64 (DER SPKI)。R 項目に「実 UI / 一次出力で形式を確認」を必ず入れる
- **Self-managed key 鍵交換ハイブリッド** (Classic 用に取得した分は将来の保険で wrangler secret に残置): クライアント RSA 鍵生成 → 公開鍵 upload → 暗号化応答 download → RSA-OAEP 復号 → secret 投入。OpenSSL は Git for Windows 同梱で十分、平文鍵はローカルに残さない

---

## 2. 設計フェーズの方法論

### 2.1 R 項目 (未確認) と Q 項目 (オーナー判断) を分離する

設計ドキュメントの最初に以下を並べる:

**R 項目 (Research、未確認の事実)**:
- 「Apple Root CA のフィンガープリント」「rpId 計算式」「ライブラリの Workers 互換性」など、**調べれば確定する**もの
- 「今すぐ確定できるか / 実装中に判明するか / 実装後に計測必須か」の 3 段階で分類する
- 「全部実装後」と並べると着手が遅れる。**今すぐ確定できるものは今やる**

**Q 項目 (Question、オーナー判断)**:
- 「challenge TTL を 5 分にするか 10 分にするか」「エラーコードを詳細出すか単一にするか」など、**事実ではなく方針**のもの
- 私 (AI) が推奨を出し、オーナーが OK/修正を決める
- **AI が独断で決めない**

### 2.2 確度ラベルで推測と事実を区別する

```
- **★★★** 公式 or 一次ソース複数で確認済
- **★★** 信頼できる二次ソース (大手ブログ・OSS実装) で確認、公式未確認
- **★** 推測 / 既存実装に倣う / 実装中に最終確認が必要
- **❓** 公開前にオーナー or 実機で確認必須
```

これを付けておくと、後から読み返したとき / 別の開発者がレビューしたときに、どこを再検証すべきか即時わかる。

### 2.3 設計ドキュメントの段階的更新を恥じない

Solara App Attest は v1.0 → v3.0 で **8 回更新**した。これは無駄ではなく:
- 「コードを書く前に設計で詰める」ことで、コードの書き直しが激減
- 各更新で「何が変わったか」「なぜ変わったか」を履歴セクションに残す
- 後から読んだ自分 (or 別開発者) が決定プロセスを追体験できる

### 2.4 「業界標準」を言い訳にしない

私 (AI) が「業界標準では signature only」と書いた → 実は半分嘘だった (片方のライブラリは時刻チェック ON)。
- **必ず一次ソース (ライブラリの実コード) を grep する**
- 推測のまま「業界標準」と書くと、後から見直したときも疑問を持たれない
- critical_rules ルール 2「事実と推測の区別」の典型的違反

---

## 3. 外部依存・ライブラリの客観評価

### 3.1 GitHub API でメンテ状況を機械的に確認

```bash
# repo の活発度を 1 リクエストで取得
curl -fsSL "https://api.github.com/repos/<owner>/<repo>" | \
  grep -E '"(pushed_at|stargazers_count|forks_count|open_issues_count|archived)"'

# 最近 5 commit の日付確認
curl -fsSL "https://api.github.com/repos/<owner>/<repo>/commits?per_page=5" | \
  grep -E '"date"' | head -5

# open issues が dependabot 自動 PR ばかりか、本物 bug 報告か
curl -fsSL "https://api.github.com/search/issues?q=repo:<owner>/<repo>+state:open" | \
  grep -E '"(title|created_at)"' | head -20
```

**判定基準**:
- **`pushed_at`** が 1 年以上前 = メンテ停滞リスク高
- **open issues が全部 dependabot PR** = 健全メンテ (本物 bug ゼロ)
- **stars vs forks 比率** が 50:1 以上 = フォーク文化が薄い (= 採用者がメンテに困ったら自分でフォーク必要)

Solara App Attest で発見した実例:
- `appattest-checker-node` (私の最初の推奨): 最終 push 2024-10、stars 20、fork 1 = **実質メンテ停滞**
- `node-app-attest` (フォールバック扱いだったが): 2026-03 dependabot active、stars 44、coverage 100% = **健全**
- ただし node-app-attest は `node:crypto.X509Certificate` 使用で **Workers 非対応**

= 「健全メンテ」と「Workers 互換」は別軸で評価する必要がある。

### 3.2 ライブラリのソース import 文を必ず grep する

```bash
# Workers 非対応の API を使っていないか機械的に検出
grep -E "from 'node:|require\\('node:" <library>/src/**/*.js | \
  grep -vE "node:crypto|node:buffer" # Workers OK な API は除外
```

Workers で動かない代表的な node API:
- `node:fs` (file system)
- `node:net` / `node:tls` (TCP/TLS socket)
- `node:cluster` / `node:worker_threads`
- `node:crypto.X509Certificate` (まだ未対応、2026 年現在)

### 3.3 「外部 SaaS で簡素化」提案の評価軸

Firebase / Auth0 / Stytch 等を採用すると「Worker 実装が 1/8 に減る」のような魅力的な数字が出る。ただし以下を**必ず**一緒に評価:

1. **障害時の依存範囲**: 外部 SaaS が落ちると自アプリも止まる
2. **依存頻度**: 自前なら 1 端末 1 回、SaaS なら毎時 30 分 のような違い
3. **過去の障害事例**: 「Firebase + App Check で 7 日 TTL 後に全 device 0% verified に崩壊」のような事例を探す
4. **ロックイン**: 後で外すコストはどれくらいか
5. **審査での開示要件**: App Store プライバシー欄に「Google サービス使用」明記など

Solara では Firebase App Check が「Worker 50 行で済む」魅力的候補だったが、**Apple サーバー依存頻度の逆転** (現状: 1 回 vs Firebase: 毎時 30 分) を理由に**不採用**にした。

---

## 4. 多層防御の ROI 評価

### 4.1 過剰防御の罠

「念のため layer を増やそう」の発想は危険:
- 偽陽性 (= 正規ユーザーが弾かれる) で UX 悪化
- 層が増えるほど attack surface も増える
- 監視複雑化 (どの層が原因か特定困難)
- 連鎖障害 (= 1 層の故障が他層に波及)

### 4.2 ROI 評価フレームワーク

各防御層について 4 軸で評価:

| 軸 | 評価例 |
|---|---|
| 防御効果 | 🟢 攻撃を直接防ぐ / 🟡 補助的 / 🔴 効果限定的 |
| 実装コスト | 低 (1 セッション) / 中 / 高 |
| 偽陽性リスク | ほぼゼロ / 中 / 高 |
| 運用負荷 | 設定のみ / 監視必要 / 常時調整 |

Solara で検討した層 (App Attest + RC + Play Integrity 統合後):

| 層 | 防御効果 | 実装 | 偽陽性 | ROI | 採否 |
|---|---|---|---|---|---|
| App Attest assertion 検証 (iOS) | 🟢 curl 直叩き全防御 | 高 (~700 行) | 低 | 🟢 最高 | ✅ 採用 |
| Play Integrity verdict 検証 (Android) | 🟢 同上 | 高 (S2-S6 で ~800 行見込み) | 低 | 🟢 最高 | ✅ 採用 |
| body `__appUserId` 注入 + 改ざん耐性 (RC 連動) | 🟢 uid 詐称防御 | 低 (~30 行追加) | ほぼゼロ | 🟢 最高 | ✅ 採用 |
| RevenueCat Webhook (Pro 状態の真の出所) | 🟢 クライアント側 isPro 詐称防御 | 中 (~270 行) | 低 | 🟢 最高 | ✅ 採用 |
| per-user rate limit (Layer C、Pro/Free 切替) | 🟢 突破時の被害最大化防止 | 低 | 低 | 🟢 高 | ✅ 採用 |
| Worker メモリ cache 60s TTL (entitlement) | 🟡 DO 連打抑制 + 即時 invalidate | 低 (~80 行) | 60s 遅延受容 | 🟢 高 | ✅ 採用 |
| Bot Fight Mode (Cloudflare) | 🟢 補助的 | 設定 1 クリック | ほぼゼロ | 🟢 最高 | ✅ 採用 |
| 異常検知アラート | 🟢 リアルタイム発見 | 中 | 低 | 🟡 中 | ✅ 採用 (後続) |
| Apple step 6 (challenge inclusion 厳格) | 🔴 Secure Enclave 突破前提でしか効果なし | 中 (latency +1RTT) | 中 | 🔴 低 | ❌ **不採用** |
| Google `decodeIntegrityToken` 経由 verdict (Android Standard) | 🟢 唯一の復号手段 (Standard token は protobuf、自前 decode 不可) | 低 (~50 行、SA JWT + OAuth2) | Google 障害連鎖 / レイテンシ ~200ms / quota 消費 (access token 50min cache で緩和) | 🟢 **必須** | ✅ **採用に逆転** (S7) |
| Trusted Entitlements REST API 二重チェック | 🟡 補助的 (Webhook 取りこぼし時) | 中 | 中 | 🟡 中 | ⏳ 公開後検討 |
| App Attest device check API | 🟡 receipt 検証 | 中 (Apple サーバー API call) | Apple 障害連鎖 | 🔴 低 | ❌ **不採用** (sign count 検証で十分) |

「ROI 低い層は採用しない」勇気が大事。同時に「ROI 評価表は機能追加のたびに更新する」(2026-05 で 5 行追加した実例)。**そして「実物で前提が崩れたら判定を逆転させる」**: Google decode 経由 verdict は当初「Self-managed key で代替できるから不採用」だったが、Standard request では自前 decode が物理的に不可能と S7 実機で判明し「必須」に逆転した。ROI 表の前提 (= 各層の防御効果や代替可能性) も、実機検証で覆ることがある。

### 4.3 段階リリース機構を必ず入れる

セキュリティクリティカル機能は本番化直後の落ちが致命的。**`log_only → enforced` の 2 段階切替**を仕込む:

```js
// 環境変数で挙動切替
const mode = env.FEATURE_ENFORCEMENT; // "disabled" | "log_only" | "enforced"

if (mode === "disabled") return null; // kill switch
if (検証失敗) {
  if (mode === "log_only") {
    console.warn("[log_only] would block:", error);
    return null; // 通過
  }
  return jsonError(401, error); // enforced
}
```

これで:
- 初回 deploy は `log_only` (= 検証走るが失敗しても通す + ログ)
- 1 週間モニタで「正規ユーザーが弾かれていない」確認
- 異常なければ `enforced` に切替 (deploy なしで vars update のみ)
- 攻撃 / 障害時は `disabled` で即時 kill switch

🔴 **log_only は「検証が通るか」ではなく「enforced にしたら弾かれるか」を事前に見る窓**: モニタ中にサーバーログで `would block ... missing_attestation_headers` 等が出たら、それは「**enforced 化したらそのリクエストが 401 で全滅する**」という事前警告。**クライアント側のヘッダー付与漏れ**(= 起動時 initialize 完了前の先行呼び出し / addHeaders の失敗) を enforced 前に必ず潰す。実例 (2026-05 Solara iOS): `/auth/attest` (鍵登録) は成功なのに `/protected/*` の一部で `missing_attestation_headers` が出ていた = per-request assertion の付与漏れ。log_only モニタが無ければ enforced 直後に保護機能が全滅していた。**サーバーログ (CF Observability 等) でクライアントの実挙動を確認する**のが段階リリースの主目的の一つ。

---

## 5. Worker ↔ Client 統合の落とし穴

### 5.1 payload bytes 正規化問題 (= Firebase 0% verified 障害の構造)

サーバー側で SHA-256(request body) を計算し、クライアント側で SHA-256(payload) を計算した値が一致する必要がある場合、**両者の bytes が完全一致しないと全リクエスト失敗**する。

JSON で起きる罠:
- `jsonEncode` の key 並び順 (insertion order vs alphabetical)
- 空白 (`{"a":1}` vs `{ "a": 1 }`)
- 末尾改行
- UTF-8 BOM
- escape sequence (`é` vs `é`)

**規約**:
```
1. Client は jsonEncode(map) → utf8.encode(string) → Uint8List で bytes を確定
2. その bytes を HTTP body にそのまま使う (中間で変換しない)
3. Server は request.arrayBuffer() で raw bytes を取得
4. CI チェック: 既知 JSON で両側の SHA-256 hex が完全一致することをテスト
```

🔴 **実例: App Attest プラグインの clientDataHash 規約ズレ (2026-05 Solara、半日溶かした)**
サードパーティ製の App Attest プラグイン (`app_attest_integrity`) は、challenge/clientData を
**「base64 文字列を UTF-8 にして」SHA256** していた (`SHA256(Data(challenge.utf8))`、Swift)。
一方サーバーは challenge/payload の**生バイト**を SHA256 していた。両者の clientDataHash が
食い違い → nonce 不一致 → **全 attestation/assertion が `401 fail_nonce_mismatch`**。
- 教訓 1: **プラグインの native ソース (Swift/Kotlin) を必ず読んで clientDataHash の作り方を確認する**。
  「challenge を渡す」だけでは、それが生バイト hash か base64 文字列 hash か分からない。ドキュメントは当てにならない。
- 教訓 2: 切り分けで **capability / 環境(prod/dev) / rpId を先に疑ったが全部ハズレ**。証明書チェーンは
  通過していて (Step1 OK)、nonce (Step4) で落ちていた = challenge データの問題と最初から分かるべきだった。
  **エラーコードを「具体的に」サーバーログに出す** (`fail_nonce_mismatch` 等) のが最短。`would block` の
  汎用メッセージだけでは原因が分からず、推測で時間を溶かす。
- 教訓 3: **サーバー側だけで直せた** (検証関数本体は触らず、呼び出し側で `base64(bytes)` の UTF-8 を渡す)。
  プラグインに合わせる側 = サーバー。クライアント再ビルド不要だった。
- 教訓 4: テストが node-app-attest の **生バイト規約 fixture** で書かれていたため、テストは通るのに本番で
  落ちる状態だった。fixture と実プラグインの規約が違うと「緑なのに動かない」が起きる。

### 5.2 body 二重 read 禁止

HTTP request body は ReadableStream で**一度しか読めない**。middleware で body を読み、handler でまた読もうとすると失敗する。

**解決パターン**:
- middleware で `request.clone()` してから読む (stream を分岐)
- または middleware で読んだ bytes を context に積む (handler が再 parse 可能)

Solara では `request.clone()` パターン採用 (handler 側コードを変更しなくて良いため)。

### 5.3 通信フォーマットを文書化する

「Worker と Client の契約」を設計ドキュメントに必ず書く:
- リクエストヘッダー (例: `X-AppAttest-KeyId`, `X-AppAttest-Assertion`)
- bytes 規約 (= §5.1)
- レスポンス形式 (成功 / 失敗時のエラーコード一覧)
- リトライ policy

### 5.4 Webhook 受信の冪等性 + out-of-order ガード

外部 SaaS (RevenueCat、Stripe、Slack 等) からの Webhook は:
- **同 event が何度も再送される**: SaaS 側の SLA 上、200 を返すまで指数バックオフで再送する
- **順序保証されない**: 後発 event が先発より先に届くことがある
- **偽 event のリプレイ攻撃**: 攻撃者が認証 secret を入手したら、過去 event を任意に流せる

これらに耐える共通パターン:

```js
// 冪等性: event_id 単位の INSERT OR IGNORE
const before = sql.exec(`SELECT 1 FROM webhook_events WHERE event_id = ?`, eventId).toArray();
if (before.length > 0) return { ok: true, alreadyProcessed: true };
sql.exec(`INSERT INTO webhook_events (event_id, received_at, event_type, ...) VALUES (?, ?, ?, ...)`, ...);

// out-of-order: last_event_at > now なら無視
const existing = sql.exec(`SELECT last_event_at FROM ... WHERE ...`, ...).toArray();
if (existing.length > 0 && existing[0].last_event_at > now) {
  return { ok: true, skippedOutOfOrder: true };
}
```

未知 event 種別 → 安全側 (= Pro 維持しない / 権限付与しない) に倒す:

```js
// 既知 event は明示的にマップ、未知は inactive 扱い (= 権限を維持しない)
if (ACTIVE_EVENT_TYPES.has(eventType)) isActive = true;
else if (GRACE_EVENT_TYPES.has(eventType)) isActive = true; // 期限まで維持
else if (INACTIVE_EVENT_TYPES.has(eventType)) isActive = false;
else isActive = false; // 未知 → 安全側
```

### 5.5 認証 secret は constant-time + 未設定で 503

Webhook 認証で **timing-safe な文字列比較** (`===` ではなく `XOR` 累積) を必ず使う。長さ違いは即 false、内容違いも全バイト比較する:

```js
function timingSafeEqualString(a, b) {
  if (typeof a !== 'string' || typeof b !== 'string') return false;
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) {
    diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return diff === 0;
}
```

secret 未設定時は **503 を返す** (200 や 401 ではない、= 公開前ガード)。これで、想定外環境 (= secret 未投入の staging 等) で本物の event を誤って処理する事故を防ぐ。

### 5.6 鍵交換のハイブリッド方式 (Self-managed key)

外部 SaaS から AES-256 や ECDSA 鍵を取得する設定で、サーバー保管中の漏洩を排除する公式パターン:

1. クライアント側で **RSA 2048-bit 鍵ペアを生成** (`openssl genrsa -aes128 -out private.pem 2048`)
2. 公開鍵 `public.pem` を SaaS にアップロード
3. SaaS は実際の暗号化鍵 (AES-256 + ECDSA 等) を **その公開鍵で暗号化したファイル** で返す
4. クライアント側 RSA 秘密鍵で復号 (`openssl pkeyutl -decrypt -pkeyopt rsa_padding_mode:oaep`)
5. 復号後の平文鍵を deploy 環境 (= Worker secret 等) に投入
6. 平文鍵をローカルに残さない (= 再復号は同じ private.pem で何度でも可能なため)

Google Play Integrity API の Self-managed key 設定で実例 (2026-05)。**「直接 AES を流通させない」追加の安全層**として、攻撃者が SaaS サーバー側に侵入しても、RSA 秘密鍵を持たない限り decode できない。

クライアント側で必要なツール: `openssl` (Windows なら Git for Windows 同梱の `C:\Program Files\Git\usr\bin\openssl.exe` で十分、単体インストール不要)。

PowerShell 注意点:
- `>` リダイレクトは UTF-16LE になる罠 → `openssl ... -out file.txt` (openssl 自身) で ASCII 出力させる
- フルパス実行は `&` call operator: `& "C:\Program Files\Git\usr\bin\openssl.exe" genrsa ...`
- backtick `` ` `` で line continuation (bash の `\` ではない)

### 5.8 Service Account 経由の Google API 呼び出し (wrangler secret + JWT 署名)

外部 SaaS の「自前 decode」が不可能で、SaaS 公式 API (例: Google `decodeIntegrityToken`) を Worker から叩く場合の定番パターン。Solara Play Integrity S7 で実装。

**Service Account JWT → OAuth2 access token フロー** (Cloudflare Workers、`jose` v6 使用):

```js
import { SignJWT, importPKCS8 } from 'jose';
// 1. SA JSON (private_key PEM PKCS8 + client_email) を JSON.parse
// 2. importPKCS8(sa.private_key, 'RS256') で署名鍵に変換
// 3. SignJWT で {scope, iss=client_email, sub=client_email, aud=token_url, iat, exp} を RS256 署名
// 4. POST oauth2.googleapis.com/token (grant_type=jwt-bearer, assertion=<JWT>) → access_token
// 5. access_token を Worker メモリに 50min cache (Google は 3600s 有効、cold start で消えても次回再署名)
// 6. Authorization: Bearer <access_token> で対象 API を呼ぶ
```

**ハマりどころ (実機で潰した)**:

- **`wrangler secret put` は対話式だと 1 行しか受け付けない**: 複数行 JSON (private_key に `\n` を含む) を貼り付けると最初の改行で切れ、残りが shell プロンプトに漏れる。診断で `Unterminated string in JSON at position XXXX` が出たらこれ。
  ```powershell
  # ❌ 対話式貼り付け (multiline JSON が切れる + private_key が画面に露出)
  npx wrangler secret put GOOGLE_PLAY_INTEGRITY_SA_JSON   # ← ここに JSON 貼り付け = 罠

  # ✅ ファイルを 1 文字列として渡す (画面非表示 + 完全投入)
  Get-Content "path\to\sa.json" -Raw | npx wrangler secret put GOOGLE_PLAY_INTEGRITY_SA_JSON
  ```
  PowerShell では `|` の直後で改行すると「空のパイプ要素」エラー → **1 行で実行**。失敗するなら `$sa = Get-Content ... -Raw; $sa | npx wrangler secret put ...` と変数経由。

- **診断 endpoint を必ず用意する**: secret が正しく入ったかを `{saConfigured, accessTokenOk, accessTokenLen}` で返す GET を作る (access token の値そのものは返さない)。これで「鍵が効いているか」を deploy 直後に 1 コマンドで確認できる。本番化 (enforced) 時は同 endpoint を 404 化するガードも入れる。

- **decode-test endpoint で実機 token を検証する**: 実機から採取した本物の token を POST し、API の生レスポンス (payload) を返す診断口を作る。これが §1.3 の R8 突破に直結した (= 実物 token がないと「自前 decode 不可」に気づけなかった)。

**鍵 (Service Account key) の rotation 手順** (漏洩時 / 定期):

1. Cloud Console > IAM > サービスアカウント > 該当 SA > キー で**新キーを先に作成** (JSON download)
2. `Get-Content 新キー.json -Raw | npx wrangler secret put ...` → `wrangler deploy` → 診断で `accessTokenOk:true` 確認
3. **新キー稼働を確認してから**旧キーを Console で削除 (先に消すと投入失敗時に詰む)
4. ローカルの旧 JSON ファイルを削除

> ⚠️ deploy は Worker を新バージョン (cold start) にするので、メモリ上の access token cache がリセットされる。つまり deploy 直後の診断 `accessTokenOk:true` は「新キーで署名成功」を確実に意味する。
> ⚠️ 対話式貼り付けで private_key が画面表示されてしまったら、ターミナル履歴に残る前提で rotation する。Console で旧キーを削除すれば、履歴に残った鍵も JWT 署名に使えなくなる (= 無効化される)。

### 5.7 設計の言葉と公式 UI の実際は乖離することがある

事前調査で「Verification key = ECDSA P-256 **PEM 形式**」と公式 docs から読み取ったが、実際の Play Console UI で取得すると **base64 (DER SubjectPublicKeyInfo) 形式**で出力される。docs は最新の UI 仕様を反映していないことがある。

対策:
- R 項目に「**公式 UI / 一次出力で取得形式を実際に確認**」を必ず入れる
- 実装段階で形式が違ったときに `crypto.subtle.importKey(format, ...)` の format 引数を `'spki'` (DER) vs `'jwk'` vs `'raw'` で切替できる柔軟性を持たせる
- 鍵の長さで判別: AES-256 → 32 bytes → base64 44 char / ECDSA P-256 SPKI → 91 bytes → base64 124 char (どちらも末尾 `=` パディングあり)

**追加事例: App Store Connect / RevenueCat ストア設定の UI 乖離 (2026-05-21, Solara iOS Layer B)**

設計 doc / 英語ベースの手順書の用語と、実際の ASC (日本語 UI) が食い違った具体例:
- **無料トライアル = 「お試しオファー」** (doc は「入門オファー (Introductory Offer)」と記載していた)。場所も「下スクロール」ではなく**サブスク価格ページ上部のタブ**。さらに**通常価格を先に保存しないと設定できない**
- **お試しオファーの「開始日/終了日」は試用期間ではなく "オファーの掲載期間"**。無期限提供にするには**「終了日なし」**を選ぶ (7 日という試用日数は別ステップ)
- **App Store サーバ通知に V1/V2 セレクタが存在しない** (空の「Set Up URL」/ URL入力後 / 既存「編集」の全状態で確認、Apple Developer Forums で複数開発者も同症状を報告)。Apple ヘルプ＆フォーラム回答は「V1/V2 をトグル可」と書くが**旧UIの記述**で、新UIは選択肢が外れ**新規URLは V2 既定**。RC は同一URLで payload から自動判別 (RC側URLではバージョン変わらない)。実バージョンは UI では読めず、受信後の `notificationVersion` (V2=`"2.0"`/JWS) か RC ダッシュボードで確定する
- **URL 内の `api.revenuecat.com/v1/...` の `v1` は RC の API パス**であって Apple 通知バージョンではない (= 「V1 設定になっている」と誤読しやすい罠。実際オーナーが一度誤認した)
- **Apple は価格を「価格ポイント」から選択する方式** (自由入力不可)。Android で決めた ¥1,480 が選べず ¥1,500 になる → 両ストアで JP 価格が数十円ずれるのは仕様。±許容を前提に設計する

対策: ストア設定の R 項目に「**実 UI のタブ名・選択肢・前提条件 (価格保存等) を画面で確認**」を必ず入れる。手順書 (英語語彙ベース) と現地語 UI の対応表を作っておく。一度設定済みでも、認証情報は片方だけ入っている等があるので**実画面で確認してから再発行しない** (P8 は再 DL 不可)。

---

## 6. AI アシスタントとの協働パターン

### 6.1 AI の「楽な選択」傾向を警戒する

Solara App Attest + RC Webhook + Play Integrity S1 で、AI (= 私) が 5+ 回オーナーに修正された:

| # | 機能 | AI の素案 | オーナーの問いかけ | 結論 |
|---|---|---|---|---|
| 1 | App Attest | R1-R8 を一括「実機検証必要」と並べた | 「未確認は今調べて確定できないか?」 | 6/8 即時確定 |
| 2 | App Attest | appattest-checker-node 推奨 | 「もっと簡潔な方法はないか?」 | 詳細調査で案 B' (ハイブリッド) に変更 |
| 3 | App Attest | Layer C を後回し | 「2/3 重チェック必要?」 | S4 統合へ前倒し |
| 4 | App Attest | `signatureOnly: true` で時刻チェック OFF | 「これは問題ある?」 | 時刻チェック C+D 追加 |
| 5 | Play Integrity | STRONG_INTEGRITY で区切る選択肢 | 「OS 対応下限と Play Integrity 閾値を揃える」 | minSdk 31 + STRONG は乖離 (= 古いパッチ端末を弾く) → DEVICE_INTEGRITY で区切る (オーナー誤解を正しく訂正できた逆ケース) |
| 6 | Play Integrity | R8 (Self-managed key が Standard でも使えるか) を「概算解決」とラベルし実機確認を先送り | 「エラーが出ても今までの調査をすぐ捨てるな。原因と最新情報を先に調べろ」 | S7 実機で `JWEInvalid` → Standard は Google decode API 必須と判明。だが既存枠組みは再利用でき decode だけ差し替えで R8 突破。**先送りした R 項目が最も高くつく所で崩れた**典型 |

**パターン**: AI は「実装量が少ない選択」「既存コードに優しい選択」「変更が小さい選択」に流れる傾向。オーナーが**能動的に問いかけないと、素案で固まる**。

逆ケース (#5) も大事: オーナーの問いかけが間違っていても、AI が一次資料を再確認して**「OS 対応下限と STRONG_INTEGRITY 閾値は別軸」**と説明できれば、誤った決断を未然に防げる。AI 側で「オーナーの意図は理解、ただし事実は違う」と区別する。

### 6.2 オーナーが投げるべき問いかけ集

セキュリティ・課金・認証など重要機能の設計レビュー時、以下を必ず聞く:

1. **「これは問題ないの? 代替案はある?」** (= AI の選択を疑う)
2. **「もっと簡潔/画期的な方法は? 公式情報で再調査して」** (= 楽じゃない方向に振る)
3. **「未確認は今確定できないものばかり?」** (= R 項目の前倒し)
4. **「多層チェック必要? 過剰にやるとダメだけど」** (= ROI 評価を要求)
5. **「業界標準と言うけど、本当に確認した?」** (= 一次ソース要求)
6. **「本番後 5 年の運用負荷でも判断して」** (= 短期最適化を阻止)

### 6.3 AI へのフィードバックは記録する

オーナーの修正が入った場合、AI は:
- `session_log.md` に「教訓」として記録する
- 同じパターンを次回繰り返さないルールを memory に追加する
- ただし AI は教訓を 6 回書いても忘れる傾向 → オーナー側でも警戒継続

---

## 7. ドキュメント運用

### 7.1 設計ドキュメントの章立てテンプレ

```
1. ステータス + 履歴 (v1.0 → 現在まで、各版の変更点)
2. ゴールとスコープ
3. 用語 / データフロー図
4. 確定事項 (Phase 1 検証手順、9 step 等)
5. 技術選定 (採用した理由 + 不採用案の理由)
6. ファイル構成
7. テスト戦略
8. ロールアウト計画 (セッション分割)
9. リスクと未確認項目 (R 項目)
10. オーナー判断必要事項 (Q 項目)
11. 参考資料 (一次ソース URL + 二次ソース)
12. 実装方針 (写経元、依存ライブラリ)
13. 確定値 (Team ID、Bundle ID、固定定数)
14. Deploy 手順 (本番化前のオーナー作業)
15. 運用ガイド (監視ログ / kill switch / 障害対応)
```

### 7.2 「次のセッション開始時に必ず読む」ドキュメントを 1 つだけ作る

複数のドキュメントを「あれも、これも」読ませると人間 (AI 含む) は読まない。**1 つの index 的ドキュメント** (例: `app_attest_design.md`) に集約し、そこから他に link する。

メモリ側も同じ: `MEMORY.md` を index にして、各メモリファイルへポインタ。

### 7.3 ドキュメントは「将来の自分」が読んで分かる形にする

- 専門用語を当然視しない (= 用語表セクションを必ず持つ)
- 「なぜそう決めたか」を必ず書く (= 結論だけでは数ヶ月後に意図が分からない)
- 「不採用にした選択肢」を残す (= 同じ検討を再びしないため)

---

## 8. テンプレ集

### 8.1 セッション 0 (設計確定) チェックリスト

実装着手前に必ず:

- [ ] 機能の脅威モデル (= 何から守るか) を列挙
- [ ] R 項目 (未確認の事実) を全部リストアップ + 確度ラベル付き
- [ ] R 項目を「今確定可能 / 実装中に判明 / 実装後計測必須」に 3 分類
- [ ] 今確定可能な R 項目を全部つぶす (= 1-2h で完了)
- [ ] Q 項目 (オーナー判断) を全部リストアップ + 推奨案併記
- [ ] オーナーに Q 項目を聞いて回答を記録
- [ ] 採用候補ライブラリの GitHub API でメンテ状況確認
- [ ] ライブラリのソース import 文を grep して Workers/対象環境互換性確認
- [ ] 既存事例 (障害事例含む) を 1-2 個調査
- [ ] 設計ドキュメント v1.0 作成 + オーナーレビュー
- [ ] ロールアウト計画 (セッション分割) を設計ドキュメント末尾に書く

### 8.2 各実装セッションのチェックリスト

- [ ] セッション開始時に設計ドキュメントを再読
- [ ] このセッションの deliverable を明確化 (= 何が完成すれば次に進めるか)
- [ ] テストファースト (= 実装前にテストの形を決める)
- [ ] 単体テストを書く (本番コードを書く前 or 直後)
- [ ] 実機検証が必要なら wrangler dev or 同等で動かす
- [ ] commit メッセージに「何を、なぜ」変更したかを書く
- [ ] 次のセッションへの引き継ぎメモを残す

### 8.3 本番 deploy 前のチェックリスト

- [ ] 設計ドキュメントの全 R/Q 項目が決着済み
- [ ] テストが全 PASS (単体 + smoke + 既存テスト維持)
- [ ] bundle size が制限内
- [ ] 段階リリース機構 (log_only / enforced / disabled) が動作確認済み
- [ ] 監視ログのキーワードが明確 (= 何が出たら異常か)
- [ ] kill switch の操作手順を docs に書いた
- [ ] 障害時の連絡先 / 復旧手順を docs に書いた
- [ ] オーナーが deploy 手順を理解した (= 自分一人で実行できる)

### 8.4 Webhook 受信実装のチェックリスト

- [ ] 認証方式は constant-time 比較 (`===` ではない)
- [ ] secret は wrangler/環境変数 secret 管理 (vars に書かない)
- [ ] secret 未設定時は 503 (公開前ガード)
- [ ] event_id 単位の冪等性 (INSERT OR IGNORE)
- [ ] out-of-order ガード (last_event_at 比較)
- [ ] 未知 event は安全側に倒す (Pro 維持しない / 権限付与しない)
- [ ] cache invalidate (受信 instance で即時、cross-instance は TTL eventual)
- [ ] rate limit bucket を専用に高めに設定 (SaaS 突発バーストで弾かない)
- [ ] CORS 不要 (外部 POST、ブラウザ起点ではない)
- [ ] 単体テストで全 event 種別をカバー
- [ ] 設計 docs に event 種別マップ + エラーコード一覧 + Deploy 手順を明記

### 8.5 外部 SaaS から鍵を取得する公式手順チェックリスト (Self-managed key)

- [ ] 公式手順を SaaS UI で実際に確認 (docs と実 UI が乖離していないか)
- [ ] 鍵取得形式を確定 (PEM vs base64 DER vs JWK)
- [ ] ハイブリッド方式なら RSA 鍵ペアをクライアント側で生成 (Git 配下に置かない)
- [ ] passphrase をパスワードマネージャー保管
- [ ] 公開鍵をアップロード、暗号化応答ファイルダウンロード
- [ ] 復号して deploy 環境 (Worker secret 等) に投入
- [ ] 平文鍵をローカルに残さない (`api_keys.txt` 削除)
- [ ] private.pem (passphrase 暗号化済) のみ保管 (rotation 時に再使用)
- [ ] 鍵 rotation 手順を docs に書いた
- [ ] 漏洩時の対応 (再生成 + secret 上書き + SaaS UI 同期) を docs に書いた

---

## 9. 参考: Solara セキュリティ層関連ファイル

このドキュメントの元になった実装:

### Apple App Attest (iOS、v3.0 完成)
- `apps/solara/docs/app_attest_design.md` — 設計ドキュメント v3.0 + v2.2 統合変更点
- `apps/solara/docs/Apple_App_Attestation_Root_CA.pem` — Apple 公式 Root CA (取得日: 2026-05-19)
- `apps/solara/worker/src/auth/` — Worker 側実装 (cbor.js / apple_root_ca.js / attestation.js / assertion.js / app_attest.js / attestation_state.js)
- `apps/solara/worker/src/index.js` — Worker entry + middleware 配線
- `apps/solara/worker/wrangler.toml` — DO binding + nodejs_compat + env vars
- `apps/solara/worker/test/` — 単体テスト + fixtures (cbor.test 26 + app_attest.test 27)
- `apps/solara/worker/r1_check/` — 実機検証用 minimal Worker
- `apps/solara/lib/utils/app_attest_client.dart` — Flutter 側クライアント
- `apps/solara/lib/main.dart` — initialize 配線

### RevenueCat Webhook + Pro エンタイトルメント (v2.2 完成)
- `apps/solara/docs/revenuecat_webhook.md` — 設計 D1-D10 + アーキ図 + event 種別マップ + 運用手順
- `apps/solara/worker/src/webhooks/revenuecat.js` — Webhook handler (268 行、Bearer 認証 + event 種別分類 + DO upsert + cache invalidate)
- `apps/solara/worker/src/auth/entitlement_cache.js` — Worker メモリ 60s TTL cache (80 行)
- `apps/solara/worker/src/auth/attestation_state.js` — DO に `user_entitlements` + `webhook_events` 2 表追加 + 2 endpoint
- `apps/solara/worker/test/revenuecat_webhook.test.js` — 26 ケース PASS
- `apps/solara/lib/utils/purchases_service.dart` — RevenueCat SDK ラッパー + `appUserId` getter
- `apps/solara/lib/utils/app_attest_client.dart` — body `__appUserId` 自動注入 (改ざん耐性 + Worker entitlement lookup キー)

### Play Integrity (Android、実装 v1.1 完成、S1-S7、実機 R8 突破)
- `apps/solara/docs/play_integrity_design.md` — 設計 v1.1 (Q1-Q4 確定、R1-R8、12-step 検証、Deploy 手順、Google decode API 方式)
- `apps/solara/worker/src/auth/play_integrity.js` — 12-step verify + `getGoogleAccessToken` (SA JWT→OAuth2) + `decodeIntegrityToken` (Google decode API) + `verifyPlayIntegrityFlow` (decodeFn DI)
- `apps/solara/worker/src/auth/attestation_state.js` — DO に `integrity_nonces` 表 + create/consume endpoint 追加
- `apps/solara/worker/src/index.js` — middleware OS 経路分岐 + `/auth/integrity/challenge` + 診断 endpoint (`/diagnose` SA 健全性 + `/decode-test` 実機 token 検証、enforced 時 404)
- `apps/solara/worker/wrangler.toml` — `GOOGLE_PLAY_INTEGRITY_SA_JSON` secret + `PLAY_INTEGRITY_ENFORCEMENT` (log_only/enforced) + `ANDROID_CERT_SHA256_ALLOWLIST` (実機採取 cert)
- `apps/solara/worker/test/play_integrity.test.js` — Google decode mock + SA JWT 経路 29 ケース (worker 累計 126/126)
- `apps/solara/lib/utils/app_attest_client.dart` — Android 経路 (nonce 取得→clientData{nonce,uid,ts}→`verify()`→3 ヘッダー注入)
- `apps/solara/tools/build_release.py` — `--gcp-project-number` で `SOLARA_GCP_PROJECT_NUMBER` を dart-define 注入
- 旧 Self-managed key (`PLAY_INTEGRITY_ENCRYPTION_KEY` / `VERIFICATION_KEY`) は wrangler secret に残置 (将来 Classic に戻す保険、v1.1 では未使用)

### 横断参照
- `lessons_security_critical_features.md` (memory 側、AI 自省用) — 私の判断ミス 4-5 パターン + オーナー問いかけ 6 パターン + 安全装置
- `project_solara_launch_checklist.md` (memory 側) — Phase 0-6 全タスク管理

---

## 10. Mac なしで iOS をビルド・App Store 配信する (Codemagic CI/CD)

**対象**: Windows / Linux だけで開発する個人開発者が、Mac を買わずに Flutter (or ネイティブ) iOS アプリを App Store まで出す方法。
**ケーススタディ**: Solara iOS (2026-05-21、1 セッションで Codemagic セットアップ→ビルド→TestFlight→iPhone 実機インストール→Sandbox 課金テストまで完走)。
**結論**: **Mac は1台も要らない。** 唯一の本物のハードウェア要件は iPhone 実機1台 (動作確認 + 課金テスト用)。

### 10.1 何が Mac なしでできるか (実証済み)

| 工程 | Mac 要否 | 代替 |
|---|---|---|
| iOS ビルド (IPA 作成) | ❌ 不要 | Codemagic クラウド macOS (mac_mini_m2) |
| 署名 (証明書/プロファイル) | ❌ 不要 | App Store Connect API キー + クラウドで自動生成 |
| TestFlight / App Store アップロード | ❌ 不要 | Codemagic publishing |
| 審査提出 | ❌ 不要 | `submit_to_app_store: true` |
| **Sandbox 課金 (IAP) テスト** | ❌ 不要 | **TestFlight (本番アカウント+Sandbox 課金ハイブリッド) を iPhone 実機で** |
| 動作確認 | △ | **iPhone 実機が1台必要** (Mac ではない) |

費用: Codemagic 無料枠 = macOS M2 **500 分/月** (個人アカウント限定。Team を選ぶと無料枠なし)。iOS ビルド1回 8〜15 分 → 月 30〜60 回。**通常は ¥0 で公開まで完走**。post-processing (Apple 処理待ち) は **ビルド分を消費しない** (非同期、macOS マシン解放後に実行)。

### 10.2 🔴 最重要: Codemagic iOS 署名の詰まりどころ3点 (この順で必ず踏む)

公式の「`ios_signing` ブロックを書けば自動署名」は**罠**。実際は以下3点を踏まないとビルドが署名で落ちる。

1. **`codemagic.yaml` はリポジトリの「ルート」に置く**
   - Codemagic はサブフォルダの yaml を検出しない。モノレポ (`apps/<name>/`) でも yaml は**ルート**に置き、`working_directory: apps/<name>` でサブフォルダを指定する。
   - 症状: Finish 画面で「mobile application が見つからない」。

2. **宣言的 `ios_signing:` ブロックを使わない → スクリプトで `--create`**
   - `environment.ios_signing` はビルド前にプロファイルを**取得するだけ**で、無いと `No matching profiles found for bundle identifier ... distribution type app_store` で**スクリプト実行前に**落ちる (ログが空になる)。
   - 代わりに `ios_signing` を消し、`integrations.app_store_connect: "<キー名>"` だけ残してスクリプトで生成:
     ```yaml
     - name: Set up code signing
       script: |
         keychain initialize
         app-store-connect fetch-signing-files "<bundle-id>" --type IOS_APP_STORE --create
         keychain add-certificates
         xcode-project use-profiles
     ```

3. **`CERTIFICATE_PRIVATE_KEY` 環境変数 (RSA 2048 PEM) が必須**
   - 上記でも `Cannot save signing certificates without certificate private key` で落ちる。Apple アカウントに配布証明書が既にあっても、その**秘密鍵はクラウドマシンに無い**ため使えず、新規作成にも秘密鍵が要る。
   - 生成 (Git for Windows 同梱の ssh-keygen で可):
     ```
     ssh-keygen -t rsa -b 2048 -m PEM -f ios_distribution_private_key -q -N ""
     ```
   - 生成した秘密鍵の**全文 (`-----BEGIN RSA PRIVATE KEY-----` 〜 END まで)** を Codemagic の環境変数 **`CERTIFICATE_PRIVATE_KEY`** (Secure) に登録。Codemagic CLI が `fetch-signing-files` でこのキーを自動使用し、新規配布証明書を秘密鍵付きで作成する。yaml 変更は不要 (env 名で自動認識)。
   - 秘密鍵ファイルはローカルに安全保管 (Git に入れない)。次回以降も同じキーで署名できる。

### 10.3 Codemagic UI 側の準備 (yaml では持てない)

- **App Store Connect API キー**を ASC (Users and Access > Integrations > Team Keys、**App Manager** 権限) で発行 → .p8 + Issuer ID + Key ID を控える (.p8 は**1回だけ DL 可**) → Codemagic の Integrations > Apple Developer Portal に登録。**Codemagic 側の登録名を yaml の `integrations.app_store_connect` と完全一致**させる (ASC 側のキー名とは無関係)。
- **環境変数グループ**を作り、`--dart-define` で渡したい鍵 (例: RevenueCat 公開キー `appl_xxx`) や `CERTIFICATE_PRIVATE_KEY`、ビルド番号採番用の `APP_STORE_APP_ID` (ASC のアプリ数値 ID) を入れる。
- **entitlement を使う機能 (Sign in with Apple 等) は、ビルド前に Apple Developer ポータルの App ID で capability を有効化**する。entitlement だけ追加して App ID 側を有効化しないと自動署名が失敗する。
- ビルド番号は `app-store-connect get-latest-testflight-build-number "$APP_STORE_APP_ID"` + 1 で自動採番できる (iOS の CFBundleVersion は Android と独立、初回は 0→1)。
- リポジトリ接続は**そのリポジトリを所有する GitHub アカウント**で行う。別アカウント所有の repo は「No repositories available」になる (org なら App を org にインストール、別ユーザー所有なら別 Chrome / シークレットでそのアカウントでログインして Codemagic に入り直す)。

### 10.4 TestFlight + Sandbox 課金テスト (Mac なし) の要点

- **TestFlight は端末の「App Store の Apple ID (設定 > 自分の名前 > メディアと購入)」のビルドだけ表示する**。内部テスターに登録する Apple ID と、iPhone の「メディアと購入」の Apple ID を**一致**させること (不一致だと TestFlight にビルドが出ない)。
- 内部テスト = Beta 審査不要で即配信。テスターが App Store Connect チームメンバーでない場合は、ユーザを招待 (App Manager 等) → 招待メール承認 → 内部テストグループに追加 → ビルド追加。
- **TestFlight ビルドの IAP は自動的に「無料 + Sandbox」**。購入シートに通常の Apple ID が出ても**そのまま購入してよい** (課金されない)。**Sandbox テスター account や ID 切替は TestFlight では不要** (Sandbox テスター account は Xcode/直接インストール build 用)。
- RevenueCat ダッシュボードの Customers 一覧は**集計ラグ**で購入直後は空に見える。**Sandbox 購入は「Sandbox」リスト**に出る (本番用「Active subscription」リストには出にくい)。アプリで Pro が解放された時点で RC は検証済み。Sign in しなければ顧客は `$RCAnonymousID:...` になる。
- 商品 ID で OS を見分けられる: Google Play = `productId:basePlanId` 形式 (`cosmic_pro_monthly:monthly-auto`)、iOS = `com.<...>.monthly` 形式。価格 (Android ¥1,480 / iOS ¥1,500) でも判別できる。

### 10.5 輸出コンプライアンス (Export Compliance) の罠

- アップロード後 TestFlight で「コンプライアンスがありません」→「管理」で回答。HTTPS + 標準ハッシュのみのアプリは「**標準的な暗号化アルゴリズム**」を選ぶ。
- 次の「フランスで配信予定?」で **「はい」を選ぶとフランス向けの輸出書類アップロードが要求される**。テスト目的なら **「いいえ」で回避**できる (フランス配信地域は後から「価格と販売状況」で変更可、TestFlight テストには影響なし)。
- 恒久対応: Info.plist に **`ITSAppUsesNonExemptEncryption = false`** を入れると、以降のビルドでこの質問が出ず、フランス含め書類不要 (= 免除対象の暗号のみ使用、の宣言)。

### 10.6 再利用チェックリスト (新アプリで Mac なし iOS 公開)

- [ ] Codemagic に **Individual** でサインアップ + repo 所有アカウントで接続
- [ ] `codemagic.yaml` を**リポジトリルート**に置く (モノレポは `working_directory`)
- [ ] `ios_signing` ブロックは使わず、`fetch-signing-files --create` スクリプト方式
- [ ] `CERTIFICATE_PRIVATE_KEY` (ssh-keygen RSA2048 PEM) を env に登録
- [ ] ASC API キー発行 → Codemagic に登録 (名前を yaml と一致)
- [ ] 使う entitlement の capability を App ID で有効化 (ビルド前)
- [ ] Info.plist に `ITSAppUsesNonExemptEncryption=false`
- [ ] ビルド → TestFlight → 内部テスター (= iPhone の Apple ID と一致) → 実機インストール
- [ ] TestFlight で IAP を無料テスト (ID 切替不要) → RC「Sandbox」リストで確認
- [ ] 動作確認後 `submit_to_app_store: true` で審査提出

---

## 11. 外部設定の実行順序と状態管理（手戻り防止）

**対象**: コードではなく「外部ダッシュボード / CLI 設定」(ストア / RevenueCat / Cloudflare / Codemagic / Apple Developer / Google Play)。これらは依存関係と「やった / やってない」状態が見えにくく、別フェーズで同じ対象を二度触って手戻りしやすい。**この章は実装の知見 (§1-9) より「作業の段取り」に特化**している。

### 11.1 なぜ手戻りが起きるか (実例: 2026-05-21 Solara RevenueCat Webhook)

- Android ストア設定フェーズ (前半) で RevenueCat webhook を **URL だけ作成**。Authorization は Worker secret 未作成のため**空** (RC では Authorization が Optional なので空で登録できてしまう)。
- Worker deploy フェーズ (後半) で secret を作成 → webhook の Authorization を埋める必要が出た。
- だが「webhook 作成済 / auth 空 / secret 待ち」を**どこにも記録していなかった** → 新規作成を試みて `same url` 重複エラー → 「鍵を新しく作ったら一致しないのでは / ログが見えなくなるのでは」と不安が連鎖し、確認に時間を浪費。
- **本質**: ① 依存関係 (secret → webhook auth) を意識しなかった ② 片方だけ先に作って放置した ③ その状態を記録しなかった、の 3 つが重なった。これは「重大なやり直し」には至らなかったが、同種の状態未記録は別の場面でも複数回起きている = **構造的問題**。

### 11.2 ルール

1. **依存のないものは前倒しする**。特に **`wrangler secret put` は依存ゼロ → 最初にやる**。secret を先に作っておけば、RevenueCat webhook を作るとき Authorization (`Bearer <secret>`) を**同じ操作で完成**でき、「空で作って後で戻る」分割が消える。
2. **同じ対象を二度触らない**。secret 作成と webhook Authorization 設定は連続して 1 パスで終わらせる。
3. **やむを得ず分割するときは「保留」を明示記録**する: 例「webhook URL 作成済 / Authorization 空 (secret 待ち) / TODO: secret 作成後に `Bearer <secret>` を埋める」。
4. **サイト別に「やった / 保留 / 未着手」を記録**し、設定を案内・再実行する前に必ずその記録を見る + オーナーに「これ、もう作ってある?」と先に確認する (memory: `feedback_track_external_dashboard_state.md`)。
5. **重複作成を拒否する外部 (RevenueCat webhook の URL 等) は、新規作成の前に既存有無を確認**する。「新規作成」と「既存を編集」を取り違えない。

### 11.3 依存を意識した推奨実行順 (テンプレ — 新アプリで埋める)

> 「番号が小さいほど依存が少ない = 先にやれる」。着手前にこの表を埋め、依存の矢印を確認してから動く。

| 順 | サイト | 作業 | これが先に要る (依存) |
|---|---|---|---|
| 1 | Cloudflare (wrangler) | `wrangler secret put` 各種 (API キー / **webhook 認証 secret**) | — (依存なし、最初にやる) |
| 2 | Apple Developer | App ID の capability 有効化 (Sign in with Apple 等) | — (CI 署名より前) |
| 3 | Codemagic | ASC API キー / `CERTIFICATE_PRIVATE_KEY` / env group | ASC API キー発行 |
| 4 | App Store Connect / Google Play | サブスク商品 / トライアル / サーバ通知・RTDN | — |
| 5 | RevenueCat | Entitlement / Offering / 商品 import | 4 (ストア商品) |
| 6 | RevenueCat | **Webhook URL + `Bearer <secret>`** | **1 (Worker secret)** |
| 7 | Cloudflare (wrangler) | `wrangler deploy` | 1 + 実装完了 |
| 8 | 実機 (TestFlight 等) | 課金 / アカウント削除 / E2E 検証 | 6 + 7 |

ポイント: **6 (webhook auth) は 1 (secret) に依存する**。1 を最初にやれば 6 を 1 パスで完成できる。逆に 1 を後回しにすると、webhook を空で作って 6 で戻る = 今回の手戻り。これが「後半でやることを前半でやれるなら一気にやる」の具体形。

### 11.4 状態の記録先と粒度

- アプリ固有の進捗は memory の launch_checklist 等に「✅完了 (日付) / [WIP] 保留理由 / [ ] 未着手」で残す。
- 外部で**作成済みのもの**は「サイト名・対象名・URL/ID・空欄や保留の有無」まで**具体的に**書く。
  - ❌ 抽象的: `[ ] webhook 設定` ← 作成済みか次セッションで判別できず再発
  - ✅ 具体的: `RC webhook 'Solara Worker' 作成済、URL .../webhooks/revenuecat、Authorization 空=secret 待ち`
- 各フェーズ開始時にこの記録を読む。「やったことの管理」が抜けると、調査・確認だけで時間を浪費する (= リスク高 / 時間の無駄)。

### 11.5 サインイン (OAuth) のプラットフォーム別セットアップと「アカウント削除」の依存

**🔴 最重要の依存**: アプリ内アカウント削除 (Apple 5.1.1(v)) は「**サインインできること**」が前提。削除ボタンはサインイン中のみ出るので、**サインイン設定が未済だと削除のテストも公開もできない**。サインインは「課金・削除」より**先に着手すべき依存項目**。新アプリでは「サインイン設定」を §11.3 の実行順表の上位に置く。

**プラットフォーム別 OAuth クライアント (互いに独立・別物)**:

| OS / 用途 | 必要なもの | 備考 |
|---|---|---|
| Android (Google) | ① Android OAuth client (package + **SHA-1**) ② Web OAuth client (= `serverClientId`) | google_sign_in 7.x は **serverClientId を渡すだけで動く** (google-services.json 不要・コード変更不要、`--dart-define` で注入) |
| iOS (Apple) | App ID で **Sign in with Apple capability 有効化** + `Runner.entitlements` | 無いと自動署名失敗 or 実機サインイン不可 |
| iOS (Google、任意) | **iOS OAuth client + URL scheme** (reversed client ID) | Android の SHA-1 とは無関係。別途必要 |
| 共通 | **Web client (serverClientId) は 1 つを全 OS 共有** | プラットフォーム別 client は別々に要る |

**🔴 SHA-1 は debug と release で別物**: `flutter run` テスト = **debug SHA-1**。Play 配信 = **Play App Signing / アップロード鍵の release SHA-1** を同 Android client に追加登録しないと本番で Google サインインが動かない。両方登録する。

**テストユーザーの罠**: OAuth 同意画面が「Testing」の間は、**登録したテストユーザーのアカウントしかサインインできない** (それ以外は「アクセスをブロック」)。実機でサインインに使うアカウントを必ずテストユーザーに追加する。

**Apple の縛り (Guideline 4.8)**: iOS で第三者サインイン (Google 等) を出すなら **Sign in with Apple も必須**。Android にこの縛りは無い。手軽な逃げ道は「**iOS は Apple のみ表示**」(Google ボタンを iOS でだけ隠す数行)。

**iOS テストは Mac/Codemagic 必須**: Windows の `flutter run` は iPhone 用ビルドを作れない (Apple 制約)。iOS 実機検証は Codemagic → TestFlight。クラッシュ等の**安価な事前確認は Android `flutter run`** で (同一 Flutter コードなので削除フローのクラッシュ有無は Android で先に潰せる)。

**実例 (2026-05 Solara)**: アカウント削除をテストしようとしたら Android で「Google サインイン失敗」→ 調査で google-services.json も OAuth client も無し (= サインイン完全未設定) と判明。サインインは削除の隠れた前提だった。Cloud Console で Android OAuth (debug SHA-1) + Web client を作成 → `--dart-define=SOLARA_GOOGLE_SERVER_CLIENT_ID=<web id>` で `flutter run` → 削除スモーク合格。iOS は Codemagic → TestFlight → Apple サインイン → 削除合格 + CF Observability で `do/account-purge` 実行を確認 (サーバー側削除も成立)。

---

## 12. このドキュメント自体のメンテ

新しいアプリ開発で類似機能を実装するたびに、本ドキュメントを更新する:
- 新しい failure pattern が見つかったら §4 に追加
- 新しい有用な問いかけが見つかったら §6.2 に追加
- 新しい外部 SaaS の評価事例が出たら §3.3 に追加
- テンプレが古くなったら §8 を更新
- 多層防御の ROI 評価表 (§4.2) は機能追加のたびに行追加 (Solara で 5 行追加した実例)
- 外部設定の順序 / 依存 / 状態未記録による手戻りが出たら §11 (実行順テンプレ表 + 記録粒度) を更新
- サインイン / OAuth / 認証の新しい罠が出たら §11.5、log_only モニタの教訓は §4.3 を更新

最終更新: 2026-05-21③ (§11.5「サインイン (OAuth) のプラットフォーム別セットアップと『アカウント削除』の依存」を新規追加 + §4.3 に「log_only はクライアントのヘッダー付与漏れを enforced 前に検出する窓」追記。Solara アカウント削除テストで「サインインが削除の隠れた前提」「Android debug/release SHA-1 は別」「google_sign_in 7.x は serverClientId だけで動く」「iOS は Apple のみ表示で逃げられる」「CF Observability で `do/account-purge` のサーバー側削除を確認」「log_only ログの `missing_attestation_headers` が enforced 前の警告」を一般化)

その前: 2026-05-21② (§11「外部設定の実行順序と状態管理」を新規追加。RevenueCat webhook を空 auth で先に作って後で戻り `same url` 重複エラーになった手戻りを契機に、①依存ゼロの `wrangler secret put` を最初にやれば webhook auth を 1 パスで完成できる ②同じ対象を二度触らない ③分割時は「保留」を具体記録する、を順序テンプレ表 §11.3 として一般化。memory `feedback_track_external_dashboard_state.md` と対。なお Mac なし iOS 配信は §10、本メンテ章は §12 に繰り下げ)

その前: 2026-05-21① (Solara iOS を **Mac なしで Codemagic→TestFlight→iPhone 実機→Sandbox 課金テスト**まで完走。§10「Mac なしで iOS をビルド・App Store 配信する」を新規追加。署名の詰まりどころ3点 = codemagic.yaml はルート必須 / `ios_signing` ブロック不可で `fetch-signing-files --create` 方式 / `CERTIFICATE_PRIVATE_KEY` env 必須。旧 §1.2 の「実機購入テストは Mac 必須」記述を訂正)

その前: 2026-05-20 (Solara Play Integrity S7 = 実装 v1.1 完成 + 実機 R8 突破。§1.3 / §4.2 / §5.8 / §6.1 更新)
