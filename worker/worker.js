/**
 * AI Omoshiro Tools - Cloudflare Worker (API Proxy)
 *
 * 全アプリ共通のOpenAI APIプロキシ。
 * セキュリティ: リファラー制限 + レート制限 + CORS制御
 */

// ── レート制限（簡易版: KVなしでメモリベース）──
const rateLimitMap = new Map();
const RATE_LIMIT_WINDOW = 60000; // 1分
const RATE_LIMIT_MAX = 5; // 1分あたり5回/IP

function checkRateLimit(ip) {
    const now = Date.now();
    const record = rateLimitMap.get(ip);
    if (!record || now - record.start > RATE_LIMIT_WINDOW) {
        rateLimitMap.set(ip, { start: now, count: 1 });
        return true;
    }
    record.count++;
    if (record.count > RATE_LIMIT_MAX) return false;
    return true;
}

// ── メモリ掃除（リクエスト時に古いエントリを削除）──
function cleanupRateLimit() {
    const now = Date.now();
    for (const [ip, record] of rateLimitMap) {
        if (now - record.start > RATE_LIMIT_WINDOW * 2) {
            rateLimitMap.delete(ip);
        }
    }
}

// ── 許可するオリジン ──
const ALLOWED_ORIGINS = [
    'https://solodev-lab.github.io',
    'http://localhost',
    'http://127.0.0.1',
];

function isAllowedOrigin(origin) {
    if (!origin) return false;
    return ALLOWED_ORIGINS.some(allowed => origin.startsWith(allowed));
}

// ── 入力サニタイズ（プロンプトインジェクション対策）──
const MAX_STRING_LENGTH = 100;
const INJECTION_PATTERNS = /ignore|forget|disregard|override|system\s*prompt|api\s*key|secret|password|token|instructions|pretend|roleplay|you\s*are\s*now/i;

function sanitizeParams(params) {
    for (const key of Object.keys(params)) {
        const val = params[key];
        if (typeof val === 'string') {
            // 長さ制限
            params[key] = val.slice(0, MAX_STRING_LENGTH);
            // 危険な制御文字を除去
            params[key] = params[key].replace(/[\x00-\x1f\x7f]/g, '');
            // プロンプトインジェクション的なパターンを無害化
            if (INJECTION_PATTERNS.test(params[key])) {
                params[key] = params[key].replace(INJECTION_PATTERNS, '***');
            }
        } else if (Array.isArray(val)) {
            // 配列（例: traits）は各要素をサニタイズ + 最大5要素
            params[key] = val.slice(0, 5).map(v =>
                typeof v === 'string' ? v.slice(0, MAX_STRING_LENGTH).replace(/[\x00-\x1f\x7f]/g, '') : v
            );
        }
    }
}

