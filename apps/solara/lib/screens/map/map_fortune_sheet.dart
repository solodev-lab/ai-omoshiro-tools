import 'package:flutter/material.dart';

import '../../i18n/strings.g.dart';
import '../../utils/direction_energy.dart';
import '../../utils/solara_i18n.dart';
import '../../widgets/info_popup.dart';
import 'map_constants.dart';
import 'map_direction_popup.dart';

/// pct() from HTML: 0-5 → 0-83.3%, 5-10 → 83.3-100%
double pctValue(double v) {
  if (v <= 5) return (v / 5) * (100 * 5 / 6);
  return (5 / 6) * 100 + (1 / 6) * 100 * ((v - 5) / 5).clamp(0, 1);
}

/// HTML: .ff-label { top:52px; left:16px; inline-flex row: ff-tag + ff-bars }
class FortuneFilterLabel extends StatelessWidget {
  final Map<String, double> sectorScores;
  final String activeSrc;
  final String activeCategory;
  /// タップでカテゴリ次へ切替 (2026-04-30 オーナー要望)。
  /// 渡されない場合はタップ無効。
  final VoidCallback? onTap;

  const FortuneFilterLabel({
    super.key,
    required this.sectorScores,
    required this.activeSrc,
    required this.activeCategory,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = sectorScores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    if (sorted.isEmpty) return const SizedBox();

    final top2 = sorted.where((e) => e.value > 0.01).take(2).toList();
    final maxScore = top2.isNotEmpty ? top2.first.value : 1.0;
    final catColor = categoryColors[activeCategory] ?? const Color(0xFFC9A84C);

    // 端末幅に応じてレイアウト寸法を可変化:
    //   - 左ラベル (合計/総合) を画面幅の 32% で頭打ち + ellipsis
    //   - 方角ラベル幅 48 → fontSize 11 × 内部 1.3 倍 = 14.3 で "東南東" を収める
    //   - 値ラベル幅 36 → fontSize 11 monospace × 1.3 で "15.7" を収める
    //   - バー幅は MediaQuery で残幅から逆算
    //
    // 2026-05-09: 旧 DailyTransitBadge 撤去でスコアバー右マージン 64px を解放。
    // 2026-05-08: アクセシビリティ配慮で score bar 内部のみ
    // clamp 1.3 倍 (= 全体 1.5 倍より控え目) を許容。寸法は 1.3 倍時の
    // テキストが収まるよう拡大調整。
    final screenW = MediaQuery.of(context).size.width;
    final leftLabelMax = screenW * 0.32;
    const dirLabelW = 48.0;
    const valueLabelW = 36.0;
    const innerHPad = 8.0;   // Container horizontal padding (片側)
    const sideMargin = 16.0;  // 親 Positioned の left:16 分
    // 残幅 = 画面幅 − サイドマージン − 左ラベル − Container padding × 2
    //         − 6 (左ラベルとバー列の間) − dirLabelW − 4 − valueLabelW − 4
    final reserved = sideMargin + leftLabelMax + innerHPad * 2 + 6 + dirLabelW + 4 + valueLabelW + 4;
    final barW = (screenW - reserved).clamp(36.0, 90.0);

    // ClipRRect で境界半径を維持しつつ、sub-pixel オーバーフローを視覚的に吸収。
    // 2026-05-08: スコアバー内のみ独自に clamp 1.3 倍を適用。
    //   - 全体 (main.dart) は 1.5 倍までクランプ
    //   - score bar 内部はさらに 1.3 倍まで絞ることで、コンパクト UI
    //     としての見た目を維持しつつ、ある程度のアクセシビリティ拡大も許容
    //   - 1.3 倍時にテキストが収まるよう dirLabelW / valueLabelW を計算済み
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: MediaQuery.withClampedTextScaling(
      minScaleFactor: 1.0,
      maxScaleFactor: 1.3,
      child: ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: innerHPad, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xB30A0A14),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0x4DC9A84C)),
        ),
        // 2026-05-08: 「合計 / 総合」を縦中央寄せ、i ボタンを最下部 +
        // ラベル右端 (= 「総合」の「合」の下) に配置するため IntrinsicHeight +
        // crossAxisStretch + Spacer 構成に変更。
        // - IntrinsicHeight で Row 内の左右 Column が同じ高さを共有
        // - 左 Column: [Spacer, Text, Spacer, Icon] で text を中央寄り、
        //   icon を最下部に。crossAxisAlignment.end でラベル右端 (合) の下に。
        // - 右 Column: mainAxisAlignment.center で 2 本のバーも縦中央寄せ
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: leftLabelMax),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // 上に唯一の Spacer を置き、text + icon を下にまとめる。
                    // 中間 Spacer は削除 (text と icon が密着するように)。
                    // これにより text が「下半分の上端」付近に来て、視覚的に
                    // バーの縦中央寄り (1.3x スケール時はほぼ中央) になる。
                    const Spacer(),
                    Text(
                      t.mapFortune.header(
                          src: srcLabels[activeSrc] ?? srcLabels['combined']!,
                          cat: categoryLabels[activeCategory] ??
                              categoryLabel('overall')),
                      style: const TextStyle(fontSize: 11, color: Color(0xFFC9A84C), letterSpacing: 0.5, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    // ? ボタン: タップで「カテゴリと関連惑星ペア」popup を表示。
                    // 親 GestureDetector (onTap=カテゴリ次へ切替) の上にあるが、
                    // 内側が gesture arena で勝つため切替は発火しない。
                    // crossAxisAlignment.end によりアイコン右端 = ラベル右端 =
                    // 「総合」の「合」の文字の真下に配置される。
                    // 2026-05-10: info_outline (ⓘ) → help_outline (❓) に変更。
                    // 「使い方」系の ? マークに統一。size 11 → 13 で視認性向上。
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => showCategoryInfoPopup(context),
                      child: const Padding(
                        padding: EdgeInsets.only(left: 6, top: 1),
                        child: Icon(Icons.help_outline,
                            size: 13, color: Color(0xFF888888)),
                      ),
                    ),
                  ],
                ),
              ),
              if (top2.isNotEmpty) ...[
                const SizedBox(width: 6),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  // 左の text 中央寄せに合わせて右の 2 バーも縦中央寄せ
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: top2.map((e) {
                  final pct = (e.value / maxScore).clamp(0.0, 1.0);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      SizedBox(width: dirLabelW, child: Text(
                        dirName(e.key),
                        style: const TextStyle(fontSize: 11, color: Color(0xFF888888), fontWeight: FontWeight.w500),
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )),
                      const SizedBox(width: 4),
                      SizedBox(
                        // バー高さ 5px — fontSize 11 化に合わせて視覚的バランス再調整
                        width: barW, height: 5,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0x15FFFFFF),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: pct,
                            child: Container(
                              decoration: BoxDecoration(
                                color: catColor,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(width: valueLabelW, child: Text(
                        e.value.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFFF6BD60), fontWeight: FontWeight.w600),
                        textAlign: TextAlign.right,
                      )),
                    ]),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),  // IntrinsicHeight 終端
      ),  // Container 終端
    ),  // ClipRRect 終端
    ),  // MediaQuery.withClampedTextScaling 終端
    );
  }
}

