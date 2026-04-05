# Session Log

## 2026-03-17 セッション: 3枚引きStripe課金実装 + overall文字数増量

### 実施内容
- タロット占い全スプレッドの総合鑑定（overall）文字数を倍増
  - 1枚引き: 2-3文→4-6文, 3枚引き: 2文→4-6文, 5枚引き: 3-4文→6-8文
  - max_tokens: 800→1600に変更（2箇所）
- 3枚引き総合鑑定の100円Stripe課金機能を実装
  - worker.js: /api/generate で3枚引きのoverallをレスポンスから削除
  - worker.js: handleStripeCreateCheckout にthree-card対応（100円、success_three.html）
  - worker.js: handleStripeVerifySession にthree-card対応（overall専用プロンプト、max_tokens 400）
  - app.js: renderThreeCardResult でoverall部分を課金ボタンに変更
  - app.js: startThreeCardCheckout() 関数追加（localStorage保存→Stripe Checkout）
  - success_three.html: 新規作成（3枚引き決済完了ページ）
- コメントアウトでON/OFF切替可能な構造にした
- 5枚引き課金は引き続き無効（コメントアウト状態）
- worker.jsのデバッグ出力（debug: errText）を削除してデプロイ済み

### 発覚した問題
- Stripe APIキー無効エラー → 原因はStripeアカウント審査（本人確認＋セキュリティチェックリスト未提出）
- 5枚引きoverallが表示されない報告 → API側は正常動作確認済み（ブラウザキャッシュの可能性）

### Stripe審査対応
- オーナーが本人確認書類とセキュリティ対策措置状況申告書を提出済み
- 審査完了待ち（1-2営業日）

### 未解決・次のアクション
- Stripe審査完了後に3枚引き課金フローのE2Eテスト
- 5枚引きoverall表示問題の確認（Ctrl+Shift+Rでキャッシュクリア）
- 本番モード切替時にsk_live_キーの設定が必要

## 2026-03-17 セッション: タロットアプリPWA化

### 議論・決定事項
- AI履歴書添削アプリ（Phase 2）は弱いと判断 → 占い横展開（AI姓名判断、AI手相占い等）に方針変更
- アプリ化はPWA → TWAでGoogle Play公開（$25支払い済み）
- 課金方法: Google Play上ではStripe直接課金はポリシー違反リスク → 無料版（広告付き）で出す戦略
- 広告: AdSense広告を結果ページに自然配置（インタースティシャル型は規約違反リスク）
  - 1枚引き: 結果下部に広告1枠
  - 3枚引き: 鑑定結果後 + アドバイス後に広告2枠
- PWAモード（standalone）では5枚引き（有料）を非表示
- 免責文言変更:「エンタメ目的の占いです」→「占い結果を保証することはできません。重要な判断にはご自身の意思を優先してください。」

### 実装内容
- `apps/tarot-reading/manifest.json` 新規作成（PWA設定）
- `apps/tarot-reading/sw.js` 新規作成（Service Worker: キャッシュ戦略）
- `apps/tarot-reading/icons/` 新規作成（192x192, 512x512 PWAアイコン）
- `apps/tarot-reading/index.html` PWAタグ追加、免責文言変更、SW登録スクリプト
- `apps/tarot-reading/app.js` PWAモード検出で5枚引き非表示、AdSense広告枠自動挿入
- `apps/tarot-reading/style.css` 広告枠スタイル追加

### 動作確認
- Service Worker正常登録 ✅
- 1枚引き結果ページ表示・広告枠配置 ✅
- 免責文言変更反映 ✅
- コンソールエラーなし ✅

### 次のアクション
- GitHub Pagesにデプロイ（git push）
- assetlinks.json設定（TWA用、Google Play公開時）
- Google Play Console でTWAアプリ作成・公開
- AdSense審査通過後に広告コードの実際のslot IDを設定
- 占い横展開第1弾（AI姓名判断）の企画・開発

## 2026-03-17 セッション: PWAデプロイ＋修正対応

### 実施内容
- PWA変更をgit push（commit f229eee → GitHub Pages デプロイ完了）
- PWAモードでフッターリンク非表示対応
- プルトゥリフレッシュ無効化（html要素にoverscroll-behavior: none追加）
- コピーボタン → スクリーンショット保存ボタンに変更（html2canvas使用）
- 結果カードをPNG画像としてダウンロード可能に
- commit 977fc45 でデプロイ完了、動作確認OK

