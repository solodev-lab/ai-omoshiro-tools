import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme/solara_theme.dart';
import 'screens/ai_consent_screen.dart';
import 'screens/map_screen.dart';
import 'screens/horoscope_screen.dart';
import 'screens/observe_screen.dart';
import 'screens/galaxy_screen.dart';
import 'screens/sanctuary_screen.dart';
import 'screens/consultation/consultation_input_screen.dart';
import 'screens/consultation/consultation_result_screen.dart';
import 'screens/consultation/consultation_history_screen.dart';
import 'screens/sanctuary/title_history_screen.dart';
import 'screens/sanctuary/class_share_card.dart';
import 'utils/app_attest_client.dart';
import 'utils/app_locale.dart';
import 'utils/celestial_events.dart';
import 'utils/consult_restore.dart';
import 'utils/consultation_credits.dart';
import 'utils/consultation_record.dart';
import 'utils/consultation_return.dart';
import 'utils/device_security_status.dart';
import 'utils/map_focus.dart';
import 'utils/moon_event_status.dart';
import 'utils/moon_notification_service.dart';
import 'utils/pro_status.dart';
import 'utils/purchases_service.dart';
import 'utils/solara_auth.dart';
import 'utils/solara_storage.dart';
import 'utils/tarot_data.dart';
import 'widgets/solara_nav_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // Make system nav bar transparent for edge-to-edge
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    statusBarColor: Colors.transparent,
  ));
  await TarotData.initialize();
  await CelestialEvents.initialize();
  await AppLocale.instance.load();
  // 月イベント通知: プラグイン + timezone を初期化し、現状態から再スケジュール。
  // マスタ OFF / OS 未許可なら cancel のみ (= 何も鳴らない)。CelestialEvents +
  // AppLocale 初期化後に呼ぶ (惑星イベント取得とロケール判定に必要)。
  // reschedule は内部 network (events) を伴うので await しない (起動を待たせない)。
  await MoonNotificationService.instance.init();
  // ignore: unawaited_futures
  MoonNotificationService.instance.rescheduleAll();
  await ProStatus.instance.load();
  // Phase 2 RASP: freerasp で root/Frida/エミュレータ等を検知 → 検知時は
  // ProStatus.isPro が effective false を返すので Pro ゲートが自動的に発火。
  // debug/Web/desktop/設定値不足ではいずれも no-op (Free 動作は不変)。
  // ProStatus が DeviceSecurityStatus を listen するため、ProStatus.load() の
  // 後に start を呼んでも順序問題なし (listener は遅延でも発火する)。
  // ignore: unawaited_futures
  DeviceSecurityStatus.instance.start();
  // Phase 2-6b: RevenueCat 配線。API キー未設定 / 未対応 OS では no-op。
  // 設定済なら entitlement listener が ProStatus を上書きするので load() の後に呼ぶ順序。
  await PurchasesService.instance.init();
  // Phase 2-9: Sign in 統合。SharedPreferences から復元 + provider 別 silent restore。
  // PurchasesService.init より後でないと、復元時の logIn が configure 前に走ってしまう。
  await SolaraAuth.instance.load();
  // Phase 1 App Attest (設計 v2.0): keyId 復元 or 初回 attest。失敗してもアプリ
  // 起動は止めない (= bypass モードで通過、Worker 側 log_only モードで動く)。
  // 実機 release のみ有効、Simulator/debug/Android/Web は bypass。
  // ignore: unawaited_futures
  AppAttestClient.instance.initialize();
  // Stella/Tarot クレジット残: 起動時に 1 回だけ非同期で fetch (await しない =
  // UI 表示を待たせない)。各画面は ConsultationCredits.instance.status を
  // 直接読むので、起動直後は null (= 「確認中」表示) で、~300ms 後に
  // notifyListeners で更新される。詳細: utils/consultation_credits.dart
  // ignore: unawaited_futures
  ConsultationCredits.instance.refresh();
  // Pro 状態変化 (Free ↔ Pro / DeviceSecurity 侵害復帰等) で残数の財布構造が
  // 変わる (Free 週次 ↔ Pro 週次)。クライアント側 RC SDK が即時 Pro 認識した直後に
  // Sanctuary の残数表示を 0/0 から正しい値へ自己治癒させるため、ProStatus の
  // 変化で必ず ConsultationCredits.refresh() を kick する (in-flight dedup あり)。
  // Worker 側は __clientEntitlement + RC REST 再検証で DO 同期遅延を吸収する。
  ProStatus.instance.addListener(() {
    // ignore: discarded_futures
    ConsultationCredits.instance.refresh();
  });
  // AI 生成同意の事前判定 (Apple 5.1.2(i) / Google Generative AI Apps Policy)。
  // 出生情報・相談内容を Google Gemini API に送信する旨を、初回起動時に明示同意。
  // 未同意なら AiConsentScreen を最初に出し、同意済なら通常の SolaraHome を出す。
  // 詳細: apps/solara/docs/store_compliance.md §2.1 / §5.2
  final hasConsent = await SolaraStorage.hasAiConsent();
  runApp(SolaraApp(initialConsented: hasConsent));
}

