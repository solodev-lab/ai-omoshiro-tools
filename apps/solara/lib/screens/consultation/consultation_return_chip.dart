import 'package:flutter/material.dart';

import '../../theme/solara_colors.dart';
import '../../utils/consultation_return.dart';
import 'consultation_result_screen.dart';

/// Map 下部 (4 チップバー = MapMenuChips の直上) に出す「← 相談結果に戻る」チップ。
///
/// [ConsultationReturn] に pending がある間だけ表示。タップで live 相談結果を
/// fetch せず再表示し (クレジット非消費)、✕ で破棄する。Map タブ専用 (配置は
/// map_screen が行う)。Map 以外へ移動 / 新規相談開始時は ConsultationReturn 側で
/// clear されるため、ここは pending の有無を listen するだけ。
class ConsultationReturnChip extends StatelessWidget {
  const ConsultationReturnChip({super.key});

  void _onReturn(BuildContext context) {
    final state = ConsultationReturn.instance.take();
    if (state == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConsultationResultScreen(
          request: state.request,
          scopeDetail: state.scopeDetail,
          resumeReadings: state.readings,
          resumeAvoid: state.avoid,
          resumeSavedAt: state.recordSavedAt,
          resumePageIndex: state.pageIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ConsultationReturn.instance,
      builder: (context, _) {
        if (!ConsultationReturn.instance.hasPending) {
          return const SizedBox.shrink();
        }
        return Center(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _onReturn(context),
              borderRadius: BorderRadius.circular(22),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
                decoration: BoxDecoration(
                  color: const Color(0xF20A0A19),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0x66C9A84C)),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x55000000),
                        blurRadius: 14,
                        offset: Offset(0, 4)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_back,
                        size: 16, color: SolaraColors.solaraGold),
                    const SizedBox(width: 7),
                    const Text(
                      '相談結果に戻る',
                      style: TextStyle(
                        color: SolaraColors.textPrimary,
                        fontSize: 13,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 2),
                    // ✕ で破棄 (Map に留まって他操作を続けたいとき)。
                    GestureDetector(
                      onTap: () => ConsultationReturn.instance.clear(),
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.all(5),
                        child: Icon(Icons.close,
                            size: 15, color: Color(0x99FFFFFF)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
