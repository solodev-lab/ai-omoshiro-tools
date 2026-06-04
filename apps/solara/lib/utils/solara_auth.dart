// Solara 認証サービス — Phase 2-9 Sign in 統合
//
// 設計:
//   - launch_checklist Phase 2「Sign in 統合」
//   - project_solara_security_principles 原則 3「App User ID は Sign in with Apple/Google の uid」
//   - Apple Guideline 5.4: Google 提供時は Apple 必須 (iOS のみ)
//
// 役割:
//   - Sign in with Apple / Google を抽象化し、現在のアカウント情報を提供
//   - 成功時に PurchasesService.logIn(uid) を呼び、RevenueCat の appUserID を切替え
//   - サインアウト時に PurchasesService.logOut を呼ぶ
//   - ChangeNotifier で UI に反映
//
// 設計判断:
//   - Sign in は **任意**。Free ユーザーは未サインインのまま全機能使える
//   - Pro 購入も anonymous appUserID で可能 (StoreKit/Play Billing が紐付け、復元は OS が担保)
//   - サインインで端末跨ぎ復元が安定する旨を UI で案内し、推奨に留める
//   - Android では Apple Sign in は不可 (service ID + redirect URI が必要、本フェーズでは非対応)。
//     Apple 公式パッケージは Android 対応だが、サーバー側 service 設定が必要なため初期は iOS のみ
//
// 🔴 API キー注入 (--dart-define):
//   --dart-define=SOLARA_GOOGLE_IOS_CLIENT_ID=xxxxx.apps.googleusercontent.com
//   --dart-define=SOLARA_GOOGLE_SERVER_CLIENT_ID=xxxxx.apps.googleusercontent.com
//   未設定でも GoogleSignIn.initialize() は呼ばれるが、ネイティブ設定 (GoogleService-Info.plist /
//   google-services.json) があれば動く。クライアント ID を渡すと優先される

import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../i18n/strings.g.dart';

import 'app_attest_client.dart';
import 'consultation_api.dart' show grantWelcomeCredits, migratePurchasedCredits;
import 'consultation_credits.dart';
import 'purchases_service.dart';
import 'solara_api.dart';

enum SolaraAuthProvider { apple, google }

/// 認証済アカウント情報。
class SolaraAuthAccount {
  final SolaraAuthProvider provider;

  /// RevenueCat appUserID として使う一意 ID。
  /// 形式: "apple:{userIdentifier}" / "google:{user.id}"
  /// プロバイダ間で衝突せず、同じプロバイダ間では端末を跨いで同じ値になる。
  final String uid;

  /// 表示名 (Apple の場合、初回のみ取得。以降は SharedPreferences から復元)。
  final String? displayName;

  /// メール (Apple の場合、初回のみ。Apple のリレーアドレスもありうる)。
  final String? email;

  const SolaraAuthAccount({
    required this.provider,
    required this.uid,
    this.displayName,
    this.email,
  });

  Map<String, dynamic> toJson() => {
        'provider': provider.name,
        'uid': uid,
        'displayName': displayName,
        'email': email,
      };

  static SolaraAuthAccount? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final providerStr = json['provider'] as String?;
    final uid = json['uid'] as String?;
    if (providerStr == null || uid == null) return null;
    final provider = SolaraAuthProvider.values.firstWhere(
      (p) => p.name == providerStr,
      orElse: () => SolaraAuthProvider.google,
    );
    return SolaraAuthAccount(
      provider: provider,
      uid: uid,
      displayName: json['displayName'] as String?,
      email: json['email'] as String?,
    );
  }

  String get displayLabel => displayName?.isNotEmpty == true
      ? displayName!
      : email?.isNotEmpty == true
          ? email!
          : provider == SolaraAuthProvider.apple
              ? t.solaraAuth.appleAccount
              : t.solaraAuth.googleAccount;
}

/// 認証エラー (UI が型で分岐できるよう薄い wrapper)。
class SolaraAuthException implements Exception {
  final String message;
  final Object? cause;
  SolaraAuthException(this.message, [this.cause]);
  @override
  String toString() => 'SolaraAuthException: $message';
}

class SolaraAuth extends ChangeNotifier {
  SolaraAuth._();

  static final SolaraAuth instance = SolaraAuth._();

  static const String _kPrefsKey = 'solara_auth_account';

  static const String _googleIosClientId =
      String.fromEnvironment('SOLARA_GOOGLE_IOS_CLIENT_ID', defaultValue: '');
  static const String _googleServerClientId =
      String.fromEnvironment('SOLARA_GOOGLE_SERVER_CLIENT_ID',
          defaultValue: '');

