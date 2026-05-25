/**
 * Solara (ii) Stella 相談 — Stage 3 (Gemini API バックエンド)
 *
 * 設計: apps/solara/docs/pro_candidates.md §7.2 Stage 3
 *
 * クライアント (Stage 2 = consultation_engine.dart) が組み立てた候補リストを
 * 受け取り、Gemini Flash を裏方として Stella が「悩み (テーマ + 自由記述) に
 * 照らした解釈」を生成して返す。Stella は方角・エネルギーだけ示す。
 * 店舗名・固有名詞は返さない。
 *
 * 注: Gemini はあくまでバックエンドの実装で、ユーザーには「Stella」として
 * 振る舞う。プロンプトでも Stella と自称する。
 *
 * 入力 body:
 *   {
 *     theme: 'love'|'money'|'work'|'communication'|'healing'|'newStart',
 *     mode:  'migration'|'travel'|'daily',
 *     scope: 'specific'|'region'|'world'|'bearings',
 *     freeText?: string,                       // 任意。自由記述 (悩み詳細)
 *     candidates: [{                            // 1..3 件、Stage 2 出力
 *       name, nameEN, lat, lng, country, region,
 *       bearing?: 'N'|'NE'|...,                // daily モード時のみ
 *       nearLines: [{planet, angle, aspect, distanceKm}, ...]
 *     }],
 *     excluded?: string[],                      // リフレッシュ用、既出候補名
 *     lang?: 'ja'                               // v1 は ja 固定
 *   }
 *
 * 出力:
 *   {
 *     intro: string,                            // 50-100 字
 *     candidates: [{ name, energyLabels[], narrative }],
 *     outro: string,                            // 100-130 字
 *     model: string,                            // 実際に使ったモデル名
 *     fallback?: boolean                        // Stella が届かない時 true (静的テンプレ)
 *   }
 *
 * 設計思想ガード:
 *   - 吉凶判定しない (Soft/Hard 独立)
 *   - 「方角を返す、店舗名は返さない」
 *   - 「無いものを在ると言わない」
 *   - awareness を開く outro (候補は世界の全部じゃない / 見えていない最高がある /
 *     予想外も気づきに変えうる)
 *   - 文体ハイブリッド: エネルギー描写=観察、相談者語りかけ=ですます
 *   - 名前ルール: ユーザー名はシステムから渡さない。Stella も呼びかけない
 */

import { callGemini } from './fortune.js';

const VALID_THEMES = new Set([
  'love', 'money', 'work', 'communication', 'healing', 'newStart',
]);
const VALID_MODES = new Set(['migration', 'travel', 'daily']);
const VALID_SCOPES = new Set(['specific', 'region', 'world', 'bearings']);

const THEME_JP = {
  love: '恋愛・関係',
  money: '豊かさ・お金',
  work: '仕事・キャリア',
  communication: '対話・学び',
  healing: '癒し・休息',
  newStart: '変化・新たな出発',
};

const MODE_JP = {
  migration: '移住',
  travel: '旅行',
  daily: 'おでかけ',
};

const SCOPE_JP = {
  specific: '具体地点',
  region: '範囲指定',
  world: '世界全体',
  bearings: '現在地から方角別',
};

const PLANET_JP = {
  sun: '太陽', moon: '月', mercury: '水星', venus: '金星', mars: '火星',
  jupiter: '木星', saturn: '土星', uranus: '天王星', neptune: '海王星', pluto: '冥王星',
};

const ANGLE_JP = {
  mc: 'MC (天頂)',
  ic: 'IC (天底)',
  asc: 'ASC (上昇)',
  dsc: 'DSC (下降)',
};

const BEARING_JP = {
  N: '北', NE: '北東', E: '東', SE: '南東',
  S: '南', SW: '南西', W: '西', NW: '北西',
};

// ── Prompt builder ──────────────────────────────────────────

function describeCandidate(c, idx) {
  const lines = [];
  lines.push(`【候補 ${idx + 1}】`);
  const isBearing = !!c.bearing;
  if (isBearing) {
    lines.push(`方角ラベル: ${c.name} (${BEARING_JP[c.bearing] || c.bearing})`);
    if (c.region) lines.push(`参考領域: ${c.region}`);
  } else {
    lines.push(`場所: ${c.name}${c.region ? ` (${c.region})` : ''}${c.country ? `, ${c.country}` : ''}`);
  }
  const near = Array.isArray(c.nearLines) ? c.nearLines : [];
  if (near.length === 0) {
    lines.push('近接ライン: なし (近距離にテーマ該当の本線が見当たらない)');
  } else {
    lines.push('近接ライン (近い順):');
    for (const nl of near) {
      const planet = PLANET_JP[nl.planet] || nl.planet;
      const angle = ANGLE_JP[String(nl.angle || '').toLowerCase()] || nl.angle;
      const d = Math.round(Number(nl.distanceKm) || 0);
      lines.push(`  - ${planet} ${angle}: 約 ${d} km`);
    }
  }
  return lines.join('\n');
}

