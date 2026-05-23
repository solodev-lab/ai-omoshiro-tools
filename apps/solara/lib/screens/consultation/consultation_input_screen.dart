// Consultation Input Screen — Stage 1 UI
//
// 設計: apps/solara/docs/pro_candidates.md §7.2 Stage 1
//
// 入力フォーム:
//   - モード 3 択 (migration / travel / daily=おでかけ)
//   - テーマ 6 チップ単一選択 (love/money/work/communication/healing/newStart)
//   - 地理スコープ 3 択 (specific / region / world)
//     ※ daily モードは scope=bearings に自動固定
//   - 範囲指定モード時: 大ブロック region picker (日本/北米/ヨーロッパ/...)
//   - 自由記述 (任意、テキストエリア)
//   - 「相談を始める」ボタン
//
// 入力完了 → Stage 2 エンジンで候補生成 → ConsultationResultScreen を push。
//
// ファイル分割 (Solara の horoscope_screen.dart と同じ part-of パターン):
//   - 本ファイル: orchestration + state management
//   - consultation_input_widgets.dart:  選択肢定数 + Choice classes + 基本サブウィジェット
//   - consultation_input_examples.dart: 相談例 (theme × mode × scope = 54 例文)
//   - consultation_input_picker.dart:   _PickedSpecific + _SpecificPicker 系

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/solara_colors.dart';
import '../../utils/astro_lines.dart' as al;
import '../../utils/consultation_api.dart';
import '../../utils/consultation_engine.dart' as ce;
import '../../utils/pro_status.dart';
import '../../utils/world_cities.dart';
import '../../widgets/info_popup.dart';
import '../../widgets/tap_to_unfocus.dart';
import '../map/map_search.dart' as map_search;
import '../map/map_vp_panel.dart';
import 'consultation_credit_sheet.dart';
import 'consultation_place_picker_screen.dart';
import 'consultation_result_screen.dart';

part 'consultation_input_widgets.dart';
part 'consultation_input_examples.dart';
part 'consultation_input_picker.dart';
part 'consultation_start_popup.dart';

/// Map から「📍この場所で相談」で起動した時の preset (specific scope 用)。
class ConsultationPresetTarget {
  final LatLng position;
  final String nameJP;
  final String nameEN;
  final String country;
  final String region;

  const ConsultationPresetTarget({
    required this.position,
    required this.nameJP,
    required this.nameEN,
    this.country = '',
    this.region = '',
  });
}

class ConsultationInputScreen extends StatefulWidget {
  /// すでに計算済の AstroLine リスト。caller (Map / Sanctuary 等) が
  /// mode に応じた frame (natal / transit / progressed / solarArc) を選んで渡す。
  final List<al.AstroLine> astroLines;

  /// 現在地。daily モードで必須、specific モードでデフォルト位置として使う。
  final LatLng? currentLocation;

  /// Map から起動した場合の preset 地点 (scope=specific を選びやすくする)。
  final ConsultationPresetTarget? presetTarget;

  const ConsultationInputScreen({
    super.key,
    required this.astroLines,
    this.currentLocation,
    this.presetTarget,
  });

  @override
  State<ConsultationInputScreen> createState() =>
      _ConsultationInputScreenState();
}

class _ConsultationInputScreenState extends State<ConsultationInputScreen> {
  // mode / scope は初期選択なし (null = 未選択)。ユーザーが明示的に選ぶまで
  // 「相談を始める」は無効。preset 起動時のみ travel / specific を初期採用する。
  String? _mode;
  String? _theme;
  String? _scope;
  String _regionGroup = '日本';

  /// 具体地点スコープでユーザーが picker (inline / Map) から選んだ地点。
  /// presetTarget があるときはそちらを優先し、本フィールドは無視する。
  _PickedSpecific? _specificPick;

  /// 直近のクレジット状況 (Free のみ取得、開始ポップアップの残数表示用)。
  ConsultationCreditStatus? _creditStatus;

  /// 開始ポップアップを「次回以降表示しない」設定 (端末保存)。
  bool _startPopupHidden = false;
  static const _kStartPopupHiddenKey = 'consultation_start_popup_hidden';

