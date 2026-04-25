import 'dart:math';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../utils/solara_storage.dart';
import 'horoscope/horo_antique_icons.dart';
import 'locations/locations_date_stepper.dart';
import 'map/map_astro.dart';
import 'map/map_constants.dart';
import 'map/map_search.dart';
import 'map/map_vp_panel.dart';

/// Locations 一覧画面 — 登録済み拠点を16方位スコア付きで管理。
/// Map画面から BottomSheet フルスクリーンで開く。
class LocationsScreen extends StatefulWidget {
  final LatLng center;
  final ScoreResult? scoreResult;
  final Map<String, double> sectorScores;
  final SolaraProfile? profile;
  final void Function(VPSlot slot)? onSelectSlot;
  /// Sanctuary タブへの遷移コールバック（プロフィール未設定時の案内から呼ばれる）
  final VoidCallback? onNavigateToSanctuary;

  const LocationsScreen({
    super.key,
    required this.center,
    required this.scoreResult,
    required this.sectorScores,
    required this.profile,
    this.onSelectSlot,
    this.onNavigateToSanctuary,
  });

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  final SlotManager _mgr = SlotManager(
    storageKey: 'solara_locations',
    defaultNames: ['場所1','場所2','場所3','場所4'],
  );
  // 基準地点プルダウン用に VIEWPOINT スロットも読み込む。
  // null = 現在地（widget.center）、それ以外は VP スロットの index
  final SlotManager _vpMgr = SlotManager(
    storageKey: 'solara_vp_slots',
    defaultNames: ['職場','お気に入り','スポット','場所'],
  );
  List<VPSlot> _slots = [];
  List<VPSlot> _vpSlots = [];
  int? _refVpIdx;
  // 表示スコアのカテゴリ。null = 総合（_dateScoreMap）、
  // それ以外は scoreResult.fScores[category] を参照。
  String? _selectedCategory;
  bool _loading = true;

