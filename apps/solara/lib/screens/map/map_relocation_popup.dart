import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/astro_glossary.dart' show showAstroGlossaryDialog;
import '../../utils/astro_houses.dart';
import '../../utils/astro_lines.dart';
import '../../widgets/astro_term_label.dart';
import '../horoscope/horo_constants.dart' show planetGlyphs, planetNamesJP, signNames;
import 'map_constants.dart' show planetMeta;
import 'map_line_narrative_sheet.dart';

// ══════════════════════════════════════════════════
// Map Relocation Popup — Phase M2 引越しレイヤー (タップ詳細)
//
// 設計: project_solara_astrocartography_m2.md
//   論点11 (9-β改): home設定済み→現住所→引越し先比較
//                  home未設定→出生地→タップ地点比較
//   論点8 (6-D1): デフォルトOFF (LayerPanelで明示的にON)
//   論点10 (8-β):  1タップで線情報+12ハウス情報を統合表示
//                 ・aspect レイヤーON & 線が近い  → 線セクション表示
//                 ・relocate レイヤーON         → ASC/MC + ハウスセクション表示
//                 ・両方ON                      → 全部表示 (統合 popup)
// ══════════════════════════════════════════════════

const _planetOrder = [
  'sun', 'moon', 'mercury', 'venus', 'mars',
  'jupiter', 'saturn', 'uranus', 'neptune', 'pluto',
];

const _personalPlanets = {'sun', 'moon', 'mercury', 'venus', 'mars'};

// アングル別の短い添字 (popup の線セクション用)
const _angleShortJp = {
  'asc': '自我・第一印象',
  'mc': 'キャリア・社会',
  'dsc': '対人・パートナー',
  'ic': '家庭・心の拠り所',
};

class MapRelocationPopup extends StatelessWidget {
  /// タップ地点
  final double tapLat;
  final double tapLng;

  /// 出生時刻ベースのチャート (Worker fetchChart の結果)
  final Map<String, double> natalPlanets; // 10惑星黄経 (relocateで不変)
  final double baselineMc;   // 比較ベース (home or birth) のMC
  final double baselineLng;  // 比較ベース (home or birth) のlng
  final List<double> baselineHouses; // 比較ベースのハウス12個

  /// 比較ベースが home(現住所) か birth(出生地) かのラベル用
  final String baselineLabel;

  /// 引越しレイヤー (ASC/MC + 12ハウス) を表示するか
  /// (relocate トグルがONなら true)
  final bool showHouses;

  /// 近接アスペクト線 (空 or null なら線セクション非表示)
  final List<NearbyAstroLine>? nearbyLines;

  /// Tier S #2: ライン narrative API 用文脈（任意）
  /// 設定済みなら線行タップで MapLineNarrativeSheet を開ける。
  /// null の場合は線行はタップ不可（静的表示のみ）。
  final Map<String, int>? natalSummary; // {ascSign, mcSign, sunSign, moonSign}
  final String? tappedPlaceName;
  final String? transitDate; // frame==transit のラインで使う
  final String lang;
  final String? userName;

  final VoidCallback onClose;

  /// 「📍この場所で相談」エントリ (Phase 2-3b)。
  /// 設定すると popup ヘッダ下に CTA ボタンが現れ、タップで onConsult が発火する。
  /// 呼出側 (map_screen) で popup 閉 → reverse_geocode → 入力画面 push を行う。
  /// null の場合はボタン非表示。
  final VoidCallback? onConsult;

  const MapRelocationPopup({
    super.key,
    required this.tapLat,
    required this.tapLng,
    required this.natalPlanets,
    required this.baselineMc,
    required this.baselineLng,
    required this.baselineHouses,
    required this.baselineLabel,
    required this.onClose,
    this.showHouses = true,
    this.nearbyLines,
    this.natalSummary,
    this.tappedPlaceName,
    this.transitDate,
    this.lang = 'ja',
    this.userName,
    this.onConsult,
  });

