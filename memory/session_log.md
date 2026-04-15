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

## 2026-04-06 セッション: 称号シェアカード画像合成システム実装

### 実施内容
- **Nanobanana2 (fal.ai) で画像アセット49枚生成**
  - 背景画像 12枚（太陽星座別、9:16、2K）: `share-assets/backgrounds/`
  - クラスアイコン 25枚（1:1、1K）: `share-assets/class-icons/`
  - 星座シンボル 12枚（1:1、1K）: `share-assets/zodiac-symbols/`
  - 生成スクリプト: `apps/solara/mockup/generate_share_assets.py`

- **shareTitle() を画像合成版に書き換え**（sanctuary.html）
  - 背景画像（太陽星座）+ クラスアイコン + 星座シンボル + テキストオーバーレイ
  - Screen合成モードで黒背景アイコンを透過合成
  - フォールバック（画像ロード失敗時）も実装
  - 新規追加: ZODIAC_GLYPHS, ZODIAC_JP, CLASS_FILE, AXIS_COLORS, loadShareImage()

### 技術詳細
- Canvas 1080×1920 → PNG ダウンロード
- `globalCompositeOperation = 'screen'` で黒背景PNG → 透過合成
- Promise.all で4画像を並列ロード → renderShareCard() で合成
- drawCover() で背景をcover-fit描画

### アセットコスト
- fal.ai Nanobanana2: 約$5（49枚）

### 未対応
- Sanctuary画面内の称号表示にもアイコンを使う（現在はテキストのみ）

## 2026-04-06 セッション: 称号シェアカード + Star Atlas v2設計

### 称号シェアカード画像合成システム
- Nanobanana2 (fal.ai) で画像アセット49枚生成
  - 背景12枚（太陽星座別）: share-assets/backgrounds/
  - クラスアイコン25枚: share-assets/class-icons/
  - 星座シンボル12枚: share-assets/zodiac-symbols/
  - Gemini背景再生成1枚（gemini.png）
- shareTitle() を画像合成版に書き換え（sanctuary.html）
  - 背景 + アイコン + テキストオーバーレイをCanvas合成
  - screenブレンドで黒背景PNG透過合成
  - フォールバック描画も実装
- 画像最適化: 125MB → 3MB（WebP変換 + リサイズ）
  - 背景: 1080×1920 WebP q85
  - アイコン/シンボル: 256×256 WebP q85
  - 星座イラスト: 512×512 WebP q85

### Star Atlas v2設計（SPEC.md反映済み）
- **旧方式の問題発見**: スパイラル配置 + Catmull-Rom → 常に同じ斜め線
- **新方式: 3Dアナモルフィック**:
  - 3層構造（奥/中/手前）にドット配置
  - カメラ55°→0°回転で星座が「揃う」結晶化演出
  - アンカー（Major Arcana）のみ直線接続、Minor Arcanaは散在星
  - Golden Angle配置でユニークな形状を自動生成
- **星座イラスト背景**: 名詞ごとに白線画（Gemini直で$0生成）
  - テスト5枚生成済み（crown/arrow/wing/flame/chalice）
  - 星座ガイドブックの神話画オーバーレイ方式
- **レアリティシステム**: 数学的（Phase 1）→ リアル集計（Phase 2）
- **名前拡張**: 10形容詞 × 35名詞 = 350通り

### コスト
- fal.ai: 約$4.52（今後はGemini直で$0に移行）
- 今後の画像生成は全てGemini直接を使用

### 注意・未実装
- constellation_painter.dart: v2（アンカー/フィールド分離 + 直線）に要書き換え
- galaxy_screen.dart: 3D逆投影 + 結晶化カメラアニメに要書き換え
- galaxy.html: 同様にv2に要更新
- 残り星座イラスト30枚の生成（名詞拡張後）
- レアリティ計算ロジックの実装

## 2026-04-06 セッション続き: 星座名詞/形容詞/レアリティ確定

### 確定した星座システム
- **形容詞30個**: 10色系統 × 3明度（カラーコード付き）
- **名詞220個**: 209通常 + 11レア（各カテゴリ1レア枠）
- **組み合わせ**: 6,600通り
- **レアリティ**: 形容詞ティア × 名詞ティア の掛け算
  - Common(45%) / Uncommon(30%) / Rare(16%) / Legendary(7%) / Mythic(2%)
