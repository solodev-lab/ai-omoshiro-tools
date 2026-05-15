// Consultation Place Picker Screen — Stage 1 「地図で選ぶ」 (Hybrid B)
//
// 設計: apps/solara/docs/pro_candidates.md §7.2 Stage 1
//        + chat 議論 (2026-05-16) 「A + B ハイブリッド」案
//
// 役割:
//   - Consultation Input 画面の inline picker (A) から「🗺 地図で選ぶ」で push
//   - flutter_map で全画面の地図を表示し、検索 / マップタップで地点選択
//   - 決定で ConsultationPresetTarget を返す (Navigator.pop の引数)
//   - キャンセル / 戻る で null を返す
//
// map_screen との関係:
//   - map_screen.dart (~2700 行) は触らない (独立画面)
//   - flutter_map package を直接使い、Solara の地図テーマ (osmHotDark) と
//     共通の TileLayer ビルダ (buildStyledTileLayer) のみ流用
//   - 検索は map_search.dart の searchPlaces / SearchHit を流用
//   - 逆ジオコーディングは reverse_geocode.dart の reverseGeocodeDetail を使う
//
// UI 構造:
//   ┌─ AppBar (戻る / タイトル) ────────────────────┐
//   │  [検索 ____________________]  ✕              │
//   │  [候補1] [候補2] [候補3]                      │  ← suggestions overlay
//   ├──────────────────────────────────────────────┤
//   │                                              │
//   │     flutter_map (全画面、osmHotDark)         │
//   │       タップで点選択 → ピン                   │
//   │       検索結果は番号付きピン                  │
//   │                                              │
//   ├──────────────────────────────────────────────┤
//   │  ✓ 京都 (京都府 / JP)                        │  ← 選択中カード
//   │  35.011°N, 135.768°E                         │
//   │  [ キャンセル ]   [ ✓ この地点で相談 ]       │
//   └──────────────────────────────────────────────┘

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../theme/solara_colors.dart';
import '../../utils/reverse_geocode.dart';
import '../map/map_search.dart';
import '../map/map_styles.dart';
import 'consultation_input_screen.dart' show ConsultationPresetTarget;

/// 地点選択画面 (B、フルスクリーン)。
/// 決定時に [ConsultationPresetTarget] を pop の引数で返す。
/// キャンセル時は null。
class ConsultationPlacePickerScreen extends StatefulWidget {
  /// 初期表示中心 (null なら 日本 中央あたり)。
  final LatLng? initialCenter;

  /// 初期ズーム (null なら 5)。
  final double? initialZoom;

  const ConsultationPlacePickerScreen({
    super.key,
    this.initialCenter,
    this.initialZoom,
  });

  @override
  State<ConsultationPlacePickerScreen> createState() =>
      _ConsultationPlacePickerScreenState();
}

