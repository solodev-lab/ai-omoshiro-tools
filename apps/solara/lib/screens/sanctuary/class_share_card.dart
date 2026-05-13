import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../utils/title_data.dart' as title_data;
import '../../widgets/class_card.dart';

/// クラスカードのシェア用画面
///
/// 用途: 「I got X, what did you get?」拡散用の縦長画像生成。
/// Instagram Stories (9:16) 向け 1080×1920 でレンダリング、OS標準シェアシートで共有。
///
/// レイアウト方針 (固定化):
///   - 端末のフォントサイズ/表示サイズ設定の影響を受けないよう textScaler を 1.0 に固定
///   - すべての寸法を AspectRatio 内部の幅 (w) からの比率で算出
///   - 一言/クラステキストの行数で他要素の位置がズレないよう、各テキスト領域に
///     最大行数ぶんの SizedBox を確保 (短い場合は上部に空白が残る)
///   - 共通背景画像 share_card_bg.webp を軸別グラデーションの上に薄く重ねる
class ClassShareCardPage extends StatefulWidget {
  final String axis;
  final String court;
  final String titleLightJP; // 一言 Light (t144.light) 例: 「省察に長けた」
  final String titleShadowJP; // 一言 Shadow (t144.shadow) 例: 「謎キャラぶって脳内ダメ出し中な」
  final String titleEN; // 太陽×月 英語二つ名 例: 「Abyssal Lighthouse」

  const ClassShareCardPage({
    super.key,
    required this.axis,
    required this.court,
    required this.titleLightJP,
    required this.titleShadowJP,
    required this.titleEN,
  });

  @override
  State<ClassShareCardPage> createState() => _ClassShareCardPageState();
}

class _ClassShareCardPageState extends State<ClassShareCardPage> {
  final GlobalKey _captureKey = GlobalKey();
  bool _showShadow = false;
  bool _sharing = false;

  title_data.TitleClass? get _cls =>
      title_data.getClassByAxisCourt(widget.axis, widget.court);

  /// 軸別グラデーション背景 (share_card_bg.webp の下に敷く)
  List<Color> get _bgGradient {
    switch (widget.axis) {
      case 'power':
        return const [Color(0xFF2A0A12), Color(0xFF0A0408)];
      case 'mind':
        return const [Color(0xFF0A1530), Color(0xFF050818)];
      case 'spirit':
        return const [Color(0xFF1F0D38), Color(0xFF080414)];
      case 'shadow':
        return const [Color(0xFF1A0828), Color(0xFF050208)];
      case 'heart':
        return const [Color(0xFF2A0E1F), Color(0xFF0E0508)];
      default:
        return const [Color(0xFF0A1220), Color(0xFF020408)];
    }
  }

