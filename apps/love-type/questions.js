// AI恋愛タイプ診断 - 質問データ & 恋愛タイプデータ

var QUESTIONS = [
    { q: "気になる人ができたらどうする？", choices: ["💌 すぐにアプローチする", "👀 じっくり観察してから動く", "🤝 まず友達として近づく", "😊 さりげなく好意をアピール"] },
    { q: "理想のデートは？", choices: ["🍽️ おしゃれなレストランで食事", "🏠 おうちでまったり過ごす", "🎢 テーマパークで思いっきり遊ぶ", "🌅 自然の中をのんびり散歩"] },
    { q: "恋人との喧嘩の後は？", choices: ["🔥 すぐ仲直りしたい", "🤔 一人で冷静に考える時間が欲しい", "😢 相手から謝ってほしい", "🗣️ とことん話し合って解決する"] },
    { q: "恋愛で最も大切にすることは？", choices: ["💖 情熱とときめき", "🤝 信頼と安心感", "😂 一緒に笑えること", "✨ お互いの成長"] },
    { q: "嫉妬するタイプ？", choices: ["🔥 かなり嫉妬する", "😤 少しだけする", "🤷 あまりしない", "😎 全くしない"] },
    { q: "愛情表現はどうする？", choices: ["💕 言葉でストレートに伝える", "🎁 行動やプレゼントで示す", "😳 恥ずかしくてなかなか言えない", "🤗 スキンシップで伝える"] },
    { q: "恋愛で一番辛いのは？", choices: ["💔 フラれること", "😔 気持ちがすれ違うこと", "⏳ 相手を待ち続けること", "🙈 自分の気持ちを伝えること"] },
    { q: "運命の相手って信じる？", choices: ["✨ 絶対に信じる！", "🤔 少し信じている", "🧐 半信半疑", "🙅 信じない、自分で見つける"] }
];