### 議論・方針確認
- ブランド名使用アプリ（マクドナルド非公式等）は商標権侵害リスク大 → やらない
- ログイン機能モジュール化（Firebase Auth）は可能だが、今は優先度低い
- 現段階はAdSense審査通過＋占い横展開で広告収益を積むことに集中

### 未対応・次のアクション
- AdSense審査通過待ち（広告枠は設置済み）
- 占い横展開第1弾の企画・開発
- TWA化（assetlinks.json設定 → Google Play提出）

## 2026-03-18 セッション: タロットv2 Phase 1 実装＋動作確認（続き）
- 前セッションのコンテキスト切れから再開
- 動作確認を実施:
  - 1枚引きフロー: 相談UI(Step1-4) → シャッフル → カード選択 → 分析中 → 結果表示 ✅
  - 2者択一フロー: 仕事>上司>2者択一 → 選択肢A/B入力 → 6枚V字配置シャッフル → 結果表示 ✅
  - 総合運: Step2(状況選択)スキップ → Step3直接表示 ✅
  - カードフリップアニメーション: 3D Y軸回転正常 ✅
  - 鑑定履歴: localStorage保存(2件) → 一覧表示 → 詳細表示 ✅
  - コンソールエラー: なし ✅
- API接続: ローカルワーカー未起動のため静的フォールバック使用（本番では正常動作予定）
- Phase 1 全5機能の実装・動作確認完了

## 2026-03-22 セッション: 名占（なうら）タイプ設計＋画像生成テスト

### 完了したこと
- ブランド名決定: **名占（なうら）**
- 1-9各数字のキーワード設定
- 総数×陰陽 18メインタイプ（性格・強み・弱みの詳細定義）
- 姓数×陰陽 18外面タイプ（社会での顔）
- 名数×陰陽 18内面タイプ（本当の自分）
- 総合二つ名を姓数×名数の81通りに拡張（守護カード寄りの解釈）
  - 修正: 5×7→疾風の女帝, 5×8→自由を統べる皇帝, 5×9→果てなき教皇
  - 修正: 1×6→渇望の戦車（6×1「愛を貫く戦車」との重複回避）
- カード画像生成スクリプト作成（generate_card.py）
  - Gemini 2.5 Flash Image（Nanobanana2相当）で動作確認済み
  - テスト画像「鏡映しの魔術師」生成成功
- 全タイプ定義をメモリに保存（project_naura_types.md）

### 未実装タスク（次セッション向け）
- [ ] types.jsに全データ（81二つ名＋外面18＋内面18）追加
- [ ] app.jsのロジック更新（総合二つ名を姓数×名数で決定）
- [ ] 数値内訳に文字変換テーブル表示追加
- [ ] 各鑑定テキストを50文字増量
- [ ] AdSense修正（非表示セクション内のpushを結果表示時に遅延実行）
- [ ] 81枚のカード画像生成

## 2026-03-22 セッション: 名占（なうら）未実装タスク5件完了

### 完了した作業
- カード画像UI統合: 81枚のPNGを結果画面に表示（card-images/{seiNum}_{meiNum}_{cardName}.png）
  - onerrorフォールバック（画像ロード失敗時は絵文字表示に切り替え）
  - CSS: border, box-shadow, drop-shadow付きで高級感ある表示
- 50音変換テーブル追加: details/summaryで折りたたみ表示
  - 行(0-9) × 段(1-5)の完全な対照表
  - 濁音・半濁音・小文字の変換ルール説明付き
- 鑑定テキスト50文字増量: 18タイプ × love/work/money = 54箇所すべて更新
- キャッシュバスティング更新: v=20260322b → v=20260322c

### 既に実装済みだったタスク（確認のみ）
- types.jsに全データ追加（18タイプ・81二つ名・18外面・18内面・4特別カード）
- app.jsロジック更新（姓数×名数で二つ名決定）
- AdSense修正（非表示セクションのpush遅延実行）

### 変更ファイル
- apps/naura/app.js: CARD_NAMES追加、cardImagePath生成、カード画像表示、変換テーブル
- apps/naura/types.js: love/work/money全54箇所のテキスト増量
- apps/naura/style.css: .card-image、.conversion-*のスタイル追加
- apps/naura/index.html: キャッシュバスティング更新

