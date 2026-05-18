/**
 * タロットカード78枚データ
 * 大アルカナ22枚 + 小アルカナ56枚
 * 各カードに正位置・逆位置の基本意味を定義
 */

const MAJOR_ARCANA = [
    { id: 0, name: '愚者', emoji: '🃏', upright: '自由・冒険・無限の可能性', reversed: '無謀・無計画・現実逃避' },
    { id: 1, name: '魔術師', emoji: '🪄', upright: '才能開花・新たな始まり・自信', reversed: '空回り・詐欺・未熟' },
    { id: 2, name: '女教皇', emoji: '📿', upright: '直感・神秘・内なる知恵', reversed: '秘密・不安・判断力低下' },
    { id: 3, name: '女帝', emoji: '👑', upright: '豊穣・母性・愛情', reversed: '過保護・虚栄・停滞' },
    { id: 4, name: '皇帝', emoji: '🏛️', upright: '権威・安定・リーダーシップ', reversed: '独裁・頑固・支配欲' },
    { id: 5, name: '教皇', emoji: '🕊️', upright: '慈悲・教え・信頼', reversed: '偽善・束縛・形式主義' },
    { id: 6, name: '恋人', emoji: '💕', upright: '愛・選択・調和', reversed: '迷い・不信・誘惑' },
    { id: 7, name: '戦車', emoji: '⚔️', upright: '勝利・前進・意志力', reversed: '暴走・挫折・方向喪失' },
    { id: 8, name: '力', emoji: '🦁', upright: '内なる強さ・忍耐・勇気', reversed: '弱気・自信喪失・衝動' },
    { id: 9, name: '隠者', emoji: '🏔️', upright: '内省・探求・孤高の知恵', reversed: '孤立・引きこもり・頑固' },
    { id: 10, name: '運命の輪', emoji: '🎡', upright: '転機・幸運・サイクルの変化', reversed: '停滞・不運・悪循環' },
    { id: 11, name: '正義', emoji: '⚖️', upright: '公正・バランス・真実', reversed: '不公平・偏見・後ろめたさ' },
    { id: 12, name: '吊るされた男', emoji: '🔮', upright: '試練・忍耐・新しい視点', reversed: '無駄な犠牲・執着・逃避' },
    { id: 13, name: '死神', emoji: '🌑', upright: '終わりと再生・変容・手放し', reversed: '変化への抵抗・停滞・腐敗' },
    { id: 14, name: '節制', emoji: '🌈', upright: '調和・節度・癒し', reversed: '不均衡・極端・浪費' },
    { id: 15, name: '悪魔', emoji: '🔥', upright: '誘惑・執着・物質的欲望', reversed: '解放・束縛からの脱出・覚醒' },
    { id: 16, name: '塔', emoji: '⚡', upright: '崩壊・衝撃・根本的変化', reversed: '回避・小さな変化・恐怖' },
    { id: 17, name: '星', emoji: '⭐', upright: '希望・インスピレーション・癒し', reversed: '失望・自信喪失・絶望' },
    { id: 18, name: '月', emoji: '🌙', upright: '幻想・不安・潜在意識', reversed: '混乱の収束・真実の発見・恐怖克服' },
    { id: 19, name: '太陽', emoji: '☀️', upright: '成功・喜び・活力', reversed: '延期・エネルギー低下・自信過剰' },
    { id: 20, name: '審判', emoji: '📯', upright: '復活・目覚め・最終判断', reversed: '後悔・過去への執着・決断できず' },
    { id: 21, name: '世界', emoji: '🌍', upright: '完成・達成・統合', reversed: '未完成・遅延・目標の見失い' }
];

const SUITS = [
    { name: 'ワンド', emoji: '🪄', element: '火', theme: '情熱・行動・創造' },
    { name: 'カップ', emoji: '🏆', element: '水', theme: '感情・愛・直感' },
    { name: 'ソード', emoji: '🗡️', element: '風', theme: '知性・真実・葛藤' },
    { name: 'ペンタクル', emoji: '🪙', element: '地', theme: '物質・財運・現実' }
];

