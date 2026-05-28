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
import '../../widgets/category_icon.dart';
import '../../widgets/dominant_fortune_overlay.dart' show DominantFortuneKind;
import '../../widgets/glass_panel.dart';
import '../../widgets/info_popup.dart';
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

  /// 「🌐 世界規模で見る」フッターリンクのハンドラ。
  /// null なら表示しない。設定すると Daily Transit popup 下部に ACG モード起動
  /// リンクが現れる (2026-05-09: 旧 🌐 サイドボタンの代替動線)。
  final VoidCallback? onEnterAcg;

  /// 「🔮 Stella に相談」フッターリンクのハンドラ (Phase 2-3c、目的起点入口)。
  /// null なら表示しない。設定するとフッターが 2 分割され、ACG モードの隣に
  /// Stella 相談入口が並ぶ (設計: pro_candidates.md §7.2 Stage 1 入口 2)。
  final VoidCallback? onEnterConsultation;

  /// イベント時刻を Map に飛ばすハンドラ (各タイムライン行の地図マーク用)。
  /// null なら地図マーク非表示。
  /// 渡された DateTime はそのイベントの瞬時時刻 (1 分単位)。
  /// Map 側は受け取った時刻をそのまま表示し、step ボタン操作で 10 分刻み grid
  /// に合流する。
  final void Function(DateTime time)? onJumpToTime;

  /// 2026-05-29: popup 初表示時に Header を 1.5s 金色 halo 発光させるフラグ。
  /// 端末日付ベースで 1 日 1 回のみ true、それ以外は false。
  /// 「ここを見て」と意識付けるための一発演出。
  final bool headerGlowOnce;

  const MapDailyTransitScreen({
    super.key,
    required this.topCategory,
    required this.birthLocation,
    this.birthLocationName = '',
    this.vpSlots = const [],
    this.natal,
    required this.onClose,
    this.onEnterAcg,
    this.onEnterConsultation,
    this.onJumpToTime,
    this.headerGlowOnce = false,
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
    // Daily Transit は Worker daily_transits.js の自前デフォルト orb を使う。
    // Sanctuary の Orb 設定は Horoscope 専用で、本画面には連携しない。
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
                glowOnce: widget.headerGlowOnce,
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
                                onJumpToTime: widget.onJumpToTime,
                              )
                            : const _LoadingBody(),
              ),
              // フッター動線 (2026-05-09: ACG / 2026-05-15: + Stella 相談)。
              // 「今日の動き → 世界規模に投影して見る (ACG)」
              //  または 「→ 悩みに合った場所を Stella に相談する」を並べる。
              // POPUP のクローズは親の handler 内 setState でまとめて行う
              // (旧: ここで _close() してフェード途中で切替えると違和感が出る)。
              if (widget.onEnterAcg != null || widget.onEnterConsultation != null)
                _FooterActions(
                  onEnterAcg: widget.onEnterAcg,
                  onEnterConsultation: widget.onEnterConsultation,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Daily Transit popup 下部の動線フッター。
///
/// 2026-05-15: 旧 `_AcgEntryFooter` (full-width ACG リンクのみ) を 2 分割。
/// 左 = ACG モード起動、右 = Stella 相談 (目的起点入口、Phase 2-3c)。
/// 片方のみ非 null の場合はもう片方の領域も空欄表示せず、単独表示にフォールバック。
class _FooterActions extends StatelessWidget {
  final VoidCallback? onEnterAcg;
  final VoidCallback? onEnterConsultation;

  const _FooterActions({
    required this.onEnterAcg,
    required this.onEnterConsultation,
  });

  @override
  Widget build(BuildContext context) {
    final hasAcg = onEnterAcg != null;
    final hasConsult = onEnterConsultation != null;
    final showSplit = hasAcg && hasConsult;

    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0x22C9A84C))),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasAcg)
              Expanded(
                child: _FooterButton(
                  emoji: '🌐',
                  title: '世界規模で見る',
                  subtitle: 'Astro*Carto*Graphy',
                  onTap: onEnterAcg!,
                  compact: showSplit,
                ),
              ),
            if (showSplit)
              const VerticalDivider(
                width: 1,
                thickness: 1,
                color: Color(0x22C9A84C),
              ),
            if (hasConsult)
              Expanded(
                child: _FooterButton(
                  emoji: '🔮',
                  title: 'Stella に相談',
                  subtitle: '悩みから場所を読む',
                  onTap: onEnterConsultation!,
                  compact: showSplit,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// フッター内の 1 つのアクションボタン (絵文字 + タイトル + サブタイトル)。
/// `compact` = 2 分割表示時の縦組レイアウト、それ以外は横一列。
class _FooterButton extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool compact;

  const _FooterButton({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      // 2 分割表示: 縦組 (絵文字 → タイトル → サブタイトル)
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFC9A84C),
                  letterSpacing: 0.4,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0x99C9A84C),
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }
    // 単独表示: 旧 _AcgEntryFooter 互換の横一列レイアウト
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFC9A84C),
                      letterSpacing: 0.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0x99C9A84C),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: Color(0x99C9A84C)),
          ],
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
          // ── 行2: アングルフィルタ + i + アングル説明文 ──
          // 2026-05-08: 個別 4 アングル (ASC/MC/DSC/IC) を追加 + i ボタンが
          // 選択中アングルに応じた専用 popup を開くように変更。
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
            child: Row(
              children: [
                _angleDropdown(),
                const SizedBox(width: 2),
                // i アイコン: 選択中アングル別の詳細解説 (瞬間 + 経過) を表示
                Builder(
                  builder: (ctx) => GestureDetector(
                    onTap: () => _showAngleDetailPopup(ctx, angleFilter),
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
                      fontSize: 13,
                      color: Color(0xFF888888),
                      height: 1.5,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 2026-05-08: カテゴリ別行動指針ボックスは _DayTabBar から
          // _TimelineBody のスクロール領域内 (先頭) に移動。
          // ユーザー要望: フォントサイズ最大時にボックスが固定表示だと
          // タイムラインの可視枠が極端に狭くなる事象を、スクロールで上に
          // 流して可視枠を確保する形に解消。
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
            fontSize: 13,
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
          fontSize: 13,
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
                  fontSize: 13,
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
          fontSize: 13,
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
                  fontSize: 13,
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

class _Header extends StatefulWidget {
  final DominantFortuneKind? topCategory;
  final String locationLabel;
  final List<VPSlot> vpSlots;
  final int vpIndex;
  final String birthLocationName;
  final ValueChanged<int> onVpChanged;
  final VoidCallback onClose;
  /// 2026-05-29: true なら mount 直後に 1.5s 金色 halo を 1 回再生。
  /// 「ここを見て」と意識付けるための一発演出。1 日 1 回のガードは親側
  /// (`_dailyHeaderGlowOnce` + `daily_header_glow` 永続キー) で済む。
  final bool glowOnce;

  const _Header({
    required this.topCategory,
    required this.locationLabel,
    required this.vpSlots,
    required this.vpIndex,
    required this.birthLocationName,
    required this.onVpChanged,
    required this.onClose,
    this.glowOnce = false,
  });

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> with SingleTickerProviderStateMixin {
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowAlpha;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    // 0.0 → 0.55 → 0.55 → 0.0 の台形カーブ (fade-in 0.4s → 維持 0.5s → fade-out 0.6s)。
    _glowAlpha = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 0.55)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 400,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(0.55),
        weight: 500,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.55, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 600,
      ),
    ]).animate(_glowCtrl);

    if (widget.glowOnce) {
      // mount 完了後に再生開始 (initState 中に forward() するとフレーム間で
      // tick が走り setState が連鎖して assertion になる場合がある)。
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _glowCtrl.forward(from: 0);
      });
    }
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // null は 'all' に正規化。enum の .name は宣言名そのままなので
    // DominantFortuneKind.love → 'love' などキー文字列と一致する。
    final catKey = widget.topCategory?.name ?? 'all';
    final color = categoryColors[catKey] ?? SolaraColors.solaraGoldLight;
    final label = categoryLabels[catKey] ?? 'TOP';
    final iconKind = widget.topCategory?.toCategoryIcon() ?? CategoryIconKind.all;
    final tagline = _tagline(widget.topCategory);

    final headerBox = Container(
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
          // 2026-05-12: アイコンサイズを 44→64 (内側 26→40) に拡大。
          // 「今日の TOP」の主役 = カテゴリアイコンなので視認性優先。
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            alignment: Alignment.center,
            child: CategoryIcon(kind: iconKind, size: 40, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2026-05-12: i ボタンを Row 末尾から「今日の TOP — label」行の
                // 末尾に移動。アイコン拡大分のスペースを確保するため。
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        '今日の TOP — $label',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: color,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    // ⓘ info_outline: 「なぜこのカテゴリが今日の TOP か」の技術的説明
                    // 5カテゴリ × 担当惑星 × ペア倍率の集計ロジックを popup で開示。
                    GestureDetector(
                      onTap: () => showAstroGlossaryDialog(
                          context, 'top_category_logic'),
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.info_outline,
                            size: 16, color: Color(0xCCAAAAAA)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  tagline,
                  style: const TextStyle(
                    fontSize: 13,
                    color: SolaraColors.textSecondary,
                    height: 1.4,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                _buildVpDropdownWithGuide(context),
              ],
            ),
          ),
          // ✕ 閉じる
          GestureDetector(
            onTap: widget.onClose,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.close, color: Color(0xFFAAAAAA), size: 22),
            ),
          ),
        ],
      ),
    );

    // 2026-05-29: 初回 1.5s 金色 halo を Stack で重ねる。
    // `clipBehavior: Clip.none` で Header 外周にもグローが滲み出る (Daily チップ
    // halo と同等の演出)。`IgnorePointer` で dropdown 等のタップ判定を邪魔しない。
    return Stack(
      clipBehavior: Clip.none,
      children: [
        headerBox,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _glowCtrl,
              builder: (context, _) {
                final a = _glowAlpha.value;
                if (a <= 0.001) return const SizedBox.shrink();
                const glow = SolaraColors.solaraGoldLight;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: glow.withValues(alpha: a),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: glow.withValues(alpha: a * 0.85),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                      BoxShadow(
                        color: glow.withValues(alpha: a * 0.45),
                        blurRadius: 36,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // _categoryKey は削除。enum.name で代替可能 (audit T2 #6, 2026-05-06)。
  // → final catKey = topCategory?.name ?? 'all';

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
  ///
  /// 2026-05-08: プルダウン左の Icons.place (場所ピン) を Icons.help_outline
  /// (❓) に置換。タップで「今日の動きの読み方」popup を開く。
  ///
  /// 2026-05-08 (#2): プルダウンの表示ラベルを住所文字列ではなく
  /// カテゴリ名 (出生地 / 現住所 / VIEWPOINT 名) に統一。
  /// - スロット -1: 必ず「出生地」(birthLocationName の住所は表示しない)
  /// - isHome=true の VPSlot: 必ず「現住所」(slot.name の住所は表示しない)
  /// - その他の VPSlot: slot.name (登録時の名前)
  /// 横幅を超える長い名前は ellipsis で truncate して RIGHT OVERFLOW 対策。
  Widget _buildVpDropdownWithGuide(BuildContext context) {
    final vpSlots = widget.vpSlots;
    // スロット index → 表示ラベル (カテゴリ名 or VIEWPOINT 名)
    String labelFor(int idx) {
      if (idx < 0) return '出生地';
      if (idx >= vpSlots.length) return 'VP';
      final s = vpSlots[idx];
      if (s.isHome) return '現住所';
      return s.name.isEmpty ? 'VP${idx + 1}' : s.name;
    }

    // スロット index → アイコン文字
    String iconFor(int idx) {
      if (idx < 0) return '🌟';
      if (idx >= vpSlots.length) return '📍';
      return vpSlots[idx].icon;
    }

    Widget itemRow(int idx) {
      // 2026-05-29: RIGHT OVERFLOW 対策 — MainAxisSize.max + Expanded で
      // 親の幅制約を Text に確実に伝播させ ellipsis を効かせる。
      // 旧 (MainAxisSize.min + Flexible) では isExpanded:true の DropdownButton
      // 内で制約が正しく届かず、長い VIEWPOINT 名で overflow していた。
      return Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Text(iconFor(idx), style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              labelFor(idx),
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFE8E0D0),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => showDailyUsageGuidePopup(context),
          behavior: HitTestBehavior.opaque,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: Icon(Icons.help_outline,
                size: 14, color: Color(0xFF888888)),
          ),
        ),
        const SizedBox(width: 2),
        // 親 Row が Header の Expanded 内にいるので、ConstrainedBox で
        // 上限幅を指定して RIGHT OVERFLOW を防ぐ。長 VIEWPOINT 名は
        // Flexible + ellipsis でこの幅内に truncate される。
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 180),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0x33C9A84C)),
            ),
            child: DropdownButton<int>(
              value: widget.vpIndex,
              underline: const SizedBox.shrink(),
              isDense: true,
              isExpanded: true,
              dropdownColor: const Color(0xF20F0F1E),
              iconEnabledColor: const Color(0xFFC9A84C),
              iconSize: 14,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFE8E0D0),
              ),
              items: [
                DropdownMenuItem<int>(value: -1, child: itemRow(-1)),
                for (int i = 0; i < vpSlots.length; i++)
                  DropdownMenuItem<int>(value: i, child: itemRow(i)),
              ],
              onChanged: (v) {
                if (v != null) widget.onVpChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ── カテゴリ別行動指針ボックス ──
// 2026-05-08: _DayTabBar から分離。_TimelineBody の ListView 先頭に
// 配置することで、スクロールに合わせて上に流れていく。フォントサイズ
// 最大時に固定表示で可視枠が圧迫される問題を解消。
class _CategoryTipsBox extends StatelessWidget {
  final String categoryKey;
  final AngleFilter angleFilter;

  const _CategoryTipsBox({
    required this.categoryKey,
    required this.angleFilter,
  });

  @override
  Widget build(BuildContext context) {
    final tipsData = categoryFilterTips[categoryKey];
    if (tipsData == null) return const SizedBox.shrink();
    final color = categoryColors[categoryKey] ?? SolaraColors.solaraGoldLight;

    // アングルに応じて tips を切替。
    // 個別 4 アングル: そのアングル専用の 3 tips を表示
    // 複合相 ASC+MC / DSC+IC: 4 tips を表示
    // 全角度: ASC+MC tips を既定で表示し「混在」をラベルに添える
    final List<String> tips;
    final String subLabel;
    switch (angleFilter) {
      case AngleFilter.asc:
        tips = tipsData.tipsAsc;
        subLabel = angleIndividualSubLabels[AngleFilter.asc] ?? 'ASC';
        break;
      case AngleFilter.mc:
        tips = tipsData.tipsMc;
        subLabel = angleIndividualSubLabels[AngleFilter.mc] ?? 'MC';
        break;
      case AngleFilter.dsc:
        tips = tipsData.tipsDsc;
        subLabel = angleIndividualSubLabels[AngleFilter.dsc] ?? 'DSC';
        break;
      case AngleFilter.ic:
        tips = tipsData.tipsIc;
        subLabel = angleIndividualSubLabels[AngleFilter.ic] ?? 'IC';
        break;
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
      // 横マージンは親 ListView の padding(16) が effective、ここでは 0。
      // 下マージンは ListView.separated の separator が担当するので 0。
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
                    fontSize: 13,
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
                    fontSize: 13,
                    color: color,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // 「おすすめ行動の例（参考）」サブヘッダー + i アイコン
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  'おすすめ行動の例（参考）',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: color.withAlpha(200),
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _showCategoryTipsIntent(
                    context, categoryKey, angleFilter),
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
          const SizedBox(height: 2),
          for (final t in tips)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ',
                      style: TextStyle(
                          fontSize: 13, color: Color(0xFF888888))),
                  Expanded(
                    child: Text(
                      t,
                      style: const TextStyle(
                        fontSize: 13,
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
          const Text(
            '※ 他の行動も、この例を参考に自由に考えてみてください',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF777777),
              fontStyle: FontStyle.italic,
              height: 1.4,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
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
              fontSize: 13,
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
              fontSize: 13,
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
                  fontSize: 13,
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
  /// 行毎の地図マークタップ時のハンドラ。null なら地図マーク非表示。
  final void Function(DateTime time)? onJumpToTime;

  const _TimelineBody({
    required this.result,
    required this.angleFilter,
    required this.categoryFilter,
    this.onJumpToTime,
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

    // カテゴリ tips ボックスをスクロール領域の先頭に挿入する条件:
    // カテゴリが all 以外、かつ tips データが存在する場合。
    // 2026-05-08: _DayTabBar 固定領域から ListView 先頭に移動。
    // ユーザー要望: フォントサイズ最大時にボックス分の表示枠が固定で
    // ロックされタイムライン可視枠が極端に圧迫される事象を、
    // 「下方向にスクロールするとボックスが上に流れる」形で解消。
    final showTips = categoryFilter != 'all' &&
        categoryFilterTips.containsKey(categoryFilter);

    // 空状態 (今日イベント無し / フィルタで 0 件) でも tips は活きるので、
    // 全状態で同じ ListView 構造を使い、children list で組み立てる。
    final children = <Widget>[];
    // L3 Lewis: 観測時刻の緯度帯ヒット惑星リスト (先頭に表示、Lewis 緯度効果)。
    // 旧 worker は latitudeBand を返さないため null 安全。
    if (result.latitudeBand != null &&
        (result.latitudeBand!.zenith.isNotEmpty ||
            result.latitudeBand!.nadir.isNotEmpty)) {
      children.add(_LatitudeBandBox(band: result.latitudeBand!));
    }
    if (showTips) {
      children.add(_CategoryTipsBox(
        categoryKey: categoryFilter,
        angleFilter: angleFilter,
      ));
    }
    if (allEvents.isEmpty) {
      children.add(const Padding(
        padding: EdgeInsets.fromLTRB(12, 28, 12, 28),
        child: Text(
          '今日は静かな日。\n特別な動きは見えません。',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: SolaraColors.textSecondary,
            height: 1.7,
            letterSpacing: 0.5,
          ),
        ),
      ));
    } else if (events.isEmpty) {
      // 全データはあるがフィルタで0件 → ユーザーにフィルタ変更を促す
      children.add(const Padding(
        padding: EdgeInsets.fromLTRB(12, 28, 12, 28),
        child: Text(
          'このフィルタ条件に\n該当するイベントはありません。\nフィルタを変更してください。',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: SolaraColors.textSecondary,
            height: 1.7,
            letterSpacing: 0.5,
          ),
        ),
      ));
    } else {
      for (final e in events) {
        children.add(_TimelineRow(
          planetKey: e.planet,
          event: e.event,
          categoryFilter: categoryFilter,
          onJumpToTime: onJumpToTime,
        ));
      }
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: children.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) => children[i],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final String planetKey;
  final TransitEvent event;
  final String categoryFilter;
  /// 地図マークタップで「このイベント時刻を Map に飛ばす」コールバック。
  /// 渡された DateTime はイベントの瞬時時刻 (1 分単位)。
  /// null なら地図マーク非表示。
  final void Function(DateTime time)? onJumpToTime;

  const _TimelineRow({
    required this.planetKey,
    required this.event,
    required this.categoryFilter,
    this.onJumpToTime,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 左ブロック: [時刻 + 惑星] 行 + 地図マーク (2026-05-12 追加)
              // 全体幅 = 64 + 4 + 24 = 92。
              SizedBox(
                width: 92,
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
                      ],
                    ),
                    // 2026-05-12: 地図マーク。タップでこの時刻 (1 分単位) を
                    // Map に飛ばす。Forecast 日別詳細と同じ機能。
                    if (onJumpToTime != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: IconButton(
                          icon: const Icon(Icons.map_outlined,
                              size: 18, color: Color(0xFFC9A84C)),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 28, minHeight: 28),
                          tooltip: 'この時刻をMapで見る',
                          // Daily Transit は state 駆動なので Navigator.pop は呼ばない。
                          // 親 (map_screen) 側で onJumpToTime ハンドラ内で
                          // _dailyTransitOpen=false にして閉じる。
                          onPressed: () => onJumpToTime!(event.time),
                        ),
                      ),
                  ],
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _angleHint(event.angle, compassLabel),
                            style: const TextStyle(
                              fontSize: 13,
                              color: SolaraColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ),
                        // L3 Lewis: MC/IC イベントで高度バッジ表示。
                        // 高度 ≈ 90° (≥85°) で天頂寄り、≈ -90° (≤-85°) で天底寄り。
                        // 天頂寄り = 観測者緯度がほぼ惑星赤緯 = 真上から降る瞬間
                        // 天底寄り = 観測者の足下を通る瞬間
                        if (event.angle == 'MC' || event.angle == 'IC') ...[
                          const SizedBox(width: 6),
                          _AltitudeBadge(angle: event.angle, altitude: event.altitude),
                        ],
                      ],
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

/// L3 Lewis 高度バッジ。
/// MC イベント: 高度 90° に近いほど天頂寄り (観測者緯度 ≈ 惑星赤緯)
/// IC イベント: 高度 -90° に近いほど天底寄り
/// 閾値 85° = Lewis ACG オーブ 5° と整合。
/// バッジタップで altitude_event 用語解説 popup を開く。
class _AltitudeBadge extends StatelessWidget {
  final String angle;     // 'MC' | 'IC'
  final double altitude;  // 度
  const _AltitudeBadge({required this.angle, required this.altitude});

  @override
  Widget build(BuildContext context) {
    final isMC = angle == 'MC';
    final extreme = isMC ? altitude >= 85.0 : altitude <= -85.0;
    final label = extreme ? (isMC ? '★ 天頂寄り' : '★ 天底寄り') : null;
    final color = extreme
        ? (isMC ? const Color(0xFFC9A84C) : const Color(0xFFB07CFF))
        : const Color(0x99AAAAAA);
    final altText = '${altitude.toStringAsFixed(0)}°';

    return GestureDetector(
      onTap: () => showAstroGlossaryDialog(context, 'altitude_event'),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withAlpha(extreme ? 200 : 100), width: 0.7),
          color: extreme ? color.withAlpha(20) : Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label != null) ...[
              Text(label, style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              )),
              const SizedBox(width: 4),
            ],
            Text(altText, style: TextStyle(
              fontSize: 11, color: color, fontFamily: 'monospace',
              fontWeight: extreme ? FontWeight.w600 : FontWeight.w400,
            )),
            const SizedBox(width: 3),
            Icon(Icons.info_outline, size: 11, color: color.withAlpha(180)),
          ],
        ),
      ),
    );
  }
}

