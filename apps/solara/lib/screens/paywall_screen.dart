// Solara ペイウォール画面 — Phase 2-6b
//
// 設計:
//   - launch_checklist Phase 2「ペイウォール UI 🚨 公開ブロッカー B5 (3.1.2 全項目 + 特商法 5 項目必須)」
//   - project_solara_security_principles 原則 4「公開前必須の法務 3 点セット」
//   - feedback_i18n_last: 当面 ja-JP のみ。EN 版はストアアップ前最終工程
//
// 必須項目 (B5):
//   ✦ サブスクタイトル ✦ 期間 (月額/年額) ✦ 価格 (税込) ✦ コンテンツ概要
//   ✦ 自動更新明記 ✦ 解約方法リンク ✦ EULA ✦ プライバシーポリシー
//   ✦ Free Trial 明記 ✦ 購入を復元
//
// 振舞:
//   - Offerings 取得成功 → 月額 / 年額の 2 カード、タップで購入
//   - Offerings 取得失敗 (API キー未設定 / 未配信 / オフライン) → 「ストア準備中」案内
//   - 購入完了 → entitlement listener が ProStatus 更新 → pop で前画面に戻る

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/solara_colors.dart';
import '../utils/legal_urls.dart';
import '../utils/pro_status.dart';
import '../utils/purchases_service.dart';

part 'paywall_widgets.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  Offerings? _offerings;
  bool _loading = true;
  bool _purchasing = false;
  bool _restoring = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
    ProStatus.instance.addListener(_onProStatusChanged);
  }

  @override
  void dispose() {
    ProStatus.instance.removeListener(_onProStatusChanged);
    super.dispose();
  }

  void _onProStatusChanged() {
    // 購入成功 → entitlement listener で ProStatus.isPro=true → pop
    if (mounted && ProStatus.instance.isPro && _purchasing) {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _loadOfferings() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    final offerings = await PurchasesService.instance.getOfferings();
    if (!mounted) return;
    setState(() {
      _offerings = offerings;
      _loading = false;
    });
  }

  Future<void> _purchase(Package package) async {
    setState(() {
      _purchasing = true;
      _errorMessage = null;
    });
    try {
      final info = await PurchasesService.instance.purchasePackage(package);
      if (!mounted) return;
      if (info == null) {
        // ユーザーキャンセル
        setState(() => _purchasing = false);
        return;
      }
      // 成功時は listener 経由で ProStatus が更新され、_onProStatusChanged で pop
      // それでも残っていたら明示的に閉じる
      if (!ProStatus.instance.isPro) {
        // verification == failed 等で Pro 判定されなかった場合
        setState(() {
          _purchasing = false;
          _errorMessage =
              '購入は完了しましたが、エンタイトルメントの検証に失敗しました。時間を置いて「購入を復元」をお試しください。';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _purchasing = false;
        _errorMessage = 'お手続き中にエラーが発生しました。\n$e';
      });
    }
  }

  Future<void> _restore() async {
    setState(() {
      _restoring = true;
      _errorMessage = null;
    });
    try {
      final info = await PurchasesService.instance.restorePurchases();
      if (!mounted) return;
      setState(() => _restoring = false);
      if (info == null || !ProStatus.instance.isPro) {
        _showSnack('復元する購入が見つかりませんでした。');
      } else {
        _showSnack('購入を復元しました。');
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _restoring = false;
        _errorMessage = '復元中にエラーが発生しました。\n$e';
      });
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: SolaraColors.celestialBlueLight,
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      _showSnack('リンクを開けませんでした: $url');
    }
  }

  Future<void> _openCancelGuide() async {
    // iOS は設定アプリへの deep link、Android は Play Store の課金管理ページ。
    // どちらも launchUrl で開く。url_launcher は scheme で自動判別する。
    String url;
    if (!kIsWeb && Platform.isIOS) {
      url = LegalUrls.iosSubscriptionsDeepLink;
    } else if (!kIsWeb && Platform.isAndroid) {
      url = LegalUrls.androidSubscriptionsDeepLink;
    } else {
      url = LegalUrls.howToCancel;
    }
    await _openUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SolaraColors.celestialBlueDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: SolaraColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          '✦ Cosmic Pro',
          style: TextStyle(
            color: SolaraColors.solaraGoldLight,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHero(),
              const SizedBox(height: 24),
              _buildFeatureList(),
              const SizedBox(height: 28),
              _buildPlansSection(),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                _buildErrorPanel(_errorMessage!),
              ],
              const SizedBox(height: 24),
              _buildAutoRenewNotice(),
              const SizedBox(height: 16),
              _buildLegalLinks(),
              const SizedBox(height: 20),
              _buildRestoreButton(),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  // _buildHero / _buildFeatureList / _buildPlansSection / _buildStoreUnavailable
  // / _buildPlanCard / _periodLabel / _introPeriodLabel は paywall_widgets.dart (part) へ移動。
}
