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
    switch (_whenKind) {
      case 'date':
        return _whenDate == null ? null : ConsultationWhen.onDate(_whenDate!);
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
        return null; // today / undecided / null
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
          ));
        }
        final pick = _specificPick;
        if (pick != null) {
          return ConsultationScope.point(ConsultationPoint(
            lat: pick.position.latitude,
            lng: pick.position.longitude,
            name: pick.name,
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
  Future<void> _onStartPressed() async {
    if (ProStatus.instance.isPro || _startPopupHidden) {
      await _runConsultation();
      return;
    }
    final proceed = await _showStartPopup();
    if (proceed) await _runConsultation();
  }

  Future<bool> _showStartPopup() async {
    var proceed = false;
    await showInfoPopup(
      context: context,
      child: _StartConsultPopup(
        status: _creditStatus,
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