// ── アプリ別プロンプト定義 ──
const APP_PROMPTS = {
    'naming-generator': {
        system: `あなたはネーミングの天才です。ユーザーの要望に合わせて、クリエイティブで印象的な名前を生成してください。
必ず以下のJSON形式で返答してください（他のテキストは不要）:
{
  "name": "メインの名前",
  "meaning": "名前の由来や意味（1文）",
  "alts": ["候補2", "候補3", "候補4"],
  "catchy": 75,
  "impact": 80,
  "memo": 70,
  "tip": "この名前に関するワンポイントアドバイス"
}`,
        buildPrompt: (params) => {
            const soundMap = {
                catchy: '短くキャッチーな（6文字以内）',
                impact: '長めでインパクトのある（7文字以上）',
                english: '英語まじりの',
                japanese: '日本語のみの（英語・フランス語など外国語は絶対に使わない）'
            };
            return `「${params.category}」の名前を考えてください。
テイスト: ${params.taste}
響き: ${soundMap[params.sound] || params.sound}
条件: メイン1つ + 候補3つを生成。すべての名前が響きの条件を満たすこと。`;
        }
    },
    'apology-generator': {
        system: `あなたは謝罪文の達人です。状況に合わせた心のこもった謝罪文を生成してください。
必ず以下のJSON形式で返答してください（他のテキストは不要）:
{
  "text": "謝罪文の本文（改行は\\nで表現）",
  "sincerity": 75,
  "tip": "この謝罪文を使うときのアドバイス"
}`,
        buildPrompt: (params) => {
            const severityMap = { light: '軽め', medium: 'そこそこ', heavy: 'かなりヤバい', critical: '人生終了レベル' };
            const formatMap = { business: 'ビジネスメール風', line: 'LINE（カジュアル）', letter: '手紙（フォーマル）' };
            return `謝罪の相手: ${params.target || '相手'}
状況: ${params.situation || '一般的な謝罪'}
深刻度: ${severityMap[params.severity] || params.severity || '普通'}
文体: ${formatMap[params.format] || params.format || 'ビジネスメール風'}
条件: 100〜200文字程度。相手に誠意が伝わる文章を生成してください。`;
        }
    },
    'excuse-generator': {
        system: `あなたは言い訳の天才です。クリエイティブで思わず笑ってしまう言い訳を生成してください。
必ず以下のJSON形式で返答してください（他のテキストは不要）:
{
  "excuse": "言い訳の本文",
  "convincing": 65,
  "creativity": 85,
  "stealth": 70,
  "risk": "low/medium/high/extreme",
  "tip": "この言い訳を使うときのコツ"
}`,
        buildPrompt: (params) => {
            const levelMap = { normal: '普通（信憑性重視）', creative: 'クリエイティブ（少し変わった）', genius: '天才（かなり独創的）', chaos: 'カオス（完全にネタ）' };
            return `言い訳が必要な状況: ${params.situation || '遅刻'}
言い訳のレベル: ${levelMap[params.level] || params.level || '普通'}
条件: 1〜3文程度。状況に合った説得力のある言い訳を生成してください。`;
        }
    },
    'love-confession': {
        system: `あなたは告白文のプロです。相手の心に響く告白文を生成してください。
必ず以下のJSON形式で返答してください（他のテキストは不要）:
{
  "text": "告白文の本文",
  "subtitle": "この告白のスタイル名（例: 王道ストレート、文学的アプローチ等）",
  "alts": ["別パターン1", "別パターン2"],
  "success": 65,
  "serious": 80,
  "power": 75,
  "tip": "告白を成功させるアドバイス"
}`,
        buildPrompt: (params) => {
            const sitMap = { direct: '直接会って', line: 'LINEで', letter: '手紙で', phone: '電話で' };
            return `相手との関係: ${params.relationship || '好きな人'}
告白のムード: ${params.mood || 'ストレート'}
シチュエーション: ${sitMap[params.situation] || params.situation || '直接'}
条件: 50〜150文字程度。心に響く告白文を生成してください。`;
        }
    },
    'pet-namer': {
        system: `あなたはペットの名付け親です。かわいくて覚えやすいペットの名前を提案してください。
必ず以下のJSON形式で返答してください（他のテキストは不要）:
{
  "name": "メインの名前",
  "meaning": "名前の由来（1文）",
  "alts": ["候補2", "候補3", "候補4"],
  "call": 85,
  "memo": 70,
  "cute": 80,
  "tip": "この名前にまつわるポイント"
}`,
        buildPrompt: (params) => {
            const styleMap = { japanese: '和風', western: '洋風', food: '食べ物系', unique: 'ユニーク・変わり種' };
            return `ペットの種類: ${params.pet || 'ペット'}
雰囲気: ${params.vibe || 'かわいい'}
名前のスタイル: ${styleMap[params.style] || params.style || '和風'}
条件: メイン1つ + 候補3つ。呼びやすく覚えやすい名前を生成してください。`;
        }
    },
    'dream-fortune': {
        system: `あなたは夢占いの専門家です。夢の内容から運勢と心理分析を行ってください。
必ず以下のJSON形式で返答してください（他のテキストは不要）:
{
  "interpretation": "夢の解釈（2〜3文）",
  "psychology": "心理学的な分析（1〜2文）",
  "fortune_score": 4,
  "lucky_color": "ラッキーカラー",
  "lucky_number": 7,
  "lucky_action": "今日やるといいこと",
  "tip": "夢からのメッセージ"
}
fortune_scoreは1〜5の整数（1=凶, 2=末吉, 3=小吉, 4=吉, 5=大吉）`,
        buildPrompt: (params) => `夢に出てきたシンボル: ${params.symbol || '不思議なもの'}
夢の中の気分: ${params.mood || '不思議'}
条件: シンボルと気分から、具体的で納得感のある夢占いを行ってください。`
    },
    'declutter-advisor': {
        system: `あなたは断捨離アドバイザーです。物を手放すかどうかの判断を手助けしてください。
必ず以下のJSON形式で返答してください（他のテキストは不要）:
{
  "verdict": "throw/keep/maybe",
  "verdict_title": "判定タイトル（例: 今すぐ手放そう！/大切に残そう/もう少し考えよう）",
  "verdict_subtitle": "一言コメント",
  "advice": "具体的なアドバイス（2〜3文）",
  "throw_score": 70,
  "regret_score": 30,
  "tip": "断捨離のコツ"
}
throw_scoreは0〜100（捨て度）、regret_scoreは0〜100（後悔度）`,
        buildPrompt: (params) => {
            const timeMap = { '1month': '1ヶ月以内', '6months': '半年以内', '1year': '1年以内', '3years': '1〜3年', 'over3': '3年以上' };
            return `断捨離するアイテムのカテゴリ: ${params.category || '物'}
最後に使った時期: ${timeMap[params.time] || params.time || '不明'}
捨てられない理由: ${params.reason || '特になし'}
条件: カテゴリと使用頻度、理由を考慮して、断捨離すべきかどうか判断してください。`;
        }
    },
    'nickname-maker': {
        system: `あなたはあだ名作りの達人です。入力された名前から楽しくて愛されるあだ名を考えてください。

【最重要ルール】あだ名には必ず入力された名前の一部（読み・音・文字）を含めてください。
- 例: 「田中太郎」→「たなっち」「タロー先輩」「たなたろ」など
- 例: 「佐藤花子」→「さとはな」「はなちゃん」「サトちん」など
- 名前と無関係なあだ名（動物名だけ、特徴だけ等）は絶対に禁止です。

必ず以下のJSON形式で返答してください（他のテキストは不要）:
{
  "nickname": "メインのあだ名（必ず名前の一部を含む）",
  "reading": "元の名前 → あだ名 の変換説明",
  "alts": ["候補2", "候補3", "候補4", "候補5"],
  "easy": 80,
  "stick": 75,
  "react": 70,
  "tip": "このあだ名のポイント"
}
easyは呼びやすさ、stickは定着度、reactはリアクション期待度（各0〜100）
altsの候補もすべて名前の一部を含むこと。`,
        buildPrompt: (params) => {
            const tasteMap = { cute: 'かわいい系', cool: 'かっこいい系', funny: 'おもしろ系', unique: '個性的' };
            return `名前: ${params.name || ''}
性格・特徴: ${(params.traits || []).join('、') || '特になし'}
テイスト: ${tasteMap[params.taste] || params.taste || 'かわいい系'}
条件: メイン1つ + 候補4つ以上。【重要】すべてのあだ名に「${params.name || ''}」の名前の一部（音・読み・文字）を必ず含めてください。名前と無関係なあだ名は禁止。`;
        }
    },
    'resignation-maker': {
        system: `あなたは退職届の文章作成アシスタントです。建前（フォーマル）と本音（カジュアル）の2パターンを生成してください。
必ず以下のJSON形式で返答してください（他のテキストは不要）:
{
  "tatemae": "建前の退職届文（改行は\\nで表現）",
  "honne": "本音バージョン（改行は\\nで表現）",
  "peaceful": 70,
  "honne_score": 60,
  "tip": "退職時のアドバイス"
}
peacefulは円満度（0〜100）、honne_scoreは本音度（0〜100）`,
        buildPrompt: (params) => {
            const tenureMap = { under1: '1年未満', '1to3': '1〜3年', '3to5': '3〜5年', '5to10': '5〜10年', over10: '10年以上' };
            const stanceMap = { gentle: '穏やか（円満退職）', normal: '普通', firm: '強め（引き止め拒否）', explosive: '爆発（もう限界）' };
            return `退職理由: ${params.reason || '一身上の都合'}
勤続年数: ${tenureMap[params.tenure] || params.tenure || '不明'}
スタンス: ${stanceMap[params.stance] || params.stance || '普通'}
条件: 建前は正式なビジネス文書、本音は率直で少しユーモアのある文章。各100〜200文字程度。`;
        }
    },
    'self-intro': {
        system: `あなたは自己紹介文の作成プロです。印象に残る自己紹介を生成してください。
必ず以下のJSON形式で返答してください（他のテキストは不要）:
{
  "text": "自己紹介文の本文",
  "subtitle": "この自己紹介のスタイル名",
  "alts": ["別パターン1", "別パターン2"],
  "impact": 80,
  "likable": 75,
  "memorable": 70,
  "tip": "自己紹介を成功させるコツ"
}`,
        buildPrompt: (params) => {
            const impressionMap = { friendly: '親しみやすい', smart: '知的', funny: 'おもしろい', mysterious: 'ミステリアス' };
            return `場面: ${params.scene || '一般'}
キャラ: ${params.chara || '普通'}
与えたい印象: ${impressionMap[params.impression] || params.impression || '親しみやすい'}
条件: 50〜150文字程度。場面とキャラに合った自然な自己紹介を生成してください。`;
        }
    },
    'personality-diagnosis': {
        system: `あなたは性格分析の専門家です。MBTI風の性格タイプと回答傾向から、パーソナライズされた分析を生成してください。
必ず以下のJSON形式で返答してください（他のテキストは不要）:
{
  "catchphrase": "このタイプのユニークなキャッチコピー（10文字以内）",
  "description": "性格の詳細説明（3〜4文）",
  "strengths": ["強み1", "強み2", "強み3"],
  "weaknesses": ["弱み1", "弱み2"],
  "compatibility": "相性の良いタイプコード（例: ENFP）",
  "compatibilityName": "相性タイプのキャッチコピー",
  "advice": "このタイプへのアドバイス（1文）"
}`,
        buildPrompt: (params) => `性格タイプ: ${params.type || 'INTJ'}
各軸のスコア: E=${params.scores?.E || 0}, I=${params.scores?.I || 0}, S=${params.scores?.S || 0}, N=${params.scores?.N || 0}, T=${params.scores?.T || 0}, F=${params.scores?.F || 0}, J=${params.scores?.J || 0}, P=${params.scores?.P || 0}
条件: このタイプに合った独創的なキャッチコピーと詳細分析を生成してください。毎回異なるキャッチコピーにしてください。`
    },
    'compatibility': {
        system: `あなたはAI相性診断の専門家です。2人の名前から相性を分析してください。
必ず以下のJSON形式で返答してください（他のテキストは不要）:
{
  "score": 75,
  "rank": "良い相性",
  "analysis": "2人の相性分析（2〜3文）",
  "advice": "2人へのアドバイス（1〜2文）"
}
scoreは40〜99の整数`,
        buildPrompt: (params) => `1人目の名前: ${params.name1 || '名前1'}
2人目の名前: ${params.name2 || '名前2'}
条件: 名前の響きやイメージから相性を分析してください。楽しくポジティブな内容にしてください。`
    },
    'past-life': {
        system: `あなたはAI前世診断の専門家です。回答傾向と前世タイプから、パーソナライズされた前世分析を生成してください。
必ず以下のJSON形式で返答してください（他のテキストは不要）:
{
  "description": "前世の詳細説明（3〜4文）",
  "traits": ["特徴1", "特徴2", "特徴3"],
  "luckyItem": "ラッキーアイテム"
}`,
        buildPrompt: (params) => `前世タイプID: ${params.typeId || 'unknown'}
回答パターン: ${JSON.stringify(params.answers || [])}
条件: このタイプに合った独創的で神秘的な前世の説明を生成してください。毎回異なる内容にしてください。`
    },
    'animal-type': {
        system: `あなたはAI動物タイプ診断の専門家です。回答傾向と動物タイプから、パーソナライズされた分析を生成してください。
必ず以下のJSON形式で返答してください（他のテキストは不要）:
{
  "description": "この動物タイプの詳細説明（3〜4文）",
  "traits": ["特徴1", "特徴2", "特徴3"],
  "compatibility": "相性の良い動物タイプ（1文）",
  "advice": "この動物タイプへのアドバイス（1文）"
}`,
        buildPrompt: (params) => `動物タイプID: ${params.animalId || 'unknown'}
回答パターン: ${JSON.stringify(params.answers || [])}
条件: この動物タイプに合った楽しい分析を生成してください。毎回異なる内容にしてください。`
    },
    'charm-level': {
        system: `あなたはAIモテ度診断の専門家です。回答傾向とスコアから、パーソナライズされたモテ度分析を生成してください。
必ず以下のJSON形式で返答してください（他のテキストは不要）:
{
  "description": "モテ度の詳細分析（3〜4文）",
  "charmPoints": ["モテポイント1", "モテポイント2", "モテポイント3"],
  "advice": "モテ度アップのアドバイス（1〜2文）"
}`,
        buildPrompt: (params) => `モテ度スコア: ${params.score || 50}点
ランク: ${params.rank || 'B'}
回答パターン: ${JSON.stringify(params.answers || [])}
条件: スコアとランクに合った具体的で励みになるモテ度分析を生成してください。`
    },
    'hidden-personality': {
        system: `あなたはAI裏性格診断の専門家です。表の顔と裏の顔のギャップを分析してください。
必ず以下のJSON形式で返答してください（他のテキストは不要）:
{
  "analysis": "表と裏のギャップ分析（3〜4文。面白くて共感できる内容に）",
  "advice": "このギャップを持つ人へのアドバイス（1〜2文）"
}`,
        buildPrompt: (params) => `性格タイプID: ${params.typeId || 'unknown'}
回答パターン: ${JSON.stringify(params.answers || [])}
条件: 表の顔と裏の顔のギャップを面白く分析してください。共感できる内容にしてください。`
    },
    'love-type': {
        system: `あなたはAI恋愛タイプ診断の専門家です。回答傾向と恋愛タイプから、パーソナライズされた分析を生成してください。
必ず以下のJSON形式で返答してください（他のテキストは不要）:
{
  "description": "恋愛タイプの詳細説明（3〜4文）",
  "traits": ["恋愛傾向1", "恋愛傾向2", "恋愛傾向3"],
  "compatibility": "相性の良い恋愛タイプ（1文）",
  "advice": "恋愛アドバイス（1〜2文）"
}`,
        buildPrompt: (params) => `恋愛タイプID: ${params.typeId || 'unknown'}
回答パターン: ${JSON.stringify(params.answers || [])}
条件: この恋愛タイプに合った楽しくて共感できる分析を生成してください。`
    },
    'mental-age': {
        system: `あなたはAIメンタル年齢診断の専門家です。回答傾向と精神年齢から、パーソナライズされた分析を生成してください。
必ず以下のJSON形式で返答してください（他のテキストは不要）:
{
  "description": "精神年齢の詳細分析（3〜4文。面白くて共感できる内容に）",
  "traits": ["特徴1", "特徴2", "特徴3"],
  "advice": "この精神年齢の人へのアドバイス（1〜2文）"
}`,
        buildPrompt: (params) => `精神年齢: ${params.mentalAge || 25}歳
回答パターン: ${JSON.stringify(params.answers || [])}
条件: この精神年齢に合った面白くて納得感のある分析を生成してください。`
    },
    'talent-finder': {
        system: `あなたはAI才能診断の専門家です。回答傾向と才能タイプから、パーソナライズされた分析を生成してください。
必ず以下のJSON形式で返答してください（他のテキストは不要）:
{
  "description": "才能の詳細説明（3〜4文）",
  "traits": ["才能の特徴1", "才能の特徴2", "才能の特徴3"],
  "compatibility": "この才能と相性の良い才能（1文）",
  "advice": "才能を活かすアドバイス（1〜2文）"
}`,
        buildPrompt: (params) => `才能タイプID: ${params.talentId || 'unknown'}
回答パターン: ${JSON.stringify(params.answers || [])}
条件: この才能タイプに合った励みになる分析を生成してください。`
    },
    'tarot-reading': {
        system: `あなたはタロット占いの専門家です。引かれたカードの組み合わせから、深い洞察に満ちた鑑定を行ってください。
カードの意味を尊重しつつ、相談者に寄り添った温かく具体的なメッセージを生成してください。

■ 1枚引き(one-card)の場合、以下のJSON形式で返答:
{
  "overall": "カードからの総合メッセージ（2〜3文）",
  "advice": "今日のアドバイス（1文）",
  "lucky_color": "ラッキーカラー",
  "lucky_number": 1〜9の整数
}

■ 3枚引き(three-card)の場合:
{
  "past": "過去の解釈（2文）",
  "present": "現在の解釈（2文）",
  "future": "未来の解釈（2文）",
  "overall": "3枚を通した総合メッセージ（2文）",
  "advice": "アドバイス（1文）"
}

■ 5枚引き(five-card)の場合:
{
  "current": "現在の状況（2文）",
  "obstacle": "障害・課題（2文）",
  "past_influence": "過去の影響（2文）",
  "future_potential": "未来の可能性（2文）",
  "conclusion": "最終結論（2文）",
  "obstacle_advice": "最終結論を良き結果にするために、障害をどのように扱い乗り越えるべきか（2〜3文、具体的なヒント）",
  "overall": "総合鑑定（3〜4文、詳細で深い洞察）",
  "advice": "具体的なアクションアドバイス（2文）",
  "lucky_item": "ラッキーアイテム"
}

必ず指定されたJSON形式のみで返答してください（他のテキストは不要）。`,
        buildPrompt: (params) => {
            const mode = params.mode || 'one-card';
            const cards = params.cards || [];
            const cardDesc = cards.map((c, i) => {
                const dir = c.isReversed ? '逆位置' : '正位置';
                return `${i + 1}枚目: ${c.name}（${dir}）- ${c.meaning}`;
            }).join('\n');

            const modeMap = {
                'one-card': '1枚引き（ワンオラクル）',
                'three-card': '3枚引き（過去・現在・未来）',
                'five-card': '5枚引き（ケルト十字簡易版：現状・障害・過去・未来・結論）'
            };

            return `占いモード: ${modeMap[mode] || mode}
引かれたカード:
${cardDesc}
条件: カードの意味と位置関係を深く読み解き、${mode}形式のJSONで鑑定結果を生成してください。毎回異なる表現で、具体的で心に響く内容にしてください。`;
        }
    },
    'business-email': {
        system: `あなたはビジネスメールの達人です。状況に合った完璧なビジネスメールを生成してください。
必ず以下のJSON形式で返答してください（他のテキストは不要）:
{
  "subject": "メールの件名",
  "body": "メール本文（改行は\\nで表現。宛名・挨拶・本文・締めを含む）",
  "polite": 85,
  "clarity": 80,
  "likable": 75,
  "tip": "このメールを送る際のワンポイントアドバイス"
}
politeは丁寧さ、clarityは伝達力、likableは好感度（各0〜100）`,
        buildPrompt: (params) => {
            const toneMap = { polite: '非常に丁寧（敬語・謙譲語をしっかり使う）', normal: '標準的なビジネス文体', casual: 'やや親しみのあるカジュアルなビジネス文体' };
            let prompt = `メールのシーン: ${params.scene || 'お礼'}
送信相手: ${params.target || '上司'}
トーン: ${toneMap[params.tone] || toneMap.polite}`;
            if (params.detail) {
                prompt += `\n詳細・背景: ${params.detail}`;
            }
            prompt += `\n条件: 宛名は「○○」のままプレースホルダーで。件名は具体的に。本文は150〜300文字程度。実用的で、そのままコピペして使えるメールを生成してください。`;
            return prompt;
        }
    }
};

