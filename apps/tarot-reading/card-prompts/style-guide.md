# タロットカード画像生成 スタイルガイド

## 共通スタイルプロンプト（全78枚に適用）

```
Antique luxurious tarot card illustration, richly colored oil painting style with golden aged patina. Ornate gold baroque frame border with intricate scrollwork. Deep jewel tones (ruby red, sapphire blue, emerald green, amethyst purple) against warm ivory background. Slightly cracked gold leaf texture on the border. Classical Renaissance art composition. Card dimensions 2:3 ratio portrait orientation. No text, no numbers, no letters on the card. The illustration fills the entire card within the ornate gold frame. Human figures should have intentionally obscured and ambiguous facial features - like weathered old oil paintings where the face is visible in form but the expression is undefined and open to interpretation. No clear smiles, no clear emotions. The face should be impressionistic and slightly dissolved, so the viewer projects their own meaning onto the figure. The body posture and composition convey the card's meaning, not the facial expression.
```

## 顔の表現について（重要）
- **顔ははっきり描かない**。形・輪郭は分かるが、表情は曖昧にする
- 理由: タロットカードの人物は「感情が読めない」ことが重要
  - 愚者は笑っているようにも、無謀にも見える
  - 正位置でも逆位置でも解釈が変わるべき
  - 表情が明確だと、読者の直感を制限してしまう
- 手法: 古い油絵が経年劣化したように、顔の部分だけ印象派的に溶ける感じ
- 体のポーズ・構図・シンボルでカードの意味を伝える

## 画像生成ルール
1. 全カード共通のスタイルプロンプトを末尾に付ける
2. カード名・番号はアプリ側でオーバーレイ表示するため、画像には入れない
3. 生成サイズ: 512x768px（2:3比率）
4. ファイル名: `{id}_{英語名}.png`（例: `00_the_fool.png`）
