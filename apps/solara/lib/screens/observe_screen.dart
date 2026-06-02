import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/daily_reading.dart';
import '../models/tarot_card.dart';
import '../utils/fortune_api.dart';
import '../utils/moon_phase.dart';
import '../utils/pro_status.dart';
import '../utils/solara_storage.dart';
import '../utils/tarot_data.dart';
import '../widgets/ai_disclaimer_footer.dart';
import '../widgets/ai_report_button.dart';
import '../widgets/pro_unlock_dialog.dart';
import '../widgets/tap_to_unfocus.dart';

import '../theme/solara_colors.dart';
import '../utils/consultation_credits.dart';
import 'consultation/consultation_credit_sheet.dart';
import 'observe/observe_card_widgets.dart';
import 'observe/observe_history.dart';
import 'observe/tarot_altar_scene.dart';
import 'observe/tarot_category_popup.dart';

part 'observe/observe_question_field.dart';
part 'observe/observe_category_selector.dart';

/// Tarot Draw screen — matches tarot.html exactly.
/// Layout: Inner tabs (TAROT DRAW / HISTORY) → Card scene → Tap hint → Reading panel
class ObserveScreen extends StatefulWidget {
  const ObserveScreen({super.key});
  @override
  State<ObserveScreen> createState() => ObserveScreenState();
}

