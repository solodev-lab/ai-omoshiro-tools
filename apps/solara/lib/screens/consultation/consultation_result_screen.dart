// Consultation Result Screen — Stage 4 UI
//
// 設計: apps/solara/docs/pro_candidates.md §7.2 Stage 4
//
// レイアウト:
//   - AppBar (戻る / share プレースホルダ / 閉じる)
//   - intro (固定、上部)
//   - PageView × N 候補 (横スワイプ + HapticFeedback.selectionClick)
//     候補カード: 名前 + energyLabels chips + narrative (縦スクロール)
//   - outro (固定、下部)
//   - 「もう一度候補を出す」ボタン (refresh callback がある場合のみ)
//
// 状態: loading / loaded / error / refreshing
//
// Phase 2-4 で対応:
//   - 自動保存 (solara_storage に request + response 永続化)
//   - 履歴閲覧画面
//   - 「📍地図で確認」連動 (公開後 v1.x)
//   - share ボタンの実体化

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/solara_colors.dart';
import '../../utils/consultation_api.dart';
import '../../utils/consultation_engine.dart';
import '../../utils/consultation_record.dart';
import '../../utils/consultation_share.dart';
import '../../utils/pro_status.dart';
import '../../utils/solara_storage.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/pro_unlock_dialog.dart';
import 'consultation_credit_sheet.dart';

part 'consultation_result_widgets.dart';
part 'consultation_result_credit_widgets.dart';
part 'consultation_result_share.dart';

class ConsultationResultScreen extends StatefulWidget {
  final String theme;
  final String mode;
  final String scope;
  final String freeText;
  final List<CandidateLocation> initialCandidates;

  /// Refresh callback: 既出名のリストを受け取り、新規候補を返す。
  /// null = リフレッシュ不可 (specific スコープ等 1 候補のケース、または履歴モード)。
  final Future<List<CandidateLocation>> Function(List<String> excludeNames)?
      regenerateCandidates;

  /// テスト/モック差し替え用: 通常は null で標準 fetchConsultation を呼ぶ。
  final Future<ConsultationResult> Function({
    required String theme,
    required String mode,
    required String scope,
    required List<CandidateLocation> candidates,
    String freeText,
    List<String> excluded,
  })? fetchOverride;

  /// 履歴モード用: 既に保存済の reading を渡すと Stella を呼ばず直接表示する。
  /// 通常 (新規相談) は null で fetch する。
  /// 履歴モード時は `autoSave: false` と `regenerateCandidates: null` も合わせる。
  final ConsultationReading? initialReading;

  /// 履歴に自動保存するか (default true)。履歴詳細表示時は false。
  final bool autoSave;

  /// スコープ詳細 (scope='region' の大ブロック名 '日本', '北米' 等)。
  /// 履歴カードでスコープアイコン横にラベル表示する用途で持ち回る。
  final String? scopeDetail;

  const ConsultationResultScreen({
    super.key,
    required this.theme,
    required this.mode,
    required this.scope,
    required this.initialCandidates,
    this.freeText = '',
    this.regenerateCandidates,
    this.fetchOverride,
    this.initialReading,
    this.autoSave = true,
    this.scopeDetail,
  });

  @override
  State<ConsultationResultScreen> createState() =>
      _ConsultationResultScreenState();
}

class _ConsultationResultScreenState extends State<ConsultationResultScreen> {
  late final PageController _pageCtrl;
  int _pageIndex = 0;

  late List<CandidateLocation> _candidates;
  ConsultationReading? _reading;
  bool _loading = true;
  bool _refreshing = false;
  bool _sharing = false;
  String? _error;

  /// Free 試食ゲートで 402 ブロックされた理由 (creditExhausted / proOnlyMode 等)。
  /// 非 null の間は結果ではなくペイウォール誘導ボックスを表示する。
  ConsultationBlock? _block;

  /// Free ユーザーの今週の残り無料回数 (Pro / 履歴モードは null = 非表示)。
  int? _freeRemaining;
  int? _freeLimit;

  /// 購入クレジット残高 (Pro / 履歴モードは null)。
  int? _purchasedBalance;

  /// シェア処理中フラグの更新 (share extension から setState を呼ぶための転送。
  /// setState は @protected で extension から直接呼べないため State 本体に置く)。
  void _setSharing(bool v) => setState(() => _sharing = v);

