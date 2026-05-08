import 'package:flutter/material.dart';

import '../../utils/direction_energy.dart';
import '../../widgets/info_popup.dart';
import 'map_constants.dart';
import 'map_direction_popup.dart';
import 'map_widgets.dart';

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
    //   - 右側 DailyTransitBadge (右上 right:20, 幅 40) と重ならないよう
    //     右マージン 64 を予約 (2026-05-04 ユーザー指摘対応)
    //
    // 2026-05-08: アクセシビリティ配慮で score bar 内部のみ
    // clamp 1.3 倍 (= 全体 1.5 倍より控え目) を許容。寸法は 1.3 倍時の
    // テキストが収まるよう拡大調整。
    final screenW = MediaQuery.of(context).size.width;
    final leftLabelMax = screenW * 0.32;
    const dirLabelW = 48.0;
    const valueLabelW = 36.0;
    const innerHPad = 8.0;   // Container horizontal padding (片側)
    const sideMargin = 16.0;  // 親 Positioned の left:16 分
    const dailyBadgeReserved = 64.0;  // DailyTransitBadge 用右マージン
    // 残幅 = 画面幅 − サイドマージン − 左ラベル − Container padding × 2
    //         − 6 (左ラベルとバー列の間) − dirLabelW − 4 − valueLabelW − 4
    //         − dailyBadgeReserved (右上 Badge 用)
    final reserved = sideMargin + leftLabelMax + innerHPad * 2 + 6 + dirLabelW + 4 + valueLabelW + 4 + dailyBadgeReserved;
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
                      '${srcLabels[activeSrc] ?? '合計'} / ${categoryLabels[activeCategory] ?? '総合'}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFFC9A84C), letterSpacing: 0.5, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    // i ボタン: タップで「カテゴリと関連惑星ペア」popup を表示。
                    // 親 GestureDetector (onTap=カテゴリ次へ切替) の上にあるが、
                    // 内側が gesture arena で勝つため切替は発火しない。
                    // crossAxisAlignment.end によりアイコン右端 = ラベル右端 =
                    // 「総合」の「合」の文字の真下に配置される。
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => showCategoryInfoPopup(context),
                      child: const Padding(
                        padding: EdgeInsets.only(left: 6, top: 1),
                        child: Icon(Icons.info_outline,
                            size: 11, color: Color(0xFF888888)),
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
                        dir16JP[e.key] ?? e.key,
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
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onClose,
            onVerticalDragEnd: (details) {
              if ((details.primaryVelocity ?? 0) > 0) onClose();
            },
            onVerticalDragUpdate: (details) {
              if ((details.primaryDelta ?? 0) > 8) onClose();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 10, bottom: 6),
              alignment: Alignment.center,
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0x40FFFFFF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          _buildSrcTabs(),
          // 凡例 Row。フォント拡大時の RIGHT OVERFLOW 対策で横スクロール化
          // (2026-05-08)。center 配置 → 左寄せ + ContentPadding に変更。
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LegendDot(color: compColors['tSoft']!, label: 'Tソフト'),
                  const SizedBox(width: 8),
                  LegendDot(color: compColors['tHard']!, label: 'Tハード'),
                  const SizedBox(width: 8),
                  LegendDot(color: compColors['pSoft']!, label: 'Pソフト'),
                  const SizedBox(width: 8),
                  LegendDot(color: compColors['pHard']!, label: 'Pハード'),
                ],
              ),
            ),
          ),
          _buildCatTabs(),
          SizedBox(
            height: 185,
            child: RawScrollbar(
              thumbColor: const Color(0x40C9A84C),
              radius: const Radius.circular(2),
              thickness: 3,
              thumbVisibility: true,
              child: Builder(builder: (rowsContext) => ListView(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                children: _buildFortuneRows(rowsContext),
              )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSrcTabs() {
    const srcs = [('combined', '合計'), ('transit', 'トランジット'), ('progressed', 'プログレス')];
    // 2026-05-08: フォント拡大時の RIGHT OVERFLOW 対策で横スクロール化。
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x14FFFFFF))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: srcs.map((s) {
            final active = activeSrc == s.$1;
            return GestureDetector(
              onTap: () => onSrcChanged(s.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(
                    color: active ? const Color(0xFFC9A84C) : Colors.transparent, width: 2)),
                ),
                child: Text(s.$2, style: TextStyle(fontSize: 13,
                  color: active ? const Color(0xFFC9A84C) : const Color(0xFF666666))),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCatTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x0FFFFFFF))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categoryColors.entries.map((e) {
            final active = activeCategory == e.key;
            return GestureDetector(
              onTap: () => onCatChanged(e.key),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(
                    color: active ? const Color(0xFFC9A84C) : Colors.transparent, width: 2)),
                ),
                child: Text(categoryLabels[e.key] ?? e.key, style: TextStyle(fontSize: 13,
                  color: active ? const Color(0xFFC9A84C) : const Color(0xFF666666))),
              ),
            );
          }).toList(),
        ),
      ),
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
              dir16JP[dir] ?? dir,
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
  const entries = <(String, String, String, String)>[
    // (cat key, icon, pairs text, nuance)
    ('healing', '🌿', '月×海王星 / 月×金星 / 太陽×海王星',
        '休息・回復・直感が流れるテーマ'),
    ('money', '💰', '木星×金星 / 木星×太陽 / 金星×太陽',
        '繁栄・喜び・自己肯定のテーマ'),
    ('love', '💗', '金星×火星 / 金星×月 / 火星×月',
        '愛・情熱・親密さのテーマ'),
    ('work', '⚙', '土星×太陽 / 土星×火星 / 木星×太陽 / 木星×火星',
        '責任・行動・拡大のテーマ'),
    ('communication', '💬', '水星×太陽 / 水星×金星 / 水星×月',
        '伝達・対話・知性のテーマ'),
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
          const Text(
            'Map の使い方',
            style: TextStyle(
                color: Color(0xFFC9A84C), fontSize: 14, letterSpacing: 1),
          ),
          const SizedBox(height: 10),
          const Text(
            '【方角を読む】',
            style: TextStyle(
                color: Color(0xFFC9A84C),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5),
          ),
          const SizedBox(height: 4),
          const Text(
            '基準地点 (VIEWPOINT) を中心に、地表の 16 方位\n'
            '(北・北北東・北東・東北東・東…) ごとのエネルギーを\n'
            'スコア化して表示しています。\n'
            '「どの土地・方向に意識を向けるべきか」が判断できます。\n\n'
            'どの方向に進むべきかだけの表示ではありません。\n'
            'もちろん方角に向かい進む事も一つの方角に対する\n'
            '行動です。他には、意識を向ける事や、声をかける、\n'
            '大切なアイテムの置き場所を方角に合わせて家を出発する、\n'
            '話しかける時の方角を意識する、深呼吸をする方角、\n'
            'など、あなたが自由に決められます。\n'
            '決めた行動により、惑星たちのエネルギーが\n'
            'あなたに届くでしょう。\n'
            '惑星たちは常に大きな視点であなたを見守っています。\n\n'
            'スコアバーをタップするとカテゴリが切替わります\n'
            '(総合 → 癒し → 豊かさ → 恋愛 → 仕事 → 話す)。\n'
            '見たいカテゴリを選ぶと、そのエネルギーが\n'
            'どの方位に強く出ているかが分かります。',
            style: TextStyle(
                color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
          ),
          const SizedBox(height: 10),
          const Text(
            '【基準地点を登録する】',
            style: TextStyle(
                color: Color(0xFFC9A84C),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5),
          ),
          const SizedBox(height: 4),
          const Text(
            '基準地点は地図画面の左側にある 📍 (VIEWPOINT) ボタン\n'
            'から登録できます。\n'
            '登録したい場所を地図中央に表示してパネルを開き、\n'
            '「この地点を保存」をタップすると、その地点が\n'
            'VIEWPOINT として保存されます。\n\n'
            '保存した基準地点は、検索結果一覧の上部や\n'
            '右上 ⊙ アイコン (Daily Transit) のプルダウンから、\n'
            'いつでも切り替えて使えます。',
            style: TextStyle(
                color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
          ),
          const SizedBox(height: 10),
        ],
        const Text(
          '【場所を探す】',
          style: TextStyle(
              color: Color(0xFFC9A84C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        const Text(
          '検索ボタンから買い物・待ち合わせ・お店などを\n'
          '検索すると、その地点が今どの惑星から\n'
          'エネルギーを受けているかを確認できます。',
          style: TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
        ),
        const SizedBox(height: 10),
        const Text(
          '【時間を読む】',
          style: TextStyle(
              color: Color(0xFFC9A84C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        const Text(
          '右上の ⊙ アイコンから「行動する時間の指針」が\n'
          '分かります。\n'
          '※ 右上アイコンの画面は「天空方位」(惑星が空のどこに\n'
          '　 いつ来るか) を扱い、この Map の「地表方位」\n'
          '　 (どの土地に向かうか) とは別物です。\n\n'
          'スコアバー (地表方位の強さ) と右上アイコン\n'
          '(天空方位 × 時刻) を組み合わせると、\n'
          'あなたの望む未来に対する最適な\n'
          '「方角 × 時間」を Solara が算出します。',
          style: TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
        ),
        const SizedBox(height: 16),
        const Divider(color: Color(0x33C9A84C), height: 1),
        const SizedBox(height: 16),
        // ── Section 2: カテゴリと関連惑星 ──
        const Text(
          'カテゴリと関連惑星',
          style: TextStyle(
              color: Color(0xFFC9A84C), fontSize: 14, letterSpacing: 1),
        ),
        const SizedBox(height: 10),
        const Text(
          '各カテゴリは、関連する惑星ペアのアスペクトを抽出し、\n'
          'ペア重みをかけて方位ごとにスコア化しています。\n'
          '(ペア重みの仕組みは下に詳しく説明)',
          style: TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
        ),
        const SizedBox(height: 12),
        for (final e in entries) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(e.$2, style: const TextStyle(fontSize: 16)),
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
        const Text(
          '【ペア重みの仕組み】',
          style: TextStyle(
              color: Color(0xFFC9A84C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        const Text(
          'カテゴリ別スコアは、関連する惑星ペアのアスペクトを抽出し、\n'
          'ペアの「中心度」に応じた重みをかけて合算しています。\n\n'
          '・主役ペア (重み 2.0)\n'
          '　そのカテゴリの中心テーマを担う惑星ペア。\n'
          '　例: 恋愛 = 金星×火星 / 仕事 = 土星×太陽\n'
          '　→ アスペクト出現時は 2 倍の影響力で計上されます。\n\n'
          '・サブペア (重み 0.5)\n'
          '　片方の惑星だけがカテゴリに関わるアスペクト。\n'
          '　例: 恋愛で「金星×木星」(金星のみ love 担当)\n'
          '　→ 0.5 倍の控えめな影響力で計上されます。\n\n'
          '・ペア外 (重み 0)\n'
          '　両方ともカテゴリに関係ない惑星のアスペクト。\n'
          '　→ そのカテゴリのスコアには反映されません。\n\n'
          'この「重み付け」により、カテゴリの「中心テーマ」を\n'
          '反映した精度の高いスコアが得られます。\n'
          'ペア重みなしの単純合算では、カテゴリの個性が\n'
          'ぼやけてしまうため、加重計算で精緻化しています。',
          style: TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
        ),
        const SizedBox(height: 14),
        const Text(
          '【総合との関係】',
          style: TextStyle(
              color: Color(0xFFC9A84C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        const Text(
          '上部スコアバーで「総合」を選んでいる時の数字は、\n'
          '全惑星・全アスペクトをそのまま合算した値です。\n'
          'カテゴリ重みは入りません (= ペア重みなし)。\n\n'
          '一方、カテゴリ別 (癒し / 豊かさ / 恋愛 / 仕事 / 話す) は\n'
          '上記のペア重みがかかります。\n'
          'さらに 1 つのアスペクトが複数カテゴリに重複計上される\n'
          'こともあります (例: 金星×木星 → 恋愛にも豊かさにも入る)。\n\n'
          'このため「カテゴリ別 5 つの単純合算 ≠ 総合」となります。\n'
          '両者は別の角度からエネルギーを見るための数値で、\n'
          'どちらが正しいということはありません。\n'
          '・カテゴリ別 = カテゴリの「集中度」を見る\n'
          '・総合 = 全体の「総量」を見る',
          style: TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
        ),
      ],
    ),
  );
}
