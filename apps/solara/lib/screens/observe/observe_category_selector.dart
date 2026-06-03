part of '../observe_screen.dart';

// ══════════════════════════════════════════════════
// タロット カテゴリ選択 (Stella クレジット制、設計 project_solara_stella_free_credits.md)。
//
// 全体運 (category=null) = 無料・1 日 1 回。
// 特定カテゴリ = 非 Pro は 1 クレジット消費 (相談と共通の財布)。Pro は無制限。
//
// UX (2026-05-26 改修):
//   - カテゴリ chip を tap → クレジット残提示の確認 POPUP → 「引く」でカテゴリ確定
//   - キャンセル / × / 外タップ = 全体運に戻る
//   - 「引く」後にユーザーがカードをタップして 1 クレジット消費
//   - 消費後は再カード tap では引けない (再カテゴリ tap で POPUP 再表示)
//   - 選択中カテゴリがある状態で 全体運 chip tap = 2 秒トースト「クレジットは使いません」
//
// 本ファイルは `observe_screen.dart` の _ObserveScreenState に part of で連結。
// setState は @protected のため、本 extension からは State 本体に置いた
// _applyCategorySelection / _applyTarotCreditBalance を経由して状態変更する。
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

extension _ObserveCategorySelector on ObserveScreenState {
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
        const SizedBox(height: 6),
        const Text(
          'タロットは1日1回です',
          style: TextStyle(fontSize: 10, color: Color(0xFF888888)),
          textAlign: TextAlign.center,
        ),
        if (!isPro) ...[
          const SizedBox(height: 2),
          Text(
            _selectedCategory == null
                ? '全体運以外のカテゴリ選択にはクレジットを消費します。'
                : _tarotFreeRemaining != null
                    ? 'カテゴリ選択は1クレジット（無料あと$_tarotFreeRemaining回'
                        '${(_tarotPurchased ?? 0) > 0 ? ' ・購入$_tarotPurchased回' : ''}）'
                    : 'カテゴリ選択は1クレジット消費',
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
    // 2026-05-26 改修: 当日引き済みなら chip 全体を「固定」状態にする。
    // 選択中の chip はゴールド強調、他は薄いグレーで disabled 表示。
    final isLocked = _alreadyDrawnToday;
    final dimmedAlpha = (isLocked && !selected) ? 0.35 : 1.0;
    return GestureDetector(
      onTap: () => _onCategoryChipTap(key, label, isPro),
      child: Opacity(
        opacity: dimmedAlpha,
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
                  color: selected
                      ? const Color(0xFFF9D976)
                      : const Color(0xFFCCCCCC),
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              if (showCredit)
                const Text(' ✦1',
                    style: TextStyle(fontSize: 10, color: Color(0xFFF6BD60))),
            ],
          ),
        ),
      ),
    );
  }

  /// chip tap のディスパッチ:
  ///   - 全体運 (null) tap:
  ///       * カテゴリ選択中 (確定/消費済問わず) → 2 秒トースト + 全体運化
  ///       * 元から全体運 → 静かに何もしない
  ///   - その他カテゴリ tap:
  ///       * Pro → POPUP なしで即確定 (無制限のため摩擦不要)
  ///       * 非Pro → 残数 refetch → POPUP → 「引く」で確定 / それ以外で全体運化
  Future<void> _onCategoryChipTap(String? key, String label, bool isPro) async {
    // 2026-05-26 仕様変更: Tarot は Pro 含め 1日1回 (全体運/カテゴリ問わず)。
    // 当日既に引いていれば chip タップは完全無反応 (popup も全体運切替もトーストも出さない)。
    // 翌日 (論理日が前進) に自動で _alreadyDrawnToday が解除される。
    if (_alreadyDrawnToday) return;

    if (key == null) {
      final wasOnCategory = _selectedCategory != null;
      _applyCategorySelection(null, false);
      if (wasOnCategory) _showOverallNoCostToast();
      return;
    }
    if (isPro) {
      // Pro は常に「確定済」(カードタップで即引ける、消費もされない)。
      _applyCategorySelection(key, true);
      return;
    }
    await _showCategoryConfirmPopup(key, label);
  }

  /// 2 秒で自動消える「クレジットは使いません」案内。
  void _showOverallNoCostToast() {
    final m = ScaffoldMessenger.maybeOf(context);
    if (m == null) return;
    m.clearSnackBars();
    m.showSnackBar(
      const SnackBar(
        content: Text(
          '全体運はクレジットを使いません',
          style: TextStyle(color: SolaraColors.textPrimary),
          textAlign: TextAlign.center,
        ),
        backgroundColor: Color(0xE60F0F1E),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: Color(0x33F6BD60)),
        ),
      ),
    );
  }

  /// 非 Pro カテゴリ tap 時の確認 POPUP。残数は表示直前に refetch して新鮮化。
  /// 戻り値処理:
  ///   - proceed=true (「引く」) → カテゴリ確定 (_categoryConfirmed=true)
  ///   - proceed=false (キャンセル / × / 外タップ / 購入シート遷移) → 全体運に戻す
  Future<void> _showCategoryConfirmPopup(String key, String label) async {
    // POPUP 表示直前にサーバー側の最新クレジット残を取り直す。in-flight dedup
    // されるので、Sanctuary 等が同時に refresh しても HTTP は 1 本にまとまる。
    await ConsultationCredits.instance.refresh();
    if (!mounted) return;
    final freshStatus = ConsultationCredits.instance.status;
    if (freshStatus != null) {
      _applyTarotCreditBalance(
        freshStatus.freeRemaining,
        freshStatus.purchasedBalance,
      );
    }
    final proceed = await showTarotCategoryPopup(
      context: context,
      categoryLabel: label,
      status: freshStatus,
      onBuy: _handleBuyFromCategoryPopup,
    );
    if (!mounted) return;
    _applyCategorySelection(proceed ? key : null, proceed);
  }

  /// POPUP からの「クレジットを購入」。購入完了は購入シート側のポーリングが
  /// ConsultationCredits.refresh() を呼んで全画面に通知する。本関数では
  /// シートを閉じた後にカテゴリだけリセットする (全体運に戻す)。
  Future<void> _handleBuyFromCategoryPopup() async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    await showConsultationCreditSheet(context);
    if (!mounted) return;
    final st = ConsultationCredits.instance.status;
    _applyTarotCreditBalance(st?.freeRemaining, st?.purchasedBalance);
    _applyCategorySelection(null, false);
  }
}
