# Solara アプリアイコン 生成プロンプト

> 別サイト(Midjourney / DALL·E / Leonardo / アイコン生成ツール等)で生成する用。
> 既存アイコン(タロットカード調)を差し替える新ブランドアイコン。
> ブランド色: ゴールド `#F9D976` / 最暗コズミック `#050208`〜`#080C14`。

---

## 技術仕様(これを必ず守る)

- **正方形 1:1、1024×1024px 以上**(iOS App Store は 1024×1024 必須、Android は後で縮小)。
- **背景は不透明・フルブリード**(角は丸めない。iOS/Android が自動でマスクする)。
- **モチーフは中央 70% 以内に収める**(上下左右に最低 15% の余白)。
  → Android のアダプティブアイコンは外周を円/角丸で削るため、端まで描くと欠ける。
- **文字・ロゴタイプ無し**(「Solara」の字は入れない。エンブレムのみ)。
- **48px でも判別できる**シンプルさ(細かいディテール・薄いグラデの飛びは厳禁)。
- **タロットカード/枠/額縁にしない**。カード型の外形を作らない。

---

## ✅ 第一推奨プロンプト(Stella = 8 芒星エンブレム)

```
App icon for a premium astrology app. A single luminous golden eight-pointed
star emblem, perfectly centered, with long sharp vertical and horizontal rays
and shorter diagonal rays, radiating a soft warm glow. Gold color #F9D976 with
a gentle inner-to-outer gradient and a delicate halo of light around it. Deep
cosmic background: near-black navy (#050208 at the edges) with a subtle radial
glow (#0A1326) behind the star. Minimal, elegant, modern flat icon style with
a soft premium sheen. Centered composition with generous empty margin around
the emblem. No text, no letters, no card frame, no border. Crisp and legible
at small sizes. 1:1 square, full-bleed dark background.
```

**ネガティブプロンプト(対応サイトのみ):**
```
text, letters, words, watermark, tarot card, card frame, border, rounded corner
frame, realistic photo, human figure, face, cluttered, busy details, low contrast,
white background
```

---

## 代替案

### 代替 A — Sol(太陽 + 軌道リング)
```
App icon for a premium astrology app. A minimal golden sun disc centered, with a
single thin elliptical orbit ring crossing it and one small accent star on the
ring. Gold #F9D976 on a deep cosmic near-black navy background (#050208) with a
faint radial glow. Modern flat premium icon style, soft glow, lots of margin.
No text, no card frame, full-bleed square, legible at small sizes.
```

### 代替 B — 同心の輝光(よりミニマル)
```
App icon: a single radiant golden star point at center emitting concentric soft
light rings on a deep near-black cosmic background. Gold #F9D976, luxurious,
minimal, lots of negative space, soft bloom. No text, no frame, full-bleed
square, high contrast, crisp at 48px.
```

---

## 生成後の使い方(オーナー作業 → 必要なら私が実装)

1. 1 枚お気に入りを 1024×1024(以上)で書き出す。
2. **Android アダプティブ用**に「エンブレムだけ背景透過(PNG)」版もあると綺麗
   (背景色 `#080C14` はアプリ側で持つため)。なくても 1 枚の正方形から私が切り出せる。
3. 私に渡してくれれば、各解像度(mipmap-hdpi〜xxxhdpi)+ アダプティブ
   (foreground/background)+ iOS 1024 へ自動スライスして組み込みます
   (flutter_launcher_icons or Android Image Asset)。

## 注意(コスト)
- 生成は **オーナーが別サイトで実施**(Gemini API 従量課金回避のため、私は生成しない)。
- 12 枚も要らない。**第一推奨を 4 枚ほど**出して 1 枚選ぶのが効率的。
