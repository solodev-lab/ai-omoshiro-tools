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
/// レイアウト (Light面/Shadow面 切替):
///   上段: SOLARA / Your Title / ✦ 一言 (t144) ✦ / TitleEN
///   中央: ClassCard (mode=none、絵のみで完全表示)
///   下段: クラス名 JP/EN / ✦ クラステキスト ✦ / What is yours?
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

  /// 軸別グラデーション背景
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

      final titleForShare = _showShadow ? widget.titleShadowJP : widget.titleLightJP;
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
            ? const Center(child: Text('クラスデータがありません', style: TextStyle(color: Color(0xFFACACAC))))
            : Column(
                children: [
                  // ── プレビュー（実シェア画像と同じ構造） ──
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 9 / 16,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: RepaintBoundary(
                            key: _captureKey,
                            child: _buildShareImage(cls),
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
                            BoxShadow(color: _accentColor.withValues(alpha: 0.25), blurRadius: 24),
                          ],
                        ),
                        child: Center(
                          child: _sharing
                              ? const SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0A0A14)))
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

  /// シェア用画像の中身（縦長 9:16）
  Widget _buildShareImage(title_data.TitleClass cls) {
    // Light/Shadow 切替で表示する値
    final titleOneLine = _showShadow ? widget.titleShadowJP : widget.titleLightJP;
    final classText = _showShadow ? cls.shadowJP : cls.lightJP;
    final accent = _accentColor;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _bgGradient,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ══════ 上段: SOLARA + 一言 ══════
            Column(
              children: [
                Text(
                  'S O L A R A',
                  style: TextStyle(
                    color: accent,
                    fontSize: 13,
                    letterSpacing: 7,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _showShadow ? '— Shadow Title —' : '— Your Title —',
                  style: TextStyle(
                    color: accent.withValues(alpha: 0.55),
                    fontSize: 10,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 12),
                // 一言 (t144.light or t144.shadow)
                Text(
                  '✦ $titleOneLine ✦',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: accent,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                    letterSpacing: 1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.titleEN,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: accent.withValues(alpha: 0.6),
                    fontSize: 11,
                    letterSpacing: 2,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),

            // ══════ 中央: ClassCard (mode=none で絵だけ完全表示) ══════
            Flexible(
              child: ClassCard(
                classData: cls,
                width: 220,
                mode: ClassCardMode.none,
                showGlow: true,
              ),
            ),

            // ══════ 下段: クラス名 + クラステキスト ══════
            Column(
              children: [
                Text(
                  cls.nameJP,
                  style: const TextStyle(
                    color: Color(0xFFEAEAEA),
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  cls.nameEN,
                  style: const TextStyle(
                    color: Color(0x80EAEAEA),
                    fontSize: 11,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '✦ $classText ✦',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: accent.withValues(alpha: 0.85),
                    fontSize: 13,
                    height: 1.6,
                    fontStyle: _showShadow ? FontStyle.italic : FontStyle.normal,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                Text(
                  'What is yours?',
                  style: TextStyle(
                    color: accent.withValues(alpha: 0.4),
                    fontSize: 10,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
