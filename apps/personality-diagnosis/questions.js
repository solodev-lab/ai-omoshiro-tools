// AI性格タイプ診断 - 質問データ
// 各質問は4軸(E/I, S/N, T/F, J/P)のいずれかを判定する
// choiceA = 左側の軸（E, S, T, J）、choiceB = 右側の軸（I, N, F, P）

const QUESTIONS = [
    // --- E/I 軸（外向/内向）: 3問 ---
    {
        id: 1,
        axis: "EI",
        text: "休日の理想の過ごし方は？",
        choiceA: { label: "友達と出かける", emoji: "🎉" },
        choiceB: { label: "家でひとり時間", emoji: "🏠" }
    },
    {
        id: 2,
        axis: "EI",
        text: "新しい環境に入ったとき、あなたは？",
        choiceA: { label: "自分から話しかける", emoji: "💬" },
        choiceB: { label: "話しかけられるのを待つ", emoji: "🤫" }
    },
    {
        id: 3,
        axis: "EI",
        text: "エネルギーが充電されるのは？",
        choiceA: { label: "人と会った後", emoji: "⚡" },
        choiceB: { label: "ひとりの時間の後", emoji: "🔋" }
    },

    // --- S/N 軸（現実/直感）: 2問 ---
    {
        id: 4,
        axis: "SN",
        text: "旅行の計画を立てるとき、重視するのは？",
        choiceA: { label: "具体的なスケジュール", emoji: "📋" },
        choiceB: { label: "ざっくりした方向性", emoji: "🧭" }
    },
    {
        id: 5,
        axis: "SN",
        text: "仕事や勉強で得意なのは？",
        choiceA: { label: "事実やデータの分析", emoji: "📊" },
        choiceB: { label: "アイデアや可能性の発想", emoji: "💡" }
    },

    // --- T/F 軸（論理/感情）: 3問 ---
    {
        id: 6,
        axis: "TF",
        text: "友達が悩みを相談してきたら？",
        choiceA: { label: "解決策を一緒に考える", emoji: "🔧" },
        choiceB: { label: "まず気持ちに寄り添う", emoji: "🤗" }
    },
    {
        id: 7,
        axis: "TF",
        text: "大事な決断をするとき、基準にするのは？",
        choiceA: { label: "論理的に正しいかどうか", emoji: "🧠" },
        choiceB: { label: "自分や周りの気持ち", emoji: "💖" }
    },
    {
        id: 8,
        axis: "TF",
        text: "映画の感想を聞かれたら？",
        choiceA: { label: "ストーリーの構成を語る", emoji: "🎬" },
        choiceB: { label: "感動したシーンを語る", emoji: "😭" }
    },

    // --- J/P 軸（計画/柔軟）: 2問 ---
    {
        id: 9,
        axis: "JP",
        text: "締め切りのある課題、どう取り組む？",
        choiceA: { label: "早めに計画的に進める", emoji: "📅" },
        choiceB: { label: "ギリギリで一気にやる", emoji: "🏃" }
    },
    {
        id: 10,
        axis: "JP",
        text: "予定が突然キャンセルになったら？",
        choiceA: { label: "ちょっと困る…", emoji: "😰" },
        choiceB: { label: "ラッキー！自由時間！", emoji: "🎊" }
    }
];