// 12恋愛タイプデータ
var LOVE_TYPES = {
    passionate: {
        id: "passionate",
        emoji: "🔥",
        name: "情熱型ロマンチスト",
        subtitle: "燃え上がる激しい恋をする人",
        description: "あなたは恋愛に全身全霊を注ぐ情熱的なタイプ。好きになったら止められない激しさがあり、愛情表現もストレートです。喜怒哀楽がはっきりしていて、恋愛を全力で楽しみます。その情熱は相手を虜にする最大の魅力です。",
        traits: ["愛情が深い", "行動力がある", "感情表現が豊か"],
        advice: "情熱は最大の武器ですが、時には冷静になって相手のペースも大切にしましょう。燃え上がりすぎて相手を疲れさせないよう注意して。",
        compatibility: "🛡️ 一途な騎士タイプ"
    },
    cinderella: {
        id: "cinderella",
        emoji: "👠",
        name: "慎重派シンデレラ",
        subtitle: "じっくり見極める恋の賢者",
        description: "あなたは恋愛に慎重なタイプ。相手をしっかり見極めてから心を開きます。表面的な魅力に惑わされず、内面を重視する賢さがあります。一度心を決めたら深い愛情を注ぐ、ギャップが魅力の持ち主です。",
        traits: ["観察力が鋭い", "内面重視", "ギャップが魅力"],
        advice: "慎重さは長所ですが、考えすぎて好機を逃すことも。時にはフィーリングを信じて一歩踏み出してみましょう。",
        compatibility: "🤝 友達から恋人タイプ"
    },
    freespirit: {
        id: "freespirit",
        emoji: "🦋",
        name: "自由奔放型",
        subtitle: "束縛嫌いの恋の冒険家",
        description: "あなたは自分の時間や空間を大切にするタイプ。恋愛も大事だけど、自分の世界も同じくらい重要。束縛されるのは苦手で、お互いを尊重し合える対等な関係を理想とします。自立した恋愛ができる大人な人です。",
        traits: ["自立している", "依存しない", "相手の自由も尊重"],
        advice: "自由を大切にしつつも、時には甘えることが相手への信頼の証になりますよ。距離感のバランスを意識して。",
        compatibility: "🌿 マイペース型タイプ"
    },
    knight: {
        id: "knight",
        emoji: "🛡️",
        name: "一途な騎士",
        subtitle: "一度好きになったら一直線",
        description: "あなたは一度好きになったらとことん一途に愛するタイプ。浮気なんて考えられないし、相手のことをいつも想っています。その誠実さと揺るぎない愛情が最大の魅力で、パートナーに安心感を与えます。",
        traits: ["誠実で信頼される", "深い愛情", "ブレない気持ち"],
        advice: "一途さは素晴らしい長所。でも尽くしすぎて自分を見失わないよう、自分自身も大切にすることを忘れないで。",
        compatibility: "🔥 情熱型ロマンチストタイプ"
    },
    tsundere: {
        id: "tsundere",
        emoji: "😤",
        name: "ツンデレ型",
        subtitle: "素直になれない愛されキャラ",
        description: "あなたは本当は好きなのに素直になれないツンデレタイプ。クールな態度の裏に深い愛情を隠しています。そのギャップに気づいた人だけが見られる甘い一面が、多くの人を魅了する不思議な魅力の持ち主です。",
        traits: ["ギャップの魅力", "本当は愛情深い", "独特な可愛さ"],
        advice: "素直になるのは怖いかもしれませんが、たまには正直に気持ちを伝えてみて。きっと相手は喜んでくれますよ。",
        compatibility: "💝 尽くし型タイプ"
    },
    clingy: {
        id: "clingy",
        emoji: "🍯",
        name: "甘えん坊タイプ",
        subtitle: "愛情確認が大好きな甘え上手",
        description: "あなたは恋人に甘えるのが大好きなタイプ。スキンシップや言葉での愛情確認を求め、いつも一緒にいたいと感じます。その可愛らしい甘え方が相手の保護欲を刺激し、愛される存在になります。",
        traits: ["甘え上手", "愛情深い", "コミュニケーション好き"],
        advice: "甘えることは素敵ですが、相手の一人の時間も尊重することで、もっと良い関係が築けますよ。",
        compatibility: "🛡️ 一途な騎士タイプ"
    },
    friendslover: {
        id: "friendslover",
        emoji: "🤝",
        name: "友達から恋人タイプ",
        subtitle: "信頼を育ててから恋に発展",
        description: "あなたは友達関係からじっくり信頼を育て、恋愛に発展させるタイプ。一目惚れよりも、時間をかけて相手を知ることで深い愛情が芽生えます。安定感のある長続きする恋愛ができる堅実な人です。",
        traits: ["信頼構築が上手", "長続きする恋", "安定感がある"],
        advice: "じっくり型の恋愛は素敵ですが、たまにはロマンチックな演出で相手をドキドキさせてみるのもおすすめ。",
        compatibility: "👠 慎重派シンデレラタイプ"
    },
    mysterious: {
        id: "mysterious",
        emoji: "🌙",
        name: "ミステリアス型",
        subtitle: "秘密のベールに包まれた魅惑の人",
        description: "あなたは全てを見せない神秘的な魅力の持ち主。ミステリアスな雰囲気が相手の興味を引き、追いかけたくなる存在です。恋の駆け引きが自然とできる、生まれながらのモテタイプと言えるでしょう。",
        traits: ["駆け引き上手", "神秘的な魅力", "聞き上手"],
        advice: "ミステリアスさも魅力ですが、信頼できる相手には少しずつ本当の自分を見せていくことで、もっと深い絆が生まれます。",
        compatibility: "🔥 情熱型ロマンチストタイプ"
    },
    selfless: {
        id: "selfless",
        emoji: "💝",
        name: "尽くし型",
        subtitle: "相手の幸せが自分の幸せ",
        description: "あなたは好きな人のために全力で尽くすタイプ。相手の喜ぶ顔が何よりの幸せで、料理を作ったり、プレゼントを選んだり、サポートすることが大好きです。その献身的な愛情が周囲の人を温かく包み込みます。",
        traits: ["思いやりがある", "面倒見がいい", "献身的"],
        advice: "尽くすことは素晴らしいですが、自分が幸せかどうかも定期的にチェックして。与えるだけでなく、受け取ることも大切ですよ。",
        compatibility: "😤 ツンデレ型タイプ"
    },
    ownpace: {
        id: "ownpace",
        emoji: "🌿",
        name: "マイペース型",
        subtitle: "自然体で愛を育む穏やかな人",
        description: "あなたは恋愛においてもマイペースを貫くタイプ。焦らず自然体で相手と向き合い、穏やかな愛情を育みます。無理をしない関係を好み、お互いの個性を大切にできる大人の恋愛観の持ち主です。",
        traits: ["自然体", "穏やかな愛情", "相手の個性を尊重"],
        advice: "マイペースは長所ですが、時には相手のペースに合わせる柔軟さも持つと、より深い関係が築けますよ。",
        compatibility: "🦋 自由奔放型タイプ"
    },
    destiny: {
        id: "destiny",
        emoji: "✨",
        name: "運命信じる型",
        subtitle: "赤い糸を信じるロマンチスト",
        description: "あなたは運命の出会いを信じるロマンチストタイプ。偶然の再会や不思議な縁を大切にし、恋愛にドラマチックな展開を求めます。記念日や特別な瞬間を大切にする、夢見がちだけど純粋な心の持ち主です。",
        traits: ["ロマンチスト", "記念日を大切にする", "純粋な心"],
        advice: "運命を信じる気持ちは素敵。でも理想を追い求めすぎず、目の前にいる人の良いところにもっと目を向けてみて。",
        compatibility: "🍯 甘えん坊タイプ"
    },
    strategist: {
        id: "strategist",
        emoji: "🧠",
        name: "理論派ストラテジスト",
        subtitle: "恋愛を冷静に分析する知性派",
        description: "あなたは恋愛においても理性的で冷静なタイプ。感情に流されず、相手との相性や将来性をしっかり見極めます。計画的にアプローチする戦略家で、落ち着いた大人の恋愛ができる知的な魅力の持ち主です。",
        traits: ["冷静な判断力", "分析力が高い", "計画的"],
        advice: "クールさも魅力ですが、たまには論理を手放して心のまま行動すると、予想外の素敵な展開が待っているかも。",
        compatibility: "🌙 ミステリアス型タイプ"
    }
};

