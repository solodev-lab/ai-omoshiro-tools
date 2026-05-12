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
class ClassShareCardPage extends StatefulWidget {
  final String axis;
  final String court;
  final String titleJP;
  final String titleEN;
  final String lightJP;
  final String shadowJP;

  const ClassShareCardPage({
    super.key,
    required this.axis,
    required this.court,
    required this.titleJP,
    required this.titleEN,
    required this.lightJP,
    required this.shadowJP,
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

      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        text: '私の称号は「${widget.titleJP}」— ${_cls?.nameJP ?? ""}\n#Solara',
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
              style: const TextStyle(color: Color(0xFFF9D976)),
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
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF9D976), Color(0xFFE8A840)],
                          ),
                          boxShadow: const [BoxShadow(color: Color(0x40F9D976), blurRadius: 24)],
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
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ── 上部 ──
            Column(
              children: [
                const Text(
                  'S O L A R A',
                  style: TextStyle(
                    color: Color(0xFFF9D976),
                    fontSize: 14,
                    letterSpacing: 8,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '— Your Title —',
                  style: TextStyle(
                    color: Color(0x80F9D976),
                    fontSize: 11,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  widget.titleJP,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFF9D976),
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.titleEN,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0x99F9D976),
                    fontSize: 12,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),

            // ── ClassCard 中央 ──
            Flexible(
              child: ClassCard(
                classData: cls,
                width: 220,
                mode: _showShadow ? ClassCardMode.shadow : ClassCardMode.light,
                showGlow: true,
              ),
            ),

            // ── 下部 ──
            Column(
              children: [
                Text(
                  cls.nameJP,
                  style: const TextStyle(
                    color: Color(0xFFEAEAEA),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
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
                  _showShadow ? '✦ ${widget.shadowJP}' : '✦ ${widget.lightJP}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFFACACAC),
                    fontSize: 13,
                    height: 1.6,
                    fontStyle: _showShadow ? FontStyle.italic : FontStyle.normal,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                const Text(
                  'What is yours?',
                  style: TextStyle(
                    color: Color(0x66F9D976),
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
