import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../utils/solara_api.dart' show solaraWorkerBase;
import 'map_astro.dart';
import 'map_constants.dart';
import 'map_vp_panel.dart' show VPSlot;

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

/// CF Worker /search 経由で場所検索。
/// [biasCenter] を渡すと Google Places の locationBias.circle (15km) として
/// 中心付近のPOIを優先する。出生地検索など特定地名のときは null で良い。
Future<List<SearchHit>> searchPlaces(String query, {LatLng? biasCenter}) async {
  if (query.trim().length < 2) return [];
  try {
    final params = <String, String>{'q': query};
    if (biasCenter != null) {
      params['lat'] = biasCenter.latitude.toString();
      params['lng'] = biasCenter.longitude.toString();
    }
    final uri = Uri.parse(_searchApiUrl).replace(queryParameters: params);
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
  /// 距離km・方位計算の起点座標 (= 選択中 VIEWPOINT または地図中心)
  final LatLng center;
  /// 最大高さ (画面下まで伸ばすために呼出側で MediaQuery 連動して指定)
  final double maxHeight;
  /// VIEWPOINT 切替プルダウン用。未指定なら dropdown 非表示。
  final List<VPSlot>? vpSlots;
  /// 選択中の VIEWPOINT index (-1 = 地図中心、0+ = vpSlots の index)
  final int selectedVpIndex;
  /// VP 選択変更コールバック
  final ValueChanged<int>? onVpChanged;
  /// 上部スコアバーと同じ activeCategory ('all' / 'money' / 'love' / 等)。
  /// 検索結果一覧で「カテゴリ名 X.X」表示に使う。
  final String activeCategory;

  const SearchResultList({
    super.key,
    required this.hits,
    required this.onTap,
    required this.onClose,
    required this.center,
    this.maxHeight = 320,
    this.vpSlots,
    this.selectedVpIndex = -1,
    this.onVpChanged,
    this.activeCategory = 'all',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: const Color(0xF20F0F1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x33C9A84C)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 6),
          child: Row(children: [
            const Icon(Icons.search, size: 14, color: Color(0xFFC9A84C)),
            const SizedBox(width: 5),
            Text('検索結果 (${hits.length})',
                style: const TextStyle(fontSize: 11, color: Color(0xFFC9A84C), letterSpacing: 1)),
            const Spacer(),
            // ── VIEWPOINT 選択 dropdown (距離・方位・スコアの起点を切替) ──
            if (vpSlots != null && onVpChanged != null)
              _buildVpDropdown(),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onClose,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Icon(Icons.close, size: 14, color: Color(0xFF888888)),
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
            itemBuilder: (ctx, i) => _hitRow(hits[i], index: i + 1),
          ),
        ),
      ]),
    );
  }

  Widget _hitRow(SearchHit h, {required int index}) {
    final parts = h.name.split(',');
    final short = parts.length > 2 ? '${parts[0]},${parts[1]}' : h.name;
    final fortuneIcon = _fortuneIcon(h.bestFortune);
    final catColor = h.bestFortune != null
        ? (categoryColors[h.bestFortune!] ?? const Color(0xFFE8E0D0))
        : const Color(0xFFE8E0D0);
    // マップ中心からの距離km (近い順並び替えはGoogle側RELEVANCE+bias任せ、
    // ユーザーには km 数字で位置感を提示する)
    final km = h.distanceKmFrom(center);
    final kmStr = km < 1
        ? '${(km * 1000).round()}m'
        : km < 10
            ? '${km.toStringAsFixed(1)}km'
            : '${km.round()}km';

    return InkWell(
      onTap: () => onTap(h),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(children: [
          // 地図上の番号マーカーと同じ番号を行頭に表示 (連動視覚化)
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFC9A84C),
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF0C0C16),
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(short,
                style: const TextStyle(fontSize: 12, color: Color(0xFFE8E0D0), fontWeight: FontWeight.w600),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Row(children: [
                Text(kmStr,
                    style: const TextStyle(
                      fontSize: 9, color: Color(0xFFC9A84C),
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(width: 8),
                if (h.bestDir != null) ...[
                  Text('${dir16JP[h.bestDir!]}方位',
                      style: const TextStyle(fontSize: 9, color: Color(0xFF999999))),
                  const SizedBox(width: 8),
                ],
                Text('${categoryLabels[activeCategory] ?? '総合'} ${h.bestScore.toStringAsFixed(1)}',
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

  /// VIEWPOINT 選択 dropdown。
  /// -1 = 地図中心、0+ = vpSlots の index。
  /// 距離km・方位・スコアの起点を切替えるためのもの。
  Widget _buildVpDropdown() {
    final slots = vpSlots ?? const [];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x33C9A84C)),
      ),
      child: DropdownButton<int>(
        value: selectedVpIndex,
        underline: const SizedBox.shrink(),
        isDense: true,
        dropdownColor: const Color(0xF20F0F1E),
        iconEnabledColor: const Color(0xFFC9A84C),
        iconSize: 16,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFFE8E0D0),
        ),
        items: [
          const DropdownMenuItem<int>(
            value: -1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.my_location,
                    size: 12, color: Color(0xFFC9A84C)),
                SizedBox(width: 4),
                Text('地図中心',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFFE8E0D0),
                    )),
              ],
            ),
          ),
          for (int i = 0; i < slots.length; i++)
            DropdownMenuItem<int>(
              value: i,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(slots[i].icon,
                      style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    slots[i].name.isEmpty ? 'VP${i + 1}' : slots[i].name,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFE8E0D0),
                    ),
                  ),
                ],
              ),
            ),
        ],
        onChanged: (v) {
          if (v == null) return;
          onVpChanged?.call(v);
        },
      ),
    );
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
  /// 上部スコアバーと同じ activeCategory ('all' / 'money' 等)。
  /// 「総合 / 豊かさ / 癒し」等のラベル動的化に使う。
  final String activeCategory;

  const SearchFocusPopup({
    super.key,
    required this.focus,
    required this.center,
    required this.fComps,
    required this.activeSrc,
    required this.onClose,
    required this.onMoveToHit,
    this.activeCategory = 'all',
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
          const Icon(Icons.place, size: 16, color: Color(0xFFC9A84C)),
          const SizedBox(width: 6),
          Expanded(child: Text(short,
            style: const TextStyle(fontSize: 13, color: Color(0xFFE8E0D0), fontWeight: FontWeight.w600),
            maxLines: 1, overflow: TextOverflow.ellipsis)),
          GestureDetector(
            onTap: onClose,
            child: const Icon(Icons.close, size: 14, color: Color(0xFF888888)),
          ),
        ]),
        // 場所名の下に住所行 (短縮で取ったあとの残り部分を表示)
        if (parts.length > 2) ...[
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 22),
            child: Text(
              parts.skip(2).join(',').trim(),
              style: const TextStyle(fontSize: 10, color: Color(0xFF888888), height: 1.3),
              maxLines: 2, overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
        const SizedBox(height: 10),
        Row(children: [
          Text('$dirJp方位',
              style: const TextStyle(fontSize: 11, color: Color(0xFFC9A84C), letterSpacing: 1)),
          const SizedBox(width: 10),
          Text('${km.toStringAsFixed(km < 100 ? 1 : 0)} km',
              style: const TextStyle(fontSize: 10, color: Color(0xFF888888))),
          const Spacer(),
          Text('${categoryLabels[activeCategory] ?? '総合'} ${focus.bestScore.toStringAsFixed(1)}',
              style: const TextStyle(fontSize: 10, color: Color(0xFFE8E0D0))),
        ]),
        const SizedBox(height: 8),
        if (top3.isNotEmpty) ...[
          Row(children: [
            const Text(
              'カテゴリ別内訳 (参考)',
              style: TextStyle(fontSize: 9, color: Color(0xFF888888), letterSpacing: 0.5),
            ),
            const SizedBox(width: 6),
            const Text(
              '※ 総合は別計算',
              style: TextStyle(fontSize: 9, color: Color(0xFF666666)),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => _showScoreInfo(context),
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(Icons.info_outline, size: 12, color: Color(0xFF888888)),
              ),
            ),
          ]),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8, runSpacing: 4,
            children: [for (final e in top3) _CatChip(cat: e.key, score: e.value)],
          ),
        ],
        const SizedBox(height: 10),
        // C-2: 「拠点として登録」削除。保存は VP/Loc パネルの「この地点を保存」へ集約
        // (検索中は popup の検索地が VP panel の center として渡される)
        _ActionTile(label: '✈ ここへ移動', onTap: onMoveToHit),
      ]),
    );
  }
}

