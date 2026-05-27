// Consultation Input — リクエスト組み立て + 開始フロー (extension)
// (part of 'consultation_input_screen.dart')
//
// State 本体 (consultation_input_screen.dart) の HARD500 回避のため、
// setState を呼ばない純ロジック (when/scope → ConsultationRequest、開始ポップアップ、
// 結果画面遷移) を extension に分離。

part of 'consultation_input_screen.dart';

extension _ConsultationInputLogic on _ConsultationInputScreenState {
  // ── リクエスト組み立て ──────────────────────────────────
  ConsultationWhen? _buildWhen() {
    // 時間帯はおでかけ (daily) のときだけ付ける。
    final tb = _mode == 'daily' ? _whenTimeBand : null;
    switch (_whenKind) {
      case 'date':
        return _whenDate == null
            ? null
            : ConsultationWhen.onDate(_whenDate!, timeBand: tb);
      case 'range':
        return (_whenStart == null || _whenEnd == null)
            ? null
            : ConsultationWhen.range(_whenStart!, _whenEnd!);
      case 'within6mo':
      case 'within1yr':
      case 'in3yr':
      case 'in5yrPlus':
        return ConsultationWhen.horizon(_whenKind!);
      default:
        // today / undecided / null。おでかけで時間帯だけ指定されたら、今日の
        // 日付に時間帯を載せて送る (Worker が時間帯を語りの主役にできるよう)。
        if (_whenKind == 'today' && tb != null) {
          final now = DateTime.now();
          final todayStr =
              '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
          return ConsultationWhen.onDate(todayStr, timeBand: tb);
        }
        return null;
    }
  }

  ConsultationScope? _buildScope() {
    switch (_scopeKind) {
      case 'point':
        final pt = widget.presetTarget;
        if (pt != null) {
          return ConsultationScope.point(ConsultationPoint(
            lat: pt.position.latitude,
            lng: pt.position.longitude,
            name: pt.nameJP,
            placeType: pt.placeType,
            placeKind: pt.placeKind,
          ));
        }
        final pick = _specificPick;
        if (pick != null) {
          return ConsultationScope.point(ConsultationPoint(
            lat: pick.position.latitude,
            lng: pick.position.longitude,
            name: pick.name,
            placeKind: pick.placeKind,
          ));
        }
        return null;
      case 'bearing':
        return ConsultationScope.bearing(radiusKm: _mode == 'daily' ? 50 : 100);
      case 'radius':
        return ConsultationScope.radius(_radiusKm);
      case 'region':
        return ConsultationScope.region(_regionGroup);
      case 'country':
        return ConsultationScope.country();
      default:
        return ConsultationScope.world();
    }
  }

  /// scope の詳細ラベル (履歴カード用)。region=グループ名 / point=地点名。
  String? get _scopeDetail {
    switch (_scopeKind) {
      case 'region':
        return _regionGroup;
      case 'point':
        return widget.presetTarget?.nameJP ?? _specificPick?.name;
      default:
        return null;
    }
  }

  // ── 開始 ────────────────────────────────────────────────
  // 2026-05-27: Pro 週次キャップ導入に合わせて Pro も popup 対象化 (旧: Pro 即時スキップ)。
  // 「次回以降表示しない」を一度押せば以降は Pro/Free とも自動スキップ = 既存 UX を維持。
  // 初回ユーザーや「気にしたい」Pro ユーザーには Pro 週次残 (例: 87/100) が伝わる。
  Future<void> _onStartPressed() async {
    if (_startPopupHidden) {
      await _runConsultation();
      return;
    }
    final proceed = await _showStartPopup();
    if (proceed) await _runConsultation();
  }

  /// 開始ポップアップから「クレジットを購入」が押されたときの処理。
  /// State 本体に置くと HARD500 を超えるため extension 側に置き、
  /// 残数更新は _refreshCreditsFresh（State 本体・setState 持ち）に委譲する。
  Future<void> _handleBuyFromPopup() async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    final changed = await showConsultationCreditSheet(context);
    if (changed) await _refreshCreditsFresh();
  }

  Future<bool> _showStartPopup() async {
    // 表示直前にサーバー側の最新クレジット残を取り直す（結果画面から戻った直後 /
    // 購入直後など、ConsultationCredits.status が古いままだと「残り 0/3」のような
    // 古い数値が出てしまう問題を回避）。in-flight dedup されるので、並行画面が
    // 同時に refresh しても HTTP は 1 本にまとまる。
    await _refreshCreditsFresh();
    if (!mounted) return false;
    var proceed = false;
    await showInfoPopup(
      context: context,
      child: _StartConsultPopup(
        initialHide: _startPopupHidden,
        onContinue: () => proceed = true,
        onBuy: _handleBuyFromPopup,
        onHideChanged: _setStartPopupHidden,
      ),
    );
    return proceed;
  }

  Future<void> _runConsultation() async {
    final profile = _profile;
    final theme = _theme;
    final mode = _mode;
    if (profile == null || theme == null || mode == null) return;

    final request = ConsultationRequest.fromProfile(
      profile,
      theme: theme,
      mode: mode,
      when: _buildWhen(),
      scope: _buildScope(),
      withWhom: _whomCtrl.text.trim(),
      wish: _wishCtrl.text.trim(),
    );

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConsultationResultScreen(
          request: request,
          scopeDetail: _scopeDetail,
        ),
      ),
    );
  }
}