- **ファイル**: constellation_nouns.md に全リスト保存

### 11カテゴリ
天体(21) / 神話(26) / 動物(26) / 武器(21) / 王権(21) / 自然(26) / 建造物(19) / 象徴(21) / 楽器(13) / 身体(13) / 幾何(13)

### 星座イラスト生成
- generate_constellation_art.py 作成（Gemini直、$0）
- 4カテゴリ分のプロンプト定義済み（celestial/music/body/geometry = 60個）
- 残り7カテゴリのプロンプト追加が必要
- Gemini混雑でタイムアウト → 別時間に再実行予定

### 未完了タスク（次回セッション）
- 残り7カテゴリのプロンプト定義追加
- 全220枚の星座イラスト生成
- 既存の5枚（crown/arrow/wing/flame/chalice）は生成済み

## 2026-04-06 セッション最終: 星座システム規模縮小

### 変更内容
- 名詞: 220個 → 61個（50通常+11レア）に厳選
- 形容詞: 30個 → 20個（10色系統×2段階）に変更
- 組み合わせ: 6,600 → 1,220通り（月1で約100年分）
- 元の10個（Crown/Arrow/Veil等）は全て残した
- 重複なし保証を仕様に追加
- 既存の星座イラスト5枚削除（再生成予定）
- 将来アプデで名詞追加する拡張設計は維持

## 2026-04-07 セッション: Gemini AI占い動的生成 + Map UI改善
- Map: セクター扇色をFORTUNEカテゴリに連動（getSectorColor()追加、FORTUNE_COLORS定義）
- Map: レイヤー/VP/検索ボタンを右端プルタブ→左側縦並び40px丸ボタンに移動
- Map: レイヤーパネル・VPパネルをボタン右横に展開する形に変更
- Tarot: Gemini 2.5 Flash APIでカード固有鑑定文を動的生成（api_proxy.py経由）
- Horo星読み: lastAspectsFoundからアスペクトテキスト化→Gemini APIで5カテゴリ鑑定文生成
- api_proxy.py新規: /api/tarot-reading + /api/fortune-reading、ポート3915
- thinkingBudget:0 設定でFlashの思考トークン消費を防止（MAX_TOKENS問題解決）
- SPEC.md更新（AI生成実装済みマーク、セクター色仕様、ファイル構成にapi_proxy.py追加）
- コミット: f732316

## 2026-04-07 セッション追記: スクロール修正 + キャッシュ即表示
- Horo星読みタブ: スクロール壊れ修正（position:absolute+bottom:70px）、バナー非表示
- Tarot: キャッシュヒット時はタイプライター省略で即表示
- コミット: 23ac7bb (スクロール修正), 3d51e3d (タロットキャッシュ即表示)
- api_proxy.pyの最終ポート: 3915

## 2026-04-07 セッション: Solaraメモリ整理 + 全5画面HTMLリファクタリング

### メモリ整理
- 9つのSolara関連メモリファイルの重複・無駄を削除
- 方針: HTMLが仕様の正（実装と仕様が一体）、メモリには「あとでやること」「やってはいけないこと」「市場データ」のみ残す
- 削除: project_solara_orb_settings.md, project_solara_v7_mockup.md
- 大幅縮小: astrocarto(443→90行), horoscope_spec(107→20行), geo_sector(68→30行), galaxy_spec(78→30行), v7_integration(36→20行), tarot_cards(58→20行), title_system(65→20行)
- 合計: 約995行 → 約230行（77%削減）

### HTMLリファクタリング
- shared/astro-math.js新規作成（105行）: 天文計算関数・惑星データを共通化
- 5画面並列リファクタリング:

| ファイル | Before | After | 削減 | 主な変更 |
|---------|--------|-------|------|---------|
| index.html (MAP) | 1429 | 1426 | -3 | VP/LOC統合(SlotManager), shared移行, ASPECT_JP削除 |
| horoscope.html (HORO) | 2402 | 2348 | -54 | Fortune carousel統合, shared移行, デッドコード削除 |
| tarot.html (TAROT) | 1375 | 1407 | +32 | null-safety追加, const→var統一, フォーマット改善 |
| galaxy.html (GALAXY) | 1854 | 1671 | -183 | generateDemoCycle/nearestNeighborOrder削除, ヘルパー抽出 |
| sanctuary.html (SANCTUARY) | 2735 | 2468 | -267 | 旧edit overlay CSS/JS完全削除, PENT_AXIS削��� |
| **合計** | **10812** | **10442** | **-370** | |

