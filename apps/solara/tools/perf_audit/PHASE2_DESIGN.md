# Phase 2 設計 — Perfetto trace 統合

> Status: 設計のみ、未実装。Phase 1 (dumpsys + /proc) MVP 完成後の次フェーズ。

## 目的

Phase 1 (`dumpsys` + `/proc`) では取れない以下を Perfetto trace 経由で取得する:

- **Per-thread CPU 内訳** — Solara の thread (UI / Raster / IO / Dart Worker) のどれが CPU を食ってるか
- **CPU 周波数履歴** — thermal throttling の可視化、周波数低下と jank の相関
- **GPU 周波数 / 使用率**
- **Frame timeline** — どの frame が janky だったか per-frame で
- **Heap callstack profile** — native heap の callstack 別 alloc 量 (leak の発生源特定)
- **Wakelock / Wakeup events** — 時系列で
- **atrace タグ** — Flutter Engine の UTRACE: 経由で build / paint / setState 等の内部 trace event

## なぜ必要か

Phase 1 計測 (2026-05-04) で:
- 「Pkg CPU 123% 漸増」を観測したが、**どの thread が食ってるか分からない**
- 「BLAST 警告増えた」体感の原因究明には **frame timeline + sched_switch** が必要
- Heap leak の発生源は smaps_rollup の Pss 集計だけでは特定不可、**callstack profile** 必要
- ユーザーの根本要件「最新情報取得して細かく取得しないといいアプリが作れない」 = Perfetto 必須

## ツール構成

### Device side
- **`/system/bin/perfetto`** — Android 9+ 標準搭載
  - A101FC (Android 14) / Pixel 8 (Android 15) / SO-41B (Android 11) 全て対応
  - `adb shell perfetto -c <config> -o /data/misc/perfetto-traces/<file>`
  - 30 分 trace で 100-500 MB のバイナリ (protobuf)

### Host side
- **`pip install perfetto`** — `trace_processor` Python ライブラリ
- `TraceProcessor("trace.pb")` で trace を **SQL でクエリ可能**
- 例:
  ```python
  from perfetto.trace_processor import TraceProcessor
  tp = TraceProcessor("trace.pb")
  result = tp.query("SELECT ts, value FROM counter WHERE name='cpu_freq'")
  ```

## ディレクトリ追加

```
apps/solara/tools/perf_audit/
├── collectors/android/
│   └── perfetto.py              # PerfettoCollector (新規)
├── analyzers/
│   └── trace_query.py           # trace_processor SQL wrapper (新規)
├── presets/
│   └── perfetto_config.pbtxt    # Perfetto data source 設定 (新規)
└── reports/
    └── traces/                  # trace.pb の保存先 (gitignore 済)
```

## 実装計画

### Step 1: `presets/perfetto_config.pbtxt` 作成

取得する data source を textproto で指定:

```protobuf
buffers: {
  size_kb: 65536          # 64 MB ring buffer (30 分計測想定)
  fill_policy: RING_BUFFER
}

data_sources: {
  config: {
    name: "linux.ftrace"
    ftrace_config: {
      ftrace_events: "sched/sched_switch"      # context switch
      ftrace_events: "sched/sched_wakeup"      # wakeup events
      ftrace_events: "power/cpu_frequency"     # CPU freq history
      ftrace_events: "power/cpu_idle"          # idle states
      ftrace_events: "power/wakeup_source_activate"
      atrace_categories: "gfx"
      atrace_categories: "view"
      atrace_categories: "am"
      atrace_apps: "com.solodevlab.solara"     # Flutter Engine UTRACE: 取得
    }
  }
}

data_sources: {
  config: {
    name: "android.surfaceflinger.frametimeline"   # frame timeline (jank API)
  }
}

data_sources: {
  config: {
    name: "linux.process_stats"
    process_stats_config: {
      proc_stats_poll_ms: 1000
    }
  }
}

data_sources: {
  config: {
    name: "android.heapprofd"   # native heap callstack (Android 10+, debug only)
    heapprofd_config: {
      sampling_interval_bytes: 4096
      process_cmdline: "com.solodevlab.solara"
    }
  }
}

data_sources: {
  config: {
    name: "android.gpu.memory"  # GPU memory tracking (Android 12+)
  }
}

duration_ms: 1800000  # 30 分。短時間計測時は CLI 引数で上書き
```