### メモリ更新
- project_naura_types.md: 未実装タスク→完了タスクに更新

## 2026-03-24 セッション: Solara Action画面モックアップ完成

### 作業内容
- 全体仕様.docx からAction astrocartography部分を読み込み
- タロット×アストロカートグラフィー連携の設計（案1+4ハイブリッド「Seed Alignment」に決定）
- ゲームVFX手法の調査・Webでの実現方法を整理
- モックアップ作成: `apps/solara/mockup/index.html`

### 確定したUI仕様
1. **カード演出**: 紫グロウの裏面 → 3Dフリップ → 縮小消滅
2. **メテオトレイル**: 光の点+グロウが上から中心へ降下
3. **着弾エフェクト**: AI生成動画（Kling AI）、mix-blend-mode: screen、メテオ60%地点で先行開始、3倍速再生
4. **収束パーティクル**: 金系4色（白金/金/暖白/暗金）、60個、全画面から中心へ
5. **セクター**: Leaflet geoポリゴン（15km半径）、ズーム/パン連動
6. **セクターエフェクト**: CSSグロウ（gold+cyan）+ Canvas geo-sparkles（5色）
7. **セクター輪郭**: 扇全体（弧+直線）に金+シアンのデュアルグロウ
8. **ステラメッセージ**: ガラスモーフィズムカード、フェードイン
9. **背景地図**: CartoDB Dark Matter タイル
10. **Globe⇔Local切替**: D3.js正距方位図法 ⇔ Leaflet、ズームレベル7で自動切替、Globeセクタータップ→flyTo
11. **カラーパレット**: 黒背景 / 金+暖白（blessed）/ 紫（shadow）/ 青灰（mid）
12. **中心地テスト**: ニューヨーク (40.7128, -74.006)

### ファイル構成
- `apps/solara/mockup/index.html` - メインモックアップ
- `apps/solara/mockup/effect_impact.mp4` - Kling AI生成の着弾エフェクト動画
- `apps/solara/mockup/effect_test.html` - エフェクト単体テスト用

### 次セッションでやること
- turf.jsによる大圏線ベースのセクター境界（案B）の実装
- メルカトル上での曲がり具合を目視確認
- ズームレベル別の表示切り替え（近距離=直線、遠距離=大圏線）
- REPLAYボタンで基盤レイヤーが消える問題の修正（要reload）


## 2026-03-24 セッション: turf.js大圏線セクター実装 + バグ修正2件

### 完了した作業
- turf.js v7 CDN追加、`geodesicArc()` ヘルパー関数を新設
- `createGeoSectors()` のflat-earth近似を `turf.destination()` による測地線計算に置換
- blessed セクターのグローポリゴンも同様に大圏線ベースに変更
- 弧のステップ数を20→24に増加（曲がりの滑らかさ向上）
- REPLAYボタンのバグ修正: `restart()` が `baseOverlays`（コンパス・方位線・惑星ライン）まで削除していた → Setで保護し、セクター/ブーストラインのみ削除するように修正
- Leaflet二重初期化エラー修正: `window.leafletMap` がDOM idの自動バインドでtruthy → `_leafletMapReady` フラグで回避

### 変更ファイル
- `apps/solara/mockup/index.html`

### 動作確認
- DRAW SEED CARD → カードフリップ → セクター描画: 正常 ✅
- REPLAY → 初期状態復帰（基盤レイヤー保持）: 正常 ✅
- コンソールエラー: なし ✅
- ネットワークエラー: なし ✅

### 次セッションでやること
- 高緯度（60°N等）での大圏線の曲がり具合を目視確認
- ズームレベル別の表示切り替え（近距離=直線、遠距離=大圏線）

## 2026-03-25 セッション: Solara Action画面モックアップ＋Astrocartography設計

