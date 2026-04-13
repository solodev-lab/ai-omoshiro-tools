import 'package:flutter/material.dart';
import '../../models/daily_reading.dart';
import '../../models/tarot_card.dart';
import '../../utils/solara_storage.dart';
import '../../utils/tarot_data.dart';
import 'observe_constants.dart';

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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
      child: Column(children: [
        // HTML: .history-header { flex, space-between, mb:14px }
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('NATAL TAROT HISTORY',
                style: TextStyle(fontSize: 12, color: Color(0xFF666666), letterSpacing: 1.5)),
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

        if (widget.history.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 60, horizontal: 20),
            child: Text(
                'まだ履歴がありません\n\nTAROT DRAW タブでカードを引くと\nここに記録されます',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF444444), fontSize: 13, height: 1.8)),
          )
        else
          Expanded(
              child: ListView.builder(
            itemCount: widget.history.length,
            itemBuilder: (ctx, i) {
              final r = widget.history[widget.history.length - 1 - i];
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
        GestureDetector(
          onTap: () => setState(() => _expandedHistory = expanded ? null : r.date),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(children: [
              SizedBox(width: 40, child: Text(card.emoji, style: const TextStyle(fontSize: 28), textAlign: TextAlign.center)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(card.nameJP, style: const TextStyle(fontSize: 14, color: Color(0xFFE8E0D0), fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(card.keyword, style: const TextStyle(fontSize: 11, color: Color(0xFF999999), fontStyle: FontStyle.italic)),
                const SizedBox(height: 4),
                Wrap(spacing: 8, children: [
                  Text('${elementEmojis[card.element] ?? ''} ${elementNames[card.element] ?? ''}',
                    style: TextStyle(fontSize: 10, color: elColor)),
                  const Text('🏠 自宅', style: TextStyle(fontSize: 10, color: Color(0xFF555555))),
                  Text(r.date, style: const TextStyle(fontSize: 10, color: Color(0xFF555555))),
                ]),
              ])),
              Text(expanded ? '▲' : '▼', style: const TextStyle(fontSize: 14, color: Color(0xFF555555))),
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
        Container(
          padding: const EdgeInsets.only(top: 10),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0x0AFFFFFF))),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Text('🔗', style: TextStyle(fontSize: 10, color: Color(0xFF666666))),
              SizedBox(width: 4),
              Text('SYNCHRONICITY', style: TextStyle(fontSize: 10, color: Color(0xFF666666), letterSpacing: 1)),
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
