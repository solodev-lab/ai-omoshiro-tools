/**
 * 英語生成のクリシェ・ガード (B案・2026-06-05)。
 *
 * 背景: 英語 (lang !== 'ja') の Gemini 生成は、英語の学習データがホロスコープ/
 * 自己啓発/グリーティングカードのクリシェ語彙で飽和しているため、プロンプトの
 * 禁止リストだけでは ~95% が天井 (毎回 1〜2 個の別のクリシェがすり抜ける)。
 * → 生成後に禁止語を検出し、見つかった時だけ「その語を使うな」と名指しして
 *   1 回だけ再生成する (detect → retry once)。クリーンなら追加生成なし＝コスト増なし。
 *
 * 禁止語の正典はここ (プロンプト側は register 指示＋少数の手本だけに減量し、
 * 列挙はこのコードに集約 = 毎回の入力トークンを節約)。日本語には適用しない。
 */

// 各パターンは単語境界つき・大文字小文字無視。label は再生成ディレクティブで名指しする用。
const EN_CLICHE_PATTERNS = [
  // 織物・運命の比喩
  [/\btapestry\b/i, 'tapestry'],
  [/\bthreads?\b/i, 'thread(s)'],
  [/\bwoven\b/i, 'woven'],
  [/\bfabric of\b/i, 'fabric of'],
  // 心・旅のクリシェ
  [/\bheart'?s desire\b/i, "heart's desire"],
  [/\bheart'?s journey\b/i, "heart's journey"],
  [/\bjourney of the heart\b/i, 'journey of the heart'],
  [/\bunfold(s|ing|ed)?\b/i, 'unfold/unfolding'],
  [/\byour soul'?s purpose\b/i, "soul's purpose"],
  [/\bhighest self\b/i, 'highest self'],
  // 幸運・運命 (good/bad 禁止にも反する)
  [/\bgood fortune\b/i, 'good fortune'],
  [/\bfortunate\b/i, 'fortunate'],
  [/\blucky\b/i, 'lucky'],
  [/\bblessed\b/i, 'blessed'],
  [/\bserendipity\b/i, 'serendipity'],
  [/\bmeant to be\b/i, 'meant to be'],
  [/\bmeant for (you|us)\b/i, 'meant for you/us'],
  [/\bin its own timing\b/i, 'in its own timing'],
  [/\bthe universe has a plan\b/i, 'the universe has a plan'],
  [/\btrust the universe\b/i, 'trust the universe'],
  [/\bdivine timing\b/i, 'divine timing'],
  [/\beverything happens for a reason\b/i, 'everything happens for a reason'],
  // 自己啓発の常套句
  [/\bembrace (vulnerability|change)\b/i, 'embrace vulnerability/change'],
  [/\bstep into your power\b/i, 'step into your power'],
  [/\blet your light shine\b/i, 'let your light shine'],
  [/\btrue sel(f|ves)\b/i, 'true self/selves'],
  [/\bshared dreams\b/i, 'shared dreams'],
  [/\bdeeper understanding\b/i, 'deeper understanding'],
  [/\bhidden wisdom\b/i, 'hidden wisdom'],
  [/\bopen your heart\b/i, 'open your heart'],
  [/\brelease what no longer serves you\b/i, 'release what no longer serves you'],
  [/\bhold space\b/i, 'hold space'],
  [/\bsacred space\b/i, 'sacred space'],
  [/\bbeautiful soul\b/i, 'beautiful soul'],
];

/**
 * text に含まれる禁止クリシェの label 配列を返す (重複排除)。クリーンなら []。
 * lang が 'ja' (またはそれ以外で日本語扱い) のときは常に [] (適用外)。
 */
export function clichesIn(text, lang) {
  if (!text || lang === 'ja') return [];
  const found = new Set();
  for (const [re, label] of EN_CLICHE_PATTERNS) {
    if (re.test(text)) found.add(label);
  }
  return [...found];
}

/**
 * 検出した label 群を「これらを使わず書き直せ」というプロンプト追記に変換する。
 * 既存プロンプトの末尾に足して 1 回だけ再生成するための文。
 */
export function clicheRetryDirective(labels) {
  if (!labels || !labels.length) return '';
  return `\n\n🔴 REWRITE REQUIRED: your previous draft used forbidden cliché wording: ${labels.join(', ')}. `
    + `Produce the JSON again, keeping every rule and the same structure, but WITHOUT those words or any equally generic `
    + `horoscope / self-help / greeting-card phrasing. Say it in plain, kind, concrete words instead.`;
}
