// Stella 相談 追加クレジット購入シート (消費型 IAP、設計 B 案)
//
// 設計: project_solara_stella_free_credits.md
//   - 無料週次クレジットを使い切った非 Pro ユーザーが、追加クレジットを購入する導線
//   - 価格は「Pro へ寄せた割高設定」(数回買うなら Pro の方が得 → 転換装置)
//   - 「Cosmic Pro なら無制限」CTA を併置して Pro へ誘導
//   - 購入はサインイン必須 (残高はアカウント appUserId に紐づく、機種変で失わない)
//   - 付与はサーバー側 (RC Webhook → DO 残高加算)。購入後に状況を再取得して反映
//
// 🔴 RevenueCat に creditsOfferingId ('credits') Offering + 消費型 Package を
//    作成しておく必要がある。未配信時は「準備中」表示。

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../theme/solara_colors.dart';
import '../../utils/consultation_api.dart' show ConsultationCreditStatus;
import '../../utils/consultation_credits.dart';
import '../../utils/purchases_service.dart';
import '../../utils/solara_auth.dart';
import '../paywall_screen.dart';

/// クレジット購入シートを開く。
/// 戻り値: 購入で残高が変わった可能性があれば true (呼出側はクレジット状況を再取得)。
Future<bool> showConsultationCreditSheet(BuildContext context) async {
  final changed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: SolaraColors.celestialBlueDark,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _CreditSheet(),
  );
  return changed ?? false;
}

class _CreditSheet extends StatefulWidget {
  const _CreditSheet();

  @override
  State<_CreditSheet> createState() => _CreditSheetState();
}

class _CreditSheetState extends State<_CreditSheet> {
  Offering? _offering;
  bool _loading = true;
  bool _busy = false;
  String? _message;

  /// シート内のクレジット残表示は ConsultationCredits.instance.status から読む。
  /// 自分から fetch はしない (起動時 / 消費時 / 購入完了ポーリング時に singleton 側が
  /// 更新するため、シート open のためだけの fetch は不要)。
  ConsultationCreditStatus? get _status => ConsultationCredits.instance.status;

  @override
  void initState() {
    super.initState();
    _load();
    // 購入完了ポーリングで残数が変わった時にシート内の残数表示も更新する。
    ConsultationCredits.instance.addListener(_onCreditsChanged);
  }

  @override
  void dispose() {
    ConsultationCredits.instance.removeListener(_onCreditsChanged);
    super.dispose();
  }

