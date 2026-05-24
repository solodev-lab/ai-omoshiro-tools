import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/reverse_geocode.dart';
import '../../utils/solara_api.dart';

// ══════════════════════════════════════════════════════════════
// Horo 位置入力 (座標貼り付け + 緯度/経度横並び + 地名自動 + TZ自動)
//
// Birth パネル / Transit パネル 共通。Map 画面の「座標取得」でクリップボードへ
// コピーした "緯度, 経度" を「座標貼り付け」で取り込む。手入力も可。
// 緯度経度から地名 (reverseGeocode) と TZ (fetchTimezoneName) を自動取得する。
// lat/lng/placeName/tzName が変わるたびに onChanged で親へ通知する。
// ══════════════════════════════════════════════════════════════
class HoroLocationInput extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final String? initialPlaceName;
  final String? initialTzName;

  /// 地名欄のラベル (Birth='出生地名 BIRTHPLACE' / Transit='地名 PLACE' 等)。
  final String placeLabel;

  /// TZ 欄を表示するか (Birth=true / Transit=false)。
  final bool showTimezone;

  /// lat/lng/placeName/tzName が変わるたびに呼ばれる。
  final void Function(double? lat, double? lng, String? placeName, String? tzName)
      onChanged;

  const HoroLocationInput({
    super.key,
    this.initialLat,
    this.initialLng,
    this.initialPlaceName,
    this.initialTzName,
    this.placeLabel = '地名 PLACE',
    this.showTimezone = false,
    required this.onChanged,
  });

  @override
  State<HoroLocationInput> createState() => _HoroLocationInputState();
}

class _HoroLocationInputState extends State<HoroLocationInput> {
  late final TextEditingController _latCtrl;
  late final TextEditingController _lngCtrl;
  String? _placeName;
  String? _tzName;
  bool _loading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _latCtrl = TextEditingController(text: _fmtInit(widget.initialLat));
    _lngCtrl = TextEditingController(text: _fmtInit(widget.initialLng));
    _placeName = widget.initialPlaceName?.isEmpty == true
        ? null
        : widget.initialPlaceName;
    _tzName = widget.initialTzName;
  }

  static String _fmtInit(double? v) =>
      (v == null || v == 0) ? '' : v.toStringAsFixed(4);

  @override
  void dispose() {
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  double? get _lat => double.tryParse(_latCtrl.text);
  double? get _lng => double.tryParse(_lngCtrl.text);

  void _notify() =>
      widget.onChanged(_lat, _lng, _placeName, _tzName);

  /// 手入力時: まず座標だけ親へ反映し、600ms デバウンスで地名/TZ を取得。
  void _onManualEdit() {
    _notify();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _runGeoLookup);
  }

  Future<void> _runGeoLookup() async {
    final lat = _lat;
    final lng = _lng;
    if (lat == null || lng == null) return;
    if (lat.abs() > 90 || lng.abs() > 180) return;
    setState(() => _loading = true);
    final results = await Future.wait<String?>([
      reverseGeocode(lat, lng),
      fetchTimezoneName(lat, lng),
    ]);
    if (!mounted) return;
    setState(() {
      _placeName = results[0];
      _tzName = results[1];
      _loading = false;
    });
    _notify();
  }

  Future<void> _pasteCoords() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = (data?.text ?? '').trim();
    // "緯度, 経度" (カンマ / 空白区切り) を解析。
    final parts = text.split(RegExp(r'[,\s]+'));
    double? lat;
    double? lng;
    if (parts.length >= 2) {
      lat = double.tryParse(parts[0]);
      lng = double.tryParse(parts[1]);
    }
    if (lat == null || lng == null || lat.abs() > 90 || lng.abs() > 180) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('クリップボードに有効な「緯度, 経度」がありません'),
          duration: Duration(seconds: 2),
        ));
      }
      return;
    }
    setState(() {
      _latCtrl.text = lat!.toStringAsFixed(6);
      _lngCtrl.text = lng!.toStringAsFixed(6);
    });
    _notify();
    _debounce?.cancel();
    _runGeoLookup();
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ── 座標貼り付け + 案内 ──
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        GestureDetector(
          onTap: _pasteCoords,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0x66F6BD60)),
              color: const Color(0x14F6BD60),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.content_paste, size: 14, color: Color(0xFFF6BD60)),
              SizedBox(width: 6),
              Text('座標貼り付け',
                  style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFF6BD60),
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Map画面で地点をタップ→「座標取得」でコピーできます',
            style: TextStyle(
                fontSize: 10, color: Color(0x99888888), height: 1.3),
          ),
        ),
      ]),
      const SizedBox(height: 10),

      // ── 地名 (緯度経度から自動取得・read-only) ──
      _labeled(widget.placeLabel, _autoBox(
        child: _loading
            ? const SizedBox(
                width: 12, height: 12,
                child: CircularProgressIndicator(
                    strokeWidth: 1.5, color: Color(0xFFC9A84C)),
              )
            : Text(
                _placeName ?? '— (座標入力後に自動取得)',
                style: TextStyle(
                  fontSize: 13,
                  color: _placeName == null
                      ? const Color(0xFF666666)
                      : const Color(0xFFE8E0D0),
                ),
              ),
      )),

      // ── 緯度 (左) / 経度 (右) 横並び ──
      Row(children: [
        Expanded(child: _labeled('緯度 LAT', _coordField(_latCtrl, '例: 35.6762'))),
        const SizedBox(width: 8),
        Expanded(child: _labeled('経度 LNG', _coordField(_lngCtrl, '例: 139.6503'))),
      ]),

      // ── タイムゾーン (緯度経度から自動取得・read-only) ──
      if (widget.showTimezone)
        _labeled('タイムゾーン TZ', _autoBox(
          child: Text(
            _tzName ?? '— (座標入力後に自動取得)',
            style: TextStyle(
              fontSize: 12,
              color: _tzName == null
                  ? const Color(0xFF666666)
                  : const Color(0xFFCCCCCC),
              fontFamily: 'monospace',
            ),
          ),
        )),
    ]);
  }

  Widget _labeled(String label, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: Color(0xFF888888), letterSpacing: 1)),
        const SizedBox(height: 3),
        child,
      ]),
    );
  }

  Widget _autoBox({required Widget child}) {
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

  Widget _coordField(TextEditingController controller, String hint) {
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
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true, signed: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]')),
        ],
        onChanged: (_) => _onManualEdit(),
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
