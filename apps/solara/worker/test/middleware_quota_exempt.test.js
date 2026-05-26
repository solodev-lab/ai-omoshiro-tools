// Test: isQuotaExemptPath (2026-05-26 追加)
//
// クォータ対象外パスの判定ロジック。残数照会 (/consultation/credits) は
// AI 呼出ゼロなのでクォータ対象外、AI 実行系 (/tarot /consultation2 等) は対象。
// 詳細は src/index.js の isQuotaExemptPath() の docstring 参照。

import { describe, it } from 'node:test';
import assert from 'node:assert/strict';

import { isQuotaExemptPath } from '../src/index.js';

describe('isQuotaExemptPath', () => {
  describe('対象外 (true を返す = クォータ skip)', () => {
    it('/protected/consultation/credits は対象外 (残数照会・AI なし)', () => {
      assert.equal(isQuotaExemptPath('/protected/consultation/credits'), true);
    });
  });

  describe('対象 (false を返す = クォータ消費)', () => {
    it('/protected/astro/consultation2 は対象 (Stella 相談・AI 呼出)', () => {
      assert.equal(isQuotaExemptPath('/protected/astro/consultation2'), false);
    });

    it('/protected/tarot は対象 (Tarot リーディング・AI 呼出)', () => {
      assert.equal(isQuotaExemptPath('/protected/tarot'), false);
    });

    it('/protected/fortune は対象 (Pro Fortune 占い・AI 呼出)', () => {
      assert.equal(isQuotaExemptPath('/protected/fortune'), false);
    });

    it('/protected/relocation は対象 (Pro Relocation 解説・AI 呼出)', () => {
      assert.equal(isQuotaExemptPath('/protected/relocation'), false);
    });

    it('/protected/account/delete は対象 (重操作・DDoS 防護)', () => {
      assert.equal(isQuotaExemptPath('/protected/account/delete'), false);
    });
  });

  describe('エッジケース', () => {
    it('似たパス /protected/consultation/credits/foo は対象 (= 厳密一致)', () => {
      assert.equal(
        isQuotaExemptPath('/protected/consultation/credits/foo'),
        false,
      );
    });

    it('末尾スラッシュ /protected/consultation/credits/ は対象 (=厳密一致)', () => {
      assert.equal(
        isQuotaExemptPath('/protected/consultation/credits/'),
        false,
      );
    });

    it('public パスは対象 (本来 middleware 通らないが念のため)', () => {
      assert.equal(isQuotaExemptPath('/public/astro/chart'), false);
    });

    it('空文字は対象', () => {
      assert.equal(isQuotaExemptPath(''), false);
    });
  });
});
