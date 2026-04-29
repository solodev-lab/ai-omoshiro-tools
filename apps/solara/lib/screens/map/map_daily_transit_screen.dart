// ============================================================
// MapDailyTransitScreen — F1-c フル UI
//
// F1-c (2026-04-29 オーナー設計):
//   最上部: 今日のトップカテゴリバナー（カテゴリアイコン + ラベル + 一行解説）
//   メイン: 10惑星 × 4アングル(ASC/MC/DSC/IC) のタイムライン
//   閉じるボタン: 右上 → 親で onClose() 経由で右上バッジ位置にフェード復帰
//
// データ:
//   /astro/daily-transits を fetchDailyTransits() で取得
//   観測点は親から渡される LatLng (現状 _center、将来は home 優先で改善予定)
// ============================================================
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../theme/solara_colors.dart';
import '../../utils/astro_glossary.dart';
import '../../utils/daily_transits_api.dart';
import '../../utils/solara_storage.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/dominant_fortune_overlay.dart' show DominantFortuneKind;
import '../../widgets/glass_panel.dart';
import 'daily_transit_data.dart';
import 'map_aspect_chip.dart';
import 'map_constants.dart';
import 'map_vp_panel.dart' show VPSlot;

class MapDailyTransitScreen extends StatefulWidget {
  final DominantFortuneKind? topCategory;
  /// 出生地座標 (常に有効)。VIEWPOINT 切替の選択肢の1つ「出生地」として使う。
  final LatLng birthLocation;
  /// 出生地名 (例: '東京都'). 空ならデフォルト「出生地」を表示。
  final String birthLocationName;
  /// VIEWPOINT スロット (home + 登録地、最大5件)。home は先頭。
  final List<VPSlot> vpSlots;
  /// V2: natal 黄経マップ。指定時、各イベントにアスペクト context が表示される。
  final Map<String, double>? natal;
  final VoidCallback onClose;

  const MapDailyTransitScreen({
    super.key,
    required this.topCategory,
    required this.birthLocation,
    this.birthLocationName = '',
    this.vpSlots = const [],
    this.natal,
    required this.onClose,
  });

  @override
  State<MapDailyTransitScreen> createState() => _MapDailyTransitScreenState();
}

/// タブ識別子。
enum _DayTab { today, tomorrow }

// データ定義は daily_transit_data.dart に分離 (2026-04-30)。

