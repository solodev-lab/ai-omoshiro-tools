# Solara データ設計

> アプリが保存・取得するデータの構造を管理する。
> スキーマを変更する場合は必ずマイグレーション方針に従う。

---

## 現在のデータ保存方式

**SharedPreferences のみ**（SQLite/Hive は未使用）

保存先ファイル: `lib/utils/solara_storage.dart`

---

## データ一覧

### 1. ユーザープロフィール
- **キー**: `solara_profile`
- **形式**: JSON文字列
- **内容**:

| フィールド | 型 | 例 | 必須 |
|-----------|-----|-----|------|
| name | String | "はやしこうじ" | YES |
| birthDate | String | "1977-10-24" | YES |
| birthTime | String | "06:56" | NO（不明の場合あり） |
| birthTimeUnknown | bool | false | YES |
| birthPlace | String | "岐阜県岐阜市" | YES |
| birthLat | double | 35.4233 | YES |
| birthLng | double | 136.7607 | YES |
| timezone | int | 9 | YES |
| residence | String | "東京都" | NO |
| residenceLat | double | 35.6762 | NO |
| residenceLng | double | 139.6503 | NO |

### 2. デイリーリーディング
- **キー**: `solara_current_cycle_readings`
- **形式**: JSON配列
- **内容**: 現在のサイクルのデイリー占い結果一覧

### 3. ギャラクシーサイクル
- **キー**: `solara_galaxy_cycles`
- **形式**: JSON配列
- **内容**: 完了済みの銀河サイクル（履歴）

### 4. 月の意図（ルナーインテンション）
- **キー**: `solara_lunar_intention_{cycleId}`
- **形式**: JSON文字列
- **内容**: サイクルごとの月の意図設定

### 5. オーバーレイ表示済みフラグ
- **キー**: `solara_overlay_shown_{type}_{date}`
- **形式**: bool
- **内容**: 各オーバーレイの表示済みフラグ（日付別）

### 6. 称号診断データ
- **キー**: `solara_title_data`
- **形式**: JSON文字列
- **内容**: ユーザーの称号診断結果

---

## 外部API

### Nominatim（OpenStreetMap 地名検索）
- **URL**: `https://nominatim.openstreetmap.org/search`
- **使用箇所**:
  - Map画面: 場所検索（1件取得）
  - Sanctuary画面: 出生地検索（5件取得）
  - Sanctuary画面: 居住地検索（1件取得）
- **User-Agent**: `SolaraApp/1.0`
- **レート制限**: 1秒に1リクエスト（Nominatim利用規約）
- **注意**: 大量リクエスト時はキャッシュすること

### 地図タイル（CartoDB）
- **URL**: `https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}.png`
- **URL**: `https://{s}.basemaps.cartocdn.com/dark_only_labels/{z}/{x}/{y}.png`
- **用途**: Map画面のベースマップ

### Cloudflare Worker（未接続）
- **状態**: Worker側は存在するが、FlutterアプリからのAPI呼び出しは未実装
- **Worker場所**: `worker/` ディレクトリ
- **機能**: Gemini API による占い文生成、Google Places 検索
- **TODO**: 星読み（Horoscope）のFortune APIをWorker経由で接続する

---

## マイグレーション方針

### SharedPreferences のバージョン管理

現在バージョン管理の仕組みがない。今後のために以下を導入する：

```
キー: solara_schema_version
値: 整数（現在は 1）
```

**スキーマを変更する場合:**
1. `solara_schema_version` の値を +1 する
2. アプリ起動時にバージョンを確認
3. 古いバージョンの場合、マイグレーション関数を実行
4. 変更内容をこのファイルに記録する

### 変更履歴

| バージョン | 日付 | 変更内容 |
|-----------|------|---------|
| 1 | 初期 | 初期スキーマ（現在の状態） |
