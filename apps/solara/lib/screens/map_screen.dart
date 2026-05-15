import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../utils/solara_api.dart' show solaraWorkerBase;
import '../utils/solara_storage.dart';
import '../utils/tile_http_client.dart' show sharedTileHttpClient;
import '../widgets/dominant_fortune_overlay.dart';
import '../widgets/info_popup.dart';
import 'map/map_daily_transit_screen.dart';
import 'map/map_constants.dart';
import 'map/map_styles.dart';
import 'map/map_sectors.dart';
import 'map/map_fortune_sheet.dart';
import 'map/map_vp_panel.dart';
import 'map/map_menu_chips.dart';
import 'map/map_display_menu.dart';
import 'map/map_viewpoint_menu.dart';
import 'map/map_astro.dart';
import 'map/map_astro_carto.dart';
import 'map/map_astro_lines.dart';
import 'map/map_location_markers.dart';
import 'map/map_planet_intro_popup.dart';
import 'map/map_planet_lines.dart';
import 'map/map_relocation_popup.dart';
import 'map/map_search.dart';
import 'map/map_overlays.dart';
import 'map/map_time_slider.dart';
import 'map/map_widgets.dart';
import '../utils/astro_lines.dart' as astro_lines;
import '../utils/direction_energy.dart';
import '../utils/reverse_geocode.dart';
import 'consultation/consultation_input_screen.dart';
import 'forecast_screen.dart';
import 'horoscope/horo_antique_icons.dart';
import 'locations_screen.dart';

/// 開発用フラグ: true なら日付チェックをバイパスして毎回オーバーレイを表示する。
/// 本番では false。
const bool _debugAlwaysShowOverlay = false;

/// 開発用: true ならタップ毎に _debugCycleOrder の順番で演出を切り替える。
/// 本番では false、実際のトップカテゴリで表示。
const bool _debugCycleOverlayKinds = false;

/// デバッグ循環順: 5種を通しで確認できるようにする
const _debugCycleOrder = <DominantFortuneKind>[
  DominantFortuneKind.love,
  DominantFortuneKind.money,
  DominantFortuneKind.healing,
  DominantFortuneKind.communication,
  DominantFortuneKind.work,
];

/// 実装済みのカテゴリ（5種全て）
const _implementedOverlayKinds = <DominantFortuneKind>{
  DominantFortuneKind.love,
  DominantFortuneKind.money,
  DominantFortuneKind.healing,
  DominantFortuneKind.communication,
  DominantFortuneKind.work,
};

const _overlayStorageKey = 'dominant_fortune';

class MapScreen extends StatefulWidget {
  /// プロフィール未設定時の案内から Sanctuary タブへ遷移させるコールバック。
  /// 実体は main.dart の `_onTabTap(4)`。
  final VoidCallback? onNavigateToSanctuary;
  const MapScreen({super.key, this.onNavigateToSanctuary});

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapCtrl = MapController();
  LatLng _center = const LatLng(35.4233, 136.7607);

  // UI state (2026-05-09 第二弾再設計)
  // - 旧 BottomSheet 方式は地図が隠れてトグル変化が見えない問題があり、
  //   左サイド ☰表示 / 📍地点 ボタンタップ → 右に展開する方式へ変更。
  // - 表示メニューと地点メニューは相互排他 (両方同時に開かない)。
  bool _searchOpen = false;
  bool _fortuneSheetOpen = false;
  bool _displayMenuOpen = false;   // ☰ 表示メニュー開閉
  bool _viewpointMenuOpen = false; // 📍 地点メニュー開閉
  // ACG モード専用: 下部 3 段メニュー (Frame/Sub/Category) のバーガー開閉。
  // 初期 false (閉じ) → ☰タップで展開、再タップ or △で閉じる。
  bool _acgMenuOpen = false;
  bool _restOverlayVisible = false;
  final String _restOverlayText = '';
  final TextEditingController _searchCtrl = TextEditingController();

  // Layer visibility
  // 'coords': 緯度経度ラベルを表示 (Map L2 メニュー「座標取得」)。
  //          十字 (+) は常時表示 (VP Pin 中心の視覚化用途で邪魔にならない)、
  //          ラベルだけはトグル ON 時のみ (常時表示は地図が見にくくなるため、
  //          2026-05-13 ユーザー判断で復活)。
  final Map<String, bool> _layers = {
    'sectors': true, 'compass': true, 'transit': true,
    'natal': false, 'progressed': false, 'coords': false,
  };

  // Fortune category / source
  // _activeCategory: 16方位スコアバー / 扇状ポリゴン / FortuneSheet / 検索ハイライト等
  //   "全体UIコンテキスト" を司る (色・スコア・rank alpha 全部)。
  // _planetFilterCategory: 惑星ライン / アスペクト線 / 天頂点マーカーの表示フィルタのみ。
  //   2026-05-09 ユーザー要望で扇状と分離。バーガーメニュー惑星>FORTUNE は
  //   このフィルタのみを更新し、扇状の表示は変えない。
  //   FortuneSheet / 上部スコアバータップ / ACG モードピル経由で _activeCategory が
  //   変わる時は両方を同期させる (旧挙動の維持・予期せぬ乖離を防止)。
  String _activeCategory = 'all';
  String _planetFilterCategory = 'all';
  String _activeSrc = 'combined';

  // Planet group visibility
  final Map<String, bool> _planetGroups = {
    'personal': true, 'social': false, 'generational': false,
  };

  // Phase M2 ASTRO レイヤー: 16方位/惑星ライン/引越し/アスペクト線 (論点5 4流派並列)
  // 設計: project_solara_astrocartography_m2.md 論点8 (引越し/アスペクトはOFFスタート)
  // planetLines は既存挙動の維持で true デフォルト (新機能のM2のみOFFスタート)
  //
  // Tier A #5 (CCG): aspectTransit / aspectProgressed / aspectSolarArc 追加。
  // 'aspect' は natal フレームを意味する (後方互換のため既存キー名を維持)。
  // 動的フレーム (T/P/SA) は viewDate から GMST を再計算する設計。
  final Map<String, bool> _astroLayers = {
    'planetLines': true,
    'relocate': false,
    // ── 第1層: フレーム線 ON/OFF ──
    'aspect': false,         // natal フレーム
    'aspectTransit': false,  // CCG transit
    'aspectProgressed': false, // CCG progressed
    'aspectSolarArc': false, // CCG solar arc
    'aspectAll': false,      // 全惑星モード (FORTUNE フィルタ無視)
    'aspectLines': false,    // B1: アスペクト線 (square/trine/sextile) 表示。OFF=本線のみ
    // ── 第2層: フレーム別の天頂/天底/天頂帯/天底帯 (2026-05-11 ACG 2層メニュー化) ──
    // 各 frame の線が ON のときのみ第2層メニューに表示される (アコーディオン)。
    // キー組立規約: '<subKey>_<frameSuffix>'
    //   subKey      = zenith | nadir | zenithBand | nadirBand
    //   frameSuffix = natal | transit | progressed | solarArc
    for (final sub in ['zenith', 'nadir', 'zenithBand', 'nadirBand'])
      for (final f in ['natal', 'transit', 'progressed', 'solarArc'])
        '${sub}_$f': false,
  };

  // ACG 第2層メニュー: 直前にタップした「線 ON」フレーム (排他表示用)。
  // null のとき第2層は折り畳まれ、地図領域がその分広がる。
  // build 時に _resolveActiveAstroFrame() で「線 ON のフレームと整合する値」へ
  // 自動補完される (hot reload や state 不整合からの自己復旧)。
  astro_lines.AstroFrame? _activeAstroFrame;

  /// 現在の _astroLayers と整合する active を返す。
  /// - active が既に line ON フレームを指していればそのまま
  /// - active が null or line OFF を指していれば、ON 中の先頭フレームへ補正
  /// - ON 中のフレームが 1 つもなければ null (第2層折り畳み)
  astro_lines.AstroFrame? _resolveActiveAstroFrame() {
    final cur = _activeAstroFrame;
    if (cur != null) {
      for (final def in acgFrameDefs) {
        if (def.frame == cur && _astroLayers[def.layerKey] == true) {
          return cur;
        }
      }
    }
    for (final def in acgFrameDefs) {
      if (_astroLayers[def.layerKey] == true) return def.frame;
    }
    return null;
  }

  // 引越しレイヤー ON時のタップ詳細ポップアップ用
  LatLng? _relocateTapPoint;

  // Astro*Carto*Graphy モード: 天頂点マーカータップ詳細用
  // 値が入っていれば下部 popup を表示する。
  // CCG: frame と point を保持し、natal以外の天頂タップにも対応。
  ({String planet, astro_lines.AstroFrame frame, LatLng point, bool isNadir})? _zenithTapInfo;

  // Phase M2 論点3: アスペクト線 40本キャッシュ (chart 取得時に build)
  // CCG (Tier A #5): 4フレーム合算 (natal+transit+progressed+solarArc) を保持
  List<astro_lines.AstroLine> _astroLinesCache = const [];

  // CCG: 日付別 ChartResult キャッシュ (タイムスライダーの往復で再fetch回避)。
  // key = "yyyy-MM-dd" (UTC日)、null は relocate設定変化等で無効化。
  // LRU 風: 50件超えたら古いものから削除 (≒ ±25日往復で十分)。
  final Map<String, ChartResult> _chartCacheByDate = {};
  static const int _chartCacheMax = 50;

  // Sector scores
  // _sectorComps: 総合（all）用の per-direction components {tSoft, tHard, pSoft, pHard}
  // _fComps: カテゴリ別の per-direction components  _fComps[cat][dir] = {tSoft,...}
  final Map<String, double> _sectorScores = {};
  final Map<String, Map<String, double>> _sectorComps = {};
  final Map<String, Map<String, Map<String, double>>> _fComps = {};
  ScoreResult? _scoreResult;

  ChartResult? _chartResult;
  List<PlanetLineData> _planetLines = [];
  SolaraProfile? _profile;

  /// プロフィール未設定状態。true の間は占い系オーバーレイ（セクター・
  /// FortuneSheet・Omen 等）を非表示にし、中央に案内カードを出す。
  /// 乱数のモックスコアを見せて誤解を招くのを防ぐ目的。
  bool _noProfile = false;

  // 日付選択（null = 今日）。UTC 扱い。
  DateTime? _selectedDate;
  bool _loadingChart = false;

  /// 初回ロードで _center を出生地に揃える用のフラグ。
  /// 2回目以降の _loadProfileAndChart 呼び出し（日付変更・Forecastジャンプ等）では
  /// ユーザーが選んだ VP / 手動中心を保持する。
  bool _hasInitialCenter = false;

  /// FlutterMap の onMapReady が発火済みか。
  /// 出生地ロードが先行した場合は _pendingInitialMove に積んで onMapReady 時に消化する。
  /// (旧実装: addPostFrameCallback で _mapCtrl.camera.zoom 直叩き → MapController 未接続で
  /// 無音失敗し、初期表示の地図描画が出ない事象が時々発生していた)
  bool _mapReady = false;
  LatLng? _pendingInitialMove;

  /// 4層防御モデル (project_solara_map_render_protocol.md):
  /// (1) flutter_map 8.3+ の visibility 計算 fix を取込む
  /// (2) _bootReady flag で warmup + style 完了まで mount を遅延 (cold start race 排除)
  /// (3) TileLayer に reset Stream を渡し、State 保持で全タイル再評価
  /// (4) settle 後の無条件リセットで Case C (flutter_map がタイル消失に気付かない状態)
  ///     からの自動復旧
  ///
  /// _bootReady=true まで FlutterMap を mount しない。warmup と _loadMapStyle が
  /// 完了するのを待つことで、初期 fetch を warm 状態 (DNS/TLS 確立済 + style 確定済)
  /// で起こす。light↔dark 構造変化 race も排除される。
  bool _bootReady = false;

  /// TileLayer.reset Stream の発火源。発火すると flutter_map が全タイル状態を
  /// 保持しつつ再評価する。State 破棄を伴わないので in-flight fetch が
  /// silent キャンセルされない。errorTileCallback と settle reset の両方から発火。
  late final StreamController<void> _tileResetCtrl;

  /// reset 発火回数カウンタ。errorTileCallback 連発で暴走しないよう上限管理。
  /// settle reset (mount 後 1 回限り) はこのカウンタを消費しない。
  int _tileResetCount = 0;
  static const int _tileResetMax = 3;
  Timer? _tileErrorDebounce;

  /// settle 後の verify-recover 用 Timer (4層防御モデル 第4層)。
  /// FlutterMap mount から 4 秒後に無条件で reset Stream を発火し、
  /// Case C で空になったタイルを救済する。dispose でキャンセル。
  Timer? _settleResetTimer;

  // Dominant fortune overlay
  DominantFortuneKind? _topCategory;
  DominantFortuneKind? _activeOverlay;
  int _debugCycleIdx = 0;

  // F1-c: Daily Transit Badge — 右上の日次トリガー。
  // _dailyBadgeUnseen=true 時は光る（リセット時刻後の初回表示）。
  // タップで _onDailyBadgeTap() → アニメ → F1-c フルUI へ。
  bool _dailyBadgeUnseen = false;
  bool _dailyTransitOpen = false;

  // Search results
  List<SearchHit> _searchHits = [];
  SearchHit? _searchFocus; // 選択済み1件（ピン表示用）
  bool _searching = false;
  // 検索一覧を表示し始めた時のマップ状態 (center/zoom)。
  // hit を選んでズームイン後、戻るボタンで一覧画面に戻る際に復元する。
  LatLng? _searchListCenter;
  double? _searchListZoom;
  // 検索実行時の「地図の見えている中心」を保存。
  // VP Pin 位置 (_center) とは別物。dropdown で「地図中心」を選んだ時の
  // 距離・方位計算の基準として使う。Phase A (2026-05-13)。
  LatLng? _searchOriginCenter;
  // 検索結果リスト dropdown で選択中の VIEWPOINT index
  // -1 = 地図中心 (= _searchOriginCenter)、0+ = _vpSlotsCache の index
  int _searchVpIndex = -1;

  // Map style (tile source + light/dark filter)
  // OSM HOT は現地言語ラベルのまま（多言語化はユーザー数増えてから再検討）。
  MapStyle _mapStyle = MapStyle.osmHotLight;

