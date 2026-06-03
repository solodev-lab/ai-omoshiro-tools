// Consultation Result Screen — V2 (全要素統合)
//
// 設計: project_solara_consultation_full_integration.md
//
// レイアウト:
//   - AppBar (戻る / タイトル「相談の結果 ⌄」=この読み解きについて / share)
//   - 内的季節バナー (初回・常設)
//   - PageView × 蓄積候補 (横スワイプ)。候補カード: 特徴見出し + 時間帯 +
//     energyLabels + narrative
//   - 「別の候補地を見る」(excluded を足して次候補を 1 つ取得・1 クレジット消費)
//
// 1 クレジット = 1 候補。最初の取得で見出し候補、「別の候補地」で 1 枚ずつ最大 5 枚。
// Pro = 無制限。live モード = ConsultationRequest で fetch / 履歴モード =
// ConsultationRecord を読み込み専用表示 (fetch なし・autosave なし・別候補なし)。

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

import '../../i18n/strings.g.dart';
import '../../theme/solara_colors.dart';
import '../../utils/consultation_api.dart' show ConsultationBlock;
import '../../utils/consultation_credits.dart';
import '../../utils/consult_restore.dart';
import '../../utils/map_focus.dart';
import '../../utils/consultation_return.dart';
import '../../utils/consultation_record.dart';
import '../../utils/consultation_share.dart';
import '../../utils/consultation_v2_api.dart';
import '../../utils/pro_status.dart';
import '../../utils/solara_i18n.dart' show isEnLocale;
import '../../utils/solara_storage.dart';
import '../map/map_constants.dart' show planetName;
import '../../widgets/ai_disclaimer_footer.dart';
import '../../widgets/ai_report_button.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/info_popup.dart';
import '../../widgets/pro_unlock_dialog.dart';
import 'consultation_credit_sheet.dart';

part 'consultation_result_widgets.dart';
part 'consultation_result_card.dart';
part 'consultation_result_credit_widgets.dart';
part 'consultation_result_share.dart';

/// 最大候補数 (Free/Pro 共通の蓄積上限。スワイプ比較の母集団)。
const int _kMaxCandidates = 5;

class ConsultationResultScreen extends StatefulWidget {
  /// live モード: 相談リクエスト (fetch する)。履歴モードでは null。
  final ConsultationRequest? request;

  /// 履歴モード: 保存済みレコード (読み込み専用表示)。live では null。
  final ConsultationRecord? record;

  /// scope の詳細ラベル (履歴カード用、region グループ名 / 地点名)。
  final String? scopeDetail;

  /// テスト用 fetch 差し替え (null で標準 fetchConsultationV2)。
  final Future<ConsultationV2Result> Function(ConsultationRequest req)?
      fetchOverride;

  /// 戻り導線 (ConsultationReturn) からの再表示用 seed。非 null かつ非空なら
  /// fetch せず live 状態をそのまま復元する (= クレジット非消費)。通常起動は null。
  final List<ConsultationV2Reading>? resumeReadings;
  final List<String>? resumeAvoid;
  final DateTime? resumeSavedAt;
  final int? resumePageIndex;

  const ConsultationResultScreen({
    super.key,
    required this.request,
    this.scopeDetail,
    this.fetchOverride,
    this.resumeReadings,
    this.resumeAvoid,
    this.resumeSavedAt,
    this.resumePageIndex,
  }) : record = null;

  const ConsultationResultScreen.fromRecord({
    super.key,
    required this.record,
  })  : request = null,
        scopeDetail = null,
        fetchOverride = null,
        resumeReadings = null,
        resumeAvoid = null,
        resumeSavedAt = null,
        resumePageIndex = null;

  bool get isHistory => record != null;

  @override
  State<ConsultationResultScreen> createState() =>
      _ConsultationResultScreenState();
}

class _ConsultationResultScreenState extends State<ConsultationResultScreen> {
  late final PageController _pageCtrl;
  int _pageIndex = 0;

  final List<ConsultationV2Reading> _readings = [];
  bool _loading = true;
  bool _loadingNext = false;
  bool _sharing = false;
  String? _error;

