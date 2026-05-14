# Solara 競合分析 — 段階 B 入口

> **このドキュメントの役割**: `pro_candidates.md`（段階 A = 構造からの候補棚卸し）を受けて、
> **段階 B（市場検証）の入口**として競合の価格・フリーミアム境界を調査し、
> `pro_candidates.md` §5 の 8 論点（特に 🔴 価格 / 攻めの度合い / 試食の線引き）に
> 暫定回答を出すための作業台。
>
> **境界思想（オーナー決定 2026-05-14）**: 「無料は入口、コア体験の一部も Pro」= やや攻めた freemium。
>
> **出典**: 2026-05-14 Web 調査（末尾 §8 にリンク）。前回の競合分析
> （メモリ `project_solara_astrocarto`、2026-03 時点、AstroCartography 特化）を再検証・拡張したもの。
>
> **⚠️ 限界**: アプリストアの表示価格は地域・時期で変動する。実機での課金画面・転換率・解約率は
> 本ドキュメントに含まれない（それは段階 B の後半、実リリース後の計測）。価格は調査時点のスナップショット。

---

## 1. 競合マップ — Solara はどこと戦うのか

Solara は「占星術 + タロット + AI 解説 + Map（方位）+ Galaxy（月相リチュアル）」の複合体。
単一カテゴリの競合は存在しない。**機能ごとに別のセグメントと比較される**のが構造的な前提。

| セグメント | 代表競合 | Solara の該当機能 | Solara の立ち位置 |
|---|---|---|---|
| **A. 西洋占星術 主流アプリ** | Co-Star / CHANI / The Pattern / Sanctuary | Horoscope / 出生図 / アスペクト | 後発。ブランド・資金力で劣る。思想（2 エネルギー）で差別化するしかない |
| **B. AstroCartography 特化** | Pathfinder / Astro-Seek / Astro.com / astrocartography.app | Map（16 方位 / ACG / ライン） | **日本語専用アプリは依然ゼロ**。Solara の最大の空白地帯 |
| **C. タロット / AI 占い** | Labyrinthos / AI tarot 各種（Tarovent, Lumi, Cosmica 等） | Tarot / AI narrative | レッドオーシャン。AI タロットは量産されている。1 日 1 枚 freemium が業界標準 |
| **D. 日本の占い市場** | チャット占い Stella / ゲッターズ飯田 / ココナラ占い | （全体） | **課金モデルが構造的に違う**（§4 で詳述）。最重要の論点 |

---

## 2. 価格データ一覧（2026-05 調査時点）

### A. 西洋占星術 主流アプリ

| アプリ | 月額 | 年額 | 無料の範囲 | Pro の範囲 |
|---|---|---|---|---|
| **Co-Star** | $9 /月 | — | デイリーホロスコープ、プッシュ通知（**実用的**） | フル出生図、星に質問、相性レポート、Eros（カップル） |
| **The Pattern** | $14.99〜/月（四半期・年額あり） | — | 基本機能 | "Go Deeper+"。追加プロフィールは 1 個無料、+3 個で $9.99 |
| **CHANI** | ~$14.99 /月 | ~$40 /年 | **ごく一部のみ**（実質サブスク前提） | ほぼ全機能 |
| **Sanctuary** | $19.99 /月 | — | 限定的 | **生身の占い師チャット鑑定**を含む（高額の理由） |
| **TimePassages** | — | — | — | $29.99 買い切り（プロ版は $79+）。デスクトップソフト系の売り切りモデル |
| **AstroMatrix** | $4.99 /月 | — | 広め | プレミアム機能 |

**バンド**: 純ソフト系（人間の鑑定なし）は **$4.99〜$14.99/月**。$19.99 の Sanctuary は人間の鑑定込み。

### B. AstroCartography 特化

| サービス | 価格 | 備考 |
|---|---|---|
| **Astro.com (Astrodienst)** | 無料 | 9000 年分の天文暦、チャート作成、各種レポート。業界標準だが UI が古い |
| **Astro-Seek** | 無料 | AstroCartography オンライン計算機。Web 主体、モバイル弱い |
| **Pathfinder (iOS)** | DL 無料 + IAP | パーソナル分析が **$29.99（機能アンロック型）**。2026 で iOS の完成度は上がっている |
| **astrocartography.app** | 不明（価格ページ取得不可） | Web プロダクト |