- 全5画面でJSエラーなし確認済み
- デザイン・機能の変更なし

## 2026-04-07 セッション2: 称号診断改修 + 星座テンプレート改善

### 称号診断（sanctuary.html）
- R12/R14/R17/R24: 3枚→6枚に拡張（全5軸+Wildcard網羅）
- R14: 質問変更「深夜、語り明かすとしたら何を語りたい？」
- R19: 質問変更「あなたの魂が一番安らぐのは、どんな瞬間？」
- R20: 質問変更「未知の扉の向こうはどんな世界？」
- R22: 3枚→6枚に拡張
- R26: 質問修正「奇跡が目の前に降りた瞬間のあなたは誰？」
- R27: 質問変更「戦いの時期が迫る。あなたはどう剣を構える？」
- 診断カウント制限を一時無効化（テスト用）
- クラスアイコンを円形クリップ（四角い背景が見える問題修正）

### 星座テンプレート（galaxy.html）
- 17星座のテンプレート座標改善（griffin足4本、unicorn角右上、pegasus T字型、kraken触手6本、等）
- テンプレート点数10+の星座にアンカー数保証追加（makeDemoReadings minMajor対応）
- 壊れたlocalStorageサイクルのスキップ処理追加
- デバッグ表示追加（左上に緑文字、要削除）

### 注意
- galaxy.htmlにデバッグ表示が残っている（次セッションで削除）
- sanctuary.htmlの診断カウント制限がコメントアウトされている（本番前に復活必要）

## 2026-04-07 セッション: Solara全面デザインリフレッシュ
- **フォント変更**: Segoe UI/Lato → Cormorant Garamond(見出し) + DM Sans(本文)。全5画面+events.js(15箇所)統一
- **コスミック背景**: 3層構造 — Canvasネビュラアニメーション(星座別色変化) + 星座WebP画像(screen blend, opacity 0.25) + 多形状星パーティクル(十字/スパークル/ハロー/ゴールド/シアン)
- **SVGアイコン**: icons.js新規作成。ナビ5個+Sanctuary設定7個を絵文字→SVGに。GALAXYは渦巻き銀河デザイン
- **ナビバー統一**: index/horoscope/tarotのインラインCSS削除→shared/styles.cssに完全統一。高さ80px/z-index150に統一。グロー効果+アクティブドット追加
- **styles.cssリンク追加**: index.html, horoscope.html, tarot.htmlに追加（以前は未リンクだった）
- **Map画面**: cosmic-bg除外（地図が主役のため不要）
- コミット: 8237493 → GitHub push済み
- 注意: タロット大アルカナ22枚の絵文字→SVGは未対応（テキスト混在のため後回し）

## 2026-04-08 セッション: Solara全5画面HTML完全準拠 + 移植手順改善

### 作業内容
- **Sanctuary画面**: section-label(11px/700/1.8px)修正、Titleボタン分離(金色btn+枠線再診断btn)、pro-banner全値修正(22px/22px/gradient text)、needProfile 13px
- **Map画面(初回)**: settings構造化、Fortune Sheet(2段タブ+レジェンド)、Layer Panel(lp-構造)、センターマーカーHTML準拠
- **Map画面(4Step再修正)**: ff-bars 120px修正、layer-panel 100px修正、PLANET GROUP追加、fortune all色#E8E0D0修正、stella追加、sr-popup拡張(tabs+advice)、preseed追加、vp-btn+vp-panel追加、seed-badge追加
- **Horoscope画面**: chart-menu 4モード、bs-tabs 5タブ、birth/transit BSセクション、chart watermark、fortune nav buttons
- **Tarot画面**: Stella msg追加、History全面書換(element色border、expanded detail、sync section)
- **Galaxy画面**: 背景色修正、GALAXYヘッダー削除、day/moon badge縦並び、stella bubble構造、dot-popup/Star Atlas/Replay全修正

