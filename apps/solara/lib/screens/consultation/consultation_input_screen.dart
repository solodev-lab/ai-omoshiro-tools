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
import '../../utils/consult_restore.dart';
import '../../utils/consultation_credits.dart';
import '../../utils/consultation_v2_api.dart';
import '../../utils/pro_status.dart';
import '../../utils/solara_storage.dart';
import '../../widgets/info_popup.dart';
import '../../widgets/pro_unlock_dialog.dart';
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

  /// 画面復元 (Android プロセス死対策) 用。コールド起動時に SolaraHome が
  /// 直前のフォーム状態を渡して再構築する。通常起動は null。
  final Map<String, dynamic>? restoreForm;

  const ConsultationInputScreen({
    super.key,
    this.currentLocation,
    this.presetTarget,
    this.restoreForm,
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
  int? _whenHour; // Pro 時刻指定 (おでかけのみ・任意): 0〜23 時。set 時 atUtcMs を送り 30 分後デルタ有効

  // ④ どこで
  String? _scopeKind; // point / bearing / radius / region / country / world
  double _radiusKm = 100;
  String _regionGroup = '日本';
  _PickedSpecific? _specificPick;

  final TextEditingController _whomCtrl = TextEditingController();
  final TextEditingController _wishCtrl = TextEditingController();

  /// 誕生/自宅データ (相談リクエストの土台)。
  SolaraProfile? _profile;

  /// 開始ポップアップを「次回以降表示しない」設定 (端末保存)。
  bool _startPopupHidden = false;
  static const _kStartPopupHiddenKey = 'consultation_start_popup_hidden';

  /// 自宅座標が設定済みか (方角/半径/自国内 scope に必須)。
  bool get _hasHome {
    final p = _profile;
    return p != null && !(p.homeLat == 0 && p.homeLng == 0);
  }

  /// 画面復元 (Android プロセス死対策) レジストリ登録トークン。
  late final Object _restoreToken;

  @override
  void initState() {
    super.initState();
    // 2026-05-29: どの経路から入っても初期選択なし (mode / scope ともに null)。
    // 旧実装は preset 経由 (Map ピンの「ここで相談」等) で travel + point を
    // 自動セットしていたが、ユーザーが「何を相談したいか」を意識的に選ぶ前に
    // tile が active 化すると入力品質が下がるため初期選択を撤廃。
    // ※ preset の地点情報は `_buildScope()` 内で widget.presetTarget を参照する
    //   ため、ユーザーが mode を選んだ後に scope='point' に進めばそのまま反映される。
    // 画面復元: コールド起動時はフォーム状態を先に復元 (profile は別途 async で load)。
    if (widget.restoreForm != null) {
      _applyRestoreForm(widget.restoreForm!);
    }
    // 押下ルート復元の登録。SolaraHome が paused 時に _captureRestore を pull する。
    _restoreToken = ConsultRestore.instance.register(_captureRestore);
    _loadPrefsAndProfile();
    // 注: 本画面は build() で ConsultationCredits を直接参照しないので listener は不要。
    // 残数表示は開始ポップアップ (_StartConsultPopup) が自前で listener を持つ。
  }

  /// 画面復元スナップショット (Android プロセス死対策)。入力画面は mount 中は常に
  /// 復元対象 (空でも「相談入力画面にいた」状態を戻す)。具体地点は presetTarget /
  /// _specificPick のどちらでも、有効点を単一の `point` に正規化して保存し、
  /// 復元時は _specificPick として再構築する (_buildScope は両方を point として扱う)。
  Map<String, dynamic>? _captureRestore() {
    final pt = widget.presetTarget;
    final pick = _specificPick;
    Map<String, dynamic>? point;
    if (pt != null) {
      point = {
        'lat': pt.position.latitude,
        'lng': pt.position.longitude,
        'name': pt.nameJP,
        'region': pt.region,
        'country': pt.country,
        'placeKind': pt.placeKind ?? 'named',
      };
    } else if (pick != null) {
      point = {
        'lat': pick.position.latitude,
        'lng': pick.position.longitude,
        'name': pick.name,
        'region': pick.region,
        'country': pick.country,
        'placeKind': pick.placeKind,
      };
    }
    return {
      'type': 'consultationInput',
      'mode': _mode,
      'theme': _theme,
      'whenKind': _whenKind,
      'whenDate': _whenDate,
      'whenStart': _whenStart,
      'whenEnd': _whenEnd,
      'whenTimeBand': _whenTimeBand,
      'whenHour': _whenHour,
      'scopeKind': _scopeKind,
      'radiusKm': _radiusKm,
      'regionGroup': _regionGroup,
      'whom': _whomCtrl.text,
      'wish': _wishCtrl.text,
      'point': point,
    };
  }

  /// 復元スナップショットからフォーム状態を再構築する (initState から同期で呼ぶ)。
  void _applyRestoreForm(Map<String, dynamic> f) {
    _mode = f['mode'] as String?;
    _theme = f['theme'] as String?;
    _whenKind = f['whenKind'] as String?;
    _whenDate = f['whenDate'] as String?;
    _whenStart = f['whenStart'] as String?;
    _whenEnd = f['whenEnd'] as String?;
    _whenTimeBand = f['whenTimeBand'] as String?;
    _whenHour = (f['whenHour'] as num?)?.toInt();
    _scopeKind = f['scopeKind'] as String?;
    _radiusKm = (f['radiusKm'] as num?)?.toDouble() ?? _radiusKm;
    _regionGroup = f['regionGroup'] as String? ?? _regionGroup;
    _whomCtrl.text = f['whom'] as String? ?? '';
    _wishCtrl.text = f['wish'] as String? ?? '';
    final p = f['point'];
    if (p is Map) {
      _specificPick = _PickedSpecific(
        position: LatLng(
          (p['lat'] as num).toDouble(),
          (p['lng'] as num).toDouble(),
        ),
        name: p['name'] as String? ?? '',
        region: p['region'] as String? ?? '',
        country: p['country'] as String? ?? '',
        placeKind: p['placeKind'] as String? ?? 'named',
      );
    }
  }

  Future<void> _loadPrefsAndProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final hidden = prefs.getBool(_kStartPopupHiddenKey) ?? false;
    final profile = await SolaraStorage.loadProfile();
    if (!mounted) return;
    setState(() {
      _startPopupHidden = hidden;
      _profile = profile;
    });
  }

  @override
  void dispose() {
    ConsultRestore.instance.unregister(_restoreToken);
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
      _whenHour = null; // 時刻指定もリセット
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

  /// Pro: 時刻ドラム (1 時間刻み) を開いて _whenHour を設定。選んだ時刻から
  /// 語りのバンド (_whenTimeBand) も自動導出して一致させる (geometry=時刻 / 語り=バンド)。
  Future<void> _pickHour() async {
    final picked = await showConsultationHourPicker(context, _whenHour ?? 15);
    if (!mounted || picked == null) return;
    setState(() {
      _whenHour = picked;
      _whenTimeBand = bandFromHour(picked);
    });
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

  /// 開始ポップアップ表示直前 / 購入後など、サーバー側の最新クレジット残を取り直す。
  /// ConsultationCredits.instance.refresh() (in-flight dedup あり) に委譲し、
  /// notifyListeners 経由で本 State も rebuild される。State 本体に残しているのは
  /// 「Pro なら skip」のロジックを 1 箇所にまとめるため + 既存 API 互換維持のため。
  Future<void> _refreshCreditsFresh() async {
    if (ProStatus.instance.isPro) return;
    await ConsultationCredits.instance.refresh();
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
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '相談する',
                style: TextStyle(
                  color: SolaraColors.textPrimary,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 6),
              // i ボタン: この機能の詳しい説明 (読み解くデータ + 開発者より)。
              GestureDetector(
                onTap: () => showConsultAboutPopup(context),
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.help_outline,
                      size: 18, color: SolaraColors.textSecondary),
                ),
              ),
            ],
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
                      // タイトル下の簡単説明 (この機能で何ができるか)。
                      const _ConsultIntroNote(),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _TimeBandSelector(
                                selected: _whenTimeBand,
                                onTap: (b) => setState(() {
                                  _whenTimeBand = _whenTimeBand == b ? null : b;
                                  _whenHour = null; // 手動バンドは時刻指定と排他
                                }),
                              ),
                              const SizedBox(height: 10),
                              // Pro: 1 時間刻みの時刻指定 (おでかけ/イベント)。選ぶと結果画面で
                              // 「30分経過後を見る」が出る。Free はタップで Pro 案内。
                              _TimeHourRow(
                                isPro: ProStatus.instance.isPro,
                                hour: _whenHour,
                                onPick: _pickHour,
                                onClear: () =>
                                    setState(() => _whenHour = null),
                                onLockedTap: () => showProUnlockDialog(
                                  context,
                                  featureLabel: 'おでかけの時刻指定 + 30分後の変化',
                                  description:
                                      '行く時刻を1時間刻みで指定でき、その場の流れが'
                                      '「30分後どう変わるか」まで読めます。CCGの線は地球の'
                                      '自転で動くので、同じ場所でも前半と後半で主役が入れ替わります。',
                                ),
                              ),
                            ],
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
                          label: _mode == 'daily'
                              ? '現住所からの距離'
                              : '現住所からの距離帯',
                          child: _RadiusChips(
                            options: _mode == 'daily'
                                ? const [20, 50, 100, 300]
                                : const [100, 300, 500],
                            selected: _radiusKm,
                            onSelect: (km) => setState(() => _radiusKm = km),
                            // 旅行/移住はバンド表示 (50〜100km 等)。おでかけは「Nkm」。
                            bandMinFor: _mode == 'daily' ? null : _travelBandMin,
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