### 実施内容
- 全体仕様.docxを読みAction astrocartography部分を分析
- タロット×Astrocartography連携アイデアを5案出し → 案1+4ハイブリッド「Seed Alignment」に決定
- Seed Alignment詳細設計:タロットの元素/惑星マッピング→レイヤー2再計算→地図演出
- モックアップ実装（apps/solara/mockup/index.html、約2000行）
  - タロットカード裏面 → TAP TO REVEAL → 3Dフリップ演出
  - メテオトレイル（光の降下線）→ 中心着弾
  - AI生成エフェクト動画（MP4、加算合成 mix-blend-mode:screen）
  - 収束パーティクル（金系4色、全画面→中心収束）
  - Leaflet地図（CartoDB Dark Matter暗色タイル）
  - 大圏線ベースの扇セクター（turf.js使用、地球規模で正確な方位）
  - 扇のマルチカラーグロウ（金→白→シアン）+ スパークル
  - 惑星ライン（大圏線、地球規模）+ 画面端追従の惑星マーカー
  - コンパスローズ（方角ラベル、ダッシュ線）全てLeafletレイヤー化
  - 地図検索機能（Nominatim API、セクター判定付き）
  - ステラメッセージ（ガラスモーフィズム）
  - 地図ラップ対応（1周スクロール可能）

### 重要な技術的発見・決定
1. D3.js正距方位図法は不要 → Leaflet+turf.js大圏線でメルカトル上に正確な方位を描画可能
2. 大圏線の方位はメルカトルの見た目と異なる（NYC→サンディエゴ=SW→実際は真西271°）→ Solaraの差別化ポイント
3. AI生成エフェクト素材: Kling AI（無料）で生成 → MP4を加算合成で地図に重ねる
4. カラーパレット確定: 背景#0A0A14、金#C9A84C、紫#6B5CE7、シアン系グロウ
5. 本番検索はGoogle Places API一択（月$200無料枠）

### 未実装・次のセッションでやること
1. 3重円（ネイタル/プログレス/トランジット）の全惑星を地図上にプロット（方式B）
2. レイヤーON/OFFコントロールパネル（扇、惑星ライン、3重円各層）
3. 3重円アライメント検出ロジック
4. ステラの統合メッセージ生成（カード+方位+称号の組み合わせ）
5. Stellar Sync（3重共鳴）特別演出

## 2026-03-25 セッション: Solara Action画面モックアップ クリーンリビルド
- MOCKUP_SPEC.md に基づき index.html をゼロから書き直し（2006行 → 約850行）
- デッドコード12個を削除: compassRadiusKm, geoPoint(), makeGeoCircle(), drawBlob(), drawPlanetLine(), drawActiveSectors(), drawSector(), trailParticles, spawnTrailParticle(), turf.js二重読み込み, D3空コメント, shockwaveCanvas
- SECTORS_DORMANT/SECTORS_ACTIVE定数も削除（drawActiveSectors専用だった）
- Canvas seedMarker描画削除（Leafletマーカーに統合済み）
- インパクトリング描画をanimate()内に移動
- 未使用CSSアニメーション(sectorBreathe, pulseGlow)削除
- 全機能維持: Leaflet地図、8方位線、方角ラベル、Seedカードフロー、メテオ、エフェクト動画、Geoセクター、惑星ライン(Liang-Barsky追従)、検索、Stellaメッセージ、省電力アニメーションループ
- プレビューサーバー: http://localhost:3003 で動作確認済み（エラーなし）
- 注意: このモックアップはSolaraアプリ本体作成時の参照用として保存

## 2026-03-27 セッション: ホロスコープ アスペクトパターン検出チューニング＆UI改善

### 実施内容
- パターン検出オーブを3°基準に確定（GT±3°, TSQ☍±3°/□±2.5°, Yod⚹±2.5°/⚻±1.2°）
  - 4°: アクティブ4個+予測5件（多すぎ）
  - 3°: アクティブ0個+予測4件（月1-2回でレア感あり）← 採用
  - 2°: ほぼ検出なし（厳しすぎ）
- 個人天体フィルタ追加（構成惑星に最低1つ個人天体必須）
- F欄チップ表示をシンプル化（パターン名+✔/⏳のみ、惑星アイコン・日数削除）
- UPCOMING PATTERNSパネルの惑星カラーをホロスコープに合わせた（N=金, T=青, P=紫）
- 全惑星にN/T/Pプレフィックス追加
- F欄枠の下側余白修正（:last-childのpadding-bottom:0を削除）
- F欄枠の下線点滅修正（border !importantで:last-child上書き）
- パターンポリゴンにF欄フィルタ適用（選択パターン以外のポリゴン非表示バグ修正）
- 仕様書（tarot_planet_mapping_design.md）にホロスコープ画面確定仕様を追記