const MINOR_NUMBERS = [
    { num: 1, name: 'エース', upright: '始まり・チャンス・潜在力', reversed: '遅延・空振り・機会損失' },
    { num: 2, name: '2', upright: '選択・均衡・パートナーシップ', reversed: '迷い・不均衡・対立' },
    { num: 3, name: '3', upright: '成長・拡大・創造性', reversed: '停滞・浪費・努力不足' },
    { num: 4, name: '4', upright: '安定・基盤・休息', reversed: '不安定・閉塞感・怠惰' },
    { num: 5, name: '5', upright: '試練・変化・葛藤', reversed: '回復・受容・和解' },
    { num: 6, name: '6', upright: '調和・感謝・援助', reversed: '不調和・恩着せ・依存' },
    { num: 7, name: '7', upright: '探求・信念・挑戦', reversed: '迷走・幻滅・諦め' },
    { num: 8, name: '8', upright: '達成・力・前進', reversed: '焦り・空回り・行き詰まり' },
    { num: 9, name: '9', upright: '完成間近・知恵・忍耐', reversed: '不安・孤独・疲労' },
    { num: 10, name: '10', upright: '完結・結実・サイクルの終わり', reversed: '崩壊・過負荷・終われない' }
];

const COURT_CARDS = [
    { rank: 'ペイジ', upright: '学び・好奇心・新しいメッセージ', reversed: '未熟・軽率・悪い知らせ' },
    { rank: 'ナイト', upright: '行動・冒険・情熱的な追求', reversed: '衝動・無計画・暴走' },
    { rank: 'クイーン', upright: '成熟・包容力・深い理解', reversed: '感情的・嫉妬・依存' },
    { rank: 'キング', upright: '支配・達成・円熟', reversed: '独裁・傲慢・支配欲' }
];

const MINOR_ARCANA = [];
let minorId = 22;
SUITS.forEach(suit => {
    MINOR_NUMBERS.forEach(num => {
        MINOR_ARCANA.push({ id: minorId++, name: `${suit.name}の${num.name}`, emoji: suit.emoji, suit: suit.name, upright: num.upright, reversed: num.reversed });
    });
    COURT_CARDS.forEach(court => {
        MINOR_ARCANA.push({ id: minorId++, name: `${suit.name}の${court.rank}`, emoji: suit.emoji, suit: suit.name, upright: court.upright, reversed: court.reversed });
    });
});

const ALL_CARDS = [...MAJOR_ARCANA, ...MINOR_ARCANA];

const FIVE_CARD_POSITIONS = [
    { name: '現在の状況', icon: '🔵' },
    { name: '障害・課題', icon: '🔴' },
    { name: '過去の影響', icon: '⏪' },
    { name: '未来の可能性', icon: '⏩' },
    { name: '最終結論', icon: '⭐' }
];

const THREE_CARD_POSITIONS = [
    { name: '過去', icon: '⏪' },
    { name: '現在', icon: '🔵' },
    { name: '未来', icon: '⏩' }
];

// ツーカード（2枚引き）— 現状と対策
const TWO_CARD_POSITIONS = [
    { name: '現在の状況', icon: '🔵' },
    { name: '対策・アドバイス', icon: '💡' }
];

// ヘキサグラム（7枚引き）— 六芒星配置
// △上三角: ①過去(top) → ②現在(右下) → ③近未来(左下)
// ▽下三角: ④対策(bottom) → ⑤お相手(左上) → ⑥本人(右上)
// 中央: ⑦最終結果
const HEXAGRAM_POSITIONS = [
    { name: '過去', icon: '⏪' },
    { name: '現在', icon: '🔵' },
    { name: '近未来', icon: '⏩' },
    { name: 'アドバイス・対策', icon: '🔑' },
    { name: 'お相手の気持ち・周囲の環境', icon: '🌍' },
    { name: '本人の気持ち', icon: '💜' },
    { name: '最終結果', icon: '⭐' }
];

