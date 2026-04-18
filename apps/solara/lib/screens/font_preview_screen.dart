import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// フォント比較画面 — 候補フォント8種を Horo と同じコンテキストで並べて比較
/// ルート: 一時的に main.dart 等から push して確認
class FontPreviewScreen extends StatefulWidget {
  const FontPreviewScreen({super.key});
  @override
  State<FontPreviewScreen> createState() => _FontPreviewScreenState();
}

class _FontPreviewScreenState extends State<FontPreviewScreen> {
  static const _gold = Color(0xFFF6BD60);
  static const _goldDim = Color(0xFFC9A84C);
  static const _copper = Color(0xFFB8764A);
  static const _ivory = Color(0xFFE8E0D0);

  /// 各候補フォント。Google Fonts 対応
  static final List<_FontOption> _fonts = [
    _FontOption('Cinzel (現在)', (s) => GoogleFonts.cinzel(textStyle: s)),
    _FontOption('Cormorant Garamond (現在)', (s) => GoogleFonts.cormorantGaramond(textStyle: s)),
    _FontOption('Playfair Display', (s) => GoogleFonts.playfairDisplay(textStyle: s)),
    _FontOption('Fraunces', (s) => GoogleFonts.fraunces(textStyle: s)),
    _FontOption('Marcellus', (s) => GoogleFonts.marcellus(textStyle: s)),
    _FontOption('Italiana', (s) => GoogleFonts.italiana(textStyle: s)),
    _FontOption('EB Garamond', (s) => GoogleFonts.ebGaramond(textStyle: s)),
    _FontOption('Spectral', (s) => GoogleFonts.spectral(textStyle: s)),
    _FontOption('Cormorant', (s) => GoogleFonts.cormorant(textStyle: s)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      appBar: AppBar(
        backgroundColor: const Color(0xEB0C0C1A),
        title: const Text('Font Preview', style: TextStyle(color: _gold)),
        iconTheme: const IconThemeData(color: _gold),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _fonts.length,
        itemBuilder: (_, i) => _buildSample(_fonts[i]),
      ),
    );
  }

  Widget _buildSample(_FontOption f) {
    // Horo で使われる典型シーン4つを同じフォントで描画
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xF00C0C16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x33F6BD60)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Font name tag
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _gold.withAlpha(30),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(f.name, style: const TextStyle(
            color: _gold, fontSize: 11, fontWeight: FontWeight.w600,
            letterSpacing: 1.0)),
        ),
        const SizedBox(height: 14),

        // 1. Header style (BIRTH DATA)
        Text('✧ BIRTH DATA',
          style: f.apply(const TextStyle(
            fontSize: 13, color: _gold,
            letterSpacing: 2.5, fontWeight: FontWeight.w600))),
        const SizedBox(height: 8),

        // 2. Center medallion style (ASC / degree)
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Text('ASC', style: f.apply(TextStyle(
              fontSize: 18, color: _goldDim,
              letterSpacing: 2.0, fontWeight: FontWeight.w700))),
            const Text('♎', style: TextStyle(fontSize: 26, color: _gold)),
            Text('15.3°', style: f.apply(TextStyle(
              fontSize: 18, color: _goldDim,
              letterSpacing: 1.0, fontWeight: FontWeight.w700))),
          ])),
          const SizedBox(width: 20),
          // 3. Roman numerals (house numbers)
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('Ⅰ  Ⅱ  Ⅲ  Ⅳ', style: f.apply(const TextStyle(
              fontSize: 20, color: _goldDim,
              letterSpacing: 0.8, fontWeight: FontWeight.w600))),
            const SizedBox(height: 4),
            Text('Ⅴ  Ⅵ  Ⅶ  Ⅷ', style: f.apply(const TextStyle(
              fontSize: 20, color: _goldDim,
              letterSpacing: 0.8, fontWeight: FontWeight.w600))),
          ]),
        ]),
        const SizedBox(height: 14),

        // 4. Axis labels
        Text('A    D    M    I',
          style: f.apply(const TextStyle(
            fontSize: 22, color: _gold,
            letterSpacing: 3.0, fontWeight: FontWeight.w700))),
        const SizedBox(height: 14),

        // 5. Body text (占い文) — 通常体とイタリック
        Text(
          'トライン — 自然な流れで才能が発揮される。努力なく恩恵を受けやすい。',
          style: f.apply(const TextStyle(
            fontSize: 15, color: _ivory, height: 1.7))),
        const SizedBox(height: 8),
        Text(
          '感情と愛情が調和的に流れる。美的感覚が優れ、人間関係が円滑。',
          style: f.apply(const TextStyle(
            fontSize: 15, color: _ivory,
            fontStyle: FontStyle.italic, height: 1.7))),
        const SizedBox(height: 10),

        // 6. Date label (italic, copper)
        Text('1998 / 04 / 15',
          style: f.apply(const TextStyle(
            fontSize: 14, color: _copper,
            fontStyle: FontStyle.italic, letterSpacing: 1.0))),
      ]),
    );
  }
}

class _FontOption {
  final String name;
  final TextStyle Function(TextStyle base) apply;
  _FontOption(this.name, this.apply);
}
