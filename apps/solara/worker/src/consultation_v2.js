/**
 * Solara Stella 相談 V2 — Gemini ナレーション層 (Phase 2)。
 *
 * 設計: project_solara_consultation_full_integration.md
 *
 * Phase 1 の秘伝計算 (consultation_engine.runConsultationPipeline) が返す
 * 構造化素材を、Stella の言葉 (Gemini Flash 裏方) に変換する。
 * 旧 consultation.js (deployed・client が候補を組む方式) には手を入れない。
 * これは新方式 (client 最小入力 → 全サーバー計算) 用の新ハンドラ。
 *
 * 出力:
 *   初回 (isFirst) のみ innerSeason / intro / outro。
 *   毎回 candidate{ name, characterHeadline, energyLabels[], narrative, timeWindow }
 *        + evidence{ factors[], km[], note } + model / fallback。
 *   1 クレジット = 1 候補。「別の候補地」は excluded を足して再呼び出し (Phase 3)。
 *
 * 文体・表現ルール (確定 2026-05-23、全文 narrative に適用):
 *   - 時間 = 時計+TZ なし。現地の時間帯のみ (旅行先=旅行先の現地時間)。
 *   - 場所の呼び方 = 提示粒度に合わせる (座標のみ→「この地点」/ 店舗→店名+種類 / 都市→都市名)。
 *   - narrative 本文に km を出さない (有無・質で語る)。km はエビデンス専用。
 *   - 1 候補に関係し合う ~2 ファクター。可能なら Soft 1 + Hard 1 で「幅」(捏造はしない)。
 *   - 冒頭の呼びかけ禁止。専門用語 (進行の月/ハウス等) を出さない。
 *   - 読心禁止 (原則5): 他人の私的な心を断定せず「あなたの意識・動き・いつ」へ変換。
 *   - 吉凶禁止 (原則2/原則1): Soft/Hard 独立、good/bad/lucky を使わせない。
 */

import { callGemini } from './fortune.js';
import { runConsultationPipeline, _internal as engineInternal } from './consultation_engine.js';

const { PLANET_JP, SIGN_JP, BUCKET_JP } = engineInternal;

const THEME_JP = {
  love: '恋愛・関係', money: '豊かさ・お金', work: '仕事・キャリア',
  communication: '対話・学び', healing: '癒し・休息', newStart: '変化・新たな出発',
};
const MODE_JP = { migration: '移住', travel: '旅行', daily: 'おでかけ' };
const ANGLE_JP = { mc: 'MC(天頂)', ic: 'IC(天底)', asc: 'ASC(上昇)', dsc: 'DSC(下降)' };
const ASPECT_JP = { conjunction: '合', trine: 'トライン', square: 'スクエア', sextile: 'セクスタイル' };
const QUALITY_JP = { soft: '流れ・調和 (Soft)', hard: '摩擦・課題 (Hard)', neutral: '中立' };
const FRAME_JP = { natal: '出生', transit: '経過', progressed: '進行' };
const BEARING_JP = { N: '北', NE: '北東', E: '東', SE: '南東', S: '南', SW: '南西', W: '西', NW: '北西' };

const PLACE_TYPE_JP = {
  restaurant: 'レストラン', cafe: 'カフェ', bar: 'バー', bakery: 'ベーカリー',
  movie_theater: '映画館', park: '公園', museum: '美術館', art_gallery: 'ギャラリー',
  shopping_mall: 'ショッピングモール', store: '店', lodging: '宿', hotel: 'ホテル',
  tourist_attraction: '観光スポット', spa: 'スパ', gym: 'ジム', library: '図書館',
  aquarium: '水族館', zoo: '動物園', amusement_park: '遊園地', book_store: '書店',
  church: '教会', temple: '寺院', shrine: '神社', beach: 'ビーチ', night_club: 'クラブ',
};

// ── 場所の呼び方を提示粒度に合わせて決める ──────────────────

