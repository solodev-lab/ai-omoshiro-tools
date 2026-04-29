// 天頂点 (Zenith Point) 解説メッセージ辞書。
// 天頂点 = 各惑星のMCライン上で 緯度=惑星赤緯δ となる唯一の地点。
// 「観測者が立つと惑星が物理的に頭上(高度90°)に来る」場所。
// MCライン全体の中でも特に強い「シャワー直下」「ノズル先端」のスポット。
// Astro*Carto*Graphy モードで天頂点マーカータップ時に表示。

class ZenithMessage {
  final String title;     // 「太陽天頂点」等
  final String summary;   // 1行サマリ (~30字)
  final String detail;    // 詳述 (~100字、特徴と注意点)
  final List<String> tags; // タグ ['存在感', '創造', 'リーダー']
  const ZenithMessage({
    required this.title,
    required this.summary,
    required this.detail,
    required this.tags,
  });
}

const Map<String, ZenithMessage> astroZenithMessages = {
  'sun': ZenithMessage(
    title: '太陽天頂点',
    summary: '本質と存在感が物理的に強化される',
    detail: '自己表現のエネルギーが天頂から直降する地点。オーラが拡大し、自分軸が研ぎ澄まされる。'
        'リーダーシップ・名声・創造性の発揮に最適な土地です。',
    tags: ['存在感', '創造', 'リーダー'],
  ),
  'moon': ZenithMessage(
    title: '月天頂点',
    summary: '感情と無意識が大地と共鳴する',
    detail: '心の深層が天頂と繋がる地点。直感・感受性・母性的な保護が増幅される。'
        '家族との繋がり、内面の癒し、過去との和解に深い影響を与える土地です。',
    tags: ['感情', '直感', '癒し'],
  ),
  'mercury': ZenithMessage(
    title: '水星天頂点',
    summary: '言葉と思考が天から降る',
    detail: '情報伝達と知性のエネルギーが直降する地点。学習・執筆・交渉・スピーチで本領発揮。'
        '閃きと言語化能力が研ぎ澄まされます。',
    tags: ['学び', '伝達', '知性'],
  ),
  'venus': ZenithMessage(
    title: '金星天頂点',
    summary: '美と愛のエネルギーが頭上から降る',
    detail: '引き寄せ力と関係性運が天頂から直降する地点。出会い・芸術・調和・豊かさが花開く。'
        '美的感覚と魅力が増幅される魔法の土地です。',
    tags: ['愛', '美', '魅力'],
  ),
  'mars': ZenithMessage(
    title: '火星天頂点',
    summary: '情熱と行動力が直降する',
    detail: '突破力・闘志・身体エネルギーが天頂から降る地点。スポーツ・起業・武術・競争で実力以上の力が出る。'
        'ただし衝突・事故にも注意が必要な土地です。',
    tags: ['行動', '情熱', '突破'],
  ),
  'jupiter': ZenithMessage(
    title: '木星天頂点',
    summary: '拡大と恵みが頭上から降る',
    detail: '豊かさと成長機会の象徴。視野が広がり、寛大さ・楽観性・哲学的洞察が深まる地点。'
        '海外・教育・出版・宗教との縁が生まれやすい土地です。',
    tags: ['恩恵', '拡大', '学び'],
  ),
  'saturn': ZenithMessage(
    title: '土星天頂点',
    summary: '結晶化と達成のエネルギー',
    detail: '覚悟と責任が試され、磨かれる地点。試練を通じて本物の力と地位を築ける土地。'
        '短期的には重圧、長期的には不動の達成をもたらす磁場です。',
    tags: ['達成', '責任', '構築'],
  ),
  'uranus': ZenithMessage(
    title: '天王星天頂点',
    summary: '突然の覚醒と自由化',
    detail: '革新と独立のエネルギーが直降する地点。突如の閃き・既存からの解放・既成概念の破壊が起きやすい土地。'
        'テクノロジー・先端分野で道が開けます。',
    tags: ['革新', '自由', '覚醒'],
  ),
  'neptune': ZenithMessage(
    title: '海王星天頂点',
    summary: '夢と霊性が大地に滲む',
    detail: '境界が溶け、無形のエネルギーと繋がる地点。芸術・霊性・癒し・深い慈愛が花開く土地。'
        '一方で混乱・依存・現実逃避にも注意が必要です。',
    tags: ['霊性', '夢', '芸術'],
  ),
  'pluto': ZenithMessage(
    title: '冥王星天頂点',
    summary: '変容と再生の根源と直結',
    detail: '深層意識・タブー・力の問題が表面化する地点。人生を根本から作り変える試練と、その先の不可逆の再生。'
        '覚悟がある者にだけ訪れる土地です。',
    tags: ['変容', '再生', '深層'],
  ),
};
