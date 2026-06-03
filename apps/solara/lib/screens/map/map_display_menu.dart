import 'package:flutter/material.dart';

import '../../widgets/info_popup.dart';
import 'map_constants.dart';
import 'map_styles.dart';

/// 左サイド ☰表示ボタンタップで右に展開するメニュー (2026-05-09)。
///
/// 3 階層タブ構造:
///   L1 (主タブ): [Map] [惑星] [ACG]
///   L2 (副タブ): 主タブ別に異なる
///       Map → [Map][MapDark][運勢方位][コンパス]
///       惑星 → [タイプ][グループ][テーマ]    (各々が L3 開閉トリガー)
///       ACG → [Natal線][Transit線][Prog線][S.Arc線][引越し]
///   L3 (惑星の副タブ展開時のみ):
///       タイプ   → [Natal][Prog][Transit]
///       グループ → [個人][社会][世代]
///       テーマ   → [総合][癒し][豊かさ][恋愛][仕事][話す]
///
/// 英語ロケール対応時は L2 を TYPE/GROUP/FOCUS に切替予定。
///
/// 設計意図:
/// - 旧 BottomSheet 方式は「シートで地図が隠れて変化が見えない」問題があった。
///   横展開メニューで地図右半分が常時見えるため、トグル変化の視覚フィードバックが
///   保たれる。
/// - 行ごとに横スクロール可能。ボタン幅を内容に合わせて確保。
class MapDisplayMenu extends StatefulWidget {
  final Map<String, bool> layers;
  final Map<String, bool> planetGroups;
  final Map<String, bool> astroLayers;

  /// 惑星>FORTUNE の選択状態。扇状の `_activeCategory` とは独立。
  /// このメニューから変更してもセクター描画には影響しない (惑星ライン/
  /// アスペクト線/天頂点マーカーの表示フィルタのみ更新)。
  final String planetFilterCategory;
  final MapStyle mapStyle;
  final ValueChanged<String> onLayerToggle;
  final ValueChanged<String> onPlanetGroupToggle;
  final ValueChanged<String> onAstroToggle;
  final ValueChanged<String> onPlanetFilterChanged;
  final ValueChanged<MapStyle> onMapStyleChanged;

  const MapDisplayMenu({
    super.key,
    required this.layers,
    required this.planetGroups,
    required this.astroLayers,
    required this.planetFilterCategory,
    required this.mapStyle,
    required this.onLayerToggle,
    required this.onPlanetGroupToggle,
    required this.onAstroToggle,
    required this.onPlanetFilterChanged,
    required this.onMapStyleChanged,
  });

  @override
  State<MapDisplayMenu> createState() => _MapDisplayMenuState();
}

enum _MainTab { map, planet, acg }
enum _PlanetSub { chart, pg, fortune }

