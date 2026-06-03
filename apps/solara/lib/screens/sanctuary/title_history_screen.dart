// 称号 (クラス) 変遷ギャラリー — C4 (Pro 機能、柱 3)
//
// 設計: apps/solara/docs/pro_candidates.md §7.3 + §3 C4
//
// 役割:
//   - 過去に診断された「クラス」(axis × court) の変遷を時系列で並べる
//   - 二つ名 (出生固定・永久・取り直し不可) は表示しない、ここはクラス専用
//   - Free でも閲覧可能 (柱 3 原則「Free でも記録は永久」)
//   - 「取り直し」自体の Pro 化は Sanctuary 画面側で別ゲート
//
// ストレージ:
//   - SolaraStorage.loadTitleHistory() / clearTitleHistory()
//   - 60 件上限 (月 1 回前提で 5 年分)
//
// 思想ガード:
//   - 「吉凶判定しない」(project_solara_design_philosophy)
//     → 旧クラスを「以前は…」と弱めて表示しない、現在と等価に並べる

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../../i18n/strings.g.dart';
import '../../theme/solara_colors.dart';
import '../../utils/consult_restore.dart';
import '../../utils/solara_storage.dart';
import '../../utils/title_data.dart' as title_data;
import '../../widgets/info_popup.dart';
import '../../widgets/memo_text_field.dart';
import '../../widgets/tap_to_unfocus.dart';

class TitleHistoryScreen extends StatefulWidget {
  /// テスト用 hook (デフォルト null で SolaraStorage を読む)。
  final Future<List<Map<String, dynamic>>> Function()? loadOverride;

  const TitleHistoryScreen({super.key, this.loadOverride});

  @override
  State<TitleHistoryScreen> createState() => _TitleHistoryScreenState();
}