  /// これ以上「別の候補地」が無い (excluded で出し尽くした)。出し直しボタンの抑制に使う。
  /// 注意: 履歴閲覧・初回残数0・出し直し後残数0 でも立つので、案Yパネルの条件には使わない。
  bool _exhausted = false;

  /// 案Yパネル (出し尽くし案内) を出すか。出し直しで枯渇 (server isExhausted) したときだけ true。
  /// 履歴閲覧や「残数0だが結果は得た」では _exhausted は立つが、これは立てない。
  bool _showExhaustionPanel = false;

  /// 枯渇 (案Y) の理由コードと代替提案 (exhausted パネルで提示)。クレジットは非消費。
  String? _exhaustedReason;
  List<String> _exhaustSuggestions = const [];

  /// avoid-window (C-2): 新規相談の開始時に固定する「直近に出した地名」スナップショット。
  /// 全リクエスト (初回 + 出し直し) に avoid として送り、theme×scope の無連続を効かせる。
  List<String> _avoid = const [];

  /// avoid-window のキー (theme:scopeKind)。履歴閲覧・具体地点は no-repeat 対象外 → null。
  String? get _avoidKey {
    final req = widget.request;
    if (req == null || widget.record != null) return null;
    final kind = req.scope?.kind ?? 'world';
    if (kind == 'point') return null; // ユーザーが選んだ具体地点は繰り返してよい
    return '${req.theme}:$kind';
  }

  /// 提示した候補名を avoid-window に積む (Pro 9 / Free 6、best-effort)。
  Future<void> _pushShownToAvoid(ConsultationV2Reading reading) async {
    final key = _avoidKey;
    final name = reading.candidate.name;
    if (key == null || name == null || name.isEmpty) return;
    final maxN = ProStatus.instance.isPro ? 9 : 6;
    await SolaraStorage.pushConsultationAvoid(key, name, maxN);
  }

  /// 初回 fetch が 402 でブロックされた理由。非 null の間は結果ではなく誘導を出す。
  ConsultationBlock? _block;

  // 2026-05-26: クレジット残バナー (_FreeCreditsBanner) を結果画面上部から撤去したため、
  // _freeRemaining / _freeLimit / _purchasedBalance は不要に。サーバー応答中の残数は
  // ConsultationCreditEvents で他画面 (Sanctuary / Start popup) に通知して反映する。

  /// 自動保存レコードの id を安定させる savedAt (毎回の追記で同一レコードを上書き)。
  DateTime? _recordSavedAt;

  final GlobalKey _shareBoundaryKey = GlobalKey();

  void _setSharing(bool v) => setState(() => _sharing = v);

  ConsultationV2Reading? get _first =>
      _readings.isNotEmpty ? _readings.first : null;

  /// 画面復元 (Android プロセス死対策) レジストリ登録トークン。
  late final Object _restoreToken;

  @override
  void initState() {
    super.initState();
    // 押下ルート復元の登録。SolaraHome が paused 時に _captureRestore を pull する。
    _restoreToken = ConsultRestore.instance.register(_captureRestore);
    if (widget.record != null) {
      _pageCtrl = PageController();
      _readings.addAll(widget.record!.toReadings());
      _loading = false;
      _exhausted = true; // 履歴は追加取得しない
    } else if (widget.resumeReadings != null &&
        widget.resumeReadings!.isNotEmpty) {
      // 戻り導線: 退避した live 状態を fetch せず復元 (クレジット非消費)。
      // 「別の候補地」も継続可 (request / avoid / readings を引き継ぐ)。
      _readings.addAll(widget.resumeReadings!);
      _avoid = widget.resumeAvoid ?? const [];
      _recordSavedAt = widget.resumeSavedAt;
      _pageIndex =
          (widget.resumePageIndex ?? 0).clamp(0, _readings.length - 1);
      _pageCtrl = PageController(initialPage: _pageIndex);
      _loading = false;
      final last = _readings.last;
      _exhausted =
          last.remainingAfter <= 0 || _readings.length >= _kMaxCandidates;
    } else {
      _pageCtrl = PageController();
      // 新規 live 相談を開始 → 別セッションの古い戻り導線は無効化する。
      ConsultationReturn.instance.clear();
      _fetch();
    }
  }