### 移植手順の改善
- **問題**: Agent要約に頼り、body要素を精読せず、照合もせずに書いた結果、Map画面で大量の漏れ
- **原因分析**: (1)Agent要約依存 (2)CSS先読みでbody省略 (3)書いた後の照合なし (4)複合ファイルの読み方が甘い (5)速度優先で精度犠牲
- **対策実施**: 
  - `feedback_html_porting_method.md` に4Step手順を記録
  - `CLAUDE.md` に移植必須手順を追記(移植完了後に削除予定)
  - Map画面で4Step(要素一覧ファイル→Todo→実装→照合)を厳守して再修正

### 未対応(演出系・JS Canvas依存)
- gray-veil, particleCanvas, screen-flash, effect-video, rest-overlay, replay button, cta button
- これらはCanvas/Video APIに依存しており、Flutter側ではCustomPainter/Rive等で別途実装が必要

## 2026-04-09 セッション: Map/Horo Flutter移植 + HTML整理整頓

### 実施内容
- **Map画面 Flutter修正（HTML準拠）**
  - タイルレイヤー: dark_all+labels 2層化、ColorFilterでbrightness/contrast/saturate適用
  - コンパスライン: 16方向→8方向、dashArray対応
  - 方位ラベル: N,NE,E等を3距離に配置
  - センターマーカー→VP Pin: ドラッグ可能ゴールドグラデーション丸(20px)
  - セクター: 16方向2タイプ→8方向3タイプ(blessed/mid/shadow)
  - Fortune Sheet: マルチセグメントバー(4色)、tick marks、RawScrollbar
  - Preseed: 3状態遷移(center→bottom→hidden)、浮遊アニメ
  - Stella: 上部右側に移動、最小化機能、AnimatedSwitcher
  - Rest Overlay: 「星が静か」モーダル追加
  - ズームボタン(+/-)追加
  - Fortune pull tab位置修正(bottom:80)

- **Horo画面 Flutter修正**
  - Astrology/Today Viewモード追加（全5カテゴリFortuneカード表示）
  - Bottom Sheetに「☆ 運勢」タブ追加
  - チャートサイズをレスポンシブ化(200-400px)
  - HoroscopeScreenState公開化→タブ切替時にプロフィール再読み込み

- **Sanctuary画面修正**
  - 生年月日の自動フォーマット(_DateSlashFormatter: 数字入力→YYYY/MM/DD自動変換)

- **HTML整理整頓**
  - Map (index.html): 1422行→2625行、CSS展開+16セクション、JS 16セクション
  - Horo (horoscope.html): 2335行→2929行、CSS展開+12セクション、JS 16セクション
  - バックアップ: index_before_cleanup.html, horoscope_before_cleanup.html

- **main.dart修正**
  - GlobalKeyでHoroscopeScreenのloadProfile()をタブ切替時に呼び出し

### 参照HTMLの修正
- Map画面: index_stable_v1.html(古い)→index.html(最新)に正しく切替

### 未解決・次のアクション
- Horo画面のAspect Filterボタン動作不良（元のHTMLでも同様に壊れている既存バグ）
- パーティクル・流星エフェクト: オーナー指示により実装しない
- 他の画面(Tarot/Galaxy/Sanctuary)のHTML整理・Flutter移植は次セッション

## 2026-04-09 セッション: Tarot/Galaxy/Sanctuary HTML整理整頓 + Flutter移植（全3画面）

### HTML整理整頓（3画面）
- **tarot.html**: CSS 15セクション + JS 12セクション番号付き`========`ブロックに統一。プロパティ展開、keyframe集約
- **galaxy.html**: CSS 9セクション + JS 22セクション番号付き統一。`@keyframes fadeIn`バグ修正（未定義だった）、DOM構造コメント追加
- **sanctuary.html**: CSS 13セクション + JS 11セクション番号付き統一。`tdParticleIn`をJS動的注入→CSS定義に移動（バグ修正）、keyframe全6個集約

### Flutter移植 — Tarot (observe_screen.dart)
- AnimatedSwitcher → 真の3Dフリップ（Matrix4.rotateY + perspective 1/800）
- カード裏: corners装飾 + ✦星4個 + cardPulseアニメーション（opacity 0.5↔0.8, scale 1↔1.05）
- Stellaメッセージ: 固定1テンプレート → 4テンプレート+日付seed選択
- element表示: 英語 → 日本語「🔥 火 · MAJOR」+ planet色付きシンボル + element色ボーダー
- Synchronicity: プレースホルダ → 編集可能TextField + "saved"表示 + 自動保存
- 履歴クリア: 即削除 → 確認AlertDialog
- DailyReading: stellaMsg/synchronicityフィールド追加

