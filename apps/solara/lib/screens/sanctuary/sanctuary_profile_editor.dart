import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../utils/app_locale.dart';
import '../../utils/solara_storage.dart';
import '../../utils/solara_api.dart';

// ══════════════════════════════════════════════════
// ── Profile Editor Page ──
// (Separate full-screen page matching HTML birth overlay)
// ══════════════════════════════════════════════════

class SanctuaryProfileEditorPage extends StatefulWidget {
  final SolaraProfile? profile;
  const SanctuaryProfileEditorPage({super.key, this.profile});

  @override
  State<SanctuaryProfileEditorPage> createState() => _SanctuaryProfileEditorPageState();
}

class _SanctuaryProfileEditorPageState extends State<SanctuaryProfileEditorPage> {
  late TextEditingController _nameCtrl;
  late TextEditingController _birthDateCtrl;
  DateTime? _birthDate;
  TimeOfDay? _birthTime;
  bool _birthTimeUnknown = false;
  String _birthPlace = '';
  double _birthLat = 0;
  double _birthLng = 0;
  int _birthTz = 9;
  String? _birthTzName;

  final TextEditingController _placeCtrl = TextEditingController();
  List<Map<String, dynamic>> _placeResults = [];
  bool _searching = false;
  bool _resolvingTz = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    if (p != null && p.birthDate.isNotEmpty) {
      final parts = p.birthDate.split('-').map(int.parse).toList();
      _birthDate = DateTime(parts[0], parts[1], parts[2]);
      _birthDateCtrl = TextEditingController(text: '${parts[0]}/${parts[1].toString().padLeft(2, '0')}/${parts[2].toString().padLeft(2, '0')}');
    } else {
      _birthDateCtrl = TextEditingController();
    }
    if (p != null && !p.birthTimeUnknown && p.birthTime.isNotEmpty) {
      final tp = p.birthTime.split(':').map(int.parse).toList();
      _birthTime = TimeOfDay(hour: tp[0], minute: tp[1]);
    }
    _birthTimeUnknown = p?.birthTimeUnknown ?? false;
    _birthPlace = p?.birthPlace ?? '';
    _birthLat = p?.birthLat ?? 0;
    _birthLng = p?.birthLng ?? 0;
    _birthTz = p?.birthTz ?? 9;
    _birthTzName = p?.birthTzName;
    _placeCtrl.text = _birthPlace;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _birthDateCtrl.dispose();
    _placeCtrl.dispose();
    super.dispose();
  }

  // 時間(0-23)と分(0-59)の選択肢
  static final _hourOptions = List.generate(24, (i) => i.toString().padLeft(2, '0'));
  static final _minuteOptions = List.generate(60, (i) => i.toString().padLeft(2, '0'));

  Future<void> _searchPlace(String query) async {
    if (query.length < 2) return;
    setState(() => _searching = true);
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&addressdetails=1',
      );
      final resp = await http.get(uri, headers: {
        'User-Agent': 'SolaraApp/1.0 (solodev-lab.com)',
        'Accept-Language': 'ja,en',
      });
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as List;
        setState(() {
          _placeResults = data.map<Map<String, dynamic>>((item) => {
            'name': item['display_name'] as String,
            'lat': double.parse(item['lat'] as String),
            'lng': double.parse(item['lon'] as String),
          }).toList();
        });
      }
    } catch (_) {
      // Silently fail
    } finally {
      setState(() => _searching = false);
    }
  }

  void _selectPlace(Map<String, dynamic> place) {
    setState(() {
      _birthPlace = place['name'] as String;
      _birthLat = place['lat'] as double;
      _birthLng = place['lng'] as double;
      _placeCtrl.text = _birthPlace;
      _placeResults = [];
      _birthTzName = null; // 新しい場所を選択したのでリセット
      _resolvingTz = true;
    });
    // C案: 緯度経度から IANA TZ名 を自動取得 (DST対応)
    _resolveTimezone();
  }

  Future<void> _resolveTimezone() async {
    final lat = _birthLat;
    final lng = _birthLng;
    final tzName = await fetchTimezoneName(lat, lng);
    if (!mounted) return;
    // 結果到着前に別の場所に変わっていたら無視
    if (_birthLat != lat || _birthLng != lng) return;
    setState(() {
      _birthTzName = tzName;
      _resolvingTz = false;
    });
  }

  void _save() {
    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('生年月日を入力してください')),
      );
      return;
    }
    if (_birthPlace.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('出生地を入力してください')),
      );
      return;
    }

    final dateStr = '${_birthDate!.year}-'
        '${_birthDate!.month.toString().padLeft(2, '0')}-'
        '${_birthDate!.day.toString().padLeft(2, '0')}';
    final timeStr = _birthTimeUnknown
        ? '12:00'
        : '${(_birthTime?.hour ?? 12).toString().padLeft(2, '0')}:'
          '${(_birthTime?.minute ?? 0).toString().padLeft(2, '0')}';

    final profile = SolaraProfile(
      name: _nameCtrl.text.trim(),
      birthDate: dateStr,
      birthTime: timeStr,
      birthTimeUnknown: _birthTimeUnknown,
      birthPlace: _birthPlace,
      birthLat: _birthLat,
      birthLng: _birthLng,
      birthTz: _birthTz,
      birthTzName: _birthTzName,
    );

    Navigator.of(context).pop(profile);
  }

  @override
  Widget build(BuildContext context) {
    // HTML: .birth-overlay { background:rgba(4,8,16,0.95); backdrop-filter:blur(12px); }
    // HTML: .birth-card { max-width:420px; width:92%; padding:24px 20px 32px; border-radius:24px; }
    return Scaffold(
      backgroundColor: const Color(0xFF020408),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                decoration: BoxDecoration(
                  color: const Color(0x0DFFFFFF),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0x1AFFFFFF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('✦ 出生情報',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFF9D976), letterSpacing: 1)),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 32, height: 32,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0x14FFFFFF),
                            ),
                            child: const Center(child: Text('✕', style: TextStyle(fontSize: 18, color: Color(0xFFACACAC)))),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 氏名
                    _birthSection('氏名', TextField(
                      controller: _nameCtrl,
                      style: const TextStyle(color: Color(0xFFEAEAEA), fontSize: 14),
                      decoration: _inputDecoration('氏名を入力'),
                    )),

                    // 生年月日 — auto-format: 19901231 → 1990/12/31
                    _birthSection('生年月日', TextField(
                      controller: _birthDateCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Color(0xFFEAEAEA), fontSize: 14),
                      decoration: _inputDecoration('YYYY/MM/DD'),
                      inputFormatters: [DateSlashFormatter()],
                      onChanged: (v) {
                        final parts = v.split('/');
                        if (parts.length == 3 && parts[2].length == 2) {
                          final y = int.tryParse(parts[0]);
                          final m = int.tryParse(parts[1]);
                          final d = int.tryParse(parts[2]);
                          if (y != null && m != null && d != null && y > 1900 && m >= 1 && m <= 12 && d >= 1 && d <= 31) {
                            setState(() => _birthDate = DateTime(y, m, d));
                          }
                        }
                      },
                    )),

                    // 出生時刻 — 24時間表記ドロップダウン（30分刻み）
                    _birthSection('出生時刻', Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 時間・分 2つのドロップダウン
                        Row(children: [
                          // 時間 (00-23)
                          Expanded(child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0x0FFFFFFF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0x1FFFFFFF)),
                            ),
                            child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                              value: _birthTimeUnknown ? null : _birthTime != null ? _birthTime!.hour.toString().padLeft(2, '0') : null,
                              hint: Text(_birthTimeUnknown ? '12' : '時', style: TextStyle(fontSize: 14, color: _birthTimeUnknown ? const Color(0x59EAEAEA) : const Color(0x99EAEAEA))),
                              isExpanded: true, dropdownColor: const Color(0xFF0A1220),
                              style: const TextStyle(fontSize: 14, color: Color(0xFFEAEAEA)),
                              icon: Icon(Icons.arrow_drop_down, color: _birthTimeUnknown ? const Color(0x59EAEAEA) : const Color(0xFFACACAC)),
                              items: _birthTimeUnknown ? null : _hourOptions.map((h) => DropdownMenuItem(value: h, child: Text('$h 時'))).toList(),
                              onChanged: _birthTimeUnknown ? null : (val) {
                                if (val != null) setState(() => _birthTime = TimeOfDay(hour: int.parse(val), minute: _birthTime?.minute ?? 0));
                              },
                            )),
                          )),
                          const SizedBox(width: 8),
                          const Text(':', style: TextStyle(fontSize: 18, color: Color(0xFFACACAC))),
                          const SizedBox(width: 8),
                          // 分 (00-59)
                          Expanded(child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0x0FFFFFFF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0x1FFFFFFF)),
                            ),
                            child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                              value: _birthTimeUnknown ? null : _birthTime != null ? _birthTime!.minute.toString().padLeft(2, '0') : null,
                              hint: Text(_birthTimeUnknown ? '00' : '分', style: TextStyle(fontSize: 14, color: _birthTimeUnknown ? const Color(0x59EAEAEA) : const Color(0x99EAEAEA))),
                              isExpanded: true, dropdownColor: const Color(0xFF0A1220),
                              style: const TextStyle(fontSize: 14, color: Color(0xFFEAEAEA)),
                              icon: Icon(Icons.arrow_drop_down, color: _birthTimeUnknown ? const Color(0x59EAEAEA) : const Color(0xFFACACAC)),
                              items: _birthTimeUnknown ? null : _minuteOptions.map((m) => DropdownMenuItem(value: m, child: Text('$m 分'))).toList(),
                              onChanged: _birthTimeUnknown ? null : (val) {
                                if (val != null) setState(() => _birthTime = TimeOfDay(hour: _birthTime?.hour ?? 12, minute: int.parse(val)));
                              },
                            )),
                          )),
                        ]),
                        // HTML: .time-unknown-row { display:flex; align-items:center; gap:8px; margin-top:8px; }
                        const SizedBox(height: 8),
                        Row(children: [
                          SizedBox(width: 18, height: 18,
                            child: Checkbox(
                              value: _birthTimeUnknown,
                              onChanged: (v) => setState(() => _birthTimeUnknown = v ?? false),
                              activeColor: const Color(0xFFF9D976),
                              side: const BorderSide(color: Color(0xFFACACAC)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => setState(() => _birthTimeUnknown = !_birthTimeUnknown),
                            child: const Text('出生時刻が分からない',
                              style: TextStyle(fontSize: 12, color: Color(0xFFACACAC))),
                          ),
                        ]),
                        // HTML: .time-noon-hint
                        if (_birthTimeUnknown) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0x14F9D976),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '鑑定には惑星配置とアスペクト情報を使用します。ハウス・ASC・MCの鑑定は省略されます。',
                              style: TextStyle(color: Color(0xFFF9D976), fontSize: 11, height: 1.4),
                            ),
                          ),
                        ],
                      ],
                    )),

                    // 出生地
                    _birthSection('出生地', Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // HTML: .map-search-row { display:flex; gap:8px; }
                        Row(children: [
                          Expanded(child: TextField(
                            controller: _placeCtrl,
                            style: const TextStyle(color: Color(0xFFEAEAEA), fontSize: 14),
                            decoration: _inputDecoration('例: 岐阜県岐阜市'),
                            onSubmitted: _searchPlace,
                          )),
                          const SizedBox(width: 8),
                          // HTML: .map-search-btn
                          GestureDetector(
                            onTap: () => _searchPlace(_placeCtrl.text),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                                  colors: [Color(0xFFF9D976), Color(0xFFE8A840)],
                                ),
                              ),
                              child: const Text('検索', style: TextStyle(
                                color: Color(0xFF0A0A14), fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ]),
                        if (_searching)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Center(child: SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF9D976)))),
                          ),
                        if (_placeResults.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A1220),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0x1AFFFFFF)),
                            ),
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: _placeResults.length,
                              separatorBuilder: (_, __) => const Divider(color: Color(0x1AFFFFFF), height: 1),
                              itemBuilder: (_, i) {
                                final place = _placeResults[i];
                                return ListTile(
                                  dense: true,
                                  title: Text(place['name'] as String,
                                    style: const TextStyle(color: Color(0xFFEAEAEA), fontSize: 13),
                                    maxLines: 2, overflow: TextOverflow.ellipsis),
                                  leading: const Icon(Icons.location_on, color: Color(0xFFF9D976), size: 18),
                                  onTap: () => _selectPlace(place),
                                );
                              },
                            ),
                          ),
                        ],
                        // HTML: .map-coords
                        if (_birthLat != 0 && _birthLng != 0) ...[
                          const SizedBox(height: 8),
                          Row(children: [
                            Expanded(child: _readonlyField('緯度', _birthLat.toStringAsFixed(4))),
                            const SizedBox(width: 8),
                            Expanded(child: _readonlyField('経度', _birthLng.toStringAsFixed(4))),
                          ]),
                          // C案: 取得した IANA TZ名 を表示 (DST自動考慮)
                          const SizedBox(height: 6),
                          Row(children: [
                            const Icon(Icons.schedule, size: 14, color: Color(0xFFACACAC)),
                            const SizedBox(width: 6),
                            Expanded(child: Text(
                              _resolvingTz
                                ? 'タイムゾーン判定中…'
                                : (_birthTzName != null
                                    ? 'タイムゾーン: $_birthTzName (DST自動)'
                                    : 'タイムゾーン: UTC+$_birthTz (固定)'),
                              style: const TextStyle(fontSize: 11, color: Color(0xFFACACAC)),
                              overflow: TextOverflow.ellipsis,
                            )),
                          ]),
                        ],
                      ],
                    )),

                    const SizedBox(height: 16),

                    // 言語切替
                    _birthSection('言語 / Language', ValueListenableBuilder<Locale?>(
                      valueListenable: AppLocale.instance.notifier,
                      builder: (_, currentLocale, __) {
                        final code = currentLocale?.languageCode;
                        return Row(children: [
                          _langBtn('端末', 'システム設定', code == null, () =>
                            AppLocale.instance.setOverride(null)),
                          const SizedBox(width: 8),
                          _langBtn('日本語', 'Japanese', code == 'ja', () =>
                            AppLocale.instance.setOverride('ja')),
                          const SizedBox(width: 8),
                          _langBtn('English', '英語', code == 'en', () =>
                            AppLocale.instance.setOverride('en')),
                        ]);
                      },
                    )),

                    const SizedBox(height: 16),

                    // Save button
                    // HTML: .birth-save-btn { width:100%; padding:14px; border-radius:14px; }
                    GestureDetector(
                      onTap: _save,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                            colors: [Color(0xFFF9D976), Color(0xFFE8A840)],
                          ),
                        ),
                        child: const Center(
                          child: Text('保存する', style: TextStyle(
                            color: Color(0xFF0A0A14), fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // HTML: .birth-section { margin-bottom:18px; }
  Widget _langBtn(String primary, String sub, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: active
              ? const Color(0x33F9D976) : const Color(0x0FFFFFFF),
            border: Border.all(
              color: active
                ? const Color(0xFFF9D976) : const Color(0x20FFFFFF),
              width: active ? 1.5 : 1,
            ),
          ),
          child: Column(children: [
            Text(primary, style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: active ? const Color(0xFFF9D976) : const Color(0xFFE0E0E0),
            )),
            const SizedBox(height: 2),
            Text(sub, style: TextStyle(
              fontSize: 10,
              color: active
                ? const Color(0xFFF9D976).withAlpha(180)
                : const Color(0xFF888888),
            )),
          ]),
        ),
      ),
    );
  }

  Widget _birthSection(String label, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HTML: .birth-label { font-size:12px; color:#ACACAC; letter-spacing:0.5px; text-transform:uppercase; }
          Text(label.toUpperCase(),
            style: const TextStyle(fontSize: 12, color: Color(0xFFACACAC), letterSpacing: 0.5)),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  // HTML: .birth-input { padding:12px 14px; background:rgba(255,255,255,0.06);
  //   border:1px solid rgba(255,255,255,0.12); border-radius:12px; color:#EAEAEA; font-size:14px; }
  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0x66EAEAEA)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    filled: true,
    fillColor: const Color(0x0FFFFFFF), // rgba(255,255,255,0.06)
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0x1FFFFFFF))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0x1FFFFFFF))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0x66F9D976))), // rgba(249,217,118,0.4)
  );

  Widget _readonlyField(String hint, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0x0FFFFFFF),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0x1FFFFFFF)),
    ),
    child: Text(value.isEmpty ? hint : value,
      style: TextStyle(fontSize: 14, color: value.isEmpty ? const Color(0x66EAEAEA) : const Color(0xFFEAEAEA))),
  );
}

/// Auto-inserts `/` after YYYY and MM for date input (YYYY/MM/DD format).
/// Only allows digits; max 8 digits (10 chars with slashes).
class DateSlashFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Strip non-digits
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 8) {
      // Max 8 digits: YYYYMMDD
      return oldValue;
    }

    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 4 || i == 6) buf.write('/');
      buf.write(digits[i]);
    }
    final formatted = buf.toString();

    // Cursor at end
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