### 確定事項
- パターン検出オーブ: 3°基準
- 予測期間: 60日
- approaching閾値: 96時間
- F欄チップ: シンプル表示
- ポリゴン描画: F欄フィルタ連動

### 未解決
- （なし — 地心変換は修正済みだった）

## 2026-03-28 セッション: ホロスコープ画面v2確定
- アスペクトリスト（N↔T / N↔P）を折りたたみ式コンテナ+タブ切替に変更
- モバイルUI: オーバーレイ方式を廃止 → Google Maps風ボトムシートに全面刷新
  - ドラッグ3段階（min/half/full）、5タブ（誕生/経過/天体/絞込/相）
  - チャートモード切替時にボトムシート内容を自動更新
- 「powered by astronomy-engine」サブタイトル削除（MIT、UI表示義務なし）
- 上部SOLARAロゴ削除 → チャート中央上にウォーターマーク透かし表示（14px, 透過18%）
- ASPECT FILTER + UPCOMING PATTERNSのタブ切替を廃止、Fパターン直下に予測統合表示
- 星座記号フォント色を#B49774（牡牛座色）に統一、枠背景は各星座固有色維持
- 星座タップでツールチップ表示（日本語名、上部は下に/下部は上に、2秒消滅）
- デスクトップSVGレスポンシブ対応（width:100%, height:auto）
- 仕様書 tarot_planet_mapping_design.md をv2として全面更新・確定
- メモリファイル project_horoscope_spec.md を最新仕様で更新

## 2026-03-29 セッション: ホロスコープv3リビルド＋仕様確定

### 問題発覚
- 前セッションでリビルドした軽量版(1184行)が保存されておらず、旧版(2030行/93KB)に戻っていた
- horoscope.htmlはgit未追跡(Untracked)だった

### 実施内容
- 旧版を `horoscope_v1_backup.html` にバックアップ
- 仕様v3に基づいて全面リビルド実施:
  - filter:blur / will-change / backdrop-filter:blur 全廃
  - SVG <animate> 要素全廃（ゴーストポリゴン含む）
  - アニメーション → CSS opacity パルスのみ
  - 3重円モード廃止 → 2重円2種（N+T / N+P）
  - ユーザーセレクタUI削除（デフォルト: はやしこうじ）
  - D/Eフィルタ削除 → A/B/Cの3段に
  - ORB_SETTINGS定数化（全アスペクト2°）
  - パターン検出・60日予測 → 生成ボタン時1回計算、キャッシュ保持
- 2重円デザイン修正: 中間リング削除、外側270/内側220の2円のみ（1重/2重共通）
- 仕様メモリ(project_horoscope_spec.md)をv3に更新

### 結果
- 新版: 1688行 / 77KB（旧版2030行/93KBから17%削減）
- 電池消費の主要因（blur/SVGアニメ/will-change）全て排除
- プレビュー動作確認済み（エラーなし、全モード正常）

### 注意点
- horoscope.htmlはまだgit未コミット
- 前セッションでの変更（リビルド後の微調整）は未反映（後で対応）

## 2026-03-30 セッション: Solara mockup仕様確定・ローカルホスト確認

### 実施内容（前セッションからの継続）
- **tarot.html**: カード引き済み時のカード表面復元機能を実装（checkTodayDraw改修）
- **tarot.html**: 「地図に反映する」ボタン追加（localStorage bridge経由でindex.htmlへ転送）
- **index.html**: カードドロー機能を削除、bridge経由の効果反映に切替
- **全3画面**: 下部ナビを統一（🧭MAP / 🌀HORO / ✨TAROT / 👤PROFILE）
- **horoscope.html**: git commit b791d1c のv3リビルド版に復元
- **MOCKUP_SPEC.md**: v2として全面書き直し・仕様確定
- ローカルホスト（port 3003）で動作確認OK

### 技術ポイント
- localStorage `solara_tarot_bridge` による画面間データ連携
- CSS 3D flipアニメーション状態のリロード時復元
- Suit判定のregex修正（WAND/CUP/SWORD/PENTACLE対応）

