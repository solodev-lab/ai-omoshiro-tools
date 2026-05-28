"""CF Logs 深掘り分析: 特定時刻の周辺 events を dump、バースト原因を特定。"""

from __future__ import annotations
import json
import sys
from collections import defaultdict, Counter
from datetime import datetime, timezone, timedelta

LOG_PATH = r"C:\Users\cojif\Downloads\logs-2026-05-28T15_23_30.272Z.json"


def load(path):
    with open(path, "r", encoding="utf-8") as f:
        raw = f.read().strip()
    if raw.startswith("["):
        return json.loads(raw)
    return [json.loads(line) for line in raw.splitlines() if line.strip()]


def parse_ts(s):
    return datetime.fromisoformat(s.replace("Z", "+00:00")).timestamp() * 1000


def jst(ms):
    return (datetime.fromtimestamp(ms / 1000, tz=timezone.utc) + timedelta(hours=9)).strftime("%H:%M:%S.%f")[:-3]


def extract(e):
    w = e.get("$workers") or {}
    ev = w.get("event") or {}
    req = ev.get("request") or {}
    resp = ev.get("response") or {}
    return {
        "ts": parse_ts(e["timestamp"]),
        "raw": e,
        "path": req.get("path") or req.get("url") or "",
        "method": req.get("method"),
        "status": resp.get("status"),
        "outcome": w.get("outcome"),
        "entrypoint": w.get("entrypoint"),
        "execModel": w.get("executionModel"),
        "requestId": w.get("requestId"),
        "isDo": (req.get("url") or "").startswith("https://do/") or w.get("executionModel") == "durableObject",
        "cpuMs": w.get("cpuTimeMs"),
        "wallMs": w.get("wallTimeMs"),
        "headers": req.get("headers") or {},
    }


def window(events, t0, t1):
    return [e for e in events if t0 <= e["ts"] <= t1]


def dump(prefix, events):
    for e in events:
        do_mark = "[DO]" if e["isDo"] else "[WK]"
        h = e["headers"]
        ua = h.get("user-agent", "")[:80] if h else ""
        cf_ip = h.get("cf-connecting-ip", "?")
        status_str = str(e["status"]) if e["status"] is not None else "---"
        method_str = e["method"] or "?"
        path_str = e["path"] or ""
        wall_str = e["wallMs"] if e["wallMs"] is not None else "?"
        cpu_str = e["cpuMs"] if e["cpuMs"] is not None else "?"
        print(f"  {prefix}{jst(e['ts'])} {do_mark} status={status_str:>3} {method_str:5} {path_str:50} req={e['requestId']} wall={wall_str}ms cpu={cpu_str}ms")


def section(title):
    print()
    print("=" * 100)
    print(f"  {title}")
    print("=" * 100)


