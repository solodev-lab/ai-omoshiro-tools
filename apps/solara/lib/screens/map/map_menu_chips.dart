import 'package:flutter/material.dart';

/// メニューチップの種別。タップで対応する BottomSheet が起動。
enum MapMenuChip {
  /// 表示: 16方位 / コンパス / マップスタイル
  display,

  /// 占星: 惑星ライン / 引越し / CCG 4線 / CHART / PLANET GROUP / FORTUNE カテゴリ + ACG
  astro,

  /// 地点: VIEWPOINT / LOCATIONS タブ + 詳細管理画面リンク
  locations,

  /// 予報: ForecastScreen を開く
  forecast,
}

/// NavBar 直上の 4 チップバー。
///
/// 設計（2026-05-09）:
/// - 旧 7 サイドボタンのうち 6 個 (☰/✨/📍/🗺/🔮/🌐) をここに集約。
/// - 🔍 検索は左サイドに残存。▲運勢方位 PullTab はチップバーの上に配置。
/// - タップ → 対応する _showSheet 起動 (showModalBottomSheet 経由)。
class MapMenuChips extends StatelessWidget {
  final ValueChanged<MapMenuChip> onTap;

  const MapMenuChips({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xCC0A0A19),
            Color(0xE60A0A19),
          ],
        ),
        border: Border(
          top: BorderSide(color: Color(0x33C9A84C)),
        ),
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Row(
          children: [
            _chip(MapMenuChip.display, '⚙️', '表示'),
            _chip(MapMenuChip.astro, '✨', '占星'),
            _chip(MapMenuChip.locations, '📍', '地点'),
            _chip(MapMenuChip.forecast, '📈', '予報'),
          ],
        ),
      ),
    );
  }

  Widget _chip(MapMenuChip key, String icon, String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTap(key),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x33C9A84C)),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x22C9A84C),
                  Color(0x0AC9A84C),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFC9A84C),
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
