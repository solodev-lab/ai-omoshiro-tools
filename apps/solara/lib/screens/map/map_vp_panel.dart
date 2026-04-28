import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/solara_storage.dart';

/// HTML: VP_ICONS — デフォルトアイコン
const _defaultIcons = ['🏠', '🏢', '⭐', '📍'];

/// HTML: VP_ICON_ALL — アイコンピッカー用32種
const _allIcons = [
  '🏠','🏢','⭐','📍','💼','🏫','🏥','☕',
  '🍽','🛒','🏖','💒','🎯','🚉','🌳','❤️',
  '🐱','🐶','🐰','🦊','🐻','🐼','🐨','🦁',
  '🐯','🐸','🐧','🦉','🦋','🐬','🐾','🦄',
];

/// スロット1件分のデータ
class VPSlot {
  String name;
  double lat;
  double lng;
  String icon;
  bool isHome;

  VPSlot({required this.name, required this.lat, required this.lng, this.icon = '📍', this.isHome = false});

  Map<String, dynamic> toJson() => {'name': name, 'lat': lat, 'lng': lng, 'icon': icon, 'isHome': isHome};
  factory VPSlot.fromJson(Map<String, dynamic> j) => VPSlot(
    name: j['name'] ?? '', lat: (j['lat'] ?? 0).toDouble(),
    lng: (j['lng'] ?? 0).toDouble(), icon: j['icon'] ?? '📍',
    isHome: j['isHome'] ?? false,
  );
}

/// HTML: SlotManager — SharedPreferencesでスロットを永続化
class SlotManager {
  final String storageKey;
  final int maxSlots;
  final List<String> defaultNames;

  SlotManager({required this.storageKey, this.maxSlots = 5, this.defaultNames = const ['職場','お気に入り','スポット','場所']});

  Future<List<VPSlot>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null) return [];
    final list = json.decode(raw) as List;
    return list.map((e) => VPSlot.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> save(List<VPSlot> slots) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, json.encode(slots.map((s) => s.toJson()).toList()));
  }

  /// HTML: syncHome — プロフィールのホーム地点を先頭スロットに同期
  Future<void> syncHome(SolaraProfile? profile) async {
    if (profile == null || profile.homeName.isEmpty) return;
    final slots = await load();
    final h = VPSlot(name: profile.homeName, lat: profile.homeLat, lng: profile.homeLng, icon: '🏠', isHome: true);
    if (slots.isNotEmpty && slots[0].isHome) {
      slots[0] = h;
    } else {
      slots.insert(0, h);
      if (slots.length > maxSlots) slots.length = maxSlots;
    }
    await save(slots);
  }

  /// HTML: saveCurrentLocation — reverse geocodingで地名取得して保存
  Future<String?> saveCurrentLocation(LatLng center) async {
    final slots = await load();
    final homeCount = (slots.isNotEmpty && slots[0].isHome) ? 1 : 0;
    if (slots.length >= maxSlots) {
      return '保存は${maxSlots - homeCount}件までです。\n不要な地点を削除してから追加してください。';
    }
    final userIdx = slots.length - homeCount;
    final defaultName = userIdx < defaultNames.length ? defaultNames[userIdx] : 'スポット';

    String name = defaultName;
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${center.latitude}&lon=${center.longitude}&zoom=16');
      final resp = await http.get(uri, headers: {'User-Agent': 'SolaraApp/1.0', 'Accept-Language': 'ja,en'});
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final addr = data['address'] as Map<String, dynamic>? ?? {};
        // 市区町村を最優先 (suburb 優先だと OSM の道路ループや橋ループ等に
        // 付いた "Loop" のような局所タグを拾ってしまう。先に都市名を探す)
        final disp = addr['city'] ?? addr['town'] ?? addr['village']
            ?? addr['suburb'] ?? addr['neighbourhood'] ?? defaultName;
        name = disp.toString().substring(0, disp.toString().length.clamp(0, 8));
      }
    } catch (_) {}

    slots.add(VPSlot(name: name, lat: center.latitude, lng: center.longitude, icon: _defaultIcons[userIdx.clamp(0, _defaultIcons.length - 1)]));
    await save(slots);
    return null; // success
  }

  Future<void> moveSlot(int i, int dir) async {
    final s = await load();
    final t = i + dir;
    if (t < 0 || t >= s.length) return;
    if ((i == 0 && s[0].isHome) || (t == 0 && s[0].isHome)) return;
    final tmp = s[i]; s[i] = s[t]; s[t] = tmp;
    await save(s);
  }

  Future<void> renameSlot(int i, String newName) async {
    final s = await load();
    if (i >= s.length || s[i].isHome) return;
    s[i].name = newName.substring(0, newName.length.clamp(0, 12));
    await save(s);
  }

  Future<void> deleteSlot(int i) async {
    final s = await load();
    if (i >= s.length || s[i].isHome) return;
    s.removeAt(i);
    await save(s);
  }

  Future<void> changeIcon(int i, String icon) async {
    final s = await load();
    if (i >= s.length || s[i].isHome) return;
    s[i].icon = icon;
    await save(s);
  }
}

