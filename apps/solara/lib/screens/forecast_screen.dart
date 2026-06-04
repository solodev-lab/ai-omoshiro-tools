import 'package:flutter/material.dart';
import '../i18n/strings.g.dart' hide AppLocale;
import '../utils/forecast_cache.dart';
import '../utils/pro_status.dart';
import '../utils/solara_i18n.dart' show isEnLocale;
import '../utils/solara_storage.dart';
import '../widgets/info_popup.dart';
import '../widgets/no_profile_guide.dart';
import '../widgets/pro_unlock_dialog.dart';
import 'forecast/forecast_life_periods.dart';
import 'forecast/forecast_section_header.dart';
import 'forecast/forecast_top5.dart';
import 'map/map_constants.dart';

/// Forecast 画面 — 1年予測（ヒートマップ + 選択日詳細 + 強運Top5）
/// Map画面から BottomSheet フルスクリーンで開く。
/// 出生情報のみで決まり地点に依存しないので基準地は持たない。
class ForecastScreen extends StatefulWidget {
  /// プロフィール未設定時の案内から Sanctuary タブへ遷移させるコールバック。
  final VoidCallback? onNavigateToSanctuary;

  // Map ジャンプ機能は廃止 (2026-05-14)。
  // 理由: FORECAST と Map は別計算 (時刻・場所依存の有無) で数字が一致しない。
  // 「Map で見る」リンクがあると「同じ数字のはず」という誤期待が生まれるため、
  // 画面間の暗黙的な接続を切る。詳細は ❓ popup の「Map との関係」を参照。

  const ForecastScreen({
    super.key,
    this.onNavigateToSanctuary,
  });

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  ForecastCache? _cache;
  bool _loading = true;
  String? _errorMsg;
  bool _noProfile = false;
  ForecastDay? _selected;

  /// 色モード: 'relative' (年内min-max正規化) | 'absolute' (固定閾値) | 'category' (topFortune色)
  String _colorMode = 'relative';

  /// 高スコア側の色: 'green' (信号機: 高=緑) | 'red' (赤=高)
  String _highColor = 'green';

  /// Top5 の並べ替え基準: 'overall' | 'love' | 'money' | 'healing' | 'work' | 'communication'
  String _top5Mode = 'overall';

  /// 年オフセット（0=今日から1年、1=翌年、2=翌々年...4=5年目）— 実験用。
  /// 切替時のみ Worker を1回呼び、他年は lazy。一括フェッチはしない。
  int _yearOffset = 0;

  /// カテゴリ色モード時の表示ランク: 1 = その日の1位カテゴリ、2 = 2位カテゴリ
  int _categoryRank = 1;

  /// 永続保存された運勢サイクル（プロフィール × yearOffset 単位）。
  /// 強制リフレッシュ時のみ再計算され、それ以外は保存値をそのまま使用。
  List<LifePeriod> _periods = [];

