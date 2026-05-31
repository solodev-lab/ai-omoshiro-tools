// Consultation Result — シェア機能 (part of consultation_result_screen.dart)
//
// シェアエクスポート (テキスト / 画像) を本体から分離。Pro 限定。

part of 'consultation_result_screen.dart';

extension _ConsultationResultShare on _ConsultationResultScreenState {
  String get _shareTheme => widget.request?.theme ?? widget.record?.theme ?? '';
  String get _shareMode => widget.request?.mode ?? widget.record?.mode ?? '';
  String get _shareScopeKind =>
      widget.request?.scope?.kind ?? widget.record?.scopeKind ?? 'world';
  String get _shareWhom =>
      widget.request?.withWhom ?? widget.record?.withWhom ?? '';
  String get _shareWish => widget.request?.wish ?? widget.record?.wish ?? '';

  List<ConsultationV2Candidate> get _shareCandidates =>
      _readings.map((r) => r.candidate).toList(growable: false);
  List<ConsultationEvidence> get _shareEvidences =>
      _readings.map((r) => r.evidence).toList(growable: false);

  Future<void> _openShareSheet() async {
    if (_readings.isEmpty || _sharing) return;

    // 2026-05-31: 相談結果のシェアを Free に戻した (オーナー指示)。Pro ゲート撤廃。
    final choice = await showModalBottomSheet<_ShareChoice>(
      context: context,
      backgroundColor: SolaraColors.celestialBlueLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: SolaraColors.glassBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.copy_outlined,
                    color: SolaraColors.solaraGold),
                title: const Text('テキストをコピー',
                    style: TextStyle(color: SolaraColors.textPrimary)),
                subtitle: const Text(
                  '相談結果を clipboard に整形してコピー',
                  style: TextStyle(
                      color: SolaraColors.textSecondary, fontSize: 11),
                ),
                onTap: () => Navigator.of(ctx).pop(_ShareChoice.text),
              ),
              ListTile(
                leading: const Icon(Icons.image_outlined,
                    color: SolaraColors.solaraGold),
                title: const Text('画像で共有',
                    style: TextStyle(color: SolaraColors.textPrimary)),
                subtitle: const Text(
                  '結果画面を PNG にして OS 標準シェアで共有',
                  style: TextStyle(
                      color: SolaraColors.textSecondary, fontSize: 11),
                ),
                onTap: () => Navigator.of(ctx).pop(_ShareChoice.image),
              ),
            ],
          ),
        ),
      ),
    );
    if (choice == null || !mounted) return;
    if (choice == _ShareChoice.text) {
      await _copyText();
    } else {
      await _shareImage();
    }
  }

  Future<void> _copyText() async {
    final first = _first;
    final text = formatConsultationAsText(
      theme: _shareTheme,
      mode: _shareMode,
      scopeKind: _shareScopeKind,
      withWhom: _shareWhom,
      wish: _shareWish,
      innerSeason: first?.innerSeason ?? '',
      intro: first?.intro ?? '',
      outro: first?.outro ?? '',
      candidates: _shareCandidates,
      evidences: _shareEvidences,
    );
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('テキストをコピーしました'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _shareImage() async {
    _setSharing(true);
    try {
      final caption = formatConsultationCaption(
        theme: _shareTheme,
        candidates: _shareCandidates,
      );
      await shareConsultationImage(
        boundaryKey: _shareBoundaryKey,
        shareText: caption,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('シェアに失敗しました: $e')),
      );
    } finally {
      if (mounted) _setSharing(false);
    }
  }
}
