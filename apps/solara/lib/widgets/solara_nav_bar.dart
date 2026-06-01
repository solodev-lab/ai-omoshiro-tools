import 'package:flutter/material.dart';
import 'nav_icons.dart';

/// Custom bottom navigation bar matching HTML shared/styles.css exactly.
///
/// HTML spec:
/// - height: 80px (--nav-height)
/// - background: linear-gradient(180deg, rgba(6,10,18,0.80), rgba(4,6,14,0.95))
/// - backdrop-filter: blur(28px)
/// - border-top: 1px solid rgba(249,217,118,0.06)
/// - box-shadow: 0 -4px 30px rgba(0,0,0,0.4), inset 0 1px 0 rgba(255,255,255,0.04)
/// - padding: 10px 4px 0
///
/// Nav item:
/// - icon: 24x24, inactive rgba(255,255,255,0.35), active #F9D976 with glow
/// - label: 9px, uppercase, letter-spacing 0.5px
/// - active glow dot: 4x4px #F9D976 with box-shadow
///
/// 2026-04-29: Android systemNav (3ボタン △〇□ / ジェスチャーバー) 対応。
/// `MediaQuery.viewPaddingOf(context).bottom` 分だけ高さを動的に拡張し、
/// アイコンは上 80px に固定して背景 gradient のみ systemNav 領域まで延ばす。
/// これによりジェスチャーナビでも 3ボタンナビでも見た目が綺麗に揃う。
class SolaraNavBar extends StatelessWidget {
  /// 視覚上の固定高さ (アイコン行が収まる本来の高さ)。
  /// systemNav 領域はこれに加算される。
  static const double baseHeight = 80;

  final int currentIndex;
  final ValueChanged<int> onTap;

  /// true のとき Galaxy(index 3) アイコン右上に「保留中の月イベント」バッジを出す。
  /// 表示判定は main.dart (MoonEventStatus.pendingToday) 側で行い、ここは描画のみ。
  final bool showGalaxyBadge;

