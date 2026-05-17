import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../utils/solara_api.dart' show solaraSearchUrl;
import 'map_astro.dart';
import 'map_constants.dart';
import 'map_fortune_sheet.dart' show showCategoryInfoPopup;

const _searchApiUrl = solaraSearchUrl;

/// 検索結果1件分
class SearchHit {
  final String name;
  /// 住所文字列 (Worker の Google Places source のみ別フィールドで返る)。
  /// Nominatim source では name 自体が "場所名, 区, 市, 県, 国" 形式の
  /// display_name なので address は null。
  final String? address;
  final double lat;
  final double lng;
  final String? country;
  final String source; // 'nominatim' | 'google'

  /// この地点に向けた16方位ランキング（1位方位とスコア）
  String? bestDir;
  double bestScore;
  String? bestFortune; // dominant fortune category
  /// 支配カテゴリ (bestFortune) 単体での bestDir 方位スコア。
  /// activeCategory='all' (総合) の時、リスト表示で「総合 N.N」より
  /// 「豊かさ N.N」のように方位の支配エネルギーを直接見せるために使う。
  double bestFortuneScore;

  SearchHit({
    required this.name, required this.lat, required this.lng,
    this.address,
    this.country, this.source = 'nominatim',
    this.bestDir, this.bestScore = 0, this.bestFortune,
    this.bestFortuneScore = 0,
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
      // address は Google Places 経路のみ Worker が別フィールドで返す。
      // 空文字は null 扱い (popup 側で fallback 判定)。
      final rawAddress = m['address'] as String?;
      return SearchHit(
        name: m['name'] as String? ?? '',
        address: (rawAddress?.isNotEmpty ?? false) ? rawAddress : null,
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
      // activeCategory='all' 表示用に、支配カテゴリ単体スコアを格納
      final domCat = h.bestFortune;
      if (domCat != null) {
        h.bestFortuneScore = scoreResult.fScores[domCat]?[dir] ?? 0;
      } else {
        h.bestFortuneScore = 0;
      }
    }
  }
}

/// 検索結果リスト（スコア付き）ポップアップ
class SearchResultList extends StatelessWidget {
  final List<SearchHit> hits;
  final void Function(SearchHit) onTap;
  final VoidCallback onClose;
  /// 距離km・方位計算の起点座標 (= VIEWPOINT)。
  /// 2026-05-13: 旧 dropdown 廃止 → VP 切替は検索バー上部のチップ列に統一。
  final LatLng center;
  /// 最大高さ (画面下まで伸ばすために呼出側で MediaQuery 連動して指定)
  final double maxHeight;
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
          // 2026-05-13: VP dropdown 撤去 → タイトルと ✕ のシンプルな構成。
          // VP 切替は検索バー上部のチップ列に統一されたので、結果一覧内に
          // 同機能を残すと UI 二重化。
          child: Row(children: [
            Expanded(
              child: Text('検索結果 (${hits.length})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFC9A84C),
                      letterSpacing: 1)),
            ),
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
    // 表示するカテゴリ・スコアを決定。
    // activeCategory='all' の時は「総合 N.N」が紛らわしい (上部スコアバーと
    // 同じ数字なので情報量ゼロ) ため、その方位の支配カテゴリ + 単独スコアを
    // 出す。それ以外 (money/love 等) は activeCategory のスコアをそのまま出す。
    final isAll = activeCategory == 'all';
    final displayCat = isAll && h.bestFortune != null
        ? h.bestFortune!
        : activeCategory;
    final displayScore = isAll && h.bestFortune != null
        ? h.bestFortuneScore
        : h.bestScore;
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
                fontSize: 13,
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
                style: const TextStyle(fontSize: 13, color: Color(0xFFE8E0D0), fontWeight: FontWeight.w600),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              // メタ情報 (距離 / 方位 / カテゴリ&スコア / 絵文字) は
              // 端末フォント拡大時 (1.5 倍) に Row では入りきらないため
              // Wrap に置換: 入らなければ自動で 2 行目へ折返し。
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(kmStr,
                      style: const TextStyle(
                        fontSize: 13, color: Color(0xFFC9A84C),
                        fontWeight: FontWeight.w600,
                      )),
                  if (h.bestDir != null)
                    Text('${dir16JP[h.bestDir!]}方位',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF999999))),
                  Text('${categoryLabels[displayCat] ?? '総合'} ${displayScore.toStringAsFixed(1)}',
                      style: TextStyle(fontSize: 13, color: catColor)),
                  if (fortuneIcon != null)
                    Text(fortuneIcon, style: const TextStyle(fontSize: 13)),
                ],
              ),
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
  /// 上部スコアバーと同じ activeCategory ('all' / 'money' 等)。
  /// 「総合 / 豊かさ / 癒し」等のラベル動的化に使う。
  final String activeCategory;

  /// VIEWPOINT スロットへ登録するハンドラ。
  /// 戻り値: 失敗時はエラーメッセージ、成功時は null。
  /// null なら登録ボタン非表示。
  final Future<String?> Function()? onSaveAsViewpoint;

  /// LOCATION スロットへ登録するハンドラ。
  /// 戻り値・null 時の挙動は onSaveAsViewpoint と同じ。
  final Future<String?> Function()? onSaveAsLocation;

  const SearchFocusPopup({
    super.key,
    required this.focus,
    required this.center,
    required this.fComps,
    required this.activeSrc,
    required this.onClose,
    required this.onMoveToHit,
    this.activeCategory = 'all',
    this.onSaveAsViewpoint,
    this.onSaveAsLocation,
  });

  @override
  Widget build(BuildContext context) {
    // 場所名 / 住所 の決定:
    //   Google Places 経路: focus.address (Worker が formattedAddress を別途返す)
    //   Nominatim 経路   : name = display_name (',' 区切り) を split して取り出し
    // 2026-05-08: Google Places で name='Tokyo Tower' のように 1 単語のみで
    // 帰ってくるケースで住所が空になっていた事象を、address 直接参照で修正。
    final parts = focus.name
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final short = parts.isNotEmpty ? parts[0] : focus.name;
    final addressLine = focus.address?.isNotEmpty == true
        ? focus.address!
        : (parts.length > 1 ? parts.skip(1).join(', ') : '');
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
      // 閾値 0.05 → 0.001 に緩和。低スコアでもカテゴリ表示を残す
      // (ユーザー指摘: カテゴリが消える方位がある対策)
      if (sum < 0.001) continue;
      catEntries.add(MapEntry(cat, sum));
    }
    catEntries.sort((a, b) => b.value.compareTo(a.value));

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
          // 2026-05-08: 場所名が長いと "..." で truncate されていたのを、
          // 横スクロール (SingleChildScrollView, scrollDirection: horizontal)
          // で全文確認できるように変更。softWrap: false で 1 行固定。
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                short,
                style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFE8E0D0),
                    fontWeight: FontWeight.w600),
                softWrap: false,
                maxLines: 1,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onClose,
            child: const Icon(Icons.close, size: 14, color: Color(0xFF888888)),
          ),
        ]),
        // 場所名の下に住所行 (parts[1] 以降全部)
        if (addressLine.isNotEmpty) ...[
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 22),
            child: Text(
              addressLine,
              style: const TextStyle(fontSize: 13, color: Color(0xFF888888), height: 1.3),
              maxLines: 2, overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
        const SizedBox(height: 10),
        // 方角・距離の行。フォント拡大時に overflow しないよう Wrap 化。
        // 2026-05-08: 「総合 N.N」表示を削除。上部スコアバーと完全に同じ数字を
        // ここで再掲しても情報量ゼロで紛らわしい (ユーザー指摘) ため、
        // 詳細はカテゴリ別内訳 (下段チップ) に集約。
        Wrap(
          spacing: 10,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('$dirJp方位',
                style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFC9A84C),
                    letterSpacing: 1)),
            Text('${km.toStringAsFixed(km < 100 ? 1 : 0)} km',
                style: const TextStyle(fontSize: 13, color: Color(0xFF888888))),
          ],
        ),
        const SizedBox(height: 8),
        if (catEntries.isNotEmpty) ...[
          // 2026-05-08: 「(参考)」削除 + top3 制限を撤廃して全カテゴリを
          // スコア降順で表示。横方向に入りきらない場合は SingleChildScrollView
          // で横スライドさせる (折返し Wrap だと縦に伸びて popup が縦長化する
          // ため、popup 高さ固定 + 横スライドの方が UI 安定)。
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'カテゴリ別内訳',
                style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF888888),
                    letterSpacing: 0.5),
              ),
              GestureDetector(
                // 2026-05-08: 検索詳細では「Map の使い方」上部 (方角を読む /
                // 基準地点を登録する) を省略。検索中は既に Map で操作中なので
                // 冗長になるため。「場所を探す」以下から表示。
                onTap: () => showCategoryInfoPopup(context,
                    includeMapUsageTop: false),
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(Icons.info_outline,
                      size: 13, color: Color(0xFF888888)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < catEntries.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  _CatChip(cat: catEntries[i].key, score: catEntries[i].value),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 10),
        // 登録ボタン: VIEWPOINT (基準視点) と LOCATION (拠点) は別管理なので
        // それぞれ個別ボタン。検索結果から直接登録できる導線。
        // 結果は SnackBar で通知 (満杯時はエラーメッセージ)。
        if (onSaveAsViewpoint != null) ...[
          _ActionTile(
            label: '📍 VIEWPOINT に登録',
            onTap: () async {
              final err = await onSaveAsViewpoint!();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(err ?? '✓ VIEWPOINT に登録しました'),
                duration: const Duration(seconds: 2),
              ));
            },
          ),
          const SizedBox(height: 6),
        ],
        if (onSaveAsLocation != null) ...[
          _ActionTile(
            label: '🏠 LOCATION に登録',
            onTap: () async {
              final err = await onSaveAsLocation!();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(err ?? '✓ LOCATION に登録しました'),
                duration: const Duration(seconds: 2),
              ));
            },
          ),
          const SizedBox(height: 6),
        ],
        _ActionTile(label: '✈ ここへ移動', onTap: onMoveToHit),
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
        Text(label, style: TextStyle(fontSize: 13, color: color)),
        const SizedBox(width: 4),
        Text(score.toStringAsFixed(1), style: const TextStyle(fontSize: 13, color: Color(0xFF999999))),
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
              style: const TextStyle(fontSize: 13, color: Color(0xFFC9A84C), letterSpacing: 0.5)),
        ),
      ),
    );
  }
}