### Step 2: `collectors/android/perfetto.py` 実装

```python
class PerfettoCollector(AndroidCollector):
    name = "perfetto"
    categories = ["sched", "cpu_freq", "gpu", "frame_timeline", "heap_callstack"]

    def __init__(self, adb, serial, package, config_path, out_dir):
        super().__init__(adb, serial, package)
        self.config_path = config_path
        self.out_dir = out_dir
        self._trace_path: Path | None = None

    def is_available(self) -> tuple[bool, str]:
        rc, out, _ = self.adb_shell("which perfetto", timeout=5)
        if rc != 0 or "perfetto" not in out:
            return False, "perfetto binary not found (Android < 9?)"
        rc, out, _ = self.adb_shell("getprop persist.traced.enable", timeout=5)
        # traced is enabled by default on user-debug builds
        return True, ""

    def start(self, duration_sec: int) -> None:
        """Start a Perfetto trace in the background. Called by scenario op."""
        device_path = "/data/misc/perfetto-traces/solara-trace.pb"
        # adb push config, then run perfetto in detached mode
        self.adb_cmd("push", str(self.config_path), "/data/local/tmp/perfetto.cfg")
        self.adb_shell(
            f"perfetto -c /data/local/tmp/perfetto.cfg --txt "
            f"-o {device_path} --background --detach=solara_trace"
        )
        self._trace_path = Path(device_path)

    def stop_and_pull(self) -> Path:
        """Stop the running trace and pull it to host."""
        self.adb_shell("perfetto --attach=solara_trace --stop")
        host_path = self.out_dir / "trace.pb"
        self.adb_cmd("pull", str(self._trace_path), str(host_path))
        return host_path

    def collect(self) -> CollectionResult:
        # No-op during polling; the trace covers the whole scenario duration
        return CollectionResult(name=self.name)
```

### Step 3: scenario YAML 拡張

新しい op type:

```yaml
operations:
  - type: perfetto_start            # シナリオ開始時に trace 開始
  - type: poll                      # 通常の dumpsys/proc サンプリング
  - type: perfetto_stop             # シナリオ終了時に trace 停止 + pull
```

`run.py` の op dispatcher に `perfetto_start` / `perfetto_stop` を追加。

### Step 4: `analyzers/trace_query.py` 実装

trace_processor SQL のラッパー:

```python
class TraceAnalyzer:
    def __init__(self, trace_path: Path, package: str):
        from perfetto.trace_processor import TraceProcessor
        self.tp = TraceProcessor(str(trace_path))
        self.package = package

    def per_thread_cpu_time(self) -> dict[str, int]:
        """Solara プロセスの thread 別 CPU 時間 (ns) を集計。"""
        rows = self.tp.query(f"""
          SELECT thread.name AS thread_name, SUM(sched.dur) AS cpu_ns
          FROM thread JOIN sched USING (utid)
          WHERE upid IN (SELECT upid FROM process WHERE name = '{self.package}')
          GROUP BY thread.name
          ORDER BY cpu_ns DESC
        """)
        return {r["thread_name"]: r["cpu_ns"] for r in rows}

    def cpu_freq_stats(self) -> dict[int, dict]:
        """CPU 0..N の周波数の min/max/avg。"""
        rows = self.tp.query("""
          SELECT cpu, MIN(value) AS min_hz, MAX(value) AS max_hz, AVG(value) AS avg_hz
          FROM cpu_counter_track JOIN counter USING (id)
          WHERE name = 'cpufreq'
          GROUP BY cpu
        """)
        return {r["cpu"]: r for r in rows}

    def frame_timeline_jank(self) -> dict:
        """Frame timeline ジャンク数を frame type 別に。"""
        rows = self.tp.query(f"""
          SELECT jank_type, COUNT(*) AS n
          FROM expected_frame_timeline_slice
          WHERE upid IN (SELECT upid FROM process WHERE name = '{self.package}')
          GROUP BY jank_type
        """)
        return {r["jank_type"]: r["n"] for r in rows}

    def heap_callstack_top(self, top_n: int = 20) -> list[dict]:
        """Native heap の callstack 別 alloc サイズ top N。"""
        return self.tp.query(f"""
          SELECT name, SUM(size) AS bytes
          FROM heap_profile_allocation
          WHERE upid IN (SELECT upid FROM process WHERE name = '{self.package}')
          GROUP BY name
          ORDER BY bytes DESC
          LIMIT {top_n}
        """).as_pandas_dataframe().to_dict("records")
```

