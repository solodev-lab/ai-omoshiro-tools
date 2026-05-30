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
import 'utils/app_attest_client.dart';
import 'utils/app_locale.dart';
import 'utils/celestial_events.dart';
import 'utils/consultation_credits.dart';
import 'utils/device_security_status.dart';
import 'utils/map_focus.dart';
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
  final _galaxyKey = GlobalKey<GalaxyScreenState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    MapFocus.instance.addListener(_onMapFocusRequested);
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
  }

  late final _screens = <Widget>[
    MapScreen(key: _mapKey, onNavigateToSanctuary: () => _onTabTap(4)),
    HoroscopeScreen(key: _horoKey, onNavigateToSanctuary: () => _onTabTap(4)),
    const ObserveScreen(),
    GalaxyScreen(key: _galaxyKey, onOverlayChanged: _onGalaxyOverlayChanged),
    const SanctuaryScreen(),
  ];

  void _onTabTap(int i) {
    // タブ切替前後の状態を捕捉 (setState で _currentIndex が変わる前)
    final switchingToGalaxy = i == 3 && _currentIndex != 3;
    final leavingGalaxy = i != 3 && _currentIndex == 3;
    final leavingHoro = i != 1 && _currentIndex == 1;
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
    if (switchingToGalaxy) _galaxyKey.currentState?.regenerateBackground();
    // タブ離脱時は Timer.periodic も明示停止 (TickerMode の対象外なので)
    if (leavingGalaxy) _galaxyKey.currentState?.pauseMotion();
    if (leavingHoro) _horoKey.currentState?.pauseAnimations();
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
        ),
      ),
    );
  }
}
