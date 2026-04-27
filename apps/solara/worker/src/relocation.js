/**
 * Relocation Narrative — Gemini API を用いたリロケーション解説生成
 *
 * 入力: { shifts: [{planet, fromHouse, toHouse}],
 *         ascChange: {fromSign, toSign} | null,
 *         mcChange: {fromSign, toSign} | null,
 *         birthPlaceName, homeName, userName, lang }
 * 出力: { shifts: [{planet, narrative}],
 *         ascNarrative, mcNarrative, summary, lang }
 *
 * Phase B: 静的テンプレート (horo_relocation_templates.dart) を動的解説で上書き。
 * フォールバック: API失敗時は呼出側 (Dart) で null を受け、静的テンプレ表示。
 */

import { callGemini } from './fortune.js';

const PLANET_JP = {
  sun: '太陽', moon: '月', mercury: '水星', venus: '金星', mars: '火星',
  jupiter: '木星', saturn: '土星', uranus: '天王星', neptune: '海王星', pluto: '冥王星',
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

const SIGN_NAMES_JP = ['牡羊', '牡牛', '双子', '蟹', '獅子', '乙女', '天秤', '蠍', '射手', '山羊', '水瓶', '魚'];
const SIGN_NAMES_EN = ['Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo', 'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces'];

// ── プロンプト生成 ──
// 変化のある shift / angle のみ Gemini に投げる（トークン節約）。
// 変化なしのものは呼出側で静的テンプレートが残る（情報量は維持）。
function buildPrompt({ shifts, ascChange, mcChange, birthPlaceName, homeName, userName, lang }) {
  const changedShifts = (shifts || []).filter(s => s.fromHouse !== s.toHouse);
  const hasAscChange = ascChange && ascChange.fromSign !== ascChange.toSign;
  const hasMcChange = mcChange && mcChange.fromSign !== mcChange.toSign;

  if (changedShifts.length === 0 && !hasAscChange && !hasMcChange) {
    return null; // 変化なし → API呼ばずに空レスポンス返す
  }

  const HOUSE_MEANINGS = lang === 'en' ? HOUSE_MEANINGS_EN : HOUSE_MEANINGS_JP;
  const SIGN_NAMES = lang === 'en' ? SIGN_NAMES_EN : SIGN_NAMES_JP;
  const from = birthPlaceName || (lang === 'en' ? 'birthplace' : '出生地');
  const to = homeName || (lang === 'en' ? 'current home' : '現住所');

  const shiftLines = changedShifts.map(s => {
    const pName = lang === 'en' ? s.planet : (PLANET_JP[s.planet] || s.planet);
    const fromMeaning = HOUSE_MEANINGS[s.fromHouse] || '';
    const toMeaning = HOUSE_MEANINGS[s.toHouse] || '';
    return `- ${pName}: ${s.fromHouse}H(${fromMeaning}) → ${s.toHouse}H(${toMeaning})`;
  }).join('\n');

  let angleLines = '';
  if (hasAscChange) {
    const fromSign = SIGN_NAMES[ascChange.fromSign];
    const toSign = SIGN_NAMES[ascChange.toSign];
    angleLines += lang === 'en'
      ? `- ASC: ${fromSign} → ${toSign}\n`
      : `- ASC: ${fromSign}座 → ${toSign}座\n`;
  }
  if (hasMcChange) {
    const fromSign = SIGN_NAMES[mcChange.fromSign];
    const toSign = SIGN_NAMES[mcChange.toSign];
    angleLines += lang === 'en'
      ? `- MC: ${fromSign} → ${toSign}\n`
      : `- MC: ${fromSign}座 → ${toSign}座\n`;
  }

  // JSON schema 部分（changedShifts ごとに narrative フィールドを生成）
  const shiftSchemaJP = changedShifts.map(s =>
    `    {"planet": "${s.planet}", "narrative": "<${PLANET_JP[s.planet]}の領域が「${HOUSE_MEANINGS[s.fromHouse]}」から「${HOUSE_MEANINGS[s.toHouse]}」へどう変わるかを2〜3文。80〜150文字>"}`
  ).join(',\n');
  const shiftSchemaEN = changedShifts.map(s =>
    `    {"planet": "${s.planet}", "narrative": "<2-3 sentences explaining how ${s.planet}'s domain shifts from ${HOUSE_MEANINGS_EN[s.fromHouse]} to ${HOUSE_MEANINGS_EN[s.toHouse]}. ~80-150 chars>"}`
  ).join(',\n');

  if (lang === 'en') {
    return `You are an expert astrologer specializing in relocation charts. The user is comparing how moving from ${from} to ${to} changes their natal house positions.

${userName ? `User: ${userName}` : ''}
${angleLines ? `Angle changes:\n${angleLines}` : ''}
Planet house shifts (changed only):
${shiftLines || '(none)'}

Generate a personalized narrative for each shift, explaining what changes in life domain emphasis. Be poetic but concrete. Address the user warmly.

Return ONLY a JSON object with these fields (no markdown, no extra text):
{
  "shifts": [
${shiftSchemaEN}
  ],
${hasAscChange ? `  "ascNarrative": "<1-2 sentences on how the first impression changes from ${SIGN_NAMES_EN[ascChange.fromSign]} to ${SIGN_NAMES_EN[ascChange.toSign]}. ~60-120 chars>",\n` : ''}${hasMcChange ? `  "mcNarrative": "<1-2 sentences on how the career image changes from ${SIGN_NAMES_EN[mcChange.fromSign]} to ${SIGN_NAMES_EN[mcChange.toSign]}. ~60-120 chars>",\n` : ''}  "summary": "<1-2 sentence overall summary of what this relocation does. ~80-150 chars>"
}`;
  }

  // 日本語
  return `あなたはリロケーションチャートの専門家です。${from}から${to}へ移動することで、ネイタルチャートのハウス位置がどう変わるかを解説してください。

${userName ? `対象: ${userName}さん` : ''}
${angleLines ? `アングル変化:\n${angleLines}` : ''}
惑星のハウス変化（変化があるもののみ）:
${shiftLines || '(なし)'}

各変化について、人生のテーマがどう移ろうかをパーソナライズして解説してください。詩的かつ具体的に、対象者に語りかける口調で。

以下のJSON形式のみで返答（マークダウンや余分な文言は不要）:
{
  "shifts": [
${shiftSchemaJP}
  ],
${hasAscChange ? `  "ascNarrative": "<第一印象が「${SIGN_NAMES_JP[ascChange.fromSign]}座」から「${SIGN_NAMES_JP[ascChange.toSign]}座」へどう変わるかを1〜2文。60〜120文字>",\n` : ''}${hasMcChange ? `  "mcNarrative": "<キャリア像が「${SIGN_NAMES_JP[mcChange.fromSign]}座」から「${SIGN_NAMES_JP[mcChange.toSign]}座」へどう変わるかを1〜2文。60〜120文字>",\n` : ''}  "summary": "<このリロケーションがもたらす総合的な変化を1〜2文。80〜150文字>"
}`;
}

// ── メインエントリ: POST /relocation ──
export async function handleRelocation(body, env) {
  const {
    shifts = [],
    ascChange = null,
    mcChange = null,
    birthPlaceName,
    homeName,
    userName,
    lang = 'ja',
  } = body;

  if (!Array.isArray(shifts)) {
    throw new Error('shifts must be an array');
  }

  const prompt = buildPrompt({ shifts, ascChange, mcChange, birthPlaceName, homeName, userName, lang });

  if (prompt === null) {
    // 変化なし — API呼ばずに空レスポンス
    return {
      shifts: [],
      ascNarrative: '',
      mcNarrative: '',
      summary: '',
      lang,
    };
  }

  if (!env.GEMINI_API_KEY) {
    throw new Error('GEMINI_API_KEY not configured on worker');
  }

  // env vars から試行順のモデル配列を構築（fortune.js と共通設定）
  const primary = env.FORTUNE_MODEL_PRIMARY || 'gemini-2.5-flash';
  const fallback = env.FORTUNE_MODEL_FALLBACK || 'gemini-flash-latest';
  const models = primary === fallback ? [primary] : [primary, fallback];

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
    shifts: Array.isArray(parsed.shifts) ? parsed.shifts : [],
    ascNarrative: parsed.ascNarrative || '',
    mcNarrative: parsed.mcNarrative || '',
    summary: parsed.summary || '',
    lang,
  };
}
