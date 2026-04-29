/**
 * Astro*Carto*Graphy Line Narrative — Gemini API
 *
 * A*C*G ライン（natal / transit 2フレーム × 10惑星 × 4アングル）の
 * タップ詳細解説を Gemini で動的生成する。
 *
 * 入力:
 *   {
 *     frame: 'natal' | 'transit',  // 4フレームのうち β対応は2つ
 *     planet: 'venus' | ...,
 *     angle: 'ASC' | 'MC' | 'DSC' | 'IC',
 *     tappedLat, tappedLng, tappedPlaceName,
 *     natalSummary: {                 // 文脈ヒント（任意）
 *       ascSign: 0-11, mcSign: 0-11,
 *       sunSign: 0-11, moonSign: 0-11
 *     },
 *     transitDate: ISO8601,           // frame='transit' のとき
 *     userName, lang: 'ja' | 'en'
 *   }
 * 出力:
 *   {
 *     title, narrative, softNote, hardNote, lang
 *   }
 *
 * 設計思想: project_solara_design_philosophy.md
 *   - Soft/Hard は独立2エネルギー、吉凶判定禁止
 *   - 「ラッキー」「アンラッキー」「良い/悪い」禁止
 *   - 「在る・効く・動く」で表現
 *
 * フォールバック: クライアント側で API 失敗時は静的辞書 (astro_glossary)
 */

import { callGemini } from './fortune.js';

const PLANET_JP = {
  sun: '太陽', moon: '月', mercury: '水星', venus: '金星', mars: '火星',
  jupiter: '木星', saturn: '土星', uranus: '天王星', neptune: '海王星', pluto: '冥王星',
};

const PLANET_THEME_JP = {
  sun: '自己・意志・生命力',
  moon: '感情・無意識・安らぎ',
  mercury: '思考・言葉・知性',
  venus: '愛・調和・価値・美',
  mars: '行動・情熱・突破',
  jupiter: '拡大・寛容・哲学',
  saturn: '制限・責任・構造',
  uranus: '変革・独立・覚醒',
  neptune: '理想・霊性・統合',
  pluto: '変容・深層・再生',
};

const PLANET_THEME_EN = {
  sun: 'self / will / vitality',
  moon: 'emotion / unconscious / comfort',
  mercury: 'thought / language / intellect',
  venus: 'love / harmony / value / beauty',
  mars: 'action / passion / breakthrough',
  jupiter: 'expansion / tolerance / philosophy',
  saturn: 'limitation / responsibility / structure',
  uranus: 'change / independence / awakening',
  neptune: 'ideal / spirit / dissolution',
  pluto: 'transformation / depth / rebirth',
};

const ANGLE_MEANING_JP = {
  ASC: '自己の表出・第一印象・身体的な現れ方',
  MC: '社会的役割・公的な顔・キャリアの方向',
  DSC: '対人関係・パートナー・「自分にとっての他者」',
  IC: '家庭・ルーツ・心の拠り所・内的基盤',
};

const ANGLE_MEANING_EN = {
  ASC: 'self-expression / first impression / how one shows up',
  MC: 'social role / public face / career direction',
  DSC: 'relationships / partner / "the other for the self"',
  IC: 'home / roots / inner foundation / heart anchor',
};

const FRAME_MEANING_JP = {
  natal: '出生時に固定された「本質の地図」。一生変わらない、その人にとっての普遍的な配置。',
  transit: '今この瞬間の天体位置で引かれる「今の流れ」。地球の自転で時々刻々と動く。',
};

const FRAME_MEANING_EN = {
  natal: 'The "essence map" fixed at birth. Universal placement that does not change in a lifetime.',
  transit: 'The "current flow" drawn from now\'s planetary positions. Shifts moment by moment with Earth\'s rotation.',
};

const SIGN_NAMES_JP = ['牡羊', '牡牛', '双子', '蟹', '獅子', '乙女', '天秤', '蠍', '射手', '山羊', '水瓶', '魚'];
const SIGN_NAMES_EN = ['Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo', 'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces'];

