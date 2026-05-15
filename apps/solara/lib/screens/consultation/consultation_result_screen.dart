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

part 'consultation_result_widgets.dart';

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
  final Future<ConsultationReading?> Function({
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

  Future<ConsultationReading?> _runFetch({
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
    });
    final reading = await _runFetch(
      candidates: _candidates,
      excluded: const [],
    );
    if (!mounted) return;
    if (reading == null) {
      setState(() {
        _loading = false;
        _error = '接続に届きませんでした。もう一度試せます。';
      });
      return;
    }
    setState(() {
      _reading = reading;
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
    final reading = await _runFetch(
      candidates: newCands,
      excluded: excludedList,
    );
    if (!mounted) return;
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
      _refreshing = false;
      _pageIndex = 0;
    });
    if (_pageCtrl.hasClients) {
      _pageCtrl.jumpToPage(0);
    }
    _maybePersist(reading, newCands);
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

  /// Phase 2-5: シェアシートを開く (テキスト / 画像 2 択)。
  /// Phase 2-6a: シェア機能は Pro 限定。Free はアップグレード案内のみ。
  Future<void> _openShareSheet() async {
    final reading = _reading;
    if (reading == null) return;
    if (_sharing) return;

    // Pro ゲート
    if (!ProStatus.instance.isPro) {
      await showProUnlockDialog(
        context,
        featureLabel: '相談結果のシェア',
        description: 'Stella の読みをテキスト/画像で書き出して、近しい人と共有できます。',
      );
      return;
    }

    final choice = await showModalBottomSheet<_ShareChoice>(
      context: context,
      backgroundColor: SolaraColors.celestialBlueLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: SolaraColors.glassBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.copy_outlined,
                  color: SolaraColors.solaraGold,
                ),
                title: const Text(
                  'テキストをコピー',
                  style: TextStyle(color: SolaraColors.textPrimary),
                ),
                subtitle: const Text(
                  '相談結果を clipboard に整形してコピー',
                  style: TextStyle(
                    color: SolaraColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                onTap: () => Navigator.of(ctx).pop(_ShareChoice.text),
              ),
              ListTile(
                leading: const Icon(
                  Icons.image_outlined,
                  color: SolaraColors.solaraGold,
                ),
                title: const Text(
                  '画像で共有',
                  style: TextStyle(color: SolaraColors.textPrimary),
                ),
                subtitle: const Text(
                  '結果画面を PNG にして OS 標準シェアで共有',
                  style: TextStyle(
                    color: SolaraColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                onTap: () => Navigator.of(ctx).pop(_ShareChoice.image),
              ),
            ],
          ),
        ),
      ),
    );
    if (choice == null) return;
    if (!mounted) return;
    if (choice == _ShareChoice.text) {
      await _copyText(reading);
    } else {
      await _shareImage(reading);
    }
  }

  Future<void> _copyText(ConsultationReading reading) async {
    final text = formatConsultationAsText(
      theme: widget.theme,
      mode: widget.mode,
      scope: widget.scope,
      freeText: widget.freeText,
      reading: reading,
    );
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('テキストをコピーしました'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _shareImage(ConsultationReading reading) async {
    setState(() => _sharing = true);
    try {
      final caption = formatConsultationCaption(
        theme: widget.theme,
        reading: reading,
      );
      await shareConsultationImage(
        boundaryKey: _shareBoundaryKey,
        shareText: caption,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('シェアに失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

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
    if (_error != null && _reading == null) {
      return _ErrorBox(message: _error!, onRetry: _fetch);
    }
    final reading = _reading;
    if (reading == null) return const _LoadingSkeleton();

    return Column(
      children: [
        _IntroBlock(text: reading.intro, fallback: reading.fallback),
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
        if (widget.regenerateCandidates != null)
          _RefreshButton(
            loading: _refreshing,
            onTap: _refreshing ? null : _refresh,
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}