class _ConsultationPlacePickerScreenState
    extends State<ConsultationPlacePickerScreen> {
  static const _defaultCenter = LatLng(36.2048, 138.2529); // 日本中央
  static const _defaultZoom = 5.0;

  final MapController _mapCtrl = MapController();
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final StreamController<void> _tileResetCtrl =
      StreamController<void>.broadcast();
  Timer? _debounce;

  bool _searching = false;
  List<SearchHit> _hits = const [];

  /// 選択中の点。
  LatLng? _picked;
  String? _pickedName;
  String? _pickedRegion;
  String? _pickedCountry; // ISO code (JP/US)
  bool _resolvingName = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _tileResetCtrl.close();
    _mapCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    final q = value.trim();
    if (q.length < 2) {
      setState(() {
        _hits = const [];
        _searching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () => _runSearch(q));
  }

  Future<void> _runSearch(String q) async {
    setState(() => _searching = true);
    // 現在のマップ中心を bias center にする (Google Places の locationBias 15km)。
    // ユーザーが見ている範囲のクエリ ('スターバックス' 等) が周辺優先になる。
    LatLng? bias;
    try {
      bias = _mapCtrl.camera.center;
    } catch (_) {
      // map がまだ build されていないケース (実質ありえないが防御)
      bias = widget.initialCenter;
    }
    final hits = await searchPlaces(q, biasCenter: bias);
    if (!mounted) return;
    setState(() {
      _hits = hits;
      _searching = false;
    });
    if (hits.isNotEmpty) {
      // 最初の結果に地図を寄せる (1 件目を中心、ズームは都市表示の 8 程度)
      _mapCtrl.move(LatLng(hits.first.lat, hits.first.lng), 8);
    }
  }

  void _onHitTap(SearchHit h) {
    _searchFocus.unfocus();
    _selectPoint(
      LatLng(h.lat, h.lng),
      initialName: _shortName(h.name),
      initialCountryCode: h.country?.toUpperCase(),
    );
    _mapCtrl.move(LatLng(h.lat, h.lng), 10);
  }

  String _shortName(String displayName) {
    // Nominatim の name は "場所名, 区, 市, 県, 国" 形式の display_name。
    // 先頭部分のみ抽出して短縮表示用に使う。
    final parts = displayName.split(',').map((s) => s.trim()).toList();
    return parts.isNotEmpty ? parts.first : displayName;
  }

  /// マップタップ / 検索結果タップで地点を確定。
  /// reverse geocode を非同期で走らせて region/country/name を埋める。
  Future<void> _selectPoint(
    LatLng latLng, {
    String? initialName,
    String? initialCountryCode,
  }) async {
    setState(() {
      _picked = latLng;
      _pickedName = initialName;
      _pickedCountry = initialCountryCode;
      _pickedRegion = null;
      _resolvingName = true;
    });
    final detail = await reverseGeocodeDetail(latLng.latitude, latLng.longitude);
    if (!mounted) return;
    if (_picked != latLng) {
      // 連打などで途中で選択が変わった場合は古い結果を破棄。
      return;
    }
    setState(() {
      _resolvingName = false;
      if (detail != null) {
        // 既に initial 名があればそれを優先 (検索結果の表記を信頼)、
        // 無ければ reverseGeocode から取る。
        _pickedName ??= detail.name;
        _pickedRegion = detail.region;
        _pickedCountry ??= detail.countryCode;
      }
    });
  }

  void _onMapTap(TapPosition _, LatLng latLng) {
    _searchFocus.unfocus();
    _selectPoint(latLng);
  }

  void _clearSelection() {
    setState(() {
      _picked = null;
      _pickedName = null;
      _pickedRegion = null;
      _pickedCountry = null;
      _resolvingName = false;
    });
  }

  void _confirm() {
    final p = _picked;
    if (p == null) return;
    final name = _pickedName?.isNotEmpty == true
        ? _pickedName!
        : '選択地点 (${p.latitude.toStringAsFixed(2)}°, ${p.longitude.toStringAsFixed(2)}°)';
    final target = ConsultationPresetTarget(
      position: p,
      nameJP: name,
      nameEN: name, // EN 解析は i18n 期、今は同一文字列で十分
      country: _pickedCountry ?? '',
      region: _pickedRegion ?? '',
    );
    Navigator.of(context).pop(target);
  }

  @override
  Widget build(BuildContext context) {
    final initialCenter = widget.initialCenter ?? _defaultCenter;
    final initialZoom = widget.initialZoom ?? _defaultZoom;

    return Scaffold(
      backgroundColor: SolaraColors.celestialBlueDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: SolaraColors.textPrimary),
        title: const Text(
          '地図で選ぶ',
          style: TextStyle(
            color: SolaraColors.textPrimary,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // フルスクリーン地図 (検索 + 選択カードは上下に float)
            Positioned.fill(
              child: FlutterMap(
                mapController: _mapCtrl,
                options: MapOptions(
                  initialCenter: initialCenter,
                  initialZoom: initialZoom,
                  minZoom: 2.5,
                  maxZoom: 19,
                  // 赤画面 (LatLng NaN) 対策の 3 層防御
                  // 詳細: project_solara_map_nan_red_screen.md
                  cameraConstraint: CameraConstraint.contain(
                    bounds: LatLngBounds(
                      const LatLng(-85, -180),
                      const LatLng(85, 180),
                    ),
                  ),
                  onTap: _onMapTap,
                ),
                children: [
                  // Solara 標準ダーク地図 (map_styles.dart の共通 builder)
                  buildStyledTileLayer(
                    MapStyle.osmHotDark,
                    resetStream: _tileResetCtrl.stream,
                  ),
                  // 検索結果ピン (番号付き)
                  if (_hits.isNotEmpty)
                    MarkerLayer(markers: [
                      for (int i = 0; i < _hits.length; i++)
                        Marker(
                          point: LatLng(_hits[i].lat, _hits[i].lng),
                          width: 28,
                          height: 28,
                          child: GestureDetector(
                            onTap: () => _onHitTap(_hits[i]),
                            child: _NumberedPin(index: i + 1),
                          ),
                        ),
                    ]),
                  // 選択中ピン (常に最前面)
                  if (_picked != null)
                    MarkerLayer(markers: [
                      Marker(
                        point: _picked!,
                        width: 36,
                        height: 36,
                        child: const Icon(
                          Icons.place,
                          color: SolaraColors.solaraGold,
                          size: 32,
                        ),
                      ),
                    ]),
                ],
              ),
            ),

            // 上部: 検索バー + suggestions
            Positioned(
              top: 8,
              left: 12,
              right: 12,
              child: _SearchBar(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                onChanged: _onSearchChanged,
                searching: _searching,
                hits: _hits,
                onHitTap: _onHitTap,
              ),
            ),

            // 下部: 選択中 + 決定/キャンセル
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: _SelectionCard(
                picked: _picked,
                name: _pickedName,
                region: _pickedRegion,
                countryCode: _pickedCountry,
                resolving: _resolvingName,
                onClear: _clearSelection,
                onConfirm: _confirm,
                onCancel: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── サブウィジェット ───────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final bool searching;
  final List<SearchHit> hits;
  final void Function(SearchHit) onHitTap;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.searching,
    required this.hits,
    required this.onHitTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xF20F0F1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x33C9A84C)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 10),
              const Icon(Icons.search,
                  size: 18, color: SolaraColors.solaraGold),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  textInputAction: TextInputAction.search,
                  onChanged: onChanged,
                  style: const TextStyle(
                    color: SolaraColors.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                    hintText: '住所 / 店名で検索',
                    hintStyle: TextStyle(
                      color: SolaraColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              if (controller.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.close,
                      size: 16, color: SolaraColors.textSecondary),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  tooltip: 'クリア',
                ),
              if (searching)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: SolaraColors.solaraGold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (hits.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: const Color(0xF20F0F1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x33C9A84C)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: hits.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: Color(0x11FFFFFF)),
              itemBuilder: (ctx, i) {
                final h = hits[i];
                // Google Places (hit.address あり) と Nominatim (display_name comma 連結) を
                // 両対応。a と同じ振り分けロジック (consultation_input_widgets._SearchHitRow)。
                final String short;
                final String sub;
                if (h.address != null && h.address!.isNotEmpty) {
                  short = h.name;
                  sub = h.address!;
                } else {
                  final parts = h.name.split(',');
                  short = parts.isNotEmpty ? parts.first.trim() : h.name;
                  sub = parts.length > 1
                      ? parts.skip(1).map((s) => s.trim()).join(', ')
                      : '';
                }
                return InkWell(
                  onTap: () => onHitTap(h),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: SolaraColors.solaraGold,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: SolaraColors.celestialBlueDark,
                              fontWeight: FontWeight.bold,
                              height: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                short,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: SolaraColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (sub.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  sub,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: SolaraColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _NumberedPin extends StatelessWidget {
  final int index;
  const _NumberedPin({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: SolaraColors.solaraGold,
      ),
      alignment: Alignment.center,
      child: Text(
        '$index',
        style: const TextStyle(
          fontSize: 13,
          color: SolaraColors.celestialBlueDark,
          fontWeight: FontWeight.bold,
          height: 1.0,
        ),
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  final LatLng? picked;
  final String? name;
  final String? region;
  final String? countryCode;
  final bool resolving;
  final VoidCallback onClear;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _SelectionCard({
    required this.picked,
    required this.name,
    required this.region,
    required this.countryCode,
    required this.resolving,
    required this.onClear,
    required this.onConfirm,
    required this.onCancel,
  });

  String _coordLabel(LatLng p) {
    final lat = p.latitude;
    final lng = p.longitude;
    final latStr = '${lat.abs().toStringAsFixed(3)}°${lat >= 0 ? 'N' : 'S'}';
    final lngStr = '${lng.abs().toStringAsFixed(3)}°${lng >= 0 ? 'E' : 'W'}';
    return '$latStr, $lngStr';
  }

  String? _addressLine() {
    final parts = <String>[
      if (region != null && region!.isNotEmpty) region!,
      if (countryCode != null && countryCode!.isNotEmpty) countryCode!,
    ];
    return parts.isEmpty ? null : parts.join(' / ');
  }

  @override
  Widget build(BuildContext context) {
    final p = picked;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xF20F0F1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x44F6BD60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (p == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'タップ または 検索 で地点を選んでください',
                style: TextStyle(
                  color: SolaraColors.textSecondary,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else ...[
            Row(
              children: [
                const Icon(Icons.place,
                    size: 18, color: SolaraColors.solaraGold),
                const SizedBox(width: 6),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Text(
                          name?.isNotEmpty == true
                              ? name!
                              : (resolving ? '読み込み中…' : '選択地点'),
                          style: const TextStyle(
                            color: SolaraColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_addressLine() != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '(${_addressLine()})',
                            style: const TextStyle(
                              color: SolaraColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close,
                      size: 16, color: SolaraColors.textSecondary),
                  onPressed: onClear,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  tooltip: '選択を解除',
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 24, top: 2, bottom: 6),
              child: Text(
                _coordLabel(p),
                style: const TextStyle(
                  color: SolaraColors.textSecondary,
                  fontSize: 11,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: onCancel,
                  style: TextButton.styleFrom(
                    foregroundColor: SolaraColors.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('キャンセル'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: p == null ? null : onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SolaraColors.solaraGold,
                    foregroundColor: SolaraColors.celestialBlueDark,
                    disabledBackgroundColor: SolaraColors.glassBorder,
                    disabledForegroundColor: SolaraColors.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'この地点で相談',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
