// ============================================================
// LocationPickerMinimap — 中央固定ピン + マップパンで座標選択
//
// 用途: Sanctuary 出生地 / 現住所入力で、検索後に微調整するためのミニマップ。
// 操作: マップを指で動かす → 中央のピンが指す座標を onChanged で通知。
//        (ピン自体はドラッグしない、IgnorePointer で gesture を Map に通す)
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../screens/map/map_styles.dart';

class LocationPickerMinimap extends StatefulWidget {
  /// 初期表示・親側 state 同期用の中心座標。
  final double lat;
  final double lng;

  /// 初期ズームレベル。デフォルト 14 (= ストリート粒度、ピン微調整しやすい)。
  final double zoom;

  /// マップの高さ。
  final double height;

  /// マップを動かして中心が変わった時に呼ばれる。
  /// hasGesture=true (ユーザー操作) のみ発火。
  final ValueChanged<({double lat, double lng})> onChanged;

  const LocationPickerMinimap({
    super.key,
    required this.lat,
    required this.lng,
    required this.onChanged,
    this.zoom = 14,
    this.height = 180,
  });

  @override
  State<LocationPickerMinimap> createState() => _LocationPickerMinimapState();
}

class _LocationPickerMinimapState extends State<LocationPickerMinimap> {
  late final MapController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = MapController();
  }

  @override
  void didUpdateWidget(covariant LocationPickerMinimap oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 親側で検索結果から座標が大きく変わったら、マップも合わせて移動。
    if (oldWidget.lat != widget.lat || oldWidget.lng != widget.lng) {
      // マイクロ秒オーダーの誤差は無視 (gesture 中の onChanged フィードバックループ防止)
      final dLat = (oldWidget.lat - widget.lat).abs();
      final dLng = (oldWidget.lng - widget.lng).abs();
      if (dLat > 0.0001 || dLng > 0.0001) {
        _ctrl.move(LatLng(widget.lat, widget.lng), widget.zoom);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _ctrl,
              options: MapOptions(
                initialCenter: LatLng(widget.lat, widget.lng),
                initialZoom: widget.zoom,
                minZoom: 3,
                maxZoom: 18,
                interactionOptions: const InteractionOptions(
                  // 回転は無効 (16 方位概念と整合)
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                onPositionChanged: (camera, hasGesture) {
                  if (!hasGesture) return;
                  widget.onChanged(
                    (lat: camera.center.latitude, lng: camera.center.longitude),
                  );
                },
              ),
              children: [
                buildStyledTileLayer(MapStyle.osmHotLight),
              ],
            ),
            // 中央固定ピン (IgnorePointer で gesture を Map に通す)。
            // Pin の先端 (下端) が中心座標を指すよう、Padding で上に持ち上げる。
            const IgnorePointer(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 28),
                  child: Icon(
                    Icons.place,
                    size: 36,
                    color: Color(0xFFC9A84C),
                    shadows: [
                      Shadow(color: Color(0xCC000000), blurRadius: 6),
                    ],
                  ),
                ),
              ),
            ),
            // 操作ヒント (右上)
            Positioned(
              top: 6,
              right: 8,
              child: IgnorePointer(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xCC0A0A14),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '地図を動かしてピン位置調整',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFFE8E0D0),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
