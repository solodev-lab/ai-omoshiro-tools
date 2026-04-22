import 'dart:math';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../utils/solara_storage.dart';
import 'map/map_astro.dart';
import 'map/map_constants.dart';
import 'map/map_search.dart';
import 'map/map_vp_panel.dart';

/// Locations 一覧画面 — 登録済み拠点を16方位スコア付きで管理。
/// Map画面から BottomSheet フルスクリーンで開く。
class LocationsScreen extends StatefulWidget {
  final LatLng center;
  final ScoreResult? scoreResult;
  final Map<String, double> sectorScores;
  final SolaraProfile? profile;
  final void Function(VPSlot slot)? onSelectSlot;

  const LocationsScreen({
    super.key,
    required this.center,
    required this.scoreResult,
    required this.sectorScores,
    required this.profile,
    this.onSelectSlot,
  });

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  final SlotManager _mgr = SlotManager(
    storageKey: 'solara_locations',
    defaultNames: ['場所1','場所2','場所3','場所4'],
  );
  List<VPSlot> _slots = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _mgr.syncHome(widget.profile);
    final s = await _mgr.load();
    if (!mounted) return;
    setState(() { _slots = s; _loading = false; });
  }

  Future<void> _addCurrent() async {
    final err = await _mgr.saveCurrentLocation(widget.center);
    if (err != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), duration: const Duration(seconds: 3)),
      );
      return;
    }
    await _load();
  }

  Future<void> _delete(int i) async {
    await _mgr.deleteSlot(i);
    await _load();
  }

  Future<void> _rename(int i) async {
    final ctrl = TextEditingController(text: _slots[i].name);
    final name = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0C0C1A),
        title: const Text('地点の名称を入力',
            style: TextStyle(fontSize: 14, color: Color(0xFFC9A84C))),
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
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('OK', style: TextStyle(color: Color(0xFFC9A84C)))),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    await _mgr.renameSlot(i, name);
    await _load();
  }

  _SlotStats _statsFor(VPSlot s) {
    final hit = SearchHit(name: s.name, lat: s.lat, lng: s.lng);
    final dir = hit.directionFrom(widget.center);
    final score = widget.sectorScores[dir] ?? 0;
    String? fortune;
    if (widget.scoreResult != null) {
      fortune = widget.scoreResult!.sFortune[dir];
    }
    final km = hit.distanceKmFrom(widget.center);
    return _SlotStats(dir: dir, score: score, fortune: fortune, km: km);
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      color: const Color(0xFF0A0A14),
      child: Column(children: [
        // Header
        Container(
          padding: EdgeInsets.fromLTRB(16, topPad + 10, 8, 10),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0x22C9A84C))),
          ),
          child: Row(children: [
            const Text('🌐', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            const Text('LOCATIONS',
                style: TextStyle(fontSize: 13, color: Color(0xFFC9A84C), letterSpacing: 3, fontWeight: FontWeight.w600)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add, color: Color(0xFFC9A84C)),
              tooltip: '現在地を登録',
              onPressed: _addCurrent,
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Color(0xFF888888)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ]),
        ),
        if (_loading) const Expanded(child: Center(
          child: CircularProgressIndicator(color: Color(0xFFC9A84C), strokeWidth: 2),
        )) else Expanded(child: _slots.isEmpty
          ? _emptyState()
          : _buildList()),
      ]),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('🗺', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 14),
        const Text('登録された拠点はまだありません',
            style: TextStyle(fontSize: 12, color: Color(0xFF777777))),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _addCurrent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0x1FC9A84C),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x66C9A84C)),
            ),
            child: const Text('📍 現在地を登録',
                style: TextStyle(fontSize: 11, color: Color(0xFFC9A84C), letterSpacing: 1)),
          ),
        ),
      ]),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _slots.length,
      separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0x11FFFFFF)),
      itemBuilder: (ctx, i) => _buildRow(i),
    );
  }

  Widget _buildRow(int i) {
    final s = _slots[i];
    final stats = _statsFor(s);
    final catColor = stats.fortune != null
        ? (categoryColors[stats.fortune!] ?? const Color(0xFFE8E0D0))
        : const Color(0xFFE8E0D0);
    final dirJp = dir16JP[stats.dir] ?? stats.dir;

    return InkWell(
      onTap: () {
        widget.onSelectSlot?.call(s);
        Navigator.of(context).maybePop();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Text(s.icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Expanded(child: Text(s.name,
                    style: const TextStyle(fontSize: 13, color: Color(0xFFE8E0D0), fontWeight: FontWeight.w600),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                if (s.isHome) Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0x33F9D976),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('HOME', style: TextStyle(fontSize: 8, color: Color(0xFFF9D976), letterSpacing: 1)),
                ),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Text('$dirJp方位',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF999999))),
                const SizedBox(width: 8),
                Text('${_fmtKm(stats.km)} km',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF666666))),
                const SizedBox(width: 8),
                if (stats.fortune != null) Text(
                  (categoryLabels[stats.fortune!] ?? stats.fortune!),
                  style: TextStyle(fontSize: 10, color: catColor),
                ),
              ]),
              const SizedBox(height: 4),
              _scoreBar(stats.score),
            ],
          )),
          const SizedBox(width: 8),
          if (!s.isHome) PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz, color: Color(0xFF888888), size: 18),
            color: const Color(0xFF14142A),
            onSelected: (v) async {
              if (v == 'rename') await _rename(i);
              if (v == 'delete') await _delete(i);
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'rename', child: Text('✏ 名称変更', style: TextStyle(color: Color(0xFFE8E0D0), fontSize: 12))),
              PopupMenuItem(value: 'delete', child: Text('🗑 削除', style: TextStyle(color: Color(0xFFFF6B6B), fontSize: 12))),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _scoreBar(double score) {
    // score 範囲: おおよそ -5..+10 程度。正規化のために max で割る。
    final maxScore = max(1.0, widget.sectorScores.values.fold<double>(0, (a, b) => b > a ? b : a));
    final ratio = (score / maxScore).clamp(0.0, 1.0);
    return Row(children: [
      Expanded(child: Container(
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0x22FFFFFF),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: ratio,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFC9A84C), Color(0xFFF6BD60)],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      )),
      const SizedBox(width: 8),
      SizedBox(
        width: 36,
        child: Text(score.toStringAsFixed(1),
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 10, color: Color(0xFFC9A84C), fontWeight: FontWeight.w600)),
      ),
    ]);
  }

  String _fmtKm(double km) {
    if (km < 10) return km.toStringAsFixed(1);
    return km.toStringAsFixed(0);
  }
}

class _SlotStats {
  final String dir;
  final double score;
  final String? fortune;
  final double km;
  _SlotStats({required this.dir, required this.score, this.fortune, required this.km});
}
