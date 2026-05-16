import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../utils/astro_glossary.dart';
import '../../utils/astro_lines.dart' show AstroFrame;
import '../../utils/astro_zenith_messages.dart'
    show astroNadirMessages, astroZenithMessages;
import '../../widgets/info_popup.dart';
import 'map_astro_lines.dart'
    show AstroNadirMarker, AstroZenithMarker, astroFrameStyles;
import 'map_constants.dart';

// ══════════════════════════════════════════════════
// Astro*Carto*Graphy モード専用UI
//
// モード状態の入退時に表示される:
//   - AstroCartoBanner       : 上部中央のタイトル + 閉じる×
//   - AstroCartoFramePills   : 4フレーム (Natal/Transit/Prog/SArc) 切替 (Tier A #5)
//   - AstroCartoCategoryPills: 下部中央のFORTUNEカテゴリ切替
//   - AstroZenithPopup       : 天頂点マーカータップ詳細
//
// マーカー本体 (AstroZenithMarker) と線/マーカービルド関数は
// map_astro_lines.dart に置く (rendering primitives は別レイヤー)。
// ══════════════════════════════════════════════════

/// Astro*Carto*Graphy モード中の上部バナー (タイトル + 閉じる×)。
/// モード状態を視覚的に示し、復帰経路を保証する。
class AstroCartoBanner extends StatelessWidget {
  final VoidCallback onClose;
  const AstroCartoBanner({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xE60C0C1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x80C9A84C)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🌐', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          // 2026-05-08: textScaler.noScaling で固定サイズ。ACG モードバナーは
          // 上部固定の小さな pill UI で、フォント拡大時に title が膨張すると
          // バナー自体が画面幅を圧迫し、❓ や ✕ ボタンが見えなくなる。
          const Text(
            'ASTRO*CARTO*GRAPHY',
            textScaler: TextScaler.noScaling,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFFC9A84C),
              letterSpacing: 2.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          // ❓ help_outline: ACG 画面の使い方説明 popup
          GestureDetector(
            onTap: () => _showAcgUsageGuide(context),
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Icon(Icons.help_outline,
                  size: 16, color: Color(0xCCAAAAAA)),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onClose,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Icon(Icons.close, size: 14, color: Color(0xFFAAAAAA)),
            ),
          ),
        ],
      ),
    );
  }
}