// ── 使用済みStripeセッション管理（二重利用防止）──
const usedStripeSessions = new Set();

// ── メインハンドラ ──
export default {
    async fetch(request, env) {
        const url = new URL(request.url);
        const origin = request.headers.get('Origin') || '';

        // CORS preflight
        if (request.method === 'OPTIONS') {
            return new Response(null, {
                headers: corsHeaders(origin)
            });
        }

        // ヘルスチェック
        if (url.pathname === '/health') {
            return new Response(JSON.stringify({ status: 'ok' }), {
                headers: { 'Content-Type': 'application/json', ...corsHeaders(origin) }
            });
        }

        // Stripe Checkout Session作成
        if (request.method === 'POST' && url.pathname === '/api/stripe/create-checkout') {
            return handleStripeCreateCheckout(request, env, origin);
        }

        // Stripe Session検証 + 5枚引きAI鑑定
        if (request.method === 'POST' && url.pathname === '/api/stripe/verify-session') {
            return handleStripeVerifySession(request, env, origin);
        }

        // POST /api/generate のみ受付
        if (request.method !== 'POST' || url.pathname !== '/api/generate') {
            return new Response(JSON.stringify({ error: 'Not Found' }), {
                status: 404,
                headers: { 'Content-Type': 'application/json', ...corsHeaders(origin) }
            });
        }

        // オリジンチェック
        if (!isAllowedOrigin(origin)) {
            return new Response(JSON.stringify({ error: 'Forbidden' }), {
                status: 403,
                headers: { 'Content-Type': 'application/json' }
            });
        }

        // レート制限（古いエントリも掃除）
        cleanupRateLimit();
        const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
        if (!checkRateLimit(ip)) {
            return new Response(JSON.stringify({ error: 'Rate limit exceeded. Please wait a moment.' }), {
                status: 429,
                headers: { 'Content-Type': 'application/json', ...corsHeaders(origin) }
            });
        }

        try {
            const body = await request.json();
            const { app, params } = body;

            if (!app || !params) {
                return new Response(JSON.stringify({ error: 'Missing app or params' }), {
                    status: 400,
                    headers: { 'Content-Type': 'application/json', ...corsHeaders(origin) }
                });
            }

            const appConfig = APP_PROMPTS[app];
            if (!appConfig) {
                return new Response(JSON.stringify({ error: 'Unknown app' }), {
                    status: 400,
                    headers: { 'Content-Type': 'application/json', ...corsHeaders(origin) }
                });
            }

            // ── 入力サニタイズ ──
            sanitizeParams(params);

            const userPrompt = appConfig.buildPrompt(params);

            // OpenAI API呼び出し
            const openaiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${env.OPENAI_API_KEY}`
                },
                body: JSON.stringify({
                    model: 'gpt-4o-mini',
                    messages: [
                        { role: 'system', content: appConfig.system },
                        { role: 'user', content: userPrompt }
                    ],
                    max_tokens: 500,
                    temperature: 0.9
                })
            });

            if (!openaiResponse.ok) {
                const errText = await openaiResponse.text();
                console.error('OpenAI error:', errText);
                return new Response(JSON.stringify({ error: 'AI generation failed' }), {
                    status: 502,
                    headers: { 'Content-Type': 'application/json', ...corsHeaders(origin) }
                });
            }

            const openaiData = await openaiResponse.json();
            const content = openaiData.choices[0].message.content;

            // JSONパース（マークダウンコードブロック対応）
            let parsed;
            try {
                const jsonStr = content.replace(/```json?\n?/g, '').replace(/```/g, '').trim();
                parsed = JSON.parse(jsonStr);
            } catch (e) {
                console.error('JSON parse error:', content);
                return new Response(JSON.stringify({ error: 'AI response parse failed', raw: content }), {
                    status: 502,
                    headers: { 'Content-Type': 'application/json', ...corsHeaders(origin) }
                });
            }

            return new Response(JSON.stringify({ success: true, data: parsed }), {
                headers: { 'Content-Type': 'application/json', ...corsHeaders(origin) }
            });

        } catch (err) {
            console.error('Worker error:', err);
            return new Response(JSON.stringify({ error: 'Internal error' }), {
                status: 500,
                headers: { 'Content-Type': 'application/json', ...corsHeaders(origin) }
            });
        }
    }
};

// ── Stripe Checkout Session作成 ──
async function handleStripeCreateCheckout(request, env, origin) {
    if (!isAllowedOrigin(origin)) {
        return new Response(JSON.stringify({ error: 'Forbidden' }), {
            status: 403, headers: { 'Content-Type': 'application/json' }
        });
    }

    try {
        const successUrl = origin.startsWith('http://localhost') || origin.startsWith('http://127.0.0.1')
            ? `${origin}/apps/tarot-reading/success.html?session_id={CHECKOUT_SESSION_ID}`
            : 'https://solodev-lab.com/apps/tarot-reading/success.html?session_id={CHECKOUT_SESSION_ID}';
        const cancelUrl = origin.startsWith('http://localhost') || origin.startsWith('http://127.0.0.1')
            ? `${origin}/apps/tarot-reading/`
            : 'https://solodev-lab.com/apps/tarot-reading/';

        const stripeResponse = await fetch('https://api.stripe.com/v1/checkout/sessions', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${env.STRIPE_SECRET_KEY}`,
                'Content-Type': 'application/x-www-form-urlencoded'
            },
            body: new URLSearchParams({
                'mode': 'payment',
                'success_url': successUrl,
                'cancel_url': cancelUrl,
                'line_items[0][price_data][currency]': 'jpy',
                'line_items[0][price_data][product_data][name]': 'AIタロット占い 5枚引き（ケルト十字簡易版）',
                'line_items[0][price_data][unit_amount]': '300',
                'line_items[0][quantity]': '1'
            }).toString()
        });

        if (!stripeResponse.ok) {
            const errText = await stripeResponse.text();
            console.error('Stripe error:', errText);
            return new Response(JSON.stringify({ error: 'Checkout creation failed' }), {
                status: 502, headers: { 'Content-Type': 'application/json', ...corsHeaders(origin) }
            });
        }

        const session = await stripeResponse.json();
        return new Response(JSON.stringify({ url: session.url }), {
            headers: { 'Content-Type': 'application/json', ...corsHeaders(origin) }
        });
    } catch (err) {
        console.error('Stripe checkout error:', err);
        return new Response(JSON.stringify({ error: 'Internal error' }), {
            status: 500, headers: { 'Content-Type': 'application/json', ...corsHeaders(origin) }
        });
    }
}

