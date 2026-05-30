/**
 * Fortune Reading — Stella の占い文生成 (Gemini API バックエンド)
 *
 * 入力: category, natal, planetHouses?, aspects(N-N), transitAspects(N-T),
 *        progressedAspects(N-P), patterns, date, userName?, lang('ja'|'en')
 * 出力: { reading, advice }
 *
 * 3層構造 (トランジット主役): natal=土台(ハウス/生来の相), N-T=今日の主役,
 *        N-P=今の人生の章(背景)。クロス相は {natal, moving, type, quality}。
 *
 * GEMINI_API_KEY は wrangler secret put GEMINI_API_KEY で設定
 * モデル: gemini-2.5-flash (テキスト生成、低コスト)
 */

import { STYLE_VOICE_JP } from './style_voice.js';

// ── Fortune カテゴリ定義 ──
// houses: そのカテゴリで重視する伝統占星術のハウス番号
//   1H=自己, 2H=所有/才能/収入, 3H=対話/兄弟/短距離, 4H=家庭/基盤,
//   5H=恋愛/楽しみ/創造, 6H=日常業務/健康, 7H=パートナー/結婚, 8H=共有資産/変容,
//   9H=哲学/遠距離/学問, 10H=社会的地位/キャリア, 11H=友人/ネットワーク, 12H=潜在意識/隠れた事
const FORTUNE_CATEGORIES = {
  overall: { jp: '全体運', en: 'Overall', planets: ['sun', 'moon', 'jupiter'], houses: [1] },
  love: { jp: '恋愛運', en: 'Love', planets: ['venus', 'mars', 'moon'], houses: [5, 7] },
  money: { jp: '豊かさ', en: 'Abundance', planets: ['venus', 'jupiter', 'saturn'], houses: [2, 8] },
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
// export: relocation.js / consultation.js など他モジュールから再利用するため。
//
// opts:
//   retries          : per-model リトライ回数 (default 2)
//   thinkingBudget   : 設定時 generationConfig.thinkingConfig.thinkingBudget で深い思考。
//                      Gemini 2.5 Flash / Pro thinking モード用 (1024 等)。null=無効。
//   maxOutputTokens  : 出力上限 (default 2048)。深い読み物は 4096 等に拡張可。
//   temperature      : 生成温度 (default 0.9)
export async function callGemini(apiKey, prompt, models, opts = {}) {
  const {
    retries = 2,
    thinkingBudget = null,
    maxOutputTokens = 2048,
    temperature = 0.9,
  } = opts;
  let lastErr;
  for (const model of models) {
    for (let attempt = 0; attempt <= retries; attempt++) {
      try {
        const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;
        const generationConfig = {
          temperature,
          topP: 0.95,
          maxOutputTokens,
          responseMimeType: 'application/json',
        };
        if (thinkingBudget != null) {
          generationConfig.thinkingConfig = { thinkingBudget };
        }
        const res = await fetch(url, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            contents: [{ parts: [{ text: prompt }] }],
            generationConfig,
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
// userName はオーナー決定 (2026-05-27) で星読みには一切使わない。受け取るが prompt に
// 渡さない (API surface 維持・Tarot 等他経路は別途)。
function buildPrompt({ category, lang, natal, planetHouses, aspects, transitAspects, progressedAspects, patterns, date, userName: _userName }) {
  const cat = FORTUNE_CATEGORIES[category] || FORTUNE_CATEGORIES.overall;
  const catName = lang === 'en' ? cat.en : cat.jp;
  const dateStr = date || new Date().toISOString().slice(0, 10);

  // 関連アスペクト抽出 (関連惑星を含むもののみ)
  const relevantPlanets = new Set(cat.planets);

  // 土台: 出生図 N-N アスペクト (生来の傾向)
  const relevantAspects = (aspects || []).filter(a =>
    relevantPlanets.has(a.p1) || relevantPlanets.has(a.p2)
  ).slice(0, 6); // トークン節約

  const aspectLines = relevantAspects.map(a => {
    const p1 = lang === 'en' ? a.p1 : (PLANET_JP[a.p1] || a.p1);
    const p2 = lang === 'en' ? a.p2 : (PLANET_JP[a.p2] || a.p2);
    const type = lang === 'en' ? a.type : (ASPECT_JP[a.type] || a.type);
    return `- ${p1} × ${p2}: ${type} (${a.quality})`;
  }).join('\n');

  // 主役/背景: クロスアスペクト整形 (N-T = 今日のトランジット / N-P = プログレス)。
  // 要素は {natal, moving, type, quality}。natal か moving が関連天体なら採用。
  const crossLines = (list, labelEn, labelJp) =>
    (list || [])
      .filter(a => relevantPlanets.has(a.natal) || relevantPlanets.has(a.moving))
      .slice(0, 6)
      .map(a => {
        const n = lang === 'en' ? a.natal : (PLANET_JP[a.natal] || a.natal);
        const m = lang === 'en' ? a.moving : (PLANET_JP[a.moving] || a.moving);
        const type = lang === 'en' ? a.type : (ASPECT_JP[a.type] || a.type);
        return lang === 'en'
          ? `- ${labelEn} ${m} ${type} natal ${n} (${a.quality})`
          : `- ${labelJp}${m} → 出生${n}: ${type} (${a.quality})`;
      })
      .join('\n');
  const transitLines = crossLines(transitAspects, 'transiting', 'トランジット');
  const progressedLines = crossLines(progressedAspects, 'progressed', 'プログレス');

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
    return `You are an expert astrologer. Read today's (${dateStr}) ${catName} for this person, using their birth chart as the foundation and TODAY'S TRANSITS as the main driver.

【Foundation — natal chart (who they are)】
Focus planets: ${cat.planets.join(', ')}
${categoryHousesHint ? `Houses traditionally read for ${catName}: ${categoryHousesHint}` : ''}
${hasHouses ? `Natal house positions of focus planets:\n${houseLines || '(none mapped)'}` : '(House positions unavailable — birth time unknown)'}
${aspectLines ? `Natal aspects (innate tendencies):\n${aspectLines}` : ''}

【Main driver — today's transits (the sky activating their natal chart)】
${transitLines || '(no notable transits to the focus planets today)'}

【Background — progressions (their current life chapter)】
${progressedLines || '(no notable progressions)'}

Active special patterns:
${patternLines.join('\n') || '(none)'}

🔴 Structure rules (in this order of importance):
- The CORE of the writing is the concrete description of how today's transits activate the natal planets.
  Example: "Mercury opposes natal Mars — sparks fly in words." Always put today's movement concretely into the body.
- 🔴 Naming rule (important): In the prose, do NOT prefix transiting planets with "transit/transiting" — use the bare planet name (e.g., "the Moon", "Mars"). Since today's sky is the default subject, an unlabeled planet name means the transit. Never put the literal word "transit"/"transiting" in the body. DO label natal planets ("natal Moon") and progressed planets ("progressed Venus") to distinguish them from transits.
- House references are OPTIONAL and limited to AT MOST ONCE in the body. Phrasings like "(planet) activates the (N)th house" are fine — keep it light.
  Do not repeat house numbers (5H, 7H, etc.) or life-area names (romance/home/career/marriage) more than once.
- Innate natal aspects are background context — at most one mention, one sentence.
- Add progressions lightly as the slow current life-chapter / inner season — at most one sentence.
- For any layer marked "(no notable ...)" or "(none)", do not force it or invent data.
- If house positions are unavailable, do not mention houses at all.
- Do NOT use any name or nickname in the writing, neither in the opening nor in the body. Begin with the movement of the stars or the day's feeling, and refer to the reader only via second person ("you") or implicit subject.
- 🔴 Safety guard: Do NOT give definitive medical, legal, financial, investment, or self-harm advice. If today's themes touch these areas (health, money, contracts, crisis), stay with gentle astrological imagery only and suggest consulting an appropriate professional. Never claim certainty about future events — use "may", "could", "this energy suggests" rather than "will" or "definitely".

Return ONLY a JSON object with exactly these fields (no markdown, no extra text):
{
  "reading": "<3-5 sentence poetic reading focused on ${catName}, led by today's transits. ~200-300 chars>",
  "advice": "<1-2 sentence practical advice. ~130-180 chars>"
}`;
  }

  // 日本語
  return `あなたは経験豊かな占星術師です。今日 (${dateStr}) の${catName}を、出生図を土台に、今日のトランジットを主役として読み解いてください。

【土台 — 出生図(あなたの性質)】
主要天体: ${cat.planets.map(p => PLANET_JP[p]).join('、')}
${categoryHousesHint ? `${catName}で重視するハウス: ${categoryHousesHint}` : ''}
${hasHouses ? `主要天体の出生ハウス位置:\n${houseLines || '(なし)'}` : '(ハウス位置は不明 — 出生時刻が登録されていません)'}
${aspectLines ? `出生図のアスペクト(生来の傾向):\n${aspectLines}` : ''}

【主役 — 今日のトランジット(今日の空が出生天体を刺激)】
${transitLines || '(今日、主要天体に目立つトランジットはなし)'}

【背景 — プログレス(今の人生の章)】
${progressedLines || '(目立つ進行はなし)'}

成立中の特殊パターン:
${patternLines.join('\n') || '(なし)'}

🔴 構成ルール (この順で重要):
- 文章の中心は「今日のトランジット相が出生天体をどう刺激しているか」の動きの描写。
  例: 「水星が出生火星にオポジション → 言葉に火花が散る」のように、今日の動きを具体的に必ず本文に出してください。
- 🔴 呼称ルール (重要): 本文では、トランジット惑星に「トランジットの」を付けず惑星名のみで書いてください (例:「トランジットの月」→「月」、「トランジットの火星」→「火星」)。今日の空が主役なので、無印の惑星名は既定でトランジットを指します。「トランジット」「Transit」という語そのものを本文に出さないでください。一方、出生(ネイタル)惑星は「出生の月」、プログレス惑星は「プログレスの(進行の)金星」のように明示して、トランジットと区別してください。
- アスペクト(角度の相)を噛み砕いて言うときは、技術名と角度を括弧で添えてください。
  例:「120度の心地よい角度(トライン120°)」「90度の緊張(スクエア90°)」「向き合う180度(オポジション180°)」「60度の追い風(セクスタイル60°)」「重なる0度(コンジャンクション0°)」。
- ハウスへの言及は任意・本文中で最大 1 回まで。「(惑星) が (N) ハウスを刺激する」程度に控えめに。
  ハウス番号 (5H, 7H 等) や領域名 (恋愛/家庭/職場/結婚) を 2 回以上連発しないでください。
- 出生図のアスペクト(生来の傾向)は「前提」として最大 1 回・1 文以内で。
- プログレスは今のゆっくりした人生の章・内的な季節として、多くても 1 文だけそっと添えてください。
- 「なし」と書かれた層は無理に触れず、捏造しないでください。
- ハウス位置が「不明」の場合は、ハウスについて言及しないでください。
- 名前・ニックネーム・敬称 (「〇〇さん」等) は冒頭も本文中も一切使わないでください。読者の呼び方は「あなた」または主語省略のみ。星の動きやその日の雰囲気から書き始めてください。
- 🔴 安全性ガイド: 医療・法律・金融・投資・自傷に関わる断定的なアドバイスをしないでください。今日のテーマがこれらの領域 (健康・お金・契約・危機) に触れる場合は、占星術的なイメージに留め、必要なら専門家への相談をやんわり勧めてください。未来の出来事を断定せず、「〜かもしれない」「〜の気配」「このエネルギーは〜を示唆する」等の表現を使い、「必ず」「絶対」は使わないでください。
${STYLE_VOICE_JP}

以下のJSON形式のみで返答してください (マークダウンや余分な文言は不要):
{
  "reading": "<${catName}にフォーカスし、今日のトランジットを主役にした詩的な鑑定 (3〜5 文)。200〜300 文字程度>",
  "advice": "<実践的なアドバイス (1〜2 文)。130〜180 文字程度>"
}`;
}

/**
 * 鑑定文から「トランジット/Transit」という語を除去する保険 (プロンプト指示すり抜け対策)。
 * Horo の星読みはトランジット惑星が主役なので、無印の惑星名 (例「月」) で書かせる方針。
 * 「トランジットの月」→「月」のように接頭辞だけ外す。出生(Natal)/プログレスのラベルは残す。
 */
export function stripTransitLabel(text, lang) {
  if (!text) return text;
  let t = text;
  if (lang === 'en') {
    t = t
      .replace(/\btransiting\s+/gi, '')
      .replace(/\btransit(?:s|ing)?\b/gi, '');
  } else {
    t = t.replace(/トランジットの/g, '').replace(/トランジット/g, '');
  }
  // 除去後の二重スペース / 句読点前スペースを軽く整える。
  return t.replace(/[ \t]{2,}/g, ' ').replace(/\s+([、。,.])/g, '$1').trim();
}

// ── DO 呼出ラッパー (deps で差し替え可能、デフォルトは env.ATTESTATION_DO 経由) ──
async function _defaultCallDo(env, path, payload) {
  const stub = env.ATTESTATION_DO.get(env.ATTESTATION_DO.idFromName('global'));
  const res = await stub.fetch(`https://do${path}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });
  const json = await res.json().catch(() => ({}));
  return { status: res.status, body: json };
}

// ── メインエントリ: POST /fortune ──
//
// 1 日 1 回固定キャッシュ ((appUserId, local_date, category, lang) で一意)。
// プロフィール変更や端末 kill 再起動で再生成されない = 「変更しない事にする」設計。
// 日付境界は端末の local TZ (body.date = 'YYYY-MM-DD'、Asia/Tokyo の 0 時で切替)。
// cache miss 時のみ Gemini を叩いて DO に保存。
//
// appUserId が無い (= 未認証の極端ケース) ときは cache をスキップして
// Gemini 直叩き (機能は壊れない、ただし「1日1回固定」は効かない)。
export async function handleFortune(body, env, deps = {}) {
  const callDoFn = deps.callDo || _defaultCallDo;
  const {
    category = 'overall',
    lang = 'ja',
    natal = {},
    planetHouses = null,
    aspects = [],
    transitAspects = [],
    progressedAspects = [],
    patterns = {},
    date,
    userName,
    // Phase A1 (2026-05-17): Pro ユーザーには thinking モード ON で深い読み。
    // Free は thinking OFF。Worker 側で本物の判定はせず、クライアントが
    // ProStatus から isPro を渡してくる (Phase 2-6b で Sign in + サーバ側
    // Pro 検証を追加して二重防御に格上げ予定)。
    thinking = false,
    __appUserId: appUserId = null, // middleware が注入する予約フィールド
  } = body;

  if (!FORTUNE_CATEGORIES[category]) {
    throw new Error(`Unknown category: ${category}`);
  }

  // 1. スコア計算 (LLM不要、確定的)
  const score = computeCategoryScore(category, aspects);

  // 2. キャッシュチェック (1日1回固定)
  // date が YYYY-MM-DD 形式で渡されているか緩く確認 (誤形式は cache スキップ)。
  const validDate = typeof date === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(date);
  const cacheEligible = typeof appUserId === 'string' && appUserId.length > 0 && validDate;
  if (cacheEligible) {
    const got = await callDoFn(env, '/fortune-reading-get', {
      appUserId, localDate: date, category, lang,
    });
    if (got.status === 200 && got.body && got.body.found) {
      // 当日既に生成済 → 同じ結果を返す (Gemini 呼ばない)。
      // 旧キャッシュ (トランジット接頭辞付き) も返却時にサニタイズして即反映する。
      return {
        category,
        score: got.body.score,
        reading: stripTransitLabel(got.body.reading, lang),
        advice: stripTransitLabel(got.body.advice, lang),
        lang,
        cached: true,
      };
    }
  }

  // 3. Gemini でテキスト生成 (cache miss / cache 不適格時)
  if (!env.GEMINI_API_KEY) {
    throw new Error('GEMINI_API_KEY not configured on worker');
  }
  // env vars から試行順のモデル配列を構築（未設定ならハードコード fallback）
  const primary = env.FORTUNE_MODEL_PRIMARY || 'gemini-2.5-flash';
  const fallback = env.FORTUNE_MODEL_FALLBACK || 'gemini-flash-latest';
  const models = primary === fallback ? [primary] : [primary, fallback];

  const prompt = buildPrompt({ category, lang, natal, planetHouses, aspects, transitAspects, progressedAspects, patterns, date, userName });
  const raw = await callGemini(env.GEMINI_API_KEY, prompt, models, {
    thinkingBudget: thinking ? 512 : null, // 2026-05-25 1024→512 (コスト半減・品質ほぼ維持)
  });

  // 4. JSON抽出 (Geminiは基本JSON返すが念のためfallback)
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

  const reading = stripTransitLabel(parsed.reading || '', lang);
  const advice = stripTransitLabel(parsed.advice || '', lang);

  // 5. DO に保存 (ON CONFLICT DO NOTHING で並行リクエストでも安全)
  if (cacheEligible) {
    await callDoFn(env, '/fortune-reading-set', {
      appUserId, localDate: date, category, lang,
      reading, advice, score,
    }).catch((_e) => { /* 保存失敗は致命的ではない (次回再生成される) */ });
  }

  return { category, score, reading, advice, lang };
}