function placeReference(candidate) {
  if (candidate.bearing) {
    return {
      ref: `${BEARING_JP[candidate.bearing] || candidate.bearing}の方角`,
      guidance: '方角 (とそこに在るエネルギー) で示す。具体的な地名・都市名は出さない。',
    };
  }
  if (candidate.placeType) {
    const typeJp = PLACE_TYPE_JP[candidate.placeType] || candidate.placeType;
    const name = candidate.name || 'この場所';
    return {
      ref: `${name} (${typeJp})`,
      guidance: 'ユーザーが選んだ実在の店舗名と種類で呼ぶ。種類の雰囲気も読んでよい。店名は発明しない。',
    };
  }
  if (candidate.name) {
    return {
      ref: candidate.name,
      guidance: '都市名で呼んでよい。一般的に広く知られた土地の特徴 (例: 古都) は使ってよいが、店舗名は出さない。',
    };
  }
  // 座標のみ (地図タップ)
  return {
    ref: 'この地点',
    guidance: '座標だけが渡されている。「この地点」と呼ぶ。地名・都市名・店舗名に言い換えない。',
  };
}

// ── ファクター → プロンプト用 日本語行 ──────────────────────

function factorPromptLine(f) {
  const planet = PLANET_JP[f.planet] || f.planet;
  const frame = FRAME_JP[f.frame] ? `${FRAME_JP[f.frame]}の` : '';
  if (f.kind === 'band') {
    const band = f.aspect === 'zenith' ? '天頂帯 (社会的露出・キャリアの緯度効果)' : '天底帯 (家庭・ルーツ・無意識の緯度効果)';
    return `${frame}${planet} ${band} [${QUALITY_JP[f.quality] || f.quality}]`;
  }
  const angle = ANGLE_JP[f.angle] || f.angle;
  const asp = ASPECT_JP[f.aspect] || f.aspect;
  return `${frame}${planet} ${angle} ${asp} [${QUALITY_JP[f.quality] || f.quality}]`;
}

function timeWindowPromptText(tw) {
  if (!tw) return '(時間帯は扱わない)';
  if (tw.kind === 'single') {
    if (!tw.planet) return `現地の時間帯: ${BUCKET_JP[tw.bucket] || tw.bucket}`;
    return `この地点で ${BUCKET_JP[tw.bucket] || tw.bucket} に ${PLANET_JP[tw.planet] || tw.planet} が ${ANGLE_JP[tw.angle] || tw.angle} を通過する (現地時間)`;
  }
  if (tw.kind === 'rhythm') {
    return tw.items.map((it) => `${BUCKET_JP[it.bucket] || it.bucket}: ${PLANET_JP[it.planet] || it.planet} ${ANGLE_JP[it.angle] || it.angle}`).join(' / ');
  }
  return '(時間帯は扱わない)';
}

/** UI チップ用の人間可読な時間帯ラベル (narrative とは別に構造で返す)。 */
function humanizeTimeWindow(tw) {
  if (!tw) return null;
  if (tw.kind === 'single') {
    return { kind: 'single', bucket: tw.bucket, label: BUCKET_JP[tw.bucket] || tw.bucket };
  }
  if (tw.kind === 'rhythm') {
    return { kind: 'rhythm', items: tw.items.map((it) => ({ bucket: it.bucket, label: BUCKET_JP[it.bucket] || it.bucket })) };
  }
  return null;
}

function innerSeasonPromptText(is) {
  if (!is) return '(内的季節データなし)';
  const houseStr = is.progMoonHouse ? `・${is.progMoonHouse}室` : '';
  let s = `進行の月: ${is.progMoonSignJP}座${houseStr} (今の内的季節・意識が向く領域) / 進行の太陽: ${is.progSunSignJP}座 (進化する核の方向)`;
  if (is.turningPoint) {
    s += ` / ソーラーアークが節目に当たっている (大きな転機の時期というニュアンスを薄く添えてよい)`;
  }
  return s;
}

// ── プロンプト生成 ──────────────────────────────────────────

