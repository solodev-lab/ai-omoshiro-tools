import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../utils/astro_glossary.dart';
import '../../utils/solara_storage.dart';
import 'map_constants.dart';
import 'map_styles.dart';
import 'map_vp_panel.dart';

/// Map メニュー BottomSheet 群 (2026-05-09 新設)。
///
/// 旧 LayerPanel (display/astro 2 view、幅110px) と VPPanel (幅180px、折返発生)
/// を廃し、幅100% の BottomSheet に再配置。タップ領域・文字を拡大して可視性向上。
///
/// 各シートは map_screen.dart の `_showSheet()` から呼び出される。
/// レイヤー切替系 (display/astro) は StatefulBuilder と組み合わせて、シート内
/// チェックボックスの即時 visual feedback と親 setState (Map 再描画) を両立。

// ── 共通スタイル ──────────────────────────────────────────────
const _kSheetBg = Color(0xF20A0A19);
const _kSheetBorder = Color(0x40C9A84C);
const _kSectionLabel = Color(0xFF888888);
const _kRowLabel = Color(0xFFE8E0D0);
const _kRowLabelOff = Color(0xFF777777);
const _kAccent = Color(0xFFC9A84C);

/// シート共通スカフォールド: ドラッグハンドル + タイトル + Scrollable 本体。
class _SheetScaffold extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SheetScaffold({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kSheetBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: _kSheetBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ドラッグハンドル
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            alignment: Alignment.center,
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0x40FFFFFF),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // タイトル
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: _kAccent,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // 本体
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// セクションヘッダー (例: "ASTRO LINES")。
Widget _sectionHeader(String label) {
  return Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 6),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        color: _kSectionLabel,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

/// 大きめチェックボックスのトグル行 (タップ領域 全幅 × 高さ 44px)。
class _ToggleRow extends StatelessWidget {
  final String label;
  final bool on;
  final Color color;
  final VoidCallback onTap;
  final String? glossaryKey;
  const _ToggleRow({
    required this.label,
    required this.on,
    required this.color,
    required this.onTap,
    this.glossaryKey,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            // チェックボックス本体
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: on ? color : const Color(0x55FFFFFF),
                  width: 1.8,
                ),
                color: on ? color.withAlpha(40) : Colors.transparent,
              ),
              child: on
                  ? Center(
                      child: Text('✓',
                          style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.bold)),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: on ? _kRowLabel : _kRowLabelOff,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            if (glossaryKey != null)
              GestureDetector(
                onTap: () => showAstroGlossaryDialog(context, glossaryKey!),
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.info_outline, size: 18, color: Color(0xCCAAAAAA)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// アクションボタン (例: "🌐 世界モード(ACG)へ →")。
class _ActionRow extends StatelessWidget {
  final IconData? icon;
  final String? leadingEmoji;
  final String label;
  final VoidCallback onTap;
  const _ActionRow({
    this.icon,
    this.leadingEmoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const color = _kAccent;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withAlpha(0x55)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withAlpha(0x22),
                color.withAlpha(0x08),
              ],
            ),
          ),
          child: Row(
            children: [
              if (leadingEmoji != null) ...[
                Text(leadingEmoji!, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
              ] else if (icon != null) ...[
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: color,
                    letterSpacing: 0.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: color.withAlpha(0x99)),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// 1. DISPLAY シート (16方位 / コンパス / マップスタイル)
// ════════════════════════════════════════════════════════════════════════

class MapDisplaySheet extends StatelessWidget {
  final Map<String, bool> layers;
  final MapStyle mapStyle;
  final ValueChanged<String> onLayerToggle;
  final ValueChanged<MapStyle> onMapStyleChanged;

  const MapDisplaySheet({
    super.key,
    required this.layers,
    required this.mapStyle,
    required this.onLayerToggle,
    required this.onMapStyleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: '⚙️  表示',
      children: [
        _sectionHeader('運勢方位'),
        _ToggleRow(
          label: '16方位スコアを表示',
          on: layers['sectors'] ?? false,
          color: _kAccent,
          glossaryKey: 'sector_score_16',
          onTap: () => onLayerToggle('sectors'),
        ),
        _sectionHeader('地図'),
        _ToggleRow(
          label: 'コンパスを表示',
          on: layers['compass'] ?? false,
          color: const Color(0xFFE8E0D0),
          onTap: () => onLayerToggle('compass'),
        ),
        _sectionHeader('マップスタイル'),
        for (final e in mapStyleConfigs.entries)
          _StyleOption(
            label: e.value.label,
            active: mapStyle == e.key,
            onTap: () => onMapStyleChanged(e.key),
          ),
      ],
    );
  }
}

class _StyleOption extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _StyleOption({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: active ? _kAccent : const Color(0x55FFFFFF),
                  width: 2,
                ),
                color: active ? _kAccent.withAlpha(80) : Colors.transparent,
              ),
              child: active
                  ? const Center(
                      child: Icon(Icons.circle, size: 8, color: _kAccent),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: active ? _kRowLabel : _kRowLabelOff,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// 2. ASTRO シート (惑星ライン / CCG / CHART / PLANET GROUP / FORTUNE / ACG起動)
// ════════════════════════════════════════════════════════════════════════

class MapAstroSheet extends StatelessWidget {
  final Map<String, bool> layers;
  final Map<String, bool> planetGroups;
  final Map<String, bool> astroLayers;
  final String activeCategory;
  final ValueChanged<String> onLayerToggle;
  final ValueChanged<String> onPlanetGroupToggle;
  final ValueChanged<String> onAstroToggle;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onEnterAcg;

  const MapAstroSheet({
    super.key,
    required this.layers,
    required this.planetGroups,
    required this.astroLayers,
    required this.activeCategory,
    required this.onLayerToggle,
    required this.onPlanetGroupToggle,
    required this.onAstroToggle,
    required this.onCategoryChanged,
    required this.onEnterAcg,
  });

  @override
  Widget build(BuildContext context) {
    final showPlanetLineDetails = astroLayers['planetLines'] ?? true;
    final anyAspectOn = astroLayers['aspect'] == true ||
        astroLayers['aspectTransit'] == true ||
        astroLayers['aspectProgressed'] == true ||
        astroLayers['aspectSolarArc'] == true;

    return _SheetScaffold(
      title: '✨  占星',
      children: [
        // ── ASTRO LINES (惑星ライン / 引越し) ──
        _sectionHeader('ASTRO LINES'),
        _ToggleRow(
          label: '惑星ライン',
          on: astroLayers['planetLines'] ?? false,
          color: const Color(0xFFFFD370),
          glossaryKey: 'planet_lines',
          onTap: () => onAstroToggle('planetLines'),
        ),
        _ToggleRow(
          label: '引越し',
          on: astroLayers['relocate'] ?? false,
          color: const Color(0xFFFFB6C1),
          glossaryKey: 'relocate_layer',
          onTap: () => onAstroToggle('relocate'),
        ),

        // ── A*C*G (4 frame) ──
        _sectionHeader('A*C*G'),
        _ToggleRow(
          label: 'Natal 線',
          on: astroLayers['aspect'] ?? false,
          color: const Color(0xFFE9D29A),
          glossaryKey: 'aspect_lines',
          onTap: () => onAstroToggle('aspect'),
        ),
        _ToggleRow(
          label: 'Transit 線',
          on: astroLayers['aspectTransit'] ?? false,
          color: const Color(0xFFFF8E5C),
          glossaryKey: 'transit_acg',
          onTap: () => onAstroToggle('aspectTransit'),
        ),
        _ToggleRow(
          label: 'Progressed 線',
          on: astroLayers['aspectProgressed'] ?? false,
          color: const Color(0xFF63D6A0),
          glossaryKey: 'progressed_acg',
          onTap: () => onAstroToggle('aspectProgressed'),
        ),
        _ToggleRow(
          label: 'Solar Arc 線',
          on: astroLayers['aspectSolarArc'] ?? false,
          color: const Color(0xFFB07CFF),
          glossaryKey: 'solar_arc_acg',
          onTap: () => onAstroToggle('aspectSolarArc'),
        ),
        if (anyAspectOn)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: _ToggleRow(
              label: '全惑星',
              on: astroLayers['aspectAll'] ?? false,
              color: const Color(0xFFE8E0D0),
              onTap: () => onAstroToggle('aspectAll'),
            ),
          ),

        // ── CHART (惑星ライン詳細) ──
        if (showPlanetLineDetails) ...[
          _sectionHeader('CHART'),
          _ToggleRow(
            label: 'Natal',
            on: layers['natal'] ?? false,
            color: const Color(0xFFFFD370),
            onTap: () => onLayerToggle('natal'),
          ),
          _ToggleRow(
            label: 'Progressed',
            on: layers['progressed'] ?? false,
            color: const Color(0xFFB088FF),
            onTap: () => onLayerToggle('progressed'),
          ),
          _ToggleRow(
            label: 'Transit',
            on: layers['transit'] ?? false,
            color: const Color(0xFF6BB5FF),
            onTap: () => onLayerToggle('transit'),
          ),
        ],

        // ── PLANET GROUP ──
        _sectionHeader('PLANET GROUP'),
        _ToggleRow(
          label: '個人天体',
          on: planetGroups['personal'] ?? false,
          color: const Color(0xFFFFD370),
          onTap: () => onPlanetGroupToggle('personal'),
        ),
        _ToggleRow(
          label: '社会天体',
          on: planetGroups['social'] ?? false,
          color: const Color(0xFF6BB5FF),
          onTap: () => onPlanetGroupToggle('social'),
        ),
        _ToggleRow(
          label: '世代天体',
          on: planetGroups['generational'] ?? false,
          color: const Color(0xFFB088FF),
          onTap: () => onPlanetGroupToggle('generational'),
        ),

        // ── FORTUNE (カテゴリピル) ──
        _sectionHeader('FORTUNE'),
        _CategoryPills(
          activeCategory: activeCategory,
          onChanged: onCategoryChanged,
        ),

        // ── ACG 起動ボタン ──
        const SizedBox(height: 24),
        _ActionRow(
          leadingEmoji: '🌐',
          label: '世界モード (Astro*Carto*Graphy) を開く',
          onTap: () {
            Navigator.of(context).maybePop();
            onEnterAcg();
          },
        ),
      ],
    );
  }
}

class _CategoryPills extends StatelessWidget {
  final String activeCategory;
  final ValueChanged<String> onChanged;
  const _CategoryPills({required this.activeCategory, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categoryColors.entries.map((e) {
        final active = activeCategory == e.key;
        return GestureDetector(
          onTap: () => onChanged(e.key),
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: active ? e.value : const Color(0x33FFFFFF),
                width: 1.5,
              ),
              color: active ? e.value.withAlpha(40) : Colors.transparent,
            ),
            child: Text(
              categoryLabels[e.key] ?? e.key,
              style: TextStyle(
                fontSize: 14,
                color: active ? e.value : const Color(0xFF888888),
                letterSpacing: 0.5,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// 3. LOCATIONS シート (VIEWPOINT / LOCATIONS タブ + 詳細管理リンク)
// ════════════════════════════════════════════════════════════════════════

const _allIcons = [
  '🏠','🏢','⭐','📍','💼','🏫','🏥','☕',
  '🍽','🛒','🏖','💒','🎯','🚉','🌳','❤️',
  '🐱','🐶','🐰','🦊','🐻','🐼','🐨','🦁',
  '🐯','🐸','🐧','🦉','🦋','🐬','🐾','🦄',
];

class MapLocationsSheet extends StatefulWidget {
  final String activeTab; // 'vp' | 'loc'
  final ValueChanged<String> onTabChanged;
  final LatLng center;
  final SolaraProfile? profile;
  final void Function(VPSlot slot) onSlotSelected;
  final VoidCallback onGeolocate;
  final VoidCallback onOpenFullLocations;

  const MapLocationsSheet({
    super.key,
    required this.activeTab,
    required this.onTabChanged,
    required this.center,
    required this.profile,
    required this.onSlotSelected,
    required this.onGeolocate,
    required this.onOpenFullLocations,
  });

  @override
  State<MapLocationsSheet> createState() => _MapLocationsSheetState();
}

class _MapLocationsSheetState extends State<MapLocationsSheet> {
  final SlotManager _vpMgr = SlotManager(
    storageKey: 'solara_vp_slots',
    defaultNames: ['職場', 'お気に入り', 'スポット', '場所'],
  );
  final SlotManager _locMgr = SlotManager(
    storageKey: 'solara_locations',
    defaultNames: ['場所1', '場所2', '場所3', '場所4'],
  );
  List<VPSlot> _vpSlots = [];
  List<VPSlot> _locSlots = [];
  int _activeSub = -1;
  String? _msg;

  late String _tab = widget.activeTab;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await _vpMgr.syncHome(widget.profile);
    await _locMgr.syncHome(widget.profile);
    final vp = await _vpMgr.load();
    final loc = await _locMgr.load();
    if (!mounted) return;
    setState(() {
      _vpSlots = vp;
      _locSlots = loc;
    });
  }

  SlotManager get _activeMgr => _tab == 'vp' ? _vpMgr : _locMgr;
  List<VPSlot> get _activeSlots => _tab == 'vp' ? _vpSlots : _locSlots;

  Future<void> _reload() async {
    final slots = await _activeMgr.load();
    if (!mounted) return;
    setState(() {
      if (_tab == 'vp') {
        _vpSlots = slots;
      } else {
        _locSlots = slots;
      }
      _activeSub = -1;
    });
  }

  Future<void> _saveLocation() async {
    final err = await _activeMgr.saveCurrentLocation(widget.center);
    if (err != null) {
      setState(() => _msg = err);
      Future<void>.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _msg = null);
      });
    } else {
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: '📍  地点',
      children: [
        // タブ切替
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0x12FFFFFF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            _tabBtn('vp', '📍 VIEWPOINT'),
            _tabBtn('loc', '🌐 LOCATIONS'),
          ]),
        ),
        const SizedBox(height: 14),

        // 現在地座標
        Text(
          '${widget.center.latitude.toStringAsFixed(4)}, ${widget.center.longitude.toStringAsFixed(4)}',
          style: const TextStyle(
            fontSize: 13,
            color: _kSectionLabel,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),

        // アクションボタン
        if (_tab == 'vp') ...[
          _ActionRow(
            icon: Icons.my_location,
            label: '現在地に移動',
            onTap: widget.onGeolocate,
          ),
          _ActionRow(
            icon: Icons.save_alt,
            label: 'この地点を保存',
            onTap: _saveLocation,
          ),
        ] else ...[
          _ActionRow(
            icon: Icons.add_location_alt,
            label: 'この地点を登録',
            onTap: _saveLocation,
          ),
        ],

        // メッセージ (失敗時)
        if (_msg != null) Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            _msg!,
            style: const TextStyle(fontSize: 13, color: Color(0xFFFF6B6B)),
            textAlign: TextAlign.center,
          ),
        ),

        // スロット一覧
        _sectionHeader(_tab == 'vp' ? '保存済みスロット' : '登録地'),
        _buildSlotList(_activeSlots, showMove: _tab == 'vp'),

        // LOCATIONS タブの場合: 詳細管理画面へのリンク
        if (_tab == 'loc') ...[
          const SizedBox(height: 16),
          _ActionRow(
            leadingEmoji: '📐',
            label: '16方位スコアで詳細管理',
            onTap: () {
              Navigator.of(context).maybePop();
              widget.onOpenFullLocations();
            },
          ),
        ],
      ],
    );
  }

  Widget _tabBtn(String key, String label) {
    final active = _tab == key;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _tab = key;
            _activeSub = -1;
          });
          widget.onTabChanged(key);
          _reload();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? const Color(0x22C9A84C) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                letterSpacing: 0.5,
                color: active ? _kAccent : _kSectionLabel,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlotList(List<VPSlot> slots, {required bool showMove}) {
    if (slots.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('（スロットなし）', style: TextStyle(fontSize: 13, color: Color(0xFF555555))),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < slots.length; i++)
          _buildSlotRow(slots[i], i, slots.length, showMove),
      ],
    );
  }

  Widget _buildSlotRow(VPSlot slot, int idx, int total, bool showMove) {
    final isActive = (slot.lat - widget.center.latitude).abs() < 0.001 &&
        (slot.lng - widget.center.longitude).abs() < 0.001;

    return Column(mainAxisSize: MainAxisSize.min, children: [
      InkWell(
        onTap: () => widget.onSlotSelected(slot),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isActive ? const Color(0x22C9A84C) : Colors.transparent,
          ),
          child: Row(children: [
            Text(slot.icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                slot.name,
                style: const TextStyle(fontSize: 15, color: _kRowLabel),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (slot.isHome)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'HOME',
                  style: TextStyle(fontSize: 11, color: Color(0x99F9D976), letterSpacing: 1.2),
                ),
              ),
            if (!slot.isHome)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () =>
                    setState(() => _activeSub = _activeSub == idx ? -1 : idx),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Icon(Icons.more_horiz, size: 18, color: Color(0xFF888888)),
                ),
              ),
          ]),
        ),
      ),
      if (_activeSub == idx && !slot.isHome)
        _buildSubMenu(idx, total, showMove),
    ]);
  }

  Widget _buildSubMenu(int idx, int total, bool showMove) {
    return Container(
      margin: const EdgeInsets.only(left: 36, top: 4, bottom: 6),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF14142A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (showMove) ...[
          _subItem('↑', '上に移動', idx == 0, () async {
            await _activeMgr.moveSlot(idx, -1);
            await _reload();
          }),
          _subItem('↓', '下に移動', idx == total - 1, () async {
            await _activeMgr.moveSlot(idx, 1);
            await _reload();
          }),
        ],
        _subItem('🎨', 'アイコン変更', false, () => _showIconPickerDialog(idx)),
        _subItem('✏️', '名称変更', false, () => _showRenameDialog(idx)),
        _subItem('🗑', '削除', false, () async {
          await _activeMgr.deleteSlot(idx);
          await _reload();
        }, isDanger: true),
      ]),
    );
  }

  Widget _subItem(String icon, String label, bool disabled, VoidCallback onTap,
      {bool isDanger = false}) {
    return InkWell(
      onTap: disabled ? null : onTap,
      child: Opacity(
        opacity: disabled ? 0.25 : 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isDanger ? const Color(0xFFFF6B6B) : _kRowLabel,
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _showIconPickerDialog(int idx) async {
    if (idx >= _activeSlots.length) return;
    final current = _activeSlots[idx].icon;
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0C0C1A),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        title: const Text('アイコンを選択',
            style: TextStyle(fontSize: 14, color: _kAccent)),
        contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        content: SizedBox(
          width: 352,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allIcons.map((ic) {
              final cur = current == ic;
              return GestureDetector(
                onTap: () => Navigator.pop(ctx, ic),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: cur ? const Color(0x33C9A84C) : Colors.transparent,
                    border: Border.all(
                      color: cur ? _kAccent : const Color(0x1AFFFFFF),
                    ),
                  ),
                  child: Center(child: Text(ic, style: const TextStyle(fontSize: 20))),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル', style: TextStyle(color: Color(0xFF555555))),
          ),
        ],
      ),
    );
    if (picked != null && picked != current) {
      await _activeMgr.changeIcon(idx, picked);
      await _reload();
    }
  }

  void _showRenameDialog(int idx) {
    final ctrl = TextEditingController(text: _activeSlots[idx].name);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0C0C1A),
        title: const Text('地点の名称を入力',
            style: TextStyle(fontSize: 14, color: _kAccent)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 12,
          style: const TextStyle(color: Color(0xFFE8E0D0), fontSize: 14),
          decoration: const InputDecoration(
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0x33C9A84C))),
            focusedBorder:
                UnderlineInputBorder(borderSide: BorderSide(color: _kAccent)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル', style: TextStyle(color: Color(0xFF555555))),
          ),
          TextButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                await _activeMgr.renameSlot(idx, name);
                await _reload();
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('OK', style: TextStyle(color: _kAccent)),
          ),
        ],
      ),
    );
  }
}

