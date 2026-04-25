/**
 * Tarot Reading — Gemini API を用いたタロット占い文生成
 *
 * 入力:
 *   cardId (0-77), reversed (bool), nameJP, keyword, element, planet?,
 *   moonPhase (0-29.53), userName?, lang ('ja'|'en')
 *
 * 出力: { reading }
 *   reading: 3〜5文の鑑定（〜250文字）
 *
 * GEMINI_API_KEY は wrangler secret put GEMINI_API_KEY で設定済み
 * モデル: env vars TAROT_MODEL_PRIMARY/FALLBACK で指定（廃止リスク対策）
 */

const PLANET_JP = {
  sun: '太陽', moon: '月', mercury: '水星', venus: '金星', mars: '火星',
  jupiter: '木星', saturn: '土星', uranus: '天王星', neptune: '海王星', pluto: '冥王星',
};

const ELEMENT_JP = {
  fire: '火', water: '水', air: '風', earth: '地',
};

// 月相を 8 段階の名前に分類（0〜29.53）
function moonPhaseLabel(p, lang) {
  const day = p % 29.53;
  const phases = lang === 'en'
    ? ['New Moon', 'Waxing Crescent', 'First Quarter', 'Waxing Gibbous',
       'Full Moon', 'Waning Gibbous', 'Last Quarter', 'Waning Crescent']
    : ['新月', '三日月', '上弦', '十三夜', '満月', '十六夜', '下弦', '有明月'];
  // 8 等分（≈3.69日ごと）
  const idx = Math.min(7, Math.floor(day / (29.53 / 8)));
  return phases[idx];
}

// ── Gemini API 呼び出し ──
// models: 試行順の配列。先頭が PRIMARY、それ以降が FALLBACK チェーン。
// 廃止モデル(404)・ overload(503/429) ・ tx エラーいずれも次のモデルへ自動フォールバック。
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
              temperature: 0.95,
              topP: 0.95,
              maxOutputTokens: 1024,
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
          break;
        }
        if (res.status === 404) {
          // モデル廃止 → リトライせず即フォールバックへ
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
function buildPrompt({ cardId, reversed, nameJP, nameEN, keyword, element, planet, moonPhase, userName, lang }) {
  const orientation = reversed
    ? (lang === 'en' ? 'Reversed' : '逆位置')
    : (lang === 'en' ? 'Upright' : '正位置');
  const elementLabel = lang === 'en' ? element : (ELEMENT_JP[element] || element);
  const planetLabel = planet
    ? (lang === 'en' ? planet : (PLANET_JP[planet] || planet))
    : null;
  const moonLabel = (typeof moonPhase === 'number') ? moonPhaseLabel(moonPhase, lang) : null;
  // 末尾の敬称「さん」を取り除く（プロンプト側で「さん」を付けるので二重防止）
  const cleanName = (typeof userName === 'string')
    ? userName.replace(/さん$/, '').trim()
    : null;

  if (lang === 'en') {
    const cardName = nameEN || nameJP;
    return `You are a wise tarot reader with a poetic voice.
Today's card: "${cardName}" (${orientation})
Keyword: ${keyword}
Element: ${elementLabel}${planetLabel ? `\nRuling planet: ${planetLabel}` : ''}${moonLabel ? `\nMoon phase: ${moonLabel}` : ''}${cleanName ? `\nQuerent name: ${cleanName}` : ''}

🔴 CRITICAL: The card is "${cardName}". Do NOT substitute it with any other card name (e.g. "Wheel of Fortune", "The Sun"). Names like "Death", "The Devil", "The Tower" are traditional tarot symbols of transformation; keep them verbatim. The reading MUST mention "${cardName}" in its opening sentence.

Write a tarot reading honoring the orientation:
- Upright: bring out the card's affirming, growth-oriented meaning
- Reversed: speak to the shadow, blockage, or inverted lesson — without being doom-laden

Return ONLY a JSON object with this exact field (no markdown, no extra text):
{
  "reading": "<3-5 sentences, ~150-250 chars. Open by naming '${cardName}'. Reference keyword and orientation>"
}`;
  }

  // 日本語
  return `あなたは詩的な語り口を持つ熟練のタロット占い師です。
本日のカード: 「${nameJP}」（${orientation}）
キーワード: ${keyword}
エレメント: ${elementLabel}${planetLabel ? `\n対応天体: ${planetLabel}` : ''}${moonLabel ? `\n月相: ${moonLabel}` : ''}${cleanName ? `\n相談者の名前: ${cleanName}（呼びかけは「${cleanName}さん」とすること。それ以外の名前を勝手に作らない）` : ''}

🔴 最重要ルール:
- カード名は「${nameJP}」です。別のカード名（「運命の輪」「太陽」等）に絶対に置き換えないでください。
- 「死神」「悪魔」「塔」等の象徴的な名前は、タロット占いにおいて成長や変容を意味する伝統的な名称です。柔らかい言葉に翻案せず、そのまま「${nameJP}」と記述してください。
- reading の冒頭文に必ず「${nameJP}」を記述してください。

正逆位置の意味を尊重して鑑定文を書いてください:
- 正位置: カードの肯定的・成長的な意味を引き出す
- 逆位置: 影・停滞・反転した教訓を語る — ただし破滅的な調子にはしない

以下のJSON形式のみで返答してください（マークダウンや余分な文言は不要）:
{
  "reading": "<3〜5文・約150〜250文字。冒頭で「${nameJP}」を明記し、キーワードと正逆位置を織り込む。実践的かつ神秘的に>"
}`;
}

// ── メインエントリ: POST /tarot ──
export async function handleTarot(body, env) {
  const {
    cardId,
    reversed = false,
    nameJP,
    nameEN,
    keyword,
    element,
    planet,
    moonPhase,
    userName,
    lang = 'ja',
  } = body;

  if (typeof cardId !== 'number' || cardId < 0 || cardId > 77) {
    throw new Error('Invalid cardId (must be 0-77)');
  }
  if (!nameJP || !keyword || !element) {
    throw new Error('Missing required fields: nameJP, keyword, element');
  }

  if (!env.GEMINI_API_KEY) {
    throw new Error('GEMINI_API_KEY not configured on worker');
  }

  // env vars から試行順のモデル配列を構築（未設定ならハードコード fallback）
  const primary = env.TAROT_MODEL_PRIMARY || 'gemini-2.5-flash';
  const fallback = env.TAROT_MODEL_FALLBACK || 'gemini-flash-latest';
  const models = primary === fallback ? [primary] : [primary, fallback];

  const prompt = buildPrompt({ cardId, reversed, nameJP, nameEN, keyword, element, planet, moonPhase, userName, lang });
  const raw = await callGemini(env.GEMINI_API_KEY, prompt, models);

  let parsed;
  try {
    parsed = JSON.parse(raw);
  } catch {
    const cleaned = raw.replace(/^```json\s*|\s*```$/g, '').trim();
    try { parsed = JSON.parse(cleaned); }
    catch {
      throw new Error(`Gemini returned non-JSON: ${raw.slice(0, 200)}`);
    }
  }

  return {
    cardId,
    reversed,
    reading: parsed.reading || '',
    lang,
  };
}