/// VP Panel — HTML: .vp-panel { top:222px; left:60px; width:180px; }
class VPPanel extends StatefulWidget {
  final String activeTab;
  final ValueChanged<String> onTabChanged;
  final LatLng center;
  final SolaraProfile? profile;
  final void Function(VPSlot slot) onSlotSelected;
  final VoidCallback onGeolocate;

  const VPPanel({
    super.key,
    required this.activeTab,
    required this.onTabChanged,
    required this.center,
    required this.profile,
    required this.onSlotSelected,
    required this.onGeolocate,
  });

  @override
  State<VPPanel> createState() => _VPPanelState();
}

class _VPPanelState extends State<VPPanel> {
  late final SlotManager _vpMgr = SlotManager(storageKey: 'solara_vp_slots', defaultNames: ['職場','お気に入り','スポット','場所']);
  late final SlotManager _locMgr = SlotManager(storageKey: 'solara_locations', defaultNames: ['場所1','場所2','場所3','場所4']);
  List<VPSlot> _vpSlots = [];
  List<VPSlot> _locSlots = [];
  int _activeSub = -1;
  String? _msg;

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
    if (mounted) setState(() { _vpSlots = vp; _locSlots = loc; });
  }

  SlotManager get _activeMgr => widget.activeTab == 'vp' ? _vpMgr : _locMgr;
  List<VPSlot> get _activeSlots => widget.activeTab == 'vp' ? _vpSlots : _locSlots;

  Future<void> _reload() async {
    final slots = await _activeMgr.load();
    if (mounted) {
      setState(() {
      if (widget.activeTab == 'vp') {
        _vpSlots = slots;
      } else {
        _locSlots = slots;
      }
      _activeSub = -1;
    });
    }
  }

  Future<void> _saveLocation() async {
    final err = await _activeMgr.saveCurrentLocation(widget.center);
    if (err != null) {
      setState(() => _msg = err);
      Future.delayed(const Duration(seconds: 3), () { if (mounted) setState(() => _msg = null); });
    } else {
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xEB0C0C1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x33C9A84C)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        // Tabs
        Container(
          decoration: BoxDecoration(color: const Color(0x08FFFFFF), borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.all(2),
          child: Row(children: [
            _tabBtn('vp', '📍 VIEWPOINT'),
            _tabBtn('loc', '🌐 LOCATIONS'),
          ]),
        ),
        const SizedBox(height: 12),
        // Content
        if (widget.activeTab == 'vp') _buildVPContent(),
        if (widget.activeTab == 'loc') _buildLocContent(),
        // Message
        if (_msg != null) Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(_msg!, style: const TextStyle(fontSize: 9, color: Color(0xFFFF6B6B)), textAlign: TextAlign.center),
        ),
      ]),
    );
  }

  Widget _tabBtn(String key, String label) {
    final active = widget.activeTab == key;
    return Expanded(child: GestureDetector(
      onTap: () { widget.onTabChanged(key); setState(() { _activeSub = -1; }); _reload(); },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0x1FC9A84C) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(child: Text(label, style: TextStyle(
          fontSize: 8, letterSpacing: 0.5,
          color: active ? const Color(0xFFC9A84C) : const Color(0xFF555555),
        ))),
      ),
    ));
  }

  Widget _buildVPContent() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _actionBtn('📡', '現在地に移動', widget.onGeolocate),
      _actionBtn('💾', 'この地点を保存', _saveLocation),
      const SizedBox(height: 8),
      // Coordinate display
      Text(
        '${widget.center.latitude.toStringAsFixed(4)}, ${widget.center.longitude.toStringAsFixed(4)}',
        style: const TextStyle(fontSize: 8, color: Color(0xFF555555), letterSpacing: 0.5),
      ),
      const SizedBox(height: 8),
      const Text('保存済みスロット', style: TextStyle(fontSize: 8, color: Color(0xFF555555), letterSpacing: 1)),
      const SizedBox(height: 6),
      _buildSlotList(_vpSlots, true),
    ]);
  }

  Widget _buildLocContent() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _actionBtn('📍', 'この地点を登録', _saveLocation),
      const SizedBox(height: 8),
      const Text('登録地', style: TextStyle(fontSize: 8, color: Color(0xFF555555), letterSpacing: 1)),
      const SizedBox(height: 6),
      _buildSlotList(_locSlots, false),
    ]);
  }

  Widget _buildSlotList(List<VPSlot> slots, bool showMove) {
    if (slots.isEmpty) {
      return const Text('（スロットなし）', style: TextStyle(fontSize: 10, color: Color(0xFF444444)));
    }
    return Column(mainAxisSize: MainAxisSize.min, children: [
      for (int i = 0; i < slots.length; i++) _buildSlotRow(slots[i], i, slots.length, showMove),
    ]);
  }

  Widget _buildSlotRow(VPSlot slot, int idx, int total, bool showMove) {
    final isActive = (slot.lat - widget.center.latitude).abs() < 0.001 &&
                     (slot.lng - widget.center.longitude).abs() < 0.001;

    return Column(mainAxisSize: MainAxisSize.min, children: [
      GestureDetector(
        onTap: () => widget.onSlotSelected(slot),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: isActive ? const Color(0x1FC9A84C) : Colors.transparent,
          ),
          child: Row(children: [
            Text(slot.icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Expanded(child: Text(slot.name, style: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (slot.isHome)
              const Text('HOME', style: TextStyle(fontSize: 8, color: Color(0x99F9D976), letterSpacing: 1)),
            if (!slot.isHome) GestureDetector(
              onTap: () => setState(() => _activeSub = _activeSub == idx ? -1 : idx),
              child: const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Text('⋯', style: TextStyle(fontSize: 14, color: Color(0xFF888888))),
              ),
            ),
          ]),
        ),
      ),
      // Submenu
      if (_activeSub == idx && !slot.isHome) _buildSubMenu(idx, total, showMove),
    ]);
  }

  Widget _buildSubMenu(int idx, int total, bool showMove) {
    return Container(
      margin: const EdgeInsets.only(left: 20, bottom: 4),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF14142A),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (showMove) ...[
          _subItem('↑', '上に移動', idx == 0, () async { await _activeMgr.moveSlot(idx, -1); await _reload(); }),
          _subItem('↓', '下に移動', idx == total - 1, () async { await _activeMgr.moveSlot(idx, 1); await _reload(); }),
        ],
        _subItem('🎨', 'アイコン変更', false, () => _showIconPickerDialog(idx)),
        _subItem('✏️', '名称変更', false, () => _showRenameDialog(idx)),
        _subItem('🗑', '削除', false, () async { await _activeMgr.deleteSlot(idx); await _reload(); }, isDanger: true),
      ]),
    );
  }

  Widget _subItem(String icon, String label, bool disabled, VoidCallback onTap, {bool isDanger = false}) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Opacity(
        opacity: disabled ? 0.25 : 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(children: [
            Text(icon, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 10, color: isDanger ? const Color(0xFFFF6B6B) : const Color(0xFFAAAAAA))),
          ]),
        ),
      ),
    );
  }

  /// アイコン選択をダイアログで表示（インライン展開だとパネル下端で画面外に切れるため）。
  /// VIEWPOINT/LOCATIONS 両タブ共通で、選択済みアイコンは金色枠で強調。
  Future<void> _showIconPickerDialog(int idx) async {
    if (idx >= _activeSlots.length) return;
    final current = _activeSlots[idx].icon;
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0C0C1A),
        // 8個/行 × 4行で 32アイコンを表示するため、横幅を広げて狭い画面でも入るよう inset を詰める。
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        title: const Text('アイコンを選択',
            style: TextStyle(fontSize: 14, color: Color(0xFFC9A84C))),
        contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        content: SizedBox(
          width: 352, // 8個/行: 36*8 + 8*7 = 344 + 余白8
          child: Wrap(
            spacing: 8, runSpacing: 8,
            children: _allIcons.map((ic) {
              final cur = current == ic;
              return GestureDetector(
                onTap: () => Navigator.pop(ctx, ic),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: cur ? const Color(0x33C9A84C) : Colors.transparent,
                    border: Border.all(
                      color: cur ? const Color(0xFFC9A84C) : const Color(0x1AFFFFFF),
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0C0C1A),
        title: const Text('地点の名称を入力', style: TextStyle(fontSize: 14, color: Color(0xFFC9A84C))),
        content: TextField(
          controller: ctrl, autofocus: true, maxLength: 12,
          style: const TextStyle(color: Color(0xFFE8E0D0), fontSize: 13),
          decoration: const InputDecoration(
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0x33C9A84C))),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFC9A84C))),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル', style: TextStyle(color: Color(0xFF555555)))),
          TextButton(onPressed: () async {
            final name = ctrl.text.trim();
            if (name.isNotEmpty) { await _activeMgr.renameSlot(idx, name); await _reload(); }
            if (ctx.mounted) Navigator.pop(ctx);
          }, child: const Text('OK', style: TextStyle(color: Color(0xFFC9A84C)))),
        ],
      ),
    );
  }

  Widget _actionBtn(String icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x1AFFFFFF)),
        ),
        child: Row(children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)))),
        ]),
      ),
    );
  }
}
