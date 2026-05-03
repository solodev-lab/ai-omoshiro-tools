// ══════════════════════════════════════════════════════════════
// Aspect Description Data
// 惑星の意味 + アスペクトの性質 を組み合わせて読める文章を生成
// ══════════════════════════════════════════════════════════════

/// 惑星ごとのテーマ・キーワード
const Map<String, Map<String, String>> planetInfo = {
  'sun':     {'name': '太陽', 'theme': '自己・意志・生命力', 'keywords': '目標 / 存在感 / 自信'},
  'moon':    {'name': '月',   'theme': '感情・無意識・安心感', 'keywords': '感受性 / 習慣 / 母性'},
  'mercury': {'name': '水星', 'theme': '思考・言葉・知性', 'keywords': 'コミュニケーション / 学び / 分析'},
  'venus':   {'name': '金星', 'theme': '愛・調和・美', 'keywords': '人間関係 / 芸術 / 喜び'},
  'mars':    {'name': '火星', 'theme': '行動・情熱・欲求', 'keywords': '勇気 / 競争 / 決断'},
  'jupiter': {'name': '木星', 'theme': '拡大・寛容・成長', 'keywords': '寛容 / 冒険 / 哲学'},
  'saturn':  {'name': '土星', 'theme': '制限・責任・構造', 'keywords': '規律 / 忍耐 / 成熟'},
  'uranus':  {'name': '天王星', 'theme': '変革・独立・革新', 'keywords': '自由 / ひらめき / 突破'},
  'neptune': {'name': '海王星', 'theme': '理想・霊性・幻想', 'keywords': '直感 / 芸術 / 溶解'},
  'pluto':   {'name': '冥王星', 'theme': '変容・深層・破壊と再生', 'keywords': '根源力 / 秘密 / 浄化'},
  'asc':     {'name': 'ASC', 'theme': '外見・第一印象・自己表出', 'keywords': '姿勢 / 始まり'},
  'mc':      {'name': 'MC',  'theme': '社会的役割・天職', 'keywords': 'キャリア / 目的地'},
  'dsc':     {'name': 'DSC', 'theme': '対人関係・パートナー', 'keywords': '他者 / 鏡'},
  'ic':      {'name': 'IC',  'theme': '家・ルーツ・内面の基盤', 'keywords': '安心 / 起源'},
};

/// アスペクトタイプごとの性質
const Map<String, Map<String, String>> aspectInfo = {
  'conjunction': {
    'name': '合 (コンジャンクション)', 'angle': '0°', 'quality': '融合',
    'summary': '2つのエネルギーが重なり一体化・共存し、最も強い影響を発揮する。',
  },
  'sextile': {
    'name': 'セクスタイル', 'angle': '60°', 'quality': '調和 (軽)',
    'summary': '軽やかな協力関係。才能や機会として現れやすく、意識的に活かせる。',
  },
  'square': {
    'name': 'スクエア', 'angle': '90°', 'quality': '緊張',
    'summary': '摩擦や葛藤を生みながら、内的な成長と行動を促す。',
  },
  'trine': {
    'name': 'トライン', 'angle': '120°', 'quality': '調和 (強)',
    'summary': '自然な流れで才能が発揮される。努力なく恩恵を受けやすい。',
  },
  'opposition': {
    'name': 'オポジション', 'angle': '180°', 'quality': '対立・均衡',
    'summary': '内外の2極のバランスを取る課題。関係性の中で自分を知る。',
  },
  'quincunx': {
    'name': 'クインカンクス', 'angle': '150°', 'quality': '異視点',
    'summary': '異なる視点・価値観のエネルギーが対面する。統合と再調整の課題。',
  },
  'semisextile': {
    'name': 'セミセクスタイル', 'angle': '30°', 'quality': '微調整',
    'summary': '小さな機会と気付きを通して微細な調整を促す。意識すれば伸びる方向。',
  },
  'semisquare': {
    'name': 'セミスクエア', 'angle': '45°', 'quality': '小緊張',
    'summary': '小さな摩擦から動きが生まれる。日常の調整を通して前進を促す。',
  },
};

