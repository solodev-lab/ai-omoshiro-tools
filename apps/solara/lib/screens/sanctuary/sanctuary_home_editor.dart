import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../utils/solara_storage.dart';

// ══════════════════════════════════════════════════
// ── Home Info Editor Page ──
// HTML exact: #homeOverlay (Nominatim search + lat/lng)
// ══════════════════════════════════════════════════

class SanctuaryHomeEditorPage extends StatefulWidget {
  final SolaraProfile? profile;
  const SanctuaryHomeEditorPage({super.key, this.profile});

  @override
  State<SanctuaryHomeEditorPage> createState() => _SanctuaryHomeEditorPageState();
}

class _SanctuaryHomeEditorPageState extends State<SanctuaryHomeEditorPage> {
  late final TextEditingController _nameCtrl;
  double? _lat;
  double? _lng;
  String _searchResult = '';
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameCtrl = TextEditingController(text: p?.homeName ?? '');
    if (p != null && p.homeLat != 0) _lat = p.homeLat;
    if (p != null && p.homeLng != 0) _lng = p.homeLng;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _nameCtrl.text.trim();
    if (query.isEmpty) return;
    setState(() { _searching = true; _searchResult = ''; });
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(query)}&limit=1&accept-language=ja',
      );
      final resp = await http.get(uri, headers: {'User-Agent': 'Solara/1.0'});
      final data = json.decode(resp.body) as List;
      if (data.isNotEmpty) {
        final lat = double.parse(data[0]['lat'] as String);
        final lng = double.parse(data[0]['lon'] as String);
        final display = (data[0]['display_name'] as String).length > 50
            ? (data[0]['display_name'] as String).substring(0, 50)
            : data[0]['display_name'] as String;
        setState(() { _lat = lat; _lng = lng; _searchResult = display; _searching = false; });
      } else {
        setState(() { _searchResult = '見つかりませんでした'; _searching = false; });
      }
    } catch (_) {
      setState(() { _searchResult = '通信エラー'; _searching = false; });
    }
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _lat == null || _lng == null) return;

    final p = widget.profile ?? const SolaraProfile();
    final updated = SolaraProfile(
      name: p.name,
      birthDate: p.birthDate,
      birthTime: p.birthTime,
      birthTimeUnknown: p.birthTimeUnknown,
      birthPlace: p.birthPlace,
      birthLat: p.birthLat,
      birthLng: p.birthLng,
      birthTz: p.birthTz,
      homeName: name,
      homeLat: _lat!,
      homeLng: _lng!,
    );
    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020408),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              decoration: BoxDecoration(
                color: const Color(0x0DFFFFFF),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0x1AFFFFFF)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Header
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.home_rounded, size: 18, color: Color(0xFFF9D976)),
                    SizedBox(width: 8),
                    Text('自宅（現住所）', style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFF9D976), letterSpacing: 1)),
                  ]),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32, height: 32,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x14FFFFFF)),
                      child: const Center(child: Icon(Icons.close, size: 18, color: Color(0xFFACACAC))),
                    ),
                  ),
                ]),
                const SizedBox(height: 20),

                // Search
                const Text('住所・地名', style: TextStyle(fontSize: 12, color: Color(0xFFACACAC), letterSpacing: 0.5)),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(child: _input(_nameCtrl, '例: 東京都渋谷区')),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _searching ? null : _search,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(colors: [Color(0xFFF9D976), Color(0xFFE8A840)]),
                      ),
                      child: Text(_searching ? '...' : '検索',
                        style: const TextStyle(color: Color(0xFF0A0A14), fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ]),
                if (_searchResult.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(_searchResult, style: const TextStyle(fontSize: 11, color: Color(0xFF6CC070))),
                  ),
                const SizedBox(height: 8),

                // Lat/Lng
                Row(children: [
                  Expanded(child: _readonlyField('緯度', _lat?.toStringAsFixed(4) ?? '')),
                  const SizedBox(width: 8),
                  Expanded(child: _readonlyField('経度', _lng?.toStringAsFixed(4) ?? '')),
                ]),
                const SizedBox(height: 16),

                // Save
                GestureDetector(
                  onTap: _save,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(colors: [Color(0xFFF9D976), Color(0xFFE8A840)]),
                    ),
                    child: const Center(child: Text('保存する',
                      style: TextStyle(color: Color(0xFF0A0A14), fontSize: 15, fontWeight: FontWeight.w700))),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _input(TextEditingController ctrl, String hint) => TextField(
    controller: ctrl,
    style: const TextStyle(color: Color(0xFFEAEAEA), fontSize: 14),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0x40FFFFFF)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: const Color(0x0FFFFFFF),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0x1EFFFFFF))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0x1EFFFFFF))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0x66F9D976))),
    ),
  );

  Widget _readonlyField(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFFACACAC))),
      const SizedBox(height: 4),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0x0FFFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x1EFFFFFF)),
        ),
        child: Text(value.isEmpty ? '—' : value,
          style: TextStyle(fontSize: 14, color: value.isEmpty ? const Color(0x40FFFFFF) : const Color(0xFFEAEAEA))),
      ),
    ],
  );
}