function buildPrompt({
  frame, planet, angle,
  tappedLat, tappedLng, tappedPlaceName,
  natalSummary, transitDate, userName, lang,
}) {
  const isJa = lang !== 'en';
  const PLANET_NAMES = isJa ? PLANET_JP : { sun: 'Sun', moon: 'Moon', mercury: 'Mercury', venus: 'Venus', mars: 'Mars', jupiter: 'Jupiter', saturn: 'Saturn', uranus: 'Uranus', neptune: 'Neptune', pluto: 'Pluto' };
  const PLANET_THEMES = isJa ? PLANET_THEME_JP : PLANET_THEME_EN;
  const ANGLE_MEANINGS = isJa ? ANGLE_MEANING_JP : ANGLE_MEANING_EN;
  const FRAME_MEANINGS = isJa ? FRAME_MEANING_JP : FRAME_MEANING_EN;
  const SIGN_NAMES = isJa ? SIGN_NAMES_JP : SIGN_NAMES_EN;

  const planetName = PLANET_NAMES[planet] || planet;
  const planetTheme = PLANET_THEMES[planet] || '';
  const angleUpper = (angle || '').toUpperCase();
  const angleMeaning = ANGLE_MEANINGS[angleUpper] || '';
  const frameMeaning = FRAME_MEANINGS[frame] || '';
  const placeStr = tappedPlaceName || (isJa ? `緯度${tappedLat.toFixed(1)}° 経度${tappedLng.toFixed(1)}°` : `lat ${tappedLat.toFixed(1)}° lng ${tappedLng.toFixed(1)}°`);

  // 文脈ヒント（あれば織り込む）
  const ns = natalSummary || {};
  const ctxLines = [];
  if (typeof ns.ascSign === 'number') {
    ctxLines.push(isJa
      ? `出生ASC: ${SIGN_NAMES[ns.ascSign]}座`
      : `Natal ASC: ${SIGN_NAMES[ns.ascSign]}`);
  }
  if (typeof ns.mcSign === 'number') {
    ctxLines.push(isJa
      ? `出生MC: ${SIGN_NAMES[ns.mcSign]}座`
      : `Natal MC: ${SIGN_NAMES[ns.mcSign]}`);
  }
  if (typeof ns.sunSign === 'number') {
    ctxLines.push(isJa
      ? `出生太陽: ${SIGN_NAMES[ns.sunSign]}座`
      : `Natal Sun: ${SIGN_NAMES[ns.sunSign]}`);
  }
  if (typeof ns.moonSign === 'number') {
    ctxLines.push(isJa
      ? `出生月: ${SIGN_NAMES[ns.moonSign]}座`
      : `Natal Moon: ${SIGN_NAMES[ns.moonSign]}`);
  }
  const ctxBlock = ctxLines.length ? ctxLines.join('\n') : '';

  if (!isJa) {
    // 英語プロンプト
    return `You are an expert astrologer specializing in Astro*Carto*Graphy (Jim Lewis school).
The user tapped on a ${planet} ${angleUpper} line at ${placeStr}.

Frame: ${frame} — ${frameMeaning}
Planet: ${planetName} — themes: ${planetTheme}
Angle: ${angleUpper} — meaning: ${angleMeaning}
${transitDate ? `Transit moment: ${transitDate}` : ''}
${ctxBlock ? `\nNatal context:\n${ctxBlock}` : ''}
${userName ? `User name: ${userName}` : ''}

🔴 CRITICAL DESIGN RULES (Solara philosophy):
1. NEVER use words like "lucky", "unlucky", "good", "bad", "blessed", "cursed".
2. Soft and Hard are TWO INDEPENDENT energies, not one axis. They can both be present, both absent, or only one.
   - Soft = flow / receptivity / expansion / harmony / opening
   - Hard = friction / change / confrontation / depth / re-examination
3. State energies as facts. Do NOT prescribe how the user should feel or act.
4. Speak of "what is present", "what activates", "what resonates" — not "what one should do".
5. Both Soft and Hard are beautiful. Neither is preferable.

Generate a personalized narrative for this ${planet} ${angleUpper} line at ${placeStr}.
Address the user warmly and concretely. Be poetic but grounded.

Return ONLY a JSON object (no markdown, no extra text):
{
  "title": "<Short title, e.g. '${planetName} ${angleUpper} Line at ${placeStr.split(',')[0]}'>",
  "narrative": "<Main reading. 200-350 chars. How does this planet's theme manifest through ${angleUpper} at this place? Concrete, embodied imagery. ${frame === 'transit' ? 'Mention the temporal nature.' : 'Mention the lifelong nature.'}>",
  "softNote": "<80-150 chars. What soft energy (flow, receptivity, expansion, harmony) presents itself here>",
  "hardNote": "<80-150 chars. What hard energy (friction, depth, re-examination, change) presents itself here>"
}`;
  }

  // 日本語プロンプト
  return `あなたはアストロカートグラフィ (Jim Lewis 流) の専門家です。
ユーザーが ${placeStr} の ${planetName} ${angleUpper} ラインをタップしました。

フレーム: ${frame} — ${frameMeaning}
惑星: ${planetName} (${planet}) — テーマ: ${planetTheme}
アングル: ${angleUpper} — 意味: ${angleMeaning}
${transitDate ? `トランジット時刻: ${transitDate}` : ''}
${ctxBlock ? `\n出生チャート文脈:\n${ctxBlock}` : ''}
${userName ? `対象者: ${userName}さん` : ''}

🔴 重要・Solara設計思想（絶対遵守）:
1. 「ラッキー」「アンラッキー」「良い」「悪い」「吉」「凶」「恵まれた」「呪われた」を絶対に使わない。
2. ソフトとハードは独立した2つのエネルギー。両方が同時に強いことも、両方とも弱いことも、片方だけのこともある。
   - ソフト = 流れ・受容・拡大・調和・開かれ
   - ハード = 摩擦・変容・対峙・深化・見直し
3. エネルギーを「事実として」伝える。「こうすべき」「こうすると良い」と指示しない。
4. 「在る」「効く」「響く」「動く」を使う。「〜が良い」「〜してください」を避ける。
5. ソフトとハードはどちらも美しい。優劣はない。

${placeStr} における ${planetName} ${angleUpper} ラインのパーソナライズされた解説を生成してください。
対象者に語りかける温かい口調で、具体的・身体的なイメージを使い、詩的でありながら地に足のついた表現で。

以下のJSON形式のみで返答（マークダウンや余分な文言は不要）:
{
  "title": "<短いタイトル。例: '${placeStr.split(',')[0]}の${planetName}${angleUpper}ライン'>",
  "narrative": "<本文。200〜350文字。この惑星のテーマが${angleUpper}を通してこの土地でどう現れるか。具体的・身体的な情景。${frame === 'transit' ? '今この瞬間の時間性に触れる。' : '一生変わらない普遍性に触れる。'}>",
  "softNote": "<80〜150文字。ここに在るソフトエネルギー（流れ・受容・拡大・調和）の現れ方>",
  "hardNote": "<80〜150文字。ここに在るハードエネルギー（摩擦・深化・見直し・変容）の現れ方>"
}`;
}

