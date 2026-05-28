// Paywall Screen — Free vs Pro 比較テーブル / FAQ アコーディオン
// (part of 'paywall_screen.dart')
//
// 役割:
//   - Suno 風レイアウトの下半分
//   - 比較テーブル: カテゴリ別 (相談・占い / 機能 / 計算) で Free vs Pro を行ごとに ✓ × / 値
//   - FAQ: 5 問のアコーディオン (memory project_solara_paywall_suno_redesign ドラフトに準拠)
//
// 行数管理:
//   - paywall_widgets.dart が大きくなりすぎないようここに分離。
//   - HARD 上限 600 行を意識し、本ファイル単体は 300 行未満を維持。

part of 'paywall_screen.dart';

extension _PaywallComparison on _PaywallScreenState {
  Widget _buildComparisonTable() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Free と Pro の違い',
            style: TextStyle(
              color: SolaraColors.solaraGoldLight,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 12),
          _comparisonHeader(),
          _comparisonSection('相談・占い'),
          _comparisonRow('Stella 相談', '週 3 回', '週 100 回'),
          _comparisonRow('タロット解釈', '1 日 1 回', '1 日 1 回\nクレジット消費なし\n+ テキスト入力欄'),
          _comparisonRow('星読み (Horo)', '「全体」のみ', '全 5 カテゴリ\n(全体・恋愛・豊かさ\n・仕事・対話)'),
          _comparisonSection('地図機能'),
          _comparisonRow('アスペクトライン', '40 本', '120 本'),
          _comparisonRow('アストロカートグラフィー', '部分機能', '全機能'),
          _comparisonSection('記録'),
          _comparisonRow('占い結果の永続的な記録', '—', '✓'),
          _comparisonRow('履歴の検索・フィルタ', '—', '✓'),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _comparisonHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: const [
          Expanded(
            flex: 4,
            child: Text(
              '機能',
              style: TextStyle(
                color: SolaraColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Free',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: SolaraColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Pro',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: SolaraColors.solaraGoldLight,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _comparisonSection(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 4),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 12,
            decoration: BoxDecoration(
              color: SolaraColors.solaraGoldLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: SolaraColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _comparisonRow(String label, String freeValue, String proValue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                color: SolaraColors.textPrimary,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              freeValue,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: SolaraColors.textSecondary,
                fontSize: 11,
                height: 1.45,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              proValue,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: SolaraColors.solaraGoldLight,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'よくあるご質問',
            style: TextStyle(
              color: SolaraColors.solaraGoldLight,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),
        _faqItem(
          'Free と Pro の違いは何ですか?',
          'Stella 相談は Free 週 3 回 → Pro 週 100 回、星読みは Free「全体」のみ → Pro 全 5 カテゴリ、'
              'アスペクトラインは Free 40 本 → Pro 120 本に増えます。タロットは両プラン 1 日 1 回ですが、'
              'Pro はカテゴリ選択時のクレジット消費なし + テキスト入力欄が付与されます。',
        ),
        _faqItem(
          'Stella 相談の週次キャップを超えるとどうなりますか?',
          '追加クレジットの購入で継続してご利用いただけます。月曜のリセット時に Pro 週 100 回が補充されます。',
        ),
        _faqItem(
          'タロットは Pro でも 1 日 1 回ですか?',
          'はい、両プラン 1 日 1 回です。Pro 特典は「カテゴリ選択時にクレジットを消費しない」「テキスト入力欄が付与される」の 2 点です。',
        ),
        _faqItem(
          'プランをアップグレード / ダウングレードできますか?',
          'Apple App Store または Google Play のサブスクリプション管理画面から、いつでも変更できます。'
              '自動更新を解約すると、次の課金日から Free プランへ自動的に切り替わります。',
        ),
        _faqItem(
          '解約後の機能はどうなりますか?',
          '現在の課金期間が終了するまでは Cosmic Pro 機能を継続してお使いいただけます。'
              '期間終了後は Free プランに自動移行します。占い結果の履歴は端末内に保存されたまま残ります。',
        ),
      ],
    );
  }

  Widget _faqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Theme(
        // ExpansionTile は divider を強制するため transparent に上書き。
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          iconColor: SolaraColors.solaraGoldLight,
          collapsedIconColor: SolaraColors.textSecondary,
          title: Text(
            question,
            style: const TextStyle(
              color: SolaraColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                answer,
                style: const TextStyle(
                  color: SolaraColors.textSecondary,
                  fontSize: 12,
                  height: 1.7,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
