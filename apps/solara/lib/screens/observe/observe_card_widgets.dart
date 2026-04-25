import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/tarot_card.dart';
import 'observe_constants.dart';

// ══════════════════════════════════════════════════
// 3D Card — perspective flip
// ══════════════════════════════════════════════════

class Observe3DCard extends StatelessWidget {
  final Animation<double> flipAnimation;
  final Animation<double> pulseOpacity;
  final Animation<double> pulseScale;
  final AnimationController pulseCtrl;
  final TarotCard? drawnCard;
  final bool reversed;

  const Observe3DCard({
    super.key,
    required this.flipAnimation,
    required this.pulseOpacity,
    required this.pulseScale,
    required this.pulseCtrl,
    required this.drawnCard,
    this.reversed = false,
  });

  @override
  Widget build(BuildContext context) {
    final angle = flipAnimation.value * pi;
    final showFront = angle > pi / 2;

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.00125)
        ..rotateY(angle),
      child: showFront && drawnCard != null
          ? Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationY(pi),
              child: ObserveCardFront(card: drawnCard!, reversed: reversed),
            )
          : ObserveCardBack(pulseCtrl: pulseCtrl, pulseOpacity: pulseOpacity, pulseScale: pulseScale),
    );
  }
}

// ══════════════════════════════════════════════════
// Card Back
// ══════════════════════════════════════════════════

class ObserveCardBack extends StatelessWidget {
  final AnimationController pulseCtrl;
  final Animation<double> pulseOpacity;
  final Animation<double> pulseScale;

  const ObserveCardBack({super.key, required this.pulseCtrl, required this.pulseOpacity, required this.pulseScale});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('back'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A3E), Color(0xFF0D0D2B)],
        ),
        border: Border.all(color: const Color(0xFFC9A84C), width: 2),
      ),
      child: Center(child: Container(
        width: 160, height: 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x4DC9A84C)),
          gradient: const RadialGradient(colors: [Color(0x146B5CE7), Colors.transparent], radius: 0.7),
        ),
        child: Stack(children: [
          Center(child: AnimatedBuilder(
            animation: pulseCtrl,
            builder: (_, child) => Opacity(
              opacity: pulseOpacity.value,
              child: Transform.scale(
                scale: pulseScale.value,
                child: const Text('✨', style: TextStyle(fontSize: 48)),
              ),
            ),
          )),
          Positioned.fill(child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0x26C9A84C)),
            ),
          )),
          const Positioned(top: 4, left: 4, child: Text('✦', style: TextStyle(fontSize: 10, color: Color(0x4DC9A84C)))),
          const Positioned(top: 4, right: 4, child: Text('✦', style: TextStyle(fontSize: 10, color: Color(0x4DC9A84C)))),
          const Positioned(bottom: 4, left: 4, child: Text('✦', style: TextStyle(fontSize: 10, color: Color(0x4DC9A84C)))),
          const Positioned(bottom: 4, right: 4, child: Text('✦', style: TextStyle(fontSize: 10, color: Color(0x4DC9A84C)))),
        ]),
      )),
    );
  }
}

// ══════════════════════════════════════════════════
// Card Front — 画像を枠全体に表示（テキストはカード外に移動）
// ══════════════════════════════════════════════════

class ObserveCardFront extends StatelessWidget {
  final TarotCard card;
  final bool reversed;
  const ObserveCardFront({super.key, required this.card, this.reversed = false});

  @override
  Widget build(BuildContext context) {
    final borderColor = Color(elementColors[card.element] ?? 0xFFC9A84C);

    final cardImage = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(card.imagePath, fit: BoxFit.cover),
    );

    return Container(
      key: ValueKey('front-${card.id}-${reversed ? 'r' : 'u'}'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 2),
        color: const Color(0xFF0D0D2B),
      ),
      child: reversed
          ? Transform.rotate(angle: pi, child: cardImage)
          : cardImage,
    );
  }
}

// ══════════════════════════════════════════════════
// Card Info — カードの下に表示するテキスト情報
// ══════════════════════════════════════════════════

class ObserveCardInfo extends StatelessWidget {
  final TarotCard card;
  final bool reversed;
  const ObserveCardInfo({super.key, required this.card, this.reversed = false});

  @override
  Widget build(BuildContext context) {
    final pInfo = planetInfo[card.planet];
    final planetColor = pInfo != null ? Color(int.parse('FF${pInfo[2]}', radix: 16)) : const Color(0xFFC9A84C);
    final suitLabel = card.isMajor ? 'MAJOR' : (card.suit?.toUpperCase() ?? '');

    return Column(children: [
      const SizedBox(height: 12),
      // Element badge
      Text(
        '${elementEmojis[card.element] ?? ''} ${elementNames[card.element] ?? ''} · $suitLabel',
        style: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA), letterSpacing: 1.5),
      ),
      const SizedBox(height: 6),
      // Card name EN
      Text(card.displayName,
          style: const TextStyle(fontSize: 14, color: Color(0xFFC9A84C), letterSpacing: 2, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center),
      const SizedBox(height: 2),
      // Card name JP + 正逆位置
      Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
        Text(card.nameJP, style: const TextStyle(fontSize: 18, color: Color(0xFFE8E0D0), fontWeight: FontWeight.w300)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: reversed ? const Color(0x33B088FF) : const Color(0x33C9A84C),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: reversed ? const Color(0x80B088FF) : const Color(0x80C9A84C)),
          ),
          child: Text(
            reversed ? '逆位置' : '正位置',
            style: TextStyle(fontSize: 10, color: reversed ? const Color(0xFFB088FF) : const Color(0xFFC9A84C), letterSpacing: 1),
          ),
        ),
      ]),
      const SizedBox(height: 6),
      // Keyword
      Text(card.keyword, style: const TextStyle(fontSize: 13, color: Color(0xFF999999), fontStyle: FontStyle.italic)),
      // Planet line
      if (pInfo != null) ...[
        const SizedBox(height: 6),
        Row(mainAxisSize: MainAxisSize.min, children: [
          Text(pInfo[0], style: TextStyle(fontSize: 11, color: planetColor)),
          const SizedBox(width: 4),
          Text('${pInfo[1]} Line', style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
        ]),
      ],
    ]);
  }
}