  /// Light/Shadow 面のアクセント色
  Color get _accentColor =>
      _showShadow ? const Color(0xFFC9A8E0) : const Color(0xFFF9D976);

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final boundary = _captureKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) throw 'capture target not found';

      // 高解像度キャプチャ（3.0x → ~1080px幅）
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw 'byteData null';

      final tmpDir = await getTemporaryDirectory();
      final file = await File('${tmpDir.path}/solara_title.png').create();
      await file.writeAsBytes(byteData.buffer.asUint8List());

      final titleForShare =
          _showShadow ? widget.titleShadowJP : widget.titleLightJP;
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        text: '私の称号は「$titleForShare」— ${_cls?.nameJP ?? ""}\n#Solara',
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('シェア失敗: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cls = _cls;

    return Scaffold(
      backgroundColor: const Color(0xFF020408),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFEAEAEA)),
        title: const Text('称号を共有', style: TextStyle(color: Color(0xFFEAEAEA))),
        actions: [
          TextButton(
            onPressed: () => setState(() => _showShadow = !_showShadow),
            child: Text(
              _showShadow ? 'LIGHT 面' : 'SHADOW 面',
              style: TextStyle(color: _accentColor),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: cls == null
            ? const Center(
                child: Text('クラスデータがありません',
                    style: TextStyle(color: Color(0xFFACACAC))))
            : Column(
                children: [
                  // ── プレビュー (実シェア画像と同じ構造) ──
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 9 / 16,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: RepaintBoundary(
                            key: _captureKey,
                            // 端末のフォント/表示サイズ設定を無視してレイアウト固定
                            child: MediaQuery(
                              data: MediaQuery.of(context).copyWith(
                                textScaler: const TextScaler.linear(1.0),
                              ),
                              child: _buildShareImage(cls),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // ── シェアボタン ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: GestureDetector(
                      onTap: _sharing ? null : _share,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            colors: _showShadow
                                ? const [Color(0xFFC9A8E0), Color(0xFF8C5BC0)]
                                : const [Color(0xFFF9D976), Color(0xFFE8A840)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _accentColor.withValues(alpha: 0.25),
                              blurRadius: 24,
                            ),
                          ],
                        ),
                        child: Center(
                          child: _sharing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF0A0A14)),
                                )
                              : const Text(
                                  '✦ 称号カードを共有する',
                                  style: TextStyle(
                                    color: Color(0xFF0A0A14),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// シェア用画像の中身 (縦長 9:16、完全固定レイアウト)
  Widget _buildShareImage(title_data.TitleClass cls) {
    final accent = _accentColor;
    final titleOneLine =
        _showShadow ? widget.titleShadowJP : widget.titleLightJP;
    final classText = _showShadow ? cls.shadowJP : cls.lightJP;

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        // ── 縦比率配分 (合計 1.0) ─────────────────────────
        // 上段 0.18, カードエリア 0.46, 下段 0.36
        final topH = h * 0.18;
        final cardAreaH = h * 0.46;
        final bottomH = h * 0.36;

        // ── フォントサイズ (幅比率で固定) ────────────────
        final fsHeader = w * 0.045;        // S O L A R A
        final fsSubtitle = w * 0.028;      // — Your Title —
        final fsTitleEN = w * 0.038;       // Abyssal Lighthouse
        final fsTitleOne = w * 0.065;      // 一言 (大、メイン)
        final fsClassJP = w * 0.090;       // 騎士
        final fsClassEN = w * 0.034;       // Knight
        final fsClassText = w * 0.040;     // クラステキスト

        // ── テキスト領域の固定高さ (最大行数 × 行送り) ───
        // 一言: 18文字超もあるので 2行ぶん確保
        final titleOneLineH = fsTitleOne * 1.4 * 2;
        // クラステキスト: 17文字超もあるので 2行ぶん確保
        final classTextH = fsClassText * 1.55 * 2;

        // ── カードサイズ (カードエリアにフィット、2:3 縦長) ──
        // カードエリア高さから逆算: cardWidth = cardAreaH / 1.5
        // ただし幅も超えないよう min を取る (左右余白 6%)
        final maxCardW = w * 0.74;
        final cardWidth = (cardAreaH / 1.5).clamp(80.0, maxCardW);

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _bgGradient,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // ── 共通背景画像 (汎用 Mucha 風装飾、薄く重ねる) ──
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.32,
                    child: Image.asset(
                      'assets/diagnosis-bg/share_card_bg.webp',
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ),

                // ── 中央コンテンツ (3段固定レイアウト) ──
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: w * 0.06,
                    vertical: w * 0.05,
                  ),
                  child: Column(
                    children: [
                      // ══════ 上段: SOLARA + サブ + TitleEN ══════
                      SizedBox(
                        height: topH,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'S O L A R A',
                              style: TextStyle(
                                color: accent,
                                fontSize: fsHeader,
                                letterSpacing: 7,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            SizedBox(height: w * 0.012),
                            Text(
                              _showShadow ? '— Shadow Title —' : '— Your Title —',
                              style: TextStyle(
                                color: accent.withValues(alpha: 0.55),
                                fontSize: fsSubtitle,
                                letterSpacing: 3,
                              ),
                            ),
                            SizedBox(height: w * 0.020),
                            Text(
                              widget.titleEN,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: accent.withValues(alpha: 0.7),
                                fontSize: fsTitleEN,
                                letterSpacing: 2,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // ══════ 中央: ClassCard (固定位置、mode=none) ══════
                      SizedBox(
                        height: cardAreaH,
                        child: Center(
                          child: ClassCard(
                            classData: cls,
                            width: cardWidth,
                            mode: ClassCardMode.none,
                            showGlow: true,
                          ),
                        ),
                      ),

                      // ══════ 下段: 一言 → クラス名 → クラステキスト ══════
                      SizedBox(
                        height: bottomH,
                        child: Column(
                          children: [
                            // 一言 (固定2行ぶんの領域、下寄せ)
                            SizedBox(
                              height: titleOneLineH,
                              child: Center(
                                child: Text(
                                  titleOneLine,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: accent,
                                    fontSize: fsTitleOne,
                                    fontWeight: FontWeight.w700,
                                    height: 1.4,
                                    letterSpacing: 1,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            SizedBox(height: w * 0.012),
                            // クラス名 JP
                            Text(
                              cls.nameJP,
                              style: TextStyle(
                                color: const Color(0xFFEAEAEA),
                                fontSize: fsClassJP,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 5,
                              ),
                            ),
                            SizedBox(height: w * 0.006),
                            Text(
                              cls.nameEN,
                              style: TextStyle(
                                color: const Color(0x80EAEAEA),
                                fontSize: fsClassEN,
                                letterSpacing: 3,
                              ),
                            ),
                            SizedBox(height: w * 0.020),
                            // クラステキスト (固定2行ぶんの領域、上寄せで安定)
                            SizedBox(
                              height: classTextH,
                              child: Center(
                                child: Text(
                                  classText,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: accent.withValues(alpha: 0.78),
                                    fontSize: fsClassText,
                                    height: 1.55,
                                    fontStyle: _showShadow
                                        ? FontStyle.italic
                                        : FontStyle.normal,
                                    letterSpacing: 0.5,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