### Flutter移植 — Galaxy (galaxy_screen.dart + constellation_painter.dart)
- constellation_namer.dart: NOUN_TEMPLATES(61座標パターン) + NOUN_SHAPES(61接続タイプ) + ADJ_COLORS(20色) + MST(Prim) + buildEdges追加
- galaxy_cycle.dart: adjIdx/nounIdxフィールド追加
- constellation_painter.dart: nearest-neighbor → MST+shape接続に全面改修、ADJ_COLOR色適用
- galaxy_screen.dart: テンプレート配置(Major)、Star Atlasカード色グラデーション+★rarity+nameJP+メタ情報

### Flutter移植 — Sanctuary (sanctuary_screen.dart)
- Home Info Editor: _HomeEditorPage追加（Nominatim検索+緯度経度保存）
- SolaraProfile: homeName/homeLat/homeLngフィールド追加
- Pattern Orbs: OrbOverlayにPATTERNSセクション追加（Grand Trine/T-Square/Yod 計5個）
- Title Diagnosis: 7問テキスト → 28問カードemoji選択（3パート: Minor1-9/Major10-24/Court25-28）
- パート遷移+Forging+Reveal: トランジション画面、光球パルス、6段階アニメーション
- 称号persistence: SharedPreferences保存・復元

### コミット
- `65d3519` main → GitHub push済み
- 11ファイル変更、+3,283行 / -1,546行

## 2026-04-10 セッション: Map Task 4/5 + 3画面照合開始

### Task 4: 天体ライン描画（完了）
- 新規: map_planet_lines.dart — natal/progressed/transit の天体ラインをPolyline描画
  - `_geodesicLine()`: Distance().offset()で大圏線50ポイント生成（20000km）
  - `buildPlanetLineData()`: ChartResultから3レイヤー×10天体=最大30本のライン生成
  - `buildPlanetPolylines()`: レイヤー/惑星グループ/カテゴリフィルター連動
  - `buildPlanetSymbols()`: 各ラインの途中にシンボルマーカー配置
