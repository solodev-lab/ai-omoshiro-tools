import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../utils/solara_api.dart' show solaraWorkerBase;
import 'map_astro.dart';
import 'map_constants.dart';

const _searchApiUrl = '$solaraWorkerBase/search';

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

/// 検索候補から1件選ばれたあとの詳細ポップアップ。
/// 現在の中心・日付・カテゴリ/ソースで再計算される動的表示。
class SearchFocusPopup extends StatelessWidget {
  final SearchHit focus;
  final LatLng center;
  /// fComps[category][direction] = {tSoft, tHard, pSoft, pHard}
  final Map<String, Map<String, Map<String, double>>> fComps;
  /// 'transit' | 'progressed' | 'combined'
  final String activeSrc;
  final VoidCallback onClose;
  final VoidCallback onMoveToHit;
  final VoidCallback onSaveAsLocation;

  const SearchFocusPopup({
    super.key,
    required this.focus,
    required this.center,
    required this.fComps,
    required this.activeSrc,
    required this.onClose,
    required this.onMoveToHit,
    required this.onSaveAsLocation,
  });

  @override
  Widget build(BuildContext context) {
    final parts = focus.name.split(',');
    final short = parts.length > 2 ? '${parts[0]}, ${parts[1]}' : focus.name;
    // 中心が動いたら方位を再計算（bestDir はキャッシュの可能性がある）
    final dir = focus.directionFrom(center);
    final dirJp = dir16JP[dir] ?? dir;
    final km = focus.distanceKmFrom(center);

    // この方位のカテゴリ別スコア — _displayScores と同じ src フィルタを適用して、
    // 日付変更・ソース切替に追随して値が動くようにする。
    final srcKeys = activeSrc == 'transit'
        ? const ['tSoft', 'tHard']
        : activeSrc == 'progressed'
            ? const ['pSoft', 'pHard']
            : compKeys;
    final catEntries = <MapEntry<String, double>>[];
    for (final cat in fComps.keys) {
      final comps = fComps[cat]?[dir];
      if (comps == null) continue;
      double sum = 0;
      for (final k in srcKeys) {
        sum += comps[k] ?? 0;
      }
      if (sum < 0.05) continue; // 0同然のカテゴリは省く
      catEntries.add(MapEntry(cat, sum));
    }
    catEntries.sort((a, b) => b.value.compareTo(a.value));
    final top3 = catEntries.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xF20F0F1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x33C9A84C)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          const Text('📍', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(child: Text(short,
            style: const TextStyle(fontSize: 13, color: Color(0xFFE8E0D0), fontWeight: FontWeight.w600),
            maxLines: 1, overflow: TextOverflow.ellipsis)),
          GestureDetector(
            onTap: onClose,
            child: const Text('✕', style: TextStyle(color: Color(0xFF555555), fontSize: 14)),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Text('$dirJp方位',
              style: const TextStyle(fontSize: 11, color: Color(0xFFC9A84C), letterSpacing: 1)),
          const SizedBox(width: 10),
          Text('${km.toStringAsFixed(km < 100 ? 1 : 0)} km',
              style: const TextStyle(fontSize: 10, color: Color(0xFF888888))),
          const Spacer(),
          Text('総合 ${focus.bestScore.toStringAsFixed(1)}',
              style: const TextStyle(fontSize: 10, color: Color(0xFFE8E0D0))),
        ]),
        const SizedBox(height: 8),
        if (top3.isNotEmpty) Wrap(
          spacing: 8, runSpacing: 4,
          children: [for (final e in top3) _CatChip(cat: e.key, score: e.value)],
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _ActionTile(label: '📌 拠点として登録', onTap: onSaveAsLocation)),
          const SizedBox(width: 6),
          Expanded(child: _ActionTile(label: '✈ ここへ移動', onTap: onMoveToHit)),
        ]),
      ]),
    );
  }
}

class _CatChip extends StatelessWidget {
  final String cat;
  final double score;
  const _CatChip({required this.cat, required this.score});

  @override
  Widget build(BuildContext context) {
    final color = categoryColors[cat] ?? const Color(0xFFE8E0D0);
    final label = categoryLabels[cat] ?? cat;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: TextStyle(fontSize: 10, color: color)),
        const SizedBox(width: 4),
        Text(score.toStringAsFixed(1), style: const TextStyle(fontSize: 9, color: Color(0xFF999999))),
      ]),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ActionTile({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0x1FC9A84C),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x66C9A84C)),
        ),
        child: Center(
          child: Text(label,
              style: const TextStyle(fontSize: 10, color: Color(0xFFC9A84C), letterSpacing: 0.5)),
        ),
      ),
    );
  }
}