// ── メインエントリ: POST /astro/line-narrative ──
export async function handleLineNarrative(body, env) {
  const {
    frame = 'natal',
    planet,
    angle,
    tappedLat,
    tappedLng,
    tappedPlaceName,
    natalSummary = null,
    transitDate = null,
    userName,
    lang = 'ja',
  } = body;

  // 入力検証
  if (!planet || !PLANET_JP[planet]) {
    throw new Error(`Invalid planet: ${planet}`);
  }
  const angleUpper = String(angle || '').toUpperCase();
  if (!['ASC', 'MC', 'DSC', 'IC'].includes(angleUpper)) {
    throw new Error(`Invalid angle: ${angle}`);
  }
  if (!['natal', 'transit'].includes(frame)) {
    throw new Error(`Invalid frame: ${frame} (β対応は natal/transit のみ)`);
  }
  if (typeof tappedLat !== 'number' || typeof tappedLng !== 'number') {
    throw new Error('tappedLat/tappedLng must be numbers');
  }

  if (!env.GEMINI_API_KEY) {
    throw new Error('GEMINI_API_KEY not configured on worker');
  }

  const primary = env.FORTUNE_MODEL_PRIMARY || 'gemini-2.5-flash';
  const fallback = env.FORTUNE_MODEL_FALLBACK || 'gemini-flash-latest';
  const models = primary === fallback ? [primary] : [primary, fallback];

  const prompt = buildPrompt({
    frame, planet, angle: angleUpper,
    tappedLat, tappedLng, tappedPlaceName,
    natalSummary, transitDate, userName, lang,
  });

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
    title: parsed.title || '',
    narrative: parsed.narrative || '',
    softNote: parsed.softNote || '',
    hardNote: parsed.hardNote || '',
    lang,
  };
}
