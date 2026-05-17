// Solara 端末セキュリティ状態 (RASP) — Phase 2 launch_checklist
//
// 設計:
//   - launch_checklist Phase 2「RASP」3 項目
//   - project_solara_security_principles 5 原則の補強
//   - freerasp ^7.5.1 (talsec) を使用
//
// 役割:
//   - 起動時に freerasp を init し、root/jailbreak/hook/debugger/emulator 等を
//     継続監視するリスナーを attach する
//   - 重大な脅威 (`_severeThreats`) を検知したら `isCompromised = true` で
//     ChangeNotifier listener に通知する
//   - 軽微な脅威 (devMode/screenshot 等) は記録のみで Pro 無効化はしない
//
// 🔴 Apple/Google ストア審査対応:
//   - **無料機能はそのまま使える**ように設計する (Free を block すると審査でリジェクト)
//   - Pro 機能のみ disable する (showProUnlockDialog 経由で「セキュリティ確認に
//     失敗」表示、Pro 購入導線も出さない = 課金後 block で User trust 失う事を避ける)
//
// 🔴 設定値 (--dart-define、CI/local の双方で):
//   --dart-define=SOLARA_FREERASP_ANDROID_HASH=<base64-sha256>  (release keystore cert hash)
//   --dart-define=SOLARA_FREERASP_IOS_TEAM_ID=<TEAM>            (Apple Developer Team ID)
//   --dart-define=SOLARA_FREERASP_WATCHER_MAIL=<email>          (任意、talsec backend reports)
//   いずれか未設定で current platform を満たせない場合は **start をスキップ** (no-op)。
//
// 🔴 検証手順:
//   - debug build: kDebugMode で start() を skip するため発火しない (テスト noise 回避)
//   - 実 release build (R8 + obfuscate + 署名済) を root 化端末/Frida/emulator で
//     起動 → 各 threat callback が発火することを実機確認 (TestFlight 配信前必須)

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:freerasp/freerasp.dart';

class DeviceSecurityStatus extends ChangeNotifier {
  DeviceSecurityStatus._();

  /// アプリ全体で 1 つのインスタンスを共有する。
  static final DeviceSecurityStatus instance = DeviceSecurityStatus._();

  /// 重大脅威 = Pro 機能を即時 disable するもの。
  /// 通常のユーザー環境では発火しない種類のみを選別 (例: devMode は開発者なら
  /// 日常的に ON なので除外、screenshot は OS 機能で除外、unsecureWiFi は
  /// カフェ 等で発火し誤検知になるため除外)。
  ///
  /// hooks         = Frida 等のフック (改変の決定的証拠)
  /// appIntegrity  = APK/IPA 改変 (resign or 再パッケージ)
  /// unofficialStore = サイドロード (Play/App Store 以外からインストール)
  /// privilegedAccess = root/jailbreak
  /// deviceBinding = 別端末でのクローン疑い
  /// simulator     = iOS Simulator (prod で発火するなら攻撃者の解析環境)
  /// automation    = UI Automator / XCUITest 等の自動化フレームワーク
  /// multiInstance = 並列インスタンス (Parallel Space 等の改変容易環境)
  static const Set<Threat> _severeThreats = {
    Threat.hooks,
    Threat.appIntegrity,
    Threat.unofficialStore,
    Threat.privilegedAccess,
    Threat.deviceBinding,
    Threat.simulator,
    Threat.automation,
    Threat.multiInstance,
  };

  /// --dart-define 由来の設定値。
  static const String _androidHash =
      String.fromEnvironment('SOLARA_FREERASP_ANDROID_HASH', defaultValue: '');
  static const String _iosTeamId =
      String.fromEnvironment('SOLARA_FREERASP_IOS_TEAM_ID', defaultValue: '');
  static const String _watcherMail = String.fromEnvironment(
    'SOLARA_FREERASP_WATCHER_MAIL',
    defaultValue: 'kojifo369@gmail.com',
  );

  /// Solara の package/bundle ID (build.gradle.kts namespace と同じ)。
  static const String _packageId = 'com.solodevlab.solara';

  bool _isCompromised = false;
  bool _started = false;
  final Set<Threat> _detectedThreats = <Threat>{};

  /// 重大脅威を 1 件以上検知したか。Pro ゲートで参照する。
  bool get isCompromised => _isCompromised;

  /// `start()` 完了済か。未起動 = 「測れていない」状態。
  bool get started => _started;

  /// 検出された全脅威 (軽微含む)。デバッグ表示用。読み取り専用。
  Set<Threat> get detectedThreats => Set<Threat>.unmodifiable(_detectedThreats);

  /// 現プラットフォームで freerasp init に必要な設定が揃っているか。
  static bool get hasConfigForCurrentPlatform {
    if (kIsWeb) return false;
    if (Platform.isAndroid) return _androidHash.isNotEmpty;
    if (Platform.isIOS) return _iosTeamId.isNotEmpty;
    return false; // Windows/macOS/Linux desktop は対象外
  }

