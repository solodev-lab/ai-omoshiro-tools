import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../utils/solara_storage.dart';
import 'map_vp_panel.dart';

/// 📍 地点ボタンタップで画面上部に展開するパネル (2026-05-09 第三弾)。
///
/// 旧設計 (右展開のコンパクトなチップ列) はスロット名の折返しや submenu の
/// 表示スペースが取れず使いにくかったため、画面上部 ~40% を占める縦長パネルに
/// 変更。VIEWPOINT / LOCATIONS タブで地点登録を管理する旧 VPPanel の体験を復活。
///
/// 構成:
///   [📍 VIEWPOINT] [🌐 LOCATIONS]  ✕
///   座標表示
///   [現在地に移動] [この地点を保存]
///   ── 保存済みスロット ──
///   🏠 HOME
///   💼 職場            ⋯ (rename/icon/delete)
///   ⭐ お気に入り       ⋯
///   ...
class MapViewpointMenu extends StatefulWidget {
  final LatLng center;
  final SolaraProfile? profile;
  final void Function(VPSlot slot) onSlotSelected;
  final VoidCallback onGeolocate;
  final VoidCallback onClose;

  /// スロット編集 (rename/icon/delete) 後に親側マーカーを再描画させる。
  final VoidCallback onSlotsChanged;

  const MapViewpointMenu({
    super.key,
    required this.center,
    required this.profile,
    required this.onSlotSelected,
    required this.onGeolocate,
    required this.onClose,
    required this.onSlotsChanged,
  });

  @override
  State<MapViewpointMenu> createState() => _MapViewpointMenuState();
}

const _allIcons = [
  '🏠','🏢','⭐','📍','💼','🏫','🏥','☕',
  '🍽','🛒','🏖','💒','🎯','🚉','🌳','❤️',
  '🐱','🐶','🐰','🦊','🐻','🐼','🐨','🦁',
  '🐯','🐸','🐧','🦉','🦋','🐬','🐾','🦄',
];

class _MapViewpointMenuState extends State<MapViewpointMenu> {
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
  String _tab = 'vp'; // 'vp' | 'loc'
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
    widget.onSlotsChanged();
  }

  Future<void> _saveCurrent() async {
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xF20A0A19),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x33C9A84C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── タブバー + 閉じるボタン ──
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: Row(children: [
              Expanded(child: _tabBtn('vp', '📍 VIEWPOINT')),
              const SizedBox(width: 6),
              Expanded(child: _tabBtn('loc', '🌐 LOCATIONS')),
              const SizedBox(width: 6),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onClose,
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  child: const Icon(Icons.close, size: 18, color: Color(0xFF888888)),
                ),
              ),
            ]),
          ),
          // ── 本体 (Expanded で残りの高さを全部使い、内部 scrollview で
          //         submenu 展開時も全項目を可視化) ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 現在の中心座標
                  Text(
                    '${widget.center.latitude.toStringAsFixed(4)}, ${widget.center.longitude.toStringAsFixed(4)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF888888),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // アクションボタン (タブ別)
                  if (_tab == 'vp') ...[
                    _actionBtn(Icons.my_location, '現在地に移動', widget.onGeolocate),
                    const SizedBox(height: 6),
                    _actionBtn(Icons.save_alt, 'この地点を保存', _saveCurrent),
                  ] else
                    _actionBtn(Icons.add_location_alt, 'この地点を登録', _saveCurrent),
                  if (_msg != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _msg!,
                        style: const TextStyle(fontSize: 12, color: Color(0xFFFF6B6B)),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    _tab == 'vp' ? '保存済みスロット' : '登録地',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildSlotList(_activeSlots, showMove: _tab == 'vp'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabBtn(String key, String label) {
    final active = _tab == key;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _tab = key;
          _activeSub = -1;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: active ? const Color(0x22C9A84C) : Colors.transparent,
          border: Border.all(
            color: active ? const Color(0xFFC9A84C) : const Color(0x22C9A84C),
            width: active ? 1.4 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              letterSpacing: 0.5,
              color: active ? const Color(0xFFC9A84C) : const Color(0xFF888888),
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x55C9A84C)),
          color: const Color(0x14C9A84C),
        ),
        child: Row(children: [
          Icon(icon, size: 16, color: const Color(0xFFC9A84C)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFC9A84C),
                letterSpacing: 0.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildSlotList(List<VPSlot> slots, {required bool showMove}) {
    if (slots.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          '（スロットなし）',
          style: TextStyle(fontSize: 12, color: Color(0xFF555555)),
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < slots.length; i++) _buildSlotRow(slots[i], i, slots.length, showMove),
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isActive ? const Color(0x22C9A84C) : Colors.transparent,
          ),
          child: Row(children: [
            Text(slot.icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                // HOME スロットは住所そのものではなく「現住所」固定表示。
                // (オーナー指示 2026-05-09: 個人情報的な住所文字列を見せない方針)
                slot.isHome ? '現住所' : slot.name,
                style: TextStyle(
                  fontSize: 13,
                  color: slot.isHome
                      ? const Color(0xFFF9D976) // HOME は金色で目立たせる
                      : const Color(0xFFE8E0D0),
                  fontWeight: slot.isHome ? FontWeight.w600 : FontWeight.w400,
                  letterSpacing: slot.isHome ? 0.5 : 0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!slot.isHome)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _activeSub = _activeSub == idx ? -1 : idx),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Icon(Icons.more_horiz, size: 18, color: Color(0xFF888888)),
                ),
              ),
          ]),
        ),
      ),
      if (_activeSub == idx && !slot.isHome) _buildSubMenu(idx, total, showMove),
    ]);
  }

  Widget _buildSubMenu(int idx, int total, bool showMove) {
    return Container(
      margin: const EdgeInsets.only(left: 32, top: 2, bottom: 4),
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
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: isDanger ? const Color(0xFFFF6B6B) : const Color(0xFFE8E0D0),
                ),
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
            style: TextStyle(fontSize: 14, color: Color(0xFFC9A84C))),
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
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0C0C1A),
        title: const Text('地点の名称を入力',
            style: TextStyle(fontSize: 14, color: Color(0xFFC9A84C))),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 12,
          style: const TextStyle(color: Color(0xFFE8E0D0), fontSize: 14),
          decoration: const InputDecoration(
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0x33C9A84C))),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFC9A84C))),
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
            child: const Text('OK', style: TextStyle(color: Color(0xFFC9A84C))),
          ),
        ],
      ),
    );
  }
}
