import 'package:flutter/material.dart';
import '../../models/daily_reading.dart';
import '../../models/tarot_card.dart';
import '../../utils/pro_status.dart';
import '../../utils/solara_storage.dart';
import '../../utils/tarot_data.dart';
import 'observe_constants.dart';
import 'observe_history_filter.dart';

// ══════════════════════════════════════════════════
// History Panel
// HTML: .history-panel { padding:16px 16px 30px }
// ══════════════════════════════════════════════════

class ObserveHistoryPanel extends StatefulWidget {
  final List<DailyReading> history;
  final VoidCallback onCleared;
  const ObserveHistoryPanel({super.key, required this.history, required this.onCleared});

  @override
  State<ObserveHistoryPanel> createState() => _ObserveHistoryPanelState();
}

class _ObserveHistoryPanelState extends State<ObserveHistoryPanel> {
  String? _expandedHistory; // date string of expanded card
  ObserveHistoryFilter _filter = const ObserveHistoryFilter();

  @override
  void initState() {
    super.initState();
    ProStatus.instance.addListener(_onProChanged);
  }

  @override
  void dispose() {
    ProStatus.instance.removeListener(_onProChanged);
    super.dispose();
  }

  void _onProChanged() {
    if (!mounted) return;
    // Free に降格された時はフィルタを初期状態に戻して結果が消えないようにする
    // (柱 3 原則: Free の記録閲覧を阻害しない)。
    if (!ProStatus.instance.isPro && _filter.isActive) {
      setState(() => _filter = const ObserveHistoryFilter());
    } else {
      setState(() {});
    }
  }

  // HTML: confirm('履歴をすべて削除しますか？')
  Future<void> _confirmClearHistory() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F0F1E),
        title: const Text('確認', style: TextStyle(color: Color(0xFFE8E0D0), fontSize: 16)),
        content: const Text('履歴をすべて削除しますか？', style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('キャンセル', style: TextStyle(color: Color(0xFF888888)))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('削除', style: TextStyle(color: Color(0xFFC9A84C)))),
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
            GestureDetector(
              onTap: _confirmClearHistory,
              child: const Text('CLEAR', style: TextStyle(fontSize: 10, color: Color(0xFF444444))),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text('※ 履歴は50件までです。古い履歴から自動的に削除されます。',
            style: TextStyle(fontSize: 9, color: Color(0xFF444444))),
        const SizedBox(height: 10),

        // ── C3 (Pro) フィルタバー: 履歴がある時のみ表示 ──
        if (widget.history.isNotEmpty) ...[
          ObserveHistoryFilterBar(
            filter: _filter,
            isPro: ProStatus.instance.isPro,
            onChanged: (f) => setState(() => _filter = f),
          ),
          const SizedBox(height: 10),
          if (_filter.isActive)
            Padding(
              padding: const EdgeInsets.only(bottom: 6, left: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${visible.length} 件 / 全 ${widget.history.length} 件',
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
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 60, horizontal: 20),
            child: Text(
                'まだ履歴がありません\n\nTAROT DRAW タブでカードを引くと\nここに記録されます',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF444444), fontSize: 13, height: 1.8)),
          )
        else if (visible.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            child: Text(
              '条件に合うカードはありません',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF666666), fontSize: 12, height: 1.6),
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
      ]),
    );
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
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(card.nameJP, style: const TextStyle(fontSize: 14, color: Color(0xFFE8E0D0), fontWeight: FontWeight.w500)),
                  const SizedBox(width: 6),
                  Text(
                    r.reversed ? '逆' : '正',
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
                  Text('${elementEmojis[card.element] ?? ''} ${elementNames[card.element] ?? ''}',
                    style: TextStyle(fontSize: 10, color: elColor)),
                  const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.home_rounded, size: 11, color: Color(0xFF666666)),
                    SizedBox(width: 3),
                    Text('自宅', style: TextStyle(fontSize: 10, color: Color(0xFF555555))),
                  ]),
                  Text(r.date, style: const TextStyle(fontSize: 10, color: Color(0xFF555555))),
                  if (r.question != null && r.question!.isNotEmpty)
                    const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.help_outline, size: 11, color: Color(0xFF888888)),
                      SizedBox(width: 3),
                      Text('質問あり', style: TextStyle(fontSize: 10, color: Color(0xFF888888))),
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
    final planetDisplay = pInfo != null ? '${pInfo[1]}(${pInfo[0]})' : '';

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
            _SyncInput(
              initialText: r.synchronicity,
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

// ══════════════════════════════════════════════════
// Synchronicity Input (separate StatefulWidget for TextField state)
// ══════════════════════════════════════════════════

class _SyncInput extends StatefulWidget {
  final String initialText;
  final ValueChanged<String> onChanged;

  const _SyncInput({required this.initialText, required this.onChanged});

  @override
  State<_SyncInput> createState() => _SyncInputState();
}

class _SyncInputState extends State<_SyncInput> {
  late final TextEditingController _ctrl;
  bool _showSaved = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    widget.onChanged(text);
    setState(() => _showSaved = true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _showSaved = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      TextField(
        controller: _ctrl,
        onChanged: _onChanged,
        maxLines: null,
        minLines: 2,
        style: const TextStyle(fontSize: 12, color: Color(0xFFE8E0D0)),
        decoration: InputDecoration(
          hintText: '偶然の一致や気づきをメモ...',
          hintStyle: const TextStyle(color: Color(0xFF444444)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          filled: true,
          fillColor: const Color(0x990F0F1E),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0x1FC9A84C))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0x1FC9A84C))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0x4DC9A84C))),
        ),
      ),
      AnimatedOpacity(
        opacity: _showSaved ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text('saved', style: TextStyle(fontSize: 9, color: Color(0xFFC9A84C))),
        ),
      ),
    ]);
  }
}