  // Astro*Carto*Graphy モード
  // ON時: 世界地図ズームアウト + relocate/aspect/aspectAll 強制ON +
  //       16方位/コンパス/惑星ライン/各種オーバーレイ非表示 +
  //       天頂点マーカー表示。情報密度を抑え世界規模ビューに集中させる。
  // 退避先: モード解除時に元の状態を完全復元する。
  bool _astroCartoMode = false;
  // MapTimeSlider 制御用:
  //   時刻行展開時に back ボタンで畳む処理を、 map_screen.dart の PopScope に
  //   統合する。 GlobalKey で closeTimeRow() を呼び、 _timeRowExpanded で
  //   状態を反映 (PopScope.canPop の再計算を trigger するため map_screen.dart
  //   の state として保持)。 MapTimeSlider 側は onExpandedChanged で通知。
  final GlobalKey<MapTimeSliderState> _timeSliderKey = GlobalKey<MapTimeSliderState>();
  bool _timeRowExpanded = false;
  LatLng? _savedCenter;
  double? _savedZoom;
  Map<String, bool>? _savedLayers;
  Map<String, bool>? _savedAstroLayers;
  MapStyle? _savedMapStyle;

  // 登録地マーカー (出生地 + VP slots + Locations slots、両モード共通表示)
  // VP/Locations 編集後は _reloadLocationSlots() で再読込。
  final SlotManager _vpSlotMgr =
      SlotManager(storageKey: 'solara_vp_slots', defaultNames: ['職場','お気に入り','スポット','場所']);
  final SlotManager _locSlotMgr =
      SlotManager(storageKey: 'solara_locations', defaultNames: ['場所1','場所2','場所3','場所4']);
  List<VPSlot> _vpSlotsCache = const [];
  List<VPSlot> _locSlotsCache = const [];
  // タップされたマーカー情報 (popup 表示用)。null = popup 非表示。
  ({String name, LatLng point, bool isBirth})? _locationTapInfo;

  @override
  void initState() {
    super.initState();
    _tileResetCtrl = StreamController<void>.broadcast();
    _bootstrap();
  }