class _MapDailyTransitScreenState extends State<MapDailyTransitScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;

  // (tab, vpIndex) 別キャッシュ。VIEWPOINT 切替で再 fetch を避ける。
  // key = '${tab.name}|$vpIndex'  (-1 = 出生地、0+ = vpSlots index)
  final Map<String, DailyTransitsResult> _cache = {};
  final Map<String, bool> _failed = {};
  final Map<String, bool> _loading = {};

  _DayTab _activeTab = _DayTab.today;

  // VIEWPOINT 選択 index (-1 = 出生地、0+ = widget.vpSlots index)
  // 初期値は initState で「自宅 (vpSlots[0].isHome) → 出生地」の順で決定
  int _vpIndex = -1;

  // フィルタ初期値: アングルは ASC+MC（地表より上=顕在に入る相）
  // カテゴリは all（全カテゴリ）。情報過多回避でアングルのみ既定で絞る。
  AngleFilter _angleFilter = AngleFilter.ascMc;
  String _categoryFilter = 'all';

  // Sanctuary で設定された orb 値（読込が完了するまで null）
  Map<String, double>? _orbs;

  /// 現在選択中の VIEWPOINT ラベル。
  String get _currentLocationLabel {
    if (_vpIndex >= 0 && _vpIndex < widget.vpSlots.length) {
      final s = widget.vpSlots[_vpIndex];
      return s.name.isEmpty ? 'VP${_vpIndex + 1}' : s.name;
    }
    return widget.birthLocationName.isNotEmpty
        ? widget.birthLocationName
        : '出生地';
  }

  /// キャッシュ・状態管理用のキー。
  String _cacheKey(_DayTab tab, int vpIndex) => '${tab.name}|$vpIndex';

  /// 初期 VIEWPOINT を決定する。
  /// オーナールール (2026-04-30):
  ///   1. 自宅 (vpSlots[0].isHome) が登録済みなら 0
  ///   2. それ以外は出生地 (-1)
  int _resolveInitialVpIndex() {
    if (widget.vpSlots.isNotEmpty && widget.vpSlots[0].isHome) return 0;
    return -1;
  }

  @override
  void initState() {
    super.initState();
    _vpIndex = _resolveInitialVpIndex();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();
    _loadOrbsAndStart();
  }

  Future<void> _loadOrbsAndStart() async {
    _orbs = await SolaraStorage.loadOrbSettings();
    if (!mounted) return;
    _loadTab(_DayTab.today, _vpIndex);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  /// タブの開始時刻（local 0:00 を UTC 化）を返す。
  /// 「本日」= 今日のローカル 00:00、「明日」= 明日のローカル 00:00。
  DateTime _tabStartTime(_DayTab tab) {
    final now = DateTime.now();
    final base = DateTime(now.year, now.month, now.day);
    return tab == _DayTab.today ? base : base.add(const Duration(days: 1));
  }

  /// 指定 (tab, vpIndex) のデータを取得する。キャッシュ済みなら何もしない。
  Future<void> _loadTab(_DayTab tab, int vpIndex) async {
    final key = _cacheKey(tab, vpIndex);
    if (_cache.containsKey(key) || (_loading[key] ?? false)) return;
    // 取得用の location 確定 (vpIndex に応じて切替)
    final loc = (vpIndex >= 0 && vpIndex < widget.vpSlots.length)
        ? LatLng(
            widget.vpSlots[vpIndex].lat, widget.vpSlots[vpIndex].lng)
        : widget.birthLocation;
    setState(() {
      _loading[key] = true;
      _failed[key] = false;
    });
    final result = await fetchDailyTransits(
      lat: loc.latitude,
      lng: loc.longitude,
      startTime: _tabStartTime(tab),
      natal: widget.natal,
      orbs: _orbs,
    );
    if (!mounted) return;
    setState(() {
      _loading[key] = false;
      if (result != null) {
        _cache[key] = result;
      } else {
        _failed[key] = true;
      }
    });
  }

  void _selectTab(_DayTab tab) {
    if (_activeTab == tab) return;
    setState(() => _activeTab = tab);
    _loadTab(tab, _vpIndex); // 未取得なら lazy load
  }

  /// VIEWPOINT dropdown 切替時。両方のタブを必要に応じて再読込。
  void _selectVp(int newIndex) {
    if (newIndex == _vpIndex) return;
    setState(() => _vpIndex = newIndex);
    // active タブ優先で fetch、もう片方は表示時に lazy load
    _loadTab(_activeTab, newIndex);
  }

  Future<void> _close() async {
    await _fadeCtrl.reverse();
    if (!mounted) return;
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final key = _cacheKey(_activeTab, _vpIndex);
    final cached = _cache[key];
    final isLoading = _loading[key] ?? false;
    final hasFailed = _failed[key] ?? false;
    return FadeTransition(
      opacity: _fadeCtrl,
      child: Container(
        color: const Color(0xEE0A0A14),
        child: SafeArea(
          child: Column(
            children: [
              _Header(
                topCategory: widget.topCategory,
                locationLabel: _currentLocationLabel,
                vpSlots: widget.vpSlots,
                vpIndex: _vpIndex,
                birthLocationName: widget.birthLocationName,
                onVpChanged: _selectVp,
                onClose: _close,
              ),
              _DayTabBar(
                active: _activeTab,
                onSelect: _selectTab,
                angleFilter: _angleFilter,
                categoryFilter: _categoryFilter,
                onAngleChanged: (v) => setState(() => _angleFilter = v),
                onCategoryChanged: (v) => setState(() => _categoryFilter = v),
              ),
              Expanded(
                child: isLoading
                    ? const _LoadingBody()
                    : hasFailed
                        ? _FailedBody(onRetry: () => _loadTab(_activeTab, _vpIndex))
                        : cached != null
                            ? _TimelineBody(
                                result: cached,
                                angleFilter: _angleFilter,
                                categoryFilter: _categoryFilter,
                              )
                            : const _LoadingBody(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── DayTabBar （本日 / 明日 切替 + フィルタ） ──

class _DayTabBar extends StatelessWidget {
  final _DayTab active;
  final ValueChanged<_DayTab> onSelect;
  final AngleFilter angleFilter;
  final String categoryFilter;
  final ValueChanged<AngleFilter> onAngleChanged;
  final ValueChanged<String> onCategoryChanged;

  const _DayTabBar({
    required this.active,
    required this.onSelect,
    required this.angleFilter,
    required this.categoryFilter,
    required this.onAngleChanged,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x14FFFFFF))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 行1: 本日/明日 + カテゴリフィルタ ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _tabBtn(_DayTab.today, '本日'),
                  const SizedBox(width: 6),
                  _tabBtn(_DayTab.tomorrow, '明日'),
                  const SizedBox(width: 14),
                  Container(
                    width: 1, height: 16,
                    color: const Color(0x22FFFFFF),
                  ),
                  const SizedBox(width: 14),
                  // カテゴリフィルタ (初期 all)
                  _categoryDropdown(),
                ],
              ),
            ),
          ),
          // ── 行2: ASC+MC フィルタ + i + アングル説明文 ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
            child: Row(
              children: [
                _angleDropdown(),
                const SizedBox(width: 2),
                // i アイコン: 4アングル詳細解説を popup で開示
                Builder(
                  builder: (ctx) => GestureDetector(
                    onTap: () => showAstroGlossaryDialog(
                        ctx, 'transit_angles'),
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.info_outline,
                          size: 14, color: Color(0xCCAAAAAA)),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    angleFilterShortMeaning[angleFilter] ?? '',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF888888),
                      height: 1.5,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── 行3: カテゴリ別行動指針 (カテゴリが all 以外のとき表示) ──
          if (categoryFilter != 'all' &&
              categoryFilterTips.containsKey(categoryFilter))
            _buildCategoryTips(categoryFilter, angleFilter),
        ],
      ),
    );
  }

  Widget _buildCategoryTips(String categoryKey, AngleFilter angleFilter) {
    final tipsData = categoryFilterTips[categoryKey];
    if (tipsData == null) return const SizedBox.shrink();
    final color = categoryColors[categoryKey] ?? SolaraColors.solaraGoldLight;

    // アングル相に応じて tips を切替。
    // ASC+MC = 外向き、DSC+IC = 内向き、全角度 = ASC+MC を既定表示し
    // 「両方の相が混在」の旨をヘッドラインに添える。
    final List<String> tips;
    final String subLabel;
    switch (angleFilter) {
      case AngleFilter.ascMc:
        tips = tipsData.tipsAscMc;
        subLabel = '外向きの相';
        break;
      case AngleFilter.dscIc:
        tips = tipsData.tipsDscIc;
        subLabel = '内向きの相';
        break;
      case AngleFilter.all:
        tips = tipsData.tipsAscMc;
        subLabel = '外向き＋内向きの相が混在';
        break;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(60)),
        color: color.withAlpha(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  tipsData.headline,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: color.withAlpha(110)),
                ),
                child: Text(
                  subLabel,
                  style: TextStyle(
                    fontSize: 9,
                    color: color,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // 「おすすめ行動の例（参考）」サブヘッダー + i アイコン
          // tips が「指示」ではなく「ユーザー自身の動きを考える参考の例示」である
          // ことを明示し、i ボタンで Solara の姿勢・使い方を popup で説明。
          Builder(
            builder: (ctx) => Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'おすすめ行動の例（参考）',
                  style: TextStyle(
                    fontSize: 9,
                    color: color.withAlpha(200),
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: () => showAstroGlossaryDialog(
                      ctx, 'category_tips_intent'),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.info_outline,
                      size: 12,
                      color: color.withAlpha(180),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          for (final t in tips)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ',
                      style: TextStyle(
                          fontSize: 10, color: Color(0xFF888888))),
                  Expanded(
                    child: Text(
                      t,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFFAAAAAA),
                        height: 1.5,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 6),
          // 注記: 他の動きも自由に考える
          Text(
            '※ 他の行動も、この例を参考に自由に考えてみてください',
            style: TextStyle(
              fontSize: 9,
              color: const Color(0xFF777777),
              fontStyle: FontStyle.italic,
              height: 1.4,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabBtn(_DayTab tab, String label) {
    final isActive = active == tab;
    return GestureDetector(
      onTap: () => onSelect(tab),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? SolaraColors.solaraGoldLight
                : const Color(0x33FFFFFF),
          ),
          color: isActive
              ? SolaraColors.solaraGoldLight.withValues(alpha: 0.10)
              : Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive
                ? SolaraColors.solaraGoldLight
                : const Color(0xFF888888),
            letterSpacing: 1.0,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _angleDropdown() {
    return _filterPill(
      child: DropdownButton<AngleFilter>(
        value: angleFilter,
        underline: const SizedBox.shrink(),
        isDense: true,
        dropdownColor: const Color(0xF20F0F1E),
        iconEnabledColor: SolaraColors.solaraGoldLight,
        iconSize: 16,
        style: const TextStyle(
          fontSize: 11,
          color: SolaraColors.solaraGoldLight,
          letterSpacing: 0.5,
        ),
        items: [
          for (final f in AngleFilter.values)
            DropdownMenuItem<AngleFilter>(
              value: f,
              child: Text(
                angleFilterLabels[f] ?? f.name,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFFE8E0D0),
                ),
              ),
            ),
        ],
        onChanged: (v) {
          if (v != null) onAngleChanged(v);
        },
      ),
    );
  }

  Widget _categoryDropdown() {
    final entries = <MapEntry<String, String>>[];
    // 「全カテゴリ」を先頭に固定
    entries.add(const MapEntry('all', '全カテゴリ'));
    for (final k in categoryPlanetSets.keys) {
      if (k == 'all') continue;
      entries.add(MapEntry(k, categoryLabels[k] ?? k));
    }
    return _filterPill(
      child: DropdownButton<String>(
        value: categoryFilter,
        underline: const SizedBox.shrink(),
        isDense: true,
        dropdownColor: const Color(0xF20F0F1E),
        iconEnabledColor: SolaraColors.solaraGoldLight,
        iconSize: 16,
        style: const TextStyle(
          fontSize: 11,
          color: SolaraColors.solaraGoldLight,
          letterSpacing: 0.5,
        ),
        items: [
          for (final e in entries)
            DropdownMenuItem<String>(
              value: e.key,
              child: Text(
                e.value,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFFE8E0D0),
                ),
              ),
            ),
        ],
        onChanged: (v) {
          if (v != null) onCategoryChanged(v);
        },
      ),
    );
  }

  Widget _filterPill({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x33C9A84C)),
      ),
      child: child,
    );
  }
}

// ── Header（トップカテゴリバナー + 閉じる） ──

class _Header extends StatelessWidget {
  final DominantFortuneKind? topCategory;
  final String locationLabel;
  final List<VPSlot> vpSlots;
  final int vpIndex;
  final String birthLocationName;
  final ValueChanged<int> onVpChanged;
  final VoidCallback onClose;

  const _Header({
    required this.topCategory,
    required this.locationLabel,
    required this.vpSlots,
    required this.vpIndex,
    required this.birthLocationName,
    required this.onVpChanged,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final catKey = _categoryKey(topCategory);
    final color = categoryColors[catKey] ?? SolaraColors.solaraGoldLight;
    final label = categoryLabels[catKey] ?? 'TOP';
    final iconKind = topCategory?.toCategoryIcon() ?? CategoryIconKind.all;
    final tagline = _tagline(topCategory);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: color.withValues(alpha: 0.4)),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.08),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            alignment: Alignment.center,
            child: CategoryIcon(kind: iconKind, size: 26, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '今日の TOP — $label',
                  style: TextStyle(
                    fontSize: 14,
                    color: color,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  tagline,
                  style: const TextStyle(
                    fontSize: 11,
                    color: SolaraColors.textSecondary,
                    height: 1.4,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                _buildVpDropdown(),
              ],
            ),
          ),
          // i アイコン: 「なぜこのカテゴリが今日の TOP か」の技術的説明
          // 5カテゴリ × 担当惑星 × ペア倍率の集計ロジックを popup で開示。
          GestureDetector(
            onTap: () =>
                showAstroGlossaryDialog(context, 'top_category_logic'),
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child:
                  Icon(Icons.info_outline, size: 18, color: Color(0xCCAAAAAA)),
            ),
          ),
          // ✕ 閉じる
          GestureDetector(
            onTap: onClose,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.close, color: Color(0xFFAAAAAA), size: 22),
            ),
          ),
        ],
      ),
    );
  }

  String _categoryKey(DominantFortuneKind? cat) {
    if (cat == null) return 'all';
    switch (cat) {
      case DominantFortuneKind.love: return 'love';
      case DominantFortuneKind.money: return 'money';
      case DominantFortuneKind.work: return 'work';
      case DominantFortuneKind.healing: return 'healing';
      case DominantFortuneKind.communication: return 'communication';
    }
  }

  String _tagline(DominantFortuneKind? cat) {
    if (cat == null) return '今日の動きを確認しましょう';
    switch (cat) {
      case DominantFortuneKind.love:
        return '関係性のエネルギーが多面的に動く一日';
      case DominantFortuneKind.money:
        return '物質的な豊かさのエネルギーが流れる一日';
      case DominantFortuneKind.work:
        return '社会的役割のエネルギーが動く一日';
      case DominantFortuneKind.healing:
        return '内省と統合のエネルギーが流れる一日';
      case DominantFortuneKind.communication:
        return '対話と知性のエネルギーが動く一日';
    }
  }

  /// VIEWPOINT dropdown。
  /// 選択肢: 出生地（-1） + 各VPスロット（0+）。
  /// 場所が変わると Daily Transit の通過時刻が再計算される。
  Widget _buildVpDropdown() {
    final birthName =
        birthLocationName.isEmpty ? '出生地' : birthLocationName;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.place, size: 12, color: Color(0xFF888888)),
        const SizedBox(width: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0x33C9A84C)),
          ),
          child: DropdownButton<int>(
            value: vpIndex,
            underline: const SizedBox.shrink(),
            isDense: true,
            dropdownColor: const Color(0xF20F0F1E),
            iconEnabledColor: const Color(0xFFC9A84C),
            iconSize: 14,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFFE8E0D0),
            ),
            items: [
              DropdownMenuItem<int>(
                value: -1,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🌟', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 4),
                    Text(birthName,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFE8E0D0),
                        )),
                  ],
                ),
              ),
              for (int i = 0; i < vpSlots.length; i++)
                DropdownMenuItem<int>(
                  value: i,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(vpSlots[i].icon,
                          style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        vpSlots[i].name.isEmpty
                            ? 'VP${i + 1}'
                            : vpSlots[i].name,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFE8E0D0),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            onChanged: (v) {
              if (v != null) onVpChanged(v);
            },
          ),
        ),
      ],
    );
  }
}

