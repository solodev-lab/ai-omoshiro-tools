"""CF Logs Explorer 形式 (workers-logs) の wrangler tail JSON 分析。

オーナー指示:
  1. 高速連打 (時間的に密な連続呼出) を漏れなく検出
  2. 電波状態悪化 = ネットワークエラー由来の異常を抽出
  3. 5xx / 4xx / outcome!=ok / exception を全件
  4. requestId 単位で worker → DO チェーンを再構成、長すぎる/失敗チェーンを特定
"""

from __future__ import annotations
import json
import sys
from collections import Counter, defaultdict
from datetime import datetime, timezone, timedelta

LOG_PATH = sys.argv[1] if len(sys.argv) > 1 else r"C:\Users\cojif\Downloads\logs-2026-05-28T15_23_30.272Z.json"


def load(path: str):
    with open(path, "r", encoding="utf-8") as f:
        raw = f.read().strip()
    if raw.startswith("["):
        return json.loads(raw)
    return [json.loads(line) for line in raw.splitlines() if line.strip()]


def parse_ts(s: str) -> float:
    """ISO 8601 → ms since epoch (UTC)."""
    dt = datetime.fromisoformat(s.replace("Z", "+00:00"))
    return dt.timestamp() * 1000


def jst(ms: float) -> str:
    return (datetime.fromtimestamp(ms / 1000, tz=timezone.utc) + timedelta(hours=9)).strftime("%H:%M:%S.%f")[:-3]


def jst_full(ms: float) -> str:
    return (datetime.fromtimestamp(ms / 1000, tz=timezone.utc) + timedelta(hours=9)).strftime("%Y-%m-%d %H:%M:%S.%f")[:-3]


def extract(e):
    """event から { ts, url, path, method, status, outcome, entrypoint, requestId, isDo, exceptions, logs } を抽出。"""
    w = e.get("$workers") or {}
    ev = w.get("event") or {}
    req = ev.get("request") or {}
    resp = ev.get("response") or {}
    url = req.get("url") or ""
    # path は workers が付与してくれている
    path = req.get("path") or url
    # url のホスト判定: https://do/ なら worker → DO 呼出 (内部)
    is_do = url.startswith("https://do/") or w.get("executionModel") == "durableObject"
    return {
        "ts": parse_ts(e["timestamp"]),
        "url": url,
        "path": path,
        "method": req.get("method"),
        "status": resp.get("status"),
        "outcome": w.get("outcome"),
        "entrypoint": w.get("entrypoint"),
        "execModel": w.get("executionModel"),
        "requestId": w.get("requestId"),
        "isDo": is_do,
        "cpuMs": w.get("cpuTimeMs"),
        "wallMs": w.get("wallTimeMs"),
        "exceptions": w.get("exceptions") or e.get("exceptions") or [],
        "logs": w.get("logs") or [],
        "scriptVersion": (w.get("scriptVersion") or {}).get("id"),
        "trigger": (e.get("$metadata") or {}).get("trigger"),
        "msg": (e.get("source") or {}).get("message"),
    }