function buildPrompt({ theme, mode, scope, freeText, candidates, excluded }) {
  const themeJp = THEME_JP[theme] || theme;
  const modeJp = MODE_JP[mode] || mode;
  const scopeJp = SCOPE_JP[scope] || scope;
  const candidateBlock = candidates.map((c, i) => describeCandidate(c, i)).join('\n\n');
  const exclBlock = (excluded && excluded.length)
    ? `\n【既出候補（除外せよ・narrative で名前を引用しない）】: ${excluded.join(', ')}`
    : '';
  const freeBlock = (freeText && freeText.trim())
    ? `\n【相談者の自由記述】\n${freeText.trim()}`
    : '\n【相談者の自由記述】(なし)';

  return `あなたは Solara の声 Stella です。アストロカートグラフィ (Jim Lewis 流) を土台に、
相談者の悩みに照らして、提示された候補地点それぞれの「在るエネルギー」を読み解きます。
自分のことは「Stella」と呼ぶか、人称は省略します。「AI」「人工知能」とは決して名乗りません。

【相談メタ】
- テーマ: ${themeJp} (${theme})
- モード: ${modeJp} (${mode})
- スコープ: ${scopeJp} (${scope})${freeBlock}${exclBlock}

【候補地点リスト】
${candidateBlock}

🔴 Solara 設計思想（絶対遵守、すべての文に適用）:

1. 吉凶判定をしない。「ラッキー」「アンラッキー」「良い/悪い」「吉/凶」「恵まれた」を絶対に使わない。
   Soft (流れ・受容・拡大・調和) と Hard (摩擦・変容・対峙・深化) は独立した 2 エネルギー。
   Hard を「悪い」ではなく「向き合う招待・覚悟が要るかもしれない機会」として描く。

2. 候補ごとに性格を鋭く差別化する。「どれも素敵」「どれを選んでも〜」と曖昧化しない。
   違う種類の招待・違う質の場として描く。

3. 相談者の悩み (テーマ + 自由記述) に必ず照らす。一般論にしない。

4. 線が無い候補は正直に描く。「無いものを在ると言わない」(Solara の誠実さ)。
   近接ラインが乏しい候補は「テーマ惑星の本線が遠い、ニュートラルな場」と素直に書く。
   無理に「実は隠れたパワーが…」等と捏造しない。

5. narrative は最も近い／強い 1〜3 本の線を中心に紡ぐ。全部に薄く触れて散漫にしない。

6. outro は判定や指示をしない。以下は禁止フレーズ:
   「選ぶのはあなた」「直感を信じて」「ラッキー」「成功」「失敗」「頑張って」「楽しんで」
   「素敵な旅を」「幸運を」「ベストを尽くして」
   代わりに awareness を開く語りで終わる。必ず以下のいずれかの種を含める:
   - 「ここに並んだ候補は世界の全部ではない (まだ見えていない場所がある)」
   - 「見えていない最高がある」
   - 「予想外の出来事も、後から気づきに変わりうる」

7. 文体ハイブリッド (重要):
   - エネルギー描写 (場の様子・線の質) = 観察。だ・である調 + 体言止め。
   - 相談者への語りかけ = 寄り添い。ですます調。
   1 段落の中で混ぜず、ブロックで切り替える。

8. energyLabels フォーマット: 候補ごとに「{惑星名} {アングル}・{5〜15 字の性格}」の配列。
   入力の nearLines を全部展開する (Stella が勝手に間引かない)。例:
     "金星 MC (天頂)・愛と調和の軸が立つ"
     "火星 ASC (上昇)・突破の身体性"

9. 名前ルール: 相談者の名前は渡されていない。あなたも呼びかけてはいけない (「○○さん」禁止)。
   自由記述中に関係呼称 (妻/夫/息子/友人 等) が出てきたら、その呼称を優先して使う。
   「関係+名前」併記しない。複数の同じ関係 (息子 A と息子 B 等) の区別が必要な場合のみ、
   自由記述中で本人が書いた名前を引用してよい。

【Stella 出力に関する追加ガード】
- 店舗名・施設名・固有名詞 (レストラン名・カフェ名等) を返さない。
  Stella は「方角・エリア・エネルギーの質」だけを示す。
- 候補名そのもの (都市名・方角ラベル) と、Solara が認識している土地のごく一般的な
  特徴 (例: 京都=古都、釧路=湿原) は使ってよい。
- moderate / extreme / 強い / 弱い は OK だが、Soft/Hard を優劣で語らない。

【出力 JSON 形式 (これ以外を返さない。マークダウン・コードフェンス禁止)】
{
  "intro": "<50〜100 字。相談者の願いを受け止める導入。テーマ + 候補数に触れる>",
  "candidates": [
    {
      "name": "<候補名 (入力と一致)>",
      "energyLabels": ["<惑星 アングル・5〜15 字性格>", ...],
      "narrative": "<500 字目安。エネルギー描写 (観察) + 相談者への語りかけ (ですます) のハイブリッド。最寄り 1〜3 線中心>"
    }
  ],
  "outro": "<100〜130 字。awareness を開く語りかけ。判定・指示・禁止フレーズを使わない>"
}

候補は ${candidates.length} 件。出力 JSON の candidates 配列もそれと同じ数で、
入力の順序を保持してください。`;
}