class SolaraApp extends StatefulWidget {
  /// 起動時点で同意済みなら true (= SolaraHome を最初から表示)。
  /// false の場合は AiConsentScreen を出し、同意後に setState で home を入れ替える。
  /// test 用にデフォルト false (= 未同意 = ConsentScreen 表示)。
  final bool initialConsented;
  const SolaraApp({super.key, this.initialConsented = false});

  @override
  State<SolaraApp> createState() => _SolaraAppState();
}

class _SolaraAppState extends State<SolaraApp> {
  late bool _consented = widget.initialConsented;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale?>(
      valueListenable: AppLocale.instance.notifier,
      builder: (_, locale, _) => MaterialApp(
        title: 'Solara',
        // Flutter 標準の状態復元基盤 (Android プロセス死対策のハイブリッド土台)。
        // これにより Navigator スタックや RestorableProperty 対応 widget が復元可能に
        // なる。検索結果詳細など非シリアライズ状態は SolaraHome 側の disk
        // スナップショット (SolaraStorage.saveRestoreSnapshot) で別途復元する。
        restorationScopeId: 'solara_root',
        debugShowCheckedModeBanner: false,
        theme: SolaraTheme.dark,
        locale: locale, // null の時は端末設定が使われる
        supportedLocales: const [Locale('ja'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        // 端末のフォントサイズ設定によるテキスト拡大を最大 1.5 倍にクランプ。
        // 2026-05-08: Solara はタイトな詩的レイアウト (スコアバー / 16方位 /
        // 天頂マーカー等) が多く、端末側 200% 設定でレイアウト崩壊する事象を
        // 防ぎつつ、アクセシビリティもある程度確保するための妥協点。
        // 無効化 (TextScaler.noScaling) は Apple HIG 違反 + ストア審査リスクの
        // ため避け、業界標準の「1.2〜1.5 クランプ」のうち上限値を採用。
        // (スコアバー / 日付バーは Column 化済みなので 1.5 まで耐えられる)
        builder: (context, child) => MediaQuery.withClampedTextScaling(
          minScaleFactor: 1.0,
          maxScaleFactor: 1.5,
          child: child!,
        ),
        // AI 同意未取得時は SolaraHome の代わりに AiConsentScreen を出す。
        // 同意完了 → setState で _consented=true → SolaraHome に差し替わる。
        // 起動スプラッシュ (背景画像 + Solara ロゴ) は廃止し、通常起動 (起動後
        // すぐ Map) に戻した (2026-06-01 オーナー判断)。
        home: _consented
            ? const SolaraHome()
            : AiConsentScreen(
                onConsented: () => setState(() => _consented = true),
              ),
      ),
    );
  }
}

class SolaraHome extends StatefulWidget {
  const SolaraHome({super.key});

