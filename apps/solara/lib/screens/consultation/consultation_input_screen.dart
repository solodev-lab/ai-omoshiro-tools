// Consultation Input Screen — 5問モデル (V2: 全要素統合)
//
// 設計: project_solara_consultation_full_integration.md
//
// 設問順: ② 場面 → ③ いつ → ④ どこで → ① テーマ → ⑤ だれと → ⑥ 願い
//   - ② 場面 (必須): おでかけ / 旅行 / 移住 — ③④をプリセット
//   - ③ いつ (場面別): おでかけ=今日/日付 ・旅行=特定日/期間 ・移住=未定/日付/ホライズン
//   - ④ どこで (場面別): おでかけ=具体地点/方角/半径 ・旅行移住=具体地点/地域/自国内/半径/世界
//   - ① テーマ (必須)
//   - ⑤ だれと (任意・自由記述・Stella レンズ)
//   - ⑥ どうなりたい/願い (任意だが核・自由記述・Stella レンズ)
//
// 最小入力 (誕生+自宅+5問+preset) を ConsultationRequest にまとめ、結果画面が
// /protected/astro/consultation2 を叩く。client 候補生成は廃止 (Worker が全計算)。
//
// ファイル分割 (part-of パターン):
//   consultation_input_screen.dart      ← 本ファイル: orchestration + state
//   consultation_input_widgets.dart     ← 基本ウィジェット + 選択肢定数
//   consultation_input_when_scope.dart  ← いつ / 半径 セレクタ
//   consultation_input_examples.dart    ← だれと / 願い の記入例
//   consultation_input_picker.dart      ← 具体地点ピッカー (_SpecificPicker)
//   consultation_start_popup.dart       ← 開始ポップアップ (Free 残数)

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/solara_colors.dart';
import '../../utils/consultation_api.dart'
    show ConsultationCreditStatus, fetchConsultationCredits;
import '../../utils/consultation_v2_api.dart';
import '../../utils/pro_status.dart';
import '../../utils/solara_storage.dart';
import '../../widgets/info_popup.dart';
import '../../widgets/tap_to_unfocus.dart';
import '../map/map_search.dart' as map_search;
import '../map/map_vp_panel.dart';
import 'consultation_credit_sheet.dart';
import 'consultation_place_picker_screen.dart';
import 'consultation_result_screen.dart';

part 'consultation_input_widgets.dart';
part 'consultation_input_when_scope.dart';
part 'consultation_input_examples.dart';
part 'consultation_input_picker.dart';
part 'consultation_input_picker_widgets.dart';
part 'consultation_input_logic.dart';
part 'consultation_start_popup.dart';

/// Map から「📍この場所で相談」で起動した時の preset (point scope 用)。
class ConsultationPresetTarget {
  final LatLng position;
  final String nameJP;
  final String nameEN;
  final String country;
  final String region;

  /// 検索で店舗を選んだ場合の Google Places type (restaurant/cafe 等)。なければ null。
  final String? placeType;

  /// 地点の種類 (Worker placeReference 用)。'named'=検索の具体地点 (名前をそのまま使う) /
  /// 'saved'=登録地 / null=従来 (座標タップ等)。
  final String? placeKind;

  const ConsultationPresetTarget({
    required this.position,
    required this.nameJP,
    required this.nameEN,
    this.country = '',
    this.region = '',
    this.placeType,
    this.placeKind,
  });
}

class ConsultationInputScreen extends StatefulWidget {
  /// 現在地 (= 自宅)。具体地点ピッカーの初期中心・検索 bias に使う。
  final LatLng? currentLocation;

  /// Map から起動した場合の preset 地点 (scope=point を選びやすくする)。
  final ConsultationPresetTarget? presetTarget;

  const ConsultationInputScreen({
    super.key,
    this.currentLocation,
    this.presetTarget,
  });

  @override
  State<ConsultationInputScreen> createState() =>
      _ConsultationInputScreenState();
}

class _ConsultationInputScreenState extends State<ConsultationInputScreen> {
  // 5 つの問い (mode / theme は初期未選択。明示選択まで送信不可)
  String? _mode; // migration / travel / daily
  String? _theme;

  // ③ いつ
  String? _whenKind; // mode 別の UI キー
  String? _whenDate; // YYYY-MM-DD ('date')
  String? _whenStart; // YYYY-MM-DD ('range')
  String? _whenEnd; // YYYY-MM-DD ('range')
  String? _whenTimeBand; // 時間帯 (おでかけのみ・任意): morning/midday/evening/night/lateNight

  // ④ どこで
  String? _scopeKind; // point / bearing / radius / region / country / world
  double _radiusKm = 100;
  String _regionGroup = '日本';
  _PickedSpecific? _specificPick;

  final TextEditingController _whomCtrl = TextEditingController();
  final TextEditingController _wishCtrl = TextEditingController();

  /// 誕生/自宅データ (相談リクエストの土台)。
  SolaraProfile? _profile;

  /// 直近のクレジット状況 (Free のみ取得、開始ポップアップの残数表示用)。
  ConsultationCreditStatus? _creditStatus;

