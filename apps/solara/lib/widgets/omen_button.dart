import 'package:flutter/material.dart';
import '../utils/omen_phrases.dart';

/// 今日のタップボタン。呼吸する金縁グロー＋タイトル/サブ/CTAの3段構成で
/// ユーザーに「今日の最高スコア演出を受け取るワクワク感」を誘う。
class OmenButton extends StatefulWidget {
  final OmenPhrase phrase;
  final VoidCallback onTap;
  const OmenButton({super.key, required this.phrase, required this.onTap});

  @override
  State<OmenButton> createState() => _OmenButtonState();
}

class _OmenButtonState extends State<OmenButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final pulse = _ctrl.value; // 0..1
        return GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xE81A0E2A),
                  Color(0xE82A184A),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Color.fromRGBO(216, 168, 72, 0.70 + pulse * 0.22),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(216, 168, 72, 0.18 + pulse * 0.22),
                  blurRadius: 18 + pulse * 10,
                  spreadRadius: 1 + pulse * 2.5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.phrase.title,
                  style: const TextStyle(
                    color: Color(0xFFF0D890),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 3,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.phrase.sub,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xE6FFFFFF),
                    fontSize: 13,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 9),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(216, 168, 72, 0.14 + pulse * 0.08),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Color.fromRGBO(216, 168, 72, 0.85 + pulse * 0.15),
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    widget.phrase.cta,
                    style: const TextStyle(
                      color: Color(0xFFFFE4A8),
                      fontSize: 15,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
