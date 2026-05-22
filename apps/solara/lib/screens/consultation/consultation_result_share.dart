// Consultation Result — シェア機能 (part of consultation_result_screen.dart)
//
// Phase 2-5 シェアエクスポート (テキスト / 画像) を本体から分離。Pro 限定。
// 本体 (consultation_result_screen.dart) が 500 行 (HARD) を超えたため切り出した。
// _ConsultationResultScreenState の private 状態 (_reading/_sharing/_shareBoundaryKey)
// に extension からアクセスする (同一ライブラリ part)。

part of 'consultation_result_screen.dart';

extension _ConsultationResultShare on _ConsultationResultScreenState {
  /// Phase 2-5: シェアシートを開く (テキスト / 画像 2 択)。
  /// Phase 2-6a: シェア機能は Pro 限定。Free はアップグレード案内のみ。
  Future<void> _openShareSheet() async {
    final reading = _reading;
    if (reading == null) return;
    if (_sharing) return;

    // Pro ゲート
    if (!ProStatus.instance.isPro) {
      await showProUnlockDialog(
        context,
        featureLabel: '相談結果のシェア',
        description: 'Stella の読みをテキスト/画像で書き出して、近しい人と共有できます。',
      );
      return;
    }

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
                leading: const Icon(
                  Icons.copy_outlined,
                  color: SolaraColors.solaraGold,
                ),
                title: const Text(
                  'テキストをコピー',
                  style: TextStyle(color: SolaraColors.textPrimary),
                ),
                subtitle: const Text(
                  '相談結果を clipboard に整形してコピー',
                  style: TextStyle(
                    color: SolaraColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                onTap: () => Navigator.of(ctx).pop(_ShareChoice.text),
              ),
              ListTile(
                leading: const Icon(
                  Icons.image_outlined,
                  color: SolaraColors.solaraGold,
                ),
                title: const Text(
                  '画像で共有',
                  style: TextStyle(color: SolaraColors.textPrimary),
                ),
                subtitle: const Text(
                  '結果画面を PNG にして OS 標準シェアで共有',
                  style: TextStyle(
                    color: SolaraColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                onTap: () => Navigator.of(ctx).pop(_ShareChoice.image),
              ),
            ],
          ),
        ),
      ),
    );
    if (choice == null) return;
    if (!mounted) return;
    if (choice == _ShareChoice.text) {
      await _copyText(reading);
    } else {
      await _shareImage(reading);
    }
  }

  Future<void> _copyText(ConsultationReading reading) async {
    final text = formatConsultationAsText(
      theme: widget.theme,
      mode: widget.mode,
      scope: widget.scope,
      freeText: widget.freeText,
      reading: reading,
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

  Future<void> _shareImage(ConsultationReading reading) async {
    _setSharing(true);
    try {
      final caption = formatConsultationCaption(
        theme: widget.theme,
        reading: reading,
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
