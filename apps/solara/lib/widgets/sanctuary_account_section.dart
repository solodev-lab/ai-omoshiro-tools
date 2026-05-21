// Sanctuary ✦ Account セクション — Phase 2-9 Sign in 統合
//
// 役割:
//   - Sanctuary 内のアカウントセクション (Sign in / 表示 / Sign out) を独立ウィジェット化
//   - sanctuary_screen.dart の肥大化を避けるための分離 (既存 _SettingsGroup と同じ視覚)
//
// 振舞:
//   - 未サインイン: Apple (iOS/macOS のみ) + Google ボタン
//   - サインイン済: provider + displayName/email + サインアウトボタン
//   - SolaraAuth を ChangeNotifier として購読し、状態変化で再描画

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';

import '../utils/solara_auth.dart';

class SanctuaryAccountSection extends StatefulWidget {
  const SanctuaryAccountSection({super.key});

  @override
  State<SanctuaryAccountSection> createState() =>
      _SanctuaryAccountSectionState();
}

class _SanctuaryAccountSectionState extends State<SanctuaryAccountSection> {
  bool _deleting = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '✦ Account',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFFF9D976),
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(height: 10),
        AnimatedBuilder(
          animation: SolaraAuth.instance,
          builder: (ctx, _) {
            final acc = SolaraAuth.instance.account;
            return acc == null
                ? _buildSignedOutBlock()
                : _buildSignedInBlock(acc);
          },
        ),
      ],
    );
  }

  Widget _buildSignedOutBlock() {
    final isApplePlatform = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'サインインで Pro が端末間に追従',
            style: TextStyle(
              color: Color(0xFFEAEAEA),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '機種変更や端末追加でも Cosmic Pro を引き継げます。記録庫はサインインなしでも端末内に残ります。',
            style: TextStyle(
              color: Color(0xFFACACAC),
              fontSize: 11,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 14),
          // iOS/macOS は Apple サインインのみ表示 (Google は iOS 用設定が未済のため。
          // 公開後に iOS Google を設定したら戻す)。Android/その他は Google のみ。
          if (isApplePlatform)
            _signInButton(
              label: ' Apple でサインイン',
              icon: Icons.apple,
              // Google と同じ「透明背景 + 枠線 + 白文字」スタイル。
              // filled:true (白背景+黒文字) は文字が見えにくいとの指摘で変更。
              filled: false,
              onTap: () => _signIn(SolaraAuthProvider.apple),
            )
          else
            _signInButton(
              label: 'Google でサインイン',
              icon: Icons.account_circle_outlined,
              filled: false,
              onTap: () => _signIn(SolaraAuthProvider.google),
            ),
        ],
      ),
    );
  }

  Widget _buildSignedInBlock(SolaraAuthAccount acc) {
    final providerLabel =
        acc.provider == SolaraAuthProvider.apple ? 'Apple' : 'Google';
    final providerIcon = acc.provider == SolaraAuthProvider.apple
        ? Icons.apple
        : Icons.account_circle_outlined;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(providerIcon, color: const Color(0xFFF9D976), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      acc.displayLabel,
                      style: const TextStyle(
                        color: Color(0xFFEAEAEA),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$providerLabel でサインイン中',
                      style: const TextStyle(
                        color: Color(0xFFACACAC),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _deleting ? null : _signOut,
            icon: const Icon(Icons.logout, size: 16),
            label: const Text('サインアウト'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFACACAC),
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.zero,
            ),
          ),
          const Divider(color: Color(0x14FFFFFF), height: 18),
          TextButton(
            onPressed: _deleting ? null : _confirmDeleteAccount,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE57373),
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.zero,
            ),
            child: Row(
              children: [
                _deleting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFE57373),
                        ),
                      )
                    : const Icon(Icons.delete_outline, size: 16),
                const SizedBox(width: 8),
                // FittedBox(scaleDown) で、幅が足りない時だけ自動縮小して 1 行で全文表示
                // (切らない / RIGHT OVERFLOWED も出ない)。Flexible で利用可能幅を与える。
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _deleting ? '削除しています…' : 'Solaraからアカウントを削除',
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _signInButton({
    required String label,
    required IconData icon,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        height: 44,
        decoration: BoxDecoration(
          color: filled ? const Color(0xFFEAEAEA) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: filled ? null : Border.all(color: const Color(0x4DFFFFFF)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: filled
                  ? const Color(0xFF080C14)
                  : const Color(0xFFEAEAEA),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: filled
                    ? const Color(0xFF080C14)
                    : const Color(0xFFEAEAEA),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signIn(SolaraAuthProvider provider) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (provider == SolaraAuthProvider.apple) {
        await SolaraAuth.instance.signInWithApple();
      } else {
        await SolaraAuth.instance.signInWithGoogle();
      }
    } on SolaraAuthException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('サインインに失敗しました: $e')));
    }
  }

  Future<void> _signOut() async {
    await SolaraAuth.instance.signOut();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('サインアウトしました')),
    );
  }

  /// アカウント削除の確認ダイアログ (App Store ガイドライン 5.1.1(v))。
  /// 機能ダイアログ (削除確認) なので info_popup ではなく AlertDialog を使う
  /// (widgets/info_popup.dart の規約: 削除確認等は対象外)。
  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0x99000000),
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xE60A0A14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x33E57373)),
        ),
        title: const Text(
          'アカウントを削除しますか？',
          style: TextStyle(
            color: Color(0xFFEAEAEA),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'サインイン情報と、サーバー上の購読記録を削除します。\n\n'
          '・有料プランをご契約中の場合、解約は別途 App Store / Google Play から行ってください（削除では自動解約されません）。\n'
          '・端末内の記録庫（相談履歴・称号・Galaxy）は、この端末に残ります。\n'
          '・この操作は取り消せません。',
          style: TextStyle(
            color: Color(0xFFBFBFBF),
            fontSize: 12.5,
            height: 1.7,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(8, 0, 12, 10),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFACACAC),
            ),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE57373),
            ),
            child: const Text('削除する'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _performDelete();
  }

  Future<void> _performDelete() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _deleting = true);
    try {
      await SolaraAuth.instance.deleteAccount();
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('アカウントを削除しました')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('削除に失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }
}