  @override
  Widget build(BuildContext context) {
    final hasLines = (nearbyLines != null && nearbyLines!.isNotEmpty);

    // showHouses 時のみ ASC/MC/houses を再計算 (重い処理を回避)
    HousesResult? relocated;
    int ascSignFrom = 0, ascSignTo = 0, mcSignFrom = 0, mcSignTo = 0;
    if (showHouses) {
      relocated = calcHousesRelocate(
        natalMc: baselineMc,
        natalLng: baselineLng,
        tapLat: tapLat,
        tapLng: tapLng,
      );
      ascSignFrom = _signOf(_recoverBaselineAsc());
      ascSignTo = _signOf(relocated.asc);
      mcSignFrom = _signOf(baselineMc);
      mcSignTo = _signOf(relocated.mc);
    }

    final mq = MediaQuery.of(context);
    // 端末フォント拡大時にコンテンツが伸びても画面上端を突き抜けないよう、
    // 画面高さの 70% で上限を切り、その内側を SingleChildScrollView で
    // スクロール可能にする。
    // 旧: Positioned(bottom: 0) + Column(mainAxisSize: min) + 高さ制限なし
    //   で、長文時に上端が status bar を突き抜けてスクロール不能だった。
    final maxH = (mq.size.height - mq.padding.top) * 0.7;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xEE0C0C1A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: const Color(0x33C9A84C)),
      ),
      constraints: BoxConstraints(maxHeight: maxH),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, showHouses: showHouses, hasLines: hasLines),
            if (onConsult != null) ...[
              const SizedBox(height: 10),
              _buildConsultCta(),
            ],
            if (hasLines) ...[
              const SizedBox(height: 10),
              _buildLinesSection(context, nearbyLines!),
            ],
            if (showHouses && relocated != null) ...[
              if (hasLines)
                const Divider(color: Color(0x22FFFFFF), height: 18)
              else
                const SizedBox(height: 10),
              _buildAngleRow('ASC', ascSignFrom, ascSignTo),
              const SizedBox(height: 4),
              _buildAngleRow('MC', mcSignFrom, mcSignTo),
              const Divider(color: Color(0x22FFFFFF), height: 18),
              _buildPlanetGrid(relocated.houses),
            ],
          ],
        ),
      ),
    );
  }

  // ── Phase 2-3b: (ii) Stella 相談 CTA ──
  /// タップ地点を起点に Stella 相談を開始するエントリーボタン。
  /// onConsult 非 null のときのみ表示される (map_screen 側で配線)。
  Widget _buildConsultCta() {
    return InkWell(
      onTap: onConsult,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0x22F6BD60),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0x66F6BD60)),
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome,
                size: 14, color: Color(0xFFF9D976)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'この場所で相談する',
                style: GoogleFonts.notoSansJp(
                  fontSize: 13,
                  color: const Color(0xFFF9D976),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 14, color: Color(0xFFF9D976)),
          ],
        ),
      ),
    );
  }

  // ── 論点10: 線情報セクション ──
  Widget _buildLinesSection(BuildContext context, List<NearbyAstroLine> lines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.timeline, size: 12, color: Color(0xFFB088FF)),
            const SizedBox(width: 6),
            AstroTermLabel(
              // 2026-05-08: i ボタン拡大 (iconSize 10→16)
              termKey: 'aspect_lines',
              iconSize: 16,
              spacing: 2,
              child: Text(
                'ライン上の地点 (近接${lines.length}本)',
                style: GoogleFonts.notoSansJp(
                  fontSize: 13,
                  color: const Color(0xFFB088FF),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // 近い順に最大5本表示 (それ以上は省略)
        for (final n in lines.take(5)) _buildLineRow(context, n),
        if (lines.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 2, left: 18),
            child: Text(
              '他${lines.length - 5}本',
              style: GoogleFonts.notoSansJp(
                fontSize: 13,
                color: const Color(0xFF666666),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLineRow(BuildContext context, NearbyAstroLine n) {
    final meta = planetMeta[n.line.planet];
    final glyph = planetGlyphs[n.line.planet] ?? '';
    final pName = planetNamesJP[n.line.planet] ?? n.line.planet;
    final aLabel = n.line.angle.toUpperCase();
    final shortJp = _angleShortJp[n.line.angle] ?? '';
    final color = meta?.color ?? const Color(0xFFE8E0D0);
    final dist = n.distanceKm;
    final distStr = dist < 10
        ? '${dist.toStringAsFixed(1)}km'
        : '${dist.round()}km';

    // 静的解説のみなので natalSummary 等の文脈に関わらず常にタップ可能。
    // 旧: natalSummary != null (Stella 用文脈) で判定していたが、Stella の解説は
    // 2026-05-11 撤去済み。
    return InkWell(
      onTap: () => _openLineSheet(context, n),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
        child: Row(
          children: [
          SizedBox(
            width: 16,
            child: Text(glyph, style: TextStyle(fontSize: 13, color: color)),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 50,
            child: Text(
              pName,
              style: GoogleFonts.notoSansJp(
                fontSize: 13, color: color, fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withAlpha(120)),
            ),
            child: Text(
              aLabel,
              style: GoogleFonts.notoSansJp(
                fontSize: 13, color: color, letterSpacing: 0.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              shortJp,
              style: GoogleFonts.notoSansJp(
                fontSize: 13, color: const Color(0xFFAAAAAA),
              ),
            ),
          ),
          Text(
            distStr,
            style: GoogleFonts.notoSansJp(
              fontSize: 13, color: const Color(0xFF777777),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right,
              size: 14, color: Color(0xFF888888)),
          ],
        ),
      ),
    );
  }

  void _openLineSheet(BuildContext context, NearbyAstroLine n) {
    final frameKey =
        n.line.frame == AstroFrame.transit ? 'transit' : 'natal';
    showLineNarrativeSheet(
      context,
      nearby: n,
      frame: frameKey,
      tappedLat: tapLat,
      tappedLng: tapLng,
      // Phase 2026-05-16 (B): 線説明 sheet 内からも「この地点で相談」可能に。
      // 親 popup の onConsult をそのまま伝搬 (タップ座標 = 元のマップタップ座標)。
      onConsult: onConsult,
    );
  }

  /// Flexible で囲んだタイトル + (termKey 非 null 時) i ボタンを横並びに。
  /// Row(min) 内で Flexible Text なので、親 Expanded の制約を尊重して overflow しない。
  Widget _buildTitleArea(
      BuildContext context, String? termKey, Widget titleText) {
    if (termKey == null) {
      // ラインタップ popup と同じ「生の Flexible Text」
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [Flexible(child: titleText)],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: GestureDetector(
            onTap: () => showAstroGlossaryDialog(context, termKey),
            behavior: HitTestBehavior.opaque,
            child: titleText,
          ),
        ),
        const SizedBox(width: 3),
        GestureDetector(
          onTap: () => showAstroGlossaryDialog(context, termKey),
          behavior: HitTestBehavior.opaque,
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Icons.info_outline,
                size: 16, color: Color(0xAACCCCCC)),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context,
      {required bool showHouses, required bool hasLines}) {
    // タイトルは状況に応じて変える
    final String title;
    final String? termKey;
    if (showHouses && hasLines) {
      title = '統合 — ${_fmtCoord(tapLat, tapLng)}';
      termKey = null; // 統合表示は専用辞書なし
    } else if (showHouses) {
      title = '引越しレイヤー — ${_fmtCoord(tapLat, tapLng)}';
      termKey = 'relocate_layer';
    } else {
      title = 'タップ地点 — ${_fmtCoord(tapLat, tapLng)}';
      termKey = 'aspect_lines';
    }

    // 2026-05-11: 旧仕様で termKey!=null のとき AstroTermLabel (= Row mainAxis:min)
    // でラップしていたため、内部 Text が親 Expanded の制約を無視して overflow を
    // 起こしていた。ラインタップ popup (termKey=null = 生 Text) と同じ動作にする
    // ため、Expanded の中で「Flexible Text + i ボタン」を自前で組む。
    final titleText = Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.notoSansJp(
        fontSize: 13,
        color: const Color(0xFFE8E0D0),
        letterSpacing: 0.6,
      ),
    );

    // 2026-05-12: 横一列だと「統合 — 35.71°N, 139.77°E」と「現住所 → タップ地点」
    // が窮屈で見にくいため、2 行構成に変更。
    //   1 行目: [📍] 統合 — 35.71°N, 139.77°E              [×]
    //   2 行目: 　　 現住所 → タップ地点
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.place, size: 14, color: Colors.pink.shade200),
            const SizedBox(width: 6),
            // タイトル + (任意で) i ボタン を Expanded 内で並べる。
            // Flexible Text で長文時に省略 → overflow しない。
            Expanded(child: _buildTitleArea(context, termKey, titleText)),
            const SizedBox(width: 8),
            // 座標取得: タップ地点の座標を "緯度, 経度" でコピー (Horo 画面で貼り付け可)。
            GestureDetector(
              onTap: () => _copyCoords(context),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0x66C9A84C)),
                  color: const Color(0x14C9A84C),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.copy, size: 11, color: Color(0xFFC9A84C)),
                  SizedBox(width: 4),
                  Text('座標取得',
                      style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFFC9A84C),
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onClose,
              child: const Icon(Icons.close, size: 16, color: Color(0xFF888888)),
            ),
          ],
        ),
        if (showHouses) Padding(
          // アイコン (size 14) + spacing (6) = 20px 分インデントして
          // タイトルテキストの左端と揃える。
          padding: const EdgeInsets.only(left: 20, top: 2),
          child: Text(
            '$baselineLabel → タップ地点',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.notoSansJp(
              fontSize: 12,
              color: const Color(0xFF888888),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAngleRow(String label, int signFrom, int signTo) {
    final changed = signFrom != signTo;
    final termKey = label.toLowerCase(); // 'asc' or 'mc'
    // 2026-05-08: フォント拡大時の RIGHT OVERFLOW 対策で Wrap 化。
    // i ボタンは iconSize 10→16 に拡大 (異常に小さいというユーザー指摘)。
    // 星座ラベル + 矢印を 1 ユニットとして Wrap で扱い、入りきらない場合は
    // 2 行に折返し可能。
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        AstroTermLabel(
          termKey: termKey,
          iconSize: 16,
          spacing: 2,
          child: Text(
            label,
            style: GoogleFonts.notoSansJp(
              fontSize: 13,
              color: const Color(0xFFC9A84C),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Text(
          '${signNames[signFrom]}座',
          style: GoogleFonts.notoSansJp(
            fontSize: 13,
            color: const Color(0xFFAAAAAA),
          ),
        ),
        Icon(
          Icons.arrow_forward,
          size: 11,
          color: changed
              ? const Color(0xFFFFB6C1)
              : const Color(0xFF555555),
        ),
        Text(
          '${signNames[signTo]}座',
          style: GoogleFonts.notoSansJp(
            fontSize: 13,
            color: changed
                ? const Color(0xFFFFD370)
                : const Color(0xFFAAAAAA),
            fontWeight: changed ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        if (!changed)
          Text(
            '変化なし',
            style: GoogleFonts.notoSansJp(
              fontSize: 13,
              color: const Color(0xFF555555),
            ),
          ),
      ],
    );
  }

  Widget _buildPlanetGrid(List<double> tapHouses) {
    return Column(
      children: [
        for (final planet in _planetOrder)
          _buildPlanetRow(planet, tapHouses),
      ],
    );
  }

  Widget _buildPlanetRow(String planet, List<double> tapHouses) {
    final lon = natalPlanets[planet];
    if (lon == null) return const SizedBox.shrink();
    final fromHouse = assignPlanetHouse(lon, baselineHouses);
    final toHouse = assignPlanetHouse(lon, tapHouses);
    final changed = fromHouse != null && toHouse != null && fromHouse != toHouse;
    final isPersonal = _personalPlanets.contains(planet);

    final dimColor = changed
        ? Colors.white.withAlpha(230)
        : Colors.white.withAlpha(110);
    final accentColor = changed
        ? (isPersonal ? const Color(0xFFFFD370) : const Color(0xFFFFB6C1))
        : const Color(0xFF888888);

    // 2026-05-08: 3 文字惑星名 (天王星 / 海王星 / 冥王星) がフォント拡大時に
    // 2 行表示になっていた問題を解消。横幅は余裕があるので、固定幅 50→64 に
    // 拡張 + softWrap: false + maxLines: 1 で 1 行表示を保証。
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            child: Text(
              planetGlyphs[planet] ?? '',
              style: TextStyle(fontSize: 14, color: dimColor),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 64,
            child: Text(
              planetNamesJP[planet] ?? planet,
              style: GoogleFonts.notoSansJp(fontSize: 13, color: dimColor),
              softWrap: false,
              maxLines: 1,
              overflow: TextOverflow.visible,
            ),
          ),
          Text(
            fromHouse != null ? '${fromHouse}H' : '—',
            style: GoogleFonts.notoSansJp(
              fontSize: 13,
              color: const Color(0xFFAAAAAA),
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.arrow_forward, size: 11, color: accentColor),
          const SizedBox(width: 6),
          Text(
            toHouse != null ? '${toHouse}H' : '—',
            style: GoogleFonts.notoSansJp(
              fontSize: 13,
              color: accentColor,
              fontWeight: changed ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          const Spacer(),
          if (changed && isPersonal)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0x55FFD370)),
              ),
              child: Text(
                '個人天体',
                style: GoogleFonts.notoSansJp(
                  fontSize: 13,
                  color: const Color(0xFFFFD370),
                ),
              ),
            )
          else if (!changed)
            Text(
              '変化なし',
              style: GoogleFonts.notoSansJp(
                fontSize: 13,
                color: const Color(0xFF555555),
              ),
            ),
        ],
      ),
    );
  }

  /// baselineMc を起点に baselineHouses[0]=ASC を取得 (Placidus定義より houses[0]=asc)
  double _recoverBaselineAsc() {
    if (baselineHouses.length == 12) return baselineHouses[0];
    return baselineMc; // フォールバック (本来到達しない)
  }

  int _signOf(double lon) {
    final n = (lon % 360 + 360) % 360;
    return (n / 30).floor() % 12;
  }

  String _fmtCoord(double lat, double lng) {
    final latStr = lat >= 0 ? '${lat.toStringAsFixed(2)}°N' : '${(-lat).toStringAsFixed(2)}°S';
    final lngStr = lng >= 0 ? '${lng.toStringAsFixed(2)}°E' : '${(-lng).toStringAsFixed(2)}°W';
    return '$latStr  $lngStr';
  }

  /// 座標を "緯度, 経度" (小数) でクリップボードへコピー。
  /// Horo 画面の出生地/トランジット場所欄で「座標貼り付け」できる。
  void _copyCoords(BuildContext context) {
    Clipboard.setData(ClipboardData(
        text: '${tapLat.toStringAsFixed(6)}, ${tapLng.toStringAsFixed(6)}'));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('座標をコピーしました'),
      duration: Duration(seconds: 2),
    ));
  }
}
