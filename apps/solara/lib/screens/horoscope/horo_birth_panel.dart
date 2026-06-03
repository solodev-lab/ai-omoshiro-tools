import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/solara_storage.dart';
import '../sanctuary/sanctuary_profile_editor.dart' show DateSlashFormatter;
import 'horo_antique_icons.dart';
import 'horo_location_input.dart' show HoroLocationInput;
import 'horo_panel_shared.dart'
    show horoAntiqueHeader, HoroHourMinuteDropdown;

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
  late int _hour;
  late int _minute;
  late bool _timeUnknown;

  // 位置入力 (HoroLocationInput) の現在値。試算時に使う。
  double? _lat;
  double? _lng;
  String? _place;
  String? _tz;

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
    // SolaraProfile.birthDate は YYYY-MM-DD 保存だが、フォーム側は
    // DateSlashFormatter (YYYY/MM/DD 表示) を使うのでスラッシュへ変換。
    _dateCtrl = TextEditingController(text: p.birthDate.replaceAll('-', '/'));
    final timeParts = p.birthTime.split(':');
    _hour = int.tryParse(timeParts.elementAtOrNull(0) ?? '12') ?? 12;
    _minute = int.tryParse(timeParts.elementAtOrNull(1) ?? '0') ?? 0;
    _timeUnknown = p.birthTimeUnknown;
    _lat = p.birthLat == 0 ? null : p.birthLat;
    _lng = p.birthLng == 0 ? null : p.birthLng;
    _place = p.birthPlace.isEmpty ? null : p.birthPlace;
    _tz = p.birthTzName;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  /// 「✨ このデータで試算」押下: フォーム値から SolaraProfile を組んで親へ
  void _apply() {
    final lat = _lat;
    final lng = _lng;
    if (lat == null || lng == null) return;
    if (lat.abs() > 90 || lng.abs() > 180) return;

    // _dateCtrl は YYYY/MM/DD (DateSlashFormatter) で保持されているため
    // SolaraProfile.birthDate 仕様の YYYY-MM-DD に正規化する。
    // 桁数チェック+各要素 int 化で異常入力 (途中入力など) を弾く。
    final dateParts = _dateCtrl.text.split('/');
    if (dateParts.length != 3) return;
    final y = int.tryParse(dateParts[0]);
    final m = int.tryParse(dateParts[1]);
    final d = int.tryParse(dateParts[2]);
    if (y == null || m == null || d == null) return;
    if (m < 1 || m > 12 || d < 1 || d > 31) return;
    final birthDateStr =
        '$y-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';

    final timeStr = _timeUnknown
        ? '12:00'
        : '${_hour.toString().padLeft(2, "0")}:${_minute.toString().padLeft(2, "0")}';

    final newProfile = widget.profile.copyWith(
      name: _nameCtrl.text,
      birthDate: birthDateStr,
      birthTime: timeStr,
      birthTimeUnknown: _timeUnknown,
      birthLat: lat,
      birthLng: lng,
      birthPlace: _place ?? '',
      birthTzName: _tz,
    );
    widget.onApply?.call(newProfile);
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ── ヘッダ + 編集中通知 + リセットボタン ──
      // 注意: isEdited 時に Expanded 兄弟があるため、horoAntiqueHeader (内部に Flexible 持ち)
      // を非flex で配置すると Row layout が unbounded width を渡してエラーになる。
      // Flexible(fit: loose) でラップして flex 子として配置すること。
      Row(children: [
        Flexible(child: horoAntiqueHeader(AntiqueIcon.birth, 'BIRTH DATA')),
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

      // ── お名前 ──
      _labeled('お名前 NAME', _textField(
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
      // 2026-05-07: BottomSheet の SanctuaryResetHourPicker を廃止し、
      // 時/分の独立プルダウン (HoroHourMinuteDropdown) に置換。
      _labeled('出生時刻 TIME', Row(children: [
        Expanded(child: HoroHourMinuteDropdown(
          hour: _hour,
          minute: _minute,
          enabled: !_timeUnknown,
          onHourChanged: (v) => setState(() => _hour = v),
          onMinuteChanged: (v) => setState(() => _minute = v),
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

      // ── 位置入力 (座標貼り付け + 緯度/経度横並び + 地名/TZ 自動) ──
      // 入力粒度の案内 (市区町村でOK・番地不要)。座標貼付式だが「正確な番地まで
      // 突き止めなくてよい」という意味は同じ。全幅 Text なので overflow しない。
      const Padding(
        padding: EdgeInsets.only(bottom: 6),
        child: Text(
          '出生地は市区町村レベルでOK・番地は不要です',
          style: TextStyle(fontSize: 11, color: Color(0xFF9AA0A6), height: 1.4),
        ),
      ),
      // key を profile に紐付け、リセット等で profile が差し替わったら再生成する。
      HoroLocationInput(
        key: ValueKey('birth_${widget.profile.birthLat}_'
            '${widget.profile.birthLng}_${widget.profile.birthDate}_'
            '${widget.profile.birthTime}'),
        initialLat: _lat,
        initialLng: _lng,
        initialPlaceName: _place,
        initialTzName: _tz,
        placeLabel: '出生地名 BIRTHPLACE',
        showTimezone: true,
        onChanged: (lat, lng, place, tz) {
          _lat = lat;
          _lng = lng;
          _place = place;
          _tz = tz;
        },
      ),
      const SizedBox(height: 4),

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
