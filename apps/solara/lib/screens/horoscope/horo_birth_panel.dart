import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/reverse_geocode.dart';
import '../../utils/solara_api.dart';
import '../../utils/solara_storage.dart';
import '../sanctuary/sanctuary_profile_editor.dart' show DateSlashFormatter;
import '../sanctuary/sanctuary_reset_hour_picker.dart';
import 'horo_antique_icons.dart';
import 'horo_panel_shared.dart' show horoAntiqueHeader;

// ══════════════════════════════════════════════════
// Birth Section (BS tab) — Horo 試算用 BIRTH DATA インライン入力
//
// 2026-05-07 全面リファクタ:
//   - 旧: 別画面 (SanctuaryProfileEditorPage) を Navigator push
//   - 新: パネル内に直接フォームを置き、「試算」ボタン押下で親へ反映
//
// 設計方針:
//   - 「友達のデータをちょっと入れて試算したい」程度のユースケース
//   - Sanctuary 画面 (本人 Profile 永続編集) とは完全に分離
//   - 緯度経度は数字 TextField のみ (地図ピッカーは Map 画面で取得してもらう案内)
//   - 出生地名 / TZ は 緯度経度から自動取得して read-only 表示
//   - 時刻は SanctuaryResetHourPicker を BottomSheet で流用 (title 上書き)
// ══════════════════════════════════════════════════

class HoroBirthPanel extends StatefulWidget {
  /// 現在の working profile (画面で表示中の値)
  final SolaraProfile profile;

  /// base と異なるか (true なら「リセット」ボタン表示)
  final bool isEdited;

  /// フォーム値で「試算」が押された時に呼ばれる
  /// 親側で _applyWorkingProfile(newProfile) を呼ぶこと
  final ValueChanged<SolaraProfile>? onApply;

  /// 「リセット」ボタン押下時 (base に戻す)
  final VoidCallback? onReset;

  const HoroBirthPanel({
    super.key,
    required this.profile,
    this.isEdited = false,
    this.onApply,
    this.onReset,
  });

  @override
  State<HoroBirthPanel> createState() => _HoroBirthPanelState();
}

class _HoroBirthPanelState extends State<HoroBirthPanel> {
  late TextEditingController _nameCtrl;
  late TextEditingController _dateCtrl;
  late TextEditingController _latCtrl;
  late TextEditingController _lngCtrl;
  late int _hour;
  late int _minute;
  late bool _timeUnknown;

  // 緯度経度から自動取得した結果 (read-only 表示用)
  String? _autoPlaceName;
  String? _autoTzName;
  bool _geoLoading = false;
  Timer? _geoDebounce;

  @override
  void initState() {
    super.initState();
    _initFromProfile(widget.profile);
  }

  @override
  void didUpdateWidget(HoroBirthPanel old) {
    super.didUpdateWidget(old);
    // 親側で profile が差し替わったら (リセット等) 入力欄を再初期化
    if (old.profile != widget.profile) {
      _initFromProfile(widget.profile);
    }
  }

  void _initFromProfile(SolaraProfile p) {
    _nameCtrl = TextEditingController(text: p.name);
    _dateCtrl = TextEditingController(text: p.birthDate);
    _latCtrl = TextEditingController(
        text: p.birthLat == 0 ? '' : p.birthLat.toStringAsFixed(4));
    _lngCtrl = TextEditingController(
        text: p.birthLng == 0 ? '' : p.birthLng.toStringAsFixed(4));
    final timeParts = p.birthTime.split(':');
    _hour = int.tryParse(timeParts.elementAtOrNull(0) ?? '12') ?? 12;
    _minute = int.tryParse(timeParts.elementAtOrNull(1) ?? '0') ?? 0;
    _timeUnknown = p.birthTimeUnknown;
    _autoPlaceName = p.birthPlace.isEmpty ? null : p.birthPlace;
    _autoTzName = p.birthTzName;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dateCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _geoDebounce?.cancel();
    super.dispose();
  }