function buildConsultationPrompt({ pipe, theme, mode, withWhom, wish }) {
  const themeJp = THEME_JP[theme] || theme;
  const modeJp = MODE_JP[mode] || mode;
  const c = pipe.candidate;
  const place = placeReference(c);
  const isFirst = pipe.isFirst;

  const factorLines = (c.factors || []).map((f) => `  - ${factorPromptLine(f)}`).join('\n')
    || '  - (テーマ該当の強いファクターが近距離に無い)';

  let relocLine = '';
  if (c.relocation && c.relocation.planetHouses) {
    const hs = Object.entries(c.relocation.planetHouses)
      .map(([p, h]) => `${PLANET_JP[p] || p}=${h}室`).join(' / ');
    relocLine = `\n【この土地でのリロケハウス (秘伝・narrative に「○室」と数字を出さず、意味だけ織り込む)】\n  ${hs}`;
  }

  const whomBlock = (withWhom && withWhom.trim())
    ? `\n【だれと (語りのレンズ・自由記述)】\n${withWhom.trim()}`
    : '\n【だれと】(指定なし)';
  const wishBlock = (wish && wish.trim())
    ? `\n【どうなりたい / 願い (語りの核・自由記述)】\n${wish.trim()}`
    : '\n【どうなりたい / 願い】(指定なし)';

  const quietGuidance = c.honestQuiet
    ? '\n⚠️ この候補はテーマ該当の強い線が近距離に無い「静かな場」。捏造して「隠れたパワーが」等と持ち上げない。'
      + '「テーマの線が遠い、ニュートラルで静かな場」と正直に描く (Solara の誠実さ)。'
    : '';

  const firstOnlySchema = isFirst
    ? `\n  "innerSeason": "<専門用語を一切使わず『今のあなたは〜の内的な季節』と一文で枠を作る。50〜90字>",`
      + `\n  "intro": "<相談者の願いを受け止める導入。テーマに触れる。冒頭呼びかけ禁止。50〜100字>",`
      + `\n  "outro": "<awareness を開く語りで終える。判定・指示・禁止フレーズなし。100〜130字>",`
    : '';

  const firstOnlyRule = isFirst
    ? `\n- innerSeason: 「進行の月」「ハウス」等の専門用語を出さず、今の内的な季節を一文で。`
      + `\n- intro/outro を出す。outro は awareness の種を必ず含む (「ここに並んだ候補は世界の全部ではない」「見えていない最高がある」「予想外も後から気づきに変わりうる」のいずれか)。`
    : '\n- これは追加候補 (2 枚目以降)。innerSeason/intro/outro は出さない。candidate だけを返す。';

  return `あなたは Solara の声 Stella です。アストロカートグラフィ (Jim Lewis 流) を土台に、
相談者の願いに照らして、提示された 1 つの候補地の「在るエネルギー」を読み解きます。
自分のことは「Stella」と呼ぶか人称を省略します。「AI」「人工知能」とは決して名乗りません。

【相談メタ】
- テーマ: ${themeJp} (${theme})
- 場面: ${modeJp} (${mode})${whomBlock}${wishBlock}

【候補地の呼び方】
- 呼称: ${place.ref}
- ルール: ${place.guidance}

【この候補地に在る占星術ファクター (近い/強い順。Soft/Hard は独立した別エネルギー)】
${factorLines}${relocLine}${quietGuidance}

【時間帯 (現地の時間帯のみ。時計の数字・タイムゾーン名は禁止)】
${timeWindowPromptText(pipe.timeWindow)}

【内的季節 (進行。専門用語は narrative に出さない。枠として使う)】
${innerSeasonPromptText(pipe.innerSeason)}

🔴 Solara 設計思想 (絶対遵守、すべての文に適用):

1. 吉凶判定をしない。「ラッキー」「アンラッキー」「良い/悪い」「吉/凶」「恵まれた」を絶対に使わない。
   Soft (流れ・受容・拡大・調和) と Hard (摩擦・変容・対峙・深化) は独立した 2 エネルギー。
   Hard は「悪い」ではなく「向き合う招待・覚悟が要るかもしれない機会」として描く。

2. narrative は関係し合う最大 2 つのファクターを中心に紡ぐ。可能なら Soft を 1 つ + Hard を 1 つ
   重ね、「順調に流れるのか/課題を抱えながらか」の幅をユーザー自身が当てはめられるようにする。
   片方の質しか無ければ無理に作らない (正直)。全ファクターに薄く触れて散漫にしない。

3. narrative 本文に距離 (km・「約○km」) を一切出さない。エネルギーの有無・質で語る。

4. 時間は現地の時間帯 (朝/昼/夕/夜/夜更け/明け方) だけで語る。時計の数字・「JST」等は出さない。
   旅行先の時間帯は旅行先の現地時間で言う。

5. 内的季節を土地のエネルギーに重ねる。「今のあなたは〜の季節。だからこの土地の質は今のあなたに〜」。
   「こうすべき」と指示しない。「今どこにいるか」+「土地がそれにどう出会うか」だけ。

6. 読心の禁止 (原則5): 相手や第三者の私的な気持ちを事実として断定しない
   (「彼はこう思っている」等は禁止)。代わりに「あなたが何を意識し・どう動き・いつ動くか」へ変換する。
   相談者本人の配置・届くエネルギー・意識すべき点は具体的・温かく・逃げずに読む。

7. 文体ハイブリッド: エネルギー描写 (場の様子・線の質) = 観察 (だ・である調 + 体言止め)。
   相談者への語りかけ = 寄り添い (ですます調)。1 段落内で混ぜず、ブロックで切り替える。

8. 冒頭でニックネーム/呼びかけを使わない (途中でたまにはOK)。相談者の名前は渡されていない。
   自由記述に関係呼称 (妻/夫/友人 等) が出たらその呼称を優先して使ってよい。

9. characterHeadline = この候補地の「一番強い要素」を短い見出し (15字以内目安) に。
   3 枚並べたとき「違う質の招待」と一目で分かる肝。静かな場なら「テーマ線が遠い静かな場」等、正直に。

10. energyLabels = 「{惑星名} {アングル/帯}・{5〜15字の性格}」の配列。上のファクターを展開する。
    例: "金星 MC・愛と調和の軸が立つ" / "火星 ASC・突破の身体性"。${firstOnlyRule}

【出力 JSON 形式 (これ以外を返さない。マークダウン・コードフェンス禁止)】
{${firstOnlySchema}
  "candidate": {
    "characterHeadline": "<15字以内目安の特徴見出し>",
    "energyLabels": ["<惑星 アングル・性格>", ...],
    "narrative": "<400〜520字。観察 (だ/である) + 語りかけ (ですます) のハイブリッド。最寄り 1〜2 ファクター中心、可能なら Soft+Hard で幅。km を出さない。内的季節を重ねる。読心しない>"
  }
}`;
}

