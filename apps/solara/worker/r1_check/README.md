# R1 検証用 minimal Worker

App Attest 設計 v1.4 の **R1: `@peculiar/x509` + 自前 CBOR + `node:crypto.createVerify` の 3 操作が Cloudflare Workers (`nodejs_compat`) で動くか** を実機検証するための test worker。

**本番には絶対 deploy しない** (`workers_dev = false`、custom domain なし)。

## 起動 + 確認

```bash
cd apps/solara/worker
npx wrangler dev --config r1_check/wrangler.toml --port 8788 --local
# 別ターミナルで:
curl http://127.0.0.1:8788/r1/all | jq
```

## 検証履歴

| 日付 | wrangler | @peculiar/x509 | 結果 |
|---|---|---|---|
| 2026-05-19 | 4.92.0 | 1.14.3 | ✅ 3 操作全パス (x509 self-verify / cbor decode / createVerify DER 71B) |

## 残置理由

- Apple SDK / @peculiar/x509 / wrangler の major version 上がった時に再検証用
- 将来 Workers の `node:crypto.X509Certificate` が GA したら、X.509 を node:crypto 側に切り替える比較ベンチマーク用
- 削除しても本番 worker (`src/index.js`) には影響ゼロ

## 関連
- 設計: `apps/solara/docs/app_attest_design.md` §10 R1