  /// 緯度経度入力後のデバウンス→ Worker /tz + Nominatim Reverse を並列取得
  void _scheduleGeoLookup() {
    _geoDebounce?.cancel();
    _geoDebounce = Timer(const Duration(milliseconds: 600), _runGeoLookup);
  }

  Future<void> _runGeoLookup() async {
    final lat = double.tryParse(_latCtrl.text);
    final lng = double.tryParse(_lngCtrl.text);
    if (lat == null || lng == null) return;
    if (lat.abs() > 90 || lng.abs() > 180) return;
    setState(() => _geoLoading = true);
    final results = await Future.wait<String?>([
      reverseGeocode(lat, lng),
      fetchTimezoneName(lat, lng),
    ]);
    if (!mounted) return;
    setState(() {
      _autoPlaceName = results[0];
      _autoTzName = results[1];
      _geoLoading = false;
    });
  }

  Future<void> _pickTime() async {
    final picked = await showModalBottomSheet<({int hour, int minute})>(
      context: context,
      backgroundColor: const Color(0xFF0A0E1C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SanctuaryResetHourPicker(
        initialHour: _hour,
        initialMinute: _minute,
        title: '✦ 出生時刻',
        subtitle: null,
      ),
    );
    if (picked == null) return;
    setState(() {
      _hour = picked.hour;
      _minute = picked.minute;
      _timeUnknown = false;
    });
  }

  /// 「✨ このデータで試算」押下: フォーム値から SolaraProfile を組んで親へ
  void _apply() {
    final lat = double.tryParse(_latCtrl.text);
    final lng = double.tryParse(_lngCtrl.text);
    if (lat == null || lng == null) return;
    if (lat.abs() > 90 || lng.abs() > 180) return;
    if (_dateCtrl.text.length < 8) return; // YYYY/MM/DD 不揃い

    final timeStr = _timeUnknown
        ? '12:00'
        : '${_hour.toString().padLeft(2, "0")}:${_minute.toString().padLeft(2, "0")}';

    final newProfile = widget.profile.copyWith(
      name: _nameCtrl.text,
      birthDate: _dateCtrl.text,
      birthTime: timeStr,
      birthTimeUnknown: _timeUnknown,
      birthLat: lat,
      birthLng: lng,
      birthPlace: _autoPlaceName ?? '',
      birthTzName: _autoTzName,
    );
    widget.onApply?.call(newProfile);
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ── ヘッダ + 編集中通知 + リセットボタン ──
      Row(children: [
        horoAntiqueHeader(AntiqueIcon.birth, 'BIRTH DATA'),
        const SizedBox(width: 8),
        if (widget.isEdited) Expanded(child: Text(
          '※ Horo画面から離れるとBIRTH DATAは初期化されます',
          style: TextStyle(
            fontSize: 10,
            color: const Color(0xFFFF9E6B).withAlpha(220),
            fontStyle: FontStyle.italic,
          ),
          overflow: TextOverflow.visible,
          softWrap: true,
        )),
        if (widget.isEdited)
          GestureDetector(
            onTap: widget.onReset,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0x66F6BD60)),
              ),
              child: Text('リセット',
                  style: GoogleFonts.cinzel(
                      fontSize: 10,
                      color: const Color(0xFFF6BD60),
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600)),
            ),
          ),
      ]),
      const SizedBox(height: 10),

      // ── 氏名 ──
      _labeled('氏名 NAME', _textField(
        controller: _nameCtrl,
        hint: '友人Aの名前 (任意)',
      )),

      // ── 生年月日 ──
      _labeled('生年月日 DATE', _textField(
        controller: _dateCtrl,
        hint: 'YYYY/MM/DD',
        keyboardType: TextInputType.number,
        inputFormatters: [DateSlashFormatter()],
      )),

      // ── 出生時刻 ──
      _labeled('出生時刻 TIME', Row(children: [
        Expanded(child: GestureDetector(
          onTap: _timeUnknown ? null : _pickTime,
          behavior: HitTestBehavior.opaque,
          child: _inputBox(
            child: Text(
              _timeUnknown
                  ? '— : —'
                  : '${_hour.toString().padLeft(2, "0")}:${_minute.toString().padLeft(2, "0")}',
              style: TextStyle(
                fontSize: 13,
                color: _timeUnknown
                    ? const Color(0xFF666666)
                    : const Color(0xFFE8E0D0),
                fontFamily: 'monospace',
                letterSpacing: 1.5,
              ),
            ),
          ),
        )),
        const SizedBox(width: 8),
        // 不明 toggle
        GestureDetector(
          onTap: () => setState(() => _timeUnknown = !_timeUnknown),
          behavior: HitTestBehavior.opaque,
          child: Row(children: [
            Container(
              width: 14, height: 14,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: _timeUnknown
                      ? const Color(0xFFF6BD60)
                      : const Color(0x33FFFFFF),
                  width: 1.5,
                ),
                color: _timeUnknown
                    ? const Color(0x22F6BD60)
                    : Colors.transparent,
              ),
              child: _timeUnknown
                  ? const Center(
                      child: Text('✓',
                          style: TextStyle(
                              fontSize: 9, color: Color(0xFFF6BD60))))
                  : null,
            ),
            const SizedBox(width: 6),
            const Text('不明',
                style: TextStyle(fontSize: 11, color: Color(0xFFAAAAAA))),
          ]),
        ),
      ])),

      // ── 緯度 / 経度 ──
      _labeled('緯度 LATITUDE', _textField(
        controller: _latCtrl,
        hint: '例: 35.6762',
        keyboardType: const TextInputType.numberWithOptions(
            decimal: true, signed: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]')),
        ],
        onChanged: (_) => _scheduleGeoLookup(),
      )),
      _labeled('経度 LONGITUDE', _textField(
        controller: _lngCtrl,
        hint: '例: 139.6503',
        keyboardType: const TextInputType.numberWithOptions(
            decimal: true, signed: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]')),
        ],
        onChanged: (_) => _scheduleGeoLookup(),
      )),

      // ── 出生地名 (緯度経度から自動取得・read-only) ──
      _labeled('出生地名 BIRTHPLACE', _inputBox(
        child: Row(children: [
          if (_geoLoading)
            const SizedBox(
              width: 12, height: 12,
              child: CircularProgressIndicator(
                  strokeWidth: 1.5, color: Color(0xFFC9A84C)),
            )
          else
            Expanded(child: Text(
              _autoPlaceName ?? '— (緯度経度入力後に自動取得)',
              style: TextStyle(
                fontSize: 13,
                color: _autoPlaceName == null
                    ? const Color(0xFF666666)
                    : const Color(0xFFE8E0D0),
              ),
            )),
        ]),
      )),

      // ── タイムゾーン (緯度経度から自動取得・read-only) ──
      _labeled('タイムゾーン TZ', _inputBox(
        child: Text(
          _autoTzName ?? '— (緯度経度入力後に自動取得)',
          style: TextStyle(
            fontSize: 12,
            color: _autoTzName == null
                ? const Color(0xFF666666)
                : const Color(0xFFCCCCCC),
            fontFamily: 'monospace',
          ),
        ),
      )),

      // ── 案内文 ──
      const Padding(
        padding: EdgeInsets.only(top: 4, bottom: 12),
        child: Text(
          '※ 緯度経度はMap画面で地点をタップして座標を確認できます',
          style: TextStyle(
            fontSize: 10,
            color: Color(0x99888888),
            fontStyle: FontStyle.italic,
            height: 1.4,
          ),
        ),
      ),

      // ── 試算ボタン ──
      GestureDetector(
        onTap: _apply,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFFF6BD60), Color(0xFFE8A840)],
            ),
          ),
          child: const Center(child: Text(
            '✨ このデータで試算',
            style: TextStyle(
              color: Color(0xFF0A0A14),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          )),
        ),
      ),
    ]);
  }

  // ── form helpers ──

  Widget _labeled(String label, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF888888),
                letterSpacing: 1)),
        const SizedBox(height: 3),
        child,
      ]),
    );
  }

  Widget _inputBox({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: child,
    );
  }

  Widget _textField({
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 13, color: Color(0xFFE8E0D0)),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0x59ACACAC)),
        ),
      ),
    );
  }
}
