
# HTMLを修正したら仕様書を再生成
python tools/html_spec_generator.py

# Flutter移植前に重複・未使用を確認
python tools/dead_code_detector.py

# 特定画面だけ分析
python tools/dead_code_detector.py --screen galaxy

このPythonスクリプトで綺麗にできる。

### すぐやるもの（docs で管理）

プロジェクト内に `docs/` フォルダを作って、テキストで管理する。
apps/solara/docs/
  architecture.md    ← 1. 共通モジュール方針・状態管理ルール
  data_schema.md     ← 2. DB構造・APIバージョン・マイグレーション方針
  security.md        ← 6. APIキー管理方針・ロジック保護方針
  legal.md           ← 9. プライバシーポリシー・免責文言・特商法
  release_checklist.md ← 3. リリース前に確認すること一覧

### ストアに出す前にやるもの（外部サービス）

Firebase           ← 5. Analytics + Crashlytics（半日で導入）
GitHub Actions     ← 3. 自動ビルド + テスト（1日で構築）
RevenueCat         ← 4. 課金基盤（課金機能実装時に導入）

### 日常運用（GitHub Issues で管理）

7. 運用・保守
  → 月1回「依存パッケージ更新」のIssueを自動作成
  → Crashlyticsでクラッシュ検知 → 自動でIssue作成
  → ストアレビュー対応テンプレート


### 既にあるもの（memory/）ここにある
8. 成長戦略
  → strategy_roadmap.md（既存）
  → project_adsense.md（既存）


## こういう運用になる
HTMLモック → dead_code_detector.py で手動チェック（コンパイラがないから）
Flutter    → flutter analyze が自動で警告してくれる（コンパイラがあるから）

## Flutterの更新手順
1. 仕様書 (specs/) を見て、HTMLの現在の正しい仕様を確認
2. Flutterの該当箇所を修正
3. 古いコードを消す（Dartは未使用なら警告が出る）
4. flutter analyze で問題がないか確認
5. 変更ログ (changelog_*.md) の Flutter反映済みを YES に更新