/// L3 Lewis 緯度帯ボックス。
/// 観測時刻に「観測者と同じ緯度線上で天頂/天底を迎えている惑星」を列挙。
/// 緯度効果 (Lewis): 同じ緯度線全周に効くため、観測者は経度を問わず影響を受ける。
class _LatitudeBandBox extends StatelessWidget {
  final LatitudeBand band;
  const _LatitudeBandBox({required this.band});

  @override
  Widget build(BuildContext context) {
    if (band.zenith.isEmpty && band.nadir.isEmpty) {
      return const SizedBox.shrink();
    }
    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => showAstroGlossaryDialog(context, 'latitude_band_now'),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                const Text('🌐', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '今あなたの緯度帯 (緯度 ${band.observerLat.toStringAsFixed(1)}°、オーブ ±${band.orb.toStringAsFixed(0)}°)',
                    style: const TextStyle(
                      fontSize: 13,
                      color: SolaraColors.textPrimary,
                      letterSpacing: 0.3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(Icons.info_outline, size: 14, color: Color(0xCCAAAAAA)),
              ],
            ),
          ),
          if (band.zenith.isNotEmpty) ...[
            const SizedBox(height: 8),
            _LatitudeBandRow(label: '天頂帯', hits: band.zenith, accent: const Color(0xFFC9A84C)),
          ],
          if (band.nadir.isNotEmpty) ...[
            const SizedBox(height: 6),
            _LatitudeBandRow(label: '天底帯', hits: band.nadir, accent: const Color(0xFFB07CFF)),
          ],
        ],
      ),
    );
  }
}

