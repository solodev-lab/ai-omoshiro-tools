import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'app_locale.dart';
import 'celestial_events.dart';
import 'moon_phase.dart';
import 'solara_storage.dart';

/// 月イベント (新月・満月・刻星化 + 惑星イベント) のローカル通知を司る singleton。
///
/// 設計方針 (2026-06 最新公式準拠):
/// - flutter_local_notifications v21 内蔵 API のみ使用 (permission_handler は iOS
///   リジェクト要因のため不採用)。
/// - exact alarm は Android 13+ で原則拒否・審査制限のため使わず、
///   [AndroidScheduleMode.inexactAllowWhileIdle] で配信 (朝のリマインダーに秒精度不要)。
/// - 許諾は初回起動では要求しない (Apple 4.5.4)。新月 Set Intention 直後の
///   ソフトアスク ([runSoftAskIfNeeded]) でのみ要求する。
/// - アプリ側マスタスイッチ (SolaraStorage.notificationsEnabled, Sanctuary トグル)
///   と OS 許諾の両方が ON のときだけ schedule する。
class MoonNotificationService {
  MoonNotificationService._();
  static final MoonNotificationService instance = MoonNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // 通知 ID (rescheduleAll で cancelAll するので、固定レンジで衝突回避)
  static const int _idNewMoon = 1001;
  static const int _idFullMoon = 1002;
  static const int _idCatasterism = 1003;
  static const int _planetEventBase = 2000; // +index
  static const int _planetEventMax = 30; // 上限ガード (通知の出し過ぎ防止)

  static const String _channelId = 'moon_cycle';
  static const int _notifyHour = 9; // イベント当日の朝 9:00 ローカル

  /// override > 端末ロケール の順で日本語かどうかを判定。
  bool get _isJP {
    final override = AppLocale.instance.notifier.value?.languageCode;
    if (override == 'ja') return true;
    if (override == 'en') return false;
    return WidgetsBinding.instance.platformDispatcher.locale.languageCode ==
        'ja';
  }

  String get _channelName => _isJP ? '月のサイクル' : 'Moon Cycle';
  String get _channelDesc =>
      _isJP ? '新月・満月・刻星化と天体イベントのお知らせ' : 'New moon, full moon, catasterism & celestial events';