  /// 永続保存された強運Top5（mode → 上位5日）。periods と同じく force でのみ再計算。
  /// mode 切替時は保存値から即引くだけで再計算しない。
  Map<String, List<ForecastDay>> _top5 = {};

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // 設定を先に読んでから _load — yearOffset が 0 のまま初回フェッチが走るのを防ぐ
    await _loadSettings();
    await _load();
  }

  Future<void> _loadSettings() async {
    final mode = await SolaraStorage.loadForecastColorMode();
    final high = await SolaraStorage.loadForecastHighColor();
    var year = await SolaraStorage.loadForecastYearOffset();
    // Phase 2-8: Pro→Free 降格時は永続化された year > 0 を 0 に巻き戻す。
    // Free が起動した瞬間に Pro 限定の年データを見るのを防ぐ。
    if (year > 0 && !ProStatus.instance.isPro) {
      year = 0;
      await SolaraStorage.saveForecastYearOffset(0);
    }
    if (!mounted) return;
    setState(() { _colorMode = mode; _highColor = high; _yearOffset = year; });
  }

  Future<void> _setColorMode(String m) async {
    setState(() => _colorMode = m);
    await SolaraStorage.saveForecastColorMode(m);
  }

  Future<void> _setHighColor(String c) async {
    setState(() => _highColor = c);
    await SolaraStorage.saveForecastHighColor(c);
  }

  Future<void> _load() async {
    setState(() { _loading = true; _errorMsg = null; _noProfile = false; });
    final p = await SolaraStorage.loadProfile();
    if (p == null || !p.isComplete) {
      if (!mounted) return;
      setState(() { _loading = false; _noProfile = true; });
      return;
    }
    // 暦年(1/1〜12/31)分を取得 (全 yearOffset 共通)。スコアは日付ごとに確定的なので
    // 暦年単位のキャッシュなら日付が進んでも内容は変わらない (ローリング更新は廃止)。
    final ForecastCache? cache =
        await ForecastRepo.fetchFull(profile: p, yearOffset: _yearOffset);
    final periods = (cache != null)
        ? await ForecastRepo.loadOrComputePeriods(cache: cache, yearOffset: _yearOffset)
        : <LifePeriod>[];
    final top5 = (cache != null)
        ? await ForecastRepo.loadOrComputeTop5(cache: cache, yearOffset: _yearOffset)
        : <String, List<ForecastDay>>{};
    if (!mounted) return;
    setState(() {
      _cache = cache;
      _periods = periods;
      _top5 = top5;
      _loading = false;
      _errorMsg = cache == null ? t.forecast.error : null;
      // 初期選択: 今年なら今日、過去/未来年は先頭(1/1)。
      _selected = _initialSelectedDay(cache);
    });
  }

  /// 画面を開いたときの初期選択日: cache 内に今日があれば今日、無ければ先頭(1/1)。
  ForecastDay? _initialSelectedDay(ForecastCache? cache) {
    if (cache == null || cache.days.isEmpty) return null;
    final now = DateTime.now();
    final todayKey = '${now.year.toString().padLeft(4, "0")}'
        '-${now.month.toString().padLeft(2, "0")}'
        '-${now.day.toString().padLeft(2, "0")}';
    for (final d in cache.days) {
      if (d.date == todayKey) return d;
    }
    return cache.days.first;
  }

  Future<void> _setYearOffset(int offset) async {
    if (_yearOffset == offset) return;
    // Phase 2-8: 年オフセット >= 1 (翌年以降) は Pro 機能 (5 年予測 = F3)。
    // 既に閲覧中の年から戻る場合はゲートしない (削減方向は常に許可)。
    if (offset > 0 && !ProStatus.instance.isPro) {
      await showProUnlockDialog(
        context,
        featureLabel: t.forecast.pro5yrLabel,
        description: t.forecast.pro5yrDesc,
      );
      return;
    }
    setState(() => _yearOffset = offset);
    await SolaraStorage.saveForecastYearOffset(offset);
    // 切替時のみ1回フェッチ（キャッシュがあれば API 呼び出しなし）
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final topPad = mq.padding.top;
    // Forecast 画面は情報密度が高く既定フォントが小さめなので、端末のテキスト
    // スケール設定を尊重しつつ、この画面のみ底上げする。
    // 倍率 = 12/9 ≈ 1.33 (最小 9px を 12px に引き上げる係数を全フォントに適用)。
    // (ヒートマップのセルは色のみ=文字を持たないので拡大の影響を受けない)
    final boosted = TextScaler.linear((mq.textScaler.scale(10) / 10) * (12 / 9));
    return MediaQuery(
      data: mq.copyWith(textScaler: boosted),
      child: Container(
      color: const Color(0xFF0A0A14),
      child: Column(children: [
        // Header
        Container(
          padding: EdgeInsets.fromLTRB(16, topPad + 10, 8, 10),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0x22C9A84C))),
          ),
          child: Row(children: [
            const Text('🔮', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            const Text('FORECAST',
                style: TextStyle(fontSize: 13, color: Color(0xFFC9A84C), letterSpacing: 3, fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            // ❓ help_outline: 画面の使い方説明 popup
            GestureDetector(
              onTap: () => _showForecastUsageGuide(context),
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.help_outline,
                    size: 16, color: Color(0xCCAAAAAA)),
              ),
            ),
            const SizedBox(width: 4),
            if (_cache != null) Text(t.forecast.daysCount(n: _cache!.days.length),
                style: const TextStyle(fontSize: 9, color: Color(0xFF666666))),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close, color: Color(0xFF888888)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ]),
        ),
        Expanded(child: _buildBody()),
      ]),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(
              color: Color(0xFFC9A84C), strokeWidth: 2),
          const SizedBox(height: 14),
          Text(t.forecast.calculating,
              style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
        ]),
      );
    }
    if (_noProfile) return NoProfileGuide(onNavigateToSanctuary: widget.onNavigateToSanctuary);
    if (_errorMsg != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_errorMsg!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
        ),
      );
    }
    final c = _cache;
    if (c == null || c.days.isEmpty) {
      return Center(
        child: Text(t.forecast.noData,
            style: const TextStyle(color: Color(0xFF888888))),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildBasisCard(c.days),
        const SizedBox(height: 16),
        _buildHeatmap(c.days),
        const SizedBox(height: 18),
        _buildSelectedDayDetail(),
        const SizedBox(height: 20),
        ForecastLifePeriodsSection(
          periods: _periods,
        ),
        const SizedBox(height: 20),
        ForecastTop5Section(
          top5: _top5,
          mode: _top5Mode,
          year: DateTime.now().year + _yearOffset,
          onModeChange: (m) => setState(() => _top5Mode = m),
          onSelect: (d) => setState(() => _selected = d),
        ),
        const SizedBox(height: 24),
        _buildFetchInfo(),
      ]),
    );
  }

  /// 表示期間 + 年間ベストの統合カード
  /// （Forecast スコアは出生情報のみで決まり地点に依存しないため基準地は表示しない）
  Widget _buildBasisCard(List<ForecastDay> days) {
    // 表示期間 (暦年 1/1〜12/31)
    final year = DateTime.now().year + _yearOffset;
    final start = DateTime(year, 1, 1);
    final end = DateTime(year, 12, 31);
    final sep = isEnLocale() ? ' - ' : ' 〜 ';
    final rangeText = '${_fmt(start)}$sep${_fmt(end)}';

    // 年間ベスト
    ForecastDay? best;
    for (final d in days) {
      if (best == null || d.overall > best.overall) best = d;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x1FC9A84C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x33C9A84C)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 表示期間
        Row(children: [
          const Text('📅', style: TextStyle(fontSize: 15)),
          const SizedBox(width: 8),
          Text(t.forecast.displayPeriod,
              style: const TextStyle(fontSize: 9, color: Color(0xFF999999), letterSpacing: 2)),
          const SizedBox(width: 8),
          // 「表示期間」のすぐ右から左寄せで表示。枠内に収まるよう自動縮小。
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(rangeText,
                  maxLines: 1,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF999999))),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (int i = 0; i < 5; i++) _yearSeg(i),
          ]),
        ),
        // 年間ベスト
        if (best != null) Padding(
          padding: const EdgeInsets.only(top: 10),
          child: _buildBestChip(best),
        ),
      ]),
    );
  }

  String _fmt(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2, "0")}/${d.day.toString().padLeft(2, "0")}';

  Widget _buildBestChip(ForecastDay best) {
    final parts = best.date.split('-');
    final mm = parts[1];
    final dd = parts[2];
    final fortune = best.topFortune;
    final fLabel = fortune != null ? (categoryLabels[fortune] ?? fortune) : '';
    final fColor = fortune != null
        ? (categoryColors[fortune] ?? const Color(0xFFC9A84C))
        : const Color(0xFFC9A84C);
    // 実効 ~2.0x では固定ラベル群の合計幅がカード幅を超えうる。FittedBox(scaleDown)
    // で全文を保ったまま 1 行に収める (truncation せず縮小のみ)。
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Text('⭐', style: TextStyle(fontSize: 12)),
        const SizedBox(width: 6),
        Text(t.forecast.yearBest,
            style: const TextStyle(fontSize: 9, color: Color(0xFF999999), letterSpacing: 2)),
        const SizedBox(width: 10),
        Text('$mm/$dd',
            style: const TextStyle(fontSize: 12, color: Color(0xFFE8E0D0), fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        if (fLabel.isNotEmpty) Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: fColor.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(fLabel, style: TextStyle(fontSize: 9, color: fColor)),
        ),
        const SizedBox(width: 6),
        Text(best.overall.toStringAsFixed(1),
            style: const TextStyle(fontSize: 10, color: Color(0xFFC9A84C))),
      ]),
    );
  }

  Widget _yearSeg(int offset) {
    final active = _yearOffset == offset;
    final labels = t.forecast.yearLabels;
    final label =
        offset < labels.length ? labels[offset] : t.forecast.plusYears(n: offset);
    return GestureDetector(
      onTap: _loading ? null : () => _setYearOffset(offset),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        margin: const EdgeInsets.only(right: 5),
        decoration: BoxDecoration(
          color: active ? const Color(0x33C9A84C) : const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? const Color(0xFFC9A84C) : const Color(0x22FFFFFF)),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 10,
              color: active ? const Color(0xFFC9A84C) : const Color(0xFF888888),
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            )),
      ),
    );
  }

  /// ヒートマップ — 12ヶ月 × ~31日 グリッド
  Widget _buildHeatmap(List<ForecastDay> days) {
    if (days.isEmpty) return const SizedBox.shrink();

    // overall の min/max を取って正規化（relative / category モードで使用）
    double minV = double.infinity, maxV = -double.infinity;
    for (final d in days) {
      if (d.overall < minV) minV = d.overall;
      if (d.overall > maxV) maxV = d.overall;
    }
    final range = (maxV - minV).abs() < 0.01 ? 1.0 : (maxV - minV);

    // 月ごとにグループ化
    final byMonth = <String, List<ForecastDay>>{};
    for (final d in days) {
      final ym = d.date.substring(0, 7); // YYYY-MM
      byMonth.putIfAbsent(ym, () => []).add(d);
    }
    final monthKeys = byMonth.keys.toList()..sort();

    // 表示中の年月レンジ (見出し横に「YYYY年M月 〜 YYYY年M月」として
    // 表示。各行ラベルから年表記を撤去して月数字のみにしたので、
    // 年情報はここに集約する)。
    String monthRangeLabel = '';
    if (monthKeys.isNotEmpty) {
      final fp = monthKeys.first.split('-');
      final lp = monthKeys.last.split('-');
      final fm = int.parse(fp[1]);
      final lm = int.parse(lp[1]);
      monthRangeLabel =
          t.forecast.monthRange(fy: fp[0], fm: fm, ly: lp[0], lm: lm);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ForecastSectionHeader(
        label: t.forecast.heatmap1yr,
        onInfo: () => _showHeatmapInfo(context),
      ),
      // 期間表示: タイトル直下の行に配置。月数字のみのラベル列とぶつからない
      // よう、見出しと同じインデントで左寄せにする。
      const SizedBox(height: 2),
      Text(
        monthRangeLabel,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF888888),
          letterSpacing: 0.4,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      const SizedBox(height: 6),
      // 狭い画面でも overflow しないよう、トグル列は横スクロール可能にする
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: _buildColorModeToggle(),
      ),
      const SizedBox(height: 6),
      _buildLegend(minV, maxV),
      const SizedBox(height: 10),
      for (final ym in monthKeys) _monthRow(ym, byMonth[ym]!, minV, range),
    ]);
  }

  /// 3-way セグメント: 相対 / 絶対 / カテゴリ
  /// ＋ 色方向トグル（category モードで無効化）
  /// ＋ ランクセグメント 1位/2位（category モードのみ有効）
  /// 全て常に表示（位置を固定、モードに応じて活性/不活性が切り替わる）
  Widget _buildColorModeToggle() {
    final highToggleDisabled = _colorMode == 'category';
    final rankDisabled = _colorMode != 'category';
    return Row(mainAxisSize: MainAxisSize.min, children: [
      _segment(t.forecast.segRelative, 'relative'),
      _segment(t.forecast.segAbsolute, 'absolute'),
      _segment(t.forecast.segCategory, 'category'),
      Padding(
        padding: const EdgeInsets.only(left: 6),
        child: GestureDetector(
          onTap: highToggleDisabled
              ? null
              : () => _setHighColor(_highColor == 'green' ? 'red' : 'green'),
          child: Opacity(
            opacity: highToggleDisabled ? 0.35 : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: highToggleDisabled ? const Color(0x08FFFFFF) : const Color(0x14FFFFFF),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: highToggleDisabled ? const Color(0x22FFFFFF) : const Color(0x33C9A84C),
                ),
              ),
              child: Text(
                _highColor == 'green'
                    ? t.forecast.highGreen
                    : t.forecast.highRed,
                style: TextStyle(
                  fontSize: 9,
                  color: highToggleDisabled ? const Color(0xFF666666) : const Color(0xFFE8E0D0),
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(width: 6),
      _rankSeg(1, rankDisabled),
      _rankSeg(2, rankDisabled),
    ]);
  }

  Widget _rankSeg(int rank, bool disabled) {
    final active = !disabled && _categoryRank == rank;
    return Opacity(
      opacity: disabled ? 0.35 : 1.0,
      child: GestureDetector(
        onTap: disabled ? null : () => setState(() => _categoryRank = rank),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          margin: const EdgeInsets.only(left: 2),
          decoration: BoxDecoration(
            color: active ? const Color(0x33C9A84C)
                 : (disabled ? const Color(0x08FFFFFF) : const Color(0x14FFFFFF)),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: active ? const Color(0xFFC9A84C)
                   : (disabled ? const Color(0x22FFFFFF) : const Color(0x33C9A84C)),
            ),
          ),
          child: Text(t.forecast.rankNth(n: rank),
              style: TextStyle(
                fontSize: 9,
                color: active ? const Color(0xFFC9A84C)
                     : (disabled ? const Color(0xFF666666) : const Color(0xFFE8E0D0)),
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              )),
        ),
      ),
    );
  }

  Widget _segment(String label, String value) {
    final active = _colorMode == value;
    return GestureDetector(
      onTap: () => _setColorMode(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        margin: const EdgeInsets.only(left: 2),
        decoration: BoxDecoration(
          color: active ? const Color(0x33C9A84C) : const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: active ? const Color(0xFFC9A84C) : const Color(0x22FFFFFF)),
        ),
        child: Text(label,
          style: TextStyle(
            fontSize: 9,
            color: active ? const Color(0xFFC9A84C) : const Color(0xFF888888),
          )),
      ),
    );
  }

  Widget _buildLegend(double minV, double maxV) {
    switch (_colorMode) {
      case 'relative':
        final low = _highColor == 'green'
            ? t.forecast.legend.relLowRed
            : t.forecast.legend.relLowGreen;
        final high = _highColor == 'green'
            ? t.forecast.legend.relHighGreen
            : t.forecast.legend.relHighRed;
        return Text(
            t.forecast.legend.relRange(
                low: low,
                high: high,
                min: minV.toStringAsFixed(1),
                max: maxV.toStringAsFixed(1)),
            style: const TextStyle(fontSize: 9, color: Color(0xFF666666)));
      case 'absolute':
        final low = _highColor == 'green'
            ? t.forecast.legend.absLowRed
            : t.forecast.legend.absLowGreen;
        final high = _highColor == 'green'
            ? t.forecast.legend.absHighGreen
            : t.forecast.legend.absHighRed;
        return Text(t.forecast.legend.absScale(low: low, high: high),
            style: const TextStyle(fontSize: 9, color: Color(0xFF666666)));
      case 'category':
        return Row(children: [
          Flexible(
            child: Text(t.forecast.legend.catRank(rank: _categoryRank),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 9, color: Color(0xFF666666))),
          ),
          const SizedBox(width: 6),
          ..._catColorChips(),
        ]);
    }
    return const SizedBox.shrink();
  }

  List<Widget> _catColorChips() {
    final cats = ['love', 'money', 'healing', 'work', 'communication'];
    return [for (final c in cats) Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Container(
        width: 6, height: 6,
        decoration: BoxDecoration(
          color: categoryColors[c],
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    )];
  }

  Widget _monthRow(String ym, List<ForecastDay> monthDays, double minV, double range) {
    final parts = ym.split('-');
    // 月数字のみ (0 padding なし)。固定幅 + 中央寄せで「5」と「12」が
    // 桁数違いでも揃って見えるようにする。年は見出し横の期間表示に集約。
    final monthLabel = int.parse(parts[1]).toString();
    return Padding(
      // 行間は最低限 (1px)。タイル自体の vertical margin は持たないので、
      // 隣接月のタイルが詰まって 1 年分の流れが読み取りやすくなる。
      padding: const EdgeInsets.only(bottom: 1),
      child: Row(children: [
        SizedBox(
          width: 24,
          child: Text(
            monthLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF888888),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Row(children: [
          for (final d in monthDays) Expanded(child: _dayCell(d, minV, range)),
        ])),
      ]),
    );
  }

  Widget _dayCell(ForecastDay d, double minV, double range) {
    final color = _cellColor(d, minV, range);
    final isSelected = _selected != null && _selected!.date == d.date;
    return GestureDetector(
      onTap: () => setState(() => _selected = d),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 0.5),
        height: 16,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
          // 選択タイルは白枠 + 淡い白 glow で他タイルから明確に浮かす。
          // 下の詳細パネル冒頭に同じ色見本を出して視覚的に紐付ける。
          border: isSelected
              ? Border.all(color: const Color(0xFFFFFFFF), width: 1.5)
              : null,
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x66FFFFFF),
                    blurRadius: 4,
                    spreadRadius: 0.5,
                  ),
                ]
              : null,
        ),
      ),
    );
  }

  /// モードに応じたセル色算出
  Color _cellColor(ForecastDay d, double minV, double range) {
    switch (_colorMode) {
      case 'absolute':
        // 固定閾値: 45 → red, 65 → yellow, 85 → green（365日テストの overall range 47-81 を包含）
        final ratio = ((d.overall - 45) / (85 - 45)).clamp(0.0, 1.0);
        return _gradientColor(ratio);
      case 'category':
        // topFortune 色をベース、overall で明度/alpha を調整
        return _categoryColor(d, minV, range);
      case 'relative':
      default:
        final ratio = ((d.overall - minV) / range).clamp(0.0, 1.0);
        return _gradientColor(ratio);
    }
  }

  /// 赤↔黄↔緑のグラデ。_highColor='red' ならratio反転で赤が高い。
  Color _gradientColor(double ratio) {
    final t = _highColor == 'green' ? ratio : 1.0 - ratio;
    if (t < 0.5) {
      return Color.lerp(const Color(0xFFE74C6B), const Color(0xFFF5D76E), t * 2)!;
    } else {
      return Color.lerp(const Color(0xFFF5D76E), const Color(0xFF64C8B4), (t - 0.5) * 2)!;
    }
  }

  /// カテゴリ色。_categoryRank (1 or 2) に応じてその日の上位 N 位カテゴリ色を返す。
  /// overall が年内で高いほど明るく（alpha 大）、低いほど暗く（alpha 小）。
  Color _categoryColor(ForecastDay d, double minV, double range) {
    // catScores 降順ソートから rank 番目を取得
    final sorted = d.catScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    String? cat;
    if (sorted.length >= _categoryRank) {
      final entry = sorted[_categoryRank - 1];
      if (entry.value > 0) cat = entry.key;
    }
    if (cat == null) return const Color(0xFF333333);
    final base = categoryColors[cat] ?? const Color(0xFF888888);
    final ratio = ((d.overall - minV) / range).clamp(0.0, 1.0);
    return base.withValues(alpha: 0.35 + ratio * 0.65);
  }

  /// 選択日を delta 日ずらせるか (リスト範囲内か)
  bool _canShiftSelectedDay(int delta) {
    final cur = _selected;
    final cache = _cache;
    if (cur == null || cache == null || cache.days.isEmpty) return false;
    final idx = cache.days.indexWhere((d) => d.date == cur.date);
    if (idx < 0) return false;
    final newIdx = idx + delta;
    return newIdx >= 0 && newIdx < cache.days.length;
  }

  /// 選択日を 1 日ずつ前後に動かす。月またぎは days リスト連続性で自然に進む。
  void _shiftSelectedDay(int delta) {
    if (!_canShiftSelectedDay(delta)) return;
    final cache = _cache!;
    final idx = cache.days.indexWhere((d) => d.date == _selected!.date);
    setState(() => _selected = cache.days[idx + delta]);
  }

  Widget _buildSelectedDayDetail() {
    final d = _selected;
    if (d == null) return const SizedBox.shrink();
    final parts = d.date.split('-');
    final dateLabel = '${parts[0]}/${parts[1]}/${parts[2]}';
    // 2026-05-12: ヘッダ行は「日付 + 矢印 + 地図ボタン」のみ。
    //   ・左のスウォッチ (色見本タイル): どの日か自明なので撤去
    //   ・右の運勢チップ: 下のカテゴリ別バーで詳細を見られるので撤去
    //   ・両者撤去で横並びの overflow リスクも解消

    // カテゴリ別スコアを降順でソート
    final catList = d.catScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x33C9A84C)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          // 左△: 1日前へ。日付リスト先頭で disable。
          _DayStepperButton(
            icon: Icons.arrow_left,
            enabled: _canShiftSelectedDay(-1),
            onTap: () => _shiftSelectedDay(-1),
          ),
          const SizedBox(width: 4),
          // 日付テキストは Expanded で横幅一杯に使い、`...` 省略を防ぐ。
          // マップボタンは下のメトリクス行右端に移動済み。
          Expanded(
            child: Text(dateLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, color: Color(0xFFE8E0D0), fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 4),
          // 右△: 1日後へ。日付リスト末尾で disable。
          _DayStepperButton(
            icon: Icons.arrow_right,
            enabled: _canShiftSelectedDay(1),
            onTap: () => _shiftSelectedDay(1),
          ),
        ]),
        const SizedBox(height: 10),
        // 3メトリクスを Expanded で等分 (Forecast は画面内で追加 1.33x ブーストが
        // 掛かり実効最大 ~2.0x。非flex のままだと横 overflow するため)。
        Row(children: [
          Expanded(child: _metric(t.forecast.metricOverall, d.overall.toStringAsFixed(1))),
          const SizedBox(width: 14),
          Expanded(child: _metric(t.forecast.metricTopDir, dirName(d.topDir))),
          const SizedBox(width: 14),
          Expanded(child: _metric(t.forecast.metricDirScore, d.topDirScore.toStringAsFixed(1))),
        ]),
        const SizedBox(height: 12),
        Text(t.forecast.categoryBy,
            style: const TextStyle(fontSize: 10, color: Color(0xFF888888), letterSpacing: 1)),
        const SizedBox(height: 6),
        for (final e in catList) _catBar(e.key, e.value, catList.first.value),
      ]),
    );
  }

  Widget _metric(String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF888888), letterSpacing: 1)),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFFC9A84C), fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _catBar(String cat, double value, double maxValue) {
    final color = categoryColors[cat] ?? const Color(0xFFE8E0D0);
    final label = categoryLabels[cat] ?? cat;
    final ratio = maxValue <= 0 ? 0.0 : (value / maxValue).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        SizedBox(width: 52,
            child: Text(label, style: TextStyle(fontSize: 10, color: color))),
        Expanded(child: Container(
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0x22FFFFFF),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: ratio,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        )),
        const SizedBox(width: 8),
        SizedBox(width: 30,
            child: Text(value.toStringAsFixed(1),
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 10, color: Color(0xFFAAAAAA)))),
      ]),
    );
  }

  Widget _buildFetchInfo() {
    final c = _cache;
    if (c == null) return const SizedBox.shrink();
    final jst = c.fetchedAt.toLocal();
    final ts = '${jst.year}/${jst.month.toString().padLeft(2, "0")}/${jst.day.toString().padLeft(2, "0")} ${jst.hour.toString().padLeft(2, "0")}:${jst.minute.toString().padLeft(2, "0")}';
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(t.forecast.lastFetch(ts: ts),
          style: const TextStyle(fontSize: 9, color: Color(0xFF555555))),
    );
  }
}