/// 特殊アスペクト (Grand Trine / T-Square / Yod) の解説 — source別
/// 'N' = ネイタル成立, 'T' = トランジット成立, 'P' = プログレス成立
const Map<String, Map<String, String>> patternDescriptions = {
  'grandtrine': {
    'title': 'グランドトライン (大三角)',
    'quality': '調和・恩恵',
    'summary': '3天体が120°ずつ結ばれる最も調和的な配置。才能や恵みが自然と流れる。',
    'N': 'グランドトラインがネイタルチャートに成立しています。3つの天体が120°ずつ調和的に結ばれ、才能や恵みが自然と流れる配置です。この力を意識的に活かすことで、大きな成果を引き寄せることができるでしょう。',
    'T': 'トランジット天体がネイタル天体とグランドトラインを形成しています。宇宙の調和が今まさにあなたに降り注いでいます。流れに身を任せることで、物事が驚くほどスムーズに進む時期です。チャンスを逃さず、積極的に行動しましょう。',
    'P': 'プログレス天体がグランドトラインを完成させています。人生の深い層で調和のエネルギーが熟成し、長期的な恵みの流れが形成されつつあります。内面的な成長が外側の現実に反映される重要な時期です。',
  },
  'tsquare': {
    'title': 'Tスクエア',
    'quality': '緊張・成長',
    'summary': '2天体がオポジション、両方に90°で頂点天体が立つ。緊張が行動を促す。',
    'N': 'Tスクエアがネイタルチャートに成立しています。緊張と葛藤のエネルギーが3つの天体間で生まれていますが、これは成長の原動力でもあります。頂点の天体が示すテーマに取り組むことで、大きな飛躍が期待できます。',
    'T': 'トランジット天体がTスクエアを活性化しています。一時的な緊張やプレッシャーを感じるかもしれませんが、それは変化と成長のサインです。課題に正面から向き合うことで、停滞を打破する力が得られるでしょう。',
    'P': 'プログレス天体がTスクエアを形成しています。人生の転換期を示す重要な配置です。内面的な葛藤が表面化しやすい時期ですが、この緊張を乗り越えることで人格的な成熟が進みます。',
  },
  'yod': {
    'title': 'ヨッド (神の指)',
    'quality': '運命・使命',
    'summary': '2天体がセクスタイル、両方に150°で頂点天体が立つ神秘的配置。',
    'N': 'ヨッド（神の指）がネイタルチャートに成立しています。運命的な使命を暗示する神秘的な配置です。頂点の天体が指し示す方向に、あなたの魂の目的が隠されています。直感を信じて、その道を探求してみましょう。',
    'T': 'トランジット天体がヨッドを完成させています。運命的な転機が訪れている暗示です。予期せぬ出来事や出会いが、人生の新しい方向性を示してくれるかもしれません。宇宙からのメッセージに耳を傾けてください。',
    'P': 'プログレス天体がヨッドを形成しています。魂のレベルで深い変容が起きている時期です。長年の謎が解けるような気づきや、人生の使命がより明確になる体験があるかもしれません。',
  },
};

/// アスペクト説明を生成 (3セクション)
///   title: "太陽 トライン 月" 形式
///   theme: 両惑星のテーマ
///   quality: アスペクトの性質
///   reading: 組み合わせ解釈 (短文)
Map<String, String> buildAspectDescription(String p1, String p2, String aspectType) {
  final pi1 = planetInfo[p1] ?? {'name': p1, 'theme': '', 'keywords': ''};
  final pi2 = planetInfo[p2] ?? {'name': p2, 'theme': '', 'keywords': ''};
  final asp = aspectInfo[aspectType] ?? {
    'name': aspectType, 'angle': '', 'quality': '', 'summary': '',
  };

  final title = '${pi1['name']} × ${pi2['name']}';
  final aspectLine = '${asp['name']} (${asp['angle']}) — ${asp['quality']}';
  final theme = '${pi1['theme']} と ${pi2['theme']} の関係';
  final summary = asp['summary'] ?? '';
  final reading = '${pi1['name']}(${pi1['keywords']}) と '
      '${pi2['name']}(${pi2['keywords']}) のテーマが '
      '${asp['quality']}な形で絡み合う。';

  return {
    'title': title,
    'aspect': aspectLine,
    'theme': theme,
    'summary': summary,
    'reading': reading,
  };
}
