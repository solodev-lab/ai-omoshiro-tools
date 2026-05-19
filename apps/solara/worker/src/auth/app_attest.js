/**
 * Apple App Attest 検証 — barrel re-export (設計 v3.0)。
 *
 * 旧 app_attest.js (360 行、verifyAttestation + verifyAssertion 同居) を
 * 役割別に分割した結果のエントリポイント:
 *   - attestation.js (~270 行): 端末初回登録、9 step + 時刻チェック
 *   - assertion.js   (~80 行):  毎リクエスト署名検証、4 step + signCount 抽出
 *
 * 既存の import 文 (`import { verifyAttestation, verifyAssertion } from
 * './auth/app_attest.js'`) を壊さないため、本ファイルは re-export のみ。
 * 新規追加時は直接 attestation.js / assertion.js から import しても OK。
 */
export { verifyAttestation } from './attestation.js';
export { verifyAssertion } from './assertion.js';
