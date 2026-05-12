# Solara クラスカード生成

25クラスのファンタジーRPG風職業カード画像を生成する。

## 仕様

- **比率**: 2:3 縦長
- **フレーム**: 黒背景 + 金縁、軸別のアクセントカラー
  - power (赤): 深紅・燃える金
  - mind (青): 群青・銀
  - spirit (紫/白): 紫・白・象牙
  - shadow (黒/紫): 漆黒・濃紫
  - heart (金/桃): 金・薔薇色・桃色
- **絵の中身**: 自由配色（軸色は枠だけに適用）
- **テキスト**: カードに文字を入れない（Flutter側でオーバーレイ）

## 画風サンプル比較 (Knight)

`generate_sample_styles.py` で4画風サンプル生成。

- `knight_vermeer.png` — ヨハネス・フェルメール風（既存タロットと統一）
- `knight_mtg.png` — Magic: The Gathering 風
- `knight_hearthstone.png` — Hearthstone 風
- `knight_ff.png` — Final Fantasy 職業画風

## 実行方法

```bash
cd apps/solara/class-cards
python generate_sample_styles.py
```

- `.env` の `GEMINI_API_KEY` を使用（無料枠）
- モデル: `gemini-3.1-flash-image-preview` (Nanobanana2)
  - 503混雑時は `gemini-2.5-flash-image-preview` → `gemini-2.0-flash-preview-image-generation` にフォールバック
- 各カード 5〜30秒、合計約100秒〜数分

## 次のステップ

1. 4画風サンプルを比較してオーナーが画風確定
2. `generate_all_class_cards.py` 作成（25クラス分）
3. assets/class-cards/ に webp 配置 + pubspec.yaml 登録
4. Flutter ウィジェット `lib/widgets/class_card.dart` 実装
5. 用途4（診断儀式の演出）と用途5（招待状/紹介カード）に統合
