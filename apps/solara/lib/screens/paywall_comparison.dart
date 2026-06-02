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
          _comparisonRow('Stella 相談', '週 3 回\n+ 購入クレジット', '週 100 回'),
          _comparisonRow(
            'タロット',
            '全体運 無料\n他カテゴリ 1 クレジット\n(1 日 1 回)',
            '全 7 カテゴリ\nクレジット消費なし\n+ 質問入力欄\n(1 日 1 回)',
          ),
          _comparisonRow('星読み (Horo)', '「全体運」のみ',
              '全 5 カテゴリ\n(全体・恋愛・豊かさ\n・仕事・対話)\n+ 深い読み'),
          _comparisonRow('拠点 (ライン近接) 解説', '✓', '✓'),
          _comparisonRow('おでかけの時刻指定\n+ 30分後の変化', '—', '✓\n(1時間刻み)'),
          _comparisonSection('地図 (ACG / CCG)'),
          _comparisonRow('ACG / CCG 4 フレーム',
              '✓ すべて\n(natal/transit\n/prog/solar arc)',
              '✓ すべて\n(natal/transit\n/prog/solar arc)'),
          _comparisonRow('天頂・天底点 / カテゴリ絞り込み', '✓', '✓'),
          _comparisonRow('天頂帯・天底帯 (緯度帯)', '—', '✓'),
          _comparisonRow('アスペクトライン', '40 本\n(合)', '120 本\n(合・□・△・⚹)'),
          _comparisonRow('引越しシミュレーション', '—', '✓'),
          _comparisonRow('拠点 (VP/LOCATION) 枠', '5か所', '10か所'),
          _comparisonSection('記録（あなたの記録は Free でも永久に残ります）'),
          _comparisonRow('占い・サイクルの永久保存', '✓', '✓'),
          _comparisonRow('星座アーカイブ・履歴の検索/フィルタ', '✓', '✓'),
          _comparisonRow('形成演出の再生・テキスト書き出し', '✓', '✓'),
          _comparisonRow('称号 (クラス) の再診断', '1 回まで', '無制限'),
          _comparisonSection('予報'),
          _comparisonRow('Forecast 期間', '1 年', '5 年'),
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
          'Stella 相談は Free 週 3 回 → Pro 週 100 回、星読みは Free「全体運」のみ → Pro 全 5 カテゴリ、'
              'アスペクトラインは Free 40 本 → Pro 120 本に増えます。タロットは両プラン 1 日 1 回ですが、'
              'Pro はカテゴリ指定時のクレジット消費なし + 質問入力欄が付与されます。\n\n'
              'ACG / CCG の 4 フレーム、星座アーカイブやタロット履歴の検索・フィルタ、'
              '占い結果の保存・シェアは Free でもお使いいただけます。'
              '詳細は上記表でご確認ください。',
        ),
        _faqItem(
          'Stella 相談の週次キャップを超えるとどうなりますか?',
          '追加クレジットの購入で継続してご利用いただけます。月曜のリセット時に Pro 週 100 回が補充されます。',
        ),
        _faqItem(
          'Pro のタロットは何が変わりますか?',
          'タロットは Free・Pro とも 1 日 1 回です。Pro では、クレジットを消費せずに'
              '聞きたいカテゴリ（全体運・恋愛・豊かさ・仕事・対話・癒し・変化）を指定して'
              'リーディングできます。さらに、知りたいことを直接質問として入力でき、'
              'その質問内容に応じたリーディング結果が表示されます。\n\n'
              'Free では全体運のみ無料（1 日 1 回）で、ほかのカテゴリは 1 回につき'
              '1 クレジットを消費します。',
        ),
        _faqItem(
          'おでかけ相談の「30分後の変化」とは?',
          'Cosmic Pro なら、おでかけ・イベントの相談で行く時刻を 1 時間刻みで'
              '指定できます。アストロカートグラフィ（CCG）の星の線は地球の自転で'
              '動くため、同じ場所でも 30 分で「その場の主役」が静かに入れ替わります。\n\n'
              '結果画面の「30分経過後を見る」を開くと、火星の線が離れていく／'
              '金星の線が近づいてくる といった移ろいを先に読めます。'
              '「核心は前半に」「後半にかけて温まる」のように、その場での'
              '時間の使い方が見えてきます（吉凶ではなく、エネルギーの質の移り変わりです）。',
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
        _faqItem(
          'Pro を再契約すると週次クレジットは増えますか?',
          'いいえ。週次クレジットは 1 アカウントごとに管理され、毎週月曜日にリセットされます。'
              'Pro を解約してすぐ再契約しても、その時点の残数は変わりません。'
              '不正利用ではありませんが、再契約によって「週 100 回」の制度を'
              '繰り返し補充するような抜け穴的な使い方はできない仕組みです。\n\n'
              '例: 水曜日に週次クレジットが残り 0 の状態で Pro を解約し、すぐ再契約しても、'
              '残りは 0 のままです。翌週の月曜日に 100 回へ復活します。',
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
