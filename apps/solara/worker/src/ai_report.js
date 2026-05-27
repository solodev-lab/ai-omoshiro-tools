/**
 * AI 出力ユーザー報告 — Google Generative AI Apps Policy (2026-04-15 全面施行) 対応。
 *
 * 設計根拠: apps/solara/docs/store_compliance.md §3.1
 *
 * Google Play は「AI 生成コンテンツを出すアプリは、ユーザーが不適切な出力を
 * **アプリ内で** 報告できる UI を必須化」と要求。Solara は Stella 相談 / Tarot /
 * Horo の 3 経路で Gemini を呼び出すため、各結果画面に「報告」ボタンを設置し、
 * 押されたら本 endpoint へ送信する。
 *
 * オーナー判断 (2026-05-28):
 *   保存先 = console.warn 経由で Cloudflare Workers Logs のみ (永続保存はしない)。
 *   - CF Dashboard > Workers > solara-api > Logs で「[AI_REPORT]」で検索可
 *   - 保存期間: Free 3 日 / Paid 7 日。Solara 公開初期は報告量も少ない想定で十分。
 *   - パターン検知が必要になったら、別途 DO 保存への昇格を検討。
 *
 * 文字数 cap:
 *   - feature/reason: 32 文字 (enum 想定だが防御的に切る)
 *   - freeText: 500 文字 (ユーザー自由記述)
 *   - outputText: 2000 文字 (AI 出力本体、Solara の最長 Horo/Tarot/Stella 1 回答想定)
 *   - 合計 ~2.5KB / 報告。CF Logs 1 行に収まる。
 *
 * 報告された PII 保護:
 *   - appUserId は middleware が注入する RC 匿名 ID のみ。氏名・出生情報は送らない。
 *   - 結果テキスト内に AI が生成したユーザー名等が混入する可能性は残るが、
 *     報告経路でしか送られないため通常運用では問題なし。
 */

/**
 * @param {object} body { feature, reason, freeText, outputText, __appUserId }
 * @returns {{ok:true, ts:string}}
 */
export function handleAiReport(body) {
  const ts = new Date().toISOString();
  const safe = {
    ts,
    feature: typeof body.feature === 'string' ? body.feature.slice(0, 32) : '(none)',
    reason: typeof body.reason === 'string' ? body.reason.slice(0, 32) : '(none)',
    freeText: typeof body.freeText === 'string' ? body.freeText.slice(0, 500) : '',
    outputText: typeof body.outputText === 'string' ? body.outputText.slice(0, 2000) : '',
    appUserId: typeof body.__appUserId === 'string' ? body.__appUserId : '(anon)',
  };
  // console.warn にすることで CF Logs の「warnings」フィルタで絞り込み可能
  // (info より上の severity を見るオーナーの運用に最適化)。
  console.warn('[AI_REPORT]', JSON.stringify(safe));
  return { ok: true, ts };
}
