part of 'horo_relocation_panel.dart';

// ══════════════════════════════════════════════════
// A2 (2026-05-17): リロケーション解説 Free ユーザー向け Pro 誘導 CTA。
//
// 設計: pro_candidates.md §7.1
//   Free=Phase A 静的テンプレ表示 (`horo_relocation_templates`)、Gemini 0 回呼出。
//   Pro=Phase B Stella 動的解説 (`/relocation` 経由) で全惑星 + ASC/MC を上書き。
//
// このファイルは `horo_relocation_panel.dart` に part of で連結され、
// `_HoroRelocationPanelState` の build メソッドから呼ばれる。
// ══════════════════════════════════════════════════

extension _RelocationProTeaser on _HoroRelocationPanelState {
  /// Free ユーザー向け Pro 誘導カード。
  /// 「下の解説は静的テンプレ、Pro で Stella のパーソナル解説に変わる」と説明し、
  /// タップで Pro Unlock dialog を出す。
  Widget buildProTeaser() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showProUnlockDialog(
        context,
        featureLabel: 'リロケーション パーソナル解説',
        description: '下の解説は出生地→現住所のハウス変化に対する一般的な説明です。'
            'Cosmic Pro にすると、Stella があなたの出生地名・住所名・全惑星の'
            '変化を読み込み、ASC/MC + 全惑星のパーソナル解説に書き換えます。',
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0x33C9A84C), Color(0x14C9A84C)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0x55C9A84C)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.auto_awesome, size: 16, color: Color(0xFFE9D29A)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stella のパーソナル解説を開く',
                    style: GoogleFonts.notoSansJp(
                      fontSize: 12.5,
                      color: const Color(0xFFE9D29A),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '下の解説は一般的なテンプレートです。Cosmic Pro で '
                    'あなたの出生地・現住所に合わせた読みに書き換わります。',
                    style: GoogleFonts.notoSansJp(
                      fontSize: 11,
                      color: const Color(0xCCE8E0D0),
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0x66F6BD60)),
                color: const Color(0x22F6BD60),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline, size: 11, color: Color(0xFFF6BD60)),
                  SizedBox(width: 4),
                  Text('Pro',
                      style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFFF6BD60),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