  /// 4層防御モデル 第2層: warmup + style 確定まで FlutterMap mount を遅延。
  /// これにより初期 fetch は DNS/TLS 確立済 + style 確定済の状態で起こる。
  /// cold start race と light↔dark switch race の両方を排除。
  Future<void> _bootstrap() async {
    await Future.wait([
      _loadMapStyle(),
      _warmupTileConnection(),
    ]);
    if (!mounted) return;
    setState(() => _bootReady = true);
    // 第4層: 4 秒後に無条件 reset で Case C を救済 (mount 後 1 回限り)
    _settleResetTimer?.cancel();
    _settleResetTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      if (kDebugMode) {
        debugPrint('[Solara Map] 🔄 settle reset (verify-recover, 4層防御 第4層)');
      }
      _tileResetCtrl.add(null);
      // 5層目: 初期ブート経路 (_bootstrap → mount → onMapReady → settle reset) は
      // _mapCtrl.move を一切経由しないため paint invalidation kick が抜けていた。
      // settle reset (fetch 系 Case C 救済) だけでは markNeedsPaint が立たず、
      // タイルは fetch 済なのに描画されないまま固着する (paint 系 Case C)。
      // reset とペアで微小パン kick を打ち、paint pipe を確実に起こす。
      // 詳細: memory/project_solara_map_paint_invalidation.md
      _kickPaintInvalidation();
    });
    // FlutterMap が mount された後にこれらを開始 (mount は build() 内で _bootReady true 化により発生)
    _loadProfileAndChart();
    _checkDailyBadgeState();
  }

  @override
  void dispose() {
    _tileErrorDebounce?.cancel();
    _settleResetTimer?.cancel();
    _tileResetCtrl.close();
    super.dispose();
  }

  /// Worker (タイル元) への DNS/TLS cold start を画面表示前に解消するための
  /// プリウォーム。fire-and-forget。失敗しても本番 fetch でリトライされるので無視。
  /// 2026-05-08: Pixel8 エミュ初期描画失敗対策で導入。
  /// 診断ログ: 経過時間と HTTP status を出力 → Worker 側か接続側か切り分け。
  ///
  /// 2026-05-08 修正: HEAD → GET に変更。CF Worker が HEAD method を受け付けず
  /// 404 を返していた (実機ログで判明)。z=0/0/0 は世界全体の 1 タイルで最小。
  Future<void> _warmupTileConnection() async {
    final stopwatch = Stopwatch()..start();
    try {
      // z=0/x=0/y=0 は世界全体を 1 枚で表す最小タイル (約 5-15KB)。
      // sharedTileHttpClient と同じ HTTP プールを使うので、
      // ここで握った keep-alive socket が直後の本番 tile fetch に再利用される。
      final url = Uri.parse('$solaraWorkerBase/tiles/osm/hot/0/0/0.png');
      final response = await sharedTileHttpClient
          .get(url)
          .timeout(const Duration(seconds: 8));
      if (kDebugMode) {
        debugPrint(
          '[Solara Map] 🔥 prewarm OK '
          '(${stopwatch.elapsedMilliseconds}ms, '
          'status=${response.statusCode}, ${response.bodyBytes.length}B)',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[Solara Map] ⚠️ prewarm failed '
          '(${stopwatch.elapsedMilliseconds}ms): $e',
        );
      }
      // 失敗しても本番リトライがあるので無視
    }
  }

  /// 個別タイル fetch 失敗時のフック。1.5s デバウンスして reset Stream を発火し、
  /// flutter_map 内部の全タイル状態を State 保持のまま再評価させる。
  /// 最大 _tileResetMax 回まで (ネットワーク断時の暴走防止)。
  ///
  /// 2026-05-09: 旧 ValueKey bump 機構から移行。bump は State 破棄を伴うため
  /// in-flight fetch が silent キャンセル → 新たな Case C を量産していた。
  /// reset Stream は flutter_map v8.0+ 公式機構で State 保持のまま再評価が可能。
  void _onTileError() {
    if (_tileResetCount >= _tileResetMax) {
      if (kDebugMode) {
        debugPrint(
          '[Solara Map] ⛔ tile error (上限 $_tileResetMax 到達、reset skip)',
        );
      }
      return;
    }
    _tileErrorDebounce?.cancel();
    _tileErrorDebounce = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      if (_tileResetCount >= _tileResetMax) return;
      _tileResetCount++;
      if (kDebugMode) {
        debugPrint(
          '[Solara Map] 🔁 error-triggered reset '
          '(回数=$_tileResetCount/$_tileResetMax)',
        );
      }
      _tileResetCtrl.add(null);
    });
  }

  /// 右上 DailyTransitBadge の「未閲覧（光る）」状態判定。
  /// _topCategory が算出されていて、かつリセット時刻考慮の
  /// 「今日」で未表示なら出す。（デバッグフラグ ON 時は常に表示）
  Future<void> _checkDailyBadgeState() async {
    bool unseen;
    if (_debugAlwaysShowOverlay) {
      unseen = true;
    } else {
      if (_topCategory == null ||
          !_implementedOverlayKinds.contains(_topCategory)) {
        // トップカテゴリ未算出 or アニメ未実装カテゴリ: 光らない（プロフィール無等）
        unseen = false;
      } else {
        final shown = await SolaraStorage.wasOverlayShownToday(_overlayStorageKey);
        unseen = !shown;
      }
    }
    if (!mounted) return;
    setState(() => _dailyBadgeUnseen = unseen);
  }

  Future<void> _loadMapStyle() async {
    final id = await SolaraStorage.loadMapStyleId();
    if (!mounted) return;
    setState(() => _mapStyle = mapStyleFromId(id));
  }

  void _onMapStyleChanged(MapStyle style) {
    setState(() => _mapStyle = style);
    SolaraStorage.saveMapStyleId(mapStyleConfigs[style]!.id);
  }

  /// 外部（main.dart のタブ切替）から呼ばれる公開リロード。
  /// Sanctuary でプロフィール登録/編集後に Map に戻ったとき、
  /// `_noProfile` フラグを更新して占い系オーバーレイを再表示するために使う。
  Future<void> reloadProfile() => _loadProfileAndChart();

  /// 出生地ロード時の初期カメラ移動を MapController が確実に attach されている
  /// タイミングで実行する。onMapReady 未到達なら _pendingInitialMove に積み、
  /// onMapReady 発火時に消化する (= flutter_map 推奨パターン)。
  /// 旧実装の addPostFrameCallback + try/catch では未接続例外を握り潰し、
  /// 「初期表示の地図描画ができない」事象を引き起こしていた。
  void _moveToInitialCenter(LatLng target) {
    if (_mapReady) {
      _mapCtrl.move(target, _mapCtrl.camera.zoom);
    } else {
      _pendingInitialMove = target;
    }
  }

  Future<void> _loadProfileAndChart({DateTime? targetDate}) async {
    final p = await SolaraStorage.loadProfile();
    if (p == null || !p.isComplete) {
      if (mounted) setState(() => _noProfile = true);
      return;
    }
    _profile = p;
    if (mounted) setState(() => _noProfile = false);
    // 登録地スロット (home含む) を読込してマーカー描画に使う
    await _reloadLocationSlots();
    if (mounted) {
      // 初回のみ _center を「現住所優先、未設定なら出生地」に設定 + カメラ移動を予約。
      // 設計方針: Map = 現住所基準の引越し検討ツール (project_solara_astrocartography_m2)。
      // 日付変更等の再計算ではユーザーが選んだ VP / 手動中心を保持する。
      final shouldMoveInitial = !_hasInitialCenter;
      setState(() {
        if (!_hasInitialCenter) {
          final hasHome = !(p.homeLat == 0 && p.homeLng == 0);
          _center = hasHome
              ? LatLng(p.homeLat, p.homeLng)
              : LatLng(p.birthLat, p.birthLng);
          _hasInitialCenter = true;
        }
        _loadingChart = true;
      });
      if (shouldMoveInitial) {
        _moveToInitialCenter(_center);
      }
    }

    // CF Worker API で天体データを取得 → scoreAll で16方位スコア計算
    // 現住所が登録されていればハウス計算は現住所ベース(リロケーション)。
    // 注意: scoreAll() は houses 配列を直接使わない(aspects/角度距離のみ)ため、
    // 現状 16方位スコアには影響なし。将来 M1(ハウス重み付け)で意味を持つ。
    final useRelocate = !(p.homeLat == 0 && p.homeLng == 0);

    // CCG (Tier A #5): 日時別 chart キャッシュ参照。
    // タイムスライダーで往復した際の API 連続呼出を回避する。
    //
    // 2026-04-29: キーに時(hour)を含める (時刻スライダー対応)。
    // 2026-05-10: キーに 10 分単位の minute bucket も含める。
    //   分用▶△ (10 分刻み) で進めても hour 単位 cache hit で
    //   惑星位置が動かない問題を解消。月は 10min で約 0.08° 動き、
    //   GMST は 10min で 2.5° 動くので、地図上の惑星線位置に反映される。
    String cacheKey;
    if (targetDate == null) {
      cacheKey = 'today';
    } else {
      final t = targetDate.toUtc();
      final minBucket = (t.minute ~/ 10) * 10;
      cacheKey =
          '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}T${t.hour.toString().padLeft(2, '0')}:${minBucket.toString().padLeft(2, '0')}';
    }
    ChartResult? chart = _chartCacheByDate[cacheKey];
    if (chart == null) {
      chart = await fetchChart(
        birthDate: p.birthDate,
        birthTime: p.birthTime,
        birthLat: p.birthLat,
        birthLng: p.birthLng,
        birthTz: p.birthTz,
        birthTzName: p.birthTzName,
        targetDate: targetDate,
        relocateLat: useRelocate ? p.homeLat : null,
        relocateLng: useRelocate ? p.homeLng : null,
      );
      if (chart != null) {
        // LRU 風: 既存キーは末尾移動、超過時に先頭削除
        _chartCacheByDate.remove(cacheKey);
        _chartCacheByDate[cacheKey] = chart;
        if (_chartCacheByDate.length > _chartCacheMax) {
          _chartCacheByDate.remove(_chartCacheByDate.keys.first);
        }
      }
    }
    if (chart != null) {
      _chartResult = chart;
      final result = scoreAll(chart);
      final lines = buildPlanetLineData(center: _center, chart: chart);
      // Phase M2 論点3 + B1: アストロライン 120本を build (Worker呼出ゼロ)
      // = コンジャンクション本線40本 + アスペクト線80本 (square/trine/sextile)
      // 比較ベースは relocate=home優先・未設定なら出生地 (chart fetch と同じ)
      final baselineLng = useRelocate ? p.homeLng : p.birthLng;
      // Tier A #5 (CCG): 4フレーム同時計算
      // - natal:   baseline 由来 GMST (chart fetch時の MC + lng から逆算)
      // - dynamic: viewDate (= targetDate ?? now) UTC から計算した GMST
      //            transit/progressed planets は Worker 計算済み
      //            solarArc planets は natal+progressed から arc=Δsun を全惑星に加算
      final viewUtc = (targetDate ?? DateTime.now()).toUtc();
      final viewGmst = astro_lines.gmstHoursFromUtc(viewUtc);
      final natalLines = astro_lines.buildAstroLines(
        natal: chart.natal,
        baselineMc: chart.mc,
        baselineLng: baselineLng,
      );
      final transitLines = chart.transit != null
          ? astro_lines.buildAstroLinesAt(
              planets: chart.transit!,
              gmstHours: viewGmst,
              frame: astro_lines.AstroFrame.transit,
            )
          : const <astro_lines.AstroLine>[];
      final progressedLines = chart.progressed != null
          ? astro_lines.buildAstroLinesAt(
              planets: chart.progressed!,
              gmstHours: viewGmst,
              frame: astro_lines.AstroFrame.progressed,
            )
          : const <astro_lines.AstroLine>[];
      final solarArcMap = chart.progressed != null
          ? astro_lines.solarArcPlanets(
              natal: chart.natal,
              progressed: chart.progressed!,
            )
          : const <String, double>{};
      final solarArcLines = solarArcMap.isNotEmpty
          ? astro_lines.buildAstroLinesAt(
              planets: solarArcMap,
              gmstHours: viewGmst,
              frame: astro_lines.AstroFrame.solarArc,
            )
          : const <astro_lines.AstroLine>[];
      final astroLines = [
        ...natalLines,
        ...transitLines,
        ...progressedLines,
        ...solarArcLines,
      ];
      // 16方位合計の最高カテゴリを今日のドミナントとする
      String? topKey;
      double topSum = -1;
      for (final entry in result.fScores.entries) {
        final sum = entry.value.values.fold<double>(0, (a, b) => a + b);
        if (sum > topSum) {
          topSum = sum;
          topKey = entry.key;
        }
      }
      setState(() {
        _sectorScores
          ..clear()
          ..addAll(result.sScores);
        _sectorComps
          ..clear()
          ..addAll(result.sComp);
        _fComps
          ..clear()
          ..addAll(result.fComp);
        _scoreResult = result;
        _planetLines = lines;
        _astroLinesCache = astroLines;
        _topCategory = topKey != null ? kindFromKey(topKey) : null;
        _loadingChart = false;
      });
      // 5層目: この setState はブート中で最大の widget tree churn (セクター +
      // 最大480本のアストロライン構築 + 惑星線)。paint invalidation 漏れ
      // (タイルは fetch 済なのに描画 pipe が止まる) が最も起きやすい瞬間。
      // settle reset (4秒後) を待たず、ここで微小パン kick を打って即回復させる。
      // 詳細: memory/project_solara_map_paint_invalidation.md
      _kickPaintInvalidation();
      // トップカテゴリが確定したので Daily Transit Badge の状態を再評価
      await _checkDailyBadgeState();
      // 検索結果が残っていれば、新しい日付のスコアで再注入
      _reannotateSearchResults();
    } else {
      if (mounted) setState(() => _loadingChart = false);
    }
  }

  /// FF Label タップで循環切替するカテゴリの順序。
  /// 総合 → 癒し → 豊かさ → 恋愛 → 仕事 → 話す → 総合 ... の順で繰返す。
  static const _categoryCycle = <String>[
    'all', 'healing', 'money', 'love', 'work', 'communication',
  ];

  /// FF Label タップ時、_activeCategory を次のカテゴリへ進める。
  /// セクター描画も同フレームで再計算されるので扇状もリアルタイム切替される。
  void _cycleActiveCategory() {
    final idx = _categoryCycle.indexOf(_activeCategory);
    final nextIdx = (idx + 1) % _categoryCycle.length;
    setState(() {
      _activeCategory = _categoryCycle[nextIdx];
      // スコアバータップは「全体UIコンテキスト」変更扱いなので
      // 惑星フィルタも追従させる (旧挙動維持)。
      _planetFilterCategory = _activeCategory;
    });
    _reannotateSearchResults();
  }

  /// 検索結果距離・方位・スコアの起点座標。
  /// _searchVpIndex == -1: 検索実行時の地図中心 (= _searchOriginCenter)、
  /// >= 0: 該当 VPSlot の座標。
  /// _searchOriginCenter が未設定 (= 検索未実行) のときは VP Pin 位置 _center
  /// にフォールバック (旧挙動互換)。
  LatLng get _searchEffectiveCenter {
    if (_searchVpIndex >= 0 && _searchVpIndex < _vpSlotsCache.length) {
      final s = _vpSlotsCache[_searchVpIndex];
      return LatLng(s.lat, s.lng);
    }
    return _searchOriginCenter ?? _center;
  }

  /// 既存の検索結果（リスト + フォーカス1件）に、現在の中心・日付・カテゴリ・ソース
  /// で算出したスコアを再注入する。日付ピッカー・VP切替・カテゴリ切替から呼ぶ。
  void _reannotateSearchResults() {
    final hasHits = _searchHits.isNotEmpty;
    final hasFocus = _searchFocus != null;
    if (!hasHits && !hasFocus) return;
    final scores = _displayScores();
    final c = _searchEffectiveCenter;
    if (hasHits) {
      annotateHitsWithScores(
        hits: _searchHits,
        center: c,
        sectorScores: scores,
        scoreResult: _scoreResult,
      );
    }
    if (hasFocus) {
      annotateHitsWithScores(
        hits: [_searchFocus!],
        center: c,
        sectorScores: scores,
        scoreResult: _scoreResult,
      );
    }
    if (mounted) setState(() {});
  }

  // 旧 _pickDate / _resetDateToToday は MapTimeSlider 常時表示に置き換えで削除 (2026-04-29)。
  // 日付選択は MapTimeSlider の slider/▲▼/LIVE で完結する。

  /// 共通: 角丸付き全画面BottomSheet
  ///
  /// [barrierAlpha] 0xB3 (≈70% 黒) がデフォルト。
  /// メニューシート (display/astro/locations) ではマップ視認性のため低めに渡す。
  Future<void> _showSheet(
    Widget child, {
    double heightFrac = 0.9,
    int barrierAlpha = 0xB3,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Color((barrierAlpha << 24)),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * heightFrac,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: child,
        ),
      ),
    );
  }

  Future<void> _openLocations() async {
    // C-2: 検索中なら検索地を「現在地」として渡す (VP Pinより検索地優先)
    final effective = _searchFocus != null
        ? LatLng(_searchFocus!.lat, _searchFocus!.lng)
        : _center;
    await _showSheet(LocationsScreen(
      center: effective,
      scoreResult: _scoreResult,
      sectorScores: _displayScores(),
      profile: _profile,
      onSelectSlot: (slot) => _rebuild(LatLng(slot.lat, slot.lng)),
      onNavigateToSanctuary: widget.onNavigateToSanctuary,
    ));
    // 戻ったタイミングでスロット編集が反映されている可能性 → マーカー再描画
    await _reloadLocationSlots();
  }

  Future<void> _openForecast() {
    // FORECAST → Map のジャンプリンクは廃止 (2026-05-14)。
    // 両画面は別計算 (時刻・場所依存の差) で数字が一致せず、リンクがあると
    // 誤った同一視を招くため、画面間の暗黙的接続を切る。
    return _showSheet(
      ForecastScreen(
        onNavigateToSanctuary: widget.onNavigateToSanctuary,
      ),
      heightFrac: 0.92,
    );
  }

  // ── 左サイド ☰ 表示 / 📍 地点 メニューの開閉 (2026-05-09 第二弾) ───────
  // 相互排他: 一方を開く → 他方は自動的に閉じる。
  // 同じボタンの再タップでトグル (開→閉)。

  // 検索バー / 表示メニュー / 地点メニュー は配置位置が重なるため相互排他。
  // 1 つを開くと他は強制的に閉じる。

  void _onDisplayMenuTap() {
    setState(() {
      _displayMenuOpen = !_displayMenuOpen;
      if (_displayMenuOpen) {
        _viewpointMenuOpen = false;
        _searchOpen = false;
      }
    });
  }

  void _onViewpointMenuTap() {
    final wasOpen = _viewpointMenuOpen;
    setState(() {
      _viewpointMenuOpen = !_viewpointMenuOpen;
      if (_viewpointMenuOpen) {
        _displayMenuOpen = false;
        _searchOpen = false;
      }
    });
    if (wasOpen && !_viewpointMenuOpen) {
      _reloadLocationSlots();
    }
  }

  void _onSearchTap() {
    // 🔍 起動時は毎回テキスト初期化 + 即フォーカス (autofocus)。
    // 「戻る」(PopScope) で閉じた時はテキストを残すので、_clearAllSearch では
    // ctrl を触らない。明示的な ✕ 閉じと、再オープン時のみクリアする方針。
    _searchCtrl.clear();
    setState(() {
      _searchOpen = true;
      _displayMenuOpen = false;
      _viewpointMenuOpen = false;
    });
  }

  /// 検索 UI 関連 state を一括クリア (バー / focus / 結果リスト / フレーミング)。
  /// 端末 back ボタン (PopScope) で「検索系をまとめて消して Map に戻す」用途。
  void _clearAllSearch() {
    setState(() {
      _searchOpen = false;
      _searchFocus = null;
      _searchHits = [];
      _searchListCenter = null;
      _searchListZoom = null;
      _searchOriginCenter = null;
    });
  }

  // 旧 _formatSelectedDate は MapTimeSlider 内で表示するため削除 (2026-04-29)。

  /// 右上 Daily Transit Badge タップ時のハンドラ。
  /// プロフィール無 or トップカテゴリ未算出ならば何もしない。
  /// 「未閲覧（リセット時刻後初回）」: アニメ → 0.5s 余韻 → F1-c フルUI
  /// 「閲覧済み（同日2回目以降）」: アニメ無し、F1-c フルUI を直接フェードイン
  Future<void> _onDailyBadgeTap() async {
    if (_activeOverlay != null) return;
    if (_dailyTransitOpen) return;
    if (_noProfile) return;

    DominantFortuneKind? kind;
    if (_debugAlwaysShowOverlay && _debugCycleOverlayKinds) {
      kind = _debugCycleOrder[_debugCycleIdx];
      _debugCycleIdx = (_debugCycleIdx + 1) % _debugCycleOrder.length;
    } else {
      kind = _topCategory;
      if (_debugAlwaysShowOverlay && (kind == null || !_implementedOverlayKinds.contains(kind))) {
        kind = DominantFortuneKind.love;
      }
      if (kind == null) {
        // トップカテゴリ未算出: アニメ無しで F1-c だけ開く（カテゴリ表示は「TOP表示」）
        setState(() => _dailyTransitOpen = true);
        return;
      }
      if (!_implementedOverlayKinds.contains(kind)) {
        // アニメ未実装カテゴリ: F1-c のみ
        setState(() => _dailyTransitOpen = true);
        return;
      }
    }

    if (!mounted) return;

    // 同日2回目以降: アニメ skip して F1-c へ直接
    final shown = await SolaraStorage.wasOverlayShownToday(_overlayStorageKey);
    if (shown && !_debugAlwaysShowOverlay) {
      setState(() => _dailyTransitOpen = true);
      return;
    }

    // 初回: アニメ再生 → 完了後に F1-c 表示
    setState(() {
      _activeOverlay = kind;
      _dailyBadgeUnseen = false;
    });
    if (!_debugAlwaysShowOverlay) {
      await SolaraStorage.markOverlayShown(_overlayStorageKey);
    }
  }

  /// Dominant Fortune Overlay 完了時の処理。
  /// アニメ → 0.5s 余韻 → F1-c フルUI フェードイン
  Future<void> _onOverlayComplete() async {
    if (!mounted) return;
    setState(() => _activeOverlay = null);
    // 余韻 0.5 秒
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _dailyTransitOpen = true);
  }

  /// F1-c フル UI を閉じる。バッジは閲覧済み状態（光らない）に。
  void _onDailyTransitClose() {
    if (!mounted) return;
    setState(() {
      _dailyTransitOpen = false;
      _dailyBadgeUnseen = false;
    });
  }

  // 旧 _dailyTransitLocation / _dailyTransitLocationLabel は廃止 (2026-04-30)。
  // MapDailyTransitScreen 内部で VIEWPOINT dropdown により切替可能になった。
  // 親は出生地と vpSlots を渡すだけ。

  Future<void> _doSearch(String query) async {
    if (query.trim().length < 2) return;
    setState(() => _searching = true);
    // 検索 bias は「現在地図が見せている中心」を使う (VP Pin 位置 _center ではない)。
    // これにより 100km 離れた地に地図をパンしてから検索 → その表示地点周辺の
    // 結果が取れる。VP は引き続き 16 方位スコア計算の基準 (= 自宅基準) を担当。
    // 起動直後で MapController が camera 未確定の場合は _center にフォールバック。
    LatLng searchOrigin;
    try {
      searchOrigin = _mapCtrl.camera.center;
    } catch (_) {
      searchOrigin = _center;
    }
    _searchOriginCenter = searchOrigin;
    _searchVpIndex = -1; // 新規検索なので「地図中心」(= searchOrigin) にリセット

    final hits = await searchPlaces(query, biasCenter: searchOrigin);
    annotateHitsWithScores(
      hits: hits,
      center: _searchEffectiveCenter,
      sectorScores: _displayScores(),
      scoreResult: _scoreResult,
    );
    if (!mounted) return;
    setState(() {
      _searchHits = hits;
      _searching = false;
      _searchOpen = false;
      _searchFocus = null; // 前回の focus は破棄
    });
    if (hits.length == 1) {
      _selectSearchHit(hits.first);
    } else if (hits.length > 1) {
      // 複数候補: zoom 13 で表示域中心の周辺、中心をリスト上部へずらす
      _frameSearchArea(searchOrigin);
    }
    // 検索後に VP Pin が画面外なら 3 秒ガイダンス。
    // 16方位扇状の起点が見えていない状態 → ユーザーが混乱しないよう案内。
    // _frameSearchArea で地図が動いた後の visibleBounds で判定するため
    // postFrame で次フレーム以降に評価する。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final visible = _mapCtrl.camera.visibleBounds;
        if (!visible.contains(_center)) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'VIEWPOINT が画面外です。ズームアウト、または左上スコアバーから 16 方位の状況を確認できます。'),
            duration: Duration(seconds: 3),
          ));
        }
      } catch (_) {/* camera 未確定なら無視 */}
    });
  }

  /// 検索結果リストが画面下半分を覆う前提で、マップ中心を「南」にずらして
  /// 元の center が画面の上半分中央に来るようにする。
  /// ズームは都市内のエリア詳細が見える 13.0（オーナー判断 2026-04-30）。
  ///
  /// この時の (shifted, zoom) を保存しておき、hit 選択後に focus を閉じた際に
  /// `_restoreSearchListView` で同じ位置・ズームへ復元する。
  void _frameSearchArea(LatLng around) {
    final size = MediaQuery.of(context).size;
    // 検索結果リスト高さ = 画面の 45% (SearchResultList に渡している maxHeight と一致)
    // 上部の地図領域 (約55%) を広めに取り、店舗探索の視認性を上げる。
    final listH = size.height * 0.45;
    // リスト中心からのオフセット (この距離だけ地図中心を南に動かす)
    final offsetPx = listH / 2;
    // Web Mercator: 1° latitude = 256 * 2^zoom / 360 / cos(lat) px
    const zoom = 13.0;
    const zoomInt = 13;
    final pxPerLatDeg = 256 * (1 << zoomInt) /
        360 /
        math.cos(around.latitude * math.pi / 180);
    final offsetLat = offsetPx / pxPerLatDeg;
    final shifted = LatLng(around.latitude - offsetLat, around.longitude);
    _searchListCenter = shifted;
    _searchListZoom = zoom;
    try {
      _mapCtrl.move(shifted, zoom);
      _kickPaintInvalidation(); // 5層目: 描画 invalidation 漏れ対策
    } catch (_) {/* 初期化中は無視 */}
  }

  /// hit 選択後に focus を閉じた際、`_frameSearchArea` で記録した
  /// 元の一覧表示状態 (center, zoom) へ地図を戻す。
  /// 一覧表示前の状態が保存されていない場合は何もしない。
  void _restoreSearchListView() {
    final c = _searchListCenter;
    final z = _searchListZoom;
    if (c == null || z == null) return;
    try {
      _mapCtrl.move(c, z);
      _kickPaintInvalidation(); // 5層目: 描画 invalidation 漏れ対策
    } catch (_) {/* 初期化中は無視 */}
  }

  void _selectSearchHit(SearchHit hit) {
    final pos = LatLng(hit.lat, hit.lng);
    // Step 1: まず通常通り中央へ移動・ズーム (既存のレベル維持)
    _mapCtrl.move(pos, 15);
    _kickPaintInvalidation(); // 5層目: 描画 invalidation 漏れ対策
    setState(() {
      _searchFocus = hit;
      // _searchHits は維持。focus を閉じるとリストが復帰する。
    });
    // Step 2: 次フレームでカメラを南へシフトし、マーカーを画面上 30% 付近に
    // 配置する。下端からせり上がる Search Focus popup (font 拡大で高くなる)
    // にマーカーが隠れないようにするため。
    // 2026-05-08: フォントサイズ拡大時に popup がマーカーを覆う事象の対策。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cam = _mapCtrl.camera;
      final size = cam.nonRotatedSize;
      if (size.width <= 0 || size.height <= 0) return;
      // 現在のカメラ中心 = hit。 hit を画面上から 30% 位置に出すには、
      // カメラを「現在の (W/2, 70%H) にあるはずの座標」へ移動すればよい。
      final shiftedCenter = cam.screenOffsetToLatLng(
        Offset(size.width / 2, size.height * 0.70),
      );
      _mapCtrl.move(shiftedCenter, cam.zoom);
    });
  }

  /// 検索 focus 中の単一マーカー。
  /// リスト中の hit 順 (1〜20) をそのまま中心に表示し、選択した番号を保持する。
  /// 一覧マーカー(_buildSearchHitMarkers)より大きめ・影濃いめ。
  Marker _buildFocusedHitMarker() {
    final f = _searchFocus!;
    // _searchHits の中での位置 = リストでの番号
    // _selectSearchHit は _searchHits を破棄せず focus を立てるので indexOf が機能する。
    final idx = _searchHits.indexOf(f);
    final hasNumber = idx >= 0;
    return Marker(
      point: LatLng(f.lat, f.lng),
      width: 38,
      height: 38,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xE6C9A84C), // ゴールド (一覧マーカーと同色)
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0xCC000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: hasNumber
            ? Text(
                '${idx + 1}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF0C0C16),
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              )
            : null,
      ),
    );
  }

  /// 検索結果リスト中に地図上へ番号マーカー (1〜20) を描画する。
  /// 表示順 = リスト順 (Google RELEVANCE + locationBias)。
  /// タップで `_selectSearchHit` を呼び、リスト側でタップしたのと同等に focus する。
  List<Marker> _buildSearchHitMarkers() {
    final hits = _searchHits;
    final markers = <Marker>[];
    for (int i = 0; i < hits.length; i++) {
      final h = hits[i];
      markers.add(Marker(
        point: LatLng(h.lat, h.lng),
        width: 32,
        height: 32,
        // 円中心がピン先になるよう alignment 中央のままにする
        child: GestureDetector(
          onTap: () => _selectSearchHit(h),
          behavior: HitTestBehavior.opaque,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xE6C9A84C), // ゴールド円 (テーマ色)
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x99000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              '${i + 1}',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF0C0C16),
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
            ),
          ),
        ),
      ));
    }
    return markers;
  }

  Color get _sectorColor {
    final base = categoryColors[_activeCategory] ?? const Color(0xFFC9A84C);
    final isDark = mapStyleConfigs[_mapStyle]?.dark ?? true;
    Color color = base;
    if (!isDark) {
      // 明るい地図（OSM Light/Cycle Light）はパステル色が埋もれるため、
      // 明度を下げ彩度を上げて視認性を確保する。
      final hsl = HSLColor.fromColor(base);
      // all/money は強めのコントラスト、healing/love はさらに薄めに、他は中間。
      final isStrong = _activeCategory == 'all' || _activeCategory == 'money';
      final isLight = _activeCategory == 'healing' || _activeCategory == 'love';
      final double lightMul = isStrong ? 0.65 : (isLight ? 0.95 : 0.85);
      final double lightMax = isStrong ? 0.72 : (isLight ? 0.90 : 0.85);
      final double satMul = isStrong ? 1.2 : (isLight ? 0.80 : 0.95);
      color = hsl
          .withLightness((hsl.lightness * lightMul).clamp(0.0, lightMax))
          .withSaturation((hsl.saturation * satMul).clamp(0.0, 1.0))
          .toColor();
    }
    // Phase M2 論点9 (7-E2): 引越しレイヤーON時は16方位カラーをdim
    if (_astroLayers['relocate'] == true) {
      color = color.withAlpha((color.a * 255 * 0.4).round());
    }
    return color;
  }

  /// カテゴリ × ソース（transit/progressed/combined）に応じた
  /// 16方位スコアを算出する。セクター描画・FortuneFilterLabel 共通利用。
  /// _activeCategory == 'all' の場合は総合合算、それ以外はカテゴリ別 _fComps を使用。
  /// _activeSrc で transit/progressed/combined を切替。
  Map<String, double> _displayScores() {
    final comps = _activeCategory == 'all'
        ? _sectorComps
        : (_fComps[_activeCategory] ?? const <String, Map<String, double>>{});
    if (comps.isEmpty) return _sectorScores; // データ未取得時のフォールバック

    final keys = _activeSrc == 'transit'
        ? const ['tSoft', 'tHard']
        : _activeSrc == 'progressed'
            ? const ['pSoft', 'pHard']
            : compKeys;

    final result = <String, double>{};
    for (final d in dir16) {
      final c = comps[d] ?? const <String, double>{};
      double total = 0;
      for (final k in keys) {
        total += c[k] ?? 0;
      }
      result[d] = total;
    }
    return result;
  }

  /// 🔴 Solara設計思想: ソフト/ハード独立2エネルギー版の方位データ。
  /// セクター描画は本メソッドの戻り値を `sectorEnergies` に渡す。
  /// _activeSrc によりトランジット/プログレス/合計を切替。
  /// （詳細: project_solara_design_philosophy.md）
  Map<String, DirectionEnergy>? _displayEnergies() {
    final comps = _activeCategory == 'all'
        ? _sectorComps
        : (_fComps[_activeCategory] ?? const <String, Map<String, double>>{});
    if (comps.isEmpty) return null;

    final useT = _activeSrc == 'transit' || _activeSrc == 'combined';
    final useP = _activeSrc == 'progressed' || _activeSrc == 'combined';

    final result = <String, DirectionEnergy>{};
    for (final d in dir16) {
      final c = comps[d] ?? const <String, double>{};
      double soft = 0;
      double hard = 0;
      if (useT) {
        soft += c['tSoft'] ?? 0;
        hard += c['tHard'] ?? 0;
      }
      if (useP) {
        soft += c['pSoft'] ?? 0;
        hard += c['pHard'] ?? 0;
      }
      result[d] = DirectionEnergy(soft: soft, hard: hard);
    }
    return result;
  }

  /// 扇状の rank (1/2/3位) 別 alpha 倍率を activeCategory に応じて返す。
  /// スコア比正規化はせず、rank で固定差を出す (1位/2位/3位 を見て分かる差)。
  /// 2026-05-04 オーナー要望微調整:
  ///   - 総合 / 恋愛: 1位 少し濃く (1.15)
  ///   - 癒し / 仕事: 3位 薄く (0.30)
  ///   - 話す: 2位 薄く (0.55) / 3位 さらに薄く (0.20)
  List<double> _sectorRankAlphaMul() {
    switch (_activeCategory) {
      case 'all':
      case 'love':
        return const [1.15, 0.70, 0.40];
      case 'healing':
      case 'work':
        return const [1.00, 0.70, 0.30];
      case 'communication':
        return const [1.00, 0.55, 0.20];
      case 'money':
        return const [1.00, 0.70, 0.40];
      default:
        return const [1.00, 0.70, 0.40];
    }
  }

  /// HTML: rebuild(nc, fly) — center変更 + flyTo + セクター再計算 + 天体ライン再構築
  void _rebuild(LatLng newCenter) {
    _mapCtrl.move(newCenter, _mapCtrl.camera.zoom.clamp(12, 18).toDouble());
    _kickPaintInvalidation(); // 5層目: 描画 invalidation 漏れ対策
    setState(() {
      _center = newCenter;
      // 天体ラインは中心点から描画するので再構築
      if (_chartResult != null) {
        _planetLines = buildPlanetLineData(center: newCenter, chart: _chartResult!);
      }
    });
    // 中心が変われば検索結果の方位/距離/スコアも変わる
    _reannotateSearchResults();
  }

  /// flutter_map TileLayer の描画 invalidation 漏れ既知問題への対症療法。
  ///
  /// 症状: 検索詳細を 2-3 個開閉、または地図タップで移動した直後、
  /// マップが黒画面化する。エラーログは一切出ない。微小なパン操作で
  /// 即座に既存タイルが現れる (= タイルはキャッシュ済、描画だけ止まっている)。
  ///
  /// 原因 (推定): widget tree の連続変化で Flutter element reconcile が走るが、
  /// TileLayer の RenderObject に paint invalidation が伝わらない瞬間がある。
  /// 4 層防御 (mount 遅延 / reset Stream / settle reset 等) は fetch エラー
  /// 系の Case C 対策で、paint 系には効かない。
  ///
  /// 対策: postFrame で camera.center を 1e-7° (≈ 11mm) ずらして戻す。
  /// flutter_map がカメライベントを検知 → markNeedsPaint → 即再描画。
  /// ユーザーが手動でやってる「微小パン」を自動化したもの。
  ///
  /// 適用箇所: _mapCtrl.move を呼ぶ全ての location (_rebuild / _selectSearchHit /
  /// _frameSearchArea / _restoreSearchListView)。
  ///
  /// 副作用: 地理座標が 11mm ずれて戻るだけ、視覚的に検知不可能。
  /// 記録: memory/project_solara_map_paint_invalidation.md
  void _kickPaintInvalidation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final c = _mapCtrl.camera.center;
        final z = _mapCtrl.camera.zoom;
        _mapCtrl.move(LatLng(c.latitude + 1e-7, c.longitude), z);
      } catch (_) {/* 初期化中は無視 */}
    });
  }

  /// VP (_center) のみ更新。地図表示は動かさない。
  /// 検索チップから VP 切替する用途 (ユーザーが検索したい地域に地図を
  /// パンしている時、チップ選択で VP だけ変える)。
  void _setVpOnly(LatLng newCenter) {
    setState(() {
      _center = newCenter;
      if (_chartResult != null) {
        _planetLines = buildPlanetLineData(center: newCenter, chart: _chartResult!);
      }
    });
    _reannotateSearchResults();
  }

  /// 現在地 (GPS) で VP のみ更新。地図は動かさない。
  /// 検索チップ「📍 現在地」用。取得中は「現在地取得中…」snackbar を出す。
  Future<void> _setVpToCurrentLocationOnly() async {
    void snack(String msg, {int seconds = 3}) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: Duration(seconds: seconds)),
      );
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      snack('端末の位置情報サービスが OFF です。設定からONにしてください。');
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      snack('位置情報の利用が永久拒否されています。設定アプリから許可してください。',
          seconds: 4);
      return;
    }
    if (permission == LocationPermission.denied) {
      snack('位置情報の利用が拒否されました。');
      return;
    }

    snack('現在地取得中…', seconds: 2);
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (!mounted) return;
      _setVpOnly(LatLng(pos.latitude, pos.longitude));
    } catch (e) {
      snack('現在地の取得に失敗しました: $e');
    }
  }

  /// Astro*Carto*Graphy モード起動。
  /// 現状を退避 → 世界規模ビュー(出生地経度・緯度20°・zoom 2.5)+ ダーク強制 +
  /// relocate/aspect/aspectAll ON + 不要レイヤー OFF。
  void _enterAstroCartoMode() {
    if (_chartResult == null || _profile == null) return;
    _savedCenter = _center;
    _savedZoom = _mapCtrl.camera.zoom;
    _savedLayers = Map<String, bool>.from(_layers);
    _savedAstroLayers = Map<String, bool>.from(_astroLayers);
    _savedMapStyle = _mapStyle;

    setState(() {
      _astroCartoMode = true;
      // Daily POPUP が開いていれば即時閉じる (フッターの「世界規模で見る」
      // から呼ばれた場合、POPUP が裏に残ったまま ACG に切り替わると
      // 切り替わった感覚が薄れるため)。
      _dailyTransitOpen = false;
      _layers['sectors'] = false;
      _layers['compass'] = false;
      _astroLayers['planetLines'] = false;
      // 2026-05-11: ACG モード入時の relocate 強制 ON を撤廃。
      // 引越しは ACG メニューの「引越し」ピルで明示的に ON/OFF (排他モード)。
      // ON のとき: 地点タップで引越し popup のみ、他のタップ反応は抑制。
      // OFF のとき: 線/天頂/天底タップが従来通り反応。
      _astroLayers['relocate'] = false;
      // CCG (D2): モード入時は Transit を強制 ON (2026-05-08 ユーザー要望で
      // 旧 Natal → Transit に変更)。Transit は「今この瞬間」のラインで
      // 一番直感的に効果を実感できるため、初期表示として最適。
      // Natal/Progressed/SolarArc は Pills UI で個別切替可能。
      // aspectAll は強制 ON しない (FORTUNE Pills でカテゴリ絞込みする UX 用)。
      // 「総合」タップで activeCategory='all' → 自動で全惑星 100% になる。
      _astroLayers['aspect'] = false;
      _astroLayers['aspectTransit'] = true;
      // 2026-05-11 2 層メニュー化: Transit 線 ON と同時に Transit の天頂も自動 ON。
      // モード入時に第2層 4 トグル全 OFF だと「ラインだけで天頂マーカー無し」となり、
      // 旧仕様 (天頂自動表示) からの体験劣化を防ぐ。天底/天頂帯/天底帯は OFF のまま
      // (ユーザーが意識して ON する段階的 UX)。
      _astroLayers['zenith_transit'] = true;
      _activeAstroFrame = astro_lines.AstroFrame.transit; // 初期 active
      _acgMenuOpen = false; // モード入時はバーガー閉、地図最大表示
      _mapStyle = MapStyle.osmHotDark;
      // 既存メニュー/シート/ピンを片付け、世界規模ビューにフォーカス
      _displayMenuOpen = false;
      _viewpointMenuOpen = false;
      _searchOpen = false;
      _fortuneSheetOpen = false;
      _searchHits = [];
      _searchFocus = null;
      _searchOriginCenter = null;
      _relocateTapPoint = null;
      _zenithTapInfo = null;
    });
    SolaraStorage.saveMapStyleId(mapStyleConfigs[MapStyle.osmHotDark]!.id);

    // 世界全景 (zoom 2.5)。中心は「現住所優先、未設定なら出生地」の経度。
    // 表示緯度は出身/現住所の半球に追従:
    //   北半球 → 20°N (赤道よりやや北で南北バランス)
    //   南半球 → 20°S (赤道よりやや南、オーストラリア等のユーザー向け)
    final p = _profile!;
    final hasHome = !(p.homeLat == 0 && p.homeLng == 0);
    final centerLat = hasHome ? p.homeLat : p.birthLat;
    final centerLng = hasHome ? p.homeLng : p.birthLng;
    final viewLat = centerLat < 0 ? -20.0 : 20.0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        _mapCtrl.move(LatLng(viewLat, centerLng), 2.5);
        _kickPaintInvalidation();
      } catch (_) {/* 初期化中は無視 */}
    });
  }

  /// Astro*Carto*Graphy モード解除。退避した状態を完全復元。
  void _exitAstroCartoMode() {
    if (_savedCenter == null) return;
    final restoreCenter = _savedCenter!;
    final restoreZoom = _savedZoom!;
    final restoreLayers = _savedLayers!;
    final restoreAstroLayers = _savedAstroLayers!;
    final restoreStyle = _savedMapStyle!;

    setState(() {
      _astroCartoMode = false;
      _layers
        ..clear()
        ..addAll(restoreLayers);
      _astroLayers
        ..clear()
        ..addAll(restoreAstroLayers);
      _mapStyle = restoreStyle;
      _relocateTapPoint = null;
      _zenithTapInfo = null;
      _activeAstroFrame = null;
      _acgMenuOpen = false;
    });
    SolaraStorage.saveMapStyleId(mapStyleConfigs[restoreStyle]!.id);
    _savedCenter = null;
    _savedZoom = null;
    _savedLayers = null;
    _savedAstroLayers = null;
    _savedMapStyle = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        _mapCtrl.move(restoreCenter, restoreZoom);
        _kickPaintInvalidation();
      } catch (_) {/* 無視 */}
    });
  }

  /// GPS で現在地を取得し、地図中心をその位置に移動。
  /// 内部で _rebuild を呼ぶので VP Pin (_center) も GPS 位置になる。
  /// 「この地点を保存」と組合せれば現在地を VP として登録可能。
  ///
  /// エラー処理:
  ///   - 位置情報サービス OFF → SnackBar 案内
  ///   - 権限拒否 → 権限リクエスト → 再拒否なら案内
  ///   - 永久拒否 → 設定アプリから許可するよう案内
  ///   - 取得タイムアウト / 例外 → SnackBar
  Future<void> _geolocate() async {
    void snack(String msg, {int seconds = 3}) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: Duration(seconds: seconds)),
      );
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      snack('端末の位置情報サービスが OFF です。設定からONにしてください。');
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      snack('位置情報の利用が永久拒否されています。設定アプリから許可してください。',
          seconds: 4);
      return;
    }
    if (permission == LocationPermission.denied) {
      snack('位置情報の利用が拒否されました。');
      return;
    }

    snack('現在地を取得中…', seconds: 2);
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (!mounted) return;
      _rebuild(LatLng(pos.latitude, pos.longitude));
    } catch (e) {
      snack('現在地の取得に失敗しました: $e');
    }
  }

  // ══════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    // 物理戻るボタン (Android) で overlay/popup を上から順に閉じる。
    // 全 overlay が閉じている時のみ canPop=true で main.dart の root PopScope
    // (= タブ Map に戻す or アプリ終了) に伝播する。
    //
    // 優先順位 (上から処理):
    //   1. Daily Transit popup
    //   2. Fortune Sheet (運勢方位)
    //   3. Zenith popup (天頂タップ、 ACG モード中にも開く)
    //   4. Relocation popup (ACG line tap、 Stack ベース)
    //      → ACG モード中なら閉じても ACG は維持 (= ACG に戻る)
    //   5. 時刻バー展開 (MapTimeSlider 内 _timeRowExpanded、 GlobalKey 経由制御)
    //   6. ACG (Astro*Carto*Graphy) モード
    //   7. 表示メニュー / 地点メニュー (左サイド展開メニュー)
    //   8. 検索バー (= _searchOpen / focus / hits を一括クリア)
    //
    // 注: 以下は Navigator stack (showDialog / showModalBottomSheet) に
    // 乗っているため Flutter 標準で back 自動処理される (この PopScope 不要):
    //   - showLineNarrativeSheet (相 narrative 詳細 modal sheet)
    //   - showInfoPopup 各種
    final hasSearchUi = _searchOpen || _searchFocus != null || _searchHits.isNotEmpty;
    final hasOverlay = _dailyTransitOpen ||
        _fortuneSheetOpen ||
        _zenithTapInfo != null ||
        _relocateTapPoint != null ||
        _timeRowExpanded ||
        _astroCartoMode ||
        _acgMenuOpen ||
        _displayMenuOpen ||
        _viewpointMenuOpen ||
        hasSearchUi;
    return PopScope(
      canPop: !hasOverlay,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // 上から順に 1 つだけ閉じる (back 1 回 = overlay 1 つ閉じる)
        if (_dailyTransitOpen) {
          _onDailyTransitClose();
        } else if (_fortuneSheetOpen) {
          setState(() => _fortuneSheetOpen = false);
        } else if (_zenithTapInfo != null) {
          setState(() => _zenithTapInfo = null);
        } else if (_relocateTapPoint != null) {
          setState(() => _relocateTapPoint = null);
        } else if (_timeRowExpanded) {
          _timeSliderKey.currentState?.closeTimeRow();
        } else if (_acgMenuOpen) {
          // ACG モード中: バーガーを優先で閉じる (モード解除より前)
          setState(() => _acgMenuOpen = false);
        } else if (_astroCartoMode) {
          _exitAstroCartoMode();
        } else if (_displayMenuOpen) {
          setState(() => _displayMenuOpen = false);
        } else if (_viewpointMenuOpen) {
          setState(() => _viewpointMenuOpen = false);
        } else if (hasSearchUi) {
          _clearAllSearch();
        }
      },
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    // 4層防御モデル 第2層: warmup + style 確定まで FlutterMap mount を遅延。
    // 起動時に黒画面 + ローディング表示。warmup の prewarm OK ログが出てから mount される。
    // 通常 50ms〜3秒程度。これにより初期 fetch を必ず warm 状態で起こす。
    if (!_bootReady) {
      return const ColoredBox(
        color: Color(0xFF080C14),
        child: Center(
          child: SizedBox(
            width: 32, height: 32,
            child: CircularProgressIndicator(
              color: Color(0xFFE8C26B),
              strokeWidth: 2.5,
            ),
          ),
        ),
      );
    }
    final topPad = MediaQuery.of(context).padding.top;
    // 2026-04-29: NavBar 被り問題の根本解決。オーバーレイ群を内側の Padded Stack に
    // 集約し、bottom: 0 = NavBar の上端 として扱う。各 widget で navInset を
    // 手動加算する必要がなく、新規追加時の被りリスクが原則無くなる。
    // FlutterMap だけは全画面のまま (NavBar 越しに blur が効く視覚効果を保持)。

    return Stack(
      children: [
        // ── Map ──
        FlutterMap(
          mapController: _mapCtrl,
          options: MapOptions(
            initialCenter: _center, initialZoom: 14,
            // minZoom 2.5: 過去 commit 9afde1b の ACG 緯度線 NaN 修正と同根の
            // 対策。ズームアウト極端時に MapCamera.projectAtZoom が Mercator
            // 投影限界 (lat ±85°) を超えて NaN を返し、TileLayer の
            // _onTileUpdateEvent が NaN カスケードして赤画面化していた。
            // ACG モードも zoom 2.5 を使うので最小値はそこに固定。
            minZoom: 2.5, maxZoom: 19,
            // cameraConstraint: 可視範囲を Mercator 安全域に閉じる。
            // 緯度 ±85.05° は WebMercator の北南端、ここを超えると tan(lat) が
            // 発散して NaN が出る。経度はラップ ±180° のままで OK。
            cameraConstraint: CameraConstraint.contain(
              bounds: LatLngBounds(
                const LatLng(-85.0, -180.0),
                const LatLng(85.0, 180.0),
              ),
            ),
            backgroundColor: mapStyleConfigs[_mapStyle]!.backgroundColor,
            // 防御層: ジェスチャー中に万一 camera.center が NaN になったら
            // 即座に検出して安全な状態へリセット。flutter_map 内部のピンチ
            // ズーム math が稀に NaN を生成するケースの最終救済。
            onPositionChanged: (camera, hasGesture) {
              final c = camera.center;
              if (!c.latitude.isFinite || !c.longitude.isFinite) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  try {
                    _mapCtrl.move(_center, 5);
                  } catch (_) {/* 再帰防止 */}
                });
              }
            },
            // FlutterMap 内部初期化完了通知。
            // 出生地が先に揃って _pendingInitialMove が積まれていればここで消化。
            //
            // 2026-05-09: 多段 viewport キックを廃止。FlutterMap 自体の mount を
            // _bootReady=true (warmup + style 完了) まで遅延しているため、初期 fetch は
            // 既に warm 状態で起こる。kick で「TileLayer を起こす」必要がなくなった。
            // 万一の Case C 救済は settle reset (4 秒後の reset Stream 発火) が担当。
            onMapReady: () {
              _mapReady = true;
              final pending = _pendingInitialMove;
              if (pending != null) {
                _pendingInitialMove = null;
                _mapCtrl.move(pending, _mapCtrl.camera.zoom);
              }
            },
            // 回転ジェスチャー無効化 (2026-04-29):
            // Solara Map は北上固定前提 (16方位セクター・コンパス・VP Pin の方位概念が
            // 回転で破綻する)。ピンチズーム時の指のひねりで誤回転していた問題を解消。
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
            // HTML: long-press 600ms → rebuild(nc, fly:true)
            onLongPress: (tapPos, latlng) => _rebuild(latlng),
            // タップ動作の二択:
            //   ① relocate ON (排他モード) → 地点タップで必ず引越し popup を出す
            //   ② relocate OFF + aspect 系 ON → 近接線があれば線 popup
            //   いずれにも当てはまらないタップは無視。
            //
            // 2026-05-11: 「引越し」トグルを排他モードに変更。
            //   ON 中: ライン/天頂/天底タップは反応しない (引越し popup のみ)。
            //   マーカー側の onTap も relocate 中は null を渡して抑制 (下記参照)。
            onTap: (tapPos, latlng) {
              if (_chartResult == null) return;
              final relocateOn = _astroLayers['relocate'] == true;
              if (relocateOn) {
                setState(() {
                  _relocateTapPoint = latlng;
                  _zenithTapInfo = null;
                });
                return;
              }
              final aspectOn = _astroLayers['aspect'] == true ||
                  _astroLayers['aspectTransit'] == true ||
                  _astroLayers['aspectProgressed'] == true ||
                  _astroLayers['aspectSolarArc'] == true;
              if (!aspectOn) return;
              final near = _findNearbyAstroLines(latlng);
              if (near.isEmpty) return;
              setState(() {
                _relocateTapPoint = latlng;
                _zenithTapInfo = null;
              });
            },
          ),
          children: [
            buildStyledTileLayer(
              _mapStyle,
              resetStream: _tileResetCtrl.stream,
              onTileError: _onTileError,
            ),
            // 出生情報が無い間はセクターを描画しない（スコアが乱数になるため）
            if (!_noProfile) PolygonLayer(polygons: buildSectors(
              center: _center,
              // soft+hard 合算済スコア (=`_displayScores()`)
              sectorScores: _displayScores(),
              // 🔴 activeCategory のカテゴリ色 1色 (スコアバーと同じ色 = 唯一の正解)
              // 詳細: project_solara_design_philosophy.md「Map扇状の例外」節
              sectorColor: _sectorColor,
              visible: _layers['sectors']!,
              lightMap: !(mapStyleConfigs[_mapStyle]?.dark ?? true),
              dimFactor: _astroLayers['relocate'] == true ? 0.4 : 1.0,
              rankAlphaMul: _sectorRankAlphaMul(),
            )),
            PolylineLayer(polylines: buildCompass(center: _center, visible: _layers['compass']!)),
            // HTML: addPlanetLines() — natal/progressed/transit 天体ライン
            // Phase M2 論点5: ASTRO『惑星ライン』メタトグル (planetLines) で全体ON/OFF
            if (_planetLines.isNotEmpty && (_astroLayers['planetLines'] ?? true))
              PolylineLayer(polylines: buildPlanetPolylines(
                lines: _planetLines, layers: _layers,
                planetGroupVis: _planetGroups, activeCategory: _planetFilterCategory,
              )),
            if (_planetLines.isNotEmpty && (_astroLayers['planetLines'] ?? true))
              PlanetSymbolsLayer(
                lines: _planetLines, layers: _layers,
                planetGroupVis: _planetGroups, activeCategory: _planetFilterCategory,
                onTap: (planet, frame) => showPlanetIntroPopup(
                  context: context,
                  planetKey: planet,
                  frame: frame,
                ),
              ),
            // Phase M2 論点3 + Tier A #5 (CCG): 4フレームのアスペクト線
            // _visibleAstroLines() で _astroLayers の natal/transit/progressed/solarArc トグルから絞り込む
            if (_visibleAstroLines().isNotEmpty)
              PolylineLayer(polylines: buildAstroPolylines(
                lines: _visibleAstroLines(),
                activeCategory: _planetFilterCategory,
                allPlanetMode: _astroLayers['aspectAll'] ?? false,
              )),
            // ── L3 / Lewis: 天頂帯・天底帯 (緯度線) ──
            // フレーム別 zenithBand_* / nadirBand_* で個別 ON/OFF (2層メニュー)。
            // 統合関数 1 つで両方描画 (lines を 1 度だけ走査、PolylineLayer も 1 つ)。
            // マーカーより下のレイヤーに置き、マーカーが上に乗る配置。
            if ((_zenithBandFrames().isNotEmpty ||
                    _nadirBandFrames().isNotEmpty) &&
                _astroLinesCache.isNotEmpty)
              PolylineLayer(polylines: buildAstroLatitudeBandPolylines(
                lines: _astroLinesCache,
                activeCategory: _planetFilterCategory,
                allPlanetMode: _astroLayers['aspectAll'] ?? false,
                zenithFrames: _zenithBandFrames(),
                nadirFrames: _nadirBandFrames(),
              )),
            // 天頂点マーカー (CCG): zenith_<frame> ON のフレームのみ描画。
            // relocate 排他モード中はマーカー onTap を null にして反応抑制。
            if (_zenithMarkerFrames().isNotEmpty && _astroLinesCache.isNotEmpty)
              MarkerLayer(markers: buildAstroZenithMarkers(
                lines: _astroLinesCache,
                activeCategory: _planetFilterCategory,
                allPlanetMode: _astroLayers['aspectAll'] ?? false,
                framesWithZenith: _zenithMarkerFrames(),
                onTap: (_astroLayers['relocate'] == true)
                    ? null
                    : (planetKey, frame, point) => setState(() {
                          _zenithTapInfo = (planet: planetKey, frame: frame, point: point, isNadir: false);
                          _relocateTapPoint = null; // 排他: 線+ハウス popup を閉じる
                        }),
              )),
            // 天底点マーカー: nadir_<frame> ON のフレームのみ描画。
            if (_nadirMarkerFrames().isNotEmpty && _astroLinesCache.isNotEmpty)
              MarkerLayer(markers: buildAstroNadirMarkers(
                lines: _astroLinesCache,
                activeCategory: _planetFilterCategory,
                allPlanetMode: _astroLayers['aspectAll'] ?? false,
                framesWithNadir: _nadirMarkerFrames(),
                onTap: (_astroLayers['relocate'] == true)
                    ? null
                    : (planetKey, frame, point) => setState(() {
                          _zenithTapInfo = (planet: planetKey, frame: frame, point: point, isNadir: true);
                          _relocateTapPoint = null;
                        }),
              )),
            // 16方位ラベル: モード中は世界規模ビューでは意味を成さないので非表示
            if (!_astroCartoMode)
              MarkerLayer(markers: buildDirLabels(center: _center)),
            // 登録地マーカー (出生地🌟+グロー / VP slots / Locations slots)
            // 通常Map / Astro*Carto*Graphy モード共通で表示。
            if (!_noProfile)
              MarkerLayer(markers: buildLocationMarkers(
                profile: _profile,
                vpSlots: _vpSlotsCache,
                locationSlots: _locSlotsCache,
                onTap: (name, point, isBirth) => setState(() {
                  _locationTapInfo = (name: name, point: point, isBirth: isBirth);
                }),
              )),
            // 検索結果リスト中: 各 hit に番号マーカー (1〜20) を描画。
            // タップで _selectSearchHit (= 該当 hit にズームイン + Focus popup)。
            // focus 中は数字マーカーを消し、下の CircleLayer のゴールド円のみ表示。
            if (_searchHits.isNotEmpty && _searchFocus == null)
              MarkerLayer(markers: _buildSearchHitMarkers()),
            // 検索 focus 中マーカー: リストでタップした番号(1〜20)を中心に表示。
            // 2026-04-30: 数字なし金色丸 → 番号付き金色丸に変更（オーナー要望）。
            // 一覧時マーカー(32x32)より少し大きく 38x38、影濃いめで「選択中」を強調。
            if (_searchFocus != null)
              MarkerLayer(markers: [_buildFocusedHitMarker()]),
            // VP Pin — HTML: draggable gold circle, dragend → rebuild
            // モード中は VP ピン非表示 (世界規模ビューでは中心の概念が無意味)
            if (!_astroCartoMode)
              MarkerLayer(markers: [
                buildVpPinMarker(
                  mapCtrl: _mapCtrl,
                  center: _center,
                  screenSize: MediaQuery.of(context).size,
                  onCenterChange: (c) => setState(() => _center = c),
                  onDragEnd: () {
                    setState(() {});
                    _reannotateSearchResults();
                  },
                ),
              ]),
          ],
        ),

        // ── 中央十字マーカー (常時表示) ──
        // 外側 Stack に直接置く (= FlutterMap と同じ全画面領域)。
        // 旧: 下の SafeArea(bottom:true)-wrap された内側 Stack に置いていたが、
        // SafeArea が NavBar 分の bottom padding を消費するため Center 位置が
        // 画面中央より NavBar半分 上にズレていた。FlutterMap の VP Pin は
        // 全画面の中央に出るので、十字も同じ全画面 Stack 階層で Center する
        // 必要がある (2026-05-13 ユーザー指摘: + と〇 がずれてる)。
        // ACG モードでは中心の概念が薄れるため非表示。
        if (!_astroCartoMode)
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: SizedBox(
                  width: 28, height: 28,
                  child: Stack(children: [
                    Center(child: Container(
                      width: 2, height: 28,
                      color: const Color(0xCCC9A84C))),
                    Center(child: Container(
                      width: 28, height: 2,
                      color: const Color(0xCCC9A84C))),
                    Center(child: Container(
                      width: 6, height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFC9A84C)))),
                  ]),
                ),
              ),
            ),
          ),

        // ── 座標取得ラベル (Map L2「座標取得」トグル ON 時のみ) ──
        // 同じ理由で外側 Stack 階層に配置 (十字と同じ画面中央基準にするため)。
        // 画面中央 + の少し下に緯度経度ラベル。地図を動かすと
        // mapEventStream 経由で再描画され、リアルタイムに座標が追従。
        // タップでクリップボードにコピー。
        // 常時表示は地図が見にくいのでトグル制 (2026-05-13)。
        if (!_astroCartoMode && (_layers['coords'] ?? false))
          Positioned.fill(
            child: StreamBuilder<MapEvent>(
              stream: _mapCtrl.mapEventStream,
              builder: (ctx, _) {
                final c = _mapCtrl.camera.center;
                final coordsText =
                    '${c.latitude.toStringAsFixed(5)}, ${c.longitude.toStringAsFixed(5)}';
                return Center(
                  // 十字 (28px) の下端 + gap でラベルを置く。
                  // Stack 中央 (= 画面中央) から 14 (十字半分) + 4 (gap) +
                  // ~12 (ラベル半分) = 30px 下にラベル中心を持っていく。
                  child: Transform.translate(
                    offset: const Offset(0, 30),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () async {
                        await Clipboard.setData(
                            ClipboardData(text: coordsText));
                        if (!ctx.mounted) return;
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                          content: Text('座標をコピー: $coordsText'),
                          duration: const Duration(seconds: 2),
                        ));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xCC0C0C16),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: const Color(0x66C9A84C)),
                        ),
                        child: Text(
                          coordsText,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFE9D29A),
                            fontFamily: 'monospace',
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

        // ── オーバーレイ全体: NavBar 上端までの領域に閉じ込める ──
        // SafeArea で Scaffold が自動設定する body padding.bottom (= NavBar 実高、
        // extendBody:true 時は NavBar が含まれる) を尊重する。これで端末や設定
        // ごとに変わる NavBar 高を Scaffold 任せで処理できる (手動計算で
        // ズレるリスクを排除)。
        // 内側の Stack 内では bottom: 0 = NavBar 上端。手動 navInset 不要。
        // 内側 SafeArea (popup 内等) は外側 SafeArea で消費済みのため二重 padding
        // しない。
        // 注: 画面正中心に出したい widget (中央十字 + 座標ラベル) はこの
        // SafeArea-wrap の中に入れると NavBar 分上にズレるので、上の階層
        // (= 外側 Stack 直下) に置くこと。
        Positioned.fill(
          child: SafeArea(
            top: false, left: false, right: false,
            child: Stack(children: [

        // ── FF Label (スコアバー) + 日付タイムスライダーを縦 stack ──
        // 2026-05-08: 端末フォントサイズ拡大でバーの高さが変わって干渉する
        // 事象を解消するため、絶対配置 (top:2 / top:44) を Column 化。
        // スコアバーの実高さに応じて日付バーが自動で下に追従する。
        // 境目には SizedBox(height: 6) で視覚的なギャップを確保。
        //
        // モード中は「世界規模スコア」の概念が無いのでスコアバーは非表示。
        // ラベルタップでカテゴリ循環切替（オーナー要望、2026-04-30）。
        Positioned(
          // ACG モード時は Banner が先頭、通常 (プロフィールあり) は
          // FortuneFilterLabel が先頭、通常 (プロフィールなし) のみ
          // 上に余白 (44) を確保 (元のスコアバッジ表示位置と同じ)。
          top: topPad + ((_noProfile && !_astroCartoMode) ? 44 : 2),
          left: 12, right: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_astroCartoMode) ...[
                // ACG タイトルバナー: フォント拡大時に下の TimeSlider と
                // 重ならないよう SizedBox(8) で一定間隔を確保する。
                // 旧: 独立した Positioned(top: topPad+2) で固定配置 →
                //     TimeSlider (top+44) と 42px 固定差で、フォント拡大で重なっていた。
                Center(child: AstroCartoBanner(onClose: _exitAstroCartoMode)),
                const SizedBox(height: 8),
              ] else if (!_noProfile) ...[
                // 元の left:16 と整列維持 (親の left:12 + ここの padding:4 = 16)。
                // FortuneFilterLabel 内の sideMargin=16 計算と整合する。
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: FortuneFilterLabel(
                    sectorScores: _displayScores(),
                    activeSrc: _activeSrc,
                    activeCategory: _activeCategory,
                    onTap: _cycleActiveCategory,
                  ),
                ),
                // スコアバーと日付バーの境目 gap
                const SizedBox(height: 6),
              ],
              // 日付タイムスライダー (常時表示)
              // ◀▶ 1日ステッパ + ±365日スライダー + NOW + ⏰ で時刻行展開
              MapTimeSlider(
                key: _timeSliderKey,
                date: _selectedDate,
                onExpandedChanged: (e) =>
                    setState(() => _timeRowExpanded = e),
                onCommit: (d) async {
                  setState(() => _selectedDate = d);
                  await _loadProfileAndChart(targetDate: d);
                },
              ),
            ],
          ),
        ),

        // ── 左サイド 3 ボタン: 🔍 検索 / ☰ 表示 / 📍 地点 ──
        // 表示・地点メニューは右に展開する別ウィジェットで描画 (下記)。
        if (!_astroCartoMode) MapSideButtons(
          topPad: topPad,
          searchOpen: _searchOpen,
          displayMenuOpen: _displayMenuOpen,
          viewpointMenuOpen: _viewpointMenuOpen,
          onSearchTap: _onSearchTap,
          onDisplayMenuTap: _onDisplayMenuTap,
          onViewpointMenuTap: _onViewpointMenuTap,
        ),

        // ACG タイトルバナーは上部 TimeSlider Positioned 内に統合済み
        // (フォント拡大時に下の TimeSlider と重ならないよう Column で順次配置)。
        // ここは ACG モード用 UI の積み下ろし開始点

        // ── Search Bar ──
        if (_searchOpen) Positioned(
          top: topPad + 152, left: 16, right: 16,
          // VP チップ列 (上) + 検索バー (下) を縦 Column。
          // 検索前に「16方位の基準点 (VP) をどこにするか」を明示選択。
          // タップで VP のみ更新 (_setVpOnly) し地図は動かさない。
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SearchVpChipRow(
                vpSlots: _vpSlotsCache,
                currentVp: _center,
                onCurrentLocationTap: _setVpToCurrentLocationOnly,
                onSlotTap: _setVpOnly,
                onHelpTap: () => _showSearchVpHelpPopup(context),
              ),
              const SizedBox(height: 6),
              SearchBarOverlay(
                controller: _searchCtrl,
                onSubmitted: _doSearch,
                // ✕ は明示的閉じ = テキストもクリア。Android back (PopScope) は
                // _clearAllSearch 経由でテキスト保持されるので別経路。
                onClose: () => setState(() {
                  _searchOpen = false;
                  _searchCtrl.clear();
                }),
              ),
            ],
          ),
        ),

        // ── 表示メニュー (☰ボタン → 検索ボックス高さで右展開) ──────
        // 2026-05-09 第四弾: 全幅 → 左サイドボタン (🔍/☰/📍) を見せるため left:60。
        // 縦位置は検索バーと同じ top+152 を維持 (オーナー要望)。
        // 検索バー / 地点メニューとは相互排他 (タップハンドラで他を閉じる)。
        if (_displayMenuOpen && !_astroCartoMode) ...[
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => setState(() => _displayMenuOpen = false),
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            top: topPad + 152, left: 60, right: 16,
            child: MapDisplayMenu(
              layers: _layers,
              planetGroups: _planetGroups,
              astroLayers: _astroLayers,
              planetFilterCategory: _planetFilterCategory,
              mapStyle: _mapStyle,
              onLayerToggle: (k) => setState(() => _layers[k] = !(_layers[k] ?? false)),
              onPlanetGroupToggle: (k) => setState(() => _planetGroups[k] = !(_planetGroups[k] ?? false)),
              onAstroToggle: (k) => setState(() {
                _astroLayers[k] = !(_astroLayers[k] ?? false);
                if (k == 'relocate' && !(_astroLayers[k] ?? false)) {
                  _relocateTapPoint = null;
                }
              }),
              // 惑星>テーマ は惑星フィルタのみを更新 (扇状非干渉)
              onPlanetFilterChanged: (k) => setState(() => _planetFilterCategory = k),
              onMapStyleChanged: _onMapStyleChanged,
            ),
          ),
        ],

        // ── 地点メニュー (📍ボタン → 縦フル展開) ─────────────────
        // 2026-05-09 第五弾: maxHeight 40% 制約を撤廃 (オーナー要望)。
        // 旧設計ではアイコン/名称変更の submenu が下端で見切れていた。
        // 「見えない方が問題」とのオーナー判断で縦は bottom:16 までフル展開。
        // チップバーは menu 開いている間は非表示 (重なり回避、下記参照)。
        if (_viewpointMenuOpen && !_astroCartoMode) ...[
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                setState(() => _viewpointMenuOpen = false);
                _reloadLocationSlots();
              },
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            top: topPad + 6, left: 60, right: 16, bottom: 16,
            child: MapViewpointMenu(
              center: _searchFocus != null
                  ? LatLng(_searchFocus!.lat, _searchFocus!.lng)
                  : _center,
              profile: _profile,
              onSlotSelected: (slot) {
                _rebuild(LatLng(slot.lat, slot.lng));
                setState(() => _viewpointMenuOpen = false);
                _reloadLocationSlots();
              },
              onGeolocate: _geolocate,
              onClose: () {
                setState(() => _viewpointMenuOpen = false);
                _reloadLocationSlots();
              },
              onSlotsChanged: _reloadLocationSlots,
            ),
          ),
        ],

        // ── 下部チップバー (Daily Transit / 運勢方位 / LOCATIONS / 予報) ──
        // 2026-05-09 第二弾: 利用頻度トップ4を下部主役チップに集約。
        // Daily Transit は未閲覧時に halo 発光 (旧右上バッジの代替)。
        // ACG モード中・運勢方位 Sheet 展開中・地点メニュー縦フル展開中は非表示。
        // 2026-05-13: 検索中も非表示 (キーボード上に押し上げられて地図領域を
        // 圧迫するため、地図を最大化する目的で隠す)。
        if (!_astroCartoMode &&
            !_fortuneSheetOpen &&
            !_viewpointMenuOpen &&
            !_searchOpen) Positioned(
          bottom: 0, left: 0, right: 0,
          child: MapMenuChips(
            dailyTransitUnseen: _dailyBadgeUnseen,
            dailyTransitDisabled: _noProfile,
            topCategory: _topCategory,
            onDailyTransitTap: _onDailyBadgeTap,
            onFortuneTap: _noProfile
                ? () {} // プロフィール未設定時は無効化 (FortuneSheet も意味を成さない)
                : () => setState(() => _fortuneSheetOpen = true),
            onLocationsTap: _openLocations,
            onForecastTap: _openForecast,
          ),
        ),

        // ── 右下「現在地に移動」ボタン ──
        // 下部チップバー (高さ 72: _kChipHeight 60 + container padding 12) の
        // 直上 8px gap、Forecast チップの上に重ねる位置。
        // 右端寄せ (right: 12) でタップしやすさ重視。
        // チップバー非表示の条件と完全に揃える (同じ理由で隠す)。
        // 検索中は VP チップ列内の「📍 現在地」で代替できるため非表示。
        if (!_astroCartoMode &&
            !_fortuneSheetOpen &&
            !_viewpointMenuOpen &&
            !_searchOpen) Positioned(
          right: 12,
          bottom: 80,
          child: MapBtn(
            onTap: _geolocate,
            child: const Icon(Icons.my_location,
                size: 20, color: Color(0xFFC9A84C)),
          ),
        ),

        // ── Fortune Sheet ──
        if (!_noProfile && _fortuneSheetOpen && !_astroCartoMode) Positioned(
          bottom: 0, left: 0, right: 0,
          child: FortuneSheet(
            activeSrc: _activeSrc,
            activeCategory: _activeCategory,
            // 'all' 時は総合 sComp、それ以外はカテゴリ別 fComp を渡す
            sectorComps: _activeCategory == 'all'
                ? _sectorComps
                : (_fComps[_activeCategory] ?? _sectorComps),
            // E4: 2エネルギー詳細ポップアップ用データ
            sectorEnergies: _displayEnergies(),
            sectorContributors: _activeCategory == 'all'
                ? _scoreResult?.sContributors
                : _scoreResult?.fContributors[_activeCategory],
            onSrcChanged: (s) {
              setState(() => _activeSrc = s);
              _reannotateSearchResults();
            },
            onCatChanged: (c) {
              setState(() {
                _activeCategory = c;
                _planetFilterCategory = c; // 全体カテゴリ変更時は惑星フィルタも同期
              });
              _reannotateSearchResults();
            },
            onClose: () => setState(() => _fortuneSheetOpen = false),
          ),
        ),

        // ── Search Result List（複数候補） ──
        // focus 中はリスト非表示。focus を閉じるとリスト復帰。
        if (_searchHits.isNotEmpty && _searchFocus == null) Positioned(
          bottom: 0, left: 8, right: 8,
          child: SearchResultList(
            hits: _searchHits,
            center: _searchEffectiveCenter,
            // 0.45 = ハーフサイズより少し小さめ。地図領域を広めに取る (オーナー判断)
            maxHeight: MediaQuery.of(context).size.height * 0.45,
            onTap: _selectSearchHit,
            onClose: () => setState(() {
              _searchHits = [];
              _searchListCenter = null;
              _searchListZoom = null;
              _searchVpIndex = -1; // 次回検索の起点を地図中心に戻す
              _searchOriginCenter = null;
              _searchCtrl.clear(); // 結果リスト ✕ も明示的閉じ扱い
            }),
            // 2026-05-13: VP dropdown 廃止 → 検索バー上部チップ列に統一
            activeCategory: _activeCategory,
          ),
        ),

        // ── Search Focus Popup（単一選択後） ──
        if (_searchFocus != null) Positioned(
          bottom: 80, left: 16, right: 16,
          child: SearchFocusPopup(
            focus: _searchFocus!,
            center: _center,
            fComps: _fComps,
            activeSrc: _activeSrc,
            activeCategory: _activeCategory,
            // ×タップ: focus 閉じる → リスト復帰 + 地図も一覧表示時へ復元
            onClose: () {
              setState(() => _searchFocus = null);
              _restoreSearchListView();
            },
            // 「ここへ移動」: 中心をその地点に移してリスト・focus 全て破棄
            onMoveToHit: () {
              final f = _searchFocus!;
              _rebuild(LatLng(f.lat, f.lng));
              setState(() {
                _searchFocus = null;
                _searchHits = [];
                _searchListCenter = null;
                _searchListZoom = null;
                _searchOriginCenter = null;
              });
            },
            // VIEWPOINT スロットへ登録 (popup は閉じない: 連続で
            // LOCATION 側にも登録したいケースに対応)。
            onSaveAsViewpoint: () async {
              final f = _searchFocus!;
              final err = await _vpSlotMgr
                  .saveCurrentLocation(LatLng(f.lat, f.lng));
              await _reloadLocationSlots();
              return err;
            },
            // LOCATION スロットへ登録
            onSaveAsLocation: () async {
              final f = _searchFocus!;
              final err = await _locSlotMgr
                  .saveCurrentLocation(LatLng(f.lat, f.lng));
              await _reloadLocationSlots();
              return err;
            },
          ),
        ),

        // ── Searching spinner ──
        if (_searching) Positioned(
          top: topPad + 204, left: 16,
          child: const StatusBadge(label: '検索中…'),
        ),

        // ── Dominant Fortune Overlay ──
        if (_activeOverlay != null) Positioned.fill(
          child: DominantFortuneOverlay(
            key: ValueKey(_activeOverlay),
            kind: _activeOverlay!,
            onComplete: _onOverlayComplete,
          ),
        ),

        // ── F1-c: Daily Transit Full UI ──
        // _onDailyBadgeTap または _onOverlayComplete で _dailyTransitOpen=true。
        // 閉じる → _onDailyTransitClose で右上バッジ位置に縮小フェード。
        // 2026-04-30: 観測点を画面内 VIEWPOINT dropdown で切替可能に変更。
        // 親は出生地と VP slots 一式を渡すだけ。初期は自宅 → 自宅未登録なら出生地。
        // V2: natal を渡してイベント時刻のアスペクト context を併記
        if (_dailyTransitOpen && _profile != null) Positioned.fill(
          child: MapDailyTransitScreen(
            topCategory: _topCategory,
            birthLocation: LatLng(_profile!.birthLat, _profile!.birthLng),
            birthLocationName: _profile!.birthPlace.isNotEmpty
                ? _profile!.birthPlace
                : '出生地',
            vpSlots: _vpSlotsCache,
            natal: _chartResult?.natal,
            onClose: _onDailyTransitClose,
            onEnterAcg: _enterAstroCartoMode,
            onEnterConsultation: _enterConsultationFromDaily,
            // 2026-05-12: 各行の地図マークでイベント時刻 (1 分単位) を
            // Map に飛ばす。MapTimeSlider 側は実分表示 → step 操作で
            // 10 分 grid に合流するように変更済み。
            onJumpToTime: (time) {
              setState(() {
                _selectedDate = time;
                _dailyTransitOpen = false;
              });
              _loadProfileAndChart(targetDate: time);
            },
          ),
        ),

        // ── Loading Indicator (date change) ──
        if (_loadingChart) Positioned(
          top: topPad + 44, right: 16,
          child: const StatusBadge(label: '計算中…'),
        ),

        // ── Rest Overlay ──
        if (_restOverlayVisible) Positioned.fill(
          child: RestOverlay(
            text: _restOverlayText,
            onDismiss: () => setState(() => _restOverlayVisible = false),
          ),
        ),

        // ── プロフィール未設定時の案内カード（Horo/Locations/Forecast と同文面・同スタイル）──
        if (_noProfile) Positioned.fill(
          child: IgnorePointer(
            ignoring: false,
            child: Center(child: _buildNoProfileGuide()),
          ),
        ),

        // ── ACGモード下部 UI (2026-05-11 バーガー左端 + 3 層を下に展開) ──
        // 上から順:
        //   [☰] ─ 左端、常時表示
        //   [1] FramePills        ─┐
        //   [2] SubPills           │ _acgMenuOpen=true のときだけ
        //   [3] CategoryPills     ─┘ NavBar 直上 1px に密着
        // Column 全体を Positioned(bottom: 1) で NavBar 上端から 1px に配置。
        // メニュー閉時はバーガーのみで Column 縮、地図領域最大。
        if (_astroCartoMode) Builder(builder: (context) {
          final active = _resolveActiveAstroFrame();
          return Positioned(
          left: 0, right: 0, bottom: 1,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ☰ バーガー (左端、常時表示)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: MapBtn(
                    active: _acgMenuOpen,
                    onTap: () => setState(() => _acgMenuOpen = !_acgMenuOpen),
                    child: Icon(
                      _acgMenuOpen ? Icons.close : Icons.menu,
                      size: 20,
                      color: _acgMenuOpen
                          ? const Color(0xFFC9A84C)
                          : const Color(0xFFE8E0D0),
                    ),
                  ),
                ),
              ),
              if (_acgMenuOpen) ...[
                // [1] 第1層: フレームピル (Natal/Transit/Prog/S.Arc + 引越し)
                // タップ挙動: すべてトグル ON/OFF。
                //   - フレームピル: ON → 線描画 + active = フレーム、再タップ OFF
                //     OFF にしたフレームが現 active と一致するなら active = null
                //     (= 第2層折り畳み、_resolveActiveAstroFrame() が他 ON 中
                //      フレームへ自動補正)
                //   - 引越しピル: ON/OFF トグル (排他モードの切替)
                Center(
                  child: AstroCartoFramePills(
                    astroLayers: _astroLayers,
                    activeFrame: active,
                    onToggle: (k) => setState(() {
                      final nowOn = !(_astroLayers[k] ?? false);
                      _astroLayers[k] = nowOn;
                      for (final def in acgFrameDefs) {
                        if (def.layerKey == k) {
                          if (nowOn) {
                            _activeAstroFrame = def.frame;
                          } else if (_activeAstroFrame == def.frame) {
                            _activeAstroFrame = null;
                          }
                          break;
                        }
                      }
                    }),
                  ),
                ),
                const SizedBox(height: 1),
                // [2] 第2層: active frame のサブトグル (active なしなら高さ 0)
                Center(
                  child: AstroCartoSubPills(
                    astroLayers: _astroLayers,
                    activeFrame: active,
                    onToggle: (k) => setState(() {
                      _astroLayers[k] = !(_astroLayers[k] ?? false);
                    }),
                  ),
                ),
                if (active != null) const SizedBox(height: 1),
                // [3] FORTUNE カテゴリ (NavBar 直上 1px に密着)
                Center(
                  child: AstroCartoCategoryPills(
                    activeCategory: _activeCategory,
                    onChanged: (k) => setState(() {
                      _activeCategory = k;
                      _planetFilterCategory = k;
                    }),
                  ),
                ),
              ],
            ],
          ),
        );
        }),
        // ACGモード下部スライダーは廃止 (2026-04-29、上部常時表示に統一)

        // ── Phase M2: 引越しレイヤー タップ詳細ポップアップ ──
        // popup は ACG 下部 UI より「後」に描画 → pills の上に重なる (2026-05-07)
        if (_relocateTapPoint != null && _chartResult != null && _profile != null)
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: SafeArea(
              top: false,
              child: _buildRelocationPopup(_relocateTapPoint!),
            ),
          ),

        // ── 天頂点タップ詳細 popup (CCG: 全フレーム対応) ──
        // 線+ハウス popup と排他 (どちらか片方のみ表示)。
        // 2026-04-30: 画面中央付近まで浮上させ、視認性を高める (オーナー要望)。
        if (_zenithTapInfo != null)
          Positioned.fill(
            child: SafeArea(
              child: GestureDetector(
                onTap: () => setState(() => _zenithTapInfo = null),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  color: const Color(0x77000000),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GestureDetector(
                    onTap: () {}, // popup自体のタップは閉じない
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.78,
                      ),
                      child: SingleChildScrollView(
                        child: _buildZenithPopup(_zenithTapInfo!),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

        // ── 登録地マーカータップ詳細 popup (出生地 / VP / Locations 共通) ──
        if (_locationTapInfo != null)
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: SafeArea(
              top: false,
              child: LocationMarkerPopup(
                name: _locationTapInfo!.name,
                point: _locationTapInfo!.point,
                isBirth: _locationTapInfo!.isBirth,
                onClose: () => setState(() => _locationTapInfo = null),
              ),
            ),
          ),
              ]), // Inner Stack 終端 (NavBar 上端までの overlay 領域)
          ), // SafeArea 終端
        ), // Positioned.fill 終端
      ],
    );
  }

  /// 天頂・天底 popup ビルダ。CCG: タップされた frame と座標を直接使う。
  /// [info.isNadir] で天頂版 / 天底版を切替。
  Widget _buildZenithPopup(({String planet, astro_lines.AstroFrame frame, LatLng point, bool isNadir}) info) {
    return AstroZenithPopup(
      planetKey: info.planet,
      zenith: info.point,
      frame: info.frame,
      isNadir: info.isNadir,
      onClose: () => setState(() => _zenithTapInfo = null),
    );
  }

  /// Phase M2 統合タップ popup (論点10 8-β):
  /// aspect ON で線情報、relocate ON で ASC/MC + 12ハウス、両方ONで統合表示。
  /// 比較ベースは home (現住所) 優先、未設定時は出生地。
  Widget _buildRelocationPopup(LatLng tap) {
    final p = _profile!;
    final chart = _chartResult!;
    final hasHome = !(p.homeLat == 0 && p.homeLng == 0);
    final baselineLng = hasHome ? p.homeLng : p.birthLng;
    final baselineLabel = hasHome ? '現住所' : '出生地';

    // CCG: aspect トグルは4フレームの何れか ON で有効
    final aspectOn = _astroLayers['aspect'] == true ||
        _astroLayers['aspectTransit'] == true ||
        _astroLayers['aspectProgressed'] == true ||
        _astroLayers['aspectSolarArc'] == true;

    // aspect ON 時のみ近接線検出 (Tier A #3、画面pixel距離 20px)
    // _findNearbyAstroLines が _visibleAstroLines() 経由で表示中フレームのみ対象にする。
    final List<astro_lines.NearbyAstroLine>? nearby = aspectOn
        ? _findNearbyAstroLines(tap)
        : null;

    // Tier S #2: ライン narrative API 用の natal 文脈を組み立てる
    int signOf(double lon) =>
        ((lon % 360 + 360) % 360 / 30).floor() % 12;
    final natalSummary = <String, int>{
      if (chart.houses.isNotEmpty) 'ascSign': signOf(chart.houses[0]),
      'mcSign': signOf(chart.mc),
      if (chart.natal['sun'] != null) 'sunSign': signOf(chart.natal['sun']!),
      if (chart.natal['moon'] != null)
        'moonSign': signOf(chart.natal['moon']!),
    };

    return MapRelocationPopup(
      tapLat: tap.latitude,
      tapLng: tap.longitude,
      natalPlanets: chart.natal,
      baselineMc: chart.mc,
      baselineLng: baselineLng,
      baselineHouses: chart.houses,
      baselineLabel: baselineLabel,
      // 旧仕様: ライン押した時も「線情報 + ハウス情報」を統合表示する。
      // 引越しトグルは「地点タップで popup を開くかどうか」の制御のみで、
      // popup の中身 (ハウス情報を出すか) とは切り離す。
      showHouses: true,
      nearbyLines: nearby,
      natalSummary: natalSummary,
      userName: p.name.isNotEmpty ? p.name : null,
      onClose: () => setState(() => _relocateTapPoint = null),
      onConsult: () => _launchConsultation(tap),
    );
  }

  /// Phase 2-3c: Daily Transit popup 内 CTA 「AI に相談」のハンドラ。
  /// 目的起点 (入口 2) — preset 無しで `ConsultationInputScreen` を push する。
  /// 1) Daily Transit popup を閉じる
  /// 2) natal-frame conjunction 本線を取り出す
  /// 3) `ConsultationInputScreen` を preset 無しで push (scope はユーザーが選ぶ)
  ///
  /// 設計: pro_candidates.md §7.2 Stage 1 入口 (2) — 目的起点。
  Future<void> _enterConsultationFromDaily() async {
    // Daily Transit popup を閉じる
    setState(() => _dailyTransitOpen = false);

    if (!mounted) return;

    final natalLines = _astroLinesCache
        .where((l) =>
            l.frame == astro_lines.AstroFrame.natal && !l.isAspectLine)
        .toList(growable: false);

    final p = _profile;
    final hasHome = p != null && !(p.homeLat == 0 && p.homeLng == 0);
    final currentLoc = hasHome ? LatLng(p.homeLat, p.homeLng) : null;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConsultationInputScreen(
          astroLines: natalLines,
          currentLocation: currentLoc,
          // preset 無し: ユーザーが scope を選ぶ (世界全体 / 範囲指定 / おでかけ等)
        ),
      ),
    );
  }

  /// Phase 2-3b: relocation popup 内 CTA 「この場所で相談」のハンドラ。
  /// 1) popup を閉じる
  /// 2) reverse_geocode で地名取得 (5s timeout、失敗時は「タップ地点」フォールバック)
  /// 3) ConsultationPresetTarget を作って ConsultationInputScreen を push
  ///
  /// 渡す astroLines は natal-frame の conjunction 本線のみ (v1)。
  /// 設計: pro_candidates.md §7.2 Stage 2 ③ で conjunction 本線 40 を使う仕様。
  Future<void> _launchConsultation(LatLng tap) async {
    // popup を閉じる
    setState(() => _relocateTapPoint = null);

    // reverse_geocode (失敗時は coordinate 文字列)
    String? placeName;
    try {
      placeName = await reverseGeocode(tap.latitude, tap.longitude);
    } catch (_) {
      placeName = null;
    }
    if (!mounted) return;

    final coordLabel =
        '${tap.latitude.toStringAsFixed(2)}°, ${tap.longitude.toStringAsFixed(2)}°';
    final nameJP = placeName ?? 'タップ地点';
    final preset = ConsultationPresetTarget(
      position: tap,
      nameJP: nameJP,
      nameEN: nameJP,
      country: '',
      region: placeName != null ? '' : coordLabel,
    );

    // natal-frame conjunction 本線のみを渡す。
    final natalLines = _astroLinesCache
        .where((l) =>
            l.frame == astro_lines.AstroFrame.natal && !l.isAspectLine)
        .toList(growable: false);

    final p = _profile;
    final hasHome = p != null && !(p.homeLat == 0 && p.homeLng == 0);
    final currentLoc = hasHome ? LatLng(p.homeLat, p.homeLng) : null;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConsultationInputScreen(
          astroLines: natalLines,
          currentLocation: currentLoc,
          presetTarget: preset,
        ),
      ),
    );
  }

  /// 登録地スロット (VP + Locations) を再読込してマーカー描画に反映する。
  /// 呼出タイミング: プロフィール初回ロード後 / VP panel 閉じた後 /
  /// Locations screen から戻った後 / 検索結果から登録した後。
  /// home は両 SlotManager の syncHome で先頭に同期される。
  Future<void> _reloadLocationSlots() async {
    await _vpSlotMgr.syncHome(_profile);
    await _locSlotMgr.syncHome(_profile);
    final vp = await _vpSlotMgr.load();
    final loc = await _locSlotMgr.load();
    if (!mounted) return;
    setState(() {
      _vpSlotsCache = vp;
      _locSlotsCache = loc;
    });
  }

  /// 近接アスペクト線を検出 (Tier A #3)。
  /// 通常Map / Astro*Carto*Graphy モード共通で画面pixel距離 (20px) で判定。
  /// km固定閾値はズームに比例して破綻するため不採用 (zoom 14 で 200km は ~21,000px)。
  /// camera は1度だけキャプチャして project に渡す
  /// (camera ゲッタを毎呼出すとインスタンス再生成のリスクがあるため)。
  /// CCG: 表示中の全フレームを跨いで近接判定する (Natal + Transit + ...)。
  List<astro_lines.NearbyAstroLine> _findNearbyAstroLines(LatLng tap) {
    final visible = _visibleAstroLines();
    if (visible.isEmpty) return const [];
    final cam = _mapCtrl.camera;
    return astro_lines.findNearbyLinesScreen(
      tapPx: cam.latLngToScreenOffset(tap),
      tapLatLng: tap,
      lines: visible,
      project: cam.latLngToScreenOffset,
      thresholdPx: 20,
    );
  }

  /// 2 層メニュー化に伴うフレーム集合ヘルパー (2026-05-11)。
  /// 各サブ機能 (天頂/天底/天頂帯/天底帯) を独立に持つ。
  /// すべて「第1層 (線) が ON」かつ「第2層トグルが ON」を満たすフレームに絞る:
  /// 線 OFF のフレームは第2層メニュー自体が折り畳まれて操作不能。

  Set<astro_lines.AstroFrame> _zenithMarkerFrames() => _filteredFrames('zenith');
  Set<astro_lines.AstroFrame> _nadirMarkerFrames() => _filteredFrames('nadir');
  Set<astro_lines.AstroFrame> _zenithBandFrames() => _filteredFrames('zenithBand');
  Set<astro_lines.AstroFrame> _nadirBandFrames() => _filteredFrames('nadirBand');

  /// フレーム定義テーブルは [acgFrameDefs] (map_astro_carto.dart で定義) を流用。
  /// 第1層 aspectKey / 第2層 frameSuffix / 描画用 frame / 表示ラベル を一元管理。
  Set<astro_lines.AstroFrame> _filteredFrames(String subKey) {
    final s = <astro_lines.AstroFrame>{};
    for (final def in acgFrameDefs) {
      if (_astroLayers[def.layerKey] == true &&
          _astroLayers['${subKey}_${def.frameSuffix}'] == true) {
        s.add(def.frame);
      }
    }
    return s;
  }

  /// 現在 ON の aspect レイヤートグルから可視フレーム集合を導き、_astroLinesCache を絞り込む。
  /// CCG (Tier A #5): natal/transit/progressed/solarArc を独立にトグルできる。
  List<astro_lines.AstroLine> _visibleAstroLines() {
    if (_astroLinesCache.isEmpty) return const [];
    final visibleFrames = <astro_lines.AstroFrame>{};
    if (_astroLayers['aspect'] == true) {
      visibleFrames.add(astro_lines.AstroFrame.natal);
    }
    if (_astroLayers['aspectTransit'] == true) {
      visibleFrames.add(astro_lines.AstroFrame.transit);
    }
    if (_astroLayers['aspectProgressed'] == true) {
      visibleFrames.add(astro_lines.AstroFrame.progressed);
    }
    if (_astroLayers['aspectSolarArc'] == true) {
      visibleFrames.add(astro_lines.AstroFrame.solarArc);
    }
    if (visibleFrames.isEmpty) return const [];
    // B1: アスペクト線 (square/trine/sextile) は専用トグル ON のときのみ。
    // デフォルト OFF → 既存どおりコンジャンクション本線のみ表示・タップ対象。
    final showAspects = _astroLayers['aspectLines'] == true;
    return _astroLinesCache
        .where((l) =>
            visibleFrames.contains(l.frame) &&
            (showAspects || !l.isAspectLine))
        .toList();
  }

  /// プロフィール未設定時の案内カード（他画面と完全同一）。
  /// 「設定する」タップで Sanctuary タブへ遷移。
  Widget _buildNoProfileGuide() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xE60C0C1A), // 地図上に出すので不透明度高めの背景
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
            onTap: () => widget.onNavigateToSanctuary?.call(),
            child: const Text('設定する →',
              style: TextStyle(fontSize: 13, color: Color(0xFFF9D976),
                decoration: TextDecoration.underline)),
          ),
        ]),
      ),
    );
  }

}