// 2者択一（6枚V字配置）— 引く順番通り
const TWO_CHOICE_POSITIONS = [
    { name: '現在', icon: '🔵' },
    { name: 'A 近未来', icon: '🅰️' },
    { name: 'B 近未来', icon: '🅱️' },
    { name: 'A 最終結果', icon: '🅰️' },
    { name: 'B 最終結果', icon: '🅱️' },
    { name: 'アドバイス', icon: '💡' }
];

// ホースシュー（7枚引き）— 馬蹄形U字配置 ∪
// 左上→左中→左下→中央下→右下→右中→右上
const HORSESHOE_POSITIONS = [
    { name: '過去', icon: '⏪' },
    { name: '現在', icon: '🔵' },
    { name: '未来', icon: '⏩' },
    { name: 'アドバイス', icon: '💡' },
    { name: '周囲の影響', icon: '🌍' },
    { name: '障害・課題', icon: '🔴' },
    { name: '最終結果', icon: '⭐' }
];

// リレーションシップクロス（5枚引き）— 恋愛・関係性の十字配置
// 配置: 上=過去 / 左=自分 中央=現在 右=相手 / 下=未来
const REL_CROSS_POSITIONS = [
    { name: 'あなた', icon: '💜' },
    { name: 'お相手', icon: '💙' },
    { name: '過去・基盤', icon: '⏪' },
    { name: '現在の関係', icon: '🔗' },
    { name: '未来の方向', icon: '⭐' }
];

// ミラースプレッド（7枚引き）— 恋愛・関係性の鏡像配置
// 中央=関係テーマ / 左列=自分(思考・感情・行動) / 右列=相手(思考・感情・行動)
const REL_MIRROR_POSITIONS = [
    { name: '関係のテーマ', icon: '🔗' },
    { name: 'あなたの思考', icon: '💭' },
    { name: 'あなたの感情', icon: '💜' },
    { name: 'あなたの行動', icon: '🌸' },
    { name: 'お相手の思考', icon: '💭' },
    { name: 'お相手の感情', icon: '💙' },
    { name: 'お相手の行動', icon: '🌊' }
];

// Yes/Noスプレッド（3枚引き）— シンプルYes/No判定
const YESNO_POSITIONS = [
    { name: '賛成の力', icon: '⭕' },
    { name: '反対の力', icon: '❌' },
    { name: '結論', icon: '⚖️' }
];

// 相談内容の選択ツリー
const CONSULTATION_TREE = {
    '💕 恋愛': {
        situations: ['片思い', '交際中', '復縁', '不倫', '配偶者'],
        questions: ['相手の気持ち', '今後の展開', 'アドバイス']
    },
    '💼 仕事': {
        situations: ['同僚', '上司', '部下', '別部署', '取引先', '客先'],
        questions: ['関係改善', '今後の展開', '転職すべき？', 'アドバイス']
    },
    '🏫 学校': {
        situations: ['友達', '先生', 'クラス', '進路'],
        questions: ['関係改善', '今後の展開', 'アドバイス']
    },
    '👨‍👩‍👧 家族': {
        situations: ['親', '兄弟姉妹', '親戚', '嫁姑'],
        questions: ['関係改善', '今後の展開', 'アドバイス']
    },
    '🤝 人間関係': {
        situations: ['友人', 'ご近所', '人付き合い全般'],
        questions: ['関係改善', '距離の取り方', 'アドバイス']
    },
    '💰 金運': {
        situations: ['収入', '投資', '借金', '転職'],
        questions: ['今後の流れ', '時期', 'アドバイス']
    },
    '🏥 健康': {
        situations: ['体調', 'メンタル', '生活習慣'],
        questions: ['注意すべきこと', '改善策', '時期']
    },
    '🌟 総合運': {
        situations: null,
        questions: ['今日', '今週', '今月']
    }
};
