# Solara perf_audit

Android アプリの **負荷を網羅的に計測する Python ツール**。
CPU / Memory / GPU(Frame) / Battery / Network / GPS / Sensor / fd / I/O など、
`dumpsys` と `/proc/<pid>/` から取れる主要メトリクスを **シナリオに従って polling 計測** し、
Markdown レポートを生成します。

Phase 1 では `dumpsys` + `/proc` 系を実装しています。Phase 2 で Perfetto trace を統合予定。
iOS は将来対応（`collectors/ios/` 雛形あり）。

## 必要環境

- Python 3.11+ (3.13 で動作確認)
- `pip install pyyaml click`
- `adb` (Android SDK Platform Tools)
- 計測対象アプリは **debuggable APK** (release だと `proc` collector が動かない、`run-as` 不可)

既定の adb path は `C:\Users\cojif\AppData\Local\Android\sdk\platform-tools\adb.exe`。
別パスは `--adb` か環境変数 `ADB_PATH` で上書き可。

## クイックスタート

```bash
# A101FC で起動直後 30 秒だけ計測
python apps/solara/tools/perf_audit/run.py -d a101fc -s cold_start

# 30 分手動放置で leak / 常時消費を検出
python apps/solara/tools/perf_audit/run.py -d a101fc -s idle_30min

# Map ACG モードで 30 分使用時の負荷
python apps/solara/tools/perf_audit/run.py -d a101fc -s map_acg_30min
```

レポートは `apps/solara/tools/perf_audit/reports/<device>_<scenario>_<timestamp>.md` に出力。

## CLI オプション

| オプション | 説明 | 例 |
|---|---|---|
| `-d, --device` | `presets/devices.yaml` の key | `a101fc`, `pixel8`, `so41b` |
| `-s, --scenario` | シナリオ名 or YAML path | `cold_start`, `idle_30min` |
| `-p, --profile` | 計測プロファイル | `quick` / `standard` / `full` (default) |
| `--collectors` | コレクター個別指定 (profile 上書き) | `dumpsys.meminfo,proc.fd` |
| `--skip` | 個別除外 | `dumpsys.batterystats_pkg,dumpsys.sensorservice` |
| `--duration` | シナリオ長を上書き (秒) | `60` |
| `--interval` | poll 間隔を上書き (秒) | `10` |
| `--adb` | adb path | `C:\Android\platform-tools\adb.exe` |
| `--out` | 出力ディレクトリ | `./my_reports` |
| `--quiet` | 進捗表示抑制 | |

## プロファイル

`presets/devices.yaml` 内 `profiles:` セクションで定義。

| profile | 含まれるコレクター | 用途 |
|---|---|---|
| `quick` | meminfo, gfxinfo, cpuinfo, proc.fd, proc.status | 起動直後の動作確認、軽い計測 |
| `standard` | + framestats, batterystats, netstats, activity, proc.io, proc.smaps | 通常使用想定の本格計測 |
| `full` | + sensorservice, location | 全カテゴリ (default) |

## デバイス追加方法

`presets/devices.yaml` の `devices:` に新規 key を追加:

```yaml
devices:
  myphone:
    name: "MyPhone XYZ"
    serial: "abc12345"  # adb devices で表示される ID。空なら auto-detect (1台のみ接続時)
    platform: android
    android_version: "15"
    sdk_api: 35
    ram_gb: 12
    gpu: "Adreno 750"
    package: com.solodevlab.solara
    notes: "..."
    caps_skip: []  # 未対応 collector があれば指定 (例: 'dumpsys.gfxinfo_framestats')
```

## シナリオ追加方法

`scenarios/` に YAML を追加:

```yaml
name: my_scenario
description: 何を見たいかの説明
duration_sec: 600
poll_interval_sec: 30
operations:
  - type: instruction
    message: "ユーザーへの操作指示"
  - type: prompt_enter
    message: "Press Enter to start..."
  - type: launch                     # アプリ起動 (am start 経由)
  - type: poll
    duration_sec: 600                # poll 時間 (省略時はトップレベル duration_sec)
```

操作種別:
- `instruction` — メッセージ表示のみ
- `prompt_enter` — Enter 押下まで停止
- `launch` — `monkey -p <pkg>` でアプリ起動
- `poll` — 指定時間内、`poll_interval_sec` ごとに全 collector を実行

## コレクター

### dumpsys 系 (`collectors/android/dumpsys.py`)

| key | 取得内容 |
|---|---|
| `dumpsys.meminfo` | Pss / Java / Native / Graphics heap |
| `dumpsys.gfxinfo` | Frame jank %, p50-99 percentile |
| `dumpsys.gfxinfo_framestats` | 直近 120 frame の per-frame timing |
| `dumpsys.batterystats_pkg` | 当該 package の battery 消費内訳 |
| `dumpsys.netstats` | UID 単位の RX/TX byte 累計 |
| `dumpsys.sensorservice` | 使用中 sensor とサンプリングレート |
| `dumpsys.location` | GPS / network location active client |
| `dumpsys.cpuinfo` | プロセス CPU% (user/kernel) と load avg |
| `dumpsys.activity_processes` | プロセス state / oom_adj / foreground |