### 未解決・注意点
- なし。仕様確定済み。次のステップはオーナー判断待ち。

## 2026-03-30 セッション: ホロスコープ フィルターD/F削除＋ネイタル予測非表示
- フィルター「アスペクト個別」(D)と「パターン」(F)のHTML・JS完全削除
  - initAspectTypeChips, aspectInPattern, applyPatternHide, updatePatternChips関数削除
  - activeFiltersからaspectTypes/pattern除去
  - toggleFilter/toggleExclusive/resetFilters/buildPatternPolygons/buildAspectLinesHTML/renderAspectInfoから関連参照削除
- ネイタル（1重）モードで予測パネル（〇日後）非表示に
- アスペクト一覧パネル(ASPECTS)はネイタルでも表示維持
- 1688行→1604行（84行削減）
- コミット: daa3eea

## 2026-04-03 セッション: Horoハウスシステム+4アングル+レスポンシブ全画面化

### Horoscope画面 — Placidusハウス+4アングル
- **Placidusハウスシステム実装**: 反復的半弧3分割法（11H/12H=上半球、2H/3H=下半球）
- **Whole Signハウス追加**: ASCの星座0°起点で30°等分
- localStorage `solara_house_system` でPlacidus/Whole Sign切替
- 高緯度(|lat|>66°)はEqual Houseに自動フォールバック
- **ASC/DSC/IC/MC 4アングル**: 十字軸ライン(opacity 0.25, 1px, zodiacOuterまで延伸) + 4ラベル
- **アングルアスペクト**: 4アングル×10天体のアスペクト検出・描画、フィルターの惑星グループ制約を受けない
- **天体テーブル**: DSC(7H)/IC(4H)行追加
- **チャート標準配置**: ASC=左(9時)、MC=上(12時)、黄道反時計回り。数式 `toRad(asc - lon + 180)`
- **ORB設定**: localStorage `solara_orb_settings` からデフォルト値を上書き
- **House System表示**: SVG左下に「House System: Placidus」薄い白文字
- **ボトムシート修正**: bottom:70px(ナビバー上)、mini=52px、相タブの二重スクロール解消

### Sanctuary画面 — Astrology設定
- **House System設定**: Placidus / Whole Sign切替UI
- **Orb設定**: 6アスペクト個別スライダー(1°〜8°)、localStorage永続化

### Map画面 — アングルアスペクト方位ブースト
- ASC/MC/DSC/ICの黄経をTRIPLE.natalに追加（_asc/_mc/_dsc/_ic）
- アングルアスペクトを持つ天体にウェイトボーナス: ASC/DSC合=×1.5、MC/IC合=×1.3
- 惑星ライン描画からアングルキーをスキップ（`name.startsWith('_')` ガード）

### 全5画面レスポンシブ化
- **shared/styles.css**: .phoneを固定サイズ→100% + 100vh、.bottom-navをfixed化、.status-barをfixed化
- **index.html (Map)**: body centeringを削除、.phoneを100%×100vh、.bottom-navをfixed化
- **tarot.html**: .phone-frameを100%×100vh、.bottom-navをfixed化、.draw-panelにmax-width:500px
- **galaxy.html**: body centeringを削除、canvasサイズをwindow.innerWidth/Height動的化、背景グラデーション座標を動的化
- **sanctuary.html**: body centeringを削除、.main-areaをfixed化、.sanctuary-contentにmax-width:600px+margin:0 auto、canvasサイズ動的化

### 仕様書更新
- SPEC.md: Map/Horo/Sanctuary/localStorageキー一覧を更新
- project_horoscope_spec.md: v4に更新（ハウス・アングル・配置・モバイル）

### コミット
- 未コミット

## 2026-04-03 セッション2: 動作確認・修正（Map/Tarot/Galaxy）

### Map画面
- 運勢方位バーの幅制限: `.ff-bw`にwidth:120px固定、`.ff-label`をinline-flex化
- 検索結果ポップアップ改善:
  - タロット未引き時もaspectDataスコアでblessed/shadow判定（上位2=blessed、下位2=shadow）
  - 5カテゴリタブ（癒し/金運/恋愛/仕事/話す）追加、方位スコアに応じたアドバイス表示
  - fortuneデータもaspectDataから取得（seedBoost不要化）