// タイプIDの配列
var LOVE_TYPE_IDS = ['passionate', 'cinderella', 'freespirit', 'knight', 'tsundere', 'clingy', 'friendslover', 'mysterious', 'selfless', 'ownpace', 'destiny', 'strategist'];

// 恋愛タイプ判定関数
function determineLoveType(answers) {
    var passion = 0;
    var stability = 0;
    var independence = 0;
    var expression = 0;

    // Q1: 気になる人ができたら？ (0:すぐアプローチ, 1:じっくり観察, 2:友達から, 3:さりげなく)
    if (answers[0] === 0) { passion += 3; expression += 1; }
    if (answers[0] === 1) { stability += 2; independence += 1; }
    if (answers[0] === 2) { stability += 2; expression += 1; }
    if (answers[0] === 3) { expression += 2; independence += 1; }

    // Q2: 理想のデートは？ (0:レストラン, 1:おうち, 2:テーマパーク, 3:自然散歩)
    if (answers[1] === 0) { expression += 2; passion += 1; }
    if (answers[1] === 1) { stability += 3; }
    if (answers[1] === 2) { passion += 2; expression += 1; }
    if (answers[1] === 3) { independence += 2; stability += 1; }

    // Q3: 喧嘩の後は？ (0:すぐ仲直り, 1:一人で考える, 2:相手から謝って, 3:話し合い)
    if (answers[2] === 0) { passion += 2; expression += 1; }
    if (answers[2] === 1) { independence += 3; }
    if (answers[2] === 2) { expression += 2; passion += 1; }
    if (answers[2] === 3) { stability += 2; independence += 1; }

    // Q4: 恋愛で大切にすること (0:情熱, 1:信頼, 2:笑い, 3:成長)
    if (answers[3] === 0) { passion += 3; }
    if (answers[3] === 1) { stability += 3; }
    if (answers[3] === 2) { expression += 2; stability += 1; }
    if (answers[3] === 3) { independence += 2; stability += 1; }

    // Q5: 嫉妬する？ (0:かなり, 1:少し, 2:あまり, 3:全く)
    if (answers[4] === 0) { passion += 3; expression += 1; }
    if (answers[4] === 1) { passion += 1; stability += 1; }
    if (answers[4] === 2) { independence += 2; }
    if (answers[4] === 3) { independence += 3; }

    // Q6: 愛情表現は？ (0:言葉で, 1:行動で, 2:恥ずかしい, 3:スキンシップ)
    if (answers[5] === 0) { expression += 3; passion += 1; }
    if (answers[5] === 1) { stability += 2; expression += 1; }
    if (answers[5] === 2) { independence += 2; stability += 1; }
    if (answers[5] === 3) { passion += 2; expression += 1; }

    // Q7: 恋愛で辛いこと (0:フラれる, 1:すれ違い, 2:待つ, 3:気持ち伝える)
    if (answers[6] === 0) { passion += 2; expression += 1; }
    if (answers[6] === 1) { stability += 2; expression += 1; }
    if (answers[6] === 2) { passion += 2; independence += 1; }
    if (answers[6] === 3) { independence += 2; stability += 1; }

    // Q8: 運命の相手信じる？ (0:絶対信じる, 1:少し, 2:半信半疑, 3:信じない)
    if (answers[7] === 0) { passion += 2; expression += 2; }
    if (answers[7] === 1) { stability += 1; expression += 1; }
    if (answers[7] === 2) { independence += 1; stability += 1; }
    if (answers[7] === 3) { independence += 2; stability += 1; }

    // スコアに基づいてタイプ判定
    if (passion >= 8 && expression >= 5) return 'passionate';
    if (passion >= 6 && expression >= 6) return 'destiny';
    if (stability >= 8 && independence <= 4) return 'knight';
    if (stability >= 6 && expression >= 4) return 'friendslover';
    if (independence >= 8 && passion <= 4) return 'strategist';
    if (independence >= 6 && stability >= 4) return 'freespirit';
    if (expression >= 7 && passion >= 4) return 'clingy';
    if (expression >= 5 && independence >= 5) return 'tsundere';
    if (stability >= 6 && independence >= 4) return 'cinderella';
    if (passion >= 5 && stability >= 4) return 'selfless';
    if (independence >= 5 && expression <= 3) return 'mysterious';
    return 'ownpace';
}