  /// リフレッシュで除外する候補名 (累積)。
  final Set<String> _excludedNames = <String>{};

  /// Phase 2-5: 画像エクスポート用、結果領域をラップする RepaintBoundary キー。
  final GlobalKey _shareBoundaryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    _candidates = List.of(widget.initialCandidates);
    if (widget.initialReading != null) {
      // 履歴モード: 即時表示、Stella は呼ばない、auto-save も走らない。
      _reading = widget.initialReading;
      _loading = false;
    } else {
      _fetch();
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<ConsultationResult> _runFetch({
    required List<CandidateLocation> candidates,
    required List<String> excluded,
  }) async {
    if (widget.fetchOverride != null) {
      return widget.fetchOverride!(
        theme: widget.theme,
        mode: widget.mode,
        scope: widget.scope,
        candidates: candidates,
        freeText: widget.freeText,
        excluded: excluded,
      );
    }
    return fetchConsultation(
      theme: widget.theme,
      mode: widget.mode,
      scope: widget.scope,
      candidates: candidates,
      freeText: widget.freeText,
      excluded: excluded,
    );
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
      _block = null;
    });
    final result = await _runFetch(
      candidates: _candidates,
      excluded: const [],
    );
    if (!mounted) return;
    if (result.isBlocked) {
      // Free 試食ゲート: 結果ではなくペイウォール誘導ボックスを出す。
      setState(() {
        _loading = false;
        _block = result.block;
      });
      return;
    }
    final reading = result.reading;
    if (reading == null) {
      setState(() {
        _loading = false;
        _error = '接続に届きませんでした。もう一度試せます。';
      });
      return;
    }
    setState(() {
      _reading = reading;
      _freeRemaining = result.freeCreditsRemaining;
      _freeLimit = result.freeCreditsLimit;
      _purchasedBalance = result.purchasedBalance;
      _loading = false;
    });
    _maybePersist(reading, _candidates);
  }

  Future<void> _refresh() async {
    final gen = widget.regenerateCandidates;
    if (gen == null) return;
    setState(() {
      _refreshing = true;
      _error = null;
    });
    // 既出として今表示中の候補名を全部追加 (累積)。
    for (final c in _candidates) {
      _excludedNames.add(c.nameJP);
    }
    final excludedList = _excludedNames.toList(growable: false);
    final newCands = await gen(excludedList);
    if (!mounted) return;
    if (newCands.isEmpty) {
      setState(() {
        _refreshing = false;
        _error = '別の候補が見つかりませんでした。';
      });
      return;
    }
    final result = await _runFetch(
      candidates: newCands,
      excluded: excludedList,
    );
    if (!mounted) return;
    if (result.isBlocked) {
      // 出し直しもクレジット 1 消費。尽きていたら購入/Pro 導線。現在の結果は残す。
      setState(() => _refreshing = false);
      if (result.block == ConsultationBlock.creditExhausted) {
        await _onBuyCredits();
      } else {
        await showProUnlockDialog(
          context,
          featureLabel: 'Stella 相談',
          description: 'Cosmic Pro なら回数無制限で読み解けます。',
        );
      }
      return;
    }
    final reading = result.reading;
    if (reading == null) {
      setState(() {
        _refreshing = false;
        _error = '接続に届きませんでした。もう一度試せます。';
      });
      return;
    }
    setState(() {
      _candidates = newCands;
      _reading = reading;
      _freeRemaining = result.freeCreditsRemaining;
      _freeLimit = result.freeCreditsLimit;
      _purchasedBalance = result.purchasedBalance;
      _refreshing = false;
      _pageIndex = 0;
    });
    if (_pageCtrl.hasClients) {
      _pageCtrl.jumpToPage(0);
    }
    _maybePersist(reading, newCands);
  }

  /// ペイウォール誘導ボックスの「Cosmic Pro」CTA。理由別に文言を出し分ける。
  void _showConsultationPaywall() {
    final (label, desc) = switch (_block) {
      ConsultationBlock.proOnlyMode => (
          '移住・旅行の相談',
          'おでかけ以外の相談も、Cosmic Pro なら無制限に。',
        ),
      ConsultationBlock.proOnlyRefresh => (
          '候補の出し直し',
          '別の候補を何度でも見比べられます。',
        ),
      _ => (
          'Stella 相談',
          '今週の無料の相談を使い切りました。Cosmic Pro なら回数無制限・thinking でより深く読み解きます。',
        ),
    };
    showProUnlockDialog(context, featureLabel: label, description: desc);
  }

  /// 追加クレジット購入シートを開く。購入で残高が入り、まだ結果未取得 (初回ブロック) なら
  /// 元の相談を自動で再試行する。
  Future<void> _onBuyCredits() async {
    final bought = await showConsultationCreditSheet(context);
    if (!mounted) return;
    if (bought && _reading == null) {
      _fetch();
    }
  }

  /// 自動保存 (auto-save)。ConsultationRecord を solara_storage に追記する。
  /// 履歴モード (initialReading != null) や auto-save 無効時は no-op。
  Future<void> _maybePersist(
    ConsultationReading reading,
    List<CandidateLocation> candidates,
  ) async {
    if (!widget.autoSave) return;
    if (widget.initialReading != null) return;
    try {
      final record = ConsultationRecord.create(
        theme: widget.theme,
        mode: widget.mode,
        scope: widget.scope,
        freeText: widget.freeText,
        candidates: candidates,
        reading: reading,
        scopeDetail: widget.scopeDetail,
      );
      await SolaraStorage.addConsultationRecord(record);
    } catch (_) {
      // 保存失敗は UX を妨げない (toast 等は出さない)。
      // 柱 3 の原則: 失敗してもユーザーは結果を読める。
    }
  }

  // シェア機能 (_openShareSheet / _copyText / _shareImage) は
  // consultation_result_share.dart (part, extension) に分離。

  @override
  Widget build(BuildContext context) {
    final canShare = _reading != null && !_loading;
    return Scaffold(
      backgroundColor: SolaraColors.celestialBlueDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: SolaraColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: '戻る',
        ),
        title: const Text(
          '相談の結果',
          style: TextStyle(
            color: SolaraColors.textPrimary,
            fontSize: 16,
            letterSpacing: 0.4,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _sharing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: SolaraColors.solaraGold,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.ios_share,
                    color: SolaraColors.textPrimary,
                  ),
            tooltip: 'シェア',
            onPressed: canShare && !_sharing ? _openShareSheet : null,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RepaintBoundary(
          key: _shareBoundaryKey,
          child: ColoredBox(
            color: SolaraColors.celestialBlueDark,
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const _LoadingSkeleton();
    if (_block != null && _reading == null) {
      return _ConsultationBlockedBox(
        reason: _block!,
        onUpgrade: _showConsultationPaywall,
        onBuyCredits: _onBuyCredits,
      );
    }
    if (_error != null && _reading == null) {
      return _ErrorBox(message: _error!, onRetry: _fetch);
    }
    final reading = _reading;
    if (reading == null) return const _LoadingSkeleton();

    // 出し直しも 1 クレジット消費 (Free も可)。Pro は無制限。
    final canRefresh = widget.regenerateCandidates != null;

    return Column(
      children: [
        _IntroBlock(text: reading.intro, fallback: reading.fallback),
        if (_freeRemaining != null || _purchasedBalance != null)
          _FreeCreditsBanner(
            remaining: _freeRemaining ?? 0,
            limit: _freeLimit,
            purchasedBalance: _purchasedBalance,
            onUpgrade: () => showProUnlockDialog(
              context,
              featureLabel: 'Stella 相談',
              description: 'Cosmic Pro なら回数無制限で読み解きます。',
            ),
          ),
        _PageIndicator(
          count: _candidates.length,
          index: _pageIndex,
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: _candidates.length,
            onPageChanged: (i) {
              HapticFeedback.selectionClick();
              setState(() => _pageIndex = i);
            },
            itemBuilder: (ctx, i) {
              final cand = _candidates[i];
              final readingForI = i < reading.candidates.length
                  ? reading.candidates[i]
                  : null;
              return _CandidateCard(
                candidate: cand,
                reading: readingForI,
              );
            },
          ),
        ),
        _OutroBlock(text: reading.outro),
        if (canRefresh)
          _RefreshButton(
            loading: _refreshing,
            onTap: _refreshing ? null : _refresh,
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}