// ── Stripe Session検証 + AI鑑定 ──
async function handleStripeVerifySession(request, env, origin) {
    if (!isAllowedOrigin(origin)) {
        return new Response(JSON.stringify({ error: 'Forbidden' }), {
            status: 403, headers: { 'Content-Type': 'application/json' }
        });
    }

    try {
        const body = await request.json();
        const { session_id, cards } = body;

        if (!session_id || !cards || !Array.isArray(cards)) {
            return new Response(JSON.stringify({ error: 'Missing session_id or cards' }), {
                status: 400, headers: { 'Content-Type': 'application/json', ...corsHeaders(origin) }
            });
        }

        // 二重利用チェック
        if (usedStripeSessions.has(session_id)) {
            return new Response(JSON.stringify({ error: 'Session already used' }), {
                status: 400, headers: { 'Content-Type': 'application/json', ...corsHeaders(origin) }
            });
        }

        // Stripe APIでセッション検証
        const verifyResponse = await fetch(`https://api.stripe.com/v1/checkout/sessions/${encodeURIComponent(session_id)}`, {
            headers: { 'Authorization': `Bearer ${env.STRIPE_SECRET_KEY}` }
        });

        if (!verifyResponse.ok) {
            return new Response(JSON.stringify({ error: 'Invalid session' }), {
                status: 400, headers: { 'Content-Type': 'application/json', ...corsHeaders(origin) }
            });
        }

        const session = await verifyResponse.json();

        if (session.payment_status !== 'paid') {
            return new Response(JSON.stringify({ error: 'Payment not completed' }), {
                status: 402, headers: { 'Content-Type': 'application/json', ...corsHeaders(origin) }
            });
        }

        // セッションを使用済みに
        usedStripeSessions.add(session_id);

        // 5枚引きAI鑑定を実行
        const appConfig = APP_PROMPTS['tarot-reading'];
        const params = { mode: 'five-card', cards };
        sanitizeParams(params);

        const userPrompt = appConfig.buildPrompt(params);

        const openaiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${env.OPENAI_API_KEY}`
            },
            body: JSON.stringify({
                model: 'gpt-4o-mini',
                messages: [
                    { role: 'system', content: appConfig.system },
                    { role: 'user', content: userPrompt }
                ],
                max_tokens: 800,
                temperature: 0.9
            })
        });

        if (!openaiResponse.ok) {
            return new Response(JSON.stringify({ error: 'AI generation failed' }), {
                status: 502, headers: { 'Content-Type': 'application/json', ...corsHeaders(origin) }
            });
        }

        const openaiData = await openaiResponse.json();
        const content = openaiData.choices[0].message.content;

        let parsed;
        try {
            const jsonStr = content.replace(/```json?\n?/g, '').replace(/```/g, '').trim();
            parsed = JSON.parse(jsonStr);
        } catch (e) {
            return new Response(JSON.stringify({ error: 'AI response parse failed' }), {
                status: 502, headers: { 'Content-Type': 'application/json', ...corsHeaders(origin) }
            });
        }

        return new Response(JSON.stringify({ success: true, data: parsed }), {
            headers: { 'Content-Type': 'application/json', ...corsHeaders(origin) }
        });
    } catch (err) {
        console.error('Stripe verify error:', err);
        return new Response(JSON.stringify({ error: 'Internal error' }), {
            status: 500, headers: { 'Content-Type': 'application/json', ...corsHeaders(origin) }
        });
    }
}

function corsHeaders(origin) {
    return {
        'Access-Control-Allow-Origin': isAllowedOrigin(origin) ? origin : '',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Max-Age': '86400'
    };
}