→ **重要**: AstroCarto 系の課金は「**買い切り / 機能アンロック型**」が目立つ（Pathfinder $29.99）。
   サブスクではない。Map をどう課金するかの選択肢として記憶しておく。

### C. タロット / AI 占い

| アプリ | 価格 | フリーミアム境界 |
|---|---|---|
| **Labyrinthos** | アプリ無料（広告なし） | 物理デッキ販売（$55）で収益化。マイクロ課金（$0.10/鑑定、$0.99/33 クレジット、$9.99 プレミアム=レッスン解放）。**学習アプリ寄り** |
| **AI タロット各種**（Tarovent / Lumi 等） | freemium | **無料 = 1 日 1 枚シングルカード / Pro = 深いスプレッド・無制限**。これが業界標準 |
| **AstroNidan**（AI 占星術） | ₹3,999/年（~$149）or クエリパック ₹99〜 | Elite 年額 or 都度課金パック併用 |

### D. 日本の占い市場

| アプリ | 課金モデル |
|---|---|
| **チャット占い Stella** | **ポイント従量課金**。チャット 4.5 円/文字、電話 375 円/分。月額サブスクなし。初回 1,000pt 無料 + カード登録で +2,000pt |
| **ゲッターズ飯田の占い** | 占い師ブランド型 |
| **占いアプリ全般（日本）** | 「無料とあっても一部のみ、課金しないと結果を全部見られない」。1 回の鑑定 2,000 円以上も普通 |
| **ホロスコープ作成ツール系**（iPhemeris / Astro Gold / 月よみ） | ツールアプリ。一部は月額シルバー/ゴールド/プレミアム階層あり。無料版はネイタル保存・編集不可など |

---

## 3. フリーミアム境界の実例 — Co-Star vs CHANI

「やや攻めた freemium」の具体像は、**Co-Star 型と CHANI 型の中間**にある。

| | **Co-Star 型**（穏当寄り） | **CHANI 型**（攻め寄り） |
|---|---|---|
| 無料の範囲 | デイリーホロスコープ + 通知。**無料単体で毎日使える** | ごく一部。**実質サブスク前提** |
| 課金の壁 | "深さ"（フル出生図・質問・相性） | ほぼ全機能 |
| 成立条件 | 無料層がマーケ装置として機能 | 強いブランド・著名人（Chani Nicholas）の集客力 |
| Solara への示唆 | **後発の Solara はこちらに寄せるべき**。無料が空っぽだとストア審査・初期レビューで死ぬ | Solara はブランド力がないのでこの型は無理 |

→ **pro_candidates.md §2 のリスク印（🟡=試食設計が肝）と完全に一致**。
   攻めた境界 = 「Co-Star より少し攻める」が現実解。CHANI まで攻めると後発には自殺行為。

---

## 4. 🔴 最重要発見 — 日本市場の構造的ミスマッチ

**Solara は JP 先行リリース（launch_checklist Phase 6 Stage 1 = JP）。だが日本の占い課金の主流はサブスクではない。**

- 日本の占いアプリ市場のトップ層（Stella 等）は **チャット/電話の従量課金（ポイント制）**。
  ユーザーの課金筋肉は「1 回の相談にいくら払うか」であって「月額を払い続ける」ではない。
- 月額サブスク型は**西洋占星術アプリの文化**（Co-Star / CHANI）。日本ではまだ主流の課金体験ではない。
- 一方、**ホロスコープ"ツール"アプリ**（iPhemeris / Astro Gold 系）には月額階層が存在する。
  Solara は「占い師チャット」ではなく「ツール + 体験」なので、こちら側に近い。

**→ 段階 B でオーナーが判断すべき論点（新規、§5 に追加）:**

1. **サブスク単独でいくか、消費型（クレジット / 都度課金）を併設するか。**
   - 消費型は日本の課金習慣に合う **かつ** Gemini の従量コスト構造（1 リクエスト = 実コスト）と
     完全に一致する。「AI 占い 10 回パック ¥◯◯」はコスト構造的にも自然。
   - AstroCarto 競合（Pathfinder $29.99 機能アンロック）、AI 占星術（AstroNidan のクエリパック）も
     都度課金を併用している = 業界でも珍しくない。
   - リスク: 課金導線が 2 系統になり UX が複雑化。ストア審査の説明も増える。