/// Fortune Sheet — HTML: .fs { bottom:80px; border-radius:16px 16px 0 0; }
class FortuneSheet extends StatelessWidget {
  final String activeSrc;
  final String activeCategory;
  final Map<String, Map<String, double>> sectorComps;
  /// E4: 2エネルギー詳細ポップアップ用。指定時、各方角行をタップで詳細を表示。
  final Map<String, DirectionEnergy>? sectorEnergies;
  /// E4: アスペクト attribution 用（行タップ時の詳細に表示）。
  final Map<String, List<AspectContribution>>? sectorContributors;
  final ValueChanged<String> onSrcChanged;
  final ValueChanged<String> onCatChanged;
  final VoidCallback onClose;

  const FortuneSheet({
    super.key,
    required this.activeSrc,
    required this.activeCategory,
    required this.sectorComps,
    this.sectorEnergies,
    this.sectorContributors,
    required this.onSrcChanged,
    required this.onCatChanged,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xF20A0A19),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: Color(0x40C9A84C))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 上部: src タブ (合計/トランジット/プログレス) の右端に × を配置。
          // 旧ドラッグバーの最上部空白 (~20px) を廃止し、その分シートを縮めて
          // 地図を多く見せる (中の表示内容量は不変)。
          Row(children: [
            Expanded(child: _buildSrcTabs()),
            GestureDetector(
              onTap: onClose,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.only(left: 4, right: 10, top: 8, bottom: 8),
                child: Icon(Icons.close, size: 22, color: Color(0xFFAAAAAA)),
              ),
            ),
          ]),
          // 凡例: 4 エネルギーの色見本。モダン化で各項目を小さなチップに。
          // 横スクロールでフォント拡大時の RIGHT OVERFLOW を回避 (2026-05-08)。
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _legendChip(compColors['tSoft']!, t.mapFortune.legendTSoft),
                  const SizedBox(width: 6),
                  _legendChip(compColors['tHard']!, t.mapFortune.legendTHard),
                  const SizedBox(width: 6),
                  _legendChip(compColors['pSoft']!, t.mapFortune.legendPSoft),
                  const SizedBox(width: 6),
                  _legendChip(compColors['pHard']!, t.mapFortune.legendPHard),
                ],
              ),
            ),
          ),
          _buildCatTabs(),
          SizedBox(
            height: 185,
            child: _FortuneRowsList(buildRows: _buildFortuneRows),
          ),
        ],
      ),
    );
  }

  Widget _buildSrcTabs() {
    final srcs = [
      ('combined', t.mapFortune.srcFull.combined),
      ('transit', t.mapFortune.srcFull.transit),
      ('progressed', t.mapFortune.srcFull.progressed),
    ];
    // モダン化: 下線タブ → 角丸ピル。アクティブは金色の淡い塗り + 枠。
    // 横スクロールでフォント拡大時の RIGHT OVERFLOW を回避 (2026-05-08)。
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: srcs.map((s) {
          final active = activeSrc == s.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => onSrcChanged(s.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: active ? const Color(0x2EC9A84C) : const Color(0x12FFFFFF),
                  borderRadius: BorderRadius.circular(18),
                  border: active
                      ? Border.all(color: const Color(0x66C9A84C))
                      : null,
                ),
                child: Text(s.$2, style: TextStyle(fontSize: 12.5,
                  color: active ? const Color(0xFFEAD9A8) : const Color(0xFF888888),
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCatTabs() {
    // モダン化: 下線タブ → 角丸ピル。アクティブはカテゴリ色の淡い塗り + 枠 + 同色文字。
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
      child: Row(
        children: categoryColors.entries.map((e) {
          final active = activeCategory == e.key;
          final c = e.value;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => onCatChanged(e.key),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: active
                      ? c.withValues(alpha: 0.20)
                      : const Color(0x12FFFFFF),
                  borderRadius: BorderRadius.circular(16),
                  border: active
                      ? Border.all(color: c.withValues(alpha: 0.55))
                      : null,
                ),
                child: Text(categoryLabels[e.key] ?? e.key, style: TextStyle(fontSize: 12.5,
                  color: active ? c : const Color(0xFF888888),
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 凡例チップ: 小さな角丸ドット + ラベルを淡い角丸背景でまとめる (モダン)。
  Widget _legendChip(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0x10FFFFFF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(fontSize: 11.5, color: Color(0xFFAAAAAA))),
      ]),
    );
  }

  List<Widget> _buildFortuneRows(BuildContext rowsContext) {
    final ck = activeSrc == 'transit' ? ['tSoft', 'tHard']
             : activeSrc == 'progressed' ? ['pSoft', 'pHard']
             : compKeys;

    final dt = <String, double>{};
    for (final d in dir16) {
      final c = sectorComps[d] ?? {};
      double t = 0;
      for (final k in ck) { t += (c[k] ?? 0); }
      dt[d] = t;
    }

    final sorted = dir16.toList()..sort((a, b) => (dt[b] ?? 0).compareTo(dt[a] ?? 0));
    final visible = sorted.where((d) => (dt[d] ?? 0) > 0.01).toList();

    return List.generate(visible.length, (i) {
      final dir = visible[i];
      final total = dt[dir]!;
      final pct = (pctValue(total) / 100).clamp(0.0, 1.0);
      final comp = sectorComps[dir] ?? {};
      final isLast = i == visible.length - 1;

      final segs = <Widget>[];
      for (final k in ck) {
        final v = comp[k] ?? 0;
        if (v < 0.001) continue;
        segs.add(Expanded(
          flex: (v * 1000).round(),
          child: Container(color: compColors[k]),
        ));
      }

      // E4: 2エネルギー詳細を表示できる場合は行をタップ可能にする。
      final canShowDetail = sectorEnergies != null && sectorEnergies![dir] != null;
      final rowContent = Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
        decoration: BoxDecoration(
          border: isLast ? null : const Border(bottom: BorderSide(color: Color(0x0AFFFFFF))),
        ),
        child: Row(children: [
          // 方角ラベル: '北北東' '東南東' などの 3 文字日本語が 1 行で収まるよう
          // 幅 60px (= 13 × 3 × 1.5 倍 = 58.5px + 余白)。
          // 2026-05-08: noTextScaling 撤去。端末フォント拡大 (clamp 1.5x) に
          // 追従させても Expanded のバー領域が十分広い (~178px) ので影響軽微。
          SizedBox(
            width: 60,
            child: Text(
              dirName(dir),
              maxLines: 1,
              softWrap: false,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFB49774),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 14, margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0x0AFFFFFF),
                borderRadius: BorderRadius.circular(7),
              ),
              child: LayoutBuilder(builder: (ctx, constraints) {
                final barW = constraints.maxWidth;
                return Stack(children: [
                  for (int t = 1; t <= 5; t++)
                    Positioned(
                      left: barW * t / 6, top: 0, bottom: 0,
                      child: Container(width: 1, color: const Color(0x21FFFFFF)),
                    ),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: pct,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Row(children: segs.isNotEmpty ? segs : [Expanded(child: Container())]),
                    ),
                  ),
                ]);
              }),
            ),
          ),
          SizedBox(width: 48, child: Text(total.toStringAsFixed(1),
            style: const TextStyle(fontSize: 13, fontFamily: 'monospace', color: Color(0xFFF6BD60)),
            textAlign: TextAlign.right)),
          if (canShowDetail)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.chevron_right, size: 14, color: Color(0x88888888)),
            ),
        ]),
      );

      if (!canShowDetail) return rowContent;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => showDirectionEnergyPopup(
          rowsContext,
          direction: dir,
          energy: sectorEnergies![dir]!,
          contributors: sectorContributors?[dir] ?? const [],
          categoryLabel: categoryLabels[activeCategory],
        ),
        child: rowContent,
      );
    });
  }
}