// ── 静的フォールバック (Stella が届かない時) ────────────────

function staticFallback(pipe) {
  const c = pipe.candidate;
  const place = placeReference(c);
  const factors = c.factors || [];
  const energyLabels = factors.map((f) => {
    const planet = PLANET_JP[f.planet] || f.planet;
    if (f.kind === 'band') return `${planet} ${f.aspect === 'zenith' ? '天頂帯' : '天底帯'}`;
    return `${planet} ${(ANGLE_JP[f.angle] || f.angle).replace(/\(.*\)/, '')}${ASPECT_JP[f.aspect] || ''}`;
  });
  const headline = factors.length
    ? `${PLANET_JP[factors[0].planet] || factors[0].planet}の${factors[0].kind === 'band' ? '帯' : (ANGLE_JP[factors[0].angle] || '').replace(/\(.*\)/, '')}が在る場`
    : 'テーマ線が遠い静かな場';
  const narrative = factors.length
    ? `${place.ref}。今は Stella の声が届きませんが、在るエネルギーの客観情報をお渡しします。`
    : `${place.ref} はテーマ該当の線が近距離に見当たらない、静かでニュートラルな場です。`;

  const out = {
    candidate: { name: c.name, characterHeadline: headline, energyLabels, narrative },
    fallback: true,
  };
  if (pipe.isFirst) {
    out.innerSeason = '';
    out.intro = `${MODE_JP[pipe.meta?.mode] || ''}の候補を整理しました。`;
    out.outro = 'ここに並んだ候補は世界の全部ではありません。見えていない場所も、いつかの気づきに変わります。';
  }
  return out;
}