class ObserveScreenState extends State<ObserveScreen>
    with TickerProviderStateMixin {
  int _innerTab = 0; // 0=draw, 1=history

  /// 画面復元 (Android プロセス死対策): HISTORY パネルのサブタブ (0=現在 / 1=過去)
  /// を子から持ち上げて保持。子は再生成時に毎回これで初期化され、切替で更新する。
  int _historyTabForChild = 0;
  bool _cardFlipped = false;
  TarotCard? _drawnCard;
  bool _drawnReversed = false; // 正逆位置（true=逆位置）
  bool _alreadyDrawnToday = false;
  bool _readingLoading = false; // /tarot 呼び出し中
  bool _readingFromApi = false; // true=Stella の声 (失敗時は fake を出さず _readingError)
  bool _readingError = false;   // true=解説取得に失敗 (素直に「失敗+再試行」を表示)

  /// 選択中の占いカテゴリ (null = 全体運。指定すると非Pro は 1 クレジット消費)。
  String? _selectedCategory;

  /// 非Pro のカテゴリが POPUP「引く」で確定済かどうか。Pro は常に true 扱い。
  /// カテゴリ確定 + カードタップ で 1 クレジット消費する。消費後 false にリセットし、
  /// 再度引きたいときはユーザーがカテゴリ chip を再 tap → POPUP → 「引く」が必要。
  /// 全体運 (null) のときは常に true (= タップで引ける)。
  bool _categoryConfirmed = false;

  /// 最後の API 応答から得た残数 (非Pro のカテゴリ占い後に表示)。
  int? _tarotFreeRemaining;
  int? _tarotPurchased;
  // カテゴリ選択肢 (_tarotCategories) と selector UI は
  // observe/observe_category_selector.dart (part, extension) に分離。

  // ── extension から呼ぶ setState ラッパー ──
  // setState は @protected で extension から直接呼べないため State 本体に置く
  // (consultation_input_logic.dart と同じパターン)。
  void _applyCategorySelection(String? key, bool confirmed) {
    setState(() {
      _selectedCategory = key;
      _categoryConfirmed = confirmed;
    });
  }

  void _applyTarotCreditBalance(int? free, int? purchased) {
    setState(() {
      _tarotFreeRemaining = free;
      _tarotPurchased = purchased;
    });
  }

  // ローディング演出: 4つのメッセージを4秒ごとに切り替え
  static const _loadingMessages = [
    '星々があなたへの言葉を紡いでいます',
    '天体の囁きに耳を澄ませています',
    'カードの神秘を解き明かしています',
    '今日のあなたの意味を結晶化しています',
  ];
  int _loadingMsgIdx = 0;
  Timer? _loadingMsgTimer;

  void _startLoadingMessageRotation() {
    _loadingMsgIdx = 0;
    _loadingMsgTimer?.cancel();
    _loadingMsgTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || !_readingLoading) {
        timer.cancel();
        return;
      }
      setState(() => _loadingMsgIdx = (_loadingMsgIdx + 1) % _loadingMessages.length);
    });
  }

  void _stopLoadingMessageRotation() {
    _loadingMsgTimer?.cancel();
    _loadingMsgTimer = null;
  }

  // HTML: cardPulse animation 3s infinite
  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);
  late final Animation<double> _pulseOpacity =
      Tween(begin: 0.5, end: 0.8).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  late final Animation<double> _pulseScale =
      Tween(begin: 1.0, end: 1.05).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

  // HTML: 3D card flip — rotateY(180deg) with 0.8s cubic-bezier(0.4,0,0.2,1)
  late final AnimationController _flipCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );
  late final Animation<double> _flipAnimation = Tween(begin: 0.0, end: 1.0)
      .animate(CurvedAnimation(parent: _flipCtrl, curve: const Cubic(0.4, 0, 0.2, 1)));

  // Reading typewriter
  String _readingText = '';
  int _typedChars = 0;
  bool _typingDone = false;

  // History
  List<DailyReading> _history = [];

  // A3 (2026-05-17): Pro 専用「相談者のテーマ」入力欄。Free では表示しない。
  // 200 字 cap (Worker 側でも防御的に再 cap)。引き済み (_alreadyDrawnToday) の
  // ときは UI を disabled にする (1 日 1 回ルールを守る)。
  final TextEditingController _questionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _flipAnimation.addListener(() => setState(() {}));
    ProStatus.instance.addListener(_onProStatusChanged);
    _checkTodayReading();
    _loadHistory();
  }

  void _onProStatusChanged() {
    if (!mounted) return;
    // Pro 切替で質問欄の表示が変わる。引きすでに済みなら次回の引きで反映。
    setState(() {});
  }

  // ── 画面復元 (Android プロセス死対策) ──────────────────────────
  // SolaraHome が paused 時に captureRestore() を呼び、コールド起動時に
  // restoreState() で復元する。HISTORY タブが開いている時のみ対象 (オーナー要望)。

  /// HISTORY タブが開いていれば {innerTab:1, historyTab:0|1} を返す。それ以外は null。
  Map<String, dynamic>? captureRestore() {
    if (_innerTab != 1) return null;
    return {'innerTab': 1, 'historyTab': _historyTabForChild};
  }

  /// 復元: HISTORY タブ + サブタブ (現在/過去サイクル) を再現する。
  void restoreState(Map<String, dynamic> data) {
    if (!mounted) return;
    final inner = (data['innerTab'] as num?)?.toInt() ?? 0;
    if (inner != 1) return;
    setState(() {
      _historyTabForChild = (data['historyTab'] as num?)?.toInt() ?? 0;
      _innerTab = 1;
    });
  }

  @override
  void dispose() {
    _loadingMsgTimer?.cancel();
    _pulseCtrl.dispose();
    _flipCtrl.dispose();
    _questionController.dispose();
    ProStatus.instance.removeListener(_onProStatusChanged);
    super.dispose();
  }

  Future<void> _checkTodayReading() async {
    // 「1日の開始時刻」基準の論理日でゲート (単調ガード)。
    // 2026-05-26 改修: Tarot は Pro 含め 1日1回 → カテゴリ占いも復元対象に。
    final drawn = await SolaraStorage.hasDrawnFreeTarotToday();
    final today = await SolaraStorage.getTodayReading();
    if (!mounted) return;
    if (today != null) {
      final card = TarotData.getCard(today.cardId);
      setState(() {
        _drawnCard = card;
        _drawnReversed = today.reversed;
        _cardFlipped = true;
        _alreadyDrawnToday = true;
        _readingFromApi = today.reading.isNotEmpty;
        // 当日引いたカテゴリを復元 (null = 全体運)。chip selected 表示用。
        _selectedCategory = today.category;
        // カテゴリで引いた当日は「確定済」扱い (chip 再 tap も card tap も
        // _alreadyDrawnToday=true で先にブロックされるが、_drawCard 内の
        // _categoryConfirmed guard との整合性のため true に揃える)。
        _categoryConfirmed = today.category != null;
      });
      _flipCtrl.value = 1.0;
      if (today.reading.isNotEmpty) {
        // キャッシュ済み: API再呼び出しせず保存テキストをタイプライター再生
        _readingText = today.reading;
        _typedChars = 0;
        _typingDone = false;
        _startTypewriter();
      } else {
        // カードは固定済みだが解説 pending (前回失敗 / 未取得)。電波が戻っていれば
        // 自動で取得して表示・保存。ダメなら「失敗+再試行」を出す (fake は出さない)。
        // ignore: unawaited_futures
        _fetchReading(card, today, ProStatus.instance.isPro);
      }
    } else if (drawn) {
      // 当日の表示カードは無いが (リセット時刻変更で論理日が過去へ戻った等)、
      // 単調ガード上は引き済み → ドロー不可のまま「引き済み」を表示。
      setState(() => _alreadyDrawnToday = true);
    }
  }

  Future<void> _loadHistory() async {
    final readings = await SolaraStorage.loadCurrentReadings();
    if (mounted) setState(() => _history = readings);
  }

  Future<void> _drawCard() async {
    if (_readingLoading) return;
    final isPro = ProStatus.instance.isPro;
    final category = _selectedCategory; // null = 全体運
    final isCategoryDraw = category != null;

    // 2026-05-26 仕様変更: Tarot は Pro 含め 1日1回 (全体運/カテゴリ問わず)。
    // 当日既に引いていればカードタップは完全無反応。
    if (_alreadyDrawnToday) return;
    if (await SolaraStorage.hasDrawnFreeTarotToday()) {
      if (mounted) setState(() => _alreadyDrawnToday = true);
      return;
    }

    // カテゴリ占いは POPUP「引く」で確定済のときだけカードタップで実行可能。
    // (Pro は _onCategoryChipTap で popup なしで true セット済、Free は POPUP 経由)。
    // _categoryConfirmed が false の状態でカードを連打しても無反応。
    if (isCategoryDraw && !_categoryConfirmed) {
      return;
    }

    final rng = Random();
    final card = TarotData.allCards[rng.nextInt(78)];
    final reversed = rng.nextBool(); // 50%確率で逆位置

    final now = DateTime.now();
    // 日付キーは論理日 (リセット時刻基準)。moonPhase は実時刻 (天文計算) のまま。
    final dateStr = await SolaraStorage.logicalTodayKey();
    final moonPhase = MoonPhase.getPhaseDay(now);
    if (!mounted) return;

    setState(() {
      _drawnCard = card;
      _drawnReversed = reversed;
      _cardFlipped = true;
      _readingText = '';
      _readingError = false;
      _readingLoading = true;
      // 2026-05-26 仕様変更: Tarot は Pro 含め 1日1回 (全体運/カテゴリ問わず)。
      // 引いた瞬間に画面固定フラグを立てる。
      _alreadyDrawnToday = true;
    });
    // 単調ガードも同時に記録。カテゴリ占いは下で 402 (クレジット切れ) になった
    // 場合のみロールバックする。
    await SolaraStorage.markFreeTarotDrawn();
    _startLoadingMessageRotation();

    _flipCtrl.forward();

    // Pro なら質問欄をここで先に評価 (一時保存にも反映するため、API 前に取得)。
    final question = isPro ? _questionController.text.trim() : '';

    final reading = DailyReading(
      date: dateStr,
      cardId: card.id,
      isMajor: card.isMajor,
      moonPhase: moonPhase,
      reversed: reversed,
      question: question.isEmpty ? null : question,
      category: category, // null = 全体運
    );
    // 全体運(無料/Pro) は従来通り先に保存。カテゴリは 402 の可能性があるので成功後に保存
    // (既存の全体運の保存を 402 ロールバックで壊さないため)。
    if (!isCategoryDraw) {
      await SolaraStorage.addReading(reading);
      _loadHistory();
    }

    // カードフリップ完了を待ってから解説を取得 (draw / 再試行 / 復元で共用)。
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    await _fetchReading(card, reading, isPro);
  }

  /// 引いたカードの解説 (/tarot) を取得して表示・保存する。
  /// draw 直後 / 再試行ボタン / 復元 (電波復活時の自動取得) で共用。
  /// 🔴 失敗時は fake で取り繕わず素直に「失敗」状態にする (オーナー方針 2026-06-03)。
  ///   今日の引き (カード) は固定のまま解説を pending 保存し、電波が戻れば同じカードで再取得する。
  Future<void> _fetchReading(
      TarotCard card, DailyReading reading, bool isPro) async {
    final isCategoryDraw = reading.category != null;
    final question = reading.question ?? '';
    if (mounted) {
      setState(() {
        _readingLoading = true;
        _readingError = false;
      });
    }
    _startLoadingMessageRotation();

    final profile = await SolaraStorage.loadProfile();
    // A3: Pro なら thinking ON + 質問欄の内容を「テーマ」として渡す。
    // category 指定時は非 Pro は 1 クレジット消費 (Worker 側でゲート)。
    // userName は渡すが、冒頭の呼びかけは Worker プロンプト側で禁止 (途中の使用は可)。
    final tarotResult = await fetchTarotReading(
      cardId: card.id,
      reversed: reading.reversed,
      nameJP: card.nameJP,
      nameEN: card.nameEN,
      keyword: card.keyword,
      element: card.element,
      planet: card.planet,
      moonPhase: reading.moonPhase,
      userName: profile?.name,
      thinking: isPro,
      question: question.isEmpty ? null : question,
      category: reading.category,
    );

    if (!mounted) return;
    _stopLoadingMessageRotation();

    // 402 = カテゴリ占いのクレジット切れ → 引きをなかったことにして購入/Pro 導線
    if (tarotResult != null && tarotResult.creditExhausted) {
      setState(() {
        _readingLoading = false;
        _readingError = false;
        _cardFlipped = false;
        _drawnCard = null;
        // 確定状態を解除 (再度カテゴリ tap で POPUP からやり直し)。
        _categoryConfirmed = false;
        _selectedCategory = null;
        // 2026-05-26 改修: API でクレジット消費されてないので 1日1回ガードも巻き戻す
        // (購入後 or 全体運切替なら引けるように)。
        _alreadyDrawnToday = false;
      });
      // 単調ガードのストレージもクリア (購入後 / 全体運切替で再ドロー可能に)。
      await SolaraStorage.clearFreeTarotDay();
      // pending 保存していたカードがあれば取り消す (クレジット切れ=引き直し可)。
      await SolaraStorage.removeReadingByDate(reading.date);
      _flipCtrl.value = 0.0;
      // Sanctuary 等の残数表示も refetch (購入シート開いてサーバー側残が動く可能性)。
      // ignore: unawaited_futures
      ConsultationCredits.instance.refresh();
      await _handleTarotCreditExhausted();
      return;
    }

    if (tarotResult != null && tarotResult.reading.isNotEmpty) {
      // 成功: Stella の声を表示・保存
      setState(() {
        _readingText = tarotResult.reading;
        _readingLoading = false;
        _readingError = false;
        _readingFromApi = true;
        _typedChars = 0;
        _typingDone = false;
        _tarotFreeRemaining = tarotResult.freeCreditsRemaining;
        _tarotPurchased = tarotResult.purchasedBalance;
        // カテゴリ消費完了 → confirmed を false に戻す。次のカテゴリ占いは
        // 再度 chip tap → POPUP → 「引く」が必要 (連打で複数消費を防ぐ)。
        // _selectedCategory は表示として残す (どのカテゴリで引いたか分かるように)。
        if (isCategoryDraw && !isPro) _categoryConfirmed = false;
      });
      reading.reading = tarotResult.reading;
      // date キーで今日の表示を置換 (pending → 本文)。
      await SolaraStorage.addReading(reading);
      _loadHistory();
      _startTypewriter();
      // カテゴリ消費 (非Pro) のみ Sanctuary 残数バッジへ通知。
      // Pro/全体運 は残数に影響しないのでスキップ。
      if (isCategoryDraw && !isPro) {
        // ignore: unawaited_futures
        ConsultationCredits.instance.refresh();
      }
    } else {
      // 失敗 (null = network/LLM): fake を出さず素直に「失敗+再試行」。クレジットは消費されない。
      // カード (今日の引き) は固定のまま解説を pending 保存 → 電波復活で再取得して表示・履歴保存。
      reading.reading = '';
      await SolaraStorage.addReading(reading); // カード固定 (category 含む) + 復元可能に
      if (!mounted) return;
      setState(() {
        _readingText = '';
        _readingLoading = false;
        _readingFromApi = false;
        _readingError = true;
      });
      _loadHistory();
    }
  }

  /// 「失敗」状態からの再試行 / 復元時の自動取得: 今日の引きのカードで解説を取り直す。
  Future<void> _retryReading() async {
    final card = _drawnCard;
    if (card == null) return;
    final today = await SolaraStorage.getTodayReading();
    if (!mounted || today == null) return;
    await _fetchReading(card, today, ProStatus.instance.isPro);
  }

  /// カテゴリ占いのクレジット切れ時: 追加クレジット購入 / Pro 導線 (相談と共通シート)。
  Future<void> _handleTarotCreditExhausted() async {
    await showConsultationCreditSheet(context);
    // 購入後はユーザーが再度カードをタップして引き直す (残数は次の引きで反映)。
  }

  // カテゴリ selector (_buildCategorySelector / _categoryChip) は
  // observe/observe_category_selector.dart (part, extension) に分離。

  // テスト用: 今日の引きを削除して再抽選可能な状態に戻す
  // 🔴 本番リリース時にこのメソッドと呼び出しボタンを削除すること
  Future<void> _resetTodayReading() async {
    final dateStr = await SolaraStorage.logicalTodayKey();
    await SolaraStorage.removeReadingByDate(dateStr);
    await SolaraStorage.clearFreeTarotDay();

    if (!mounted) return;
    _stopLoadingMessageRotation();
    setState(() {
      _drawnCard = null;
      _drawnReversed = false;
      _cardFlipped = false;
      _alreadyDrawnToday = false;
      _readingText = '';
      _typedChars = 0;
      _typingDone = false;
      _readingLoading = false;
      _readingFromApi = false;
      _readingError = false;
    });
    _flipCtrl.value = 0.0;
    _loadHistory();
  }

  void _startTypewriter() {
    Future.delayed(const Duration(milliseconds: 25), () {
      if (!mounted) return;
      if (_typedChars < _readingText.length) {
        setState(() => _typedChars++);
        _startTypewriter();
      } else {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) setState(() => _typingDone = true);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🔴 (2026-05-19) 全 TextField (Pro テーマ欄 / 現在&過去 HISTORY メモ) で
    // 入力欄外タップ → 入力確定 + キーボード閉じる、 を TapToUnfocus 共通 widget で実現。
    return TapToUnfocus(
      child: TarotAltarScene(
        child: SafeArea(
          child: Column(children: [
            _buildInnerTabs(),
            Expanded(
              child: _innerTab == 0 ? _buildDrawPanel() : ObserveHistoryPanel(
                history: _history,
                onCleared: _loadHistory,
                initialHistoryTab: _historyTabForChild,
                onHistoryTabChanged: (i) => _historyTabForChild = i,
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ========================================
  // Inner Tabs: 🃏 TAROT DRAW / 📜 HISTORY
  // ========================================

  Widget _buildInnerTabs() {
    return Container(
      height: 40,
      decoration: const BoxDecoration(
        color: Color(0xE60F0F1E),
        border: Border(bottom: BorderSide(color: Color(0x1FC9A84C))),
      ),
      child: Row(children: [
        _innerTabBtn(0, '🃏 TAROT DRAW'),
        _innerTabBtn(1, '📜 HISTORY'),
      ]),
    );
  }

  Widget _innerTabBtn(int idx, String label) {
    final active = _innerTab == idx;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _innerTab = idx),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: active ? const Border(bottom: BorderSide(color: Color(0xFFC9A84C), width: 2)) : null,
        ),
        child: Text(label, style: TextStyle(
          color: active ? const Color(0xFFC9A84C) : const Color(0xFF555555),
          fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 1,
        )),
      ),
    ));
  }

  // ========================================
  // Draw Panel
  // ========================================

  Widget _buildDrawPanel() {
    final isPro = ProStatus.instance.isPro;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      child: Column(children: [
        // A3: 質問入力欄 (Pro 専用) / 誘導カード (Free)
        // 実装は part-of `observe/observe_question_field.dart` の extension。
        if (isPro)
          buildQuestionField()
        else
          buildQuestionFieldTeaser(),
        const SizedBox(height: 16),
        // カテゴリ選択 (全体運=無料 / 特定カテゴリ=非Proは1クレジット)
        _buildCategorySelector(isPro),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _drawCard,
          child: AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, _) {
              final t = _pulseCtrl.value * 2 * pi;
              final dy = sin(t) * 4.0;
              return Transform.translate(
                offset: Offset(0, dy),
                child: Container(
                  width: 200,
                  height: 320,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.55),
                        blurRadius: 30,
                        spreadRadius: 4,
                        offset: Offset(0, 16 - dy * 0.6),
                      ),
                    ],
                  ),
                  child: Observe3DCard(
                    flipAnimation: _flipAnimation,
                    pulseOpacity: _pulseOpacity,
                    pulseScale: _pulseScale,
                    pulseCtrl: _pulseCtrl,
                    drawnCard: _drawnCard,
                    reversed: _drawnReversed,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Card info below card (moved from inside card front)
        if (_cardFlipped && _drawnCard != null)
          ObserveCardInfo(card: _drawnCard!, reversed: _drawnReversed),
        if (!_alreadyDrawnToday)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('👆 タップしてカードを引く', style: TextStyle(fontSize: 11, color: Color(0xFF555555))),
          ),
        if (_alreadyDrawnToday && !_cardFlipped)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('✓ 本日のカードは引き済み',
                style: TextStyle(fontSize: 13, color: Color(0xFF666666), letterSpacing: 0.5),
                textAlign: TextAlign.center),
          ),
        // 🔴 本番リリース時に削除: テスト用「今日の引きをリセット」ボタン
        if (_alreadyDrawnToday)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: GestureDetector(
              onTap: _resetTodayReading,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0x55FF6B6B)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('🔄 [DEV] 今日の引きをリセット',
                    style: TextStyle(fontSize: 10, color: Color(0xFFFF8888), letterSpacing: 0.8)),
              ),
            ),
          ),
        const SizedBox(height: 16),
        if (_readingLoading) _buildLoadingIndicator(),
        if (_readingError && !_readingLoading) _buildReadingError(),
        if (_readingText.isNotEmpty && !_readingLoading) _buildReadingPanel(),
      ]),
    );
  }

  // ========================================
  // Reading Panel
  // ========================================

  Widget _buildLoadingIndicator() {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, _) {
        final t = _pulseCtrl.value; // 0..1 (3秒周期)
        final phase = t * 2 * pi;

        // 星3つを順次点灯（進行感）
        final activeDot = (t * 3).floor() % 3;
        // メッセージ全体に呼吸 opacity (0.55..1.0)
        final breathOpacity = 0.775 + 0.225 * sin(phase);
        // 末尾の点を 1〜3 個で循環
        final dotCount = 1 + (t * 4).floor() % 3;
        final tail = '・' * dotCount;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const RadialGradient(
              colors: [Color(0x33C9A84C), Color(0x110F0F1E), Color(0x000F0F1E)],
              stops: [0.0, 0.6, 1.0],
              radius: 0.9,
            ),
            border: Border.all(color: const Color(0x33C9A84C)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (int i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '✦',
                    style: TextStyle(
                      fontSize: i == activeDot ? 18 : 13,
                      color: Color.fromRGBO(
                        201, 168, 76,
                        i == activeDot ? 1.0 : 0.28,
                      ),
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 14),
            // 2026-05-03: Opacity widget 撤去 (Critical fix)。
            // breathing は Color alpha で表現 = saveLayer 回避。
            Text(
              _loadingMessages[_loadingMsgIdx],
              style: TextStyle(
                fontSize: 12.5,
                color: const Color(0xFFE8E0D0)
                    .withValues(alpha: breathOpacity.clamp(0.5, 1.0)),
                fontStyle: FontStyle.italic,
                letterSpacing: 1.2,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              tail,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFFC9A84C),
                letterSpacing: 6,
                height: 1.0,
              ),
            ),
          ]),
        );
      },
    );
  }

  /// 解説取得に失敗したとき: fake で取り繕わず素直に「失敗+再試行」(オーナー方針 2026-06-03)。
  /// 引いたカードは固定のまま。電波が戻って再試行が成功すれば同じカードの解説が表示される。
  Widget _buildReadingError() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '解説の取得に失敗しました。',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFFE8E0D0),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '通信状況を確認して、もう一度お試しください。',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFFB8B2A6),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: _readingLoading ? null : _retryReading,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFF6BD60),
                side: const BorderSide(color: Color(0x55F6BD60)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '再試行',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: const Color(0x990F0F1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x33C9A84C)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0x1FC9A84C),
                border: Border.all(color: const Color(0x40C9A84C)),
              ),
              child: const Center(child: Text('🔮', style: TextStyle(fontSize: 18)))),
          const SizedBox(width: 10),
          const Text('✦ TAROT READING',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFC9A84C), letterSpacing: 1.5)),
        ]),
        const SizedBox(height: 14),
        Text(_readingText.substring(0, _typedChars),
            style: const TextStyle(fontSize: 13, height: 1.85, color: Color(0xD9E8E0D0))),
        if (!_typingDone)
          const Text('▋', style: TextStyle(fontSize: 13, color: Color(0xFFC9A84C))),
        if (_typingDone && !_readingFromApi) ...[
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: const [
            Flexible(
              child: Text('⚠ オフラインモード（簡易表示）',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 9, color: Color(0xFF666666), letterSpacing: 0.8)),
            ),
          ]),
        ],
        // AI 出力ユーザー報告 (Google Gen AI Policy)。本物の Gemini 出力時のみ表示。
        // 詳細: docs/store_compliance.md §3.1 / widgets/ai_report_button.dart
        if (_typingDone && _readingFromApi) ...[
          AiReportButton(feature: 'tarot', outputText: _readingText),
          // 解釈は 1 つに過ぎない旨の注記。
          const StellaInterpretationNote(
            text: 'カードからStellaが解釈の１つとして本内容を表示しています。'
                '内容に違和感がある場合はご自身で解釈を広げてみてください。'
                'あくまでここでの表示は解釈の１つに過ぎません。',
          ),
          // disclaimer footer (Apple 4.0 + Google Misleading) — 報告ボタンの直下に常時。
          const AiDisclaimerFooter(),
        ],
      ]),
    );
  }
}
