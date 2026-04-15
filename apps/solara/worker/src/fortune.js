/**
 * Fortune Reading — Gemini API を用いた占い文生成
 *
 * 入力: category, natal, transit?, aspects, patterns, lang('ja'|'en')
 * 出力: { reading, advice, direction }
 *
 * GEMINI_API_KEY は wrangler secret put GEMINI_API_KEY で設定
 * モデル: gemini-2.5-flash (テキスト生成、低コスト)
 */

// ── Fortune カテゴリ定義 ──
const FORTUNE_CATEGORIES = {
  overall: { jp: '全体運', en: 'Overall', planets: ['sun', 'moon', 'jupiter'] },
  love: { jp: '恋愛運', en: 'Love', planets: ['venus', 'mars', 'moon'] },
  money: { jp: '金運', en: 'Money', planets: ['venus', 'jupiter', 'saturn'] },
  career: { jp: '仕事運', en: 'Career', planets: ['saturn', 'venus', 'sun'] },
  communication: { jp: '対話運', en: 'Communication', planets: ['mercury', 'moon', 'jupiter'] },
};

const PLANET_JP = {
  sun: '太陽', moon: '月', mercury: '水星', venus: '金星', mars: '火星',
  jupiter: '木星', saturn: '土星', uranus: '天王星', neptune: '海王星', pluto: '冥王星',
};

const ASPECT_JP = {
  conjunction: 'コンジャンクション', opposition: 'オポジション',
  trine: 'トライン', square: 'スクエア', sextile: 'セクスタイル',
  quincunx: 'クインカンクス', semisextile: 'セミセクスタイル', semisquare: 'セミスクエア',
};

const PATTERN_JP = {
  grandtrine: 'グランドトライン', tsquare: 'Tスクエア', yod: 'ヨッド',
};

// ── カテゴリスコア計算 (関連惑星のアスペクト強度で算出) ──
//   soft/neutral → +, hard → - だが絶対値は影響力 (大=スコア振れ大)
//   最終スコア: 50 ± 影響量 をクランプ (20-95)
export function computeCategoryScore(category, aspects) {
  const cat = FORTUNE_CATEGORIES[category];
  if (!cat) return 50;
  const relevantPlanets = new Set(cat.planets);

  let influence = 0; // + で好調、- で課題
  for (const a of aspects) {
    const involved = relevantPlanets.has(a.p1) || relevantPlanets.has(a.p2);
    if (!involved) continue;
    const orb = a.orb ?? 2;
    const diffFromExact = Math.abs((a.diff ?? a.aspectAngle) - (a.aspectAngle ?? 0));
    const tightness = Math.max(0, 1 - diffFromExact / orb); // 0〜1 (exact=1)

    // quality 別重み
    if (a.quality === 'soft') influence += 10 * tightness;
    else if (a.quality === 'hard') influence -= 6 * tightness; // 課題=成長機会なのでsoft強め
    else influence += 3 * tightness; // neutral
  }

  const score = Math.round(50 + influence);
  return Math.max(20, Math.min(95, score));
}

// ── Gemini API 呼び出し (503時はリトライ) ──
async function callGemini(apiKey, prompt, { retries = 2 } = {}) {
  // fallback 順: 2.5-flash → 2.0-flash (503回避)
  const models = ['gemini-2.5-flash', 'gemini-2.0-flash'];
  let lastErr;
  for (const model of models) {
    for (let attempt = 0; attempt <= retries; attempt++) {
      try {
        const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;
        const res = await fetch(url, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            contents: [{ parts: [{ text: prompt }] }],
            generationConfig: {
              temperature: 0.9,
              topP: 0.95,
              maxOutputTokens: 2048, // JSON truncation回避
              responseMimeType: 'application/json',
            },
          }),
        });
        if (res.status === 503 || res.status === 429) {
          lastErr = new Error(`Gemini ${model} ${res.status}: overloaded`);
          if (attempt < retries) {
            await new Promise(r => setTimeout(r, 500 * (attempt + 1)));
            continue;
          }
          break; // 次のモデルへ
        }
        if (!res.ok) {
          const err = await res.text().catch(() => '');
          throw new Error(`Gemini API ${res.status}: ${err.slice(0, 200)}`);
        }
        const data = await res.json();
        const cand = data?.candidates?.[0];
        const text = cand?.content?.parts?.[0]?.text;
        const finishReason = cand?.finishReason;
        if (!text) throw new Error('Gemini response missing text');
        if (finishReason === 'MAX_TOKENS') {
          // 出力切れ - JSON不完全の可能性高い
          throw new Error('Gemini MAX_TOKENS: output truncated');
        }
        return text;
      } catch (e) {
        lastErr = e;
        if (attempt >= retries) break;
      }
    }
  }
  throw lastErr ?? new Error('Gemini call failed');
}