  const SolaraNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.showGalaxyBadge = false,
  });

  /// systemNav 込みの NavBar 全体の高さ。
  /// Map画面など bottom 配置で「NavBar の上」を計算するときに使う。
  static double totalHeight(BuildContext context) =>
      baseHeight + systemNavInset(context);

  /// 3ボタンナビ (△〇□) 検出用の閾値。
  /// ジェスチャーナビ (Pixel 8 等) は 16〜24px、3ボタンナビは ~48px。
  /// 閾値以下は「ジェスチャーバーが NavBar 下端の空白に収まる」とみなして拡張しない。
  static const double _threeButtonNavThreshold = 30;

  /// 3ボタンナビ時のみ加算する追加高さ。ジェスチャーナビ時は 0。
  /// オーナー指定 (2026-04-29): 3ボタン時も systemNav 高 - 12px で詰める
  /// (NavBar が大き過ぎないよう僅かに短縮)。
  static const double _threeButtonShrink = 12;
  static double systemNavInset(BuildContext context) {
    final v = MediaQuery.viewPaddingOf(context).bottom;
    if (v <= _threeButtonNavThreshold) return 0;
    final adjusted = v - _threeButtonShrink;
    return adjusted < 0 ? 0 : adjusted;
  }

  static const _gold = Color(0xFFF9D976);
  static const _inactiveColor = Color(0x59FFFFFF); // rgba(255,255,255,0.35)

  static const _labels = ['Map', 'Horo', 'Tarot', 'Galaxy', 'Sanctuary'];

  /// スライド光点のサイズ (HTML active glow dot = 4×4px)。
  static const double _dotSize = 4;

  /// 光点が旧位置→新位置へ移動する時間。easeOutCubic でスッと減速して収まる。
  static const Duration _slideDuration = Duration(milliseconds: 280);

  /// アイコン/ラベルの色・glow が グレー⇄ゴールド を補間する時間 (光点とほぼ同尺)。
  static const Duration _fadeDuration = Duration(milliseconds: 250);

  @override
  Widget build(BuildContext context) {
    final inset = systemNavInset(context);
    // 2026-05-03: BackdropFilter 撤去 (Adreno saveLayer leak の Critical)。
    // gradient は alpha 高めに変更し、後ろの地図がうっすら透ける程度を維持。
    return Container(
      height: baseHeight + inset,
      padding: EdgeInsets.only(top: 10, left: 4, right: 4, bottom: inset),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xF2060A12), Color(0xFF04060E)],
        ),
        border: const Border(top: BorderSide(color: Color(0x0FF9D976), width: 1)),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 30, offset: Offset(0, -4)),
        ],
      ),
      // Expanded で 5 等分割。固定 width:64 の SizedBox を使うと
      // 狭い端末/表示サイズ大の時に 5×64=320 が画面幅(padding控除後)を
      // 超えて RIGHT OVERFLOWED が発生していた。
      //
      // 2026-06-01: 選択中ゴールド光点を「各項目に表示/非表示」する方式から、
      // 「1個だけを横スライドさせる」方式に変更 (UX 改善)。
      // Align(topCenter) で Stack を項目 Column の高さ (~54px) に縮め、
      // AnimatedPositioned が光点の left だけをタブ切替時に補間する。
      // AnimatedPositioned / TweenAnimationBuilder は one-shot
      // (目標到達で内部 ticker が停止) なので、静止時の CPU/電池消費はゼロ。
      // .repeat() / Timer は一切使わない (Galaxy 等の常時 tick とは別物)。
      child: Align(
        alignment: Alignment.topCenter,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 5 等分割なのでセル幅 = 全幅 / 5。光点はセル中央 (= アイコン中央)。
            final cellWidth = constraints.maxWidth / 5;
            final dotLeft = cellWidth * currentIndex + (cellWidth - _dotSize) / 2;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(
                    5,
                    (i) => Expanded(child: _buildItem(i)),
                  ),
                ),
                // スライドするゴールド光点 (全項目で共有する 1 個)。
                // bottom:0 = 項目 Column 最下段の placeholder (4px) に重なる。
                AnimatedPositioned(
                  duration: _slideDuration,
                  curve: Curves.easeOutCubic,
                  left: dotLeft,
                  bottom: 0,
                  width: _dotSize,
                  height: _dotSize,
                  child: _glowDot(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// スライドするゴールド光点本体 (旧 active glow dot と同一スタイル)。
  /// サイズは AnimatedPositioned 側の width/height (4×4) で与える。
  Widget _glowDot() => Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _gold,
          boxShadow: [
            BoxShadow(color: _gold.withAlpha(128), blurRadius: 8, spreadRadius: 2),
            BoxShadow(color: _gold.withAlpha(38), blurRadius: 20, spreadRadius: 4),
          ],
        ),
      );

  /// 保留中の月イベントを示す Galaxy アイコン右上のゴールド点。
  /// NavBar 背景色で 1px 縁取りしてアイコンから視覚的に分離する。
  Widget _moonBadge() => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _gold,
          border: const Border.fromBorderSide(
            BorderSide(color: Color(0xFF04060E), width: 1),
          ),
          boxShadow: [
            BoxShadow(color: _gold.withAlpha(140), blurRadius: 5, spreadRadius: 1),
          ],
        ),
      );

  Widget _buildItem(int index) {
    final active = index == currentIndex;

    // SizedBox(width:64) を撤去。親 Row が Expanded で幅を与えるので
    // タップ領域はそのセル幅いっぱい (HitTestBehavior.opaque で透明部もタップ可)。
    //
    // TweenAnimationBuilder で active(0↔1) を補間。色・glow をその t で lerp する。
    // これも one-shot — タブ切替時のみ ~250ms tick して停止し、静止時は何も動かない。
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: active ? 1 : 0),
        duration: _fadeDuration,
        curve: Curves.easeOut,
        builder: (context, t, _) {
          // 色: rgba(255,255,255,0.35) → #F9D976 を t で lerp (t=0 で旧 inactive と完全一致)。
          final color = Color.lerp(_inactiveColor, _gold, t)!;
          // Icon with glow — drop-shadow の濃度を t で補間 (t=1 で旧 active と完全一致)。
          Widget icon = Container(
            decoration: BoxDecoration(
              boxShadow: t <= 0
                  ? null
                  : [
                      BoxShadow(
                          color: _gold.withAlpha((180 * t).round()),
                          blurRadius: 8),
                      BoxShadow(
                          color: _gold.withAlpha((77 * t).round()),
                          blurRadius: 16),
                    ],
            ),
            child: _iconForIndex(index, color),
          );
          // 保留中の月イベントがあれば Galaxy(index 3) アイコン右上にゴールド点。
          // Galaxy タブ滞在中 (active) は overlay/体験が目の前にあるので出さない。
          // 静的描画 (アニメ・tick なし) — 静止時 CPU/電池消費ゼロ。
          if (index == 3 && showGalaxyBadge && !active) {
            icon = Stack(
              clipBehavior: Clip.none,
              children: [
                icon,
                Positioned(top: -2, right: -2, child: _moonBadge()),
              ],
            );
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 6),
              icon,
              const SizedBox(height: 4),
              // Label: 9px, uppercase, letter-spacing 0.5
              // 2026-05-08: textScaler.noScaling 適用。global の 1.5x 拡大が
              // 9px label に乗ると Container 高 80px 内 (実 content 70px) を
              // 超えて BOTTOM OVERFLOWED が発生 (特に Noto Sans JP で行高が
              // 大きい)。NavBar label は固定 9px UI 要素として扱う。
              Text(
                _labels[index],
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  fontSize: 9, color: color, letterSpacing: 0.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 4),
              // 光点の予約スペース。実体は Stack 上の AnimatedPositioned が描画する。
              // ここで _dotSize(4px) を必ず確保し、Column 高さを旧実装と完全に同一に保つ
              // (active/inactive で高さが変わらない → 光点 Y がブレない)。
              const SizedBox(height: _dotSize),
            ],
          );
        },
      ),
    );
  }

  Widget _iconForIndex(int index, Color color) {
    switch (index) {
      case 0: return SolaraNavIcons.map(size: 24, color: color);
      case 1: return SolaraNavIcons.horo(size: 24, color: color);
      case 2: return SolaraNavIcons.tarot(size: 24, color: color);
      case 3: return SolaraNavIcons.galaxy(size: 24, color: color);
      case 4: return SolaraNavIcons.sanctuary(size: 24, color: color);
      default: return const SizedBox();
    }
  }
}
