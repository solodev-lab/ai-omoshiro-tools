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
import { STYLE_VOICE_JP, styleVoiceFor, outputLangDirective } from './style_voice.js';

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
  // 検索で選んだ具体的な場所 (店/公園/会社/学校等)。その場所名をそのまま使う。
  if (candidate.placeKind === 'named' && candidate.name) {
    return {
      ref: candidate.name,
      guidance: 'ユーザーが検索で選んだ具体的な場所名 (店・公園・会社・学校等)。この名前をそのまま使う。'
        + '都市名・住所・地名に言い換えたり丸めたりしない (例:「JR名古屋高島屋」を「名古屋」にしない)。名前は発明しない。',
    };
  }
  // ViewPoint / Locations の登録地。「登録名」という場所、と呼ぶ。
  if (candidate.placeKind === 'saved' && candidate.name) {
    return {
      ref: `「${candidate.name}」という場所`,
      guidance: `ユーザーが登録した場所。「${candidate.name}」という登録名で呼ぶ。都市名・住所に言い換えない。`,
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

// ── 30 分後デルタ (Pro おでかけ時刻指定) → プロンプト節 ──────────

const DELTA_DIR_JP = {
  approaching: 'この場所に近づいてくる (これから高まっていく)',
  receding: 'この場所から離れていく (引いていく)',
  entering: '新たにこの場所へ差してくる (後半に立ち上がる)',
  leaving: 'この場所から外れていく (役目を終える)',
  steady: 'ほぼ位置を保つ (流れは穏やかに続く)',
};

/** timeDelta.changes をプロンプト用の日本語ブロックにする。変化が無ければ空文字。 */
function deltaPromptSection(timeDelta) {
  if (!timeDelta || !Array.isArray(timeDelta.changes) || !timeDelta.changes.length) return '';
  const lines = timeDelta.changes.map((ch) => {
    const planet = PLANET_JP[ch.planet] || ch.planet;
    const angle = ANGLE_JP[ch.angle] || ch.angle;
    const asp = ASPECT_JP[ch.aspect] || ch.aspect;
    return `  - ${planet} ${angle} ${asp} の線が ${DELTA_DIR_JP[ch.dir] || ch.dir}`;
  }).join('\n');
  return `\n\n【${timeDelta.deltaMin}分後の変化 (選んだ時刻から${timeDelta.deltaMin}分後、この地点で角ラインが地球の自転で動いた結果)】\n${lines}`;
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

function buildConsultationPrompt({ pipe, theme, mode, withWhom, wish, userTimeBand }) {
  const themeJp = THEME_JP[theme] || theme;
  const modeJp = MODE_JP[mode] || mode;
  const c = pipe.candidate;
  const place = placeReference(c);
  const isFirst = pipe.isFirst;
  // 30 分後デルタ (Pro おでかけ時刻指定)。candidate.timeDelta が非 null のとき。
  const timeDelta = c.timeDelta || null;
  const deltaSection = deltaPromptSection(timeDelta);
  const hasDelta = !!(timeDelta && Array.isArray(timeDelta.changes) && timeDelta.changes.length);
  const deltaMin = hasDelta ? timeDelta.deltaMin : 30;
  const deltaSchemaLine = hasDelta
    ? `,\n    "deltaAfter": "<${deltaMin}分後、この場所の流れがどう移ろうかを書く。100〜160字。観察(だ/である)+語りかけ(ですます)のハイブリッド。吉凶禁止。線が離れる=そのエネルギーが引いて別の質へ移る/近づく・差す=これから高まる、で描く。『核心は前半に』『後半に向けて〜』のような主体性への寄り添い助言はOK(断定・命令はしない)。変化が小さければ『この${deltaMin}分は流れが穏やかに続く』と正直に。>"`
    : '';
  const deltaRule = hasDelta
    ? `\n- deltaAfter: 上の「${deltaMin}分後の変化」を、選んだ時刻の読みからの"移ろい"として語る。線が動く=その場の主役が静かに入れ替わる、を吉凶なしで。前半/後半の質の違いに気づける一言を添える。`
    : '';

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

  // ユーザーが「おでかけ」で予定時間帯を指定したら、それを語りの主役にする
  // (= 昼の予定なのに朝/夜更けを語る白け防止)。未指定なら従来どおりエンジン推奨。
  const userBandJp = userTimeBand ? (BUCKET_JP[userTimeBand] || null) : null;
  const timeSection = userBandJp
    ? `相談者の予定時間帯: ${userBandJp} (この時間に行く予定。語りはこの時間帯を主役にする)\n  (参考・この土地で星の線が際立つ時間帯: ${timeWindowPromptText(pipe.timeWindow)})`
    : timeWindowPromptText(pipe.timeWindow);

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
${timeSection}

【内的季節 (進行。専門用語は narrative に出さない。枠として使う)】
${innerSeasonPromptText(pipe.innerSeason)}${deltaSection}

🔴 Solara 設計思想 (絶対遵守、すべての文に適用):

1. 吉凶判定をしない。「ラッキー」「アンラッキー」「良い/悪い」「吉/凶」「恵まれた」を絶対に使わない。
   Soft (流れ・受容・拡大・調和) と Hard (摩擦・変容・対峙・深化) は独立した 2 エネルギー。
   Hard は「悪い」ではなく「向き合う招待・覚悟が要るかもしれない機会」として描く。

2. narrative は関係し合う最大 2 つのファクターを中心に紡ぐ。可能なら Soft を 1 つ + Hard を 1 つ
   重ね、「順調に流れるのか/課題を抱えながらか」の幅をユーザー自身が当てはめられるようにする。
   片方の質しか無ければ無理に作らない (正直)。全ファクターに薄く触れて散漫にしない。

3. narrative 本文に距離 (km・「約○km」) を一切出さない。エネルギーの有無・質で語る。

4. 時間は現地の時間帯 (朝/昼/夕方/夜/夜更け) だけで語る。時計の数字・「JST」等は出さない。${userBandJp ? `
   🔴 相談者の予定時間帯「${userBandJp}」を語りの主役にし、その時間に寄り添う。予定外の時間帯 (朝/夜更け等) を中心に語らない。` : `
   旅行先の時間帯は旅行先の現地時間で言う。時間帯の指定がないので、特定の時間帯を断定して語らず、必要なら「この土地で星の線が際立つ時間帯」として案内に留める。`}

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
    例: "金星 MC・愛と調和の軸が立つ" / "火星 ASC・突破の身体性"。

11. 🔴 安全性ガイド: 医療・法律・金融・投資・自傷に関わる断定的なアドバイスをしない。
    相談文 (テーマ/だれと/願い) がこれらの領域 (健康・お金・契約・危機) に触れる場合も、
    占星術の文脈にだけ寄り添い、必要なら専門家への相談をやんわり勧める。
    移住・転職・離婚・出産等の人生の重大判断についても、「占星術はあなたの意識を映す鏡」
    として読み、最終判断は相談者本人のものと明確にする。「必ず」「絶対」「○○すべき」は禁止。${firstOnlyRule}

12. テーマ (癒し/恋愛 等) は相談者が既に選択済み。本人の動機を推測 (「〜を求めているのかもしれませんね」等) しない。
    テーマは所与とし、その土地がそのテーマにどう出会うかを語る。${deltaRule}
${STYLE_VOICE_JP}

【出力 JSON 形式 (これ以外を返さない。マークダウン・コードフェンス禁止)】
{${firstOnlySchema}
  "candidate": {
    "characterHeadline": "<15字以内目安の特徴見出し>",
    "energyLabels": ["<惑星 アングル・性格>", ...],
    "narrative": "<400〜520字。観察 (だ/である) + 語りかけ (ですます) のハイブリッド。最寄り 1〜2 ファクター中心、可能なら Soft+Hard で幅。km を出さない。内的季節を重ねる。読心しない>"${deltaSchemaLine}
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

  const candidateOut = { name: c.name, characterHeadline: headline, energyLabels, narrative };
  if (c.timeDelta) {
    // fallback では narrative を生成できないので changes のみ (UI 側で narrative 空なら非表示)。
    candidateOut.deltaAfter = { deltaMin: c.timeDelta.deltaMin, changes: c.timeDelta.changes, narrative: '' };
  }
  const out = { candidate: candidateOut, fallback: true };
  if (pipe.isFirst) {
    out.innerSeason = '';
    out.intro = `${MODE_JP[pipe.meta?.mode] || ''}の候補を整理しました。`;
    out.outro = 'ここに並んだ候補は世界の全部ではありません。見えていない場所も、いつかの気づきに変わります。';
  }
  return out;
}

// ════════════════════════════════════════════════════════════
// 非 ja 言語版 (lang !== 'ja')。英語を土台に「出力は {言語} で書け」ディレクティブ +
// 言語別の声 (styleVoiceFor) を注入。日本語版と同じ構造・同じ出力 JSON フィールド名。
// 🔴 上の日本語パスには一切手を入れない (JP 無傷を最優先)。
// ════════════════════════════════════════════════════════════

const THEME_EN = {
  love: 'Love & relationships', money: 'Abundance & money', work: 'Work & career',
  communication: 'Talk & learning', healing: 'Healing & rest', newStart: 'Change & new beginnings',
};
const MODE_EN = { migration: 'relocation', travel: 'travel', daily: 'an outing' };
const ANGLE_EN = { mc: 'MC (zenith)', ic: 'IC (nadir)', asc: 'ASC (rising)', dsc: 'DSC (setting)' };
const ASPECT_EN = { conjunction: 'conjunction', trine: 'trine', square: 'square', sextile: 'sextile' };
const QUALITY_EN = { soft: 'flow & harmony (Soft)', hard: 'friction & challenge (Hard)', neutral: 'neutral' };
const FRAME_EN = { natal: 'natal', transit: 'transiting', progressed: 'progressed' };
const BEARING_EN = { N: 'north', NE: 'northeast', E: 'east', SE: 'southeast', S: 'south', SW: 'southwest', W: 'west', NW: 'northwest' };
const BUCKET_EN = { morning: 'morning', midday: 'midday', evening: 'evening', night: 'night', lateNight: 'late night' };
const SIGN_EN = ['Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo', 'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces'];
const PLANET_EN = {
  sun: 'the Sun', moon: 'the Moon', mercury: 'Mercury', venus: 'Venus', mars: 'Mars',
  jupiter: 'Jupiter', saturn: 'Saturn', uranus: 'Uranus', neptune: 'Neptune', pluto: 'Pluto',
};
const PLACE_TYPE_EN = {
  restaurant: 'restaurant', cafe: 'café', bar: 'bar', bakery: 'bakery',
  movie_theater: 'cinema', park: 'park', museum: 'museum', art_gallery: 'gallery',
  shopping_mall: 'shopping mall', store: 'shop', lodging: 'inn', hotel: 'hotel',
  tourist_attraction: 'tourist spot', spa: 'spa', gym: 'gym', library: 'library',
  aquarium: 'aquarium', zoo: 'zoo', amusement_park: 'amusement park', book_store: 'bookshop',
  church: 'church', temple: 'temple', shrine: 'shrine', beach: 'beach', night_club: 'club',
};
const DELTA_DIR_EN = {
  approaching: 'is drawing closer to this place (it keeps rising from here)',
  receding: 'is pulling away from this place (it is receding)',
  entering: 'is newly reaching this place (rising in the latter half)',
  leaving: 'is moving off this place (its role winding down)',
  steady: 'holds roughly its position (the flow continues gently)',
};

function placeReferenceEN(candidate) {
  if (candidate.bearing) {
    return {
      ref: `the ${BEARING_EN[candidate.bearing] || candidate.bearing} direction`,
      guidance: 'Refer to it by direction (and the energy present there). Do not name a specific place or city.',
    };
  }
  if (candidate.placeType) {
    const typeEn = PLACE_TYPE_EN[candidate.placeType] || candidate.placeType;
    const name = candidate.name || 'this place';
    return {
      ref: `${name} (${typeEn})`,
      guidance: 'Use the real venue name and type the user chose. You may read the mood of the type. Do not invent a venue name.',
    };
  }
  if (candidate.placeKind === 'named' && candidate.name) {
    return {
      ref: candidate.name,
      guidance: 'A specific place the user searched for (a shop, park, company, school, etc.). Use this exact name. '
        + 'Do not rephrase or round it into a city or address (e.g. do not turn "JR Nagoya Takashimaya" into "Nagoya"). Do not invent names.',
    };
  }
  if (candidate.placeKind === 'saved' && candidate.name) {
    return {
      ref: `the place called "${candidate.name}"`,
      guidance: `A place the user saved. Refer to it by its saved name, "${candidate.name}". Do not rephrase it into a city or address.`,
    };
  }
  if (candidate.name) {
    return {
      ref: candidate.name,
      guidance: 'You may refer to it by city name. Widely-known traits of the land (e.g. an ancient capital) are fine, but do not name venues.',
    };
  }
  return {
    ref: 'this spot',
    guidance: 'Only coordinates were given. Call it "this spot". Do not rephrase it into a place, city, or venue name.',
  };
}

function factorPromptLineEN(f) {
  const planet = PLANET_EN[f.planet] || f.planet;
  const frame = FRAME_EN[f.frame] ? `${FRAME_EN[f.frame]} ` : '';
  if (f.kind === 'band') {
    const band = f.aspect === 'zenith'
      ? 'zenith band (latitude effect on public exposure / career)'
      : 'nadir band (latitude effect on home, roots, the unconscious)';
    return `${frame}${planet} ${band} [${QUALITY_EN[f.quality] || f.quality}]`;
  }
  const angle = ANGLE_EN[f.angle] || f.angle;
  const asp = ASPECT_EN[f.aspect] || f.aspect;
  return `${frame}${planet} ${angle} ${asp} [${QUALITY_EN[f.quality] || f.quality}]`;
}

function timeWindowPromptTextEN(tw) {
  if (!tw) return '(time of day is not in scope)';
  if (tw.kind === 'single') {
    if (!tw.planet) return `Local time of day: ${BUCKET_EN[tw.bucket] || tw.bucket}`;
    return `At this spot, around ${BUCKET_EN[tw.bucket] || tw.bucket} the ${PLANET_EN[tw.planet] || tw.planet} crosses the ${ANGLE_EN[tw.angle] || tw.angle} (local time)`;
  }
  if (tw.kind === 'rhythm') {
    return tw.items.map((it) => `${BUCKET_EN[it.bucket] || it.bucket}: ${PLANET_EN[it.planet] || it.planet} ${ANGLE_EN[it.angle] || it.angle}`).join(' / ');
  }
  return '(time of day is not in scope)';
}

function deltaPromptSectionEN(timeDelta) {
  if (!timeDelta || !Array.isArray(timeDelta.changes) || !timeDelta.changes.length) return '';
  const lines = timeDelta.changes.map((ch) => {
    const planet = PLANET_EN[ch.planet] || ch.planet;
    const angle = ANGLE_EN[ch.angle] || ch.angle;
    const asp = ASPECT_EN[ch.aspect] || ch.aspect;
    return `  - the ${planet} ${angle} ${asp} line ${DELTA_DIR_EN[ch.dir] || ch.dir}`;
  }).join('\n');
  return `\n\n[Shift ${timeDelta.deltaMin} minutes later (${timeDelta.deltaMin} min after the chosen time, as the angle lines move with Earth's rotation at this spot)]\n${lines}`;
}

function humanizeTimeWindowEN(tw) {
  if (!tw) return null;
  if (tw.kind === 'single') {
    return { kind: 'single', bucket: tw.bucket, label: BUCKET_EN[tw.bucket] || tw.bucket };
  }
  if (tw.kind === 'rhythm') {
    return { kind: 'rhythm', items: tw.items.map((it) => ({ bucket: it.bucket, label: BUCKET_EN[it.bucket] || it.bucket })) };
  }
  return null;
}

function innerSeasonPromptTextEN(is) {
  if (!is) return '(no inner-season data)';
  const moonSign = (is.progMoonSign != null && SIGN_EN[is.progMoonSign]) ? SIGN_EN[is.progMoonSign] : (is.progMoonSignJP || '');
  const sunSign = (is.progSunSign != null && SIGN_EN[is.progSunSign]) ? SIGN_EN[is.progSunSign] : (is.progSunSignJP || '');
  const houseStr = is.progMoonHouse ? `, house ${is.progMoonHouse}` : '';
  let s = `Progressed Moon: ${moonSign}${houseStr} (the current inner season / where awareness turns) / Progressed Sun: ${sunSign} (the evolving direction of the core)`;
  if (is.turningPoint) {
    s += ` / a solar-arc turning point is in effect (you may lightly suggest a season of larger change)`;
  }
  return s;
}

function buildConsultationPromptEN({ pipe, theme, mode, withWhom, wish, userTimeBand, lang = 'en' }) {
  const themeEn = THEME_EN[theme] || theme;
  const modeEn = MODE_EN[mode] || mode;
  const c = pipe.candidate;
  const place = placeReferenceEN(c);
  const isFirst = pipe.isFirst;
  const timeDelta = c.timeDelta || null;
  const deltaSection = deltaPromptSectionEN(timeDelta);
  const hasDelta = !!(timeDelta && Array.isArray(timeDelta.changes) && timeDelta.changes.length);
  const deltaMin = hasDelta ? timeDelta.deltaMin : 30;
  const deltaSchemaLine = hasDelta
    ? `,\n    "deltaAfter": "<How this place's flow shifts ${deltaMin} minutes later. 60-110 words. Observation (plain) + address to the reader (gentle), hybrid. No good/bad. A line moving away = that energy receding into another quality; drawing closer / newly arriving = rising from here. Light, non-commanding pointers like 'the heart of it is early on' or 'it warms toward the latter half' are fine (no assertions, no commands). If the change is small, be honest: 'these ${deltaMin} minutes simply flow on gently.'>"`
    : '';
  const deltaRule = hasDelta
    ? `\n- deltaAfter: tell the "shift" from the reading at the chosen time. A moving line = the lead of the place quietly changing — without good/bad. Add one line that helps notice the difference in quality between the first and the latter half.`
    : '';

  const factorLines = (c.factors || []).map((f) => `  - ${factorPromptLineEN(f)}`).join('\n')
    || '  - (no strong theme-matching factor lies close by)';

  let relocLine = '';
  if (c.relocation && c.relocation.planetHouses) {
    const hs = Object.entries(c.relocation.planetHouses)
      .map(([p, h]) => `${PLANET_EN[p] || p}=house ${h}`).join(' / ');
    relocLine = `\n[Relocated houses at this land (esoteric — do NOT put house numbers in the narrative; weave only the meaning)]\n  ${hs}`;
  }

  const whomBlock = (withWhom && withWhom.trim())
    ? `\n[With whom (a lens for the telling — free text)]\n${withWhom.trim()}`
    : '\n[With whom] (unspecified)';
  const wishBlock = (wish && wish.trim())
    ? `\n[What they wish for (the core of the telling — free text)]\n${wish.trim()}`
    : '\n[What they wish for] (unspecified)';

  const quietGuidance = c.honestQuiet
    ? '\n⚠️ This candidate is a "quiet place" with no strong theme line close by. Do not fabricate or inflate it ("a hidden power…"). '
      + 'Describe it honestly as "a neutral, quiet place where the theme lines are far" (Solara\'s honesty).'
    : '';

  const userBandEn = userTimeBand ? (BUCKET_EN[userTimeBand] || null) : null;
  const timeSection = userBandEn
    ? `The reader's planned time of day: ${userBandEn} (they will go at this time; center the telling on this time of day)\n  (for reference, the time of day when the star lines stand out at this land: ${timeWindowPromptTextEN(pipe.timeWindow)})`
    : timeWindowPromptTextEN(pipe.timeWindow);

  const firstOnlySchema = isFirst
    ? `\n  "innerSeason": "<Without any jargon, frame it in one sentence: 'right now you are in an inner season of …'. 25-45 words>",`
      + `\n  "intro": "<An opening that receives the reader's wish. Touch the theme. No opening salutation. 25-50 words>",`
      + `\n  "outro": "<Close with words that open awareness. No verdict, command, or banned phrase. 50-70 words>",`
    : '';

  const firstOnlyRule = isFirst
    ? `\n- innerSeason: no jargon ("progressed Moon", "house"); name the current inner season in one sentence.`
      + `\n- Provide intro/outro. The outro must carry a seed of awareness (one of: "the candidates listed here are not all the world holds" / "there is an unseen best" / "the unexpected can later turn into insight").`
    : '\n- This is an additional candidate (2nd onward). Do not output innerSeason/intro/outro. Return only candidate.';

  return `You are Stella, the voice of Solara. Built on astrocartography (the Jim Lewis tradition),
you read the "energy present" at one offered candidate place, in light of the reader's wish.
Call yourself "Stella", or omit the first person. Never call yourself "AI" or "artificial intelligence".

[Consultation meta]
- Theme: ${themeEn} (${theme})
- Setting: ${modeEn} (${mode})${whomBlock}${wishBlock}

[How to refer to the place]
- Reference: ${place.ref}
- Rule: ${place.guidance}

[Astrological factors present at this place (nearest/strongest first. Soft and Hard are two independent energies)]
${factorLines}${relocLine}${quietGuidance}

[Time of day (local time of day only. Clock numbers and timezone names are forbidden)]
${timeSection}

[Inner season (progressions. Keep the jargon out of the narrative; use it only as a frame)]
${innerSeasonPromptTextEN(pipe.innerSeason)}${deltaSection}

🔴 Solara design principles (absolute — apply to every sentence):

1. No good/bad verdicts. Never use "lucky", "unlucky", "good/bad", "fortunate/unfortunate", "blessed".
   Soft (flow, receptivity, expansion, harmony) and Hard (friction, transformation, confrontation, deepening) are two independent energies.
   Render Hard not as "bad" but as "an invitation to face something — an opportunity that may ask for resolve".

2. Weave the narrative around at most TWO interrelated factors. If possible, layer one Soft + one Hard,
   so the reader can place themselves on the span of "flowing smoothly / carrying a challenge". If only one quality is present, don't force it (honesty). Don't touch every factor thinly and scatter.

3. Never put distance (km, "about __ km") in the narrative. Speak in the presence and quality of energy.

4. Speak of time only by local time of day (morning / midday / evening / night / late night). No clock numbers, no "JST", etc.${userBandEn ? `
   🔴 Make the reader's planned time of day, "${userBandEn}", the lead of the telling; stay with that time. Do not center it on other times (early morning / late night, etc.).` : `
   For a travel place, use the destination's local time of day. Since no time of day is specified, do not assert a particular one; if needed, present it only as "the time of day when the star lines stand out at this land".`}

5. Lay the inner season over the land's energy: "right now you are in a season of …, so this land's quality meets you as …".
   Do not instruct ("you should"). Only "where you are now" + "how the land meets that".

6. No mind-reading (principle 5): never state another person's private feelings as fact
   ("he thinks …" is forbidden). Instead convert it into "what you notice, how you move, and when you move". Read the reader's own placements, the energy reaching them, and what to be aware of — concretely, warmly, without dodging.

7. Hybrid register: energy description (the scene, the quality of the lines) = observation (plain, declarative).
   Address to the reader = gentle (warm, second person). Do not mix the two inside one paragraph; switch by block.

8. Do not open with a nickname or salutation (occasionally fine later). The reader's name is not provided.
   If a relational term (wife / husband / friend, etc.) appears in the free text, you may prefer that term.

9. characterHeadline = a short headline of this place's single strongest element (aim for ~6 words).
   The hook that, with three placed side by side, makes "a different invitation" obvious at a glance. For a quiet place, be honest ("a quiet place, theme lines far").

10. energyLabels = an array of "{planet} {angle/band} · {a 3-7 word character}". Unfold the factors above.
    e.g. "Venus MC · an axis of love and harmony" / "Mars ASC · the body of breakthrough".

11. 🔴 Safety guard: give no definitive medical, legal, financial, investment, or self-harm advice.
    If the consultation text (theme / with whom / wish) touches these areas (health, money, contracts, crisis),
    stay only within astrological imagery and gently suggest consulting an appropriate professional.
    For major life decisions too (relocation, career change, divorce, childbirth), read astrology "as a mirror of your awareness"
    and make clear the final decision is the reader's own. "Will", "definitely", "you should" are forbidden.${firstOnlyRule}

12. The theme (healing / love, etc.) is already chosen by the reader. Do not guess their motive ("perhaps you are seeking …").
    Take the theme as given and tell how this land meets that theme.${deltaRule}
${styleVoiceFor(lang)}${outputLangDirective(lang)}

[Output JSON format (return nothing else. No markdown, no code fences)]
{${firstOnlySchema}
  "candidate": {
    "characterHeadline": "<a feature headline, aim for ~6 words>",
    "energyLabels": ["<planet angle · character>", ...],
    "narrative": "<160-230 words. Observation (plain) + address (gentle), hybrid. Centered on the nearest 1-2 factors, with a Soft+Hard span if possible. No km. Lay the inner season over it. No mind-reading>"${deltaSchemaLine}
  }
}`;
}

function staticFallbackEN(pipe) {
  const c = pipe.candidate;
  const place = placeReferenceEN(c);
  const factors = c.factors || [];
  const energyLabels = factors.map((f) => {
    const planet = PLANET_EN[f.planet] || f.planet;
    if (f.kind === 'band') return `${planet} ${f.aspect === 'zenith' ? 'zenith band' : 'nadir band'}`;
    return `${planet} ${(ANGLE_EN[f.angle] || f.angle).replace(/\(.*\)/, '').trim()} ${ASPECT_EN[f.aspect] || ''}`.trim();
  });
  const headline = factors.length
    ? `a place where ${PLANET_EN[factors[0].planet] || factors[0].planet}'s ${factors[0].kind === 'band' ? 'band' : (ANGLE_EN[factors[0].angle] || '').replace(/\(.*\)/, '').trim()} is present`
    : 'a quiet place, theme lines far';
  const narrative = factors.length
    ? `${place.ref}. Stella's voice isn't reaching right now, so here is the objective picture of the energy present.`
    : `${place.ref} is a quiet, neutral place with no theme-matching line close by.`;

  const candidateOut = { name: c.name, characterHeadline: headline, energyLabels, narrative };
  if (c.timeDelta) {
    candidateOut.deltaAfter = { deltaMin: c.timeDelta.deltaMin, changes: c.timeDelta.changes, narrative: '' };
  }
  const out = { candidate: candidateOut, fallback: true };
  if (pipe.isFirst) {
    out.innerSeason = '';
    out.intro = `I've gathered the candidates for your ${MODE_EN[pipe.meta?.mode] || 'outing'}.`;
    out.outro = 'The candidates listed here are not all the world holds. Unseen places, too, may one day turn into insight.';
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
  const isNonJa = lang !== 'ja';

  // Phase 1: 秘伝計算 (候補プールは D1。env を渡す。binding 無し時は worldCities フォールバック)
  const pipe = await runPipeline(body, env);

  // これ以上候補が無い (excluded で出し尽くした / 静かな場ばかり / プール空)。
  // 案Y: 正直に止めて代替提案を返す。exhausted:true なので index.js は課金しない。
  if (!pipe.candidate) {
    return {
      exhausted: true, remainingAfter: 0,
      exhaustedReason: pipe.exhaustedReason || null,
      suggestions: pipe.suggestions || [],
      meta: pipe.meta,
    };
  }

  // おでかけの予定時間帯 (任意)。既知バケツのみ採用 (不正値は無視)。
  // 2026-05-29: narrative は userTimeBand を主役にする一方で UI ラベルだけ
  // エンジン計算 (角通過時刻) の bucket を出していたため、本文「夜」/ラベル「昼」のズレが発生。
  // userTimeBand が指定されている時は UI 表示用 timeWindow もユーザー選択に合わせる。
  const VALID_BANDS = ['morning', 'midday', 'evening', 'night', 'lateNight'];
  const rawBand = body && body.when && body.when.timeBand;
  const userTimeBand = VALID_BANDS.includes(rawBand) ? rawBand : null;
  const timeWindow = userTimeBand
    ? { kind: 'single', bucket: userTimeBand, label: (isNonJa ? BUCKET_EN[userTimeBand] : BUCKET_JP[userTimeBand]) || userTimeBand }
    : (isNonJa ? humanizeTimeWindowEN(pipe.timeWindow) : humanizeTimeWindow(pipe.timeWindow));

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
      placeKind: pipe.candidate.placeKind || null,
      lat: pipe.candidate.lat, lng: pipe.candidate.lng,
      country: pipe.candidate.country, region: pipe.candidate.region,
      // 実在の町 (D1 局所) の表示用方角・距離 (本文には出さない、UI バッジ用)。
      directionFromHome: pipe.candidate.directionFromHome || null,
      directionCode: pipe.candidate.directionCode || null,
      distanceKm: pipe.candidate.distanceKm ?? null,
    },
    timeWindow,
    meta: pipe.meta,
  };

  if (!env.GEMINI_API_KEY) {
    return { ...base, ...(isNonJa ? staticFallbackEN(pipe) : staticFallback(pipe)), model: 'fallback' };
  }

  const primary = env.CONSULTATION_MODEL_PRIMARY || env.FORTUNE_MODEL_PRIMARY || 'gemini-2.5-flash';
  const fallbackModel = env.CONSULTATION_MODEL_FALLBACK || env.FORTUNE_MODEL_FALLBACK || 'gemini-flash-latest';
  const models = primary === fallbackModel ? [primary] : [primary, fallbackModel];

  const prompt = (isNonJa ? buildConsultationPromptEN : buildConsultationPrompt)({ pipe, theme, mode, withWhom, wish, userTimeBand, lang });

  let parsed;
  try {
    const raw = await callGeminiFn(env.GEMINI_API_KEY, prompt, models, {
      // 🔴 2026-06-02 実測: 相談も「決定論的に選んだ候補地のナレーション」で Gemini は推論しない。
      // thinking 512 vs 0 を 5テーマ厳密比較 → 全件 STOP/JSON妥当・品質同等 (0 の方が簡潔)・40%減
      // (¥0.48→¥0.29)。fortune/tarot と同じく thinkingBudget:0 (真に OFF)。
      thinkingBudget: 0,
      maxOutputTokens: 4096, // 候補1つ + (初回のみ intro/outro/innerSeason)。安全網 (thinking:0 で実害~570tok)
      retries: 1,
    });
    try { parsed = JSON.parse(raw); }
    catch { parsed = JSON.parse(raw.replace(/^```json\s*|\s*```$/g, '').trim()); }
  } catch (_) {
    return { ...base, ...(isNonJa ? staticFallbackEN(pipe) : staticFallback(pipe)), model: 'fallback' };
  }

  const ai = (parsed && parsed.candidate) || {};
  const td = pipe.candidate.timeDelta || null;
  const out = {
    ...base,
    candidate: {
      ...base.candidateMeta,
      characterHeadline: typeof ai.characterHeadline === 'string' ? ai.characterHeadline : '',
      energyLabels: Array.isArray(ai.energyLabels) ? ai.energyLabels : [],
      narrative: typeof ai.narrative === 'string' ? ai.narrative : '',
      timeWindow,
      // 30 分後デルタ (Pro 時刻指定時のみ)。changes=構造データ / narrative=Stella の言葉。
      ...(td ? {
        deltaAfter: {
          deltaMin: td.deltaMin,
          changes: td.changes,
          narrative: typeof ai.deltaAfter === 'string' ? ai.deltaAfter : '',
        },
      } : {}),
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
  deltaPromptSection,
  // 非 ja 言語版 (英語土台 + 出力言語ディレクティブ + 言語別の声)。
  buildConsultationPromptEN, placeReferenceEN, staticFallbackEN, humanizeTimeWindowEN,
};
