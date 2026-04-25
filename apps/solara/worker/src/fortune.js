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
// houses: そのカテゴリで重視する伝統占星術のハウス番号
//   1H=自己, 2H=所有/才能/収入, 3H=対話/兄弟/短距離, 4H=家庭/基盤,
//   5H=恋愛/楽しみ/創造, 6H=日常業務/健康, 7H=パートナー/結婚, 8H=共有資産/変容,
//   9H=哲学/遠距離/学問, 10H=社会的地位/キャリア, 11H=友人/ネットワーク, 12H=潜在意識/隠れた事
const FORTUNE_CATEGORIES = {
  overall: { jp: '全体運', en: 'Overall', planets: ['sun', 'moon', 'jupiter'], houses: [1] },
  love: { jp: '恋愛運', en: 'Love', planets: ['venus', 'mars', 'moon'], houses: [5, 7] },
  money: { jp: '金運', en: 'Money', planets: ['venus', 'jupiter', 'saturn'], houses: [2, 8] },
  career: { jp: '仕事運', en: 'Career', planets: ['saturn', 'venus', 'sun'], houses: [6, 10] },
  communication: { jp: '対話運', en: 'Communication', planets: ['mercury', 'moon', 'jupiter'], houses: [3, 9] },
};

const HOUSE_MEANINGS_JP = {
  1: '自己・新しい始まり', 2: '所有・才能・収入', 3: '対話・短距離・兄弟',
  4: '家庭・基盤', 5: '恋愛・楽しみ・創造', 6: '日常業務・健康',
  7: 'パートナー・結婚', 8: '共有資産・変容', 9: '哲学・遠距離・学問',
  10: '社会的地位・キャリア', 11: '友人・ネットワーク', 12: '潜在意識・隠れた事',
};

const HOUSE_MEANINGS_EN = {
  1: 'self/new beginnings', 2: 'possessions/talents/income', 3: 'communication/siblings/short trips',
  4: 'home/foundations', 5: 'romance/play/creativity', 6: 'daily work/health',
  7: 'partners/marriage', 8: 'shared resources/transformation', 9: 'philosophy/long trips/higher learning',
  10: 'career/public status', 11: 'friends/networks', 12: 'subconscious/hidden matters',
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

// ── Gemini API 呼び出し (503時はリトライ、404はモデル廃止扱いで即fallback) ──
// models: 試行順の配列。先頭が PRIMARY、それ以降が FALLBACK チェーン。
async function callGemini(apiKey, prompt, models, { retries = 2 } = {}) {
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
        if (res.status === 404) {
          // モデル廃止 → 即フォールバックへ
          const err = await res.text().catch(() => '');
          lastErr = new Error(`Gemini ${model} 404 (deprecated): ${err.slice(0, 200)}`);
          break;
        }
        if (!res.ok) {
          const err = await res.text().catch(() => '');
          throw new Error(`Gemini API ${model} ${res.status}: ${err.slice(0, 200)}`);
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
function buildPrompt({ category, lang, natal, planetHouses, aspects, patterns, date, userName }) {
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

  // ハウス情報（出生時刻が判明している場合のみ planetHouses が渡される）
  const HOUSE_MEANINGS = lang === 'en' ? HOUSE_MEANINGS_EN : HOUSE_MEANINGS_JP;
  const hasHouses = planetHouses && Object.keys(planetHouses).length > 0;
  let houseLines = '';
  let categoryHousesHint = '';
  if (hasHouses) {
    // カテゴリで重視するハウスの説明
    const houseHints = (cat.houses || []).map(h => `${h}H(${HOUSE_MEANINGS[h] || ''})`);
    categoryHousesHint = houseHints.join(' / ');
    // 関連惑星のハウス位置（cat.planets を優先）
    const lines = [];
    for (const p of cat.planets) {
      const h = planetHouses[p];
      if (h) {
        const pName = lang === 'en' ? p : (PLANET_JP[p] || p);
        const meaning = HOUSE_MEANINGS[h] || '';
        lines.push(`- ${pName}: ${h}H (${meaning})`);
      }
    }
    houseLines = lines.join('\n');
  }

  if (lang === 'en') {
    return `You are an expert astrologer. Generate a personalized ${catName} fortune reading for today (${dateStr}).

Focus planets for this category: ${cat.planets.join(', ')}
${categoryHousesHint ? `Houses traditionally read for ${catName}: ${categoryHousesHint}` : ''}
${userName ? `User: ${userName}` : ''}

${hasHouses ? `Natal house positions of focus planets:\n${houseLines || '(none mapped)'}\n` : '(House positions unavailable — birth time unknown)\n'}
Key aspects involving these planets:
${aspectLines || '(no significant aspects)'}

Active special patterns:
${patternLines.join('\n') || '(none)'}

🔴 If house positions are provided, weave them into the reading concretely (e.g. "with Venus in your 10th house of career, your love appears in professional contexts"). If unavailable, do not invent or mention houses.

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
${categoryHousesHint ? `${catName}で重視するハウス: ${categoryHousesHint}` : ''}
${userName ? `対象者: ${userName}さん` : ''}

${hasHouses ? `主要天体の出生ハウス位置:\n${houseLines || '(なし)'}\n` : '(ハウス位置は不明 — 出生時刻が登録されていません)\n'}
主要天体に関わる現在のアスペクト:
${aspectLines || '(顕著なアスペクトなし)'}

成立中の特殊パターン:
${patternLines.join('\n') || '(なし)'}

🔴 ハウス位置が与えられている場合は、それを具体的に織り込んでください（例:「金星が10ハウス（社会的地位）にあるあなたの恋愛運は、職場や公的な場での出会いから訪れる」）。ハウス位置が「不明」の場合は、ハウスについて捏造したり言及したりしないでください。

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
    planetHouses = null,
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
  // env vars から試行順のモデル配列を構築（未設定ならハードコード fallback）
  const primary = env.FORTUNE_MODEL_PRIMARY || 'gemini-2.5-flash';
  const fallback = env.FORTUNE_MODEL_FALLBACK || 'gemini-flash-latest';
  const models = primary === fallback ? [primary] : [primary, fallback];

  const prompt = buildPrompt({ category, lang, natal, planetHouses, aspects, patterns, date, userName });
  const raw = await callGemini(env.GEMINI_API_KEY, prompt, models);

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