// ── プロンプト生成 ──
function buildPrompt({ category, lang, natal, aspects, patterns, date, userName }) {
  const cat = FORTUNE_CATEGORIES[category] || FORTUNE_CATEGORIES.overall;
  const catName = lang === 'en' ? cat.en : cat.jp;
  const dateStr = date || new Date().toISOString().slice(0, 10);

  // 関連アスペクト抽出 (関連惑星を含むもののみ)
  const relevantPlanets = new Set(cat.planets);
  const relevantAspects = (aspects || []).filter(a =>
    relevantPlanets.has(a.p1) || relevantPlanets.has(a.p2)
  ).slice(0, 8); // トークン節約

  const aspectLines = relevantAspects.map(a => {
    const p1 = lang === 'en' ? a.p1 : (PLANET_JP[a.p1] || a.p1);
    const p2 = lang === 'en' ? a.p2 : (PLANET_JP[a.p2] || a.p2);
    const type = lang === 'en' ? a.type : (ASPECT_JP[a.type] || a.type);
    return `- ${p1} × ${p2}: ${type} (${a.quality})`;
  }).join('\n');

  // 成立中の特殊パターン
  const patternLines = [];
  for (const type of ['grandtrine', 'tsquare', 'yod']) {
    const list = patterns?.[type] || [];
    for (const p of list) {
      const pNames = (p.planets || []).map(pl => {
        const key = typeof pl === 'string' ? pl : pl.key;
        return lang === 'en' ? key : (PLANET_JP[key] || key);
      }).join(', ');
      const name = lang === 'en' ? type : PATTERN_JP[type];
      patternLines.push(`- ${name}: ${pNames}`);
    }
  }

  if (lang === 'en') {
    return `You are an expert astrologer. Generate a personalized ${catName} fortune reading for today (${dateStr}).

Focus planets for this category: ${cat.planets.join(', ')}
${userName ? `User: ${userName}` : ''}

Key aspects involving these planets:
${aspectLines || '(no significant aspects)'}

Active special patterns:
${patternLines.join('\n') || '(none)'}

Return ONLY a JSON object with exactly these fields (no markdown, no extra text):
{
  "reading": "<2-3 sentence poetic reading focused on ${catName}. ~120-180 chars>",
  "advice": "<1 sentence practical advice. ~40-80 chars>",
  "direction": "<cardinal direction (N/NE/E/SE/S/SW/W/NW) + brief reason. ~30-60 chars>"
}`;
  }

  // 日本語
  return `あなたは経験豊かな占星術師です。今日 (${dateStr}) の${catName}について、パーソナライズされた占い文を生成してください。

このカテゴリの主要天体: ${cat.planets.map(p => PLANET_JP[p]).join('、')}
${userName ? `対象者: ${userName}さん` : ''}

主要天体に関わる現在のアスペクト:
${aspectLines || '(顕著なアスペクトなし)'}

成立中の特殊パターン:
${patternLines.join('\n') || '(なし)'}

以下のJSON形式のみで返答してください (マークダウンや余分な文言は不要):
{
  "reading": "<${catName}にフォーカスした詩的な2〜3文の鑑定。120〜200文字程度>",
  "advice": "<実践的なアドバイス1文。40〜80文字>",
  "direction": "<吉方位(東/西/南/北/北東/北西/南東/南西のいずれか)と簡潔な理由。30〜60文字>"
}`;
}

// ── メインエントリ: POST /fortune ──
export async function handleFortune(body, env) {
  const {
    category = 'overall',
    lang = 'ja',
    natal = {},
    aspects = [],
    patterns = {},
    date,
    userName,
  } = body;

  if (!FORTUNE_CATEGORIES[category]) {
    throw new Error(`Unknown category: ${category}`);
  }

  // 1. スコア計算 (LLM不要、確定的)
  const score = computeCategoryScore(category, aspects);

  // 2. Gemini でテキスト生成
  if (!env.GEMINI_API_KEY) {
    throw new Error('GEMINI_API_KEY not configured on worker');
  }
  const prompt = buildPrompt({ category, lang, natal, aspects, patterns, date, userName });
  const raw = await callGemini(env.GEMINI_API_KEY, prompt);

  // 3. JSON抽出 (Geminiは基本JSON返すが念のためfallback)
  let parsed;
  try {
    parsed = JSON.parse(raw);
  } catch {
    // コードフェンス除去してリトライ
    const cleaned = raw.replace(/^```json\s*|\s*```$/g, '').trim();
    try { parsed = JSON.parse(cleaned); }
    catch {
      throw new Error(`Gemini returned non-JSON: ${raw.slice(0, 200)}`);
    }
  }

  return {
    category,
    score,
    reading: parsed.reading || '',
    advice: parsed.advice || '',
    direction: parsed.direction || '',
    lang,
  };
}
