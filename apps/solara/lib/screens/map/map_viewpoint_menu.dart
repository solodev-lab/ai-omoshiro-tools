import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../utils/solara_storage.dart';
import 'map_vp_panel.dart';

/// 左サイド 📍地点ボタンタップで右に展開するメニュー (2026-05-09)。
///
/// VIEWPOINT (出生地+保存スロット) のクイック切替に特化。
/// LOCATIONS (16方位スコア比較画面) は下部チップ → LocationsScreen を使う。
///
/// 構成:
///   [現在地] [この地点を保存]
///   [🏠 HOME] [💼 職場] [⭐ お気に入り] [📍 場所] ...
class MapViewpointMenu extends StatefulWidget {
  final LatLng center;
  final SolaraProfile? profile;
  final void Function(VPSlot slot) onSlotSelected;
  final VoidCallback onGeolocate;

  /// スロット編集 (rename/icon/delete) 後に親側マーカーを再描画させるためのコールバック。
  final VoidCallback onSlotsChanged;

  const MapViewpointMenu({
    super.key,
    required this.center,
    required this.profile,
    required this.onSlotSelected,
    required this.onGeolocate,
    required this.onSlotsChanged,
  });

  @override
  State<MapViewpointMenu> createState() => _MapViewpointMenuState();
}

class _MapViewpointMenuState extends State<MapViewpointMenu> {
  final SlotManager _mgr = SlotManager(
    storageKey: 'solara_vp_slots',
    defaultNames: ['職場', 'お気に入り', 'スポット', '場所'],
  );
  List<VPSlot> _slots = [];
  String? _msg;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _mgr.syncHome(widget.profile);
    final slots = await _mgr.load();
    if (!mounted) return;
    setState(() => _slots = slots);
  }

  Future<void> _saveCurrent() async {
    final err = await _mgr.saveCurrentLocation(widget.center);
    if (err != null) {
      setState(() => _msg = err);
      Future<void>.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _msg = null);
      });
    } else {
      await _load();
      widget.onSlotsChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xEB0A0A19),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x33C9A84C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // アクションボタン (現在地 / この地点を保存)
          _scrollRow([
            _actionBtn(Icons.my_location, '現在地に移動', widget.onGeolocate),
            _actionBtn(Icons.save_alt, 'この地点を保存', _saveCurrent),
          ]),
          const SizedBox(height: 6),
          // 保存スロット一覧
          if (_slots.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Text(
                '（スロットなし）',
                style: TextStyle(fontSize: 12, color: Color(0xFF555555)),
              ),
            )
          else
            _scrollRow([
              for (final slot in _slots) _slotBtn(slot),
            ]),
          // エラーメッセージ (保存上限超過時など)
          if (_msg != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _msg!,
                style: const TextStyle(fontSize: 12, color: Color(0xFFFF6B6B)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _scrollRow(List<Widget> children) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            children[i],
          ],
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x55C9A84C)),
          color: const Color(0x14C9A84C),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: const Color(0xFFC9A84C)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFC9A84C),
              letterSpacing: 0.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _slotBtn(VPSlot slot) {
    final isActive = (slot.lat - widget.center.latitude).abs() < 0.001 &&
        (slot.lng - widget.center.longitude).abs() < 0.001;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onSlotSelected(slot),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? const Color(0xFFC9A84C) : const Color(0x33C9A84C),
            width: isActive ? 1.4 : 1,
          ),
          color: isActive ? const Color(0x33C9A84C) : Colors.transparent,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(slot.icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 80),
            child: Text(
              slot.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: isActive
                    ? const Color(0xFFC9A84C)
                    : const Color(0xFFAAAAAA),
                letterSpacing: 0.3,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