def main():
    raw = load(LOG_PATH)
    events = sorted([extract(e) for e in raw], key=lambda x: x["ts"])

    # 1) 503 exceededCpu 周辺 ±10 秒
    section("1) 503 exceededCpu 発生 (20:01:20.882 /public/astro/forecast) 周辺 ±10 秒")
    t_ms = parse_ts("2026-05-28T11:01:20.882Z")  # JST 20:01:20 = UTC 11:01:20
    around = window(events, t_ms - 10000, t_ms + 10000)
    dump("", around)
    # exceededCpu event の生 dump (cpu/wall 等の詳細)
    print("\n  -- exceededCpu event の raw $workers --")
    for e in events:
        if e["outcome"] == "exceededCpu":
            print(f"  {jst(e['ts'])} requestId={e['requestId']}")
            w = e["raw"].get("$workers") or {}
            # cpuTimeMs / wallTimeMs / dispatchNamespace 等
            print(f"    cpu={w.get('cpuTimeMs')}ms wall={w.get('wallTimeMs')}ms")
            print(f"    scriptVersion={w.get('scriptVersion',{}).get('id')}")
            print(f"    exceptions={w.get('exceptions')}")
            # ev のリクエスト詳細
            ev = w.get("event") or {}
            req = ev.get("request") or {}
            print(f"    method={req.get('method')} url={req.get('url')}")
            print(f"    headers (excerpt): cf-ipcountry={req.get('headers',{}).get('cf-ipcountry')} cf-ipcity={req.get('headers',{}).get('cf-ipcity')}")
            print(f"    body in event? keys={list(ev.keys())}")

    # 2) 425 pro_sync_pending + 429 連発 周辺
    section("2) 425 pro_sync_pending + 429 多発 周辺 (20:32:37 〜 20:33:20)")
    t0 = parse_ts("2026-05-28T11:32:20.000Z")
    t1 = parse_ts("2026-05-28T11:33:30.000Z")
    around = window(events, t0, t1)
    dump("", around)

    # 3) /public/astro/chart 13 回/3.84 秒 (20:17:55.172 〜 20:17:59.016)
    section("3) /public/astro/chart 13 回バースト (20:17:55.172 〜 20:17:59.016)")
    t0 = parse_ts("2026-05-28T11:17:54.000Z")
    t1 = parse_ts("2026-05-28T11:18:01.000Z")
    around = window(events, t0, t1)
    chart_events = [e for e in around if e["path"] == "/public/astro/chart"]
    print(f"  /public/astro/chart イベント数 (5秒窓内): {len(chart_events)}")
    print(f"  全イベント (chart 含めて窓内全部):")
    dump("", around)

    # 4) /protected/fortune 5 回/57ms (19:36:09.380 〜 19:36:09.437)
    section("4) /protected/fortune 5 回/57ms バースト (19:36:09.380 〜 19:36:09.437)")
    t0 = parse_ts("2026-05-28T10:36:09.000Z")
    t1 = parse_ts("2026-05-28T10:36:11.000Z")
    around = window(events, t0, t1)
    fortune_events = [e for e in around if e["path"] == "/protected/fortune"]
    print(f"  /protected/fortune イベント数 (2秒窓内): {len(fortune_events)}")
    for e in fortune_events:
        h = e["headers"] or {}
        # X-Solara-User-Id? body の中身は CF Logs では取得できない
        ua = h.get("user-agent", "")
        print(f"  {jst(e['ts'])} status={e['status']} wall={e['wallMs']}ms cpu={e['cpuMs']}ms req={e['requestId']}")

    # 5) /auth/integrity/challenge 9 回/3 秒 (19:37:52.612 〜 19:37:55.370)
    section("5) /auth/integrity/challenge 9 回バースト (19:37:52 〜 19:37:55)")
    t0 = parse_ts("2026-05-28T10:37:50.000Z")
    t1 = parse_ts("2026-05-28T10:37:58.000Z")
    around = window(events, t0, t1)
    ic_events = [e for e in around if e["path"] == "/auth/integrity/challenge"]
    print(f"  /auth/integrity/challenge イベント数 (8秒窓内): {len(ic_events)}")
    print(f"  全イベント:")
    dump("", around)

    # 6) 時間ギャップ後の "電波回復バースト" を検証
    section("6) 大きな時間ギャップ直後 60 秒に何が起きているか (電波回復後の再送バースト検証)")
    # 大ギャップ: 19:48:49 → 19:57:10 (500秒)、20:05:25 → 20:17:40 (734秒)、20:20:41 → 20:31:36 (655秒)、
    #            20:33:26 → 20:57:04 (1418秒)、20:58:37 → 21:25:41 (1624秒)
    gap_recoveries = [
        ("19:57:10 復帰 (500秒ギャップ後)", parse_ts("2026-05-28T10:57:10.000Z")),
        ("20:17:40 復帰 (734秒ギャップ後)", parse_ts("2026-05-28T11:17:40.000Z")),
        ("20:31:36 復帰 (655秒ギャップ後)", parse_ts("2026-05-28T11:31:36.000Z")),
        ("20:57:04 復帰 (1418秒ギャップ後)", parse_ts("2026-05-28T11:57:04.000Z")),
        ("21:25:41 復帰 (1624秒ギャップ後)", parse_ts("2026-05-28T12:25:41.000Z")),
    ]
    for label, t in gap_recoveries:
        print(f"\n  -- {label} の直後 60 秒 --")
        around = window(events, t - 1000, t + 60000)
        # path 集計
        c = Counter(e["path"] for e in around)
        print(f"    path 集計: {dict(c.most_common())}")
        # 異常応答だけ抜粋
        abn = [e for e in around if (e["status"] is not None and e["status"] >= 400) or e["outcome"] not in (None, "ok")]
        if abn:
            print(f"    異常応答:")
            dump("    ", abn)

    # 7) Pro 関連の状態遷移を追う: entitlement-get の 200/404 の連続パターン
    section("7) entitlement-get 200↔404 の遷移パターン (Pro 加入 / 解約 を追えるか)")
    ent_events = [e for e in events if e["path"] == "/entitlement-get"]
    print(f"  /entitlement-get 全 {len(ent_events)} 件 の status 推移 (時系列):")
    last_status = None
    for e in ent_events:
        if e["status"] != last_status:
            print(f"  {jst(e['ts'])} status={e['status']} req={e['requestId']}  <-- 遷移")
            last_status = e["status"]
        else:
            print(f"  {jst(e['ts'])} status={e['status']} req={e['requestId']}")

    # 8) requestId が同じ event の流れ (主に長い wallTimeMs のもの)
    section("8) 長い wallTimeMs の requestId のチェーン (consultation2 系)")
    # 上位 5 件をピック
    by_wall = sorted([e for e in events if e["wallMs"] is not None], key=lambda x: -x["wallMs"])[:5]
    for top in by_wall:
        rid = top["requestId"]
        chain = [e for e in events if e["requestId"] == rid]
        chain.sort(key=lambda x: x["ts"])
        print(f"\n  -- req={rid} 全 {len(chain)} event --")
        dump("    ", chain)

    # 9) Webhook RC 受信履歴
    section("9) RevenueCat webhook 受信履歴 (entitlement-upsert の前後関係)")
    rc_events = [e for e in events if e["path"] in ("/webhooks/revenuecat", "/entitlement-upsert")]
    rc_events.sort(key=lambda x: x["ts"])
    for e in rc_events:
        do_mark = "[DO]" if e["isDo"] else "[WK]"
        print(f"  {jst(e['ts'])} {do_mark} status={e['status']} {e['path']} req={e['requestId']}")


if __name__ == "__main__":
    main()
