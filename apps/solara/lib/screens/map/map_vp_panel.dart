import 'package:flutter/material.dart';

/// VP Panel — HTML: .vp-panel { top:222px; left:60px; width:180px; }
class VPPanel extends StatelessWidget {
  final String activeTab;
  final ValueChanged<String> onTabChanged;

  const VPPanel({
    super.key,
    required this.activeTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xEB0C0C1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x33C9A84C)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0x08FFFFFF),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(2),
          child: Row(children: [
            _vpTabBtn('vp', '📍 VIEWPOINT'),
            _vpTabBtn('loc', '🌐 LOCATIONS'),
          ]),
        ),
        const SizedBox(height: 12),
        if (activeTab == 'vp') _buildVPContent(),
        if (activeTab == 'loc') _buildLocContent(),
      ]),
    );
  }

  Widget _vpTabBtn(String key, String label) {
    final active = activeTab == key;
    return Expanded(child: GestureDetector(
      onTap: () => onTabChanged(key),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0x1FC9A84C) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(child: Text(label, style: TextStyle(
          fontSize: 8, letterSpacing: 0.5,
          color: active ? const Color(0xFFC9A84C) : const Color(0xFF555555),
        ))),
      ),
    ));
  }

  Widget _buildVPContent() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _vpAction('📡', '現在地に移動', () {}),
      _vpAction('💾', 'この地点を保存', () {}),
      const SizedBox(height: 8),
      const Text('保存済みスロット', style: TextStyle(fontSize: 8, color: Color(0xFF555555), letterSpacing: 1)),
      const SizedBox(height: 6),
      const Text('（スロットなし）', style: TextStyle(fontSize: 10, color: Color(0xFF444444))),
    ]);
  }

  Widget _buildLocContent() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('保存された場所はありません', style: TextStyle(fontSize: 10, color: Color(0xFF555555))),
      const SizedBox(height: 8),
      _vpAction('📍', 'この地点を登録', () {}),
    ]);
  }

  Widget _vpAction(String icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x1AFFFFFF)),
        ),
        child: Row(children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)))),
        ]),
      ),
    );
  }
}