  /// プラグイン + timezone を初期化 (main() で 1 回)。多重呼び出しは no-op。
  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // 端末 TZ 取得失敗時は UTC のまま続行 (通知時刻が多少ずれても落とさない)。
    }
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    // request* を全て false に: init 時に OS 許諾ダイアログを出さない
    // (Apple 4.5.4 / ソフトアスクで明示要求するため)。
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings:
          const InitializationSettings(android: androidInit, iOS: darwinInit),
    );
    // Android 8.0+ 通知チャンネル
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.defaultImportance,
    ));
    _initialized = true;
  }

  /// 現在 OS で通知が許可されているか。
  Future<bool> isAuthorized() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return (await android.areNotificationsEnabled()) ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final opts = await ios.checkPermissions();
      return opts?.isEnabled ?? false;
    }
    return false;
  }

  /// OS 許諾ダイアログを出して結果を返す。既に許可済なら無言で true。
  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return (await android.requestNotificationsPermission()) ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return (await ios.requestPermissions(
              alert: true, badge: true, sound: true)) ??
          false;
    }
    return false;
  }

  NotificationDetails _details() => NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: const DarwinNotificationDetails(),
      );

  /// [localDay] の朝 [_notifyHour] 時の TZDateTime。過去なら null。
  tz.TZDateTime? _morningOf(DateTime localDay) {
    final scheduled = tz.TZDateTime(
        tz.local, localDay.year, localDay.month, localDay.day, _notifyHour);
    if (!scheduled.isAfter(tz.TZDateTime.now(tz.local))) return null;
    return scheduled;
  }

  Future<void> _scheduleAt(
      int id, tz.TZDateTime when, String title, String body) async {
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: when,
      notificationDetails: _details(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// 全予約をキャンセルし、現在の状態から今後の通知を再スケジュールする。
  /// マスタスイッチ OFF / OS 未許可なら cancel のみで終了 (= 何も鳴らない)。
  /// 起動時 / 意図設定後 / 儀式完了後 / トグル ON 時に呼ぶ。
  Future<void> rescheduleAll() async {
    await init();
    await _plugin.cancelAll();
    if (!await SolaraStorage.getNotificationsEnabled()) return;
    if (!await isAuthorized()) return;

    final isJP = _isJP;
    final now = DateTime.now();

    // 1. 次の新月 (新サイクル開始の案内)
    final nmWhen = _morningOf(MoonPhase.findNextNewMoon(now).toLocal());
    if (nmWhen != null) {
      await _scheduleAt(
        _idNewMoon,
        nmWhen,
        isJP ? '🌑 新月' : '🌑 New Moon',
        isJP ? '新しいサイクルの始まり。Galaxy で意図を選べます。'
            : 'A new cycle begins. Set your intention in Galaxy.',
      );
    }

    // 2/3. 当サイクルに意図があれば満月 (中間) / 刻星化 (締めくくり)
    final (cycleStart, cycleEnd) = MoonPhase.getCurrentCycleBounds(now);
    final csLocal = cycleStart.toLocal();
    final cycleId =
        '${csLocal.year}-${csLocal.month.toString().padLeft(2, '0')}';
    final intention = await SolaraStorage.loadIntention(cycleId);
    if (intention != null) {
      if (intention.midpoint == null) {
        final fmWhen =
            _morningOf(MoonPhase.findFullMoonInCycle(now).toLocal());
        if (fmWhen != null) {
          await _scheduleAt(
            _idFullMoon,
            fmWhen,
            isJP ? '🌕 満月' : '🌕 Full Moon',
            isJP ? 'Galaxy で意図の振り返りを。' : 'Reflect on your intention in Galaxy.',
          );
        }
      }
      if (intention.catasterism == null) {
        final crystDay =
            cycleEnd.toLocal().subtract(const Duration(days: 1));
        final cWhen = _morningOf(crystDay);
        if (cWhen != null) {
          await _scheduleAt(
            _idCatasterism,
            cWhen,
            isJP ? '✨ 月の節目' : "✨ Cycle's End",
            isJP ? 'このサイクルの締めくくりを Galaxy で。' : 'Close this cycle in Galaxy.',
          );
        }
      }
    }

    // 4. 惑星イベント (始まる当日の朝)
    try {
      final events =
          await CelestialEvents.fetchCycleEvents(now.year, now.month);
      var i = 0;
      for (final e in events) {
        final d = e.localDate;
        if (d == null) continue;
        final when = _morningOf(d);
        if (when == null) continue;
        await _scheduleAt(
          _planetEventBase + i,
          when,
          isJP ? '🌌 天体の動き' : '🌌 Celestial Event',
          isJP ? e.localDescJP : e.localDesc,
        );
        i++;
        if (i >= _planetEventMax) break;
      }
    } catch (_) {
      // events 取得失敗 (オフライン等) は無視。次回 reschedule で再試行。
    }
  }

  /// マスタスイッチを OFF にして全予約を取り消す。明示 OFF はソフトアスクも抑制。
  Future<void> disable() async {
    await init();
    await _plugin.cancelAll();
    await SolaraStorage.setNotificationsEnabled(false);
    await SolaraStorage.setNotifSoftAskDeclines(2); // 明示 OFF → 以後ソフトアスクしない
  }

  /// Sanctuary トグル ON 時のフロー: OS 許諾を確保 → マスタ ON → schedule。
  /// 許諾が取れなければ false を返す (呼び側は「設定で許可してください」案内)。
  Future<bool> enableFromToggle() async {
    await init();
    var granted = await isAuthorized();
    if (!granted) granted = await requestPermission();
    if (!granted) return false;
    await SolaraStorage.setNotificationsEnabled(true);
    await SolaraStorage.setNotifSoftAskDeclines(0);
    await rescheduleAll();
    return true;
  }

  /// 新月 Set Intention 直後に呼ぶソフトアスク。
  /// ① 既に有効 / ② 計2回断られた・明示OFF / ③ 同一サイクルで既出 なら出さない。
  /// 「受け取る」→ OS 許諾 → 許可されれば有効化。スケジュールは呼び側が行う。
  static Future<void> runSoftAskIfNeeded(
    BuildContext context, {
    required String cycleId,
  }) async {
    final svc = instance;
    await svc.init();
    if (await SolaraStorage.getNotificationsEnabled()) return;
    if (await SolaraStorage.getNotifSoftAskDeclines() >= 2) return;
    if (await SolaraStorage.getNotifSoftAskCycle() == cycleId) return;
    if (!context.mounted) return;

    await SolaraStorage.setNotifSoftAskCycle(cycleId);
    if (!context.mounted) return;
    final isJP = svc._isJP;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A0E1A),
        title: Text(
          isJP ? '🌙 月のお知らせ' : '🌙 Moon reminders',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        content: Text(
          isJP
              ? '満月の振り返りや新月の始まり、星の節目を、そっとお知らせしましょうか？\n（あとから設定でいつでも変更できます）'
              : 'Shall we gently remind you of full moons, new moons, and celestial events?\n(You can change this anytime in settings.)',
          style: const TextStyle(color: Color(0xFFCCCCCC), height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(isJP ? '今はしない' : 'Not now',
                style: const TextStyle(color: Color(0x99FFFFFF))),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(isJP ? '受け取る' : 'Enable',
                style: const TextStyle(color: Color(0xFFF9D976))),
          ),
        ],
      ),
    );

    if (accepted == true) {
      final granted = await svc.requestPermission();
      if (granted) {
        await SolaraStorage.setNotificationsEnabled(true);
        await SolaraStorage.setNotifSoftAskDeclines(0);
      }
    } else {
      await SolaraStorage.incrementNotifSoftAskDeclines();
    }
  }
}
