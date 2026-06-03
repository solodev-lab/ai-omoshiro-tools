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
        title: const Text(
          '変遷をすべて削除しますか？',
          style: TextStyle(color: SolaraColors.textPrimary, fontSize: 16),
        ),
        content: const Text(
          '保存された称号 (クラス) の変遷が消えます。元に戻せません。\n'
          '現在の称号は Sanctuary に残ります。',
          style: TextStyle(color: SolaraColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: SolaraColors.energyHardLight,
            ),
            child: const Text('削除'),
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
        children: const [
          Text('称号 変遷 とは',
              style: TextStyle(
                  color: Color(0xFFF6D98A), fontSize: 14, letterSpacing: 1)),
          SizedBox(height: 10),
          Text(
            'ここには、Sanctuary で診断した「称号（クラス）」の\n'
            '移り変わりが、新しいものから順に記録されます。',
            style: TextStyle(
                color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
          ),
          SizedBox(height: 14),
          Text('【称号（クラス）と二つ名】',
              style: TextStyle(
                  color: Color(0xFFF9D976),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
          SizedBox(height: 4),
          Text(
            '・二つ名 … 太陽星座×月星座から導かれる、\n'
            '　生涯変わらないあなたの呼び名。\n'
            '・称号（クラス）… 設問への答えで形づくられる\n'
            '　「今のあなた」。内面や状況の変化に合わせて、\n'
            '　再診断で変わっていきます。',
            style: TextStyle(
                color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
          ),
          SizedBox(height: 12),
          Text('【再診断について】',
              style: TextStyle(
                  color: Color(0xFFF9D976),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
          SizedBox(height: 4),
          Text(
            'Sanctuary の「再診断する」から受け直せます。\n'
            '・Free … 1 回まで\n'
            '・Cosmic Pro … 何度でも（毎日でも可）\n'
            '変化のタイミングで受け直すと、ここに変遷が\n'
            '積み重なり、成長の軌跡を辿れます。',
            style: TextStyle(
                color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
          ),
          SizedBox(height: 12),
          Text('【Solara の姿勢】',
              style: TextStyle(
                  color: Color(0xFFF9D976),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
          SizedBox(height: 4),
          Text(
            '過去の称号を「以前は…」と弱めることはしません。\n'
            'どの称号も、その時々のあなたとして等しく並びます。',
            style: TextStyle(
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
            const Text(
              '称号 変遷',
              style: TextStyle(
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
            const Text(
              'まだ称号の変遷はありません',
              style: TextStyle(
                color: SolaraColors.textPrimary,
                fontSize: 14,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              'Sanctuary で再診断するたびに、\nここに過去のクラスが残っていきます。',
              style: TextStyle(
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
              hintText: '商号が変わったときの状況や心境を、自分のために残す',
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