  SolaraAuthAccount? _account;
  bool _googleInitialized = false;
  bool _loaded = false;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _googleEventsSub;

  SolaraAuthAccount? get account => _account;
  bool get isSignedIn => _account != null;
  bool get loaded => _loaded;

  /// 初回サインイン特典 (signin grant) が **今回新規付与された** ときの付与額。
  /// お祝いスナックバー用の one-shot シグナル。null = 表示すべきものなし。
  /// UI 層 (main.dart) が listen し、表示後に [consumeSigninGrantCelebration] でクリアする。
  /// alreadyGranted (再サインイン等で既に付与済) のときは立てない (=お祝いしない)。
  int? _pendingSigninGrantAmount;
  int? get pendingSigninGrantAmount => _pendingSigninGrantAmount;
  void consumeSigninGrantCelebration() => _pendingSigninGrantAmount = null;

  /// 起動時に 1 度呼ぶ。SharedPreferences から復元 + provider 別の silent restore。
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPrefsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          _account = SolaraAuthAccount.fromJson(decoded);
        }
      } catch (_) {
        // 破損 JSON は捨てる
      }
    }

    // 起動時の検証 (provider 別)。失敗時は local state をクリア。
    if (_account != null) {
      await _verifyOrClear();
    }

    notifyListeners();
  }

  Future<void> _verifyOrClear() async {
    final acc = _account;
    if (acc == null) return;
    try {
      if (acc.provider == SolaraAuthProvider.apple) {
        if (!_isApplePlatform) return; // Apple 端末でなければスキップ
        final userIdentifier = _stripPrefix(acc.uid, 'apple:');
        if (userIdentifier == null) {
          await _clearLocalSession();
          return;
        }
        final state = await SignInWithApple.getCredentialState(userIdentifier);
        if (state != CredentialState.authorized) {
          await _clearLocalSession();
        }
      } else {
        // Google: silent restore を試みる
        await _ensureGoogleInitialized();
        final user =
            await GoogleSignIn.instance.attemptLightweightAuthentication();
        if (user == null) {
          await _clearLocalSession();
        } else {
          // user.id が一致するか確認 (端末で別アカウントになってる可能性)
          if (user.id != _stripPrefix(acc.uid, 'google:')) {
            // アカウント切替が発生 → 新しいアカウントを採用
            await _adoptGoogleAccount(user);
          }
        }
      }
    } catch (_) {
      // 検証失敗は安全側で local だけクリア (UI で「再サインインしてください」案内)
      await _clearLocalSession();
    }
  }

  /// Apple サインイン (iOS / macOS 推奨)。
  Future<SolaraAuthAccount> signInWithApple() async {
    if (!_isApplePlatform) {
      throw SolaraAuthException(t.solaraAuth.appleOnlyPlatform);
    }
    final available = await SignInWithApple.isAvailable();
    if (!available) {
      throw SolaraAuthException(t.solaraAuth.appleUnavailable);
    }

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final userIdentifier = credential.userIdentifier;
    if (userIdentifier == null) {
      throw SolaraAuthException(t.solaraAuth.appleNoUserId);
    }

    // 表示名 / email は初回のみ来る → 既存と merge
    final existingDisplayName = _account?.displayName;
    final existingEmail = _account?.email;
    final givenName = credential.givenName;
    final familyName = credential.familyName;
    final fullName = (givenName != null || familyName != null)
        ? [givenName, familyName].whereType<String>().join(' ').trim()
        : null;

    final account = SolaraAuthAccount(
      provider: SolaraAuthProvider.apple,
      uid: 'apple:$userIdentifier',
      displayName: (fullName?.isNotEmpty == true)
          ? fullName
          : existingDisplayName,
      email: credential.email ?? existingEmail,
    );

    await _commitAccount(account);
    return account;
  }

  /// Google サインイン (iOS / Android / macOS / Web)。
  Future<SolaraAuthAccount> signInWithGoogle() async {
    await _ensureGoogleInitialized();
    try {
      final user = await GoogleSignIn.instance.authenticate();
      final account = SolaraAuthAccount(
        provider: SolaraAuthProvider.google,
        uid: 'google:${user.id}',
        displayName: user.displayName,
        email: user.email,
      );
      await _commitAccount(account);
      return account;
    } on GoogleSignInException catch (e) {
      // canceled / unknownError 等は SDK 仕様のまま投げ直し
      throw SolaraAuthException(t.solaraAuth.googleSignInFailed, e);
    }
  }

  /// 現在のアカウントを取り外す。
  Future<void> signOut() async {
    final provider = _account?.provider;
    try {
      if (provider == SolaraAuthProvider.google && _googleInitialized) {
        await GoogleSignIn.instance.signOut();
      }
      // Apple は dedicated sign out API がない (Apple ID 設定で revoke するしかない)。
      // ローカル状態だけクリアして再サインインの導線を出す。
    } catch (_) {
      // SDK 例外は無視してローカルクリアは続行 (UX: 出口は常に開けておく)
    }
    await _clearLocalSession();
  }

  /// アカウント削除 (App Store ガイドライン 5.1.1(v) — Sign in を提供する以上、
  /// アプリ内に削除手段が必須)。
  ///
  /// 手順:
  ///   1. サーバー側 (Worker DO) の Pro 記録 + Webhook ログを物理削除 (best-effort)。
  ///      まだ RevenueCat にログイン中の uid (apple:/google:) で assertion 署名する
  ///      ため、必ず logOut より前に実行する。
  ///   2. プロバイダ側トークン失効:
  ///        - Google: disconnect() で付与スコープを revoke (signOut より強い)。
  ///        - Apple : クライアント側の失効 API は無いためローカルクリアのみ。
  ///          (option 3 / 将来: サーバーで Apple REST revoke を足す場合は、削除時に
  ///           getAppleIDCredential を再取得して fresh authorizationCode をサーバーへ
  ///           渡し revoke する。authorizationCode は約 5 分で失効・単回限りのため
  ///           「サインイン時に保存」では使えない点に注意。)
  ///   3. RevenueCat logOut + ローカルセッションクリア。
  ///
  /// 注意: 購読そのものの解約はしない (Apple/Google が管理)。UI 側で「有料プランは
  /// 別途ストアで解約」を案内する。ローカル記録庫 (相談履歴 / 称号 / Galaxy) は
  /// 端末内の個人コンテンツであり、クラウド識別子 (アカウント) とは独立に保持する。
  Future<void> deleteAccount() async {
    final provider = _account?.provider;

    // 0. Apple Sign In ユーザー: fresh authorizationCode を取得 (REST revoke 用)。
    //    authorizationCode は ~5 分 / 単回限りのため「サインイン時に保存」では使えない。
    //    削除フローの中で再度 getAppleIDCredential を呼んで取り直す必要がある。
    //    取得失敗 (キャンセル / 端末不可) なら null を Worker に渡す = サーバー側で no-op。
    //    DO 削除と RC 削除は別途進むので、Apple revoke 失敗でも個人識別子は消える。
    String? appleAuthorizationCode;
    if (provider == SolaraAuthProvider.apple) {
      appleAuthorizationCode = await _getFreshAppleAuthorizationCode();
    }

    // 1. サーバー側データ削除 (logOut 前 = appUserId が apple:/google: のうちに)
    await _purgeServerAccountData(
      appleAuthorizationCode: appleAuthorizationCode,
    );

    // 2. プロバイダ側 revoke (失敗してもローカル削除は続行)
    try {
      if (provider == SolaraAuthProvider.google) {
        await _ensureGoogleInitialized();
        await GoogleSignIn.instance.disconnect();
      }
      // Apple は上記 Step 0 + Step 1 (Worker → Apple /auth/revoke) で revoke 済。
    } catch (_) {
      // 出口は常に開ける
    }

    // 3. RC logOut + ローカルクリア
    await _clearLocalSession();
  }

  /// アカウント削除フロー中に fresh な Apple authorizationCode を取得する。
  /// 失敗 (端末不可 / ユーザーキャンセル / Apple Sign In 利用不可) は null。
  /// 呼出側は null でも削除フローを続行 (Worker 側で no-op、DO/RC 削除は進む)。
  Future<String?> _getFreshAppleAuthorizationCode() async {
    if (!_isApplePlatform) return null;
    try {
      if (!await SignInWithApple.isAvailable()) return null;
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [AppleIDAuthorizationScopes.email],
      );
      final code = credential.authorizationCode;
      return code.isNotEmpty ? code : null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SolaraAuth] Apple authorizationCode fetch failed: $e');
      }
      return null;
    }
  }

  /// Worker `/protected/account/delete` を叩いて DO の Pro 記録を物理削除する。
  /// 失敗 (オフライン / 未 attest / Worker エラー) してもアカウント削除自体は
  /// 続行する (best-effort)。`postProtected` が body に `__appUserId` を自動注入。
  ///
  /// [appleAuthorizationCode]: Apple Sign In ユーザーで fresh authorizationCode が
  /// 取得できた場合に渡す。Worker 側で Apple /auth/revoke (Token Revocation) に使われる。
  /// null/未渡しなら Worker は Apple revoke を skip し、他の削除工程は通常通り進む。
  Future<void> _purgeServerAccountData({
    String? appleAuthorizationCode,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (appleAuthorizationCode != null && appleAuthorizationCode.isNotEmpty) {
        payload['appleAuthorizationCode'] = appleAuthorizationCode;
      }
      final res = await AppAttestClient.instance.postProtected(
        solaraAccountDeleteUrl,
        payload: payload,
      );
      if (res.statusCode != 200 && kDebugMode) {
        debugPrint(
            '[SolaraAuth] server purge non-200: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[SolaraAuth] server purge failed: $e');
    }
  }

  // ── 内部処理 ────────────────────────────────────────────

  bool get _isApplePlatform {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isMacOS;
  }

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize(
      clientId: _googleIosClientId.isNotEmpty ? _googleIosClientId : null,
      serverClientId:
          _googleServerClientId.isNotEmpty ? _googleServerClientId : null,
    );
    _googleInitialized = true;

    // アカウント切替・暗黙的サインアウトをストリーム購読 (二重サブスクは弾く)
    _googleEventsSub ??=
        GoogleSignIn.instance.authenticationEvents.listen(_onGoogleEvent);
  }

  void _onGoogleEvent(GoogleSignInAuthenticationEvent event) {
    switch (event) {
      case GoogleSignInAuthenticationEventSignIn(:final user):
        if (_account == null ||
            _account?.uid != 'google:${user.id}') {
          // 別アカウントになった場合は採用
          unawaited(_adoptGoogleAccount(user));
        }
      case GoogleSignInAuthenticationEventSignOut():
        // SDK 側で signOut された (revoke 等) → ローカル同期
        if (_account?.provider == SolaraAuthProvider.google) {
          unawaited(_clearLocalSession());
        }
    }
  }

  Future<void> _adoptGoogleAccount(GoogleSignInAccount user) async {
    final account = SolaraAuthAccount(
      provider: SolaraAuthProvider.google,
      uid: 'google:${user.id}',
      displayName: user.displayName,
      email: user.email,
    );
    await _commitAccount(account);
  }

  Future<void> _commitAccount(SolaraAuthAccount account) async {
    _account = account;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefsKey, jsonEncode(account.toJson()));
    // サインイン前 (匿名) の app_user_id を控える (移送の from に使う)。
    final oldAppUserId = PurchasesService.instance.appUserId;
    // RevenueCat に uid を渡す。configured されていなければ no-op。
    try {
      await PurchasesService.instance.logIn(account.uid);
    } catch (_) {
      // 失敗してもサインイン自体は成立とみなす (Pro 復元は次回起動で再試行)
    }
    // 匿名残高の移送 + 初回サインイン特典 (恒久クレジット)。UI はブロックしない。
    unawaited(
        _onSignedInCredits(oldAppUserId, PurchasesService.instance.appUserId));
    notifyListeners();
  }

  /// サインイン完了時のクレジット処理 (best-effort、失敗は握り潰す)。
  ///   1. 匿名→認証で id が変わったら、匿名 id の恒久クレジット残高を認証 id へ移送
  ///      (匿名に取り残されるのを防ぐ。Worker 側は匿名 from のみ許可 = 窃取防止)。
  ///   2. 初回 Google/Apple サインイン特典をアカウント単位で 1 回付与 (冪等)。
  ///   3. 残高表示を更新。
  Future<void> _onSignedInCredits(String? oldId, String? newId) async {
    try {
      if (oldId != null &&
          newId != null &&
          oldId != newId &&
          oldId.startsWith(r'$RCAnonymousID:')) {
        await migratePurchasedCredits(oldId);
      }
      final res = await grantWelcomeCredits(kind: 'signin');
      await ConsultationCredits.instance.refresh();
      // 今回新規に付与できたときだけ、お祝い通知を UI へ伝える。
      // alreadyGranted (再サインイン) や失敗 (null) では祝わない。
      if (res != null && res.granted && res.amount > 0) {
        _pendingSigninGrantAmount = res.amount;
        notifyListeners();
      }
    } catch (_) {
      // best-effort
    }
  }

  Future<void> _clearLocalSession() async {
    _account = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPrefsKey);
    try {
      await PurchasesService.instance.logOut();
    } catch (_) {
      // 同上
    }
    notifyListeners();
  }

  String? _stripPrefix(String uid, String prefix) {
    if (!uid.startsWith(prefix)) return null;
    return uid.substring(prefix.length);
  }

  /// テスト用: SharedPreferences とキャッシュ両方をリセット。
  @visibleForTesting
  Future<void> resetForTest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPrefsKey);
    _account = null;
    _loaded = true;
    _googleInitialized = false;
    await _googleEventsSub?.cancel();
    _googleEventsSub = null;
    notifyListeners();
  }
}
