// Consult Entry Popup — Stella 相談の共通入口 popup
//
// 設計議論 2026-05-16 → 2026-05-17 簡素化:
//   - 「Stella に相談」開始 popup として複数経路で共通利用:
//     - 空地点タップ (ACG/非 ACG 共通、Pro ユーザーのみ): map_screen.onTap から
//     - 線/天頂/天底 popup 内 CTA 「この地点で相談」: 直接 ConsultationInputScreen
//       を push する経路で、この popup は経由しない
//
// 表示内容 (吉凶禁止原則を守るため Map の sector スコアは出さない):
//   - 地名 (reverse geocode 結果、失敗時は「タップ地点」)
//   - 座標 (lat°/lng°)
//   - 最寄りの natal-frame conjunction line 3 本 (Stella 相談エンジンと同じ材料)
//   - 「この場所で相談する」CTA
//
// 工数注: 最寄り線計算は呼出側で済ませて [nearestLines] として渡す。

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

import '../../i18n/strings.g.dart';
import '../../theme/solara_colors.dart';
import '../../utils/astro_lines.dart' show NearbyAstroLine;
import '../../utils/reverse_geocode.dart';
import 'map_constants.dart' show planetMeta;

/// ANGLE 略号 → 日本語表記 (popup 用、長くない範囲で意味を取りやすく)。
const _angleLabelJP = <String, String>{
  'asc': 'ASC',
  'mc': 'MC',
  'dsc': 'DSC',
  'ic': 'IC',
};

class ConsultEntryPopup extends StatefulWidget {
  /// ユーザーがタップした座標 (実際の地点 = preset として相談画面に渡す座標)。
  final LatLng tapPoint;

  /// 最寄り natal-frame conjunction line 3 本 (caller が計算済)。
  /// 距離昇順、最大 3 本を想定 (より多くても先頭 3 本だけ表示する)。
  final List<NearbyAstroLine> nearestLines;

  /// 「この場所で相談する」CTA タップ時のハンドラ。
  /// caller 側で Pro チェック + reverseGeocode + ConsultationInputScreen push を行う。
  final VoidCallback onConsult;

  /// × タップ / 外側タップで閉じる時のハンドラ。
  final VoidCallback onClose;

  const ConsultEntryPopup({
    super.key,
    required this.tapPoint,
    required this.nearestLines,
    required this.onConsult,
    required this.onClose,
  });

  @override
  State<ConsultEntryPopup> createState() => _ConsultEntryPopupState();
}

class _ConsultEntryPopupState extends State<ConsultEntryPopup> {
  String? _placeName;
  String? _region;
  String? _countryCode;
  bool _resolving = true;

  @override
  void initState() {
    super.initState();
    _resolveName();
  }

  Future<void> _resolveName() async {
    final detail = await reverseGeocodeDetail(
      widget.tapPoint.latitude,
      widget.tapPoint.longitude,
    );
    if (!mounted) return;
    setState(() {
      _resolving = false;
      _placeName = detail?.name;
      _region = detail?.region;
      _countryCode = detail?.countryCode;
    });
  }

  String get _coordLabel {
    final lat = widget.tapPoint.latitude;
    final lng = widget.tapPoint.longitude;
    final latStr = '${lat.abs().toStringAsFixed(3)}°${lat >= 0 ? 'N' : 'S'}';
    final lngStr = '${lng.abs().toStringAsFixed(3)}°${lng >= 0 ? 'E' : 'W'}';
    return '$latStr, $lngStr';
  }

  String? get _addressLine {
    final parts = <String>[
      if (_region != null && _region!.isNotEmpty) _region!,
      if (_countryCode != null && _countryCode!.isNotEmpty) _countryCode!,
    ];
    return parts.isEmpty ? null : parts.join(' / ');
  }

  /// 座標を "緯度, 経度" (小数) でクリップボードへコピー。
  /// Horo 画面の出生地/トランジット場所欄で「座標貼り付け」できる。
  void _copyCoords() {
    final lat = widget.tapPoint.latitude;
    final lng = widget.tapPoint.longitude;
    Clipboard.setData(ClipboardData(
        text: '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}'));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(t.consultEntry.coordsCopied),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xEE0C0C1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x44F6BD60)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ヘッダ: 地名 + × ボタン
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
                        _resolving
                            ? t.consultEntry.loading
                            : (_placeName?.isNotEmpty == true
                                ? _placeName!
                                : t.mapScreen.tappedPoint),
                        style: const TextStyle(
                          color: SolaraColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                      if (_addressLine != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '(${_addressLine!})',
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
              GestureDetector(
                onTap: widget.onClose,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close,
                      size: 16, color: SolaraColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    _coordLabel,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: SolaraColors.textSecondary,
                      fontSize: 11,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _copyCoords,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0x66F6BD60)),
                      color: const Color(0x14F6BD60),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.copy,
                          size: 11, color: SolaraColors.solaraGoldLight),
                      const SizedBox(width: 4),
                      Text(t.consultEntry.getCoords,
                          style: const TextStyle(
                              fontSize: 10,
                              color: SolaraColors.solaraGoldLight,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ],
            ),
          ),

          // 最寄り ACG 線セクション
          if (widget.nearestLines.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              t.consultEntry.nearestLines,
              style: const TextStyle(
                color: SolaraColors.textSecondary,
                fontSize: 10,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            for (int i = 0; i < widget.nearestLines.length && i < 3; i++) ...[
              if (i > 0) const SizedBox(height: 4),
              _NearestLineRow(nearby: widget.nearestLines[i]),
            ],
          ],

          // 相談 CTA
          const SizedBox(height: 12),
          InkWell(
            onTap: widget.onConsult,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0x33F6BD60),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0x88F6BD60)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome,
                      size: 16, color: SolaraColors.solaraGoldLight),
                  const SizedBox(width: 8),
                  Text(
                    t.consultEntry.consultHere,
                    style: const TextStyle(
                      color: SolaraColors.solaraGoldLight,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NearestLineRow extends StatelessWidget {
  final NearbyAstroLine nearby;
  const _NearestLineRow({required this.nearby});

  @override
  Widget build(BuildContext context) {
    final meta = planetMeta[nearby.line.planet];
    final color = meta?.color ?? SolaraColors.solaraGoldLight;
    final sym = meta?.sym ?? nearby.line.planet;
    final jp = meta?.jp ?? nearby.line.planet;
    final angleJp =
        _angleLabelJP[nearby.line.angle.toLowerCase()] ?? nearby.line.angle;
    final dist = nearby.distanceKm;
    final distStr = dist < 10
        ? '${dist.toStringAsFixed(1)} km'
        : '${dist.round()} km';
    return Row(
      children: [
        SizedBox(
          width: 20,
          child: Text(
            sym,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: color,
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$jp $angleJp',
            style: TextStyle(
              color: color.withValues(alpha: 0.92),
              fontSize: 12,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Text(
          distStr,
          style: const TextStyle(
            color: SolaraColors.textSecondary,
            fontSize: 12,
            letterSpacing: 0.2,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
