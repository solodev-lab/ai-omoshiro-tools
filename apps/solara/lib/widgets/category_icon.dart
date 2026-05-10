// ============================================================
// CategoryIcon — Solara カテゴリアイコン
//
// 2026-05-10: ベクター CustomPaint (Style D) → アンティーク神秘画 (Gemini 生成
// WebP) に置換。assets/menu_icons/{kind}.webp を Image.asset で表示。
//
// 7カテゴリ + 未開封 + 3メニュー (運勢方位/LOCATION/予報) で計 10 枚。
//   - all          : 4芒星 + 12方位tick (純金、汎用 / トップ未確定時)
//   - love (恋愛)   : ♀ Venus + 薔薇蔓 (dusty rose)
//   - money (豊かさ): ♃ Jupiter + 月桂樹 (muted amber)
//   - work (仕事)   : ♄ Saturn + 環 + masonic compass (slate-blue)
//   - healing (癒し): ☽ Moon + 8月相 + 麦穂 (silver-blue)
//   - communication : ☿ Mercury + 翼 + 蛇 (verdigris)
//
// Daily 未開封チップは `unsealed.webp` を別アセット名で使う (kind 不要)。
// 旧 _CategoryIconPainter (CustomPaint ベクター描画) は git history で復元可能。
// ============================================================
import 'package:flutter/material.dart';

import 'dominant_fortune_overlay.dart' show DominantFortuneKind;

enum CategoryIconKind { all, love, money, work, healing, communication }

extension DominantFortuneKindToCategoryIcon on DominantFortuneKind {
  CategoryIconKind toCategoryIcon() {
    switch (this) {
      case DominantFortuneKind.love:          return CategoryIconKind.love;
      case DominantFortuneKind.money:         return CategoryIconKind.money;
      case DominantFortuneKind.work:          return CategoryIconKind.work;
      case DominantFortuneKind.healing:       return CategoryIconKind.healing;
      case DominantFortuneKind.communication: return CategoryIconKind.communication;
    }
  }
}

extension _CategoryIconKindAsset on CategoryIconKind {
  String get assetName {
    switch (this) {
      case CategoryIconKind.all:           return 'all';
      case CategoryIconKind.love:          return 'love';
      case CategoryIconKind.money:         return 'money';
      case CategoryIconKind.work:          return 'work';
      case CategoryIconKind.healing:       return 'healing';
      case CategoryIconKind.communication: return 'communication';
    }
  }
}

/// カテゴリ別アンティークアイコン (Gemini 生成 WebP)。
///
/// [size] は描画領域の一辺ピクセル。アセットは 256×256 で生成済みなので、
/// size <= 256 では LANCZOS 縮小で十分シャープに表示される。
/// [color] は旧 API 互換で残しているが、画像は自前で色を持っているため
/// 渡しても無視される。`color` 指定が必要なら別途 ColorFilter を検討。
/// [strokeWidth] も同様に旧 API 互換のため残置 (画像なので意味を持たない)。
class CategoryIcon extends StatelessWidget {
  final CategoryIconKind kind;
  final double size;
  final Color? color;
  final double strokeWidth;

  const CategoryIcon({
    super.key,
    required this.kind,
    this.size = 24,
    this.color,
    this.strokeWidth = 1.6,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/menu_icons/${kind.assetName}.webp',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
  }
}
