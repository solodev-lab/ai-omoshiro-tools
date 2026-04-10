import 'package:flutter/material.dart';

/// Map circle button — HTML: .search-trigger, .layer-btn, .vp-btn
/// width:40px; height:40px; border-radius:50%;
/// background:rgba(10,10,25,.8); border:1px solid rgba(255,255,255,.12);
class MapBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool active;
  const MapBtn({super.key, required this.child, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xCC0A0A19),
          border: Border.all(
            color: active
                ? const Color(0x80C9A84C)
                : const Color(0x1FFFFFFF),
          ),
        ),
        child: Center(child: child),
      ),
    );
  }
}

/// Legend dot — HTML: .fs-legend { font-size:9px; color:#888; }
class LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const LegendDot({super.key, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('●', style: TextStyle(fontSize: 9, color: color)),
        const SizedBox(width: 2),
        Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF888888))),
      ],
    );
  }
}

/// Preseed prompt — HTML: .preseed { z-index:30; text-align:center; }
class Preseed extends StatefulWidget {
  const Preseed({super.key});
  @override
  State<Preseed> createState() => _PreseedState();
}

class _PreseedState extends State<Preseed> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _float = Tween<double>(begin: 0, end: -8).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _float,
      builder: (_, child) => Transform.translate(offset: Offset(0, _float.value), child: child),
      child: const Column(mainAxisSize: MainAxisSize.min, children: [
        Opacity(opacity: 0.6, child: Text('🌱', style: TextStyle(fontSize: 32))),
        SizedBox(height: 16),
        Text('今日の方位を探索してみよう\n地図をタップして始めてね',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Color(0xFF555555), letterSpacing: 1, height: 1.8)),
      ]),
    );
  }
}