/// 「総合は別計算」i ボタン押下時の説明ダイアログ。
/// ユーザー指摘: 検索結果一覧の総合と詳細の各カテゴリ合算が一致しない理由を可視化。
void _showScoreInfo(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xF00F0F1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0x33C9A84C)),
      ),
      title: const Text(
        '総合スコアの計算',
        style: TextStyle(color: Color(0xFFC9A84C), fontSize: 14, letterSpacing: 1),
      ),
      content: const SingleChildScrollView(
        child: Text(
          '【総合スコア (上段の数字)】\n'
          '現在選択中のカテゴリ (デフォルト: 総合) における、その方位のスコアを表示。\n'
          '総合カテゴリでは、全カテゴリのソフト・ハード両エネルギーを加重合成した値です。\n\n'
          '【カテゴリ別内訳 (下段のチップ)】\n'
          'その方位における各カテゴリ単独のスコアを表示。\n'
          '癒し / 豊かさ / 恋愛 / 仕事 / 話す をそれぞれ独立に算出。\n\n'
          '【なぜ合計が一致しないか】\n'
          '総合は単純な足し算ではなく、エネルギーの方向性を考慮した加重計算です。\n'
          'カテゴリ別内訳の合算 ≠ 総合 となるのは、計算方法が異なるためです。',
          style: TextStyle(color: Color(0xFFE8E0D0), fontSize: 12, height: 1.6),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text(
            '閉じる',
            style: TextStyle(color: Color(0xFFC9A84C), letterSpacing: 1),
          ),
        ),
      ],
    ),
  );
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