// ── メインエントリ ──────────────────────────────────────────

/**
 * 相談リクエスト → Stella の読み (Phase 1 計算 → Gemini ナレーション)。
 * @param {object} body 最小入力 (consultation_engine と同じ contract)
 * @param {object} env Worker env
 * @param {object} [deps] テスト用注入 ({ callGeminiFn, runPipeline })
 */
export async function handleConsultationV2(body, env, deps = {}) {
  const runPipeline = deps.runPipeline || runConsultationPipeline;
  const callGeminiFn = deps.callGeminiFn || callGemini;

  const { theme, mode, withWhom = '', wish = '', lang = 'ja' } = body || {};
  if (lang !== 'ja') throw new Error(`Unsupported lang: ${lang} (v1 supports ja only)`);

  // Phase 1: 秘伝計算
  const pipe = runPipeline(body);

  // これ以上候補が無い (excluded で出し尽くした)
  if (!pipe.candidate) {
    return { exhausted: true, remainingAfter: 0, meta: pipe.meta };
  }

  const timeWindow = humanizeTimeWindow(pipe.timeWindow);

  // 共通で返す土台 (Gemini 成否に依らず付ける構造データ)
  const base = {
    isFirst: pipe.isFirst,
    evidence: pipe.evidence,
    remainingAfter: pipe.remainingAfter,
    single: pipe.single,
    fallbackHonest: pipe.fallbackHonest,
    candidateMeta: {
      name: pipe.candidate.name, nameEN: pipe.candidate.nameEN,
      bearing: pipe.candidate.bearing, placeType: pipe.candidate.placeType,
      lat: pipe.candidate.lat, lng: pipe.candidate.lng,
      country: pipe.candidate.country, region: pipe.candidate.region,
    },
    timeWindow,
    meta: pipe.meta,
  };

  if (!env.GEMINI_API_KEY) {
    return { ...base, ...staticFallback(pipe), model: 'fallback' };
  }

  const primary = env.CONSULTATION_MODEL_PRIMARY || env.FORTUNE_MODEL_PRIMARY || 'gemini-2.5-flash';
  const fallbackModel = env.CONSULTATION_MODEL_FALLBACK || env.FORTUNE_MODEL_FALLBACK || 'gemini-flash-latest';
  const models = primary === fallbackModel ? [primary] : [primary, fallbackModel];

  const prompt = buildConsultationPrompt({ pipe, theme, mode, withWhom, wish });

  let parsed;
  try {
    const raw = await callGeminiFn(env.GEMINI_API_KEY, prompt, models, {
      thinkingBudget: 512, // 2026-05-25 1024→512 (コスト半減・品質ほぼ維持)。Free/Pro 同等品質
      maxOutputTokens: 2048, // 候補1つ + (初回のみ intro/outro/innerSeason)
      retries: 1,
    });
    try { parsed = JSON.parse(raw); }
    catch { parsed = JSON.parse(raw.replace(/^```json\s*|\s*```$/g, '').trim()); }
  } catch (_) {
    return { ...base, ...staticFallback(pipe), model: 'fallback' };
  }

  const ai = (parsed && parsed.candidate) || {};
  const out = {
    ...base,
    candidate: {
      ...base.candidateMeta,
      characterHeadline: typeof ai.characterHeadline === 'string' ? ai.characterHeadline : '',
      energyLabels: Array.isArray(ai.energyLabels) ? ai.energyLabels : [],
      narrative: typeof ai.narrative === 'string' ? ai.narrative : '',
      timeWindow,
    },
    model: primary,
  };
  delete out.candidateMeta;

  if (pipe.isFirst) {
    out.innerSeason = typeof parsed.innerSeason === 'string' ? parsed.innerSeason : '';
    out.intro = typeof parsed.intro === 'string' ? parsed.intro : '';
    out.outro = typeof parsed.outro === 'string' ? parsed.outro : '';
  }
  return out;
}

export const _internal = {
  buildConsultationPrompt, placeReference, factorPromptLine,
  timeWindowPromptText, humanizeTimeWindow, innerSeasonPromptText, staticFallback,
};
