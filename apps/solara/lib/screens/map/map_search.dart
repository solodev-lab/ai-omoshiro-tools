import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'map_astro.dart';
import 'map_constants.dart';

const _searchApiUrl = 'https://solara-api.solodev-lab.com/search';

/// 検索結果1件分
class SearchHit {
  final String name;
  final double lat;
  final double lng;
  final String? country;
  final String source; // 'nominatim' | 'google'

  /// この地点に向けた16方位ランキング（1位方位とスコア）
  String? bestDir;
  double bestScore;
  String? bestFortune; // dominant fortune category

  SearchHit({
    required this.name, required this.lat, required this.lng,
    this.country, this.source = 'nominatim',
    this.bestDir, this.bestScore = 0, this.bestFortune,
  });

  /// 中心座標から見たこの地点の方位（16方位名）
  String directionFrom(LatLng center) {
    return _azimuthToDir16(_bearingDeg(center.latitude, center.longitude, lat, lng));
  }

  /// 中心から km 距離
  double distanceKmFrom(LatLng center) {
    return _haversineKm(center.latitude, center.longitude, lat, lng);
  }
}

double _bearingDeg(double lat1, double lng1, double lat2, double lng2) {
  final phi1 = lat1 * pi / 180, phi2 = lat2 * pi / 180;
  final dL = (lng2 - lng1) * pi / 180;
  final y = sin(dL) * cos(phi2);
  final x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(dL);
  final b = atan2(y, x) * 180 / pi;
  return (b + 360) % 360;
}

String _azimuthToDir16(double az) {
  // 0° = N, 22.5° 刻み
  final idx = ((az / 22.5).round()) % 16;
  return dir16[idx];
}

double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const R = 6371.0;
  final dLat = (lat2 - lat1) * pi / 180;
  final dLng = (lng2 - lng1) * pi / 180;
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLng / 2) * sin(dLng / 2);
  return R * 2 * atan2(sqrt(a), sqrt(1 - a));
}

/// CF Worker /search 経由で場所検索
Future<List<SearchHit>> searchPlaces(String query) async {
  if (query.trim().length < 2) return [];
  try {
    final uri = Uri.parse('$_searchApiUrl?q=${Uri.encodeComponent(query)}');
    final resp = await http.get(uri).timeout(const Duration(seconds: 8));
    if (resp.statusCode != 200) return [];
    final data = json.decode(resp.body) as Map<String, dynamic>;
    final source = data['source'] as String? ?? 'nominatim';
    final results = (data['results'] as List? ?? []);
    return results.map((r) {
      final m = r as Map<String, dynamic>;
      return SearchHit(
        name: m['name'] as String? ?? '',
        lat: (m['lat'] as num).toDouble(),
        lng: (m['lng'] as num).toDouble(),
        country: m['country'] as String?,
        source: source,
      );
    }).toList();
  } catch (_) {
    return [];
  }
}

/// 検索結果に、現在中心からの方位スコアと支配カテゴリを注入する
void annotateHitsWithScores({
  required List<SearchHit> hits,
  required LatLng center,
  required Map<String, double> sectorScores,
  required ScoreResult? scoreResult,
}) {
  for (final h in hits) {
    final dir = h.directionFrom(center);
    h.bestDir = dir;
    h.bestScore = sectorScores[dir] ?? 0;
    if (scoreResult != null) {
      h.bestFortune = scoreResult.sFortune[dir];
    }
  }
}

/// 検索結果リスト（スコア付き）ポップアップ
class SearchResultList extends StatelessWidget {
  final List<SearchHit> hits;
  final void Function(SearchHit) onTap;
  final VoidCallback onClose;

  const SearchResultList({
    super.key,
    required this.hits,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 320),
      decoration: BoxDecoration(
        color: const Color(0xF20F0F1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x33C9A84C)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 6),
          child: Row(children: [
            const Text('🔍 検索結果', style: TextStyle(fontSize: 11, color: Color(0xFFC9A84C), letterSpacing: 1)),
            const Spacer(),
            GestureDetector(
              onTap: onClose,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text('✕', style: TextStyle(color: Color(0xFF888888), fontSize: 14)),
              ),
            ),
          ]),
        ),
        const Divider(height: 1, color: Color(0x22C9A84C)),
        Flexible(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 4),
            shrinkWrap: true,
            itemCount: hits.length,
            separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0x11FFFFFF)),
            itemBuilder: (ctx, i) => _hitRow(hits[i]),
          ),
        ),
      ]),
    );
  }

  Widget _hitRow(SearchHit h) {
    final parts = h.name.split(',');
    final short = parts.length > 2 ? '${parts[0]},${parts[1]}' : h.name;
    final fortuneIcon = _fortuneIcon(h.bestFortune);
    final catColor = h.bestFortune != null
        ? (categoryColors[h.bestFortune!] ?? const Color(0xFFE8E0D0))
        : const Color(0xFFE8E0D0);

    return InkWell(
      onTap: () => onTap(h),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(short,
                style: const TextStyle(fontSize: 12, color: Color(0xFFE8E0D0), fontWeight: FontWeight.w600),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Row(children: [
                if (h.bestDir != null) ...[
                  Text('${dir16JP[h.bestDir!]}方位',
                      style: const TextStyle(fontSize: 9, color: Color(0xFF999999))),
                  const SizedBox(width: 8),
                ],
                Text('スコア ${h.bestScore.toStringAsFixed(1)}',
                    style: TextStyle(fontSize: 9, color: catColor)),
                const SizedBox(width: 8),
                if (fortuneIcon != null) Text(fortuneIcon,
                    style: const TextStyle(fontSize: 10)),
              ]),
            ],
          )),
          const SizedBox(width: 6),
          const Icon(Icons.arrow_forward_ios, size: 10, color: Color(0xFF555555)),
        ]),
      ),
    );
  }

  String? _fortuneIcon(String? cat) {
    switch (cat) {
      case 'love': return '💗';
      case 'money': return '💰';
      case 'healing': return '🌿';
      case 'communication': return '💬';
      case 'work': return '⚙';
      default: return null;
    }
  }
}
