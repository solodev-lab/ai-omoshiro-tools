import 'package:flutter/material.dart';

/// ============================================================
/// SolaraSafeText — Row/Column 内で overflow しない Text
///
/// 設計: feedback_text_overflow.md (2026-05-11 規約)
///   ・Row/Column 内の Text は必ず Flexible + maxLines + ellipsis でラップ
///   ・本ヘルパーで毎回書くボイラープレートを排除
///   ・全機種・全フォントサイズで RIGHT OVERFLOWED を出さない
///
/// 制約:
///   ・親が Row / Column / Flex でないと Flexible は使えない (Dart 警告)
///   ・直接の親が Flex 系であることを確認した上で使う
///   ・親が Container/SizedBox など Flex 系でない場合は通常 Text を使う
///
/// 使い方:
///   Row(children: [
///     Icon(Icons.place),
///     SolaraSafeText('引越しレイヤー — 35.71°N, 139.77°E'),
///     Icon(Icons.close),
///   ])
/// ============================================================

class SolaraSafeText extends StatelessWidget {
  /// 表示文字列
  final String text;

  /// テキストスタイル
  final TextStyle? style;

  /// 最大行数 (デフォルト 1 = 1 行省略)
  final int maxLines;

  /// テキスト整列
  final TextAlign? textAlign;

  /// overflow 動作 (デフォルト ellipsis)
  final TextOverflow overflow;

  /// flex 値 (1 = Expanded 相当、null = Flexible)
  /// 複数 SolaraSafeText を並べる場合、配分の重みを指定可。
  final int? flex;

  /// FlexFit (デフォルト loose、Expanded 相当にしたい場合は tight)
  final FlexFit fit;

  /// テキスト前後に padding (Row/Column のスペースを微調整)
  final EdgeInsetsGeometry? padding;

  const SolaraSafeText(
    this.text, {
    super.key,
    this.style,
    this.maxLines = 1,
    this.textAlign,
    this.overflow = TextOverflow.ellipsis,
    this.flex,
    this.fit = FlexFit.loose,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: true,
      textAlign: textAlign,
    );
    if (padding != null) {
      child = Padding(padding: padding!, child: child);
    }
    return Flexible(
      flex: flex ?? 1,
      fit: fit,
      child: child,
    );
  }
}