  void _onCreditsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    // offering だけ取得 (RC SDK 経由、ネット不要・キャッシュあり)。
    // クレジット残は singleton 経由 (起動時に refresh 済 = 高確率で hit)。
    final offering = await PurchasesService.instance.getCreditOffering();
    if (!mounted) return;
    setState(() {
      _offering = offering;
      _loading = false;
    });
  }

  /// 購入前のサインイン強制 (paywall と同方針)。残高をアカウントに紐づけるため必須。
  Future<bool> _ensureSignedIn() async {
    if (SolaraAuth.instance.isSignedIn) return true;
    final isApple = !kIsWeb && (Platform.isIOS || Platform.isMacOS);
    final providerLabel = isApple ? 'Apple' : 'Google';
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SolaraColors.celestialBlueDark,
        title: const Text('サインインが必要です',
            style: TextStyle(color: SolaraColors.textPrimary, fontSize: 16)),
        content: Text(
          'クレジットのご購入には $providerLabel サインインが必要です。\n\n'
          'サインインすると、機種変更や再インストール後も残高が引き継がれます。'
          '無料の機能はサインインなしでお使いいただけます。',
          style: const TextStyle(
              color: SolaraColors.textSecondary, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('キャンセル',
                style: TextStyle(color: SolaraColors.textSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: SolaraColors.solaraGoldLight,
              foregroundColor: SolaraColors.celestialBlueDark,
            ),
            child: Text('$providerLabel でサインイン'),
          ),
        ],
      ),
    );
    if (proceed != true || !mounted) return false;
    try {
      if (isApple) {
        await SolaraAuth.instance.signInWithApple();
      } else {
        await SolaraAuth.instance.signInWithGoogle();
      }
    } on SolaraAuthException catch (e) {
      if (mounted) setState(() => _message = e.message);
      return false;
    } catch (e) {
      if (mounted) setState(() => _message = 'サインインに失敗しました');
      return false;
    }
    return SolaraAuth.instance.isSignedIn;
  }

  Future<void> _buy(Package pkg) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    final signedIn = await _ensureSignedIn();
    if (!signedIn) {
      if (mounted) setState(() => _busy = false);
      return;
    }
    final before = _status?.purchasedBalance ?? 0;
    try {
      final info = await PurchasesService.instance.purchasePackage(pkg);
      if (info == null) {
        // ユーザーキャンセル
        if (mounted) setState(() => _busy = false);
        return;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _message = '購入に失敗しました。時間をおいてお試しください。';
        });
      }
      return;
    }
    // 付与はサーバー側 (RC Webhook)。反映を数回ポーリングで待つ。
    await _pollUntilGranted(before);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  /// 購入後、サーバー残高が増えるまで最大 ~9 秒ポーリング (Webhook ラグ吸収)。
  /// ConsultationCredits.instance.refresh() で fetch + 全画面通知 (Sanctuary 上部 /
  /// Start popup 等) が一気通貫で走る。
  ///
  /// 間隔 500ms × 18 回 = 上限 9 秒。Webhook が即時反映されたケースで「購入完了 →
  /// シートが 0.5 秒以内に閉じる」体感を出すため、旧 1500ms 間隔から短縮。
  Future<void> _pollUntilGranted(int before) async {
    for (var i = 0; i < 18; i++) {
      await ConsultationCredits.instance.refresh();
      if (!mounted) return;
      final s = ConsultationCredits.instance.status;
      if (s != null && (s.purchasedBalance ?? 0) > before) {
        // 残高 update は singleton の notifyListeners 経由で本 sheet も再描画される。
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  }

  void _openPaywall() {
    Navigator.of(context).pop(false);
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => const PaywallScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: SolaraColors.glassBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Row(
              children: [
                Icon(Icons.auto_awesome,
                    color: SolaraColors.solaraGold, size: 20),
                SizedBox(width: 8),
                // 大フォント設定 (最大1.5x) + 狭い端末でもはみ出さないよう Flexible 化。
                Flexible(
                  child: Text('Stella 相談クレジット',
                      style: TextStyle(
                          color: SolaraColors.solaraGoldLight,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (_status != null && !_status!.pro)
              Text(
                '今週の無料相談 あと${_status!.freeRemaining ?? 0}回'
                '${(_status!.purchasedBalance ?? 0) > 0 ? ' ・ 購入残高 ${_status!.purchasedBalance}回' : ''}',
                style: const TextStyle(
                    color: SolaraColors.textSecondary, fontSize: 12),
              ),
            const SizedBox(height: 14),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CircularProgressIndicator(
                      color: SolaraColors.solaraGold, strokeWidth: 2),
                ),
              )
            else
              ..._buildContent(),
            if (_message != null) ...[
              const SizedBox(height: 10),
              Text(_message!,
                  style: const TextStyle(
                      color: SolaraColors.energyHardLight, fontSize: 12),
                  textAlign: TextAlign.center),
            ],
            const SizedBox(height: 14),
            // Pro 誘導 (踏み台 → Pro 転換装置)
            TextButton(
              onPressed: _busy ? null : _openPaywall,
              style: TextButton.styleFrom(
                  foregroundColor: SolaraColors.solaraGold),
              child: const Text('✦ Cosmic Pro なら回数無制限 →'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildContent() {
    final offering = _offering;
    final packages = offering?.availablePackages ?? const <Package>[];
    if (packages.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'クレジットの販売準備中です。\nしばらくしてからお試しください。',
            style: TextStyle(
                color: SolaraColors.textSecondary, fontSize: 13, height: 1.6),
            textAlign: TextAlign.center,
          ),
        ),
      ];
    }
    // 価格昇順 (small → large)
    final sorted = [...packages]..sort((a, b) =>
        a.storeProduct.price.compareTo(b.storeProduct.price));
    return [
      for (final p in sorted) _packageTile(p),
    ];
  }

  Widget _packageTile(Package p) {
    final product = p.storeProduct;
    final title = product.title.isNotEmpty ? product.title : 'クレジット';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: const Color(0x14F6BD60),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _busy ? null : () => _buy(p),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: SolaraColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      if (product.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(product.description,
                            style: const TextStyle(
                                color: SolaraColors.textSecondary,
                                fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(product.priceString,
                    style: const TextStyle(
                        color: SolaraColors.solaraGoldLight,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