// ── Static fallback (Stella が届かない時) ───────────────────

function staticFallback({ theme, mode, scope, candidates }) {
  const themeJp = THEME_JP[theme] || theme;
  const modeJp = MODE_JP[mode] || mode;

  const out = {
    intro: `${themeJp} のテーマで、${modeJp} の候補を整理しました。`
      + `今は Stella の声が届きませんでしたが、各候補の客観情報をお渡しします。`,
    candidates: candidates.map((c) => {
      const near = Array.isArray(c.nearLines) ? c.nearLines : [];
      const labels = near.map((nl) => {
        const planet = PLANET_JP[nl.planet] || nl.planet;
        const angle = ANGLE_JP[String(nl.angle || '').toLowerCase()] || nl.angle;
        return `${planet} ${angle}・${Math.round(Number(nl.distanceKm) || 0)}km`;
      });
      const lines = near.slice(0, 3).map((nl) => {
        const planet = PLANET_JP[nl.planet] || nl.planet;
        const angle = ANGLE_JP[String(nl.angle || '').toLowerCase()] || nl.angle;
        return `${planet} ${angle} 約${Math.round(Number(nl.distanceKm) || 0)}km`;
      });
      const narrative = near.length === 0
        ? `${c.name} はテーマ該当の本線が近距離に見当たらないニュートラルな場です。`
        : `${c.name}。最寄りの線は ${lines.join('、')}。客観情報のみの表示です。`;
      return {
        name: c.name,
        energyLabels: labels,
        narrative,
      };
    }),
    outro: 'ここに並んだ候補は世界の全部ではありません。見えていない場所も、いつかの気づきに変わります。',
    fallback: true,
  };
  return out;
}

// ── メインエントリ: POST /astro/consultation ────────────────

export async function handleConsultation(body, env) {
  const {
    theme,
    mode,
    scope,
    freeText = '',
    candidates = [],
    excluded = [],
    lang = 'ja',
  } = body || {};

  // 入力検証
  if (!VALID_THEMES.has(theme)) {
    throw new Error(`Invalid theme: ${theme}`);
  }
  if (!VALID_MODES.has(mode)) {
    throw new Error(`Invalid mode: ${mode}`);
  }
  if (!VALID_SCOPES.has(scope)) {
    throw new Error(`Invalid scope: ${scope}`);
  }
  if (!Array.isArray(candidates) || candidates.length < 1 || candidates.length > 5) {
    throw new Error('candidates must be array of 1..5 items');
  }
  if (lang !== 'ja') {
    // v1 は ja 固定。EN は i18n 期で追加。
    throw new Error(`Unsupported lang: ${lang} (v1 supports ja only)`);
  }

  if (!env.GEMINI_API_KEY) {
    throw new Error('GEMINI_API_KEY not configured on worker');
  }

  // モデル: Pro 専用機能。thinking Flash を primary、通常 Flash を fallback。
  // env で上書き可能。
  const primary = env.CONSULTATION_MODEL_PRIMARY
    || env.FORTUNE_MODEL_PRIMARY
    || 'gemini-2.5-flash';
  const fallback = env.CONSULTATION_MODEL_FALLBACK
    || env.FORTUNE_MODEL_FALLBACK
    || 'gemini-flash-latest';
  const models = primary === fallback ? [primary] : [primary, fallback];

  const prompt = buildPrompt({
    theme, mode, scope, freeText, candidates, excluded,
  });

  let parsed;
  try {
    const raw = await callGemini(env.GEMINI_API_KEY, prompt, models, {
      thinkingBudget: 512, // 2026-05-25 1024→512 (コスト半減・品質ほぼ維持)。Free/Pro 同等品質
      maxOutputTokens: 4096, // 3 候補 × 500 字 + intro/outro でやや余裕
      retries: 1,
    });
    try {
      parsed = JSON.parse(raw);
    } catch {
      const cleaned = raw.replace(/^```json\s*|\s*```$/g, '').trim();
      parsed = JSON.parse(cleaned);
    }
  } catch (err) {
    // 静的 fallback
    return { ...staticFallback({ theme, mode, scope, candidates }), model: 'fallback' };
  }

  // 出力スキーマの最小バリデーション (足りないキーは空文字で埋め、stucture 保証)
  const outCandidates = Array.isArray(parsed.candidates) ? parsed.candidates : [];
  const padded = candidates.map((c, i) => {
    const ai = outCandidates[i] || {};
    return {
      name: ai.name || c.name,
      energyLabels: Array.isArray(ai.energyLabels) ? ai.energyLabels : [],
      narrative: typeof ai.narrative === 'string' ? ai.narrative : '',
    };
  });

  return {
    intro: typeof parsed.intro === 'string' ? parsed.intro : '',
    candidates: padded,
    outro: typeof parsed.outro === 'string' ? parsed.outro : '',
    model: primary,
  };
}
