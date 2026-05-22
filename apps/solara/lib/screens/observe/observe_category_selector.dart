part of '../observe_screen.dart';

// ══════════════════════════════════════════════════
// タロット カテゴリ選択 (Stella クレジット制、設計 project_solara_stella_free_credits.md)。
//
// 全体運 (category=null) = 無料・1 日 1 回。
// 特定カテゴリ = 非 Pro は 1 クレジット消費 (相談と共通の財布)。Pro は無制限。
// 本ファイルは `observe_screen.dart` の _ObserveScreenState に part of で連結され、
// `_selectedCategory` / `_tarotFreeRemaining` 等の private state にアクセスする。
// observe_screen.dart が 500 行 (HARD) を超えるため selector を切り出した。
// ══════════════════════════════════════════════════

/// カテゴリ選択肢 (Stella 相談の theme と同じ語彙)。null = 全体運。
const List<(String?, String)> _tarotCategories = [
  (null, '全体運'),
  ('love', '恋愛'),
  ('money', '豊かさ'),
  ('work', '仕事'),
  ('communication', '対話'),
  ('healing', '癒し'),
  ('newStart', '変化'),
];

extension _ObserveCategorySelector on _ObserveScreenState {
  /// カテゴリ選択 UI。全体運=無料 / 特定カテゴリ=非Pro は 1 クレジット消費。
  Widget _buildCategorySelector(bool isPro) {
    return Column(
      children: [
        const Text('占いたいカテゴリ',
            style: TextStyle(
                fontSize: 11, color: Color(0xFF888888), letterSpacing: 1.0)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            for (final (key, label) in _tarotCategories)
              _categoryChip(key, label, isPro),
          ],
        ),
        if (!isPro) ...[
          const SizedBox(height: 6),
          Text(
            _selectedCategory == null
                ? '全体運は無料（1日1回）'
                : _tarotFreeRemaining != null
                    ? 'カテゴリ占いは1クレジット（無料あと$_tarotFreeRemaining回'
                        '${(_tarotPurchased ?? 0) > 0 ? ' ・購入$_tarotPurchased回' : ''}）'
                    : 'カテゴリ占いは1クレジット消費',
            style: const TextStyle(fontSize: 10, color: Color(0xFF888888)),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _categoryChip(String? key, String label, bool isPro) {
    final selected = _selectedCategory == key;
    final showCredit = key != null && !isPro; // 非Pro の特定カテゴリは 1 クレジット
    return GestureDetector(
      onTap: () => _selectCategory(key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0x33F6BD60) : const Color(0x11FFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xAAF6BD60) : const Color(0x33FFFFFF),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color:
                    selected ? const Color(0xFFF9D976) : const Color(0xFFCCCCCC),
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (showCredit)
              const Text(' ✦1',
                  style: TextStyle(fontSize: 10, color: Color(0xFFF6BD60))),
          ],
        ),
      ),
    );
  }
}