/// ACG (Astro*Carto*Graphy) 画面の使い方 popup。
/// バナー左の ❓ ボタンから開く。
void _showAcgUsageGuide(BuildContext context) {
  showInfoPopup(
    context: context,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'ASTRO*CARTO*GRAPHY の使い方',
          style: TextStyle(
              color: Color(0xFFC9A84C), fontSize: 14, letterSpacing: 1),
        ),
        SizedBox(height: 10),
        // ── Jim Lewis への礼と Solara 独自性 ──
        Text(
          '— Jim Lewis が遺した、地球上の天体地図 —',
          style: TextStyle(
            color: Color(0xFFE9D29A),
            fontSize: 13,
            fontStyle: FontStyle.italic,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        Text(
          '1970 年代、占星術師 Jim Lewis によって体系化された手法。\n'
          '出生時の天体配置を世界地図上の「線」として投影し、\n'
          'どの土地でどの惑星が立ち上がるのかを描き出します。\n\n'
          'Solara はこの伝統的な ACG に「時間軸」を重ねました。\n'
          'Natal / Transit / Progressed / Solar Arc の 4 フレームと\n'
          '時刻スライダーで、過去・今・先の天体配置に自由に飛べる。\n'
          '線が時間とともに動き、星の風景が刻一刻と書き換わります。\n\n'
          'さらに Solara 独自の 16 方位スコア (運勢方位扇) を重ねれば、\n'
          '「どこに」と「いつ」が、地図と時計の上に同時に立ち上がる。\n'
          '旅・引越し・出張・大事な約束 — 行動の基準点が、ここで決まります。',
          style: TextStyle(
              color: Color(0xFFE8E0D0),
              fontSize: 13,
              height: 1.7,
              fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 18),
        Text(
          '【4 つのフレーム (上部ピル)】',
          style: TextStyle(
              color: Color(0xFFC9A84C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
        ),
        SizedBox(height: 4),
        Text(
          '・Natal: 出生時の天体位置に基づくライン (生涯不変)\n'
          '・Transit: 今この瞬間の天体位置のライン (毎日動く)\n'
          '・Prog: 2 次進行 (1 日 = 1 年の比率) のライン\n'
          '・S.Arc: ソーラーアーク (太陽進行弧で全惑星シフト)\n\n'
          'それぞれ独立に ON/OFF 可能。各ピル横の i ボタンで\n'
          '詳しい説明が見られます。',
          style: TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
        ),
        SizedBox(height: 10),
        Text(
          '【天頂マーカー (地図上の◯)】',
          style: TextStyle(
              color: Color(0xFFC9A84C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
        ),
        SizedBox(height: 4),
        Text(
          '各惑星が真上 (天頂) を通る土地を表示します。\n'
          'そこではその惑星のエネルギーがダイレクトに\n'
          '頭上から降る「シャワー直下」の地点です。\n'
          'タップで惑星固有のメッセージを確認できます。',
          style: TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
        ),
        SizedBox(height: 10),
        Text(
          '【アングルライン (地図上の線)】',
          style: TextStyle(
              color: Color(0xFFC9A84C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
        ),
        SizedBox(height: 4),
        Text(
          '惑星 × 4 アングル (ASC/MC/DSC/IC) のライン:\n'
          '・ASC (上昇): 惑星が東の地平線に昇る土地\n'
          '・MC (天頂): 惑星が真上を通る土地\n'
          '・DSC (下降): 惑星が西の地平線に沈む土地\n'
          '・IC (天底): 惑星が真下 (地球の裏側) にある土地\n\n'
          '線をタップすると、その地点の引越し効果\n'
          '(ASC/MC のサイン変化、惑星のハウス遷移) が\n'
          '詳細表示されます。',
          style: TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
        ),
        SizedBox(height: 10),
        Text(
          '【カテゴリピル (下部)】',
          style: TextStyle(
              color: Color(0xFFC9A84C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
        ),
        SizedBox(height: 4),
        Text(
          '癒し / 豊かさ / 恋愛 / 仕事 / 話す をタップで切替えると、\n'
          'そのカテゴリ関連の惑星ラインだけが強調表示されます。\n'
          '「総合」では全惑星のラインを表示。',
          style: TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
        ),
        SizedBox(height: 10),
        Text(
          '【活用方法】',
          style: TextStyle(
              color: Color(0xFFC9A84C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
        ),
        SizedBox(height: 4),
        Text(
          '旅行先・引越し先・出張先の選定に。\n'
          '同じ「行動」でも、ある土地ではエネルギーが\n'
          '強く流れ、別の土地では静かに流れます。\n'
          '見たい惑星のラインを基準に、\n'
          'あなたの目的に合う土地を見つけられます。',
          style: TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────
// ACG 下部 3 段メニュー (2026-05-11 再設計)
//
// 下から積み上げ (地図領域を最大化):
//   [3] CategoryPills    ── 一番下、FORTUNE カテゴリ
//   [2] SubPills         ── 中段、第2層 (active frame のみ表示、排他)
//   [1] FramePills       ── 上段、第1層 (4 フレーム横並び)
//
// 第2層は activeFrame が null のとき折り畳まれ、地図領域がその分広がる。
// activeFrame = 直前にタップして ON にしたフレーム (排他)。
// acgFrameDefs はビュー間で共通: layerKey / frame / shortLabel / termKey / frameSuffix。
// ─────────────────────────────────────────────────────────

class AcgFrameDef {
  final String layerKey;
  final AstroFrame frame;
  final String shortLabel;
  final String termKey;
  final String frameSuffix;
  const AcgFrameDef({
    required this.layerKey,
    required this.frame,
    required this.shortLabel,
    required this.termKey,
    required this.frameSuffix,
  });
}

const List<AcgFrameDef> acgFrameDefs = [
  AcgFrameDef(
    layerKey: 'aspect', frame: AstroFrame.natal,
    shortLabel: 'Natal', termKey: 'aspect_lines', frameSuffix: 'natal',
  ),
  AcgFrameDef(
    layerKey: 'aspectTransit', frame: AstroFrame.transit,
    shortLabel: 'Transit', termKey: 'transit_acg', frameSuffix: 'transit',
  ),
  AcgFrameDef(
    layerKey: 'aspectProgressed', frame: AstroFrame.progressed,
    shortLabel: 'Prog', termKey: 'progressed_acg', frameSuffix: 'progressed',
  ),
  AcgFrameDef(
    layerKey: 'aspectSolarArc', frame: AstroFrame.solarArc,
    shortLabel: 'S.Arc', termKey: 'solar_arc_acg', frameSuffix: 'solarArc',
  ),
];

const List<({String subKey, String label, String termKey})> _subDefs = [
  (subKey: 'zenith', label: '天頂', termKey: 'zenith_point'),
  (subKey: 'nadir', label: '天底', termKey: 'nadir_point'),
  (subKey: 'zenithBand', label: '天頂帯', termKey: 'latitude_band'),
  (subKey: 'nadirBand', label: '天底帯', termKey: 'latitude_band'),
];

/// 第1層: フレーム切替ピル (横並び 4 ピル + i)。
/// タップ: 線の ON/OFF + active 更新 (排他、第2層展開対象)。
class AstroCartoFramePills extends StatelessWidget {
  final Map<String, bool> astroLayers;
  final AstroFrame? activeFrame;
  final ValueChanged<String> onToggle;

  const AstroCartoFramePills({
    super.key,
    required this.astroLayers,
    required this.activeFrame,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final relocateOn = astroLayers['relocate'] ?? false;
    return _ScrollableRowPanel(
      borderRadius: 16,
      maxWidthMargin: 16,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...acgFrameDefs.map((d) {
            final on = astroLayers[d.layerKey] ?? false;
            final active = on && activeFrame == d.frame;
            final accent = astroFrameStyles[d.frame]!.accent;
            return _FramePill(
              label: d.shortLabel,
              accent: accent,
              on: on,
              active: active,
              onTap: () => onToggle(d.layerKey),
              onInfoTap: () => showAstroGlossaryDialog(context, d.termKey),
            );
          }),
          // S.Arc の右隣に「引越し」ピル。
          // ON のとき排他的に: 地点タップで引越し popup のみ、他 (線/天頂/天底
          // タップ) は反応しない。地図上の引越し検討に集中するためのモードトグル。
          _FramePill(
            label: '引越し',
            accent: const Color(0xFFE9D29A),
            on: relocateOn,
            active: false,
            onTap: () => onToggle('relocate'),
            onInfoTap: () => showAstroGlossaryDialog(context, 'relocate_layer'),
          ),
          // 「アスペクト」ピル (Phase 2026-05-17 追加、Pro 機能):
          // ON で本線 40 → 全 120 本 (square/trine/sextile を追加) 表示。
          // 全フレーム横断のグローバルトグル (`aspectLines` 単一フラグ)。
          // 旧 UI では MapDisplayMenu (非 ACG モードのバーガー) にのみ存在し、
          // ACG モード下部ピルには乗っていなかった (設計の見落とし)。
          _FramePill(
            label: 'アスペクト',
            accent: const Color(0xFFB59CFF),
            on: astroLayers['aspectLines'] ?? false,
            active: false,
            onTap: () => onToggle('aspectLines'),
            onInfoTap: () =>
                showAstroGlossaryDialog(context, 'aspect_lines_full'),
          ),
        ],
      ),
    );
  }
}

/// 第2層: active frame のサブトグル 4 つ (横並び)。
/// active が null なら SizedBox.shrink (高さ 0、地図領域確保)。
class AstroCartoSubPills extends StatelessWidget {
  final Map<String, bool> astroLayers;
  final AstroFrame? activeFrame;
  final ValueChanged<String> onToggle;

  const AstroCartoSubPills({
    super.key,
    required this.astroLayers,
    required this.activeFrame,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (activeFrame == null) return const SizedBox.shrink();
    final def = acgFrameDefs.firstWhere((d) => d.frame == activeFrame);
    final accent = astroFrameStyles[activeFrame!]!.accent;
    return _ScrollableRowPanel(
      borderRadius: 14,
      maxWidthMargin: 16,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _subDefs.map((sub) {
          final key = '${sub.subKey}_${def.frameSuffix}';
          final on = astroLayers[key] ?? false;
          return _SubPill(
            label: sub.label,
            accent: accent,
            on: on,
            onTap: () => onToggle(key),
            onInfoTap: () => showAstroGlossaryDialog(context, sub.termKey),
          );
        }).toList(),
      ),
    );
  }
}

/// 第1層の個別ピル (ラベル + i)。active 時はリング glow で強調。
class _FramePill extends StatelessWidget {
  final String label;
  final Color accent;
  final bool on;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback onInfoTap;
  const _FramePill({
    required this.label,
    required this.accent,
    required this.on,
    required this.active,
    required this.onTap,
    required this.onInfoTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: on ? accent : const Color(0x1FFFFFFF),
          width: on ? (active ? 1.6 : 1.0) : 0.8,
        ),
        color: on ? accent.withAlpha(active ? 50 : 26) : Colors.transparent,
        boxShadow: active
            ? [BoxShadow(color: accent.withAlpha(140), blurRadius: 8)]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 5, 4, 5),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: on ? accent : const Color(0xFF888888),
                  letterSpacing: 0.3,
                  fontWeight: on ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: onInfoTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.info_outline,
                size: 16,
                color: on ? accent.withAlpha(220) : const Color(0xCCAAAAAA),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 第2層の個別小ピル (天頂 / 天底 / 天頂帯 / 天底帯)。
class _SubPill extends StatelessWidget {
  final String label;
  final Color accent;
  final bool on;
  final VoidCallback onTap;
  final VoidCallback onInfoTap;
  const _SubPill({
    required this.label,
    required this.accent,
    required this.on,
    required this.onTap,
    required this.onInfoTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: on ? accent.withAlpha(220) : const Color(0x1FFFFFFF),
          width: on ? 1.1 : 0.7,
        ),
        color: on ? accent.withAlpha(26) : Colors.transparent,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(9, 4, 3, 4),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: on ? accent : const Color(0xFF888888),
                  letterSpacing: 0.2,
                  fontWeight: on ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: onInfoTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.info_outline,
                size: 13,
                color: on ? accent.withAlpha(220) : const Color(0xCCAAAAAA),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ピル列の overflow 対策ラッパー。
/// - コンテンツが画面幅 - maxWidthMargin に収まる: 中央寄せで通常表示
/// - 超える: 横スクロール可能
/// 共通のグラスモーフィズム枠 (背景・border・角丸) を内蔵。
class _ScrollableRowPanel extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double maxWidthMargin;
  const _ScrollableRowPanel({
    required this.child,
    required this.borderRadius,
    this.maxWidthMargin = 16,
  });

  @override
  Widget build(BuildContext context) {
    final maxW =
        MediaQuery.of(context).size.width - maxWidthMargin;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxW),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xE60C0C1A),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: const Color(0x33C9A84C)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: child,
        ),
      ),
    );
  }
}

/// Astro*Carto*Graphy モード中のカテゴリピル。
/// (LayerPanel の代わりにモード中のFORTUNEカテゴリ切替を担当)
class AstroCartoCategoryPills extends StatelessWidget {
  final String activeCategory;
  final ValueChanged<String> onChanged;
  const AstroCartoCategoryPills({
    super.key,
    required this.activeCategory,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _ScrollableRowPanel(
      borderRadius: 18,
      maxWidthMargin: 16,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: categoryColors.entries.map((e) {
          final active = activeCategory == e.key;
          // glossary キーは fortune_<categoryKey>
          final termKey = 'fortune_${e.key}';
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: active ? e.value : const Color(0x1FFFFFFF),
              ),
              color: active ? e.value.withAlpha(36) : Colors.transparent,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => onChanged(e.key),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(9, 4, 3, 4),
                    child: Text(
                      categoryLabels[e.key] ?? e.key,
                      style: TextStyle(
                        fontSize: 13,
                        color: active ? e.value : const Color(0xFF888888),
                        letterSpacing: 0.4,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => showAstroGlossaryDialog(context, termKey),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.info_outline,
                      size: 16,
                      color: active ? e.value.withAlpha(220) : const Color(0xCCAAAAAA),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// 天頂・天底点タップ詳細 popup。
/// 画面下部に表示し、惑星固有のメッセージ + 座標 + タグを示す。
/// CCG: frame で見出し付加 (Transit/Progressed/Solar Arc は時間連動を明示)。
/// [isNadir] で天底版を表示 (astroNadirMessages 参照、マーカー装飾も切替)。
class AstroZenithPopup extends StatelessWidget {
  final String planetKey;        // 'sun', 'moon', ...
  final LatLng zenith;           // 表示用の座標 (lat=δ, lng=MC line)
  final AstroFrame frame;
  final bool isNadir;
  final VoidCallback onClose;

  /// 「この地点で相談する」CTA タップ時のハンドラ。
  /// 非 null のとき popup 内にボタンが表示される。caller (map_screen) が
  /// zenith 座標を preset として `_launchConsultation` を呼ぶ。
  final VoidCallback? onConsult;

  const AstroZenithPopup({
    super.key,
    required this.planetKey,
    required this.zenith,
    required this.onClose,
    this.frame = AstroFrame.natal,
    this.isNadir = false,
    this.onConsult,
  });

  @override
  Widget build(BuildContext context) {
    final meta = planetMeta[planetKey];
    final msg = (isNadir ? astroNadirMessages : astroZenithMessages)[planetKey];
    if (meta == null || msg == null) return const SizedBox.shrink();
    final frameStyle = astroFrameStyles[frame] ?? astroFrameStyles[AstroFrame.natal]!;
    final isNatal = frame == AstroFrame.natal;
    final frameLabel = isNatal
        ? null
        : (frame == AstroFrame.transit
            ? 'TRANSIT — 今この瞬間の天体位置'
            : frame == AstroFrame.progressed
                ? 'PROGRESSED — 2次進行 (1日=1年)'
                : 'SOLAR ARC — 太陽進行弧で全惑星シフト');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xEE0C0C1A),
        // 2026-04-30: 中央表示に対応するため全周角丸 (旧: 上端のみ)
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isNatal ? const Color(0x66C9A84C) : frameStyle.accent.withAlpha(140),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 18,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── frame ラベル (Natal以外) ──
            if (frameLabel != null) Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: frameStyle.accent, width: 0.8),
                  color: frameStyle.accent.withAlpha(28),
                ),
                child: Text(
                  frameLabel,
                  style: TextStyle(
                    fontSize: 13,
                    color: frameStyle.accent,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            // ── ヘッダ: 装飾マーカー再現 + タイトル + × ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                isNadir
                    ? AstroNadirMarker(
                        planetSym: meta.sym,
                        planetColor: meta.color,
                        frame: frame,
                      )
                    : AstroZenithMarker(
                        planetSym: meta.sym,
                        planetColor: meta.color,
                        frame: frame,
                      ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        msg.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: meta.color,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        msg.summary,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFC9A84C),
                          letterSpacing: 0.3,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onClose,
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Icon(Icons.close, size: 18, color: Color(0xFFAAAAAA)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // ── 詳述 ──
            Text(
              msg.detail,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFE8E0D0),
                height: 1.7,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 12),
            // ── タグ + 座標 ──
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...msg.tags.map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: meta.color.withAlpha(120), width: 0.8),
                    color: meta.color.withAlpha(20),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 13,
                      color: meta.color,
                      letterSpacing: 0.3,
                    ),
                  ),
                )),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0x33C9A84C), width: 0.8),
                  ),
                  child: Text(
                    '${zenith.latitude.toStringAsFixed(1)}°, ${zenith.longitude.toStringAsFixed(1)}°',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF888888),
                      fontFamily: 'monospace',
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
            // 「この地点で相談する」CTA (Phase 2026-05-16、B 経路)。
            // onConsult 非 null のときのみ表示。zenith 座標を preset として渡す。
            if (onConsult != null) ...[
              const SizedBox(height: 14),
              InkWell(
                onTap: onConsult,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 11, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0x33F6BD60),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0x88F6BD60)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome,
                          size: 16, color: Color(0xFFE9D29A)),
                      SizedBox(width: 8),
                      Text(
                        'この地点で相談する',
                        style: TextStyle(
                          color: Color(0xFFE9D29A),
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
          ],
        ),
      ),
    );
  }
}
