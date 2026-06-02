// Consultation API — クレジット系 (V2 と共有)
//
// 設計: project_solara_stella_free_credits.md
//
// 相談の本体 (候補生成 + Stella ナレーション) は V2 (consultation_v2_api.dart) に
// 移行済み。本ファイルには V2 でも使うクレジット系のみ残す:
//   - ConsultationBlock (402 paywall 理由) + consultationBlockFromCode
//   - ConsultationCreditStatus + fetchConsultationCredits

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'app_attest_client.dart';
import 'solara_api.dart'
    show
        solaraConsultationCreditsUrl,
        solaraConsultationWelcomeGrantUrl,
        solaraConsultationMigratePurchasedUrl;

// 旧 ConsultationCreditEvents (notify-only ChangeNotifier) は 2026-05-26 に
// ConsultationCredits (state-holder singleton, lib/utils/consultation_credits.dart) へ
// 置換済み。詳細は consultation_credits.dart 冒頭のコメント参照。

/// Free 試食クレジット切れ等で Worker が 402 を返したときのブロック理由。
enum ConsultationBlock {
  /// 今週の無料 Stella 相談を使い切った (Free。購入残高も 0)。
  creditExhausted,

  /// このモードは無料試食の対象外 (CONSULTATION_FREE_MODES に含まれない)。
  proOnlyMode,

  /// 候補の出し直しは Pro 限定 (Free は 1 回の結果セットのみ)。
  proOnlyRefresh,

  /// Pro の今週の相談上限 (CONSULTATION_PRO_WEEKLY、default 100) に到達 +
  /// 購入残高 0 (2026-05-27 追加。月曜 UTC リセット or 追加クレジット購入を案内)。
  proWeeklyExhausted,

  /// クライアント側 RC SDK は Pro と認識しているが Worker (DO) がまだ非 Pro と判定 (425 Too Early)。
  /// RC Webhook 遅延 / 解約直後 / sandbox renewal 等の同期窓で発生し得る。
  /// 購入クレジットは消費されていない (= 安全停止)。クライアントは数十秒後にリトライ。
  proSyncPending,

  /// 上記以外の 402 (将来追加コード)。フォールバックでペイウォールへ。
  unknown,
}

/// 402 / 425 paywall レスポンスの `error` コード → [ConsultationBlock]。
/// V2 (consultation_v2_api.dart) からも再利用する。
ConsultationBlock consultationBlockFromCode(String? code) {
  switch (code) {
    case 'consultation_credit_exhausted':
      return ConsultationBlock.creditExhausted;
    case 'consultation_pro_only_mode':
      return ConsultationBlock.proOnlyMode;
    case 'consultation_pro_only_refresh':
      return ConsultationBlock.proOnlyRefresh;
    case 'consultation_pro_weekly_exhausted':
      return ConsultationBlock.proWeeklyExhausted;
    case 'pro_sync_pending':
      return ConsultationBlock.proSyncPending;
    default:
      return ConsultationBlock.unknown;
  }
}

/// Stella 相談クレジットの現在状況。
///
/// - Pro: [proRemaining] / [proLimit] / [weekBucket] + [purchasedBalance]
///        (2026-05-27 追加。Pro 週次キャップ CONSULTATION_PRO_WEEKLY=100/週)
/// - 非 Pro: [freeRemaining] / [freeLimit] / [weekBucket] + [purchasedBalance]
///
/// [purchasedBalance] は Pro/非 Pro 共通。Pro が週次キャップを使い切ったときの
/// フォールバック消費先として使われる。
class ConsultationCreditStatus {
  /// Pro 加入中。
  final bool pro;

  /// Free の今週の無料相談残数 (Pro は null)。
  final int? freeRemaining;
  final int? freeLimit;

  /// Pro の今週の相談残数 (非 Pro は null)。
  final int? proRemaining;
  final int? proLimit;

  /// ISO 週バケット "YYYY-Www" (月曜 UTC リセット境界の識別子)。
  final String? weekBucket;

  /// 購入クレジット残高 (Pro/非 Pro 共通)。
  final int? purchasedBalance;

  const ConsultationCreditStatus({
    required this.pro,
    this.freeRemaining,
    this.freeLimit,
    this.proRemaining,
    this.proLimit,
    this.weekBucket,
    this.purchasedBalance,
  });

  /// 何かしら相談できる残数があるか。
  /// Pro は週次残 or 購入残のどちらかが > 0 なら true (= 「無制限」ではなくなった)。
  bool get hasAny {
    if (pro) {
      return (proRemaining ?? 0) > 0 || (purchasedBalance ?? 0) > 0;
    }
    return (freeRemaining ?? 0) > 0 || (purchasedBalance ?? 0) > 0;
  }

  factory ConsultationCreditStatus.fromJson(Map<String, dynamic> j) =>
      ConsultationCreditStatus(
        pro: j['pro'] == true,
        freeRemaining: (j['freeRemaining'] as num?)?.toInt(),
        freeLimit: (j['freeLimit'] as num?)?.toInt(),
        proRemaining: (j['proRemaining'] as num?)?.toInt(),
        proLimit: (j['proLimit'] as num?)?.toInt(),
        weekBucket: j['weekBucket'] as String?,
        purchasedBalance: (j['purchasedBalance'] as num?)?.toInt(),
      );
}