/// Map の使い方 + カテゴリと関連惑星ペアの説明 popup。
/// スコアバー左ラベル下の i ボタンから開く。
///
/// 構成 (フル):
///   1. 「Map の使い方」 — 方角を読む / 基準地点登録 / 場所検索 / 時間連動
///   2. 「カテゴリと関連惑星」 — 5 カテゴリそれぞれの惑星ペア定義
///      + ペア重みの仕組み詳細
///   3. 「総合との関係」 — カテゴリ別合算 ≠ 総合 の理由
///
/// [includeMapUsageTop] = false (検索詳細 popup から呼ばれる場合) は、
/// 「方角を読む」「基準地点を登録する」セクションを省略し、「場所を探す」
/// から開始する。検索詳細では既に Map 上で操作中なのでスコアバーや基準
/// 地点登録の説明は冗長なため。
void showCategoryInfoPopup(
  BuildContext context, {
  bool includeMapUsageTop = true,
}) {
  // 各カテゴリのアイコン文字 (絵文字)、関連惑星ペア (実装と一致)、
  // ニュアンス説明をデータ駆動で並べる。
  // ペア定義は map_astro.dart の _fortunePairs と一致させる:
  //   healing: moon×neptune / moon×venus / sun×neptune
  //   money:   jupiter×venus / jupiter×sun / venus×sun
  //   love:    venus×mars / venus×moon / mars×moon
  //   work:    saturn×sun / saturn×mars / jupiter×sun / jupiter×mars
  //   communication: mercury×sun / mercury×venus / mercury×moon
    // 惑星ペア表記はロケール別惑星名 (planetName) で組み立てる (× / は言語非依存)。
    String pair(String a, String b) => '${planetName(a)}×${planetName(b)}';
  final entries = <(String, String, String, String)>[
    // (cat key, icon, pairs text, nuance)
    ('healing', '🌿',
        '${pair('moon', 'neptune')} / ${pair('moon', 'venus')} / ${pair('sun', 'neptune')}',
        t.mapFortune.catMeta.healing),
    ('money', '💰',
        '${pair('jupiter', 'venus')} / ${pair('jupiter', 'sun')} / ${pair('venus', 'sun')}',
        t.mapFortune.catMeta.money),
    ('love', '💗',
        '${pair('venus', 'mars')} / ${pair('venus', 'moon')} / ${pair('mars', 'moon')}',
        t.mapFortune.catMeta.love),
    ('work', '⚙',
        '${pair('saturn', 'sun')} / ${pair('saturn', 'mars')} / ${pair('jupiter', 'sun')} / ${pair('jupiter', 'mars')}',
        t.mapFortune.catMeta.work),
    ('communication', '💬',
        '${pair('mercury', 'sun')} / ${pair('mercury', 'venus')} / ${pair('mercury', 'moon')}',
        t.mapFortune.catMeta.communication),
  ];

  showInfoPopup(
    context: context,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section 1: Map の使い方 (機能概観) ──
        // includeMapUsageTop=false の場合 (検索詳細から呼ばれた時) は
        // 「方角を読む」「基準地点を登録する」を省略し、「場所を探す」から開始。
        if (includeMapUsageTop) ...[
          Text(
            t.mapFortune.usage.title,
            style: const TextStyle(
                color: Color(0xFFC9A84C), fontSize: 14, letterSpacing: 1),
          ),
          const SizedBox(height: 10),
          Text(
            t.mapFortune.usage.dirTitle,
            style: const TextStyle(
                color: Color(0xFFC9A84C),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5),
          ),
          const SizedBox(height: 4),
          Text(
            t.mapFortune.usage.dirBody,
            style: const TextStyle(
                color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
          ),
          const SizedBox(height: 10),
          Text(
            t.mapFortune.usage.regTitle,
            style: const TextStyle(
                color: Color(0xFFC9A84C),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5),
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              style: const TextStyle(
                  color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
              children: [
                TextSpan(text: t.mapFortune.usage.regPre),
                const WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Icon(Icons.location_on_outlined,
                      size: 14, color: Color(0xFFC9A84C)),
                ),
                TextSpan(text: t.mapFortune.usage.regPost),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        Text(
          t.mapFortune.usage.findTitle,
          style: const TextStyle(
              color: Color(0xFFC9A84C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          t.mapFortune.usage.findBody,
          style: const TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
        ),
        const SizedBox(height: 10),
        Text(
          t.mapFortune.usage.timeTitle,
          style: const TextStyle(
              color: Color(0xFFC9A84C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          t.mapFortune.usage.timeBody,
          style: const TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
        ),
        const SizedBox(height: 16),
        const Divider(color: Color(0x33C9A84C), height: 1),
        const SizedBox(height: 16),
        // ── Section 2: カテゴリと関連惑星 ──
        Text(
          t.mapFortune.catPlanets.title,
          style: const TextStyle(
              color: Color(0xFFC9A84C), fontSize: 14, letterSpacing: 1),
        ),
        const SizedBox(height: 10),
        Text(
          t.mapFortune.catPlanets.intro,
          style: const TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
        ),
        const SizedBox(height: 12),
        for (final e in entries) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Text(e.$2,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryLabels[e.$1] ?? e.$1,
                      style: TextStyle(
                          color: categoryColors[e.$1] ??
                              const Color(0xFFE8E0D0),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      e.$3,
                      style: const TextStyle(
                          color: Color(0xFFB8B0A0),
                          fontSize: 12,
                          height: 1.5),
                    ),
                    Text(
                      e.$4,
                      style: const TextStyle(
                          color: Color(0xFF888888),
                          fontSize: 12,
                          height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 4),
        // ── ペア重みの詳細解説 (2026-05-08 ボリューム増) ──
        Text(
          t.mapFortune.catPlanets.weightTitle,
          style: const TextStyle(
              color: Color(0xFFC9A84C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          t.mapFortune.catPlanets.weightBody,
          style: const TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
        ),
        const SizedBox(height: 14),
        Text(
          t.mapFortune.catPlanets.overallTitle,
          style: const TextStyle(
              color: Color(0xFFC9A84C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          t.mapFortune.catPlanets.overallBody,
          style: const TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
        ),
      ],
    ),
  );
}

/// `RawScrollbar` と `ListView` で同じ `ScrollController` を共有する。
/// PrimaryScrollController を複数 ScrollView が共有して
/// `thumbVisibility: true` が assert に引っかかる問題の対策 (2026-05-12)。
class _FortuneRowsList extends StatefulWidget {
  final List<Widget> Function(BuildContext) buildRows;
  const _FortuneRowsList({required this.buildRows});

  @override
  State<_FortuneRowsList> createState() => _FortuneRowsListState();
}

class _FortuneRowsListState extends State<_FortuneRowsList> {
  final ScrollController _ctrl = ScrollController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawScrollbar(
      controller: _ctrl,
      thumbColor: const Color(0x40C9A84C),
      radius: const Radius.circular(2),
      thickness: 3,
      thumbVisibility: true,
      child: ListView(
        controller: _ctrl,
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        children: widget.buildRows(context),
      ),
    );
  }
}