  final TextEditingController _freeTextCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // preset target がある場合は specific スコープ + 旅行モードを推奨デフォルト。
    if (widget.presetTarget != null) {
      _scope = 'specific';
      _mode = 'travel';
    }
    _loadPrefsAndCredits();
  }

  /// 「次回以降表示しない」設定の読込 + Free ユーザーのクレジット残数取得。
  Future<void> _loadPrefsAndCredits() async {
    final prefs = await SharedPreferences.getInstance();
    final hidden = prefs.getBool(_kStartPopupHiddenKey) ?? false;
    ConsultationCreditStatus? status;
    if (!ProStatus.instance.isPro) {
      status = await fetchConsultationCredits();
    }
    if (!mounted) return;
    setState(() {
      _startPopupHidden = hidden;
      _creditStatus = status;
    });
  }

  @override
  void dispose() {
    _freeTextCtrl.dispose();
    super.dispose();
  }

  void _onModeChanged(String id) {
    setState(() {
      _mode = id;
      // scope 未選択 (null) のときは触らない。ユーザーに範囲を明示選択させる
      // (初期選択なし方針)。
      if (_scope == null) return;
      // mode 切替時の scope 補正は「新モードで使えない scope なら有効値へ」
      // のみ。それ以外 (specific / region) は現状維持し、ユーザーの選択を尊重する。
      //
      // 旧仕様 (2026-05-16 修正前) では非 daily→daily で常に bearings に強制
      // 切替していたが、Map タップで preset 入りの specific スコープに来た
      // ユーザーが mode を「おでかけ」に変えると地点選択が消える UX 上の問題が
      // あり撤回。preset がある時は specific を尊重する。
      final validScopes =
          _scopeChoicesFor(id).map((c) => c.id).toSet();
      if (validScopes.contains(_scope)) return;

      // 現 scope が新モードで使えない場合のフォールバック:
      //   preset/specificPick があるなら specific を最優先
      //   それ以外は: daily ← bearings (現在地基点が主流) / 非 daily ← world (世界規模が広い)
      if (widget.presetTarget != null || _specificPick != null) {
        _scope = 'specific';
      } else {
        _scope = id == 'daily' ? 'bearings' : 'world';
      }
    });
  }

  /// region group → 国コード集合 (worldCityRegionGroups を反転)
  Set<String> _resolveRegionCountries(String group) {
    return worldCityRegionGroups.entries
        .where((e) => e.value == group)
        .map((e) => e.key)
        .toSet();
  }

  /// Submit 可否。
  /// - theme 必須
  /// - specific スコープ時は presetTarget OR _specificPick が必須 (currentLocation の
  ///   自動採用は廃止。明示選択を要求して「勝手に現在地が選ばれている」UX を排除)
  /// - bearings スコープ時は currentLocation 必須 (現在地が方角計算の起点)
  bool get _canSubmit {
    if (_theme == null) return false;
    // 初期選択なし方針: 場面 (mode) と範囲 (scope) を明示選択するまで送信不可。
    if (_mode == null) return false;
    if (_scope == null) return false;
    if (_scope == 'bearings' && widget.currentLocation == null) return false;
    if (_scope == 'specific' &&
        widget.presetTarget == null &&
        _specificPick == null) {
      return false;
    }
    return true;
  }

  /// scope に応じて候補生成関数を構築する。
  Future<List<ce.CandidateLocation>> Function(List<String>)
      _buildRegenerator(List<al.AstroLine> themeLines) {
    switch (_scope) {
      case 'specific':
        final pt = widget.presetTarget;
        final pick = _specificPick;
        return (_) async {
          if (pt != null) {
            return [
              ce.candidateForSpecific(
                target: pt.position,
                nameJP: pt.nameJP,
                nameEN: pt.nameEN,
                country: pt.country,
                region: pt.region,
                themeLines: themeLines,
              ),
            ];
          }
          if (pick != null) {
            return [
              ce.candidateForSpecific(
                target: pick.position,
                nameJP: pick.name,
                nameEN: pick.name,
                country: pick.country,
                region: pick.region,
                themeLines: themeLines,
              ),
            ];
          }
          // ここに到達するのは _canSubmit が間違ったときだけ。空配列で UI 側のエラー表示に委ねる。
          return const [];
        };
      case 'region':
        final countries = _resolveRegionCountries(_regionGroup);
        return (excl) async => ce.candidatesForRegion(
              themeLines: themeLines,
              countries: countries,
              excludeNames: excl,
            );
      case 'world':
        return (excl) async => ce.candidatesForWorld(
              themeLines: themeLines,
              excludeNames: excl,
            );
      case 'bearings':
        final cur = widget.currentLocation!;
        return (excl) async => ce.candidatesForDaily(
              currentLocation: cur,
              themeLines: themeLines,
              excludeNames: excl,
            );
      default:
        return (_) async => const [];
    }
  }

  /// 「🗺 地図で選ぶ」 → B = ConsultationPlacePickerScreen を push し、選択結果を取得する。
  /// キャンセル時は null を返す。
  Future<_PickedSpecific?> _openMapPicker() async {
    final initialCenter = widget.currentLocation ??
        (widget.presetTarget?.position);
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

  /// 「相談を始める」押下時のエントリ。
  /// Pro = 無制限なのでポップアップ無しで即実行。
  /// Free = 開始ポップアップ (残数 + 補充案内 + 購入導線) を挟む。
  ///        「次回以降表示しない」設定済みならスキップして即実行。
  Future<void> _onStartPressed() async {
    if (ProStatus.instance.isPro || _startPopupHidden) {
      await _runConsultation();
      return;
    }
    final proceed = await _showStartPopup();
    if (proceed) await _runConsultation();
  }

  /// 開始ポップアップを表示。続行ボタンで true を返す (× / 外タップ / 購入は false)。
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

  /// ポップアップの「クレジットを購入」→ 購入シートを開く (popup は閉じ済み)。
  Future<void> _handleBuyFromPopup() async {
    // popup の pop と購入シートの push を競合させないため次フレームへ。
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    final changed = await showConsultationCreditSheet(context);
    if (changed && mounted) {
      final s = await fetchConsultationCredits();
      if (mounted) setState(() => _creditStatus = s);
    }
  }

  /// 「次回以降表示しない」チェックの保存。
  Future<void> _setStartPopupHidden(bool v) async {
    _startPopupHidden = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kStartPopupHiddenKey, v);
  }

  Future<void> _runConsultation() async {
    final theme = _theme;
    if (theme == null) return;
    final themeLines = ce.filterThemeLines(widget.astroLines, theme);
    final regen = _buildRegenerator(themeLines);
    final initial = await regen(const <String>[]);

    if (!mounted) return;
    if (initial.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('候補が見つかりませんでした。'),
        ),
      );
      return;
    }

    // specific scope = 1 候補のみ、refresh 不可
    final regenForResult = _scope == 'specific' ? null : regen;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConsultationResultScreen(
          theme: theme,
          mode: _mode!,
          scope: _scope!,
          freeText: _freeTextCtrl.text.trim(),
          initialCandidates: initial,
          regenerateCandidates: regenForResult,
          // 履歴カードのスコープ横ラベル用に「範囲指定」の大ブロック名を持ち回す。
          scopeDetail: _scope == 'region' ? _regionGroup : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TapToUnfocus(
      child: Scaffold(
      backgroundColor: SolaraColors.celestialBlueDark,
      // 🔴 (2026-05-19) キーボードで背景がずれないよう false 統一。
      resizeToAvoidBottomInset: false,
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
                    _Section(
                      label: '何のテーマで観たい？',
                      child: _ThemeGrid(
                        selected: _theme,
                        onSelect: (id) => setState(() => _theme = id),
                      ),
                    ),
                    _Section(
                      // サブタイトル変更 (2026-05-16):
                      // 旧「どの距離感で？」は 3 モード (移住/旅行/おでかけ) が
                      // 「距離」というより「場面」を指すので、より直感的な文言へ。
                      label: 'どんな場面で？',
                      child: _ModeRow(
                        selected: _mode,
                        onSelect: _onModeChanged,
                      ),
                    ),
                    // 範囲 (scope) 選択: モード別に選択肢を切替
                    //   - daily:     具体地点 / 方角ベース / 範囲指定
                    //   - 他モード:   具体地点 / 範囲指定 / 世界全体
                    // 場面 (mode) を選ぶまでは非表示 (scope 選択肢が mode 依存のため)。
                    if (_mode != null)
                      _Section(
                        label: '範囲は？',
                        child: _ScopeRow(
                          selected: _scope,
                          onSelect: (id) => setState(() => _scope = id),
                          choices: _scopeChoicesFor(_mode!),
                        ),
                      ),
                    // 地域ブロックピッカーは scope='region' のとき (mode 関係なく)
                    if (_scope == 'region')
                      _Section(
                        label: '地域ブロック',
                        child: _RegionPicker(
                          selected: _regionGroup,
                          onSelect: (g) =>
                              setState(() => _regionGroup = g),
                        ),
                      ),
                    // 具体地点ピッカー (A inline): preset がない specific スコープ専用。
                    // preset があるときは下の _PresetLocationCard で「✓ ... を見ます」を出す。
                    // mode に依存せず scope='specific' なら表示 (daily も対応)。
                    if (_scope == 'specific' &&
                        widget.presetTarget == null)
                      _Section(
                        label: '地点を選ぶ',
                        child: _SpecificPicker(
                          selected: _specificPick,
                          biasCenter: widget.currentLocation,
                          onSelect: (p) =>
                              setState(() => _specificPick = p),
                          onClear: () =>
                              setState(() => _specificPick = null),
                          onOpenMapPicker: _openMapPicker,
                        ),
                      ),
                    _Section(
                      label: '自由記述（任意）',
                      child: _FreeTextField(
                        controller: _freeTextCtrl,
                      ),
                    ),
                    // 相談例 (テーマ × モード × スコープで 3 つ提示、タップで自由記述に反映)。
                    // scope 別に文脈が変わる:
                    //   specific = 具体地名が決まっている前提
                    //   region/world = 範囲は決まっているが場所はまだ
                    //   bearings (daily 専用) = 行き先を決め打たず方角を相談
                    _Section(
                      label: 'こんな相談ができそう',
                      child: _ConsultExamples(
                        theme: _theme,
                        mode: _mode,
                        scope: _scope,
                        onPick: (text) => setState(() {
                          _freeTextCtrl.text = text;
                          _freeTextCtrl.selection = TextSelection.fromPosition(
                            TextPosition(offset: text.length),
                          );
                        }),
                      ),
                    ),
                    if (widget.presetTarget != null && _scope == 'specific')
                      _PresetLocationCard(target: widget.presetTarget!),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            // 無料クレジットの案内は「相談を始める」押下時の開始ポップアップに集約
            // (consultation_start_popup.dart)。画面下の常設注記は廃止。
            _SubmitBar(
              enabled: _canSubmit,
              onSubmit: _onStartPressed,
            ),
          ],
        ),
      ),
      ),
    );
  }
}