class _MapDisplayMenuState extends State<MapDisplayMenu> {
  _MainTab _tab = _MainTab.map;
  _PlanetSub? _planetSub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xEB0A0A19),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x33C9A84C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _scrollRow([
            _tabBtnWithInfo('Map', _MainTab.map),
            _tabBtnWithInfo('惑星', _MainTab.planet),
            _tabBtnWithInfo('ACG', _MainTab.acg),
          ]),
          const SizedBox(height: 6),
          _scrollRow(_l2Buttons()),
          if (_tab == _MainTab.planet && _planetSub != null) ...[
            const SizedBox(height: 6),
            _scrollRow(_l3Buttons()),
          ],
        ],
      ),
    );
  }

  // ── L2 (主タブ別の副タブ) ────────────────────────────────────
  List<Widget> _l2Buttons() {
    switch (_tab) {
      case _MainTab.map:
        return [
          _radioBtn('Map', widget.mapStyle == MapStyle.osmHotLight,
              () => widget.onMapStyleChanged(MapStyle.osmHotLight)),
          _radioBtn('MapDark', widget.mapStyle == MapStyle.osmHotDark,
              () => widget.onMapStyleChanged(MapStyle.osmHotDark)),
          _toggleBtn('運勢方位', widget.layers['sectors'] ?? false,
              () => widget.onLayerToggle('sectors')),
          _toggleBtn('コンパス', widget.layers['compass'] ?? false,
              () => widget.onLayerToggle('compass')),
          // 「座標取得」: 十字 (+) は常時表示、ラベル (緯度経度) のみ
          // このトグルで制御。ラベル常時表示は地図が見にくいのでトグル制。
          _toggleBtn('座標取得', widget.layers['coords'] ?? false,
              () => widget.onLayerToggle('coords')),
        ];
      case _MainTab.planet:
        // L2 ラベル (2026-05-09 リネーム): 旧 CHART/PG/FORTUNE は日本語として
        // 直感的でなかったので、カタカナの簡素なラベルに統一。
        // 英語ロケール対応時は TYPE/GROUP/FOCUS の予定。
        return [
          _subTabBtn('タイプ', _planetSub == _PlanetSub.chart, () => _toggleSub(_PlanetSub.chart)),
          _subTabBtn('グループ', _planetSub == _PlanetSub.pg, () => _toggleSub(_PlanetSub.pg)),
          _subTabBtn('テーマ', _planetSub == _PlanetSub.fortune, () => _toggleSub(_PlanetSub.fortune)),
        ];
      case _MainTab.acg:
        return [
          _toggleBtn('Natal線', widget.astroLayers['aspect'] ?? false,
              () => widget.onAstroToggle('aspect')),
          _toggleBtn('Transit線', widget.astroLayers['aspectTransit'] ?? false,
              () => widget.onAstroToggle('aspectTransit')),
          _toggleBtn('Prog線', widget.astroLayers['aspectProgressed'] ?? false,
              () => widget.onAstroToggle('aspectProgressed')),
          _toggleBtn('S.Arc線', widget.astroLayers['aspectSolarArc'] ?? false,
              () => widget.onAstroToggle('aspectSolarArc')),
          // B1: アスペクト線 (square/trine/sextile)。全フレーム共通トグル、デフォルト OFF。
          _toggleBtn('アスペクト線', widget.astroLayers['aspectLines'] ?? false,
              () => widget.onAstroToggle('aspectLines')),
          // 2026-05-11 「天頂帯」を ACG モード下部の 2 層メニュー (各フレーム配下) に移動。
          // フレーム別に独立 (zenithBand_natal / nadirBand_transit 等) なので
          // ここの共通トグルは廃止。
          _toggleBtn('引越し', widget.astroLayers['relocate'] ?? false,
              () => widget.onAstroToggle('relocate')),
        ];
    }
  }

  // ── L3 (惑星の副タブ展開時のみ) ────────────────────────────────
  List<Widget> _l3Buttons() {
    switch (_planetSub!) {
      case _PlanetSub.chart:
        return [
          _toggleBtn('Natal', widget.layers['natal'] ?? false,
              () => widget.onLayerToggle('natal')),
          _toggleBtn('Prog', widget.layers['progressed'] ?? false,
              () => widget.onLayerToggle('progressed')),
          _toggleBtn('Transit', widget.layers['transit'] ?? false,
              () => widget.onLayerToggle('transit')),
        ];
      case _PlanetSub.pg:
        return [
          _toggleBtn('個人', widget.planetGroups['personal'] ?? false,
              () => widget.onPlanetGroupToggle('personal')),
          _toggleBtn('社会', widget.planetGroups['social'] ?? false,
              () => widget.onPlanetGroupToggle('social')),
          _toggleBtn('世代', widget.planetGroups['generational'] ?? false,
              () => widget.onPlanetGroupToggle('generational')),
        ];
      case _PlanetSub.fortune:
        return [
          for (final e in categoryColors.entries)
            _radioBtn(
              categoryLabels[e.key] ?? e.key,
              widget.planetFilterCategory == e.key,
              () => widget.onPlanetFilterChanged(e.key),
              tintColor: e.value,
            ),
        ];
    }
  }

  void _toggleSub(_PlanetSub sub) {
    setState(() {
      _planetSub = (_planetSub == sub) ? null : sub;
    });
  }

  // ── ボタンビルダー ────────────────────────────────────────
  /// L1 主タブ (3 個。常に 1 個だけ active)
  Widget _tabBtn(String label, bool active, VoidCallback onTap) {
    return _ChipButton(
      label: label,
      active: active,
      tintColor: const Color(0xFFC9A84C),
      onTap: onTap,
      bold: true,
    );
  }

  /// L1 タブ + 右隣に i ボタン (タップで内部表示の説明 popup)。
  /// i は本体タブと別の GestureDetector を持ち、タブ切替とは独立に動く。
  Widget _tabBtnWithInfo(String label, _MainTab tab) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      _tabBtn(label, _tab == tab, () => setState(() => _tab = tab)),
      const SizedBox(width: 2),
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _showTabInfo(tab),
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: Icon(Icons.info_outline,
              size: 14, color: Color(0x99C9A84C)),
        ),
      ),
    ]);
  }

  /// L1 主タブの内部表示を説明する popup を出す。
  /// 内容は L2/L3 の各項目で何ができるかの概要。
  void _showTabInfo(_MainTab tab) {
    late String title;
    late List<(String, String)> items;
    switch (tab) {
      case _MainTab.map:
        title = 'Map レイヤー';
        items = const [
          ('Map / MapDark', '通常マップとダークマップを切替。視認性の好みで選択。'),
          ('運勢方位', '自分の運勢を 16 方位の扇形で地図上に表示。色が濃い方位ほど追い風。タップでカテゴリ別に絞り込める。'),
          ('コンパス', '中心地点から見た方位線 (N / E / S / W)。距離感の把握に。'),
          ('座標取得', '画面中央の + の下に緯度経度ラベルを表示。地図を動かすと中心の座標がリアルタイムで更新される。ラベルをタップするとクリップボードにコピーされる。場所登録の事前確認や任意地点の座標確認に。十字 (+) 自体はトグル OFF でも常時表示。'),
        ];
        break;
      case _MainTab.planet:
        // map_constants.dart の planetMeta / planetGroups / fortunePlanets
        // を引いて日本語名で全惑星を列挙する (短縮 Sun〜Mars 表記をやめ、
        // ユーザーが惑星を見落とさず確認できる形に)。
        String planetsJp(List<String> keys) =>
            keys.map((k) => planetMeta[k]?.jp ?? k).join(' / ');
        title = '惑星レイヤー';
        items = [
          (
            'タイプ',
            'どのチャートの惑星を表示するか。'
                'Natal (出生時固定) / Prog (1日=1年で進行) / Transit (今この瞬間)。'
          ),
          (
            'グループ',
            '10 惑星のグループフィルタ。\n'
                '・個人: ${planetsJp(planetGroups["personal"]!)}\n'
                '・社会: ${planetsJp(planetGroups["social"]!)}\n'
                '・世代: ${planetsJp(planetGroups["generational"]!)}'
          ),
          (
            'テーマ',
            'カテゴリ別フィルタ。テーマに関わる惑星のみ強調表示する。\n'
                '・総合: 全惑星\n'
                '・癒し: ${planetsJp(fortunePlanets["healing"]!)}\n'
                '・豊かさ: ${planetsJp(fortunePlanets["money"]!)}\n'
                '・恋愛: ${planetsJp(fortunePlanets["love"]!)}\n'
                '・仕事: ${planetsJp(fortunePlanets["work"]!)}\n'
                '・話す: ${planetsJp(fortunePlanets["communication"]!)}'
          ),
        ];
        break;
      case _MainTab.acg:
        title = 'ACG レイヤー (Astro*Carto*Graphy)';
        items = const [
          ('4 フレームのライン (Natal / Transit / Prog / S.Arc)',
              '各惑星 × 4 アングル (ASC/MC/DSC/IC) の「本線」を世界規模で描画。4 フレームはすべて無料で切替できる (Natal=出生時固定 / Transit=今動く / Prog=2次進行 / S.Arc=ソーラーアーク)。各ピル横の i ボタンに詳しい説明があります。'),
          ('アスペクト線 〔Pro〕',
              '本線 (コンジャンクション 40 本) に、スクエア / トライン / セクスタイルを加えた全 120 本を表示する拡張。ON 中の全フレームに同時適用されます。Cosmic Pro 限定。'),
          ('引越し 〔Pro〕',
              '地図タップ地点を引越し先に見立てて表示。①現住所と比べて近づく / 遠ざかる星のライン、②ASC / MC の星座変化、③10 惑星の 12 ハウス遷移、をまとめて確認できます。Cosmic Pro 限定。'),
          ('表示のヒント',
              'ACG 線は世界規模で表示するため、ズームレベルによっては画面外に出て見えないことがあります。ズームアウト (縮小表示) すると線の全体像が確認しやすくなります。'),
        ];
        break;
    }
    showInfoPopup(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFFC9A84C),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6)),
          const SizedBox(height: 12),
          for (final item in items) ...[
            _MenuInfoRow(title: item.$1, body: item.$2),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  /// L2 副タブ (惑星専用、開閉トリガー)
  Widget _subTabBtn(String label, bool open, VoidCallback onTap) {
    return _ChipButton(
      label: label,
      active: open,
      tintColor: const Color(0xFFFFD370),
      onTap: onTap,
    );
  }

  /// 通常トグル (ON/OFF)
  Widget _toggleBtn(String label, bool on, VoidCallback onTap) {
    return _ChipButton(
      label: label,
      active: on,
      tintColor: const Color(0xFFC9A84C),
      onTap: onTap,
    );
  }

  /// ラジオ (排他選択)
  Widget _radioBtn(String label, bool selected, VoidCallback onTap, {Color? tintColor}) {
    return _ChipButton(
      label: label,
      active: selected,
      tintColor: tintColor ?? const Color(0xFFC9A84C),
      onTap: onTap,
    );
  }

  /// 横スクロール可能な行 (ボタン数が多い場合の overflow 対策)
  Widget _scrollRow(List<Widget> children) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// 説明 popup 用の項目行 (見出し + 本文)。
class _MenuInfoRow extends StatelessWidget {
  final String title;
  final String body;
  const _MenuInfoRow({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFE9D29A),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4)),
        const SizedBox(height: 3),
        Text(body,
            style: const TextStyle(
                fontSize: 12, color: Color(0xFFCCCCCC), height: 1.45)),
      ],
    );
  }
}

/// 共通のチップ風ボタン (active 状態で塗りつぶし変化)。
class _ChipButton extends StatelessWidget {
  final String label;
  final bool active;
  final Color tintColor;
  final VoidCallback onTap;
  final bool bold;
  const _ChipButton({
    required this.label,
    required this.active,
    required this.tintColor,
    required this.onTap,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? tintColor : tintColor.withAlpha(0x44),
            width: active ? 1.4 : 1,
          ),
          color: active ? tintColor.withAlpha(0x33) : Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: active ? tintColor : const Color(0xFF888888),
            letterSpacing: 0.4,
            fontWeight: bold || active ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