/// 検索チップ列の ? から開く: VP (16方位基準) の選び方ガイド。
/// 自宅 / 現在地 / 登録 VP のどれを選ぶかは占星術的に「観測点」の議論で、
/// ユーザー次第であることを伝える。
void _showSearchVpHelpPopup(BuildContext context) {
  showInfoPopup(
    context: context,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'VIEWPOINT (16方位の基準点) の選び方',
          style: TextStyle(
              color: Color(0xFFC9A84C), fontSize: 14, letterSpacing: 1),
        ),
        SizedBox(height: 10),
        Text(
          'チップをタップすると 16 方位スコアの基準点 (VP) が\n'
          'その地点に切替わります。地図の表示は動きません。\n'
          '検索バーで地名を入れずに検索すると、地図中心の\n'
          '周辺から候補が返ります (VP は別軸)。',
          style: TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
        ),
        SizedBox(height: 14),
        Text(
          '【📍 現在地】',
          style: TextStyle(
              color: Color(0xFFC9A84C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
        ),
        SizedBox(height: 4),
        Text(
          '「今この瞬間、どちらに向かうべきか」を見たい時。\n'
          'GPS で現在地を取得し、その場を観測点にします。\n'
          '移動中・旅先での「今ここの方角」用途。',
          style: TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
        ),
        SizedBox(height: 10),
        Text(
          '【🏠 自宅 / 登録 VP】',
          style: TextStyle(
              color: Color(0xFFC9A84C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
        ),
        SizedBox(height: 4),
        Text(
          '自分の拠点 (自宅・学校・職場など) を観測点にする使い方。\n'
          '「自宅や学校、職場から見てこの検索地は\n'
          '何のエネルギーを受けているのか」と読む使い方があります。',
          style: TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
        ),
        SizedBox(height: 14),
        Text(
          'どちらを選ぶかはユーザー次第',
          style: TextStyle(
              color: Color(0xFFC9A84C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
        ),
        SizedBox(height: 4),
        Text(
          '占星術で「観測点をどこに置くか」は、見たいテーマで\n'
          '変わります。日常の指針なら自宅、いま動く瞬間の判断\n'
          'なら現在地、旅先で根を張る場所を考えるならその土地。\n'
          '使い分けで「方角の意味」が立体的に見えてきます。',
          style: TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
        ),
        SizedBox(height: 14),
        Text(
          'VP が画面外に出た時',
          style: TextStyle(
              color: Color(0xFFC9A84C),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
        ),
        SizedBox(height: 4),
        Text(
          '検索地と VP が大きく離れていると、16 方位の扇状が\n'
          '画面外に出てしまい見えません。ズームアウトするか、\n'
          '左上のスコアバー (帯) をタップすると、画面外でも\n'
          '今日の方位状況が確認できます。',
          style: TextStyle(
              color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
        ),
      ],
    ),
  );
}