  // ── 日付選択（Locations 内ローカル状態。親の _selectedDate には影響しない）──
  // null = 「今日」（親から渡された sectorScores/scoreResult をそのまま使用）
  // それ以外 = その日付で fetchChart + scoreAll を再実行した結果を使う
  DateTime? _selectedDate;
  ScoreResult? _dateScoreResult;
  Map<String, double> _dateSectorScores = {};
  bool _refetchingDate = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _mgr.syncHome(widget.profile);
    await _vpMgr.syncHome(widget.profile);
    final s = await _mgr.load();
    final vp = await _vpMgr.load();
    if (!mounted) return;
    setState(() { _slots = s; _vpSlots = vp; _loading = false; });
  }

  /// 基準地点 = 選択中 VP スロットの座標、未選択なら widget.center（現在の地図中心）
  LatLng get _refPoint {
    if (_refVpIdx != null && _refVpIdx! < _vpSlots.length) {
      final v = _vpSlots[_refVpIdx!];
      return LatLng(v.lat, v.lng);
    }
    return widget.center;
  }

  /// 現在のスコアソース（日付選択中なら再フェッチ結果、なければ親から渡されたもの）
  ScoreResult? get _activeScoreResult => _selectedDate != null
      ? _dateScoreResult : widget.scoreResult;
  Map<String, double> get _activeSectorScores => _selectedDate != null
      ? _dateSectorScores : widget.sectorScores;

  /// カテゴリ別スコアマップ（未選択時は総合）
  Map<String, double> get _activeScoreMap {
    if (_selectedCategory != null && _activeScoreResult != null) {
      return _activeScoreResult!.fScores[_selectedCategory] ?? _activeSectorScores;
    }
    return _activeSectorScores;
  }

  // 日付選択の許容範囲（showSolaraDatePicker と同じ）: 今日−10年 〜 今日+20年
  DateTime get _dateMin {
    final n = DateTime.now();
    return DateTime.utc(n.year - 10, n.month, n.day);
  }
  DateTime get _dateMax {
    final n = DateTime.now();
    return DateTime.utc(n.year + 20, n.month, n.day);
  }

  /// 表示用の現在の選択日（null なら今日）
  DateTime get _displayDate {
    final d = _selectedDate;
    if (d != null) return d;
    final n = DateTime.now().toUtc();
    return DateTime.utc(n.year, n.month, n.day, 12);
  }

  /// y/m/d オフセットで日付を移動。範囲外はクランプ。
  Future<void> _shiftDate({int years = 0, int months = 0, int days = 0}) async {
    final base = _displayDate;
    int newY = base.year + years;
    int newM = base.month + months;
    int newD = (years != 0 || months != 0) ? base.day : base.day + days;
    await _setYmd(newY, newM, newD);
  }

  /// 年月日を絶対値で指定（手入力用）。月の最大日や年範囲は内部でクランプ。
  Future<void> _setYmd(int year, int month, int day) async {
    int newY = year;
    int newM = month;
    while (newM < 1) { newM += 12; newY -= 1; }
    while (newM > 12) { newM -= 12; newY += 1; }
    final daysInMonth = DateUtils.getDaysInMonth(newY, newM);
    int newD = day.clamp(1, daysInMonth);
    var next = DateTime.utc(newY, newM, newD, 12);
    if (next.isBefore(_dateMin)) next = _dateMin;
    if (next.isAfter(_dateMax)) next = _dateMax;
    await _setDate(next);
  }

  /// 「今日」に戻す（fetch 不要、親の値を使う）
  Future<void> _resetToday() async {
    if (_selectedDate == null) return;
    setState(() {
      _selectedDate = null;
      _dateScoreResult = null;
      _dateSectorScores = {};
    });
  }

  /// 指定日でチャートを再取得してスコアを更新
  Future<void> _setDate(DateTime utcNoon) async {
    final p = widget.profile;
    if (p == null) return;
    setState(() {
      _selectedDate = utcNoon;
      _refetchingDate = true;
    });
    final chart = await fetchChart(
      birthDate: p.birthDate,
      birthTime: p.birthTime,
      birthLat: p.birthLat,
      birthLng: p.birthLng,
      birthTz: p.birthTz,
      birthTzName: p.birthTzName,
      targetDate: utcNoon,
    );
    if (!mounted) return;
    if (chart != null) {
      final res = scoreAll(chart);
      setState(() {
        _dateScoreResult = res;
        _dateSectorScores = res.sScores;
        _refetchingDate = false;
      });
    } else {
      setState(() => _refetchingDate = false);
    }
  }

  Future<void> _addCurrent() async {
    final err = await _mgr.saveCurrentLocation(widget.center);
    if (err != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), duration: const Duration(seconds: 3)),
      );
      return;
    }
    await _load();
  }

  Future<void> _delete(int i) async {
    await _mgr.deleteSlot(i);
    await _load();
  }

  Future<void> _rename(int i) async {
    final ctrl = TextEditingController(text: _slots[i].name);
    final name = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0C0C1A),
        title: const Text('地点の名称を入力',
            style: TextStyle(fontSize: 14, color: Color(0xFFC9A84C))),
        content: TextField(
          controller: ctrl, autofocus: true, maxLength: 12,
          style: const TextStyle(color: Color(0xFFE8E0D0), fontSize: 13),
          decoration: const InputDecoration(
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0x33C9A84C))),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFC9A84C))),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル', style: TextStyle(color: Color(0xFF555555)))),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('OK', style: TextStyle(color: Color(0xFFC9A84C)))),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    await _mgr.renameSlot(i, name);
    await _load();
  }

  _SlotStats _statsFor(VPSlot s) {
    final hit = SearchHit(name: s.name, lat: s.lat, lng: s.lng);
    final ref = _refPoint;
    final dir = hit.directionFrom(ref);
    final score = _activeScoreMap[dir] ?? 0;
    final fortune = _activeScoreResult?.sFortune[dir];
    final km = hit.distanceKmFrom(ref);
    return _SlotStats(dir: dir, score: score, fortune: fortune, km: km);
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return GestureDetector(
      // 日付フィールド外をタップしたら defocus → _DateNumberField の onFocusChange で自動 commit。
      // Locations 全体をヒット対象にし、子の TextField/IconButton 等のタップは透過する。
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
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
            const Text('🌐', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            const Text('LOCATIONS',
                style: TextStyle(fontSize: 13, color: Color(0xFFC9A84C), letterSpacing: 3, fontWeight: FontWeight.w600)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close, color: Color(0xFF888888)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ]),
        ),
        if (_loading) const Expanded(child: Center(
          child: CircularProgressIndicator(color: Color(0xFFC9A84C), strokeWidth: 2),
        )) else if (!(widget.profile?.isComplete ?? false))
          // プロフィール未設定時は Horo 画面と同じ案内カードを出す。
          // 日付ステッパー等は出生情報に依存するため、混乱を避けて非表示。
          Expanded(child: _buildNoProfileGuide())
        else ...[
          // 操作メニュー（ヘッダ直下に配置）
          LocationsDateStepper(
            displayDate: _displayDate,
            dateMin: _dateMin,
            dateMax: _dateMax,
            onResetToToday: _selectedDate != null ? _resetToday : null,
            refetching: _refetchingDate,
            onShift: ({int years = 0, int months = 0, int days = 0}) =>
                _shiftDate(years: years, months: months, days: days),
            onSetYmd: _setYmd,
          ),
          _buildRefPointSelector(),
          _buildCategorySelector(),
          Expanded(child: _slots.isEmpty ? _emptyState() : _buildList()),
        ],
      ]),
      ),
    );
  }

  /// プロフィール未設定時の案内カード（Horo 画面の _buildNoProfile と同スタイル）。
  /// 「設定する」タップで Navigator.pop でシートを閉じ、Sanctuary タブへ遷移。
  Widget _buildNoProfileGuide() {
    return SafeArea(child: Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0x14F9D976),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x40F9D976)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const AntiqueGlyph(icon: AntiqueIcon.reading, size: 32,
            color: Color(0xFFF6BD60)),
          const SizedBox(height: 8),
          const Text('SANCTUARYでプロフィールを設定すると、\n各地点の方位スコアが表示されます',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFFF6BD60))),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              Navigator.of(context).maybePop();
              widget.onNavigateToSanctuary?.call();
            },
            child: const Text('設定する →',
              style: TextStyle(fontSize: 12, color: Color(0xFFF9D976),
                decoration: TextDecoration.underline)),
          ),
        ]),
      ),
    )));
  }

  /// 基準地点プルダウン：現在地 + VIEWPOINT スロット一覧
  Widget _buildRefPointSelector() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0x22C9A84C))),
      ),
      child: Row(children: [
        const Text('基準地点',
            style: TextStyle(fontSize: 10, color: Color(0xFF888888), letterSpacing: 1.5)),
        const SizedBox(width: 12),
        Expanded(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0x33C9A84C)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int?>(
              value: _refVpIdx,
              isExpanded: true,
              isDense: true,
              dropdownColor: const Color(0xFF14142A),
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFC9A84C), size: 18),
              style: const TextStyle(fontSize: 12, color: Color(0xFFE8E0D0)),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('📡', style: TextStyle(fontSize: 13)),
                    SizedBox(width: 6),
                    Text('現在地（地図中心）', style: TextStyle(fontSize: 12, color: Color(0xFFE8E0D0))),
                  ]),
                ),
                for (int i = 0; i < _vpSlots.length; i++)
                  DropdownMenuItem<int?>(
                    value: i,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(_vpSlots[i].icon, style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 6),
                      Flexible(child: Text(_vpSlots[i].name,
                          style: const TextStyle(fontSize: 12, color: Color(0xFFE8E0D0)),
                          overflow: TextOverflow.ellipsis)),
                    ]),
                  ),
              ],
              onChanged: (v) => setState(() => _refVpIdx = v),
            ),
          ),
        )),
      ]),
    );
  }

  /// カテゴリ別スコア表示切替（5つ：癒し/金運/恋愛/仕事/話す）
  /// 未選択 = 総合スコア。アクティブなチップを再タップで未選択に戻る。
  Widget _buildCategorySelector() {
    const cats = ['healing', 'money', 'love', 'work', 'communication'];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      // 一覧との区切り線
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x22C9A84C))),
      ),
      child: Row(children: [
        for (final c in cats) ...[
          Expanded(child: GestureDetector(
            onTap: () => setState(() {
              _selectedCategory = _selectedCategory == c ? null : c;
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _selectedCategory == c
                      ? (categoryColors[c] ?? const Color(0xFFE8E0D0))
                      : const Color(0x1FFFFFFF),
                ),
                color: _selectedCategory == c
                    ? (categoryColors[c] ?? const Color(0xFFE8E0D0)).withAlpha(26)
                    : Colors.transparent,
              ),
              child: Center(child: Text(
                categoryLabels[c] ?? c,
                style: TextStyle(
                  fontSize: 11,
                  color: _selectedCategory == c
                      ? (categoryColors[c] ?? const Color(0xFFE8E0D0))
                      : const Color(0xFF666666),
                ),
              )),
            ),
          )),
          if (c != cats.last) const SizedBox(width: 4),
        ],
      ]),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('🗺', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 14),
        const Text('登録された拠点はまだありません',
            style: TextStyle(fontSize: 12, color: Color(0xFF777777))),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _addCurrent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0x1FC9A84C),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x66C9A84C)),
            ),
            child: const Text('📍 現在地を登録',
                style: TextStyle(fontSize: 11, color: Color(0xFFC9A84C), letterSpacing: 1)),
          ),
        ),
      ]),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _slots.length,
      separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0x11FFFFFF)),
      itemBuilder: (ctx, i) => _buildRow(i),
    );
  }

  Widget _buildRow(int i) {
    final s = _slots[i];
    final stats = _statsFor(s);
    final dirJp = dir16JP[stats.dir] ?? stats.dir;

    return InkWell(
      onTap: () {
        widget.onSelectSlot?.call(s);
        Navigator.of(context).maybePop();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Text(s.icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(s.name,
                  style: const TextStyle(fontSize: 13, color: Color(0xFFE8E0D0), fontWeight: FontWeight.w600),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                Text('$dirJp方位',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF999999))),
                const SizedBox(width: 8),
                Text('${_fmtKm(stats.km)} km',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF666666))),
              ]),
              const SizedBox(height: 4),
              _scoreBar(stats.score),
            ],
          )),
          const SizedBox(width: 8),
          // 右端 40px の固定枠 — HOME 行は HOME バッジ、他行は ⋯ メニュー。
          // 全行同じ幅にすることでスコアバーの長さも揃う。
          SizedBox(
            width: 40,
            child: Center(child: s.isHome
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0x33F9D976),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('HOME',
                      style: TextStyle(fontSize: 8, color: Color(0xFFF9D976), letterSpacing: 1)),
                )
              : PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, color: Color(0xFF888888), size: 18),
                  color: const Color(0xFF14142A),
                  onSelected: (v) async {
                    if (v == 'rename') await _rename(i);
                    if (v == 'delete') await _delete(i);
                  },
                  itemBuilder: (ctx) => const [
                    PopupMenuItem(value: 'rename', child: Text('✏ 名称変更', style: TextStyle(color: Color(0xFFE8E0D0), fontSize: 12))),
                    PopupMenuItem(value: 'delete', child: Text('🗑 削除', style: TextStyle(color: Color(0xFFFF6B6B), fontSize: 12))),
                  ],
                )),
          ),
        ]),
      ),
    );
  }

  Widget _scoreBar(double score) {
    // score 範囲: おおよそ -5..+10 程度。正規化のために active map の max で割る。
    final maxScore = max(1.0, _activeScoreMap.values.fold<double>(0, (a, b) => b > a ? b : a));
    final ratio = (score / maxScore).clamp(0.0, 1.0);
    return Row(children: [
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
                gradient: const LinearGradient(
                  colors: [Color(0xFFC9A84C), Color(0xFFF6BD60)],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      )),
      const SizedBox(width: 8),
      SizedBox(
        width: 36,
        child: Text(score.toStringAsFixed(1),
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 10, color: Color(0xFFC9A84C), fontWeight: FontWeight.w600)),
      ),
    ]);
  }

  String _fmtKm(double km) {
    if (km < 10) return km.toStringAsFixed(1);
    return km.toStringAsFixed(0);
  }
}

class _SlotStats {
  final String dir;
  final double score;
  final String? fortune;
  final double km;
  _SlotStats({required this.dir, required this.score, this.fortune, required this.km});
}