// ── Loading / Failed states ──

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28, height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: SolaraColors.solaraGoldLight,
            ),
          ),
          SizedBox(height: 14),
          Text(
            '惑星の動きを読み取っています',
            style: TextStyle(
              fontSize: 11,
              color: SolaraColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _FailedBody extends StatelessWidget {
  final VoidCallback onRetry;
  const _FailedBody({required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, color: Color(0xFF666666), size: 32),
          const SizedBox(height: 10),
          const Text(
            'データの取得に失敗しました',
            style: TextStyle(
              fontSize: 12,
              color: SolaraColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: SolaraColors.solaraGoldLight),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'もう一度',
                style: TextStyle(
                  fontSize: 11,
                  color: SolaraColors.solaraGoldLight,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Timeline ──

class _TimelineBody extends StatelessWidget {
  final DailyTransitsResult result;
  final AngleFilter angleFilter;
  final String categoryFilter;

  const _TimelineBody({
    required this.result,
    required this.angleFilter,
    required this.categoryFilter,
  });

  @override
  Widget build(BuildContext context) {
    // フィルタ適用 (アングル AND カテゴリ)
    final allowedAngles = angleFilterSets[angleFilter] ?? const {};
    final allowedPlanets = categoryPlanetSets[categoryFilter] ?? const {};
    final allEvents = result.flatTimeline();
    final events = allEvents
        .where((e) =>
            allowedAngles.contains(e.event.angle) &&
            allowedPlanets.contains(e.planet))
        .toList();

    if (allEvents.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Text(
            '今日は静かな日。\n特別な動きは見えません。',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: SolaraColors.textSecondary,
              height: 1.7,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
    }
    if (events.isEmpty) {
      // 全データはあるがフィルタで0件 → ユーザーにフィルタ変更を促す
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Text(
            'このフィルタ条件に\n該当するイベントはありません。\nフィルタを変更してください。',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: SolaraColors.textSecondary,
              height: 1.7,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: events.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) => _TimelineRow(
        planetKey: events[i].planet,
        event: events[i].event,
        categoryFilter: categoryFilter,
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final String planetKey;
  final TransitEvent event;
  final String categoryFilter;

  const _TimelineRow({
    required this.planetKey,
    required this.event,
    required this.categoryFilter,
  });

  @override
  Widget build(BuildContext context) {
    final meta = planetMeta[planetKey];
    final planetColor = meta?.color ?? SolaraColors.solaraGoldLight;
    final planetSym = meta?.sym ?? '✦';
    final planetJP = meta?.jp ?? planetKey;
    final localTime = event.time.toLocal();
    final timeStr =
        '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
    final angleLabel = _angleLabel(event.angle);
    final compassLabel = _azimuthToCompass(event.azimuth);

    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 時刻 — 必ず1行（5文字 HH:mm が折り返さないよう固定幅 + 折返し禁止）
              SizedBox(
                width: 64,
                child: Text(
                  timeStr,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: TextStyle(
                    fontSize: 16,
                    color: planetColor,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'monospace',
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // 惑星シンボル
              SizedBox(
                width: 24,
                child: Text(
                  planetSym,
                  style: TextStyle(fontSize: 18, color: planetColor),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 行のタイトル — i アイコン付きでタップ可。
                    // タップで「惑星 × アングル × カテゴリ」の組み合わせ解説を表示
                    // (アングル一般説明はヘッダーの transit_angles 側に集約済み)
                    GestureDetector(
                      onTap: () => _showEventDetailDialog(
                        context,
                        planetKey: planetKey,
                        angle: event.angle,
                        categoryFilter: categoryFilter,
                      ),
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              '$planetJP が$angleLabel通過',
                              style: const TextStyle(
                                fontSize: 13,
                                color: SolaraColors.textPrimary,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.info_outline,
                            size: 14,
                            color: Color(0xCCAAAAAA),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _angleHint(event.angle, compassLabel),
                      style: const TextStyle(
                        fontSize: 10,
                        color: SolaraColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // V2.2: natal アスペクト context（Sanctuary orb 設定で検出された全件）
          // 横スクロールで全部閲覧可能。チップタップで Horo相タブ相当の詳細。
          if (event.aspects.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 88),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (int i = 0; i < event.aspects.length; i++) ...[
                      MapAspectChip(
                          transitPlanet: planetKey,
                          aspect: event.aspects[i]),
                      if (i < event.aspects.length - 1)
                        const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _angleLabel(String angle) {
    switch (angle) {
      case 'ASC': return '東の地平 (ASC)';
      case 'MC': return '天頂 (MC)';
      case 'DSC': return '西の地平 (DSC)';
      case 'IC': return '天底 (IC)';
      default: return angle;
    }
  }

  String _angleHint(String angle, String compass) {
    switch (angle) {
      case 'ASC': return '昇り始める時刻 — $compass の地平に現れる';
      case 'MC': return '最も高くに上る時刻 — $compass の空で頂点';
      case 'DSC': return '沈む時刻 — $compass の地平に降る';
      case 'IC': return '地下を通る時刻 — 内的な動きとして効く';
      default: return '';
    }
  }

  String _azimuthToCompass(double az) {
    // 0=北、90=東、180=南、270=西
    final norm = ((az % 360) + 360) % 360;
    const labels = [
      '北', '北北東', '北東', '東北東',
      '東', '東南東', '南東', '南南東',
      '南', '南南西', '南西', '西南西',
      '西', '西北西', '北西', '北北西',
    ];
    final idx = ((norm + 11.25) ~/ 22.5) % 16;
    return labels[idx];
  }
}

/// 個別イベント i ボタン用ダイアログ。
/// 「惑星 × アングル」の基本意味文 + 「カテゴリ」別の補足文を表示する。
/// テンプレ式 (40 × 5 = 45 パターン) で構成。
void _showEventDetailDialog(
  BuildContext context, {
  required String planetKey,
  required String angle,
  required String categoryFilter,
}) {
  final meta = planetMeta[planetKey];
  final planetJP = meta?.jp ?? planetKey;
  final planetColor = meta?.color ?? SolaraColors.solaraGoldLight;
  final angleUpper = angle.toUpperCase();
  final base = planetAngleBaseText[planetKey]?[angleUpper] ?? '';
  final appendix = (categoryFilter != 'all')
      ? categoryAppendix[categoryFilter]
      : null;
  final title = '$planetJPの$angleUpper通過';

  showDialog<void>(
    context: context,
    barrierColor: const Color(0x99000000),
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
      child: GlassPanel(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        color: planetColor,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(),
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(Icons.close,
                          size: 18, color: Color(0xFFAAAAAA)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (base.isNotEmpty)
                Text(
                  base,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFE8E0D0),
                    height: 1.7,
                    letterSpacing: 0.2,
                  ),
                ),
              if (appendix != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: SolaraColors.solaraGoldLight.withAlpha(80)),
                    color: SolaraColors.solaraGoldLight.withAlpha(15),
                  ),
                  child: Text(
                    appendix,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFCCCCCC),
                      height: 1.7,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

