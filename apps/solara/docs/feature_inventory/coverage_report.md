# Solara feature inventory — Coverage Report

> 機械抽出 ↔ ドキュメント / Worker ↔ Flutter の対整合チェック結果。
> このファイルは extract.py が再生成する。手で編集しないこと。

## #3 Worker ↔ Flutter エンドポイント対整合

- Worker 側に定義された path: **14**
- Flutter から呼ばれている path リテラル: **11**

### Worker → Flutter 漏れ (Worker にあるが Flutter から呼出無し)

- `/astro/line-narrative`
- `/astro/predict`
- `/health`

### Flutter → Worker 漏れ (Flutter が呼ぶが Worker に定義無し)

> 注意: Flutter リテラルにテンプレ展開 `${var}` を含むものは検出精度低。

- (該当なし)

### 一致 (= 健全)

- `/astro/chart`
- `/astro/daily-transits`
- `/astro/events`
- `/astro/forecast`
- `/fortune`
- `/relocation`
- `/search`
- `/tarot`
- `/tiles/*`
- `/tiles/osm/*`
- `/tz`

## #1 / #2 機械抽出 ↔ feature_inventory.md (人手版) の対整合

> `apps/solara/docs/feature_inventory.md` がまだ存在しない。
> 人手版ファイル作成後に再実行すると、ここに class/関数名の漏れチェック結果が出る。
## #4 画面 ↔ 機能集合

### 層 4a: Map 画面

- ファイル数: 25
- Worker URL 呼出: ['/astro/chart', '/search', '/tiles/osm/hot/', '/tiles/osm/hot/0/0/0']
- Popup/Dialog: `showInfoPopup`×14, `showLineNarrativeSheet`×3, `showSolaraDatePicker`×1
- Navigator.push 等: 0 箇所

### 層 4b: Horoscope 画面

- ファイル数: 25
- Worker URL 呼出: (なし)
- Popup/Dialog: `showInfoPopup`×2
- Navigator.push 等: 0 箇所

### 層 4c: Observe (Tarot) 画面

- ファイル数: 5
- Worker URL 呼出: (なし)
- Popup/Dialog: (なし)
- Navigator.push 等: 0 箇所

### 層 4d: Galaxy 画面

- ファイル数: 5
- Worker URL 呼出: (なし)
- Popup/Dialog: `showInfoPopup`×1
- Navigator.push 等: 0 箇所

### 層 4e: Sanctuary 画面

- ファイル数: 8
- Worker URL 呼出: (なし)
- Popup/Dialog: `showInfoPopup`×3
- Navigator.push 等: 0 箇所

### 層 4f: サブ画面 (Forecast / Locations / Philosophy / Font Preview)

- ファイル数: 7
- Worker URL 呼出: (なし)
- Popup/Dialog: `showInfoPopup`×5
- Navigator.push 等: 0 箇所
