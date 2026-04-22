import 'package:flutter/material.dart';
import '../utils/forecast_cache.dart';
import '../utils/solara_storage.dart';
import 'map/map_constants.dart';

/// Forecast 画面 — 1年予測（ヒートマップ + 選択日詳細 + 強運Top5）
/// Map画面から BottomSheet フルスクリーンで開く。
class ForecastScreen extends StatefulWidget {
  final void Function(DateTime date)? onJumpToDate;
  /// 基準地ラベル（VPスロット名やホーム名など）。未指定時はプロフィールから導出。
  final String? baseLabel;
  /// 基準地の住所/座標テキスト。未指定時はプロフィール座標を表示。
  final String? baseDetail;

  const ForecastScreen({
    super.key,
    this.onJumpToDate,
    this.baseLabel,
    this.baseDetail,
  });

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  SolaraProfile? _profile;
  ForecastCache? _cache;
  bool _loading = true;
  String? _errorMsg;
  ForecastDay? _selected;

  /// 色モード: 'relative' (年内min-max正規化) | 'absolute' (固定閾値) | 'category' (topFortune色)
  String _colorMode = 'relative';

  /// 高スコア側の色: 'green' (信号機: 高=緑) | 'red' (赤=高)
  String _highColor = 'green';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _load();
  }

  Future<void> _loadSettings() async {
    final mode = await SolaraStorage.loadForecastColorMode();
    final high = await SolaraStorage.loadForecastHighColor();
    if (!mounted) return;
    setState(() { _colorMode = mode; _highColor = high; });
  }

  Future<void> _setColorMode(String m) async {
    setState(() => _colorMode = m);
    await SolaraStorage.saveForecastColorMode(m);
  }

  Future<void> _setHighColor(String c) async {
    setState(() => _highColor = c);
    await SolaraStorage.saveForecastHighColor(c);
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() { _loading = true; _errorMsg = null; });
    final p = await SolaraStorage.loadProfile();
    if (p == null || !p.isComplete) {
      if (!mounted) return;
      setState(() { _loading = false; _errorMsg = '出生情報を Sanctuary で登録してください'; });
      return;
    }
    _profile = p;
    final cache = forceRefresh
        ? await ForecastRepo.fetchFull(profile: p, force: true)
        : await ForecastRepo.refreshIncremental(profile: p);
    if (!mounted) return;
    setState(() {
      _cache = cache;
      _loading = false;
      _errorMsg = cache == null ? 'Forecast の取得に失敗しました。ネットワーク接続を確認してください。' : null;
      // 初期選択: 今日
      _selected = cache != null && cache.days.isNotEmpty ? cache.days.first : null;
    });
  }

  Future<void> _forceRefresh() async {
    if (_profile == null) return;
    final rem = await ForecastRepo.cooldownRemaining(profileHashOf(_profile!));
    if (rem > Duration.zero) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('クールダウン中です（残り ${rem.inMinutes} 分）'),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    await _load(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
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
            const SizedBox(width: 6),
            if (_cache != null) Text('(${_cache!.days.length}日)',
                style: const TextStyle(fontSize: 9, color: Color(0xFF666666))),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFFC9A84C), size: 20),
              tooltip: '再取得',
              onPressed: _loading ? null : _forceRefresh,
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Color(0xFF888888)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ]),
        ),
        Expanded(child: _buildBody()),
      ]),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(color: Color(0xFFC9A84C), strokeWidth: 2),
          SizedBox(height: 14),
          Text('天体の運行を計算中…', style: TextStyle(fontSize: 11, color: Color(0xFF888888))),
        ]),
      );
    }
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
      return const Center(
        child: Text('データがありません', style: TextStyle(color: Color(0xFF888888))),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildBaseLocation(),
        const SizedBox(height: 14),
        _buildHeatmap(c.days),
        const SizedBox(height: 18),
        _buildSelectedDayDetail(),
        const SizedBox(height: 18),
        _buildTop5(c.days),
        const SizedBox(height: 24),
        _buildFetchInfo(),
      ]),
    );
  }

  /// 基準地ブロック — ヒートマップ見出しの上に表示。
  /// Forecast は出生情報（natal）をベースに計算しているため、
  /// 明示的に「どこを基準に見ているか」を示す。
  Widget _buildBaseLocation() {
    // ラベル優先順位: widget.baseLabel > profile.homeName > profile.birthPlace > '基準地'
    final p = _profile;
    String label;
    if (widget.baseLabel != null && widget.baseLabel!.isNotEmpty) {
      label = widget.baseLabel!;
    } else if (p != null && p.homeName.isNotEmpty) {
      label = p.homeName;
    } else if (p != null && p.birthPlace.isNotEmpty) {
      label = p.birthPlace;
    } else {
      label = '基準地';
    }

    // 詳細テキスト: widget.baseDetail > 座標
    String? detail = widget.baseDetail;
    if ((detail == null || detail.isEmpty) && p != null) {
      final lat = p.homeLat != 0 ? p.homeLat : p.birthLat;
      final lng = p.homeLng != 0 ? p.homeLng : p.birthLng;
      if (lat != 0 || lng != 0) {
        detail = '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x1FC9A84C),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x33C9A84C)),
      ),
      child: Row(children: [
        const Text('📍', style: TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('基準地',
                style: TextStyle(fontSize: 9, color: Color(0xFF999999), letterSpacing: 2)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 13, color: Color(0xFFC9A84C), fontWeight: FontWeight.w600),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            if (detail != null) Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(detail,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF888888)),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        )),
      ]),
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

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('▸ 1年ヒートマップ',
            style: TextStyle(fontSize: 11, color: Color(0xFFC9A84C), letterSpacing: 2)),
        const Spacer(),
        _buildColorModeToggle(),
      ]),
      const SizedBox(height: 6),
      _buildLegend(minV, maxV),
      const SizedBox(height: 10),
      for (final ym in monthKeys) _monthRow(ym, byMonth[ym]!, minV, range),
    ]);
  }

  /// 3-way セグメント: 相対 / 絶対 / カテゴリ（＋ 色方向トグル）
  Widget _buildColorModeToggle() {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      _segment('相対', 'relative'),
      _segment('絶対', 'absolute'),
      _segment('カテゴリ', 'category'),
      if (_colorMode != 'category') Padding(
        padding: const EdgeInsets.only(left: 6),
        child: GestureDetector(
          onTap: () => _setHighColor(_highColor == 'green' ? 'red' : 'green'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0x14FFFFFF),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0x33C9A84C)),
            ),
            child: Text(
              _highColor == 'green' ? '🟢↑高' : '🔴↑高',
              style: const TextStyle(fontSize: 9, color: Color(0xFFE8E0D0)),
            ),
          ),
        ),
      ),
    ]);
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
        final low = _highColor == 'green' ? '赤=年内最低' : '緑=年内最低';
        final high = _highColor == 'green' ? '緑=年内最高' : '赤=年内最高';
        return Text('$low  /  $high  （min:${minV.toStringAsFixed(1)} → max:${maxV.toStringAsFixed(1)}）',
            style: const TextStyle(fontSize: 9, color: Color(0xFF666666)));
      case 'absolute':
        final low = _highColor == 'green' ? '赤=45以下' : '緑=45以下';
        final high = _highColor == 'green' ? '緑=85以上' : '赤=85以上';
        return Text('$low  /  黄=65  /  $high  （固定スケール）',
            style: const TextStyle(fontSize: 9, color: Color(0xFF666666)));
      case 'category':
        return Row(children: [
          const Text('色=最強カテゴリ / 濃さ=スコア高低',
              style: TextStyle(fontSize: 9, color: Color(0xFF666666))),
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
    final label = '${parts[0]}/${parts[1]}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        SizedBox(
          width: 50,
          child: Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF888888))),
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
          border: isSelected
              ? Border.all(color: const Color(0xFFFFFFFF), width: 1)
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

  /// カテゴリ色。topFortune が無ければ中間グレー。
  /// overall が年内で高いほど明るく（alpha 大）、低いほど暗く（alpha 小）。
  Color _categoryColor(ForecastDay d, double minV, double range) {
    final cat = d.topFortune;
    if (cat == null) return const Color(0xFF333333);
    final base = categoryColors[cat] ?? const Color(0xFF888888);
    final ratio = ((d.overall - minV) / range).clamp(0.0, 1.0);
    // alpha 0.35 〜 1.0（最弱日でも色味が見える程度に）
    return base.withValues(alpha: 0.35 + ratio * 0.65);
  }

  Widget _buildSelectedDayDetail() {
    final d = _selected;
    if (d == null) return const SizedBox.shrink();
    final parts = d.date.split('-');
    final dateLabel = '${parts[0]}/${parts[1]}/${parts[2]}';
    final fortune = d.topFortune;
    final fortuneLabel = fortune != null ? (categoryLabels[fortune] ?? fortune) : '—';
    final fortuneColor = fortune != null
        ? (categoryColors[fortune] ?? const Color(0xFFE8E0D0))
        : const Color(0xFF888888);

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
          Text(dateLabel, style: const TextStyle(fontSize: 16, color: Color(0xFFE8E0D0), fontWeight: FontWeight.w600)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: fortuneColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: fortuneColor.withValues(alpha: 0.5)),
            ),
            child: Text(fortuneLabel, style: TextStyle(fontSize: 10, color: fortuneColor)),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _metric('総合', d.overall.toStringAsFixed(1)),
          const SizedBox(width: 14),
          _metric('強運方位', dir16JP[d.topDir] ?? d.topDir),
          const SizedBox(width: 14),
          _metric('方位スコア', d.topDirScore.toStringAsFixed(1)),
        ]),
        const SizedBox(height: 12),
        const Text('カテゴリ別',
            style: TextStyle(fontSize: 10, color: Color(0xFF888888), letterSpacing: 1)),
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

  Widget _buildTop5(List<ForecastDay> days) {
    final sorted = List<ForecastDay>.from(days)
      ..sort((a, b) => b.overall.compareTo(a.overall));
    final top5 = sorted.take(5).toList();
    if (top5.isEmpty) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('▸ 強運Top5', style: TextStyle(fontSize: 11, color: Color(0xFFC9A84C), letterSpacing: 2)),
      const SizedBox(height: 10),
      for (int i = 0; i < top5.length; i++) _top5Row(i, top5[i]),
    ]);
  }

  Widget _top5Row(int rank, ForecastDay d) {
    final parts = d.date.split('-');
    final dateLabel = '${parts[1]}/${parts[2]}';
    final fortune = d.topFortune;
    final fortuneLabel = fortune != null ? (categoryLabels[fortune] ?? fortune) : '';
    final fortuneColor = fortune != null
        ? (categoryColors[fortune] ?? const Color(0xFFE8E0D0))
        : const Color(0xFF888888);

    return InkWell(
      onTap: () => setState(() => _selected = d),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          SizedBox(width: 24,
              child: Text('#${rank + 1}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFFC9A84C), fontWeight: FontWeight.w600))),
          SizedBox(width: 50,
              child: Text(dateLabel,
                  style: const TextStyle(fontSize: 12, color: Color(0xFFE8E0D0)))),
          Expanded(child: Row(children: [
            Text('${dir16JP[d.topDir] ?? d.topDir}方位',
                style: const TextStyle(fontSize: 10, color: Color(0xFF999999))),
            const SizedBox(width: 10),
            if (fortuneLabel.isNotEmpty) Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: fortuneColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(fortuneLabel, style: TextStyle(fontSize: 9, color: fortuneColor)),
            ),
          ])),
          Text(d.overall.toStringAsFixed(1),
              style: const TextStyle(fontSize: 11, color: Color(0xFFC9A84C), fontWeight: FontWeight.w600)),
          if (widget.onJumpToDate != null) IconButton(
            icon: const Icon(Icons.map_outlined, size: 16, color: Color(0xFF888888)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            tooltip: 'その日をMapで見る',
            onPressed: () {
              final parts = d.date.split('-').map(int.parse).toList();
              final date = DateTime.utc(parts[0], parts[1], parts[2], 3, 0, 0);
              widget.onJumpToDate!(date);
              Navigator.of(context).maybePop();
            },
          ),
        ]),
      ),
    );
  }

  Widget _buildFetchInfo() {
    final c = _cache;
    if (c == null) return const SizedBox.shrink();
    final jst = c.fetchedAt.toLocal();
    final ts = '${jst.year}/${jst.month.toString().padLeft(2, "0")}/${jst.day.toString().padLeft(2, "0")} ${jst.hour.toString().padLeft(2, "0")}:${jst.minute.toString().padLeft(2, "0")}';
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text('最終取得: $ts  /  差分更新方式（月次）',
          style: const TextStyle(fontSize: 9, color: Color(0xFF555555))),
    );
  }
}
