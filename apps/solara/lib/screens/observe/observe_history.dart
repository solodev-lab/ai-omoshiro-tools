import 'package:flutter/material.dart';
import '../../i18n/strings.g.dart';
import '../../models/daily_reading.dart';
import '../../models/galaxy_cycle.dart';
import '../../models/tarot_card.dart';
import '../../theme/solara_colors.dart';
import '../../utils/solara_storage.dart';
import '../../utils/tarot_data.dart';
import '../../widgets/memo_text_field.dart';
import 'observe_constants.dart';
import 'observe_history_filter.dart';
import 'observe_history_past.dart';
import 'observe_reading_button.dart';

// ══════════════════════════════════════════════════
// History Panel
// HTML: .history-panel { padding:16px 16px 30px }
// ══════════════════════════════════════════════════

class ObserveHistoryPanel extends StatefulWidget {
  final List<DailyReading> history;
  final VoidCallback onCleared;

  /// 画面復元 (Android プロセス死対策): 初期表示するサブタブ (0=現在 / 1=過去)。
  final int initialHistoryTab;

  /// サブタブが切替わるたびに親 (ObserveScreen) へ通知 (復元キャプチャ用)。
  final ValueChanged<int>? onHistoryTabChanged;

  const ObserveHistoryPanel({
    super.key,
    required this.history,
    required this.onCleared,
    this.initialHistoryTab = 0,
    this.onHistoryTabChanged,
  });

  @override
  State<ObserveHistoryPanel> createState() => _ObserveHistoryPanelState();
}

class _ObserveHistoryPanelState extends State<ObserveHistoryPanel> {
  String? _expandedHistory; // date string of expanded card
  ObserveHistoryFilter _filter = const ObserveHistoryFilter();

  /// 内部タブ: 0=現在サイクル / 1=過去サイクル (柱3 原則「記録は永久」)
  late int _historyTab = widget.initialHistoryTab;

  /// 過去サイクル一覧 (タブ切替時に loadCompletedCycles で取得)
  List<GalaxyCycle>? _pastCycles;
  bool _loadingPastCycles = false;

  Future<void> _ensurePastCyclesLoaded() async {
    if (_pastCycles != null || _loadingPastCycles) return;
    setState(() => _loadingPastCycles = true);
    final cycles = await SolaraStorage.loadCompletedCycles();
    if (!mounted) return;
    setState(() {
      _pastCycles = cycles;
      _loadingPastCycles = false;
    });
  }