  @override
  State<SolaraHome> createState() => _SolaraHomeState();
}

class _SolaraHomeState extends State<SolaraHome> with WidgetsBindingObserver {
  int _currentIndex = 0;
  final _mapKey = GlobalKey<MapScreenState>();
  final _horoKey = GlobalKey<HoroscopeScreenState>();
  final _observeKey = GlobalKey<ObserveScreenState>();
  final _galaxyKey = GlobalKey<GalaxyScreenState>();

  /// 画面復元スナップショットの有効期限。これより古いものは無視する。
  /// warm resume 時に破棄しているので、残存 = プロセス死を意味する。広めに取るが
  /// 「翌日開いたら古い検索が出る」を避けるため上限を設ける。
  static const _restoreMaxAge = Duration(hours: 6);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    MapFocus.instance.addListener(_onMapFocusRequested);
    // ignore: unawaited_futures
    _restoreLastScreen();
    // C: 起動時の月イベント判定 (NavBar バッジ + Map 案内)。MapScreen の state は
    // build 後に生成されるため postFrame で呼ぶ (initState 時点では currentState=null)。
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshMoonStatus());
  }

  /// コールド起動時、直近 paused で保存したスナップショットがあれば画面を復元する。
  /// 低 RAM 端末 (A101FC 等) で外部アプリ往復中に OS が Solara を kill → 復帰時
  /// コールド再起動で初期画面に戻る問題への対策。
  Future<void> _restoreLastScreen() async {
    final snap = await SolaraStorage.loadRestoreSnapshot();
    await SolaraStorage.clearRestoreSnapshot(); // 1 回限り消費
    if (snap == null || !mounted) return;
    final savedAt = DateTime.tryParse(snap['savedAt'] as String? ?? '');
    if (savedAt == null ||
        DateTime.now().difference(savedAt) > _restoreMaxAge) {
      return; // 古すぎるスナップショットは無視
    }
    // タブ復元 (全タブ共通の軽量復元)。
    final tab = (snap['tab'] as num?)?.toInt();
    if (tab != null &&
        tab >= 0 &&
        tab < _screens.length &&
        tab != _currentIndex) {
      setState(() => _currentIndex = tab);
    }
    // Map 画面の復元 (検索 + 各ポップアップ)。中身の消化タイミングは MapScreen 側
    // (検索=onMapReady 後 / ポップアップ=chart 読込後) に委ねる。
    final mapData = snap['map'];
    if (mapData is Map) {
      final data = Map<String, dynamic>.from(mapData);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _mapKey.currentState?.restoreMapState(data);
      });
    }
    // Tarot (Observe) 画面の HISTORY タブ復元。
    final observeData = snap['observe'];
    if (observeData is Map) {
      final data = Map<String, dynamic>.from(observeData);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _observeKey.currentState?.restoreState(data);
      });
    }
    // Galaxy 画面の共有画面 (通常再生終了 / 形成演出終了) 復元。
    final galaxyData = snap['galaxy'];
    if (galaxyData is Map) {
      final data = Map<String, dynamic>.from(galaxyData);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _galaxyKey.currentState?.restoreGalaxyState(data);
      });
    }
    // 押下ルート (相談入力 / 相談結果画面) の復元。タブ/Map の後に root Navigator へ push。
    final route = snap['route'];
    if (route is Map) {
      final data = Map<String, dynamic>.from(route);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // ignore: unawaited_futures
        _restorePushedRoute(data);
      });
    }
  }

  /// 復元スナップショットの押下ルートを root Navigator に再 push する。
  /// 相談結果は必ず履歴レコードから (fromRecord・読み込み専用) 開く。API 再実行＝
  /// クレジット二重消費は絶対にしない。レコードが見つからなければ何もしない。
  Future<void> _restorePushedRoute(Map<String, dynamic> route) async {
    final type = route['type'];
    if (type == 'consultationResult') {
      final id = route['recordId'] as String?;
      if (id == null) return;
      final list = await SolaraStorage.loadConsultationHistory();
      ConsultationRecord? rec;
      for (final r in list) {
        if (r.id == id) {
          rec = r;
          break;
        }
      }
      if (rec == null || !mounted) return;
      final found = rec;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ConsultationResultScreen.fromRecord(record: found),
      ));
    } else if (type == 'consultationInput') {
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ConsultationInputScreen(restoreForm: route),
      ));
    } else if (type == 'consultationHistory') {
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) =>
            ConsultationHistoryScreen(initialFavOnly: route['favOnly'] == true),
      ));
    } else if (type == 'titleHistory') {
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => const TitleHistoryScreen(),
      ));
    } else if (type == 'classShare') {
      if (!mounted) return;
      final axis = route['axis'] as String?;
      final court = route['court'] as String?;
      if (axis == null || court == null) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ClassShareCardPage(
          axis: axis,
          court: court,
          titleLightJP: route['light'] as String? ?? '',
          titleShadowJP: route['shadow'] as String? ?? '',
          titleEN: route['en'] as String? ?? '',
          initialShowShadow: route['showShadow'] == true,
        ),
      ));
    }
  }

  /// バックグラウンド遷移時に現在の画面状態を保存する (プロセス死に備える)。
  Future<void> _saveRestoreSnapshot() async {
    final snap = <String, dynamic>{
      'savedAt': DateTime.now().toIso8601String(),
      'tab': _currentIndex,
    };
    // Map 画面のスナップショット (検索 + Daily/Fortune/Locations/Forecast ポップアップ)。
    // 中身の構造は MapScreen が所有し、SolaraHome は透過で運ぶだけ。
    final map = _mapKey.currentState?.captureMapRestore();
    if (map != null) {
      snap['map'] = map;
    }
    // Tarot (Observe) 画面の HISTORY タブ状態。
    final observe = _observeKey.currentState?.captureRestore();
    if (observe != null) {
      snap['observe'] = observe;
    }
    // Galaxy 画面の共有画面 (通常再生終了 / 形成演出終了) 状態。
    final galaxy = _galaxyKey.currentState?.captureRestore();
    if (galaxy != null) {
      snap['galaxy'] = galaxy;
    }
    // 押下ルート (相談入力 / 相談結果画面) の最前面スナップショット。
    final route = ConsultRestore.instance.captureTop();
    if (route != null) {
      snap['route'] = route;
    }
    await SolaraStorage.saveRestoreSnapshot(snap);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    MapFocus.instance.removeListener(_onMapFocusRequested);
    super.dispose();
  }

  /// 相談結果カードの🗺ボタン要求を受け、Map タブへ切替えて候補位置＋日付でフォーカス。
  /// (結果画面は popUntil で閉じた後に request されるので、ここで前面はルートに戻っている)
  void _onMapFocusRequested() {
    if (!mounted) return;
    final req = MapFocus.instance.take();
    if (req == null) return;
    _onTabTap(0); // Map タブ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapKey.currentState?.focusLocationAndDate(req.pos, req.date);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // バックグラウンド復帰時にクレジット残を再取得 (別端末購入や Webhook 遅延
    // 吸収用)。各画面で個別に observer を持たせず、SolaraHome 1 箇所に集約。
    // 詳細: utils/consultation_credits.dart
    if (state == AppLifecycleState.resumed) {
      // ignore: unawaited_futures
      ConsultationCredits.instance.refresh();
      // warm 復帰 = メモリ状態が無傷なので復元スナップショットは不要。
      // 残すと次のコールド起動で誤って古い画面を復元しうるため破棄する。
      // ignore: unawaited_futures
      SolaraStorage.clearRestoreSnapshot();
      // B: warm 復帰でも月イベント判定を再評価。initState は warm resume で再実行
      // されないため、満月当日にアプリを開き直しても overlay が出ない穴を塞ぐ。
      // ignore: unawaited_futures
      _galaxyKey.currentState?.recheckMoonEvents();
      // C: バッジ/Map 案内も resume で再評価 (日付跨ぎ・別端末での完了を反映)。
      // ignore: unawaited_futures
      _refreshMoonStatus();
    } else if (state == AppLifecycleState.paused) {
      // バックグラウンド遷移 (外部アプリ起動含む): プロセス死に備え状態保存。
      // paused はまだ生存中に発火するので書き込みは間に合う。
      // ignore: unawaited_futures
      _saveRestoreSnapshot();
    }
  }

  /// Galaxy 画面が overlay (replay / formation / moon 系) を表示中かどうか。
  /// 🔴 (2026-05-19) Flutter PopScope は階層を持たず、本 PopScope の
  /// onPopInvokedWithResult が Galaxy 内 PopScope と **同時に** 呼ばれる。
  /// Galaxy が overlay を出している間は Map タブへの戻しを抑止して、
  /// 内側 PopScope の overlay 閉じる処理だけを動かす。
  bool _galaxyHasOverlay = false;

  void _onGalaxyOverlayChanged(bool active) {
    if (!mounted) return;
    if (_galaxyHasOverlay != active) {
      setState(() => _galaxyHasOverlay = active);
    }
    // overlay 開閉で wasLocalOverlayShownToday が変わりうる (完了/ディスミス時に
    // markLocalOverlayShown される) → 月イベント保留状態を再計算してバッジ/案内を更新。
    // ignore: unawaited_futures
    _refreshMoonStatus();
    if (!active) {
      // 儀式完了/ディスミスで intention の midpoint/catasterism が変わりうる →
      // 済んだイベントの通知予約を取り消すため再スケジュール (A)。
      // ignore: unawaited_futures
      MoonNotificationService.instance.rescheduleAll();
    }
  }

  // ── C: 月イベント (新月/満月/刻星化) の NavBar バッジ + Map 案内 ──
  /// 保留中の月イベント種別。null = 保留なし。NavBar バッジは `!= null` で点灯し、
  /// Map 案内は MapScreen に種別を渡して表示する。発火条件は overlay と同一
  /// (MoonEventStatus.pendingToday に一本化)。
  MoonEventKind? _pendingMoonKind;

  /// 月イベント保留状態を再計算し、NavBar バッジ (_pendingMoonKind) と Map 案内
  /// (MapScreen.showMoonNotice) を更新する。起動 / resume / タブ切替 /
  /// Galaxy overlay 開閉 のたびに呼ぶ。許諾不要・新パッケージ不要のアプリ内導線。
  Future<void> _refreshMoonStatus() async {
    final kind = await MoonEventStatus.pendingToday(DateTime.now());
    if (!mounted) return;
    if (kind != _pendingMoonKind) {
      setState(() => _pendingMoonKind = kind);
    }
    // Map 案内は MapScreen 側 state に命令で渡す (既存の GlobalKey 流儀)。
    _mapKey.currentState?.showMoonNotice(kind);
  }

  late final _screens = <Widget>[
    MapScreen(key: _mapKey, onNavigateToSanctuary: () => _onTabTap(4)),
    HoroscopeScreen(key: _horoKey, onNavigateToSanctuary: () => _onTabTap(4)),
    ObserveScreen(key: _observeKey),
    GalaxyScreen(key: _galaxyKey, onOverlayChanged: _onGalaxyOverlayChanged),
    const SanctuaryScreen(),
  ];

  void _onTabTap(int i) {
    // タブ切替前後の状態を捕捉 (setState で _currentIndex が変わる前)
    final switchingToGalaxy = i == 3 && _currentIndex != 3;
    final leavingGalaxy = i != 3 && _currentIndex == 3;
    final leavingHoro = i != 1 && _currentIndex == 1;
    // Map 以外のタブへ移ったら「相談結果に戻る」導線を破棄 (Map タブ専用の一過性
    // 導線。🗺 ジャンプは _onMapFocusRequested → _onTabTap(0) なので消えない)。
    if (i != 0) ConsultationReturn.instance.clear();
    setState(() => _currentIndex = i);
    // Map / Horo へ戻ったときはプロフィールを再読込（Sanctuary で編集された場合に追従）
    if (i == 0) _mapKey.currentState?.reloadProfile();
    if (i == 1) {
      _horoKey.currentState?.loadProfile();
      // Horo 入室で anim 起動 (30s 寿命タイマー fresh start)
      // 注: initState ではなく、ここで起動する。IndexedStack で initState は app 起動時に
      // 走るため、そこで wake すると裏タブで CPU 浪費 + 寿命タイマーが消化されてしまう。
      _horoKey.currentState?.wakeAnimations();
    }
    // Galaxy 入室で背景再生成 + motion fresh 40s lifecycle
    if (switchingToGalaxy) {
      _galaxyKey.currentState?.regenerateBackground();
      // B: 入室時にも月イベント (新月/満月/刻星化) 判定を再評価。warm 状態で別タブから
      // 満月当日などに Galaxy へ入っても overlay が出ない穴を塞ぐ。
      // ignore: unawaited_futures
      _galaxyKey.currentState?.recheckMoonEvents();
    }
    // タブ離脱時は Timer.periodic も明示停止 (TickerMode の対象外なので)
    if (leavingGalaxy) _galaxyKey.currentState?.pauseMotion();
    if (leavingHoro) _horoKey.currentState?.pauseAnimations();
    // C: タブ切替のたびに月イベント保留状態を再評価 (バッジ/Map 案内を最新化)。
    // ストレージ読み込み数回の軽量処理 — ユーザー操作起点なのでホットループではない。
    // ignore: unawaited_futures
    _refreshMoonStatus();
  }

  @override
  Widget build(BuildContext context) {
    // Android system back button:
    //   - Map 以外のタブ → Map に戻す
    //   - Map タブ → アプリを閉じる (= 通常の root pop = SystemNavigator.pop)
    // タブ内 overlay (Daily Transit 等) は map_screen.dart の PopScope で
    // 先に消化される (AND 評価で本 PopScope より下位)。
    //
    // 🔴 (2026-05-19) Galaxy overlay 表示中 (_galaxyHasOverlay=true) は
    // Map タブへの戻し処理を抑止する。Flutter PopScope は階層を持たず、
    // 内側 (Galaxy 内 overlay PopScope) と外側 (本 PopScope) の
    // onPopInvokedWithResult が同時に呼ばれる仕様のため、ここで明示的に
    // 「Galaxy が overlay 処理中なら触らない」と宣言する必要がある。
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_galaxyHasOverlay) return; // Galaxy 内 PopScope に任せる
        if (_currentIndex != 0) {
          _onTabTap(0);
        }
      },
      child: Scaffold(
        extendBody: true,
        // 🔴 (2026-05-19) 全タブで resizeToAvoidBottomInset=false に統一。
        // オーナー要望: 「TextField 選択でキーボードが出るとき背景もずれる」 を
        // 解消する。 キーボードは body の上に被さるだけで、 背景 (Tarot 占卓 /
        // Galaxy 星空 / Horoscope シャート等) はそのまま固定。
        // 旧設計 (Map のみ false): 検索バー位置が固定で、 キーボードで FlutterMap
        // が縮むと地理中心が視覚的にシフトする問題から導入。 今回その挙動を全タブに
        // 統一する。 各 TextField は SingleChildScrollView or
        // bottomSheet 内に配置されているので、 隠れる場合は自然にスクロールできる。
        resizeToAvoidBottomInset: false,
        body: IndexedStack(
          index: _currentIndex,
          // 2026-05-03: TickerMode で裏画面の AnimationController.repeat() を停止。
          // Galaxy 星空回転 / Horoscope 円 / Tarot Altar 等の常時 tick が
          // SurfaceFlinger の release タイミングを乱して Map 画面の点滅を引き起こしていた。
          children: [
            for (int i = 0; i < _screens.length; i++)
              TickerMode(enabled: i == _currentIndex, child: _screens[i]),
          ],
        ),
        bottomNavigationBar: SolaraNavBar(
          currentIndex: _currentIndex,
          onTap: _onTabTap,
          showGalaxyBadge: _pendingMoonKind != null,
        ),
      ),
    );
  }
}