2. **JP 先行で月額サブスクの転換率が想定より低い前提を持っておく。** $9.99/月が「相場として妥当か」
   以前に、「JP ユーザーが月額占いアプリにそもそも慣れていない」可能性を織り込む。

これは pro_candidates.md 段階 A では出てこなかった、**市場検証でしか見えない論点**。

---

## 5. §5 の 8 論点への暫定回答

`pro_candidates.md` §5 の論点に、本調査で出せる範囲で暫定回答する。
**確定 → `pro_candidates.md` §7（3 本柱すり合わせ完了 2026-05-15）。** 残る未決は pro_candidates §7.6。

| # | 論点 | 競合分析からの暫定回答 |
|---|---|---|
| **1** | 🔴 価格 $9.99/月・$49.99/年は妥当か | **月額は妥当、ただし「中の上」**。純ソフト系のバンドは $4.99〜$14.99。$9.99 は Co-Star($9) と同水準で、AstroMatrix($4.99) より高い。**人間の鑑定がない Solara が $9.99 を取るには、複合体（占星術+タロット+Map+Galaxy）の"幅"で正当化が要る**。年額 $49.99 は月額の約 4.2 ヶ月分 = かなり攻めた割引（CHANI は年額が月額の約 2.7 ヶ月分）。**年額は $59.99 でも通る**。値付けの前に §4（JP のサブスク不慣れ）を先に解く方が重要 |
| **2** | 🔴 攻めの度合い「無料 1 日 1 回」は試食として十分か | **十分。むしろ業界標準そのもの**。AI タロット競合（Tarovent / Lumi）が「無料=1 日 1 枚 / Pro=無制限・深いスプレッド」を採用済み。A1〜A3 の「無料 1 日 1 回」は攻めすぎではない。**逆の問題に注意**: 標準すぎて差別化にならない。差別化は回数制限ではなく 2 エネルギー思想 / Galaxy / Map 側で出す |
| **3** | 🔴 試食設計（🟡 項目の線引き） | **Co-Star 型を基準に**（§3）。「無料単体で毎日使える」状態を死守。CHANI 型（ほぼ全ゲート）は後発には不可。具体線引きは候補ごとに別途設計が要る（段階 B 後半） |
| **4** | オーブ設定(B5) は Free か Pro か | **競合に直接の比較対象なし**（オーブ微調整を課金境界にしている主流アプリは確認できず）。これは思想 vs 収益の純粋な内部判断。競合分析からは「無料に置いても競合優位は失わない / Pro に上げても競合は気にしない」=**どちらでも市場的には中立**。思想（あなたが読み取りツールを調整する）を優先して**無料寄り**を推奨 |
| **5** | 3 本柱の最終構成 | §6 参照。競合分析は pro_candidates §4 の推奨骨格（AI 使い放題を柱に上げる）を**支持する** |
| **6** | D3「姓名 × タロット」の優先度 | タロット/AI 占いはレッドオーシャン（C セグメント）。**独自占術は数少ない差別化フックなので集客側に寄せる価値あり**。ただし新規実装大。段階 B で「集客 ROI」を見て判断 |
| **7** | 無料トライアル 7 日 | 競合（CHANI 等サブスク型）は無料トライアル併用が一般的。**7 日トライアル自体は標準的で問題なし**。ただし §4 の通り JP ではトライアル後の継続率が西洋市場の数字より落ちる前提を持つ |
| **8** | 段階リリースとの整合 | Stage 1（JP 無料機能のみ）期間は、§3 の「Co-Star 型の充実した無料層」がそのまま"無料機能のみ版"として成立する。**攻めた境界でも無料層を Co-Star 水準で作っておけば Stage 1 は破綻しない** |
| **追加** | 🔴 サブスク vs 消費型併設（§4 で新規発見） | **段階 B でオーナー判断必須**。JP 課金習慣 + Gemini コスト構造の両方が消費型（クレジット/都度課金）併設を後押しする。AstroCarto・AI 占星術競合も都度課金を併用 |

---

## 6. 3 本柱への影響

pro_candidates.md §4 の推奨骨格を競合分析で検証:

