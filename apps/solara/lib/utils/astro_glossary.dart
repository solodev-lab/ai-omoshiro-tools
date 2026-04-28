// ============================================================
// Solara Astro Glossary — Phase M2 論点4 (β案 確定)
//
// 占星術専門用語の解説辞書。AstroTermLabel widget と組み合わせて、
// 用語の横にiアイコンを置き、タップでグラスモーフィズム解説を出す。
//
// 設計: project_solara_astrocartography_m2.md 論点4
//   全て専門用語表記 + iアイコンで補助。
// ============================================================

import 'package:flutter/material.dart';

import '../widgets/glass_panel.dart';

class AstroGlossaryEntry {
  /// 表示用の正式名 (例: "ASC (上昇宮)")
  final String title;

  /// 1行サマリ (タップ前の hint 表示用)
  final String summary;

  /// 詳細解説 (popup 内)
  final String detail;

  const AstroGlossaryEntry({
    required this.title,
    required this.summary,
    required this.detail,
  });
}

/// 用語キー → 解説。Map widgets から `astroGlossary[key]` で参照。
const Map<String, AstroGlossaryEntry> astroGlossary = {
  // ── 4 アングル ──
  'asc': AstroGlossaryEntry(
    title: 'ASC (Ascendant / 上昇宮)',
    summary: '東の地平線で昇る黄道点。第1ハウスの起点。',
    detail:
        '生まれた瞬間に東の地平線で昇っていた黄道上の点。第1ハウスのカスプ (起点) で、'
        '外面的な人格・第一印象・身体的特徴を司る。\n\n'
        'リロケーションで地点を変えると ASC の星座が変わり、'
        'その土地で「どんな人として現れるか」が変化する。',
  ),
  'mc': AstroGlossaryEntry(
    title: 'MC (Midheaven / 天頂)',
    summary: '子午線上の黄道点。第10ハウスの起点。',
    detail:
        '生まれた瞬間に天頂 (子午線と黄道の交点) にあった点。第10ハウスのカスプで、'
        '社会的役割・キャリア・公的な評価を司る。\n\n'
        'リロケーションで MC の星座が変わると、その土地での「社会的位置づけ」'
        'が変化する。「ハリウッド MC」のように特定の都市で MC を活かすという考え方も。',
  ),
  'dsc': AstroGlossaryEntry(
    title: 'DSC (Descendant / 下降宮)',
    summary: '西の地平線へ沈む黄道点。第7ハウスの起点。',
    detail:
        'ASC の真反対に位置する点。第7ハウスのカスプで、'
        'パートナーシップ・対人関係・結婚を司る。\n\n'
        'ASC が「自分」なら DSC は「自分にとっての他者」。'
        'リロケーションで DSC が変わると出会う相手の傾向が変わる。',
  ),
  'ic': AstroGlossaryEntry(
    title: 'IC (Imum Coeli / 天底)',
    summary: '子午線下の黄道点。第4ハウスの起点。',
    detail:
        'MC の真反対に位置する点。第4ハウスのカスプで、'
        '家庭・ルーツ・心の拠り所を司る。\n\n'
        'リロケーションで IC が変わると、その土地での「家としての落ち着き」'
        'の感覚が変わる。',
  ),

  // ── ハウス (12個) ──
  'house_1': AstroGlossaryEntry(
    title: '第1ハウス (アセンダント・ハウス)',
    summary: '自我・身体・第一印象。',
    detail: '自分自身、身体、性格の表れ方。ASC が起点。'
        'ここに惑星があるとその性質が「外に出る」。',
  ),
  'house_2': AstroGlossaryEntry(
    title: '第2ハウス (お金のハウス)',
    summary: '所有・金銭・自己価値。',
    detail: '稼ぐ力、所有物、自分の価値観。物質的な安定と自己肯定感の源。',
  ),
  'house_3': AstroGlossaryEntry(
    title: '第3ハウス (コミュニケーション)',
    summary: '会話・学び・近距離移動・兄弟姉妹。',
    detail: '日常的な会話、学習、近所、兄弟姉妹、短距離旅行。情報処理の場。',
  ),
  'house_4': AstroGlossaryEntry(
    title: '第4ハウス (家庭のハウス)',
    summary: '家・ルーツ・心の拠り所。IC が起点。',
    detail: '家、家族、出身、心の安全基地。終末期、晩年も司る。',
  ),
  'house_5': AstroGlossaryEntry(
    title: '第5ハウス (創造のハウス)',
    summary: '恋愛・遊び・創造性・子供。',
    detail: 'ロマンス、芸術表現、ギャンブル、子育て。喜びを生み出す場。',
  ),
  'house_6': AstroGlossaryEntry(
    title: '第6ハウス (仕事と健康)',
    summary: '日常業務・健康・奉仕。',
    detail: '日々のルーティンワーク、体調管理、奉仕。職人的な技術習得。',
  ),
  'house_7': AstroGlossaryEntry(
    title: '第7ハウス (パートナーシップ)',
    summary: '結婚・対人・契約。DSC が起点。',
    detail: '結婚相手、ビジネスパートナー、公然の敵。1対1の対峙関係。',
  ),
  'house_8': AstroGlossaryEntry(
    title: '第8ハウス (深淵のハウス)',
    summary: '他者の資源・性・変容・遺産。',
    detail: 'パートナーの財産、性、深い結びつき、遺産、心理的変容、生死。',
  ),
  'house_9': AstroGlossaryEntry(
    title: '第9ハウス (高次の探求)',
    summary: '哲学・宗教・遠距離旅行・高等教育。',
    detail: '海外、思想、大学、宗教、長距離移動。視野を広げる場。',
  ),
  'house_10': AstroGlossaryEntry(
    title: '第10ハウス (天職のハウス)',
    summary: '社会的役割・キャリア・名声。MC が起点。',
    detail: '職業、社会的地位、評判、目標。世間からの見え方。',
  ),
  'house_11': AstroGlossaryEntry(
    title: '第11ハウス (友愛のハウス)',
    summary: '友人・サークル・理想・未来計画。',
    detail: '友人、コミュニティ、希望、長期計画、社会改革。',
  ),
  'house_12': AstroGlossaryEntry(
    title: '第12ハウス (秘密のハウス)',
    summary: '無意識・秘密・隠遁・霊性。',
    detail: '無意識、隠された敵、入院、出家、霊的探求。表に出ないもの。',
  ),

  // ── Phase M2 機能用語 ──
  'relocation': AstroGlossaryEntry(
    title: 'リロケーション (Relocation Chart)',
    summary: '出生時刻はそのまま、別の土地でハウスを再計算。',
    detail:
        '惑星の位置 (黄経) は出生時刻で確定し、地点を変えても変わらない。'
        'しかし ASC・MC・12ハウスのカスプは「観測者の位置と方角」で決まるため、'
        '別の土地に立つと再計算される。\n\n'
        '結果: 同じ太陽でも「東京では5H」「ハワイでは10H」のように、'
        '体験するハウスが変わる = その土地での自分の出方が変わる。',
  ),
  'relocate_layer': AstroGlossaryEntry(
    title: '引越しレイヤー',
    summary: 'タップ地点でリロケーションチャートを表示。',
    detail:
        'Solara の引越し検討ツール。地図タップで、その土地に住んだ場合の'
        '10惑星のハウス再配置と、ASC/MC の星座変化を表示する。\n\n'
        '比較ベースは現住所 (未設定なら出生地)。'
        '個人天体 (太陽〜火星) のハウスが大きく変わる土地は、'
        '人生の方向性が変わる可能性のある土地と言える。',
  ),
  'aspect_lines': AstroGlossaryEntry(
    title: 'アスペクト線 (Astro*Carto*Graphy / Natal)',
    summary: '出生時の各惑星×ASC/MC/DSC/ICの世界地図上ライン。',
    detail:
        'Jim Lewis (1970年代) が体系化したアストロカートグラフィの主要手法。'
        '出生時の10惑星 × 4アングル = 40本のラインを地球曲面に投影。'
        '一生変わらない「本質の地図」。\n\n'
        '線上の土地ではその惑星のエネルギーが特定のアングルで強く働く。\n'
        '・金星 ASC ライン → 対人運・恋愛運が前面に\n'
        '・木星 MC ライン → キャリアでの幸運\n'
        '・土星 IC ライン → 家庭での重い責任',
  ),
  'transit_acg': AstroGlossaryEntry(
    title: 'Transit線 (Cyclo*Carto*Graphy)',
    summary: '今この瞬間の天体位置で引いた40本のライン。毎日動く。',
    detail:
        'Jim Lewis が A*C*G の続編として体系化した CCG (Cyclo*Carto*Graphy)。'
        '出生時ではなく「今 (またはタイムスライダーで指定した時刻)」'
        'の天体位置を世界地図に投影する。\n\n'
        '線は時間と共に動く。地球の自転で MC/IC は1日360°、'
        'ASC/DSC は緯度依存で蛇行しながら西へ流れる。\n\n'
        '使い方:\n'
        '・木星 ASC が今どこを通っているか → 今日のラッキー地点\n'
        '・土星 MC が来週東京を通る → 重い決断のタイミング',
  ),
  'progressed_acg': AstroGlossaryEntry(
    title: 'Progressed線 (Secondary Progression)',
    summary: '2次進行 (1日=1年) の天体位置で引いた40本。',
    detail:
        '2次進行 (1日=1年) で進めた天体位置を A*C*G ライン化したもの。'
        '人生の長期テーマがどこに現れるかの地図。\n\n'
        '出生から30年経った人なら、出生から30日後の天体位置を使う。'
        '太陽は約1°/年でゆっくり動き、月は約12°/年。\n\n'
        '「現在の自分の本質」が活性化する土地を示す。'
        'Natal線 (出生固定) より動きが緩やかで、Transit線より深い意味を持つ。',
  ),
  'solar_arc_acg': AstroGlossaryEntry(
    title: 'Solar Arc線 (ソーラーアーク方向)',
    summary: '太陽の進行弧を全惑星に等しく加算した位置でのライン。',
    detail:
        'ソーラーアーク・ディレクション = 太陽の2次進行による移動弧 '
        '(arc = 進行太陽 - 出生太陽) を全惑星に同じだけ加算する古典的予測法。\n\n'
        'Progressed と異なり、すべての惑星が同じ速度 (太陽速度) で動くため、'
        '惑星間のアスペクト構造が崩れず、人生の重要転機の'
        'タイミングを示す指標として伝統的に重視される。\n\n'
        'CCG では Solar Arc 木星MC 通過 = 大きな成功運の年、'
        'Solar Arc 土星ASC = 重大な責任年、のように読む。',
  ),
  'sector_score_16': AstroGlossaryEntry(
    title: '16方位スコア',
    summary: '出生地から見た方角別のエネルギー量。',
    detail:
        'natal/transit/progressed の総合アスペクトを16方位 (N, NNE, NE...) に投影し、'
        '方角ごとの「エネルギー量」を算出。色の濃淡で表示。\n\n'
        '引越しレイヤーとは別系統 (ローカルスペース流派)。'
        '同時表示時は引越しレイヤーを主としてこちらは dim 表示する。',
  ),
  'planet_lines': AstroGlossaryEntry(
    title: '惑星方位ライン (ローカルスペース)',
    summary: '出生地起点に各惑星の方角線を放射状に描画。',
    detail:
        'ローカルスペース流派の手法。出生地を中心とした「方位の家」を描き、'
        '各惑星がどの方向にあるかを線で示す。\n\n'
        'アストロカートグラフィ (アスペクト線) とは流派が異なる。'
        '前者は「ローカル方位」、後者は「世界曲線」。',
  ),
  'placidus': AstroGlossaryEntry(
    title: 'Placidus (プラシーダス)',
    summary: '時間ベースで12ハウスを分割する伝統的方式。',
    detail:
        'プラチドス・デ・ティティス (17世紀) のハウスシステム。'
        '太陽が ASC から MC まで動く時間を3等分してハウス境界を決める。\n\n'
        '高緯度 (|lat|>66°) では計算破綻するため、Solara は自動的に Equal House に'
        'フォールバックする。',
  ),
  // ── FORTUNE カテゴリ (CategoryPills の i アイコン用、2026-04-29) ──
  'fortune_all': AstroGlossaryEntry(
    title: '総合 (All Categories)',
    summary: '全10惑星のラインを100%表示。フィルタなし。',
    detail:
        '占星術の全領域を一望するモード。10惑星 × 4アングル = 40本の'
        'アスペクト線をすべて同じ強度で表示する。\n\n'
        '個別の運勢カテゴリではなく、「人生全体のエネルギー地図」'
        'として土地の総合的な性質を確認したいときに使う。',
  ),
  'fortune_love': AstroGlossaryEntry(
    title: '恋愛 (Love)',
    summary: '金星・火星・月のラインを強調、他は dim。',
    detail:
        '対人運・恋愛運に関わる惑星のみを際立たせるフィルタ。\n\n'
        '・金星 (Venus): 愛・美・関係性\n'
        '・火星 (Mars): 情熱・行動・性\n'
        '・月 (Moon): 感情・親密さ\n\n'
        'これら3惑星のラインが集まる土地は、恋愛体験が活性化しやすい。',
  ),
  'fortune_money': AstroGlossaryEntry(
    title: '金運 (Money)',
    summary: '木星・金星・太陽のラインを強調、他は dim。',
    detail:
        '財運・物質的成功に関わる惑星のフィルタ。\n\n'
        '・木星 (Jupiter): 拡大・幸運・繁栄\n'
        '・金星 (Venus): 価値・所有・贅沢\n'
        '・太陽 (Sun): 自己実現・地位\n\n'
        'これらの ASC/MC ラインが通る土地は、金運の追い風を得やすい。',
  ),
  'fortune_work': AstroGlossaryEntry(
    title: '仕事 (Career)',
    summary: '土星・火星・木星・太陽のラインを強調、他は dim。',
    detail:
        'キャリア・社会的達成に関わる惑星のフィルタ。\n\n'
        '・土星 (Saturn): 責任・規律・長期成果\n'
        '・火星 (Mars): 競争力・突破力\n'
        '・木星 (Jupiter): 機会・拡大\n'
        '・太陽 (Sun): リーダーシップ・公的評価\n\n'
        '特に MC ライン (天頂) が重要 — その土地での「社会的な顔」を示す。',
  ),
  'fortune_communication': AstroGlossaryEntry(
    title: '話す (Communication)',
    summary: '水星・金星・月のラインを強調、他は dim。',
    detail:
        'コミュニケーション・知的活動・対話に関わる惑星のフィルタ。\n\n'
        '・水星 (Mercury): 思考・言語・情報伝達\n'
        '・金星 (Venus): 社交・調和・魅力\n'
        '・月 (Moon): 共感・感情伝達\n\n'
        'これらのラインが通る土地は、執筆・営業・教育・SNS発信等が乗りやすい。',
  ),
  'fortune_healing': AstroGlossaryEntry(
    title: '癒し (Healing)',
    summary: '月・海王星・金星のラインを強調、他は dim。',
    detail:
        '癒し・休息・スピリチュアルな再生に関わる惑星のフィルタ。\n\n'
        '・月 (Moon): 安らぎ・無意識・母性\n'
        '・海王星 (Neptune): 直感・夢・統合\n'
        '・金星 (Venus): 美・喜び・自己受容\n\n'
        'これらのラインが通る土地は、リトリート・療養・内省に向く。',
  ),
};

/// 用語解説 popup を表示する共通ヘルパー。
/// LayerPanel / FramePills / CategoryPills 等から共通で呼ぶ。
/// [termKey] が astroGlossary に存在しなければ何もしない。
void showAstroGlossaryDialog(BuildContext context, String termKey) {
  final entry = astroGlossary[termKey];
  if (entry == null) return;
  showDialog<void>(
    context: context,
    barrierColor: const Color(0x99000000),
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
      child: GlassPanel(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(entry.title,
                      style: const TextStyle(
                        fontSize: 14, color: Color(0xFFC9A84C),
                        fontWeight: FontWeight.w600, letterSpacing: 0.4,
                      )),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(),
                    child: const Icon(Icons.close, size: 18, color: Color(0xFFAAAAAA)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(entry.summary,
                style: const TextStyle(
                  fontSize: 11, color: Color(0xFFAAAAAA),
                  height: 1.5, letterSpacing: 0.3,
                )),
              const Divider(color: Color(0x22FFFFFF), height: 18),
              Text(entry.detail,
                style: const TextStyle(
                  fontSize: 12, color: Color(0xFFE8E0D0),
                  height: 1.7, letterSpacing: 0.2,
                )),
            ],
          ),
        ),
      ),
    ),
  );
}