/// `/protected/consultation/credits` を呼んで現在のクレジット状況を取得する。
/// 失敗時 null (UI 側は表示を控える)。
///
/// 🔴 直接呼ばないこと: 必ず `ConsultationCredits.instance.refresh()` を経由する。
/// 直接呼ぶと in-flight dedup が効かず、複数画面が同時に叩いてバーストする
/// (2026-05-26 の 5 分間 45 回バースト問題の再発)。本関数は singleton から
/// しか呼ばれない前提で残してある。
Future<ConsultationCreditStatus?> fetchConsultationCredits({
  Duration timeout = const Duration(seconds: 15),
  http.Client? client,
}) async {
  final c = client ?? http.Client();
  try {
    final merged = AppAttestClient.withAppUserIdMerged(<String, dynamic>{});
    final bodyBytes = utf8.encode(json.encode(merged));
    final headers = <String, String>{'Content-Type': 'application/json'};
    await AppAttestClient.instance.addHeaders(headers, bodyBytes);
    final res = await c
        .post(
          Uri.parse(solaraConsultationCreditsUrl),
          headers: headers,
          body: bodyBytes,
        )
        .timeout(timeout);
    if (res.statusCode == 200) {
      return ConsultationCreditStatus.fromJson(
        json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>,
      );
    }
  } catch (_) {
    // network error → null
  } finally {
    if (client == null) c.close();
  }
  return null;
}

/// ウェルカム特典付与の結果。
/// [granted] = 今回新規に付与した / [alreadyGranted] = この端末は既に付与済。
class WelcomeGrantResult {
  final bool granted;
  final bool alreadyGranted;
  final int amount;
  final int purchasedBalance;

  const WelcomeGrantResult({
    required this.granted,
    required this.alreadyGranted,
    required this.amount,
    required this.purchasedBalance,
  });

  factory WelcomeGrantResult.fromJson(Map<String, dynamic> j) =>
      WelcomeGrantResult(
        granted: j['granted'] == true,
        alreadyGranted: j['alreadyGranted'] == true,
        amount: (j['amount'] as num?)?.toInt() ?? 0,
        purchasedBalance: (j['purchasedBalance'] as num?)?.toInt() ?? 0,
      );
}

/// `/protected/consultation/welcome-grant` を呼び、ウェルカム特典 (恒久クレジット) を
/// 付与する。**呼び出し側で「付与すべき」と判断した時だけ呼ぶこと。**
/// [kind] = 'profile' (出生地+現住所を揃えた、端末単位で 1 回) /
///          'signin' (初回 Google/Apple サインイン、アカウント単位で 1 回)。
/// Worker 側で冪等付与する (二重付与/farming 防止) ので何度呼んでも安全。失敗時 null。
Future<WelcomeGrantResult?> grantWelcomeCredits({
  String kind = 'profile',
  Duration timeout = const Duration(seconds: 15),
  http.Client? client,
}) async {
  final c = client ?? http.Client();
  try {
    final merged =
        AppAttestClient.withAppUserIdMerged(<String, dynamic>{'kind': kind});
    final bodyBytes = utf8.encode(json.encode(merged));
    final headers = <String, String>{'Content-Type': 'application/json'};
    // 冪等な書き込み (端末/アカウント単位で 1 回)。cold/stale warmup で attestation が
    // 8s degrade したら本送信前に warmup を待って付け直す (= missing_attestation_headers
    // を出さず enforced 化のブロッカー/farming 穴を塞ぐ)。詳細 addHeadersWithWarmRetry。
    await AppAttestClient.instance.addHeadersWithWarmRetry(headers, bodyBytes);
    final res = await c
        .post(
          Uri.parse(solaraConsultationWelcomeGrantUrl),
          headers: headers,
          body: bodyBytes,
        )
        .timeout(timeout);
    if (res.statusCode == 200) {
      return WelcomeGrantResult.fromJson(
        json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>,
      );
    }
  } catch (_) {
    // network error → null
  } finally {
    if (client == null) c.close();
  }
  return null;
}

/// `/protected/consultation/migrate-purchased` を呼び、匿名 app_user_id に貯まった
/// 恒久クレジット残高を、サインイン後の認証済 id ([toAppUserId] = 現在の app_user_id) へ
/// 移送する。[fromAppUserId] は logIn 前の匿名 id ($RCAnonymousID:...)。
/// Worker 側で「from が匿名のみ + 冪等」を担保。成功時 true、失敗/対象外でも握り潰す。
Future<bool> migratePurchasedCredits(
  String fromAppUserId, {
  Duration timeout = const Duration(seconds: 15),
  http.Client? client,
}) async {
  final c = client ?? http.Client();
  try {
    final merged = AppAttestClient.withAppUserIdMerged(
        <String, dynamic>{'fromAppUserId': fromAppUserId});
    final bodyBytes = utf8.encode(json.encode(merged));
    final headers = <String, String>{'Content-Type': 'application/json'};
    // 冪等な移送 (from が匿名のみ + Worker 側冪等)。welcome-grant と同様、cold/stale
    // warmup の degrade を本送信前に warmup 待ちで付け直す (addHeadersWithWarmRetry)。
    await AppAttestClient.instance.addHeadersWithWarmRetry(headers, bodyBytes);
    final res = await c
        .post(
          Uri.parse(solaraConsultationMigratePurchasedUrl),
          headers: headers,
          body: bodyBytes,
        )
        .timeout(timeout);
    return res.statusCode == 200;
  } catch (_) {
    return false;
  } finally {
    if (client == null) c.close();
  }
}