def main():
    raw_events = load(LOG_PATH)
    events = [extract(e) for e in raw_events]
    events.sort(key=lambda x: x["ts"])
    n = len(events)
    print(f"# CF Logs 分析")
    print(f"ファイル: {LOG_PATH}")
    print(f"件数: {n}")

    if not events:
        return

    # 時間範囲
    ts_min, ts_max = events[0]["ts"], events[-1]["ts"]
    span = (ts_max - ts_min) / 1000
    print(f"時間範囲 (JST): {jst_full(ts_min)} 〜 {jst_full(ts_max)}  ({span:.1f}秒 = {span/60:.1f}分)")

    # script version 分布
    sv = Counter(e["scriptVersion"] for e in events)
    print(f"\n## scriptVersion 分布")
    for k, v in sv.most_common():
        print(f"  {v}件  {k}")

    # entrypoint 分布
    ep = Counter(e["entrypoint"] for e in events)
    print(f"\n## entrypoint 分布")
    for k, v in ep.most_common():
        print(f"  {v}件  {k}")

    # outcome 分布
    out = Counter(e["outcome"] for e in events)
    print(f"\n## outcome 分布")
    for k, v in out.most_common():
        print(f"  {v}件  {k}")

    # ステータス分布
    status_dist = Counter(e["status"] for e in events)
    print(f"\n## status 分布")
    for k, v in sorted(status_dist.items(), key=lambda x: (x[0] is None, x[0])):
        print(f"  {v}件  status={k}")

    # path 分布 (外部 + DO 両方)
    print(f"\n## path 別アクセス回数 (上位 30、status 内訳付)")
    by_path = defaultdict(list)
    for e in events:
        by_path[e["path"]].append(e)
    for path, lst in sorted(by_path.items(), key=lambda x: -len(x[1]))[:30]:
        sc = Counter(x["status"] for x in lst)
        sd = " ".join(f"{s}={c}" for s, c in sorted(sc.items(), key=lambda x: (x[0] is None, x[0])))
        do_count = sum(1 for x in lst if x["isDo"])
        print(f"  {len(lst):5d}  DO={do_count:5d}  {path}  [{sd}]")

    # 異常応答 (4xx/5xx) 全件
    print(f"\n## 異常応答 (status >= 400) 全件")
    abn = [e for e in events if e["status"] is not None and e["status"] >= 400]
    for e in abn:
        do_mark = "[DO]" if e["isDo"] else "[WK]"
        print(f"  {jst_full(e['ts'])}  status={e['status']}  outcome={e['outcome']}  {do_mark} {e['method']} {e['path']}  req={e['requestId']}")
    print(f"  合計: {len(abn)} 件")

    # outcome != ok 全件
    print(f"\n## outcome != 'ok' 全件")
    notok = [e for e in events if e["outcome"] not in (None, "ok")]
    for e in notok:
        do_mark = "[DO]" if e["isDo"] else "[WK]"
        print(f"  {jst_full(e['ts'])}  status={e['status']}  outcome={e['outcome']}  {do_mark} {e['method']} {e['path']}  req={e['requestId']}")
    print(f"  合計: {len(notok)} 件")

    # exceptions 全件
    print(f"\n## exceptions 全件")
    ex_total = 0
    for e in events:
        for ex in e["exceptions"]:
            ex_total += 1
            print(f"  {jst_full(e['ts'])}  {ex.get('name')}: {ex.get('message')}  @ {e['path']}  req={e['requestId']}")
    print(f"  合計: {ex_total} 件")

    # log level warn/error/fatal 全件
    print(f"\n## logs warn/error/fatal 全件")
    warn_total = 0
    for e in events:
        for lg in e["logs"]:
            lvl = lg.get("level")
            if lvl in ("warn", "error", "fatal"):
                warn_total += 1
                msg = lg.get("message")
                if isinstance(msg, list):
                    msg_str = " ".join(str(m) for m in msg)
                else:
                    msg_str = str(msg)
                print(f"  {jst_full(e['ts'])}  [{lvl}] {msg_str[:250]}  @ {e['path']}  req={e['requestId']}")
    print(f"  合計: {warn_total} 件")

    # 高 wallMs (= ネットワーク待ち / DO 遅延の可能性)
    print(f"\n## wallTimeMs 上位 30 件 (DO + Worker、電波遅延・DO 遅延の兆候)")
    by_wall = sorted([e for e in events if e["wallMs"] is not None], key=lambda x: -x["wallMs"])[:30]
    for e in by_wall:
        do_mark = "[DO]" if e["isDo"] else "[WK]"
        print(f"  {jst_full(e['ts'])}  wall={e['wallMs']}ms cpu={e['cpuMs']}ms  {do_mark} {e['path']}  req={e['requestId']}")

    # 高速連打 (同一 path が短時間に繰り返される)
    # オーナー指示「高速で実行されている所」 = 同一 path / 同一 requestId 内 / または「同じ user が短時間に何度も同じ操作」
    # 1) Worker 入口 (entrypoint=default, isDo=False) を path × 1 秒窓 で集計
    print(f"\n## 高速連打パターン (entrypoint=default の外部入口、1 秒窓に 3 回以上)")
    worker_events = [e for e in events if not e["isDo"]]
    by_path_ext = defaultdict(list)
    for e in worker_events:
        by_path_ext[e["path"]].append(e["ts"])
    burst_paths = []
    for path, ts_list in by_path_ext.items():
        ts_list.sort()
        # 各 ts を起点に 1 秒以内に何個入るかを数える
        max_in_window = 0
        for i in range(len(ts_list)):
            j = i
            while j < len(ts_list) and ts_list[j] - ts_list[i] <= 1000:
                j += 1
            in_w = j - i
            if in_w > max_in_window:
                max_in_window = in_w
        if max_in_window >= 3:
            burst_paths.append((path, max_in_window, len(ts_list)))
    burst_paths.sort(key=lambda x: -x[1])
    for path, peak, total in burst_paths:
        print(f"  ピーク={peak}回/1秒  総計={total}回  path={path}")
    if not burst_paths:
        print("  (1 秒窓 3 回以上の path なし)")

    # 2) より粗い 5 秒窓 / 5 回以上
    print(f"\n## 高速連打パターン (5 秒窓に 5 回以上)")
    bursts_5s = []
    for path, ts_list in by_path_ext.items():
        ts_list.sort()
        max_in_window = 0
        worst_window = None
        for i in range(len(ts_list)):
            j = i
            while j < len(ts_list) and ts_list[j] - ts_list[i] <= 5000:
                j += 1
            in_w = j - i
            if in_w > max_in_window:
                max_in_window = in_w
                worst_window = (ts_list[i], ts_list[j - 1])
        if max_in_window >= 5:
            bursts_5s.append((path, max_in_window, len(ts_list), worst_window))
    bursts_5s.sort(key=lambda x: -x[1])
    for path, peak, total, win in bursts_5s:
        print(f"  ピーク={peak}回/5秒  総計={total}回  時間={jst(win[0])}〜{jst(win[1])}  path={path}")

    # requestId 単位で worker → DO チェーンを再構成
    print(f"\n## requestId 単位の集計 (worker 1 リクエスト = DO 何呼出か)")
    by_req = defaultdict(list)
    for e in events:
        rid = e["requestId"]
        if rid:
            by_req[rid].append(e)
    chain_sizes = Counter(len(lst) for lst in by_req.values())
    print(f"  worker req 数: {len(by_req)}")
    for size, cnt in sorted(chain_sizes.items()):
        print(f"  チェーン長 {size}: {cnt}件")
    # 長いチェーン上位 10
    long_chains = sorted(by_req.items(), key=lambda x: -len(x[1]))[:10]
    print(f"\n  ## 長いチェーン Top 10")
    for rid, lst in long_chains:
        lst.sort(key=lambda x: x["ts"])
        worker_e = next((x for x in lst if not x["isDo"]), None)
        if worker_e:
            print(f"  req={rid} 長さ={len(lst)} 入口={worker_e['method']} {worker_e['path']} status={worker_e['status']} {jst(worker_e['ts'])}")
            do_paths = Counter(x["path"] for x in lst if x["isDo"])
            for p, c in do_paths.most_common():
                print(f"    DO {c}回: {p}")

    # 連続失敗パターン: 同じ path で短時間に複数回 4xx/5xx/outcome!=ok
    print(f"\n## 連続失敗 (同じ path で 60 秒以内に 2 件以上の異常応答)")
    by_path_err = defaultdict(list)
    for e in events:
        is_err = (e["status"] is not None and e["status"] >= 400) or (e["outcome"] not in (None, "ok")) or e["exceptions"]
        if is_err:
            by_path_err[e["path"]].append(e)
    seq_err_count = 0
    for path, lst in by_path_err.items():
        lst.sort(key=lambda x: x["ts"])
        if len(lst) < 2:
            continue
        # 連続性チェック
        for i in range(len(lst) - 1):
            if lst[i + 1]["ts"] - lst[i]["ts"] <= 60000:
                seq_err_count += 1
                print(f"  path={path}  {jst_full(lst[i]['ts'])} (status={lst[i]['status']}, outcome={lst[i]['outcome']})")
                print(f"              {jst_full(lst[i+1]['ts'])} (status={lst[i+1]['status']}, outcome={lst[i+1]['outcome']})  Δ={(lst[i+1]['ts']-lst[i]['ts'])/1000:.2f}s")
                break  # 1 path 1 報告
    print(f"  検出: {seq_err_count} path")

    # 大きな時間ギャップ (= 端末/通信が一時的に途絶した可能性、ログ全体での「間」)
    print(f"\n## 時間ギャップ Top 10 (連続ログ間の最大ギャップ、電波途絶の兆候)")
    gaps = []
    for i in range(1, len(events)):
        gap = events[i]["ts"] - events[i-1]["ts"]
        gaps.append((gap, events[i-1], events[i]))
    gaps.sort(key=lambda x: -x[0])
    for gap, prev, cur in gaps[:10]:
        print(f"  ギャップ {gap/1000:.2f}秒  前: {jst(prev['ts'])} {prev['path']}  → 次: {jst(cur['ts'])} {cur['path']}")


if __name__ == "__main__":
    main()
