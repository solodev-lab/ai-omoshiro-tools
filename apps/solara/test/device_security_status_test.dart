// DeviceSecurityStatus + 連動 (ProStatus / showProUnlockDialog) のテスト。
//
// Phase 2 RASP launch_checklist 配線の最小検証。
//   - 重大脅威 (privilegedAccess 等) で isCompromised が true、軽微脅威
//     (devMode 等) では false
//   - ProStatus.isPro が isCompromised を反映 (effective false)
//   - showProUnlockDialog が isCompromised で content を切替
//
// 注: Talsec.start() 実呼出はテストでは行わない (native channel が無いため)。
//     resetForTest / debugTriggerCompromised で状態だけ操作する。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freerasp/freerasp.dart' show Threat;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:solara/utils/device_security_status.dart';
import 'package:solara/utils/pro_status.dart';
import 'package:solara/widgets/pro_unlock_dialog.dart';

void main() {
  // テスト間で singleton state が漏れないよう毎回 reset。
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    DeviceSecurityStatus.instance.resetForTest(isCompromised: false);
    await ProStatus.instance.resetForTest(isPro: false);
  });

  group('DeviceSecurityStatus', () {
    test('default は isCompromised=false / started=false', () {
      expect(DeviceSecurityStatus.instance.isCompromised, isFalse);
      expect(DeviceSecurityStatus.instance.started, isFalse);
      expect(DeviceSecurityStatus.instance.detectedThreats, isEmpty);
    });

    test('重大脅威 (privilegedAccess) で isCompromised=true', () {
      int notifyCount = 0;
      void listener() => notifyCount++;
      DeviceSecurityStatus.instance.addListener(listener);

      DeviceSecurityStatus.instance.debugTriggerCompromised(Threat.privilegedAccess);

      expect(DeviceSecurityStatus.instance.isCompromised, isTrue);
      expect(
        DeviceSecurityStatus.instance.detectedThreats,
        contains(Threat.privilegedAccess),
      );
      expect(notifyCount, 1, reason: 'compromised 遷移時に通知');

      DeviceSecurityStatus.instance.removeListener(listener);
    });

    test('軽微脅威 (devMode) は isCompromised=false のまま', () {
      DeviceSecurityStatus.instance.debugTriggerCompromised(Threat.devMode);
      expect(DeviceSecurityStatus.instance.isCompromised, isFalse);
      // ただし検知歴には残る
      expect(
        DeviceSecurityStatus.instance.detectedThreats,
        contains(Threat.devMode),
      );
    });

    test('複数の重大脅威が来ても notifyListeners は最初の 1 回だけ発火', () {
      int notifyCount = 0;
      void listener() => notifyCount++;
      DeviceSecurityStatus.instance.addListener(listener);

      DeviceSecurityStatus.instance.debugTriggerCompromised(Threat.hooks);
      DeviceSecurityStatus.instance.debugTriggerCompromised(Threat.appIntegrity);
      DeviceSecurityStatus.instance.debugTriggerCompromised(Threat.simulator);

      expect(DeviceSecurityStatus.instance.isCompromised, isTrue);
      expect(notifyCount, 1, reason: '初回遷移のみ通知 (連発回避)');

      DeviceSecurityStatus.instance.removeListener(listener);
    });

    test('重大 8 脅威全部が isCompromised を発火させる', () {
      const severeThreats = [
        Threat.hooks,
        Threat.appIntegrity,
        Threat.unofficialStore,
        Threat.privilegedAccess,
        Threat.deviceBinding,
        Threat.simulator,
        Threat.automation,
        Threat.multiInstance,
      ];
      for (final t in severeThreats) {
        DeviceSecurityStatus.instance.resetForTest(isCompromised: false);
        DeviceSecurityStatus.instance.debugTriggerCompromised(t);
        expect(
          DeviceSecurityStatus.instance.isCompromised,
          isTrue,
          reason: '$t は severe であるべき',
        );
      }
    });

    test('軽微脅威全部は isCompromised を発火させない', () {
      const minorThreats = [
        Threat.debug,
        Threat.passcode,
        Threat.deviceId,
        Threat.obfuscationIssues,
        Threat.secureHardwareNotAvailable,
        Threat.systemVPN,
        Threat.devMode,
        Threat.adbEnabled,
        Threat.screenshot,
        Threat.screenRecording,
        Threat.unsecureWiFi,
        Threat.timeSpoofing,
        Threat.locationSpoofing,
      ];
      for (final t in minorThreats) {
        DeviceSecurityStatus.instance.resetForTest(isCompromised: false);
        DeviceSecurityStatus.instance.debugTriggerCompromised(t);
        expect(
          DeviceSecurityStatus.instance.isCompromised,
          isFalse,
          reason: '$t は minor であるべき (Pro 機能を blocking しない)',
        );
      }
    });
  });

  group('ProStatus × DeviceSecurityStatus', () {
    test('compromised=false の時は raw=effective', () async {
      await ProStatus.instance.resetForTest(isPro: true);
      expect(ProStatus.instance.isPro, isTrue);
      expect(ProStatus.instance.isProRaw, isTrue);
    });

    test('compromised=true で effective isPro が false (raw は true のまま)', () async {
      await ProStatus.instance.resetForTest(isPro: true);
      DeviceSecurityStatus.instance.debugTriggerCompromised(Threat.hooks);
      expect(ProStatus.instance.isPro, isFalse,
          reason: 'effective state は compromised で false に倒れる');
      expect(ProStatus.instance.isProRaw, isTrue,
          reason: 'raw 状態は購入履歴を保持 (Paywall 表示用)');
    });

    test('DeviceSecurityStatus 変化で ProStatus listener が発火', () async {
      await ProStatus.instance.resetForTest(isPro: true);
      int notifyCount = 0;
      void listener() => notifyCount++;
      ProStatus.instance.addListener(listener);

      DeviceSecurityStatus.instance.debugTriggerCompromised(Threat.hooks);
      expect(notifyCount, 1,
          reason: 'DeviceSecurityStatus → ProStatus への connection が効いている');

      ProStatus.instance.removeListener(listener);
    });
  });

  group('showProUnlockDialog × compromised', () {
    testWidgets('compromised=false の時は通常の Pro upsell content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => TextButton(
                onPressed: () => showProUnlockDialog(
                  ctx,
                  featureLabel: 'テスト機能',
                  description: 'テスト説明',
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('✦ Cosmic Pro'), findsOneWidget);
      expect(find.text('Pro にアップグレード'), findsOneWidget,
          reason: '通常時は課金導線が出る');
      expect(find.textContaining('セキュリティ確認'), findsNothing);
    });

    testWidgets('compromised=true の時はセキュリティ通知 content', (tester) async {
      DeviceSecurityStatus.instance.debugTriggerCompromised(Threat.privilegedAccess);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => TextButton(
                onPressed: () => showProUnlockDialog(
                  ctx,
                  featureLabel: 'テスト機能',
                  description: 'テスト説明',
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('✦ デバイスのセキュリティ確認'), findsOneWidget);
      expect(find.text('Pro にアップグレード'), findsNothing,
          reason: '改変端末では課金導線を出さない (購入後トラブル回避)');
      expect(find.textContaining('改変や解析ツール'), findsOneWidget);
      expect(find.textContaining('無料機能はそのまま'), findsOneWidget,
          reason: 'ストア審査対応: Free 機能の継続利用を明示');
    });
  });
}