  /// 開始ポップアップを「次回以降表示しない」設定 (端末保存)。
  bool _startPopupHidden = false;
  static const _kStartPopupHiddenKey = 'consultation_start_popup_hidden';

  /// 自宅座標が設定済みか (方角/半径/自国内 scope に必須)。
  bool get _hasHome {
    final p = _profile;
    return p != null && !(p.homeLat == 0 && p.homeLng == 0);
  }

  @override
  void initState() {
    super.initState();
    if (widget.presetTarget != null) {
      _mode = 'travel';
      _scopeKind = 'point';
    }
    _loadPrefsAndProfile();
  }

  Future<void> _loadPrefsAndProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final hidden = prefs.getBool(_kStartPopupHiddenKey) ?? false;
    final profile = await SolaraStorage.loadProfile();
    if (!mounted) return;
    // プロフィールは先に反映 (submit 可否の土台)。クレジット残は後追いで埋める。
    setState(() {
      _startPopupHidden = hidden;
      _profile = profile;
    });
    if (!ProStatus.instance.isPro) {
      final status = await fetchConsultationCredits();
      if (mounted) setState(() => _creditStatus = status);
    }
  }

  @override
  void dispose() {
    _whomCtrl.dispose();
    _wishCtrl.dispose();
    super.dispose();
  }

  // ── ② 場面 ──────────────────────────────────────────────
  void _onModeChanged(String id) {
    setState(() {
      _mode = id;
      // 場面が変わると ③④ の選択肢が変わるのでリセット (preset 尊重)。
      _whenKind = _defaultWhenKind(id);
      _whenDate = null;
      _whenStart = null;
      _whenEnd = null;
      _whenTimeBand = null; // 場面変更で時間帯もリセット (おでかけ以外では非表示)
      if (widget.presetTarget != null || _specificPick != null) {
        _scopeKind = 'point';
      } else {
        _scopeKind = null;
      }
    });
  }

  String? _defaultWhenKind(String mode) {
    switch (mode) {
      case 'daily':
        return 'today';
      case 'migration':
        return 'undecided';
      default:
        return null; // travel は明示選択 (特定日 / 期間)
    }
  }

  // ── ③ いつ ──────────────────────────────────────────────
  Future<void> _onWhenKindTap(String key) async {
    if (key == 'date') {
      final picked = await _pickSingleDate();
      if (!mounted) return;
      if (picked == null) return; // キャンセル → 選択変更しない
      setState(() {
        _whenKind = 'date';
        _whenDate = picked;
      });
      return;
    }
    if (key == 'range') {
      final r = await _pickDateRange();
      if (!mounted) return;
      if (r == null) return;
      setState(() {
        _whenKind = 'range';
        _whenStart = r.$1;
        _whenEnd = r.$2;
      });
      return;
    }
    setState(() => _whenKind = key);
  }

  Future<String?> _pickSingleDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (picked == null) return null;
    return _ymd(picked);
  }

  Future<(String, String)?> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
      initialDateRange: DateTimeRange(start: now, end: now.add(const Duration(days: 3))),
    );
    if (picked == null) return null;
    return (_ymd(picked.start), _ymd(picked.end));
  }

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ── ④ どこで ────────────────────────────────────────────
  void _onScopeKindTap(String id) {
    setState(() {
      _scopeKind = id;
      // 半径のデフォルトは場面別 (おでかけ=50 / 旅行移住=100)。
      if (id == 'radius') {
        _radiusKm = _mode == 'daily' ? 50 : 100;
      }
    });
  }

  Future<_PickedSpecific?> _openMapPicker() async {
    final initialCenter =
        widget.currentLocation ?? widget.presetTarget?.position;
    final result = await Navigator.of(context).push<ConsultationPresetTarget>(
      MaterialPageRoute(
        builder: (_) => ConsultationPlacePickerScreen(
          initialCenter: initialCenter,
        ),
      ),
    );
    if (result == null) return null;
    return _PickedSpecific(
      position: result.position,
      name: result.nameJP,
      region: result.region,
      country: result.country,
    );
  }

  // ── 送信可否 ────────────────────────────────────────────
  bool get _canSubmit {
    if (_profile == null || (_profile!.birthDate).isEmpty) return false;
    if (_mode == null || _theme == null || _scopeKind == null) return false;
    // when の妥当性
    if (_whenKind == 'date' && _whenDate == null) return false;
    if (_whenKind == 'range' && (_whenStart == null || _whenEnd == null)) {
      return false;
    }
    // scope の妥当性
    switch (_scopeKind) {
      case 'point':
        if (widget.presetTarget == null && _specificPick == null) return false;
        break;
      case 'bearing':
      case 'radius':
      case 'country':
        if (!_hasHome) return false;
        break;
    }
    return true;
  }

  // リクエスト組み立て (_buildWhen/_buildScope/_scopeDetail) と
  // 開始フロー (_onStartPressed/_showStartPopup/_runConsultation) は
  // consultation_input_logic.dart (extension) に分離 (HARD500 回避)。

  Future<void> _handleBuyFromPopup() async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    final changed = await showConsultationCreditSheet(context);
    if (changed && mounted) {
      final s = await fetchConsultationCredits();
      if (mounted) setState(() => _creditStatus = s);
    }
  }

  Future<void> _setStartPopupHidden(bool v) async {
    _startPopupHidden = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kStartPopupHiddenKey, v);
  }

  @override
  Widget build(BuildContext context) {
    return TapToUnfocus(
      child: Scaffold(
        backgroundColor: SolaraColors.celestialBlueDark,
        // 背景は単色なので resize しても見た目は動かない。true にすると body が
        // キーボード分だけ縮み、フォーカスした下部入力欄 (だれと/願い) が
        // SingleChildScrollView 内で自動スクロールしてキーボード上に出る。
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            '相談する',
            style: TextStyle(
              color: SolaraColors.textPrimary,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: SolaraColors.textPrimary),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ② 場面
                      _Section(
                        label: 'どんな場面で？',
                        child: _ModeRow(selected: _mode, onSelect: _onModeChanged),
                      ),
                      // ③ いつ
                      if (_mode != null)
                        _Section(
                          label: 'いつ？',
                          child: _WhenSelector(
                            mode: _mode!,
                            selectedKind: _whenKind,
                            dateLabel: _whenLabel(),
                            onTapKind: _onWhenKindTap,
                          ),
                        ),
                      // ③' 時間帯 (おでかけのみ・任意)。昼の予定なのに朝/夜更けを
                      // 語られる白けを防ぐため、行く時間帯を Stella に伝える。
                      if (_mode == 'daily')
                        _Section(
                          label: '時間帯（任意）',
                          child: _TimeBandSelector(
                            selected: _whenTimeBand,
                            onTap: (b) => setState(() =>
                                _whenTimeBand = _whenTimeBand == b ? null : b),
                          ),
                        ),
                      // ④ どこで
                      if (_mode != null)
                        _Section(
                          label: 'どこで？',
                          child: _ScopeWrap(
                            selected: _scopeKind,
                            onSelect: _onScopeKindTap,
                            choices: _scopeChoicesFor(_mode!),
                          ),
                        ),
                      if (_scopeKind == 'radius')
                        _Section(
                          label: '自宅からの距離',
                          child: _RadiusChips(
                            options: _mode == 'daily'
                                ? const [50, 100, 300]
                                : const [100, 300, 500],
                            selected: _radiusKm,
                            onSelect: (km) => setState(() => _radiusKm = km),
                          ),
                        ),
                      if (_scopeKind == 'region')
                        _Section(
                          label: '地域ブロック',
                          child: _RegionPicker(
                            selected: _regionGroup,
                            onSelect: (g) => setState(() => _regionGroup = g),
                          ),
                        ),
                      if (_scopeKind == 'point' && widget.presetTarget == null)
                        _Section(
                          label: '地点を選ぶ',
                          child: _SpecificPicker(
                            selected: _specificPick,
                            biasCenter: widget.currentLocation,
                            onSelect: (p) => setState(() => _specificPick = p),
                            onClear: () => setState(() => _specificPick = null),
                            onOpenMapPicker: _openMapPicker,
                          ),
                        ),
                      if (_scopeKind == 'point' && widget.presetTarget != null)
                        _PresetLocationCard(target: widget.presetTarget!),
                      if (!_hasHome && _mode != null)
                        const _NoHomeNote(),
                      // ① テーマ
                      _Section(
                        label: '何のテーマで観たい？',
                        child: _ThemeGrid(
                          selected: _theme,
                          onSelect: (id) => setState(() => _theme = id),
                        ),
                      ),
                      // ⑤ だれと
                      _Section(
                        label: 'だれと？（任意）',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FreeTextField(
                              controller: _whomCtrl,
                              hint: '例: 妻と / ひとりで / 気になる人と',
                              maxLines: 2,
                              maxLength: 80,
                            ),
                            _WhomExamples(
                              theme: _theme,
                              onPick: (t) => setState(() => _whomCtrl.text = t),
                            ),
                          ],
                        ),
                      ),
                      // ⑥ 願い
                      _Section(
                        label: 'どうなりたい？／願い（任意）',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FreeTextField(
                              controller: _wishCtrl,
                              hint: '今いちばん大切にしたい気持ちを一言で',
                              maxLines: 3,
                              maxLength: 200,
                            ),
                            _WishExamples(
                              theme: _theme,
                              onPick: (t) => setState(() => _wishCtrl.text = t),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              _SubmitBar(enabled: _canSubmit, onSubmit: _onStartPressed),
            ],
          ),
        ),
      ),
    );
  }

  /// ③ で選んだ日付/期間の表示ラベル (選択チップの下に出す)。
  String? _whenLabel() {
    if (_whenKind == 'date') return _whenDate;
    if (_whenKind == 'range' && _whenStart != null && _whenEnd != null) {
      return '$_whenStart 〜 $_whenEnd';
    }
    return null;
  }
}