  /// 起動時に 1 度だけ呼ぶ。
  ///
  /// - debug build (kDebugMode) では skip (debug threat で常時発火するため)
  /// - Web / desktop platform では skip (freerasp 非対応)
  /// - 設定値 (--dart-define) 不足でも skip = no-op
  /// - 上記いずれでもなければ Talsec.start + attachListener
  Future<void> start() async {
    if (_started) return;
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      if (kDebugMode) {
        debugPrint('[DeviceSecurity] 非対応プラットフォーム → skip');
      }
      return;
    }
    if (kDebugMode) {
      // debug build では `Threat.debug` で常時発火 + signing cert が release と
      // 異なるため appIntegrity も発火する。テスト時のノイズを避けるため skip。
      debugPrint('[DeviceSecurity] kDebugMode → start を skip');
      return;
    }
    if (!hasConfigForCurrentPlatform) {
      debugPrint('[DeviceSecurity] --dart-define 不足 → skip (no-op、Pro は通常動作)');
      return;
    }

    try {
      await Talsec.instance.start(_buildConfig());
      await Talsec.instance.attachListener(_buildCallback());
      _started = true;
      if (kDebugMode) {
        debugPrint('[DeviceSecurity] freerasp start OK');
      }
    } catch (e) {
      // Talsec の init 失敗は致命的でない (Pro は通常動作で Free 機能維持)。
      debugPrint('[DeviceSecurity] start failed (継続): $e');
    }
  }

  TalsecConfig _buildConfig() {
    return TalsecConfig(
      watcherMail: _watcherMail,
      isProd: !kDebugMode,
      // killOnBypass=false: SDK バイパス時はアプリを kill せず callback だけ
      // 出す。kill すると Free ユーザーまで強制終了になりストア審査で問題。
      killOnBypass: false,
      androidConfig: Platform.isAndroid
          ? AndroidConfig(
              packageName: _packageId,
              signingCertHashes: [_androidHash],
              // Solara は Google Play 専売 (+ Galaxy Store はオーナー判断)。
              // 一旦 Play Store のみを公式とし、それ以外は unofficialStore で検知。
              supportedStores: const ['com.android.vending'],
            )
          : null,
      iosConfig: Platform.isIOS
          ? IOSConfig(
              bundleIds: const [_packageId],
              teamId: _iosTeamId,
            )
          : null,
    );
  }

  ThreatCallback _buildCallback() {
    return ThreatCallback(
      onHooks: () => _onThreat(Threat.hooks),
      onDebug: () => _onThreat(Threat.debug),
      onPasscode: () => _onThreat(Threat.passcode),
      onDeviceID: () => _onThreat(Threat.deviceId),
      onSimulator: () => _onThreat(Threat.simulator),
      onAppIntegrity: () => _onThreat(Threat.appIntegrity),
      onObfuscationIssues: () => _onThreat(Threat.obfuscationIssues),
      onDeviceBinding: () => _onThreat(Threat.deviceBinding),
      onUnofficialStore: () => _onThreat(Threat.unofficialStore),
      onPrivilegedAccess: () => _onThreat(Threat.privilegedAccess),
      onSecureHardwareNotAvailable: () =>
          _onThreat(Threat.secureHardwareNotAvailable),
      onSystemVPN: () => _onThreat(Threat.systemVPN),
      onDevMode: () => _onThreat(Threat.devMode),
      onADBEnabled: () => _onThreat(Threat.adbEnabled),
      onScreenshot: () => _onThreat(Threat.screenshot),
      onScreenRecording: () => _onThreat(Threat.screenRecording),
      onMultiInstance: () => _onThreat(Threat.multiInstance),
      onUnsecureWiFi: () => _onThreat(Threat.unsecureWiFi),
      onTimeSpoofing: () => _onThreat(Threat.timeSpoofing),
      onLocationSpoofing: () => _onThreat(Threat.locationSpoofing),
      onAutomation: () => _onThreat(Threat.automation),
    );
  }

  void _onThreat(Threat t) {
    _detectedThreats.add(t);
    final wasCompromised = _isCompromised;
    if (_severeThreats.contains(t)) {
      _isCompromised = true;
    }
    // 重大脅威で状態遷移した時だけ listener 通知 (notifyListeners の連発を避ける)。
    if (wasCompromised != _isCompromised) {
      notifyListeners();
    }
    if (kDebugMode) {
      debugPrint(
        '[DeviceSecurity] threat=$t severe=${_severeThreats.contains(t)} '
        'isCompromised=$_isCompromised',
      );
    }
  }

  /// テスト/開発用: 検知状態を直接書き換える。通常コードからは start() のみ使う。
  @visibleForTesting
  void resetForTest({
    bool isCompromised = false,
    Set<Threat>? detected,
  }) {
    final old = _isCompromised;
    _detectedThreats
      ..clear()
      ..addAll(detected ?? <Threat>{});
    _isCompromised = isCompromised;
    _started = false;
    if (old != _isCompromised) notifyListeners();
  }

  /// テスト/開発用: 重大脅威 1 件を発火させる (発火経路を模擬)。
  @visibleForTesting
  void debugTriggerCompromised(Threat t) {
    _onThreat(t);
  }
}