### Step 5: `report.py` に Phase 2 metrics 統合

`SUMMARY_KEYS` に追加:
```python
("perfetto_thread", "ui_thread_cpu_pct", "UI thread CPU %", "{:.2f}"),
("perfetto_thread", "raster_thread_cpu_pct", "Raster thread CPU %", "{:.2f}"),
("perfetto_cpu", "cpu0_freq_avg_mhz", "CPU0 avg freq (MHz)", "{:.0f}"),
("perfetto_frame", "jank_app_count", "Frame jank (app)", "{}"),
("perfetto_frame", "jank_sf_count", "Frame jank (SurfaceFlinger)", "{}"),
("perfetto_heap", "top_alloc_bytes", "Top callstack alloc (B)", "{:,}"),
```

`compare.py` も同様に対応 (新 metric が増えるだけなので自動で拾われる)。

## 取得項目マトリクス (Phase 1 + 2 完成後の全像)

| 指標 | Phase 1 (dumpsys/proc) | Phase 2 (perfetto) |
|---|---|---|
| Pkg CPU% | ✓ | + per-thread (UI/Raster/IO/Worker) |
| Frame jank% | ✓ (累積) | + per-frame timeline + jank type 別 |
| CPU 周波数 | ✗ | ✓ (時系列、CPU 0..N 別) |
| GPU 周波数 / 使用率 | ✗ | ✓ |
| sched_switch / wakeup | ✗ | ✓ |
| Native heap | ✓ (Pss only) | + callstack profile (top alloc 元) |
| Wakelock | ✓ (一覧のみ) | + 時系列 + duration |
| atrace タグ | ✗ | ✓ (Flutter内部 trace event = build/paint/setState) |
| Frame deadline missed | ✓ (件数のみ) | + どの frame か特定 |

## 注意点

1. **trace ファイルが巨大** — 30 分 trace で 100-500 MB、`reports/traces/` は gitignore 済前提
2. **Perfetto config の長さ制限** — 取得 source 増やすほど buffer 圧迫、ring buffer 上書きリスク
3. **trace_processor は CPU 食う** — 30 分 trace の SQL クエリで host 側 10-30 秒
4. **Heap profile は debug build 限定** (heapprofd の SDK 制限)
5. **atrace タグは Flutter Engine が UTRACE: で出してる** — Skia + Flutter 内部 timeline が見える
6. **`pip install perfetto` 必要** — host 側追加依存
7. **SO-41B (Android 11)** で動作確認必要 — Android 11 の Perfetto は機能制限あり (atrace_apps OK、heapprofd 限定)
8. **`--detach` モード** で background trace、scenario poll と並列動作
9. **trace 開始/停止のタイミング** — scenario の最初と最後で確実に揃える、エラー時の trace 強制停止が必要

## 段階的着手プラン

| Session | 内容 | 所要 |
|---|---|---|
| **A** | perfetto_config.pbtxt + PerfettoCollector + scenario op (perfetto_start/stop)、5 分 trace で動作確認 | ~1 時間 |
| **B** | TraceAnalyzer (trace_query.py) + per-thread CPU / CPU freq / frame timeline の SQL + report.py 統合 | ~1 時間 |
| **C** | 30 分 idle scenario で実 perfetto trace 取得 + Phase 1 結果と統合 | ~30 分 |
| **D** | Pixel 8 / SO-41B での動作確認 + Android 11 制限対応 | ~30 分 |

合計 **3-4 時間程度** で Phase 2 完成想定。

## 期待される成果

Phase 1 で「CPU 123% 漸増」が観測されたが、Phase 2 で:
- **どの thread が食ってるか** が判明 → 修正対象明確化
- **CPU 周波数低下** が thermal throttling の証拠として可視化
- **frame timeline で jank の発生時刻** を特定 → 何の操作が janky か結びつく
- **heap callstack** で leak 発生源を特定 → 修正コード一発

「警告増えた」体感を **数字 + 構造** で示せるようになる。
