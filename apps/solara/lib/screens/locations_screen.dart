import 'dart:math';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../utils/solara_storage.dart';
import '../widgets/info_popup.dart';
import '../widgets/no_profile_guide.dart';
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
  // VIEWPOINT プルダウン用に VIEWPOINT スロットも読み込む。
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

  /// VIEWPOINT = 選択中 VP スロットの座標、未選択なら widget.center（現在の地図中心）
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

  // 日付選択の許容範囲（showSolaraDatePicker と同じ）: 今日−10年 〜 今日+20年。
  // ローカル DateTime (JST 0:00) で持つ。DateTime.utc(...) で構築すると
  // JST の年月日が UTC として再解釈され、9 時間ズレた境界になってしまう
  // (JST 0..8 時帯で日付が 1 日早く弾かれる)。
  DateTime get _dateMin {
    final n = DateTime.now();
    return DateTime(n.year - 10, n.month, n.day);
  }
  DateTime get _dateMax {
    final n = DateTime.now();
    return DateTime(n.year + 20, n.month, n.day);
  }

  /// 表示用の現在の選択日時 (null なら今日 + 現在時刻)。
  /// 2026-05-08: 時刻表示対応のため UTC noon → DateTime.now().toUtc() に変更。
  /// これにより _displayDate.toLocal().hour が現在時刻 (live) を反映する。
  DateTime get _displayDate {
    final d = _selectedDate;
    if (d != null) return d;
    return DateTime.now().toUtc();
  }

  /// 現在表示中のローカル時刻 (0..23)
  int get _displayHourLocal => _displayDate.toLocal().hour;

  /// y/m/d オフセットで日付を移動。範囲外はクランプ。
  /// 年月日抽出はローカル (.toLocal()) 基準で行う。UTC オブジェクトの
  /// .year/.month/.day を直接読むと JST 0..8 時帯で 1 日ズレる。
  Future<void> _shiftDate({int years = 0, int months = 0, int days = 0}) async {
    final base = _displayDate.toLocal();
    int newY = base.year + years;
    int newM = base.month + months;
    int newD = (years != 0 || months != 0) ? base.day : base.day + days;
    await _setYmd(newY, newM, newD);
  }

  /// 年月日を絶対値で指定（手入力用）。月の最大日や年範囲は内部でクランプ。
  /// 時刻部分は _displayHourLocal を維持。
  Future<void> _setYmd(int year, int month, int day) async {
    int newY = year;
    int newM = month;
    while (newM < 1) { newM += 12; newY -= 1; }
    while (newM > 12) { newM -= 12; newY += 1; }
    final daysInMonth = DateUtils.getDaysInMonth(newY, newM);
    int newD = day.clamp(1, daysInMonth);
    // 既存の時刻 (local) を維持しつつ年月日のみ差し替え。
    final curHour = _displayHourLocal;
    // 比較・clamp はローカル基準で統一 (_dateMin/Max もローカル)。
    // 以前は newLocal.toUtc() を UTC の min/max と比較していたため、
    // JST 0..8 時帯で境界がズレていた。
    var newLocal = DateTime(newY, newM, newD, curHour, 0, 0);
    if (newLocal.isBefore(_dateMin)) newLocal = _dateMin;
    if (newLocal.isAfter(_dateMax)) newLocal = _dateMax;
    await _setDate(newLocal.toUtc());
  }

  /// 時刻 (local hour 0..23) を絶対値で指定。年月日は維持。
  Future<void> _setHour(int hour) async {
    final clamped = hour.clamp(0, 23);
    final cur = _displayDate.toLocal();
    final newLocal = DateTime(cur.year, cur.month, cur.day, clamped, 0, 0);
    await _setDate(newLocal.toUtc());
  }

  /// 時刻 (local hour) をオフセットで移動。0 ⇄ 23 でラップ。
  Future<void> _shiftHour(int delta) async {
    final cur = _displayHourLocal;
    final next = ((cur + delta) % 24 + 24) % 24;
    await _setHour(next);
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
    // 現住所が登録されていればハウス計算は現住所ベース(リロケーション)。
    final useRelocate = !(p.homeLat == 0 && p.homeLng == 0);
    final chart = await fetchChart(
      birthDate: p.birthDate,
      birthTime: p.birthTime,
      birthLat: p.birthLat,
      birthLng: p.birthLng,
      birthTz: p.birthTz,
      birthTzName: p.birthTzName,
      targetDate: utcNoon,
      relocateLat: useRelocate ? p.homeLat : null,
      relocateLng: useRelocate ? p.homeLng : null,
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
            const SizedBox(width: 6),
            // ❓ help_outline: 画面の使い方説明 popup
            GestureDetector(
              onTap: () => _showLocationsUsageGuide(context),
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.help_outline,
                    size: 16, color: Color(0xCCAAAAAA)),
              ),
            ),
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
          Expanded(child: NoProfileGuide(onNavigateToSanctuary: widget.onNavigateToSanctuary))
        else ...[
          // 操作メニュー（ヘッダ直下に配置）
          LocationsDateStepper(
            displayDate: _displayDate,
            displayHour: _displayHourLocal,
            dateMin: _dateMin,
            dateMax: _dateMax,
            onResetToToday: _selectedDate != null ? _resetToday : null,
            refetching: _refetchingDate,
            onShift: ({int years = 0, int months = 0, int days = 0}) =>
                _shiftDate(years: years, months: months, days: days),
            onSetYmd: _setYmd,
            onShiftHour: _shiftHour,
            onSetHour: _setHour,
          ),
          _buildRefPointSelector(),
          _buildCategorySelector(),
          Expanded(child: _slots.isEmpty ? _emptyState() : _buildList()),
        ],
      ]),
      ),
    );
  }

  /// VIEWPOINT プルダウン：現在地 + VIEWPOINT スロット一覧
  Widget _buildRefPointSelector() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0x22C9A84C))),
      ),
      child: Row(children: [
        const Text('VIEWPOINT',
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
              // 2026-05-08: スロットラベルを住所→カテゴリ名に統一
              // (Daily Transit / 検索結果一覧と同じ規則)
              // - 地図中心 (value=null): 「地図中心」(短縮、検索結果と統一)
              // - isHome=true VPSlot → 「現住所」(固定)
              // - その他 VPSlot → slot.name (空なら VP{n})
              // 全 Text を Flexible + ellipsis でラップして RIGHT OVERFLOW 防止
              // (1.5x フォント拡大時に '現在地（地図中心）' が dropdown 幅を超えていた)
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Row(mainAxisSize: MainAxisSize.min, children: const [
                    Text('📡', style: TextStyle(fontSize: 13)),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '地図中心',
                        style: TextStyle(
                            fontSize: 12, color: Color(0xFFE8E0D0)),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ]),
                ),
                for (int i = 0; i < _vpSlots.length; i++)
                  DropdownMenuItem<int?>(
                    value: i,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(_vpSlots[i].icon, style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _vpSlots[i].isHome
                              ? '現住所'
                              : (_vpSlots[i].name.isEmpty
                                  ? 'VP${i + 1}'
                                  : _vpSlots[i].name),
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFFE8E0D0)),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
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
          Flexible(
            child: Text(s.icon,
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: const TextStyle(fontSize: 22)),
          ),
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
                Flexible(
                  child: Text('$dirJp方位',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF999999))),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text('${_fmtKm(stats.km)} km',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF666666))),
                ),
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