class _TitleHistoryScreenState extends State<TitleHistoryScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _records = const [];

  /// 画面復元 (Android プロセス死対策) レジストリ登録トークン。
  late final Object _restoreToken;

  @override
  void initState() {
    super.initState();
    _restoreToken = ConsultRestore.instance.register(
      () => {'type': 'titleHistory'},
    );
    _load();
  }

  @override
  void dispose() {
    ConsultRestore.instance.unregister(_restoreToken);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = widget.loadOverride != null
        ? await widget.loadOverride!()
        : await SolaraStorage.loadTitleHistory();
    if (!mounted) return;
    setState(() {
      _records = list;
      _loading = false;
    });
  }

  Future<void> _confirmClearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SolaraColors.celestialBlueLight,
        title: Text(
          t.titleHist.clearTitle,
          style: const TextStyle(color: SolaraColors.textPrimary, fontSize: 16),
        ),
        content: Text(
          t.titleHist.clearBody,
          style: const TextStyle(color: SolaraColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.titleHist.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: SolaraColors.energyHardLight,
            ),
            child: Text(t.titleHist.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await SolaraStorage.clearTitleHistory();
    await _load();
  }

  /// AppBar タイトル横の i ボタン。称号変遷と再診断についての案内を表示する。
  /// 内容は Sanctuary の「✦ 称号の受け直しについて」案内を踏まえる。
  void _showGuide(BuildContext context) {
    showInfoPopup(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.titleHist.guideTitle,
              style: const TextStyle(
                  color: Color(0xFFF6D98A), fontSize: 14, letterSpacing: 1)),
          const SizedBox(height: 10),
          Text(
            t.titleHist.guideIntro,
            style: const TextStyle(
                color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
          ),
          const SizedBox(height: 14),
          Text(t.titleHist.guideClassEpithetHead,
              style: const TextStyle(
                  color: Color(0xFFF9D976),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(
            t.titleHist.guideClassEpithet,
            style: const TextStyle(
                color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
          ),
          const SizedBox(height: 12),
          Text(t.titleHist.guideRediagnoseHead,
              style: const TextStyle(
                  color: Color(0xFFF9D976),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(
            t.titleHist.guideRediagnose,
            style: const TextStyle(
                color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
          ),
          const SizedBox(height: 12),
          Text(t.titleHist.guideStanceHead,
              style: const TextStyle(
                  color: Color(0xFFF9D976),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(
            t.titleHist.guideStance,
            style: const TextStyle(
                color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TapToUnfocus(
      child: Scaffold(
      backgroundColor: SolaraColors.celestialBlueDark,
      // 🔴 (2026-05-19) キーボードで背景がずれないよう false 統一。
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t.sanctuary.titleHistory,
              style: const TextStyle(
                color: SolaraColors.textPrimary,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _showGuide(context),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.info_outline,
                    size: 16, color: SolaraColors.solaraGoldLight),
              ),
            ),
          ],
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: SolaraColors.textPrimary),
        actions: [
          if (_records.isNotEmpty && kDebugMode)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: '[DEV] すべて削除',
              onPressed: _confirmClearAll,
            ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: SolaraColors.solaraGold,
                  strokeWidth: 2,
                ),
              )
            : _records.isEmpty
                ? const _EmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: _records.length,
                    separatorBuilder: (_, _) =>
                        const _ChainConnector(),
                    itemBuilder: (ctx, i) {
                      final r = _records[i];
                      final isLatest = i == 0;
                      return _TitleChainRow(
                        record: r,
                        isLatest: isLatest,
                      );
                    },
                  ),
      ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.history_edu_outlined,
              color: SolaraColors.textSecondary,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              t.titleHist.emptyTitle,
              style: const TextStyle(
                color: SolaraColors.textPrimary,
                fontSize: 14,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              t.titleHist.emptyBody,
              style: const TextStyle(
                color: SolaraColors.textSecondary,
                fontSize: 12,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChainConnector extends StatelessWidget {
  const _ChainConnector();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Center(
        child: Container(
          width: 1.5,
          height: 24,
          color: const Color(0x33F9D976),
        ),
      ),
    );
  }
}

class _TitleChainRow extends StatelessWidget {
  final Map<String, dynamic> record;
  final bool isLatest;
  const _TitleChainRow({required this.record, required this.isLatest});

  String _formatDate(DateTime dt) {
    final l = dt.toLocal();
    final y = l.year;
    final m = l.month.toString().padLeft(2, '0');
    final d = l.day.toString().padLeft(2, '0');
    return '$y/$m/$d';
  }

  @override
  Widget build(BuildContext context) {
    final savedAtRaw = record['savedAt'] as String? ?? '';
    final savedAt = DateTime.tryParse(savedAtRaw);
    final dateLabel = savedAt != null ? _formatDate(savedAt) : '—';

    final axis = record['axis'] as String? ?? '';
    final court = record['court'] as String? ?? '';
    final classJP = record['classJP'] as String? ?? '';
    final classEN = record['classEN'] as String? ?? '';
    final lightJP = record['lightJP'] as String? ?? '';
    final shadowJP = record['shadowJP'] as String? ?? '';
    final note = record['note'] as String? ?? '';

    final cls = (axis.isNotEmpty && court.isNotEmpty)
        ? title_data.getClassByAxisCourt(axis, court)
        : null;
    final displayJP = classJP.isNotEmpty
        ? classJP
        : (cls?.nameJP ?? '—');
    final displayEN = classEN.isNotEmpty ? classEN : (cls?.nameEN ?? '');

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xCC0A0A14),
        border: Border.all(
          color: isLatest
              ? const Color(0x66F9D976)
              : const Color(0x22F9D976),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isLatest)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0x33F9D976),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0x66F9D976)),
                  ),
                  child: const Text(
                    'NOW',
                    style: TextStyle(
                      color: SolaraColors.solaraGoldLight,
                      fontSize: 10,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (isLatest) const SizedBox(width: 8),
              Text(
                dateLabel,
                style: const TextStyle(
                  color: SolaraColors.textSecondary,
                  fontSize: 11,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  displayJP,
                  style: const TextStyle(
                    color: SolaraColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (displayEN.isNotEmpty) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    displayEN,
                    style: const TextStyle(
                      color: SolaraColors.textSecondary,
                      fontSize: 12,
                      letterSpacing: 1.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          if (lightJP.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 3),
                  child: Text(
                    '✦',
                    style: TextStyle(
                      color: SolaraColors.solaraGoldLight,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    lightJP,
                    style: const TextStyle(
                      color: SolaraColors.textPrimary,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (shadowJP.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 3),
                  child: Text(
                    '☾',
                    style: TextStyle(
                      color: SolaraColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    shadowJP,
                    style: const TextStyle(
                      color: SolaraColors.textSecondary,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (savedAtRaw.isNotEmpty) ...[
            const SizedBox(height: 12),
            MemoTextField(
              initialText: note,
              label: 'NOTE',
              labelIcon: '✎',
              hintText: t.titleHist.noteHint,
              onChanged: (text) {
                SolaraStorage.updateTitleHistoryNote(savedAtRaw, text);
              },
            ),
          ],
        ],
      ),
    );
  }
}
