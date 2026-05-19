# アプリ開発の知見集 — セキュリティクリティカル機能の設計から本番投入まで

**対象**: 個人開発者 / 小規模チームが、Apple/Google ストア向けのアプリで認証・課金・サーバー検証など「失敗が許されない」機能を実装するときの方法論
**ケーススタディ**: Solara (Flutter + Cloudflare Workers) の Apple App Attest 実装 (2026-05、7 セッション、~12-15h、累計コード ~1100 行 + テスト 64 ケース全 PASS)
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

## 1. ケーススタディ: Solara App Attest 7 セッション

### 当初の見積もり vs 実績

| 項目 | 当初見積もり | 実績 |
|---|---|---|
| 期間 | 4 日 (32h) | ~12-15h (7 セッション × 1.5-2h) |
| 設計修正回数 | 0-1 回想定 | **8 回** (v1.0 → v3.0) |
| ライブラリ採用判断 | 1 回で確定 | **4 回切替** (案 A → 案 B' → C+D + Firebase 検討) |
| テストケース | 想定なし | 64 ケース全 PASS |
| ドキュメント | 設計書 1 つ | 設計書 v3.0 + 汎用ノウハウ集 (本書) |

### セッション構成 (= 設計を先に固めた効果で工数 50% 短縮)

| # | 内容 | 教訓 |
|---|---|---|
| 1 | 設計確定 (R/Q 項目決着、ライブラリ選定、アーキテクチャ) | コード書く前に未確認項目を全部つぶす |
| 2 | 最も基礎の純粋関数 (CBOR デコーダ) + 単体テスト + 実機動作確認 | 「動くか」を最小コードで早期検証 |
| 3 | 中核ロジック (証明書チェーン検証) + 改竄テスト | 実 fixture でデバッグ可能な状態に |
| 4 | 補助ロジック (assertion verify) + 永続化 (DO) + smoke test | 永続化は実機テスト必須 |
| 5 | 本番統合 + 段階リリース機構 (log_only) | 本番化前の安全装置を必ず入れる |
| 6 | クライアント側統合 + 既存コード置換 | 既存テストが壊れないか毎回確認 |
| 7 | ドキュメント整理 + 運用ガイド + メモリ最終化 | 「将来の自分」のための再利用性確保 |

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

Solara で検討した層 (App Attest 文脈):

| 層 | 防御効果 | 実装 | 偽陽性 | ROI | 採否 |
|---|---|---|---|---|---|
| App Attest assertion 検証 | 🟢 curl 直叩き全防御 | 高 (~700 行) | 低 | 🟢 最高 | ✅ 採用 |
| per-user rate limit (Layer C) | 🟢 突破時の被害最大化防止 | 低 | 低 | 🟢 高 | ✅ 採用 |
| Bot Fight Mode (Cloudflare) | 🟢 補助的 | 設定 1 クリック | ほぼゼロ | 🟢 最高 | ✅ 採用 |
| 異常検知アラート | 🟢 リアルタイム発見 | 中 | 低 | 🟡 中 | ✅ 採用 (後続) |
| Apple step 6 (challenge inclusion 厳格) | 🔴 Secure Enclave 突破前提でしか効果なし | 中 (latency +1RTT) | 中 | 🔴 低 | ❌ **不採用** |

「ROI 低い層は採用しない」勇気が大事。

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

---

## 6. AI アシスタントとの協働パターン

### 6.1 AI の「楽な選択」傾向を警戒する

Solara App Attest で、AI (= 私) が 4 回オーナーに修正された:

| # | AI の素案 | オーナーの問いかけ | 結論 |
|---|---|---|---|
| 1 | R1-R8 を一括「実機検証必要」と並べた | 「未確認は今調べて確定できないか?」 | 6/8 即時確定 |
| 2 | appattest-checker-node 推奨 | 「もっと簡潔な方法はないか?」 | 詳細調査で案 B' (ハイブリッド) に変更 |
| 3 | Layer C を後回し | 「2/3 重チェック必要?」 | S4 統合へ前倒し |
| 4 | `signatureOnly: true` で時刻チェック OFF | 「これは問題ある?」 | 時刻チェック C+D 追加 |

**パターン**: AI は「実装量が少ない選択」「既存コードに優しい選択」「変更が小さい選択」に流れる傾向。オーナーが**能動的に問いかけないと、素案で固まる**。

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

---

## 9. 参考: Solara App Attest 関連ファイル

このドキュメントの元になった実装:

- `apps/solara/docs/app_attest_design.md` — 設計ドキュメント v3.0 確定版
- `apps/solara/docs/Apple_App_Attestation_Root_CA.pem` — Apple 公式 Root CA (取得日: 2026-05-19)
- `apps/solara/worker/src/auth/` — Worker 側実装 (cbor.js / apple_root_ca.js / app_attest.js / attestation_state.js)
- `apps/solara/worker/src/index.js` — Worker entry + middleware 配線
- `apps/solara/worker/wrangler.toml` — DO binding + nodejs_compat + env vars
- `apps/solara/worker/test/` — 単体テスト + fixtures
- `apps/solara/worker/r1_check/` — 実機検証用 minimal Worker
- `apps/solara/lib/utils/app_attest_client.dart` — Flutter 側クライアント
- `apps/solara/lib/main.dart` — initialize 配線

---

## 10. このドキュメント自体のメンテ

新しいアプリ開発で類似機能を実装するたびに、本ドキュメントを更新する:
- 新しい failure pattern が見つかったら §4 に追加
- 新しい有用な問いかけが見つかったら §6.2 に追加
- 新しい外部 SaaS の評価事例が出たら §3.3 に追加
- テンプレが古くなったら §8 を更新

最終更新: 2026-05-19 (Solara App Attest 7 セッション完了直後)