/// LOCATIONS 画面の使い方 popup (ヘッダの ❓ ボタンから開く)。
/// 登録した VIEWPOINT 一覧画面の各機能を概観する。
void _showLocationsUsageGuide(BuildContext context) {
  showInfoPopup(
    context: context,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'LOCATIONS の使い方',
          style: TextStyle(
              color: Color(0xFFC9A84C), fontSize: 14, letterSpacing: 1),
        ),
        SizedBox(height: 10),
        Text(
          'あなたが登録したVIEWPOINT（視点の中心点）から\n'
          'みた、LOCATION（登録地点）のエネルギーを\n'
          '一覧で確認できます。\n'
          '気になるところをLOCATIONとして登録しておけば、\n'
          '一目で今日のエネルギーを知る事ができます。\n\n'
          'よく行く場所を登録しておくと、\n'
          '今日この公園は癒しスコアが高い、\n'
          '今日このカフェは恋愛スコアが高い、\n'
          'というように、登録地ごとの今日のエネルギー\n'
          '強弱が一目で分かる便利機能です。',
          style: TextStyle(
              color: Color(0xFFE8E0D0),
              fontSize: 13,
              height: 1.6,
              fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 14),
        Text(
          '【日付・時刻】',
          style: TextStyle(
              color: Color(0xFFC9A84C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
        ),
        SizedBox(height: 4),
        Text(
          '上部の「日付」と「時刻」を変更すると、その時点の\n'
          'スコアで再計算されます。「今日に戻す」ボタンで\n'
          '現在に戻せます。',
          style: TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
        ),
        SizedBox(height: 10),
        Text(
          '【VIEWPOINT 切替】',
          style: TextStyle(
              color: Color(0xFFC9A84C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
        ),
        SizedBox(height: 4),
        Text(
          '「VIEWPOINT」プルダウンで、距離・方位スコアの\n'
          '基準地点を切替えられます。\n'
          '・地図中心 (現在地) ・現住所 ・登録した VIEWPOINT\n'
          'を選択可能。',
          style: TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
        ),
        SizedBox(height: 10),
        Text(
          '【カテゴリ切替】',
          style: TextStyle(
              color: Color(0xFFC9A84C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
        ),
        SizedBox(height: 4),
        Text(
          '癒し / 豊かさ / 恋愛 / 仕事 / 話す をタップで切替えると、\n'
          'そのカテゴリのスコアで地点が再ランクされます。\n'
          'もう一度同じカテゴリをタップで未選択 (= 総合スコア表示) に\n'
          '戻ります。',
          style: TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
        ),
        SizedBox(height: 10),
        Text(
          '【地点の登録】',
          style: TextStyle(
              color: Color(0xFFC9A84C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
        ),
        SizedBox(height: 4),
        Text(
          'Map 画面の左側 📍 ボタンから、地図中央の地点を\n'
          'VIEWPOINT と LOCATION のどちらにも保存できます。\n'
          '保存した地点は名前変更や削除も可能です。',
          style: TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
        ),
      ],
    ),
  );
}
