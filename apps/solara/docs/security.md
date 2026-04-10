# Solara セキュリティ方針

> APIキーやユーザーデータの管理ルール。
> 新しい外部サービスを追加する時はこのファイルを確認する。

---

## 現在の状態

| 項目 | 状態 | 備考 |
|------|------|------|
| Flutterコード内のAPIキー | ✅ なし | ハードコードされたキーなし |
| CF Worker のシークレット | ✅ 安全 | wrangler secret で管理 |
| HTTPS通信 | ✅ 全てHTTPS | HTTP通信なし |
| デバッグログ | ⚠️ 未確認 | リリース前に確認必要 |
| ProGuard/R8 | ⚠️ 未確認 | リリース前に確認必要 |

---

## ルール

### 1. APIキーは絶対にソースコードに書かない

**禁止:**
```dart
// ❌ これは絶対にやらない
const apiKey = 'sk-abc123...';
final response = await http.get(Uri.parse('https://api.example.com?key=$apiKey'));
```

**正しい方法:**
```dart
// ✅ サーバー側（CF Worker）でAPIキーを持つ
// Flutter → CF Worker → 外部API
final response = await http.get(Uri.parse('https://solara-worker.xxx.workers.dev/fortune'));
// CF Worker が内部で Gemini API キーを使う
```

### 2. 独自占いロジックはサーバー側に置く

将来的に独自ロジック（姓名×タロット等）を実装する場合：
- **計算ロジック → CF Worker に置く**
- Flutter側にはUIと結果表示のみ
- 理由: APKをデコンパイルするとDartコードは読める。競合にコピーされる

### 3. ユーザーデータの保護

**SharedPreferencesの注意点:**
- SharedPreferencesは**暗号化されていない**（プレーンテキスト）
- root化された端末では読み取り可能
- 現時点では占いプロフィール程度なのでリスクは低い
- **将来、課金情報やトークンを保存する場合は `flutter_secure_storage` を使う**

### 4. 外部API利用のルール

| API | User-Agent | レート制限 | 注意 |
|-----|------------|-----------|------|
| Nominatim | `SolaraApp/1.0` | 1req/秒 | 商用利用時はタイルサーバー自前運用を検討 |
| CartoDB タイル | なし | なし | 利用規約に従う |
| CF Worker | なし | Cloudflare Free: 100,000 req/日 | 超過時は有料プランに移行 |

### 5. 署名キーの管理

- **keystore ファイルはGitに含めない**（.gitignore に追加済みか確認）
- パスワードは安全な場所に保管（1Password等）
- keystore を紛失するとアプリのアップデートが不可能になる

---

## 新しいサービスを追加する時のチェックリスト

- [ ] APIキーがソースコードに含まれていないか？
- [ ] APIキーをCF Worker経由で使えるか？
- [ ] ユーザーデータを外部に送信していないか？
- [ ] HTTPS通信を使っているか？
- [ ] レート制限を確認したか？
- [ ] 利用規約を確認したか？