- map_constants.dart: ChartLineStyle, PlanetMeta, planetGroups, fortunePlanets 追加
  - CHART_STYLE: natal(#E8E0D0,solid,w2,o0.5), progressed(#C9A84C,dash8 6,w1.8,o0.45), transit(#00D4FF,dash3 6,w1.8,o0.45)
- map_screen.dart: _planetLines保持、_rebuild()で中心変更時に再構築

### Task 5: VP Panelスロット管理（完了）
- map_vp_panel.dart: フルリライト
  - SlotManager: SharedPreferencesでVP/LOCスロット永続化（max5件）
  - VPSlot: name/lat/lng/icon/isHome モデル
  - syncHome(): プロフィールのホーム地点を先頭スロットに同期
  - saveCurrentLocation(): Nominatim reverse geocodingで地名自動取得
  - CRUD: move/rename/delete/changeIcon、アイコンピッカー32種
  - 名称変更ダイアログ（AlertDialog）
  - GPS現在地移動は仮実装（geolocatorパッケージ未導入）

### Tarot画面照合結果
- observe_screen.dart(976行) vs tarot.html(1561行) を全行照合
- **結果: HTML準拠で完璧に実装済み**
  - inner-tab-nav, card-scene, 3D flip, card-back/front, stella-msg, reading-panel, history全要素のCSS値が一致
  - パーティクルエフェクトのみ省略（Canvas演出、機能差分なし）
  - location-selector, mood-slider, result-panel, apply-btn → HTMLにもDOM不存在（CSS定義のみ）

### 進行中
- Galaxy画面・Sanctuary画面のHTML要素一覧をバックグラウンドで作成中
- 次: 各画面のFlutterとの差分特定→修正

### Galaxy画面修正（追加分）
- Golden Angle二重レイヤー実装（cycle_spiral_painter.dart全面書き直し）
  - Layer 1: Ghost path（セグメントフェード付き）
  - Layer 2: Spiral anchor dots（全日アンカー）
  - Layer 3: GA位置の実ドット（projectGA3D、55°アナモルフィック投影）
  - Connection threads（spiral→GA破線接続）
  - mulberry32 PRNG で z-jitter
- 名詞リスト12個HTML準拠に修正（EN/JP両方）
- Grid maxCrossAxisExtent 200→160px
- CurrentDay金色リング追加
- 星座アートイメージ61枚をassets/constellation-art/にコピー
  - ConstellationPainter + MiniConstellationPainter にartImage/flipXパラメータ追加
  - screen blend + 35% opacity で描画
  - galaxy_screen.dart にプリロード機能追加

### Sanctuary画面修正
- TITLE_144テーブル（144エントリ）をtitle_data.dartに追加（HTMLから正確コピー）
- SUN_ADJ（12星座外面形容詞）+ MOON_NOUN（12星座内面名詞）追加
- getSunSign/getMoonSign関数追加（HTML準拠の星座計算）
- TITLE_CLASSES テーブル追加（5軸×5宮廷=25クラス）
- computeResults: determineFinalAxis（tiebreak付き）+ determineCourt（Part3 court集計）+ wildcard処理 + TITLE_144参照
- TD_ROUNDS Part3: axis→court属性に修正、質問をHTML準拠に変更
- Orb/House設定永続化（SharedPreferences）
- Home→VP同期（solara_vp_slots/solara_locations先頭スロット同期）
- saveBirthInfo時の称号自動更新（星座変更検知→TITLE_144再参照）

### メモリ更新
- feedback_html_precision.md: 「1セッション1画面」制約を「Opus 4.6 1Mでは不要」に修正

### ビルド状況
- flutter analyze: error/warningゼロ（全プロジェクト）

## 2026-04-14 セッション: Solara Star Atlas画面 星座絵精緻化

### 星座テンプレート修正 (constellation_namer.dart + galaxy.html)
- Crux(57): 円+十字 → 十字のみ9点、shape 'loop'→'open'
- Mobius(60): 楕円 → ∞軌跡12点、新shape 'infinity' を buildEdges に追加
- Prism(58): 6点 → 10点プリズム+光線、shape 'closed'→'open'
- Bow(16): 弓向き → 時計回り90°に合わせて三角形頂点左へ反転
- Leviathan(18): 6点 → 12点C字型（右開口）
- Excalibur(24): 十字鍔を下部(.5,.75)に、shape 'linear'→'open'
- Harp(48): 6点 → 10点（左柱+中央縦線+右頂点V型）
- Lyre(50): 10点 → 13点（縦弦3本×3段）、shape 'closed'→'open'

### 星座絵画像 (assets/constellation-art/)
- 白枠検出・除去 10画像: chalice/arrow/griffin/anchor/wing/serpent/unicorn/sword/jewel/mirror
- bow.webp を時計回り90度回転（弦=右、本体=左）
- 元画像を assets/constellation-art-backup/ に保存
- tools/ に画像処理Pythonスクリプト5個追加: detect_white_border.py, fix_white_borders.py, rotate_bow.py, check_black_level.py, show_border.py

### 星座絵描画方式改善 (constellation_painter.dart)
- ColorFilter.matrix(輝度→alpha)で黒背景を完全透明化、BlendMode.screen廃止
- glow色を属性色→白ベースに変更（暗いSilent/Abyssal等でも星・線が見える）
- glow濃度UP: 線glow α0.4→0.7、anchor星glow α0.55→0.9
- MiniConstellationPainter のサイズ強化: anchor glow半径5→9, 線太さ1.5→2.5

### Star Atlasカードパネル (galaxy_star_atlas.dart)
- パネル色を属性色→lightAdj (Color.lerp白ブレンド50%)で明度統一
- 背景α 0.08/0.03、枠α 0.3（ほぼクリアで星座絵を見やすく）

### Star Atlas帯問題（未解決・次セッション引継）
- childAspectRatio 0.62→0.775 変更時に「ボトムナビ上の横長矩形」発生
- 検証結果: nebula/boxShadow/cardBorder/cardGradient いずれも無関係
- GalaxyStarAtlasTab 空にすると消える → GridView/中身が原因
- childAspectRatio を0.62に戻しても帯は残る → 帯は childAspect 変更と独立した別要因
- 帯の原因特定は次セッションで継続
- 帯問題発生前の健全な状態に全コードを巻き戻し済み

### ファイル構造
- galaxy画面 5ファイル分割は維持: galaxy_screen.dart / galaxy_constellation_builder.dart / galaxy_star_atlas.dart / galaxy_replay_overlay.dart / widgets/constellation_painter.dart


## 2026-04-15 セッション: Solara Timezone C案 + Fortune API (Gemini) + CF Worker本番デプロイ

### 追加/変更ファイル
- **Worker (新規)**:
  - `apps/solara/worker/src/tzlookup.js` — 緯度経度→IANA TZ名 (bounding-box heuristic)
  - `apps/solara/worker/src/fortune.js` — Gemini 2.5 Flash (→2.0 fallback) 占い文生成、503/429リトライ、スコア計算 (aspects×quality加重)
- **Worker (修正)**:
  - `apps/solara/worker/src/index.js` — `/tz`, `/fortune` エンドポイント追加
  - `apps/solara/worker/src/astro.js` — `makeUTCDateFromTzName` (Intl DST対応)、computeChart/Predictions が `birthTzName` optional 受付
  - `apps/solara/worker/wrangler.toml` — custom_domain route、workers_dev = true
- **Flutter (新規)**:
  - `lib/utils/solara_api.dart` — `fetchTimezoneName()` (/tz呼出)
  - `lib/utils/fortune_api.dart` — `fetchFortune()` + `computeFortuneScore()` + `FortuneReading` モデル
- **Flutter (修正)**:
  - `lib/utils/solara_storage.dart` — `SolaraProfile.birthTzName` 追加 (null許容、copyWith付き、後方互換)
  - `lib/screens/sanctuary/sanctuary_profile_editor.dart` — 出生地選択時に `/tz` 自動呼出、UIにTZ名表示
  - `lib/screens/map/map_astro.dart` — `fetchChart` に `birthTzName` 優先送信
  - `lib/screens/map_screen.dart` — profile.birthTzName を fetchChart に渡す
  - `lib/screens/horoscope_screen.dart` — `_loadFortunes()` (5カテゴリ並列、日次キャッシュ、loading/error状態)
  - `lib/screens/horoscope/horo_fortune_cards.dart` — HoroAstrologyView に `fortunes/fortuneLoading/fortuneError/onRetry` パラメータ、mockデータ→API結果表示、スコアバッジ、スケルトン、再試行ボタン

### デプロイ
- **Cloudflare Worker**: `https://solara-api.solodev-lab.com` (custom domain) 本番稼働
  - fallback: `https://solara-api.kojifo369.workers.dev`
  - `GEMINI_API_KEY` wrangler secret put 完了
  - `/health`, `/tz`, `/astro/events`, `/fortune` 全エンドポイント疎通確認済み
- **wrangler.toml**: `routes = [{pattern: "solara-api.solodev-lab.com", custom_domain: true}]`
  - 初回 `routes pattern/zone_name` 形式ではDNS自動作成されず → `custom_domain = true` で自動発行

### APIキー管理確認
- `.env` は `.gitignore` 登録済み、Git履歴にコミットなし
- `GEMINI_API_KEY` は Cloudflare 暗号化シークレットストアのみ、コード/設定に平文なし
- `git ls-files | grep "AIzaSy"` → ヒット0件

### 仕様書更新
- `apps/solara/docs/architecture.md` — CF Worker本番稼働セクション追加、全エンドポイント表
- `apps/solara/mockup/SPEC.md` — Fortune API仕様・TZ C案処理フロー追記

### 学び・注意点
- `routes` で DNS 自動作成するには `custom_domain = true` が必要 (`zone_name` 形式は手動DNS設定必要)
- Gemini JSON mode の `maxOutputTokens: 1024` はJSON途中切断のリスク → `2048` に引き上げ
- Windows PC の負の DNS キャッシュ (NXDOMAIN) は `ipconfig /flushdns` でも ISP/ルーターキャッシュが残る → ブラウザDoH or 待つ
- Horoscope のパターン検出UI (GT/TSQ/Yod) は既に Flutter 側で完全実装済み (HoroPredictionPanel + HoroAstrologyView + ChartPainter)、今回は Fortune 文字生成のみが残タスクだった