| 推奨骨格の柱 | 競合分析からの評価 |
|---|---|
| **1. AI 占い 使い放題** | ✅ **支持**。AI タロット競合の標準境界（1 日 1 回 / 無制限）と一致。ただし価格面では Solara はこの柱単体だと「$4.99〜$9.99 の AI 占いアプリ群」と同じ土俵 = $9.99 の上限に張り付く。**他 2 柱で幅を出さないと値付けが持たない** |
| **2. あなたの記録庫** | ✅ **支持**。Co-Star / CHANI も履歴・レポート保存を課金側に置く。記録性は解約抑止に効く定石。思想ガードレールにも触れない（pro_candidates §3 カテゴリ C は全 ◎） |
| **3. アドバンスト占星術（B+F）** | ✅ **支持、かつここが Solara の生命線**。Map（AstroCartography）は **B セグメントで日本語専用アプリがゼロ** = 競合分析が示す唯一の明確な空白地帯。アスペクトライン 120 本・ACG・無制限拠点をこの柱に集約する価値は高い |
| E（演出）をおまけに | ✅ **支持**。Sanctuary の $19.99 は人間の鑑定で正当化されている。演出だけで月額を取る競合は確認できず。演出は束ねる側 |

**結論**: pro_candidates.md §4 の推奨骨格は競合分析で覆らない。むしろ「柱 3（Map）が最大の差別化」という
点が強化された。「Aether shaders を柱から降ろす」判断も支持される。

---

## 7. 残検証タスク（段階 B の続き）

本ドキュメントで答えが出ない、次にやること:

- [ ] **JP の月額サブスク占いアプリの実例を 2〜3 個深掘り**（ツール系で月額階層を持つアプリの転換率・価格帯）。§4 の「JP はサブスク不慣れ」仮説の精度を上げる
- [ ] **astrocartography.app の価格を取得**（今回 403 で取得不可）。AstroCarto のサブスク事例があるか確認
- [ ] **Linea の現状確認**（2026-03 メモリでは「バグ多い」。まだ生きているか）
- [ ] **消費型課金を併設する場合の UX 設計**（オーナー判断後）。ストア審査の説明含む
- [ ] **オーナーとの 8 論点ウォークスルー** — 本 §5 の暫定回答を叩き台に、候補を実際に削る
- [ ] 価格の最終決定（§5 #1：年額 $49.99 → $59.99 含む）

---

## 8. 出典（2026-05-14 調査）

- [Best Astrology Apps & Sites 2026 — Taroscoper](https://www.taroscoper.com/guides/best-astrology-apps-and-sites-compared)（403 で本文取得不可、検索サマリのみ）
- [CHANI App Review 2026 — Aurae](https://www.auraeastrology.com/blog/chani-app-review-2026-an-astrologers-honest-opinion)
- [The CHANI App](https://www.chani.com/app)
- [Co–Star — costarastrology.com](https://www.costarastrology.com/)
- [Co–Star paywall — Adapty](https://adapty.io/paywall-library/co-star-personalized-astrology/)
- [The Pattern — General information about Subscriptions](https://thepattern.zendesk.com/hc/en-us/articles/14045427454740-General-information-about-Subscriptions)
- [The Pattern App: Features, Pricing — Bustle](https://www.bustle.com/life/pattern-app-review-features-price)
- [Sanctuary Astrology App](https://shop.sanctuaryworld.co/pages/our-app)
- [Astrocartography - Pathfinder — App Store](https://apps.apple.com/us/app/astrocartography-pathfinder/id6744743546)
- [AstroCartography Chart Online — Astro-Seek](https://horoscopes.astro-seek.com/astrocartography-online-astro-map-relocation)
- [Labyrinthos Tarot App Review — Bustle](https://www.bustle.com/life/labyrinthos-tarot-reading-app-review)
- [Tarovent — AI Tarot Reading Online](https://www.tarovent.com/)
- [Lumi: AI Tarot & Horoscope — Google Play](https://play.google.com/store/apps/details?id=com.yobzh.tarot)
- [10 Best AI Astrology Apps & Websites 2026 — AstroNidan](https://astronidan.com/blog/10-best-ai-astrology-apps-websites-2026-free-paid-comparison/)（403 で本文取得不可、検索サマリのみ）
- [チャット占いアプリ『ステラ』完全版 — zired](https://zired.net/stella/)
- [占いアプリおすすめランキング2026 — マイベスト](https://my-best.com/6294)
- [おすすめ西洋占星術アプリまとめ — 星を研究する人](https://astro-study.net/entry/astrology_tool/recommend/01)
- [Astrodienst 無料ホロスコープ](https://www.astro.com/horoscopes/ja)