class _LatitudeBandRow extends StatelessWidget {
  final String label;
  final List<LatitudeBandHit> hits;
  final Color accent;
  const _LatitudeBandRow({required this.label, required this.hits, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 50,
          child: Text(label, style: TextStyle(
            fontSize: 12, color: accent,
            fontWeight: FontWeight.w600, letterSpacing: 0.4,
          )),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Wrap(
            spacing: 6, runSpacing: 4,
            children: hits.map((h) {
              final meta = planetMeta[h.planet];
              final sym = meta?.sym ?? '✦';
              final color = meta?.color ?? accent;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withAlpha(140), width: 0.7),
                  color: color.withAlpha(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(sym, style: TextStyle(fontSize: 13, color: color)),
                    const SizedBox(width: 3),
                    Text('δ${h.dec >= 0 ? '+' : ''}${h.dec.toStringAsFixed(1)}°',
                      style: TextStyle(
                        fontSize: 10, color: color.withAlpha(220),
                        fontFamily: 'monospace',
                      )),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
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
  // B6: カテゴリ × アングル の組み合わせ補足を優先 (惑星×カテゴリ×アングル の文脈)。
  // データが無い場合は legacy の categoryAppendix (カテゴリ単体) にフォールバック。
  final appendix = (categoryFilter != 'all')
      ? (categoryAngleAppendix[categoryFilter]?[angleUpper] ??
          categoryAppendix[categoryFilter])
      : null;
  final title = '$planetJPの$angleUpper通過';

  _showPlanetAngleDetail(
    context: context,
    title: title,
    base: base,
    appendix: appendix,
    planetColor: planetColor,
  );
}

/// 「お勧め行動の例」i ボタンタップ時のカテゴリ × アングル別ガイド dialog。
/// activeCategory + 選択中 angleFilter に応じた使い方説明を出す。
/// fallback: カテゴリ entry がない場合 (=all 等) は astro_glossary に投げる。
/// 2026-05-08: angleFilter パラメータ追加 — 個別アングル別の細分化対応。
void _showCategoryTipsIntent(
    BuildContext context, String categoryKey, AngleFilter angleFilter) {
  final catEntries = categoryTipsIntent[categoryKey];
  final entry = catEntries?[angleFilter] ?? catEntries?[AngleFilter.all];
  if (entry == null) {
    showAstroGlossaryDialog(context, 'category_tips_intent');
    return;
  }
  showInfoPopup(
    context: context,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          entry.title,
          style: const TextStyle(
            color: Color(0xFFC9A84C),
            fontSize: 14,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          entry.body,
          style: const TextStyle(
            color: Color(0xFFE8E0D0),
            fontSize: 13,
            height: 1.7,
          ),
        ),
      ],
    ),
  );
}

/// アングル詳細 popup (アングルプルダウン横の i ボタンから開く)。
/// 個別アングル選択時はその瞬間 + 次のアングルへの経過を表示。
/// 複合 / 全角度の場合はまとめ表示。
/// 2026-05-08: showAstroGlossaryDialog('transit_angles') を置換。
void _showAngleDetailPopup(BuildContext context, AngleFilter filter) {
  final entry = angleDetailContent[filter];
  if (entry == null) {
    showAstroGlossaryDialog(context, 'transit_angles');
    return;
  }
  showInfoPopup(
    context: context,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          entry.title,
          style: const TextStyle(
            color: Color(0xFFC9A84C),
            fontSize: 14,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          entry.body,
          style: const TextStyle(
            color: Color(0xFFE8E0D0),
            fontSize: 13,
            height: 1.7,
          ),
        ),
      ],
    ),
  );
}

/// 2026-05-07: 統一 popup ヘルパー [showInfoPopup] 経由に移行。
/// 右上 × / 全文スクロール / 外タップ閉じが Shell 側で自動提供される。
void _showPlanetAngleDetail({
  required BuildContext context,
  required String title,
  required String base,
  required String? appendix,
  required Color planetColor,
}) {
  showInfoPopup(
    context: context,
    maxWidth: 360,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: planetColor,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 10),
        if (base.isNotEmpty)
          Text(
            base,
            style: const TextStyle(
              fontSize: 13,
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
                fontSize: 13,
                color: Color(0xFFCCCCCC),
                height: 1.7,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

/// 「今日の動き」画面の使い方 popup。
/// _Header の ❓ help_outline アイコンから開く。
///
/// Map スコアバー側の `showCategoryInfoPopup` と対になる「逆向き」説明:
///   - スコアバー (Map 本体) = 方角の指針
///   - この画面                = 時間の指針
///   - 両方を組み合わせて Solara が「方角 × 時間」を算出
///
/// 「今日の動きの読み方」というシンプルな見出しでパッと見て機能を理解
/// してもらうのが目的。技術的な「なぜこのカテゴリが TOP か」はもう一つの
/// ⓘ info_outline アイコン (`top_category_logic` glossary) に分離。
void showDailyUsageGuidePopup(BuildContext context) {
  showInfoPopup(
    context: context,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          '今日の動きの読み方',
          style: TextStyle(
              color: Color(0xFFC9A84C), fontSize: 14, letterSpacing: 1),
        ),
        SizedBox(height: 8),
        // ── 画面要約 (ユーザー要望: パッと見て機能が分かる一行) ──
        Text(
          'この画面では、あなたの意図する目的に合わせて\n'
          '「いつ行動するか」の時間の指針が分かります。',
          style: TextStyle(
              color: Color(0xFFE8E0D0),
              fontSize: 13,
              height: 1.6,
              fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 14),
        // ── 基準地点 (VIEWPOINT) の説明 ──
        Text(
          '【基準地点 (VIEWPOINT)】',
          style: TextStyle(
              color: Color(0xFFC9A84C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
        ),
        SizedBox(height: 4),
        Text(
          '右側のプルダウンが「基準地点」です。\n'
          '出生地 (現住所として登録した地点) や、\n'
          'VIEWPOINT として登録した地点を選択できます。\n'
          'この画面では、選択した基準地点の空で、\n'
          '惑星が「天空方位」のどこにいつ来るかを表示します。',
          style: TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
        ),
        SizedBox(height: 10),
        // ── Map 画面の方位との違いを明示 ──
        Text(
          '【⚠ Map 画面の方位とは別物です】',
          style: TextStyle(
              color: Color(0xFFFFA864), // やや警告色 (混同防止)
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
        ),
        SizedBox(height: 4),
        Text(
          '・Map 画面 = 「地表方位」(16 方位)\n'
          '　基準地点から見て地表のどの方向に行くか\n'
          '　(東の土地へ行く / 北の土地へ向かう、という地理)\n\n'
          '・この画面 = 「天空方位」(4 アングル)\n'
          '　基準地点の真上の空で惑星がどこにあるか\n'
          '　(東の地平線 / 真上の天頂 / 西の地平線 / 真下)\n\n'
          '同じ「東」でも、Map では「東の土地」、\n'
          'この画面では「東の地平線 (惑星が昇る位置)」を指します。',
          style: TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
        ),
        SizedBox(height: 10),
        Text(
          '【時間と天空方位を読む】',
          style: TextStyle(
              color: Color(0xFFC9A84C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
        ),
        SizedBox(height: 4),
        Text(
          '今日、各惑星が選択した基準地点の空で\n'
          '4 つの天空方位 (アングル) を通る時刻を表示します:\n\n'
          '・ASC (東の地平線) — 惑星が昇る瞬間\n'
          '・MC  (真上 = 天頂) — 惑星が最高点を通る瞬間\n'
          '・DSC (西の地平線) — 惑星が沈む瞬間\n'
          '・IC  (真下 = 地下) — 惑星が地球の裏側にある瞬間\n\n'
          '「いつ恋愛運が上がる」「いつ仕事の節目になる」など、\n'
          '行動する時間の指針が読み取れます。',
          style: TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
        ),
        SizedBox(height: 10),
        Text(
          '【Map スコアバーと組み合わせる】',
          style: TextStyle(
              color: Color(0xFFC9A84C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
        ),
        SizedBox(height: 4),
        Text(
          '地表方位ごとのエネルギーの強さは、\n'
          'Map のスコアバーから確認できます (16 方位)。\n'
          '「合計 / 総合」ラベル下の i ボタンに詳細解説があります。\n\n'
          'スコアバー (地表方位の強さ) と\n'
          'この画面 (天空方位 × 時刻) を組み合わせると、\n'
          'あなたの望む未来に対する最適な\n'
          '「方角 × 時間」を Solara が算出します。',
          style: TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
        ),
      ],
    ),
  );
}

