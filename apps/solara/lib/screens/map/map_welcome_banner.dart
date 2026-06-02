import 'package:flutter/material.dart';

/// Map 画面のウェルカム特典バナーの種類。
enum WelcomeBannerMode {
  /// 非表示。
  none,

  /// B: 出生地のみ登録済 → 現住所も登録すると恒久クレジット3、と促す。
  addHome,

  /// C: 出生地+現住所あり・付与済 → Stella 相談へ誘導。
  tryStella,

  /// D: profile 付与完了 + C 消化後・未サインイン → サインインでさらに3クレジット、と促す。
  addSignin,
}

/// Map 上部に出すウェルカム特典バナー (B/C 共通)。
///
/// - B (addHome) : 「現住所を登録すると無料クレジット3」→ CTA で Sanctuary (自宅登録) へ。
/// - C (tryStella): 「無料クレジット3をお贈りしました」→ CTA で Stella 相談入力へ。
/// 文言は固定 (オーナー承認済 2026-05-31)。右上 ✕ で閉じられる。
class MapWelcomeBanner extends StatelessWidget {
  final WelcomeBannerMode mode;
  final VoidCallback onCta;
  final VoidCallback onDismiss;

  const MapWelcomeBanner({
    super.key,
    required this.mode,
    required this.onCta,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (mode == WelcomeBannerMode.none) return const SizedBox.shrink();
    final String title;
    final String subtitle;
    final String ctaLabel;
    final Widget iconWidget;
    switch (mode) {
      case WelcomeBannerMode.addHome: // B
        title = '✦ 現住所を登録すると、無料クレジットを3つプレゼント';
        subtitle = 'あなたの「今いる場所」から星を読み解き、Stella相談にも使えます。';
        ctaLabel = '現住所を登録する';
        iconWidget =
            const Icon(Icons.auto_awesome, color: Color(0xFFF9D976), size: 22);
        break;
      case WelcomeBannerMode.addSignin: // D
        title = '✦ Google / Apple でサインインすると、無料クレジットをさらに3つプレゼント';
        subtitle = 'サインインすると記録を引き継げて、機種変更や再インストールでも安心です。';
        ctaLabel = 'サインインする';
        iconWidget =
            const Icon(Icons.login, color: Color(0xFFF9D976), size: 22);
        break;
      case WelcomeBannerMode.tryStella: // C
      case WelcomeBannerMode.none:
        title = '✦ ようこそ。無料クレジットを3つお贈りしました';
        subtitle =
            '週でリセットされない相談チケットです。Stellaに、あなたの星と場所のことを相談してみませんか？';
        ctaLabel = 'Stellaに相談する';
        iconWidget = const SizedBox(
          width: 28,
          height: 28,
          child: Image(
            image: AssetImage('assets/menu_icons/consult.webp'),
            fit: BoxFit.contain,
          ),
        );
        break;
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        color: const Color(0xF20C0C1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x55F6BD60)),
        boxShadow: const [
          BoxShadow(color: Color(0x33C9A84C), blurRadius: 18),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── アイコン (C は水晶玉アイコン、B は ✦) ──
          Padding(
            padding: const EdgeInsets.only(top: 1, right: 10),
            child: iconWidget,
          ),
          // ── テキスト + CTA ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFF6D98A),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFFC9C9D4),
                    fontSize: 11.5,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: onCta,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF9D976), Color(0xFFE8A840)],
                      ),
                    ),
                    child: Text(
                      ctaLabel,
                      style: const TextStyle(
                        color: Color(0xFF0A0A14),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── 閉じる ──
          GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close, color: Color(0x88C9C9D4), size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