- z-index整理: ナビバー=130、レイヤー/VP/運勢パネル=120-121、検索結果=110
- タロットブリッジ完全削除:
  - `seedBoost`/`calcSeedBoost()`/`drawnCard`/`applyBridge()`/`stellaMsg(card)`全削除
  - `seedBadge`要素削除
  - preseedメッセージ変更:「今日の方位を探索してみよう」
  - Stella表示はvibe-basedのみ（generateStellaMessage）

### Tarot画面
- BOOST DIRECTION（コンパス+方位ラベル+説明）セクション削除
- PLANET LINESセクション削除
- 「地図に反映する」ボタン（applyToMap）削除
- astronomy-engine読み込み削除（方角不要のため）
- PLANET_SYMBOLSのangle・DIRECTIONS定義削除
- getCardInfoから方位計算削除
- generateStellaMsgから方位参照削除（カード名+惑星名のみ、日付シード）
- 自宅/現在地/指定場所セレクター削除
- 今の気分スライダー削除
- 履歴詳細からboostDir/planets表示削除

### Galaxy画面
- スパイラル外周フェードアウト: `fade=1-Math.pow(i/len,1.5)`でopacity+lineWidth漸減
- ズームアウト制限: 最小0.48（初期値1.0から10段階）
- レイアウト修正:
  - `.screen.active`をposition:fixed
  - `.main-area`をposition:fixed、top:44px/bottom:80px
  - STELLA+デモボタンをmain-area末尾に移動（flex-shrink:0）
  - `.cycle-content`にoverflow:hidden

### 設計変更（重要）
- **タロットカードは方角に無関係** — カードの方位ブースト概念を完全廃止
- Map画面の方位スコアは100%アスペクトデータのみ
- カードはテーマ（キーワード・エレメント）のみ提供、方角は天文計算が担当

### コミット
- 未コミット

## 2026-04-04 セッション: プロフィールシステム + ビューポイント/登録地分離

### 完了したこと

#### Phase 1: SANCTUARY — プロフィール編集
- settings-itemをタップ→オーバーレイで編集可能に（氏名/生年月日/出生時刻/出生地/自宅）
- 出生地・自宅: Nominatimジオコーディングで座標自動取得
- `solara_profile` としてlocalStorage永続化
- 自宅保存時にVP slots + LOCATIONS両方に自動同期

#### Phase 2: MAP — ビューポイント/登録地の分離
- VPパネルに2タブUI追加: `📍 VIEWPOINT` / `🌐 LOCATIONS`
- **VIEWPOINT**: 方位の原点。タップ→rebuild()で扇・惑星ライン再計算
- **LOCATIONS**: HORO用登録地。タップ→地図パンのみ（扇は動かない）
- `solara_locations` 新規ストレージ + CRUD関数群
- ホームスロット（isHome=true）は削除不可・名称変更不可
- BIRTH定数をprofileから読み込み
- vpDel/vpMove/vpRename/vpChIconにホームガード追加

#### Phase 3: HOROSCOPE — プロフィール自動読込
- defaultUserをprofileから初期化（fallback: ハードコード値）
- 出生地・トランジット場所にセレクト追加（登録地から選択可能）
- トランジット/プログレスデフォルト = 自宅（home自動選択）
- getTransitLocation() fallback = home座標
- プロフィール未設定時に案内バナー表示
- 旧ハードコード3都市（東京/大阪/岐阜）を廃止

### 設計思想
- **ビューポイント** = 「ここから見た方角のエネルギー」を確認する場所（旅行先、職場等）
- **登録地** = HORO画面のトランジット/プログレス計算で使う場所
- **自宅** = 両方に自動登録。Sanctuaryで一元管理
- 方位スコアは惑星アスペクトベース（場所によって変わらない＝方位術的設計）

### コミット
- `be0dd3e` — GitHub push済み

