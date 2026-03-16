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

// 小アルカナ56枚を生成
const MINOR_ARCANA = [];
let minorId = 22;

SUITS.forEach(suit => {
    // 数札 1-10
    MINOR_NUMBERS.forEach(num => {
        MINOR_ARCANA.push({
            id: minorId++,
            name: `${suit.name}の${num.name}`,
            emoji: suit.emoji,
            suit: suit.name,
            upright: num.upright,
            reversed: num.reversed
        });
    });
    // 宮廷札
    COURT_CARDS.forEach(court => {
        MINOR_ARCANA.push({
            id: minorId++,
            name: `${suit.name}の${court.rank}`,
            emoji: suit.emoji,
            suit: suit.name,
            upright: court.upright,
            reversed: court.reversed
        });
    });
});

// 全78枚
const ALL_CARDS = [...MAJOR_ARCANA, ...MINOR_ARCANA];

// 5枚引きのポジション名
const FIVE_CARD_POSITIONS = [
    { name: '現在の状況', icon: '🔵' },
    { name: '障害・課題', icon: '🔴' },
    { name: '過去の影響', icon: '⏪' },
    { name: '未来の可能性', icon: '⏩' },
    { name: '最終結論', icon: '⭐' }
];

// 3枚引きのポジション名
const THREE_CARD_POSITIONS = [
    { name: '過去', icon: '⏪' },
    { name: '現在', icon: '🔵' },
    { name: '未来', icon: '⏩' }
];
