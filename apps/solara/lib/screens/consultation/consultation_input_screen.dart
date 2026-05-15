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

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../theme/solara_colors.dart';
import '../../utils/astro_lines.dart' as al;
import '../../utils/consultation_engine.dart' as ce;
import '../../utils/world_cities.dart';
import 'consultation_result_screen.dart';

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

// テーマ定義 (id, 表示名, ヒント例文)
const _themeChoices = <_ThemeChoice>[
  _ThemeChoice('love', '恋愛・関係', '近くにいる人とのつながりを深めたい'),
  _ThemeChoice('money', '豊かさ・お金', '生活基盤を整えたい・流れを変えたい'),
  _ThemeChoice('work', '仕事・キャリア', '次のキャリアの方向を探している'),
  _ThemeChoice('communication', '対話・学び', '言葉を磨きたい・新しいことを学びたい'),
  _ThemeChoice('healing', '癒し・休息', '一度立ち止まって自分を整えたい'),
  _ThemeChoice('newStart', '変化・新たな出発', '心機一転、別のステージに進みたい'),
];

const _modeChoices = <_ModeChoice>[
  _ModeChoice('migration', '移住', '大陸・国・年単位の場所選び'),
  _ModeChoice('travel', '旅行', '地域・都市・期間ありの滞在'),
  _ModeChoice('daily', 'おでかけ', '今日の現在地周辺・方角ベース'),
];

const _scopeChoices = <_ScopeChoice>[
  _ScopeChoice('specific', '具体地点', '特定の場所を 1 つ吟味'),
  _ScopeChoice('region', '範囲指定', '地域ブロックから 3 候補'),
  _ScopeChoice('world', '世界全体', '地球規模で 3 候補'),
];

// 大ブロック region picker (worldCityRegionGroups の値で識別)
const _regionPickerGroups = <String>[
  '日本',
  '北米',
  'ヨーロッパ',
  'アジア',
  '中東',
  'アフリカ',
  '中南米',
  'オセアニア',
];

class _ThemeChoice {
  final String id;
  final String label;
  final String hint;
  const _ThemeChoice(this.id, this.label, this.hint);
}

class _ModeChoice {
  final String id;
  final String label;
  final String hint;
  const _ModeChoice(this.id, this.label, this.hint);
}

class _ScopeChoice {
  final String id;
  final String label;
  final String hint;
  const _ScopeChoice(this.id, this.label, this.hint);
}

class _ConsultationInputScreenState extends State<ConsultationInputScreen> {
  String _mode = 'migration';
  String? _theme;
  String _scope = 'world';
  String _regionGroup = '日本';