## 2026-04-04 セッション: Sanctuary大幅リビルド + 仕様書整理
- **出生情報統合**: 氏名/生年月日/出生時刻/出生地を1つのオーバーレイ画面に統合
- **出生時刻不明対応**: チェックボックス追加。Horo画面でハウス/ASC/MC/角度アスペクト非表示、Sanctuaryでハウスシステム選択無効化
- **地図ピッカー**: 出生地・自宅登録にLeaflet地図UI追加（検索+クリック+逆ジオコーディング）
- **Aspect Orbs別画面化**: Major/Minor/Patternsの3カテゴリ、±ボタン+スライダー+デフォルトマーク+リセット
- **マイナーアスペクト追加**: セミセクスタイル(30°/1°)、セミスクエア(45°/1°)
- **パターンオーブ設定可能化**: localStorage参照、Yod Quincunx 1.5°に変更
- **Sanctuary Sleep削除**: OS標準機能と重複のため
- **Rate Solara削除**: リリース時に追加
- **Cosmic Pro価格変更**: $9.99/月、$49.99/年
- **仕様書整理**: SPEC.mdにオーブ値一元化、tarot_planet_mapping_design.mdの旧値削除、出生時刻不明仕様追加
- コミット: 58752c0 → GitHub push済み

## 2026-04-04 セッション: Solara称号システム（Title System）仕様策定

### 決定事項
- **称号構造**: メイン称号（ホロスコープ自動算出）+ サブタイトル（タロット診断）の二層構造
- **メイン称号**: 太陽星座(形容詞) × 月星座(名詞) = 144通り、人物系形容詞に統一
- **サブタイトル**: 25クラス（5軸×5クラス）、大アルカナとは無関係の独自分類
- **5軸**: Power/Mind/Spirit/Shadow/Heart
- **診断方法**: 大アルカナ3択×15ラウンド + 人物札4択×4スート = 計19問
- **Light/Shadow**: 両方カジュアルトーン（「〜すぎて」構文）
- **再診断**: 初回2回無料、以降Cosmic Pro限定月1回（新月連動）
- **Stella連携**: 25クラス×3フレーズ = 75個の呼びかけ
- **シェア**: Shadow面のみ表示、Instagram Stories向け縦長画像
- **UI**: Sanctuary画面にTITLE DIAGNOSISセクション追加

### ファイル変更
- `apps/solara/mockup/SPEC.md` に称号システム全仕様を追記
- localStorageキー6個追加（solara_title_*）

### 未実装タスク
- 15ラウンドの3枚提示組み合わせテーブル
- 愚者(0)・世界(21)の特別枠詳細
- 英語版Light/Shadow文・Stellaフレーズ
- シェアカードビジュアルデザイン
- 鍛造演出詳細アニメーション仕様

### 称号診断HTMLモックアップ実装完了
- sanctuary.htmlに称号診断システムを実装（約1400行追加）
- 28問のカード選択診断（数札9問→大アルカナ15問→人物札4問）
- 5軸スコアリング + ワイルドカード + 人物タイプ判定
- 太陽/月星座計算 → メイン称号144通り自動生成
- 25クラスのLight/Shadow表示（日英対応）
- 鍛造演出 + 段階的称号開封アニメーション
- localStorage永続化 + シェアカードCanvas生成
- 再診断制限（無料2回、以降Cosmic Pro）
- 動作確認済み: 全28問通過→スコアリング→称号生成→表示全て正常

### 称号文テンプレート方式変更
- メイン称号をカジュアル日本語テンプレート合成方式に変更
- 旧: 「風を駆ける灯台 — Trickster」（詩的・意味不明）
- 新: 「調子に乗って自由に表現しちゃったあとに反省会が欠かせないKnight」（共感・MBTI的）
- 太陽12パーツ（外面行動パターン）+ 月12パーツ（内面の裏の顔）+ 接続詞 + クラス名
- 144文の手作り調整は次セッションで実施予定
- SPEC.md更新済み

## 2026-04-06 セッション: Solara称号144通り完成
- title_workshop.md作成: 太陽12星座×12フレーズ + 月12星座×12フレーズ = 288素材
- title_144.md作成: 144通りの称号一言テキスト全完成
- 制作方式: 最初は太陽+月を別々に作って接続詞で繋ぐ方式 → 途中から「一文で人物像を描く」スタイルに進化
- オーナーが全144個を手動で最終編集・調整済み
- 矛盾チェック実施: 5箇所の明確な矛盾を修正（獅子×天秤、獅子×水瓶、蠍×水瓶、魚×天秤、魚×魚）
- メモリ更新: project_solara_title_system.md（144称号完成・次タスク更新）
- 次のタスク: sanctuary.htmlへの144個別テキスト組み込み
