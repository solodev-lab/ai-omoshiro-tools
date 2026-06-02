/**
 * Relocation Narrative — Stella のリロケーション解説生成 (Gemini API バックエンド)
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

// ── A案 (アングル近接) 用 ──
const ANGLE_JP = {
  asc: 'ASC（自己・第一印象）', mc: 'MC（社会的立場・キャリア）',
  dsc: 'DSC（対人・パートナーシップ）', ic: 'IC（家庭・心の拠り所）',
};
const ANGLE_EN = {
  asc: 'ASC (self/first impression)', mc: 'MC (career/public status)',
  dsc: 'DSC (partnership)', ic: 'IC (home/roots)',
};

// 度数差 → 度合い語。Dart 側 (horo_relocation_angles.dart) と閾値を一致させる。
function magnitudeWordJP(absDeg) {
  if (absDeg < 0.5) return 'ごくわずかに';
  if (absDeg < 2) return 'わずかに';
  if (absDeg < 6) return 'はっきりと';
  return '大きく';
}
function magnitudeWordEN(absDeg) {
  if (absDeg < 0.5) return 'very slightly';
  if (absDeg < 2) return 'slightly';
  if (absDeg < 6) return 'noticeably';
  return 'greatly';
}

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

// ── A案プロンプト生成 (アングル近接) ──
// planets: [{planet, natalHouse?, reloHouse?, nearestAngle, deltaDeg, direction}]
// angles:  [{angle, fromSign, toSign}]  (星座が変わった軸のみ)
// 何も無ければ null (呼出側は空レスポンス)。
function buildAnglePrompt({ planets, angles, birthPlaceName, homeName, userName, lang }) {
  const list = Array.isArray(planets) ? planets : [];
  const angleList = Array.isArray(angles) ? angles : [];
  if (list.length === 0 && angleList.length === 0) return null;

  const HOUSE = lang === 'en' ? HOUSE_MEANINGS_EN : HOUSE_MEANINGS_JP;
  const ANGLE = lang === 'en' ? ANGLE_EN : ANGLE_JP;
  const SIGN = lang === 'en' ? SIGN_NAMES_EN : SIGN_NAMES_JP;
  const magWord = lang === 'en' ? magnitudeWordEN : magnitudeWordJP;
  const from = birthPlaceName || (lang === 'en' ? 'birthplace' : '出生地');
  const to = homeName || (lang === 'en' ? 'current home' : '現住所');

  const planetFacts = list.map(p => {
    const pName = lang === 'en' ? p.planet : (PLANET_JP[p.planet] || p.planet);
    const ang = ANGLE[p.nearestAngle] || p.nearestAngle;
    const mag = magWord(Math.abs(p.deltaDeg || 0));
    const houseChanged = p.natalHouse && p.reloHouse && p.natalHouse !== p.reloHouse;
    if (houseChanged) {
      const fromH = HOUSE[p.natalHouse] || `${p.natalHouse}H`;
      const toH = HOUSE[p.reloHouse] || `${p.reloHouse}H`;
      return lang === 'en'
        ? `- ${pName}: HOUSE MOVE ${p.natalHouse}H(${fromH}) -> ${p.reloHouse}H(${toH}); nearest angle ${ang}`
        : `- ${pName}: ハウス移動 ${p.natalHouse}H(${fromH}) → ${p.reloHouse}H(${toH})、最寄り軸 ${ang}`;
    }
    if (p.direction === 'closer') {
      return lang === 'en'
        ? `- ${pName}: moves ${mag} CLOSER to ${ang}`
        : `- ${pName}: ${ang}に${mag}近づく`;
    }
    if (p.direction === 'farther') {
      return lang === 'en'
        ? `- ${pName}: moves ${mag} FARTHER from ${ang}`
        : `- ${pName}: ${ang}から${mag}遠ざかる`;
    }
    return lang === 'en'
      ? `- ${pName}: stays about the same near ${ang}`
      : `- ${pName}: ${ang}との距離はほぼ保たれる`;
  }).join('\n');

  const angleFacts = angleList.map(a => {
    const ang = ANGLE[a.angle] || a.angle;
    return lang === 'en'
      ? `- ${ang}: ${SIGN[a.fromSign]} -> ${SIGN[a.toSign]}`
      : `- ${ang}: ${SIGN[a.fromSign]}座 → ${SIGN[a.toSign]}座`;
  }).join('\n');

  const planetSchema = list.map(p =>
    lang === 'en'
      ? `    {"planet": "${p.planet}", "narrative": "<1-2 sentences, ~50-110 chars>"}`
      : `    {"planet": "${p.planet}", "narrative": "<1〜2文・50〜110文字>"}`
  ).join(',\n');
  const angleSchema = angleList.map(a =>
    lang === 'en'
      ? `    {"angle": "${a.angle}", "narrative": "<1-2 sentences, ~50-110 chars>"}`
      : `    {"angle": "${a.angle}", "narrative": "<1〜2文・50〜110文字>"}`
  ).join(',\n');

  if (lang === 'en') {
    return `You are an expert in relocation astrology / astrocartography. The user compares moving from ${from} to ${to}. A planet near an angle (ASC/MC/DSC/IC) expresses that life area more strongly in that place.
${userName ? `User: ${userName}` : ''}

Planet vs nearest-angle changes:
${planetFacts || '(none)'}
${angleFacts ? `\nAngle sign changes:\n${angleFacts}` : ''}

For each planet, write how its theme shifts in the new place based on its angle proximity. Concrete, warm, and NEUTRAL: never say good/bad/lucky/unlucky; use "strengthens / softens / comes forward / settles". For very small changes, be honest and understated. Address the user warmly without a mechanical greeting.

Return ONLY a JSON object (no markdown, no extra text):
{
  "planets": [
${planetSchema}
  ],${angleList.length ? `\n  "angles": [\n${angleSchema}\n  ],` : ''}
  "summary": "<overall 1-2 sentence summary, ~70-130 chars>"
}`;
  }

  return `あなたはリロケーション占星術 / アストロカートグラフィの専門家です。${from}から${to}への移動を比較します。惑星はアングル(ASC/MC/DSC/IC)に近いほど、その人生領域がその土地で強く働きます。
${userName ? `対象: ${userName}さん` : ''}

各惑星と最寄りアングルの変化:
${planetFacts || '(なし)'}
${angleFacts ? `\nアングルの星座変化:\n${angleFacts}` : ''}

各惑星について、アングルへの近さの変化から、その星のテーマがこの土地でどう変わるかを書いてください。具体的かつ温かく、ただし中立に。吉凶・幸運/不運の語は禁止。「強まる／やわらぐ／前に出る／落ち着く」で表現。ごく小さな変化は誇張せず正直に控えめに。冒頭の機械的な呼びかけは避け、自然に語りかける口調で。

以下のJSON形式のみで返答 (マークダウンや余分な文言は不要):
{
  "planets": [
${planetSchema}
  ],${angleList.length ? `\n  "angles": [\n${angleSchema}\n  ],` : ''}
  "summary": "<総合サマリーを1〜2文・70〜130文字>"
}`;
}

// ── A案メインエントリ: アングル近接の動的解説 (全員無料) ──
async function handleRelocationAngle(body, env) {
  const {
    planets = [],
    angles = [],
    birthPlaceName,
    homeName,
    userName,
    lang = 'ja',
  } = body;

  if (!Array.isArray(planets)) {
    throw new Error('planets must be an array');
  }

  const prompt = buildAnglePrompt({ planets, angles, birthPlaceName, homeName, userName, lang });
  if (prompt === null) {
    return { planets: [], angles: [], summary: '', lang };
  }

  if (!env.GEMINI_API_KEY) {
    throw new Error('GEMINI_API_KEY not configured on worker');
  }

  const primary = env.FORTUNE_MODEL_PRIMARY || 'gemini-2.5-flash';
  const fallback = env.FORTUNE_MODEL_FALLBACK || 'gemini-flash-latest';
  const models = primary === fallback ? [primary] : [primary, fallback];

  // ナレーション生成のみ → thinking OFF (§0.2.51)。10天体ぶんで長めなので出力上限を拡張
  // (上限であって課金額ではない。実出力分のみ課金)。
  const raw = await callGemini(env.GEMINI_API_KEY, prompt, models, {
    thinkingBudget: 0,
    maxOutputTokens: 4096,
  });

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
    planets: Array.isArray(parsed.planets) ? parsed.planets : [],
    angles: Array.isArray(parsed.angles) ? parsed.angles : [],
    summary: parsed.summary || '',
    lang,
  };
}

// ── メインエントリ: POST /relocation ──
export async function handleRelocation(body, env) {
  // A案 (アングル近接・新アプリ): model:'angle' か planets[] が来たら新分岐。
  // 旧B/旧A (shifts[]) は後方互換でそのまま下に残す。
  if (body && (body.model === 'angle' || Array.isArray(body.planets))) {
    return handleRelocationAngle(body, env);
  }
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

// テスト用内部エクスポート (A案アングル近接)。
export const _internal = {
  buildAnglePrompt,
  magnitudeWordJP,
  magnitudeWordEN,
};