  final TextEditingController _freeTextCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // preset target がある場合は specific スコープ + 旅行モードを推奨デフォルト。
    if (widget.presetTarget != null) {
      _scope = 'specific';
      _mode = 'travel';
    }
  }

  @override
  void dispose() {
    _freeTextCtrl.dispose();
    super.dispose();
  }

  void _onModeChanged(String id) {
    setState(() {
      _mode = id;
      // daily を選んだ瞬間に scope は bearings 専用
      if (id == 'daily') {
        _scope = 'bearings';
      } else if (_scope == 'bearings') {
        // 他モードに戻ったら scope をデフォルトの world に
        _scope = 'world';
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
  /// - specific スコープ時は presetTarget も currentLocation も無ければ不可
  /// - daily モード時は currentLocation 必須
  bool get _canSubmit {
    if (_theme == null) return false;
    if (_mode == 'daily' && widget.currentLocation == null) return false;
    if (_scope == 'specific' &&
        widget.presetTarget == null &&
        widget.currentLocation == null) {
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
          final cur = widget.currentLocation!;
          return [
            ce.candidateForSpecific(
              target: cur,
              nameJP: '現在地',
              nameEN: 'Current Location',
              country: '',
              region: '',
              themeLines: themeLines,
            ),
          ];
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

  Future<void> _submit() async {
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
          mode: _mode,
          scope: _scope,
          freeText: _freeTextCtrl.text.trim(),
          initialCandidates: initial,
          regenerateCandidates: regenForResult,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SolaraColors.celestialBlueDark,
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
                      label: 'どの距離感で？',
                      child: _ModeRow(
                        selected: _mode,
                        onSelect: _onModeChanged,
                      ),
                    ),
                    if (_mode != 'daily')
                      _Section(
                        label: '範囲は？',
                        child: _ScopeRow(
                          selected: _scope,
                          onSelect: (id) => setState(() => _scope = id),
                          hasPreset: widget.presetTarget != null,
                          hasCurrent: widget.currentLocation != null,
                        ),
                      ),
                    if (_mode != 'daily' && _scope == 'region')
                      _Section(
                        label: '地域ブロック',
                        child: _RegionPicker(
                          selected: _regionGroup,
                          onSelect: (g) =>
                              setState(() => _regionGroup = g),
                        ),
                      ),
                    _Section(
                      label: '自由記述（任意）',
                      child: _FreeTextField(
                        controller: _freeTextCtrl,
                        hint: _theme != null
                            ? _themeChoices
                                .firstWhere((t) => t.id == _theme)
                                .hint
                            : 'いま気になっていること',
                      ),
                    ),
                    if (widget.presetTarget != null && _scope == 'specific')
                      _PresetLocationCard(target: widget.presetTarget!),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            _SubmitBar(
              enabled: _canSubmit,
              onSubmit: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

// ── サブウィジェット ───────────────────────────────────────

class _Section extends StatelessWidget {
  final String label;
  final Widget child;
  const _Section({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: SolaraColors.textSecondary,
              fontSize: 12,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ThemeGrid extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;
  const _ThemeGrid({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _themeChoices.map((t) {
        final active = selected == t.id;
        return GestureDetector(
          onTap: () => onSelect(t.id),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: active ? const Color(0x33F6BD60) : const Color(0x14FFFFFF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: active
                    ? SolaraColors.solaraGold
                    : SolaraColors.glassBorder,
              ),
            ),
            child: Text(
              t.label,
              style: TextStyle(
                color: active
                    ? SolaraColors.solaraGoldLight
                    : SolaraColors.textPrimary,
                fontSize: 13,
                letterSpacing: 0.3,
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _ModeRow extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  const _ModeRow({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _modeChoices.map((m) {
        final active = selected == m.id;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(m.id),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color:
                    active ? const Color(0x33F6BD60) : const Color(0x10FFFFFF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: active
                      ? SolaraColors.solaraGold
                      : SolaraColors.glassBorder,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    m.label,
                    style: TextStyle(
                      color: active
                          ? SolaraColors.solaraGoldLight
                          : SolaraColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    m.hint,
                    style: TextStyle(
                      color: SolaraColors.textSecondary,
                      fontSize: 10,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _ScopeRow extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  final bool hasPreset;
  final bool hasCurrent;
  const _ScopeRow({
    required this.selected,
    required this.onSelect,
    required this.hasPreset,
    required this.hasCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _scopeChoices.map((s) {
        final active = selected == s.id;
        final disabled =
            s.id == 'specific' && !hasPreset && !hasCurrent;
        return Expanded(
          child: GestureDetector(
            onTap: disabled ? null : () => onSelect(s.id),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: disabled
                    ? const Color(0x08FFFFFF)
                    : active
                        ? const Color(0x33F6BD60)
                        : const Color(0x10FFFFFF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: active && !disabled
                      ? SolaraColors.solaraGold
                      : SolaraColors.glassBorder,
                ),
              ),
              child: Opacity(
                opacity: disabled ? 0.4 : 1,
                child: Column(
                  children: [
                    Text(
                      s.label,
                      style: TextStyle(
                        color: active && !disabled
                            ? SolaraColors.solaraGoldLight
                            : SolaraColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.hint,
                      style: TextStyle(
                        color: SolaraColors.textSecondary,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _RegionPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  const _RegionPicker({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _regionPickerGroups.map((g) {
        final active = selected == g;
        return GestureDetector(
          onTap: () => onSelect(g),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: active ? const Color(0x33F6BD60) : const Color(0x12FFFFFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: active
                    ? SolaraColors.solaraGold
                    : SolaraColors.glassBorder,
              ),
            ),
            child: Text(
              g,
              style: TextStyle(
                color: active
                    ? SolaraColors.solaraGoldLight
                    : SolaraColors.textPrimary,
                fontSize: 12,
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _FreeTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const _FreeTextField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 3,
      maxLength: 200,
      style: const TextStyle(
        color: SolaraColors.textPrimary,
        fontSize: 13,
        height: 1.6,
      ),
      decoration: InputDecoration(
        hintText: '例: $hint',
        hintStyle: TextStyle(
          color: SolaraColors.textSecondary.withValues(alpha: 0.6),
          fontSize: 12,
        ),
        filled: true,
        fillColor: const Color(0x10FFFFFF),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: SolaraColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: SolaraColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: SolaraColors.solaraGold),
        ),
        counterStyle: TextStyle(
          color: SolaraColors.textSecondary.withValues(alpha: 0.6),
          fontSize: 10,
        ),
      ),
    );
  }
}

class _PresetLocationCard extends StatelessWidget {
  final ConsultationPresetTarget target;
  const _PresetLocationCard({required this.target});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x14F6BD60),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x44F6BD60)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_on_outlined,
            color: SolaraColors.solaraGold,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${target.nameJP}${target.region.isNotEmpty ? " (${target.region})" : ""} を見ます',
              style: const TextStyle(
                color: SolaraColors.textPrimary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitBar extends StatelessWidget {
  final bool enabled;
  final Future<void> Function() onSubmit;
  const _SubmitBar({required this.enabled, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: SolaraColors.glassBorder, width: 1),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: enabled ? () => onSubmit() : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: SolaraColors.solaraGold,
            foregroundColor: SolaraColors.celestialBlueDark,
            disabledBackgroundColor: SolaraColors.glassBorder,
            disabledForegroundColor: SolaraColors.textSecondary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
          child: const Text('相談を始める'),
        ),
      ),
    );
  }
}