  @override
  void dispose() {
    ConsultRestore.instance.unregister(_restoreToken);
    _pageCtrl.dispose();
    super.dispose();
  }

  /// 画面復元スナップショット。履歴に保存済みのレコードを持つ時のみ非 null。
  /// 復元は必ず `fromRecord` (読み込み専用) で行うため、recordId のみ保存する。
  /// live モードで未保存 (fetch 中・失敗) なら null を返し、復元対象から外す
  /// (request で復元すると API 再実行＝クレジット二重消費になるため絶対にしない)。
  Map<String, dynamic>? _captureRestore() {
    String? id;
    if (widget.record != null) {
      id = widget.record!.id;
    } else if (_recordSavedAt != null) {
      // _persist() の採番ルール (id = savedAt.millisecondsSinceEpoch) と一致。
      id = _recordSavedAt!.millisecondsSinceEpoch.toString();
    }
    if (id == null) return null;
    return {'type': 'consultationResult', 'recordId': id};
  }

  Future<ConsultationV2Result> _runFetch(ConsultationRequest req) {
    if (widget.fetchOverride != null) return widget.fetchOverride!(req);
    return fetchConsultationV2(req);
  }

  Future<void> _fetch() async {
    final req = widget.request;
    if (req == null) return;
    setState(() {
      _loading = true;
      _error = null;
      _block = null;
    });
    // avoid-window スナップショットを開始時に固定 (以後の出し直しでも同じものを送る)。
    final key = _avoidKey;
    _avoid = key != null
        ? await SolaraStorage.getConsultationAvoid(key)
        : const <String>[];
    final result =
        await _runFetch(req.copyWith(isFirst: true, excluded: const [], avoid: _avoid));
    if (!mounted) return;
    if (result.isBlocked) {
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
        _error = t.consultResult.connError;
      });
      return;
    }
    setState(() {
      _readings
        ..clear()
        ..add(reading);
      _exhausted = reading.remainingAfter <= 0;
      _loading = false;
    });
    // クレジット消費が発生したので、ConsultationCredits.refresh() で最新残数を
    // 1 本の HTTP で取得 → singleton の notifyListeners で全画面 (Sanctuary 上部 /
    // 入力画面の開始ポップアップ等) が一気に更新される。
    // ignore: unawaited_futures
    ConsultationCredits.instance.refresh();
    // 提示した候補を avoid-window に積む (次回相談の無連続用・best-effort)。
    // ignore: unawaited_futures
    _pushShownToAvoid(reading);
    _persist();
  }

  /// 「別の候補地を見る」: excluded を足して次の候補を 1 つ取得し append する。
  Future<void> _loadNext() async {
    final req = widget.request;
    if (req == null) return;
    setState(() {
      _loadingNext = true;
      _error = null;
    });
    final excluded = _readings
        .map((r) => r.candidate.name)
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
    final result =
        await _runFetch(req.copyWith(isFirst: false, excluded: excluded, avoid: _avoid));
    if (!mounted) return;
    setState(() => _loadingNext = false);

    if (result.isExhausted) {
      // 案Y: 正直に止めて代替提案を出す (パネル表示)。クレジットは消費していない。
      setState(() {
        _exhausted = true;
        _showExhaustionPanel = true; // 出し直し由来の枯渇のみパネルを出す
        _exhaustedReason = result.exhaustedReason;
        _exhaustSuggestions = result.suggestions;
      });
      return;
    }
    if (result.isBlocked) {
      if (result.block == ConsultationBlock.creditExhausted) {
        await _onBuyCredits();
      } else {
        await showProUnlockDialog(
          context,
          featureLabel: t.consultResult.pro.consultLabel,
          description: t.consultResult.pro.consultDesc,
        );
      }
      return;
    }
    final reading = result.reading;
    if (reading == null) {
      _snack(t.consultResult.connError);
      return;
    }
    setState(() {
      _readings.add(reading);
      _exhausted = reading.remainingAfter <= 0 ||
          _readings.length >= _kMaxCandidates;
      _pageIndex = _readings.length - 1;
    });
    // 「別の候補地を見る」もクレジット消費なので singleton 経由で全画面更新。
    // ignore: unawaited_futures
    ConsultationCredits.instance.refresh();
    // 提示した候補を avoid-window に積む (次回相談の無連続用・best-effort)。
    // ignore: unawaited_futures
    _pushShownToAvoid(reading);
    if (_pageCtrl.hasClients) {
      _pageCtrl.animateToPage(
        _pageIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
    _persist();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// 「別の候補地」を出せるか (live・未尽き・上限未満・残りあり)。
  bool get _canLoadNext {
    if (widget.isHistory || _exhausted) return false;
    if (_readings.length >= _kMaxCandidates) return false;
    final last = _readings.isNotEmpty ? _readings.last : null;
    return last != null && last.remainingAfter > 0;
  }

  Future<void> _onBuyCredits() async {
    final bought = await showConsultationCreditSheet(context);
    if (!mounted) return;
    if (bought && _readings.isEmpty) _fetch();
  }

  void _showConsultationPaywall() {
    final (label, desc) = switch (_block) {
      ConsultationBlock.proOnlyMode => (
          t.consultResult.pro.migrationLabel,
          // 2026-05-29: タイル表記 (おでかけ・イベント) に合わせて文言統一。
          t.consultResult.pro.migrationDesc,
        ),
      ConsultationBlock.proOnlyRefresh => (
          t.consultResult.pro.refreshLabel,
          t.consultResult.pro.refreshDesc,
        ),
      _ => (
          t.consultResult.pro.weeklyLabel,
          t.consultResult.pro.weeklyDesc,
        ),
    };
    showProUnlockDialog(context, featureLabel: label, description: desc);
  }

  /// AppBar タイトルタップで「この読み解きについて」(内的季節+前置き+注記+
  /// 現在候補のエビデンス) を 1 枚のポップアップで表示。
  void _showAboutReading() {
    final f = _first;
    if (f == null) return;
    final cur = _pageIndex < _readings.length ? _readings[_pageIndex] : f;
    showInfoPopup(
      context: context,
      child: _AboutReadingContent(
        innerSeason: f.innerSeason,
        intro: f.intro,
        outro: f.outro,
        evidence: cur.evidence,
      ),
    );
  }

  Future<void> _persist() async {
    if (widget.isHistory) return;
    final req = widget.request;
    if (req == null || _readings.isEmpty) return;
    try {
      _recordSavedAt ??= DateTime.now().toUtc();
      final record = ConsultationRecord.fromReadings(
        theme: req.theme,
        mode: req.mode,
        scopeKind: req.scope?.kind ?? 'world',
        scopeDetail: widget.scopeDetail,
        // 2026-05-29: 履歴一覧に「いつ」(日付・期間・ホライズン・時間帯) を表示
        // できるよう ConsultationWhen を丸ごと保存する。
        when: req.when,
        withWhom: req.withWhom,
        wish: req.wish,
        readings: _readings,
        savedAt: _recordSavedAt,
      );
      await SolaraStorage.addConsultationRecord(record);
    } catch (_) {
      // 保存失敗は UX を妨げない (柱 3: 失敗してもユーザーは結果を読める)。
    }
  }

  /// 結果カードの🗺ボタン: Map タブへ移り、候補地を相談の日付でフォーカスする。
  /// 先にルート (タブ Scaffold) まで戻してから要求 → SolaraHome が Map タブへ切替。
  /// 日付導出 (おでかけ=指定日/旅行=初日/移住=時期) は map_focus の純関数に委譲。
  void _openCandidateOnMap(ConsultationV2Candidate c) {
    final w = widget.request?.when;
    final rec = widget.record;
    final date = w != null
        ? mapFocusDate(
            kind: w.kind, date: w.date, start: w.start, timeBand: w.timeBand)
        : rec != null
            ? mapFocusDate(
                kind: rec.whenKind, date: rec.whenDate,
                start: rec.whenStart, timeBand: rec.whenTimeBand)
            : null;
    // live セッションは「戻り導線」用に状態を退避 (Map 下部チップから fetch なしで
    // 再表示できる)。履歴は対象外 (履歴一覧からいつでも再開できるため)。
    if (!widget.isHistory && widget.request != null && _readings.isNotEmpty) {
      ConsultationReturn.instance.stash(ConsultationResumeState(
        request: widget.request!,
        readings: List<ConsultationV2Reading>.of(_readings),
        avoid: _avoid,
        recordSavedAt: _recordSavedAt,
        pageIndex: _pageIndex,
        scopeDetail: widget.scopeDetail,
      ));
    }
    Navigator.of(context).popUntil((r) => r.isFirst);
    MapFocus.instance.request(LatLng(c.lat, c.lng), date);
  }

  /// Pro 時刻指定 (おでかけ) の指定時刻 (端末ローカルの「時」0-23)。null = 時刻未指定。
  /// ライブ結果は request.when.atUtcMs、履歴は record.whenAtUtcMs から復元する。
  /// 結果カードの時間帯行に「15:00」のように指定時刻を出すために使う。
  int? get _specifiedHour {
    final ms = widget.request?.when?.atUtcMs ?? widget.record?.whenAtUtcMs;
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal().hour;
  }

  @override
  Widget build(BuildContext context) {
    final canShare = _readings.isNotEmpty && !_loading;
    return Scaffold(
      backgroundColor: SolaraColors.celestialBlueDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: SolaraColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: t.consultResult.back,
        ),
        // タイトルタップで「この読み解きについて」(エビデンス) を開く。
        // 2026-05-31: タップ領域が文字の実寸ぶんしかなく上下が狭かったため、
        // Padding で上下左右に判定を広げる (文字部分込みで広い当たり判定に)。
        title: GestureDetector(
          onTap: _readings.isNotEmpty ? _showAboutReading : null,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.consultResult.title,
                  style: const TextStyle(
                    color: SolaraColors.textPrimary,
                    fontSize: 16,
                    letterSpacing: 0.4,
                  ),
                ),
                if (_readings.isNotEmpty) ...[
                  const SizedBox(width: 3),
                  const Icon(Icons.expand_more,
                      size: 18, color: SolaraColors.textPrimary),
                ],
              ],
            ),
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
                : const Icon(Icons.ios_share, color: SolaraColors.textPrimary),
            tooltip: t.consultResult.shareTooltip,
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
    if (_block != null && _readings.isEmpty) {
      return _ConsultationBlockedBox(
        reason: _block!,
        onUpgrade: _showConsultationPaywall,
        onBuyCredits: _onBuyCredits,
      );
    }
    if (_error != null && _readings.isEmpty) {
      return _ErrorBox(message: _error!, onRetry: _fetch);
    }
    final first = _first;
    if (first == null) return const _LoadingSkeleton();

    final cur = _pageIndex >= 0 && _pageIndex < _readings.length
        ? _readings[_pageIndex]
        : null;

    return Column(
      children: [
        if (first.fallback) const _FallbackChip(),
        // 2026-05-26: 「今週の無料相談…」バナー (_FreeCreditsBanner) と
        // 「内的季節」バナー (_InnerSeasonBanner) を結果画面上部から撤去。
        // クレジット残は Sanctuary 上部 ＋ 入力画面の開始ポップアップで提示する。
        _PageIndicator(count: _readings.length, index: _pageIndex),
        Expanded(
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: _readings.length,
            onPageChanged: (i) {
              HapticFeedback.selectionClick();
              setState(() => _pageIndex = i);
            },
            itemBuilder: (ctx, i) => _CandidateCard(
              reading: _readings[i],
              onOpenMap: () => _openCandidateOnMap(_readings[i].candidate),
              specifiedHour: _specifiedHour,
            ),
          ),
        ),
        // おでかけ/近傍半径で近くの町が乏しいときのヒント (現在表示中の候補基準)。
        if (cur != null && cur.sparse) _SparseHint(nearbyCount: cur.nearbyCount),
        if (_canLoadNext)
          _RefreshButton(loading: _loadingNext, onTap: _loadingNext ? null : _loadNext),
        // 案Y: 出し直しで出し尽くしたときだけ正直に止めて代替提案を出す (クレジット非消費)。
        // 履歴閲覧・初回残数0 では _exhausted は立つが _showExhaustionPanel は立てない。
        if (_showExhaustionPanel)
          _ExhaustionPanel(reason: _exhaustedReason, suggestions: _exhaustSuggestions),
        const SizedBox(height: 16),
      ],
    );
  }
}
