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
import 'map_aspect_chip.dart';
import 'map_constants.dart';

class MapDailyTransitScreen extends StatefulWidget {
  final DominantFortuneKind? topCategory;
  final LatLng location;
  /// 観測点ラベル（ヘッダ表示用）。例: 「自宅」「東京都渋谷区」。
  final String locationLabel;
  /// V2: natal 黄経マップ。指定時、各イベントにアスペクト context が表示される。
  final Map<String, double>? natal;
  final VoidCallback onClose;

  const MapDailyTransitScreen({
    super.key,
    required this.topCategory,
    required this.location,
    this.locationLabel = '',
    this.natal,
    required this.onClose,
  });

  @override
  State<MapDailyTransitScreen> createState() => _MapDailyTransitScreenState();
}

/// タブ識別子。
enum _DayTab { today, tomorrow }

class _MapDailyTransitScreenState extends State<MapDailyTransitScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;

  // タブ別キャッシュ。再タップで再 fetch を避ける。
  final Map<_DayTab, DailyTransitsResult> _cache = {};
  final Map<_DayTab, bool> _failed = {
    _DayTab.today: false, _DayTab.tomorrow: false,
  };
  final Map<_DayTab, bool> _loading = {
    _DayTab.today: false, _DayTab.tomorrow: false,
  };

  _DayTab _activeTab = _DayTab.today;

  // Sanctuary で設定された orb 値（読込が完了するまで null）
  Map<String, double>? _orbs;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();
    _loadOrbsAndStart();
  }

  Future<void> _loadOrbsAndStart() async {
    _orbs = await SolaraStorage.loadOrbSettings();
    if (!mounted) return;
    _loadTab(_DayTab.today);
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

  Future<void> _loadTab(_DayTab tab) async {
    if (_cache.containsKey(tab) || (_loading[tab] ?? false)) return;
    setState(() {
      _loading[tab] = true;
      _failed[tab] = false;
    });
    final result = await fetchDailyTransits(
      lat: widget.location.latitude,
      lng: widget.location.longitude,
      startTime: _tabStartTime(tab),
      natal: widget.natal,
      orbs: _orbs,
    );
    if (!mounted) return;
    setState(() {
      _loading[tab] = false;
      if (result != null) {
        _cache[tab] = result;
      } else {
        _failed[tab] = true;
      }
    });
  }

  void _selectTab(_DayTab tab) {
    if (_activeTab == tab) return;
    setState(() => _activeTab = tab);
    _loadTab(tab); // 未取得なら lazy load
  }

  Future<void> _close() async {
    await _fadeCtrl.reverse();
    if (!mounted) return;
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final cached = _cache[_activeTab];
    final isLoading = _loading[_activeTab] ?? false;
    final hasFailed = _failed[_activeTab] ?? false;
    return FadeTransition(
      opacity: _fadeCtrl,
      child: Container(
        color: const Color(0xEE0A0A14),
        child: SafeArea(
          child: Column(
            children: [
              _Header(
                topCategory: widget.topCategory,
                locationLabel: widget.locationLabel,
                onClose: _close,
              ),
              _DayTabBar(
                active: _activeTab,
                onSelect: _selectTab,
              ),
              Expanded(
                child: isLoading
                    ? const _LoadingBody()
                    : hasFailed
                        ? _FailedBody(onRetry: () => _loadTab(_activeTab))
                        : cached != null
                            ? _TimelineBody(result: cached)
                            : const _LoadingBody(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── DayTabBar （本日 / 明日 切替） ──

class _DayTabBar extends StatelessWidget {
  final _DayTab active;
  final ValueChanged<_DayTab> onSelect;

  const _DayTabBar({required this.active, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x14FFFFFF))),
      ),
      child: Row(
        children: [
          _tabBtn(_DayTab.today, '本日'),
          const SizedBox(width: 6),
          _tabBtn(_DayTab.tomorrow, '明日'),
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
}

// ── Header（トップカテゴリバナー + 閉じる） ──

class _Header extends StatelessWidget {
  final DominantFortuneKind? topCategory;
  final String locationLabel;
  final VoidCallback onClose;

  const _Header({
    required this.topCategory,
    required this.locationLabel,
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
                if (locationLabel.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.place,
                          size: 11, color: Color(0xFF888888)),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          locationLabel,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF888888),
                            letterSpacing: 0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
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
  const _TimelineBody({required this.result});

  @override
  Widget build(BuildContext context) {
    final events = result.flatTimeline();
    if (events.isEmpty) {
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

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: events.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) => _TimelineRow(
        planetKey: events[i].planet,
        event: events[i].event,
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final String planetKey;
  final TransitEvent event;

  const _TimelineRow({required this.planetKey, required this.event});

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
                    // タップで 4アングル(ASC/MC/DSC/IC) の意味解説を表示。
                    GestureDetector(
                      onTap: () => showAstroGlossaryDialog(
                          context, 'transit_angles'),
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