### proc 系 (`collectors/android/proc.py`)

| key | 取得内容 | 備考 |
|---|---|---|
| `proc.fd` | fd 総数 + symlink target 別カテゴリ集計 | A101FC fd leak 指標 |
| `proc.status` | VmPeak / VmRSS / VmHWM / Threads / FDSize | |
| `proc.io` | read/write bytes / syscall count | |
| `proc.smaps_rollup` | smaps 集計 Pss / Anon / Swap | |

すべて `run-as` 経由なので **debuggable APK 限定**。release build では `proc` 系は skip。

## レポートの比較 (compare.py)

2 つのレポートを side-by-side で比較する CLI。debug build vs profile build、
修正前 vs 修正後、A101FC vs Pixel 8 等を一発で見比べる用。

```bash
python apps/solara/tools/perf_audit/analyzers/compare.py \
  --left  apps/solara/tools/perf_audit/reports/a101fc_idle_30min_20260504_000428.md \
  --right apps/solara/tools/perf_audit/reports/a101fc_idle_30min_20260504_004500.md \
  --label-left  debug \
  --label-right profile \
  --out   apps/solara/tools/perf_audit/reports/compare_debug_vs_profile.md
```

出力内容:
- **Conditions** 表 — 計測条件 (Device / Scenario / Started / 等) を並列表示
- **Summary side-by-side** — 共通メトリクスを 9 列で比較 (各 First/Last/Δ + Last Δ% + Verdict)
- **Highlights** — 差分 10% 以上を絶対値順に列挙、↑↓ + (低下/増加/大幅...) で要点抽出

注意: 片方だけに含まれる collector のメトリクス (例: profile で `proc` skip) は
"(L 取得失敗)" / "(R 取得失敗)" と表示される。

## レポートの読み方

レポートには 3 つのセクション:

1. **Header** — device / scenario / 計測条件
2. **Summary — first / last / delta** — 主要メトリクスの推移サマリ
   - `↑` = +5%以上 増加 (leak 疑い候補)
   - `↓` = -5%以上 減少
   - `→` = ほぼ変化なし
3. **Time series by category** — category 別の時系列テーブル
   - `fd` は target 別 breakdown も付加 (first / last 比較で何が増えたか分かる)

## 既知の制約

- **release build で proc collector が動かない** — `run-as` 必要、debuggable のみ
- **Android 11 (SO-41B) で `gfxinfo framestats` の出力が異なる** — `caps_skip` で除外推奨
- **Pixel 8 / SO-41B の serial は未設定** — auto-detect (1台のみ接続時) または yaml に追記
- **batterystats は `--reset` していない** — 累積値なので絶対値はあてにせず差分で見る
- **Perfetto trace 未統合 (Phase 2 予定)** — CPU sched / GPU 詳細は Phase 1 では取れない
- **シナリオ自動操作なし** — UI 操作は手動 (壊れにくい設計、Solara は UI 改修頻繁のため)

## トラブルシューティング

**`adb: command not found`**
→ Windows: フルパスで実行か `--adb` 指定。bash で `adb.exe` を PATH に。

**`No device connected via adb`**
→ `adb devices -l` で接続確認。USB debugging ON、unauthorized なら端末側で許可。

**`run-as not available (release/non-debuggable build?)`**
→ debug build を `flutter run` 等で入れ直す。release APK では proc 系不可。

**`dumpsys batterystats` がほぼ空**
→ 充電中だと記録されない。USB 抜いて (PC 側 `adb tcpip 5555` + Wi-Fi adb 推奨)、または `dumpsys batterystats --reset` 後に時間置く。

## ソース構成

```
apps/solara/tools/perf_audit/
├── run.py                       # CLI エントリ
├── presets/devices.yaml         # 端末プロファイル + collector profile 定義
├── scenarios/                   # 計測シナリオ
├── collectors/
│   ├── base.py                  # Collector / AndroidCollector 抽象基底
│   ├── android/
│   │   ├── dumpsys.py           # dumpsys 全サービス
│   │   └── proc.py              # /proc/<pid>/{fd,status,io,smaps_rollup}
│   └── ios/                     # 将来対応
├── analyzers/
│   └── report.py                # Markdown レポート生成
└── reports/                     # 出力 (gitignore 推奨)
```

## 今後の拡張 (Phase 2 / 3)

- **Perfetto trace 統合** — `adb shell perfetto` の自動取得 + `trace_processor` SQL 解析
- **Pixel 8 / SO-41B 対応** — capability check 強化
- **8 時間夜間 leak 検出シナリオ** — overnight_8h.yaml
- **Worker access log との突合** — Cloudflare Worker call rate
- **iOS 対応** — `xctrace` (Instruments) ベース
- **CI 連携** — Phase 修正前後の自動回帰チェック