/// FORECAST 画面の使い方 popup (ヘッダの ❓ ボタンから開く)。
void _showForecastUsageGuide(BuildContext context) {
  showInfoPopup(
    context: context,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.forecast.usage.title,
          style: const TextStyle(
              color: Color(0xFFC9A84C), fontSize: 14, letterSpacing: 1),
        ),
        const SizedBox(height: 10),
        Text(
          t.forecast.usage.intro,
          style: const TextStyle(
              color: Color(0xFFE8E0D0),
              fontSize: 13,
              height: 1.6,
              fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 14),
        Text(
          t.forecast.usage.s1Title,
          style: const TextStyle(
              color: Color(0xFFC9A84C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          t.forecast.usage.s1Body,
          style: const TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
        ),
        const SizedBox(height: 10),
        Text(
          t.forecast.usage.s2Title,
          style: const TextStyle(
              color: Color(0xFFC9A84C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          t.forecast.usage.s2Body,
          style: const TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
        ),
        const SizedBox(height: 10),
        Text(
          t.forecast.usage.s3Title,
          style: const TextStyle(
              color: Color(0xFFC9A84C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          t.forecast.usage.s3Body,
          style: const TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
        ),
        const SizedBox(height: 10),
        Text(
          t.forecast.usage.s4Title,
          style: const TextStyle(
              color: Color(0xFFC9A84C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          t.forecast.usage.s4Body,
          style: const TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
        ),
        const SizedBox(height: 10),
        Text(
          t.forecast.usage.s5Title,
          style: const TextStyle(
              color: Color(0xFFC9A84C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          t.forecast.usage.s5Body,
          style: const TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
        ),
      ],
    ),
  );
}

/// 1 年ヒートマップの読み方 popup (ヒートマップ見出し横の i ボタンから)。
/// 3 つの色モード・色方向・ランクの仕組みを解説。
void _showHeatmapInfo(BuildContext context) {
  showInfoPopup(
    context: context,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.forecast.heatmapInfo.title,
          style: const TextStyle(
              color: Color(0xFFC9A84C), fontSize: 14, letterSpacing: 1),
        ),
        const SizedBox(height: 10),
        Text(
          t.forecast.heatmapInfo.s1Title,
          style: const TextStyle(
              color: Color(0xFFC9A84C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          t.forecast.heatmapInfo.s1Body,
          style: const TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
        ),
        const SizedBox(height: 10),
        Text(
          t.forecast.heatmapInfo.s2Title,
          style: const TextStyle(
              color: Color(0xFFC9A84C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          t.forecast.heatmapInfo.s2Body,
          style: const TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
        ),
        const SizedBox(height: 10),
        Text(
          t.forecast.heatmapInfo.s3Title,
          style: const TextStyle(
              color: Color(0xFFC9A84C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          t.forecast.heatmapInfo.s3Body,
          style: const TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
        ),
        const SizedBox(height: 10),
        Text(
          t.forecast.heatmapInfo.footer,
          style: const TextStyle(
              color: Color(0xFF999999), fontSize: 11, height: 1.5),
        ),
      ],
    ),
  );
}

/// 選択日詳細パネルの △ ボタン (左右で 1 日前後に動かす)。
/// 端 (リスト先頭/末尾) に達したら disabled (薄色) で押せなくなる。
class _DayStepperButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _DayStepperButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 40, height: 40,
        child: Center(
          child: Icon(
            icon,
            size: 32,
            color: enabled
                ? const Color(0xFFC9A84C)
                : const Color(0x33C9A84C),
          ),
        ),
      ),
    );
  }
}
