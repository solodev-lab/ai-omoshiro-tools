// ============================================================
// Solara Astro Glossary — Phase M2 論点4 (β案 確定)
//
// 占星術専門用語の解説辞書。AstroTermLabel widget と組み合わせて、
// 用語の横にiアイコンを置き、タップでグラスモーフィズム解説を出す。
//
// 設計: project_solara_astrocartography_m2.md 論点4
//   全て専門用語表記 + iアイコンで補助。
// ============================================================

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
    title: 'アスペクト線 (Astro*Carto*Graphy)',
    summary: '各惑星×ASC/MC/DSC/ICの世界地図上ライン。',
    detail:
        'Jim Lewis (1970年代) が体系化したアストロカートグラフィの主要手法。'
        '各惑星 × 4アングル = 40本のラインを地球曲面に投影。\n\n'
        '線上の土地ではその惑星のエネルギーが特定のアングルで強く働く。\n'
        '・金星 ASC ライン → 対人運・恋愛運が前面に\n'
        '・木星 MC ライン → キャリアでの幸運\n'
        '・土星 IC ライン → 家庭での重い責任',
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
};