  // HTML: confirm('履歴をすべて削除しますか？')
  Future<void> _confirmClearHistory() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F0F1E),
        title: Text(t.observe.confirm, style: const TextStyle(color: Color(0xFFE8E0D0), fontSize: 16)),
        content: Text(t.observe.deleteAllConfirm, style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(t.observe.cancel, style: const TextStyle(color: Color(0xFF888888)))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(t.observe.delete, style: const TextStyle(color: Color(0xFFC9A84C)))),
        ],
      ),
    );
    if (ok == true) {
      await SolaraStorage.clearReadings();
      widget.onCleared();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 履歴は新しい順で並べてから filter を適用 (元 list は古い順)。
    final ordered = widget.history.reversed.toList();
    final visible = _filter.apply(ordered);

    // 過去サイクルタブを開いた時にロード (一度ロードしたらキャッシュ)
    if (_historyTab == 1) {
      _ensurePastCyclesLoaded();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
      child: Column(children: [
        // HTML: .history-header { flex, space-between, mb:14px }
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(
              child: Text('NATAL TAROT HISTORY',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Color(0xFF666666), letterSpacing: 1.5)),
            ),
            // CLEAR は現在サイクルのみ削除 (過去サイクルは星座として永久)
            if (_historyTab == 0)
              GestureDetector(
                onTap: _confirmClearHistory,
                child: const Text('CLEAR', style: TextStyle(fontSize: 10, color: Color(0xFF444444))),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // ── 内部タブ: 現在サイクル / 過去サイクル ──
        _buildInnerTabBar(),
        const SizedBox(height: 10),

        if (_historyTab == 0) ..._buildCurrentTabContent(visible),
        if (_historyTab == 1)
          Expanded(child: _buildPastTabContent()),
      ]),
    );
  }

  // ══════════════════════════════════════════════════
  // Inner tab bar (現在 / 過去)
  // ══════════════════════════════════════════════════
  Widget _buildInnerTabBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _innerTabBtn(0, t.observe.tabCurrentCycle),
        const SizedBox(width: 4),
        _innerTabBtn(1, t.observe.tabPastCycle),
      ],
    );
  }

  Widget _innerTabBtn(int idx, String label) {
    final active = _historyTab == idx;
    return GestureDetector(
      onTap: () {
        setState(() => _historyTab = idx);
        widget.onHistoryTabChanged?.call(idx); // 画面復元キャプチャ用
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: active ? const Color(0x33C9A84C) : const Color(0x10FFFFFF),
          border: Border.all(
            color: active
                ? const Color(0x88C9A84C)
                : SolaraColors.glassBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: active
                ? SolaraColors.solaraGoldLight
                : SolaraColors.textSecondary,
            letterSpacing: 0.6,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  /// 現在タブの中身 (旧 build の主要部分)。 Column の children として展開する
  /// ので List of Widget で返す。
  List<Widget> _buildCurrentTabContent(List<DailyReading> visible) {
    return [
      Text(t.observe.limitNote,
          style: const TextStyle(fontSize: 9, color: Color(0xFF444444))),
      const SizedBox(height: 10),

      // ── C3 (Pro) フィルタバー: 履歴がある時のみ表示 ──
      if (widget.history.isNotEmpty) ...[
        ObserveHistoryFilterBar(
          filter: _filter,
          isPro: true, // 2026-05-31: 履歴の検索/フィルタを Free 開放 (オーナー指示)
          onChanged: (f) => setState(() => _filter = f),
        ),
        const SizedBox(height: 10),
        if (_filter.isActive)
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                t.observe.countLine(visible: visible.length, total: widget.history.length),
                style: const TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 10,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
      ],

      if (widget.history.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
          child: Text(
              t.observe.emptyHistory,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF444444), fontSize: 13, height: 1.8)),
        )
      else if (visible.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
          child: Text(
            t.observe.noMatch,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF666666), fontSize: 12, height: 1.6),
          ),
        )
      else
        Expanded(
            child: ListView.builder(
          itemCount: visible.length,
          itemBuilder: (ctx, i) {
            final r = visible[i];
            return _buildHistoryCard(r);
          },
        )),
    ];
  }

  /// 過去タブの中身: ロード中はスピナー、ロード後は ObserveHistoryPastPanel。
  Widget _buildPastTabContent() {
    if (_pastCycles == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(
            color: SolaraColors.solaraGold,
            strokeWidth: 2,
          ),
        ),
      );
    }
    return ObserveHistoryPastPanel(cycles: _pastCycles!);
  }

  // ══════════════════════════════════════════════════
  // History Card
  // HTML: .history-card { radius:14px; mb:12px; border-left:3px solid [element色]; bg:rgba(15,15,30,0.5) }
  // ══════════════════════════════════════════════════

  Widget _buildHistoryCard(DailyReading r) {
    final card = TarotData.getCard(r.cardId);
    final elColor = Color(elementColors[card.element] ?? 0xFFC9A84C);
    final expanded = _expandedHistory == r.date;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0x800F0F1E),
        border: Border(left: BorderSide(color: elColor, width: 3)),
      ),
      child: Column(children: [
        InkWell(
          onTap: () => setState(() => _expandedHistory = expanded ? null : r.date),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(children: [
              SizedBox(width: 40, child: Text(card.emoji, style: const TextStyle(fontSize: 28), textAlign: TextAlign.center)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  // 過去サイクル側 (observe_history_past) と同じく Flexible+ellipsis で
                  // 長いカード名でも横 overflow しないようにする。
                  Flexible(
                    child: Text(card.localName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, color: Color(0xFFE8E0D0), fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    r.reversed ? t.observe.posShortReversed : t.observe.posShortUpright,
                    style: TextStyle(
                      fontSize: 10,
                      color: r.reversed ? const Color(0xFFB088FF) : const Color(0xFFC9A84C),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ]),
                const SizedBox(height: 2),
                Text(card.keyword, style: const TextStyle(fontSize: 11, color: Color(0xFF999999), fontStyle: FontStyle.italic)),
                const SizedBox(height: 4),
                Wrap(spacing: 8, children: [
                  Text('${elementEmojis[card.element] ?? ''} ${elementName(card.element)}',
                    style: TextStyle(fontSize: 10, color: elColor)),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.home_rounded, size: 11, color: Color(0xFF666666)),
                    const SizedBox(width: 3),
                    Text(t.observe.home, style: const TextStyle(fontSize: 10, color: Color(0xFF555555))),
                  ]),
                  Text(r.date, style: const TextStyle(fontSize: 10, color: Color(0xFF555555))),
                  if (r.question != null && r.question!.isNotEmpty)
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.help_outline, size: 11, color: Color(0xFF888888)),
                      const SizedBox(width: 3),
                      Text(t.observe.hasQuestion, style: const TextStyle(fontSize: 10, color: Color(0xFF888888))),
                    ]),
                ]),
              ])),
              // 詳細展開ボタン: タップ領域を 32px (Material 推奨 minimum tap target)
              // 確保しつつ、アイコン自体を 28px に拡大 (元 16px、視認性向上)。
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                child: Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  size: 28,
                  color: const Color(0xFFC9A84C),
                ),
              ),
            ]),
          ),
        ),
        if (expanded) _buildHistoryDetail(card, r),
      ]),
    );
  }

  // ══════════════════════════════════════════════════
  // History Detail
  // ══════════════════════════════════════════════════

  Widget _buildHistoryDetail(TarotCard card, DailyReading r) {
    final pInfo = planetInfo[card.planet];
    final planetDisplay = pInfo != null ? '${observePlanetName(card.planet!)}(${pInfo[0]})' : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: Color(0x660A0A14),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (planetDisplay.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(planetDisplay, style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
          ),
        // 質問欄 (Pro 引き時のみ保存される)
        if (r.question != null && r.question!.isNotEmpty) ...[
          const Row(children: [
            Text('❓', style: TextStyle(fontSize: 10, color: Color(0xFFC9A84C))),
            SizedBox(width: 4),
            Text('QUESTION', style: TextStyle(fontSize: 10, color: Color(0xFFC9A84C), letterSpacing: 1)),
          ]),
          const SizedBox(height: 6),
          Text(
            r.question!,
            style: const TextStyle(fontSize: 12, color: Color(0xCCE8E0D0), height: 1.6),
          ),
          const SizedBox(height: 12),
        ],
        if (r.reading.isNotEmpty) ...[
          const Row(children: [
            Text('🔮', style: TextStyle(fontSize: 10, color: Color(0xFFC9A84C))),
            SizedBox(width: 4),
            Text('READING', style: TextStyle(fontSize: 10, color: Color(0xFFC9A84C), letterSpacing: 1)),
          ]),
          const SizedBox(height: 6),
          Text(r.reading, style: const TextStyle(fontSize: 12, color: Color(0xD9E8E0D0), height: 1.7)),
          const SizedBox(height: 8),
          ObserveFullReadingButton(card: card, reading: r),
          const SizedBox(height: 12),
        ],
        Container(
          padding: const EdgeInsets.only(top: 10),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0x0AFFFFFF))),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Text('🔗', style: TextStyle(fontSize: 10, color: Color(0xFF666666))),
              SizedBox(width: 4),
              Flexible(
                child: Text('SYNCHRONICITY',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: Color(0xFF666666), letterSpacing: 1)),
              ),
            ]),
            const SizedBox(height: 6),
            MemoTextField(
              initialText: r.synchronicity,
              hintText: t.observe.memoHintSync,
              onChanged: (text) {
                r.synchronicity = text;
                SolaraStorage.updateSynchronicity(r.date, text);
              },
            ),
          ]),
        ),
      ]),
    );
  }
}

// _FullReadingButton は observe_reading_button.dart の ObserveFullReadingButton
// に統合。 過去サイクル側 (observe_history_past.dart) と重複していたため。
