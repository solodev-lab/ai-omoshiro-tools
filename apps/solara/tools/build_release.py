#!/usr/bin/env python3
"""Solara リリースビルドヘルパー (Phase 2 launch_checklist 残)

役割:
    `flutter build` の `--obfuscate` / `--split-debug-info` フラグを毎回
    手打ちさせない。シンボルファイル保存先をバージョン別に分離し、後で
    クラッシュ deobfuscation できる状態を維持する。

使い方 (CWD = apps/solara):
    python tools/build_release.py apk
    python tools/build_release.py aab    # Play Console 提出用
    python tools/build_release.py ios    # macOS のみ、TestFlight 用

オプション:
    --version <ver>   pubspec.yaml と異なる version を強制 (通常は不要)
    --release-mode    実際にビルドする (省略時は dry-run: コマンド表示のみ)

出力:
    build/symbols/<platform>/<version>/   <- .symbols ファイル群
    build/app/outputs/...                 <- 通常の Flutter ビルド成果物

🔴 シンボルファイル保管ポリシー:
    - build/ は .gitignore 済み。**リリース毎に手動バックアップ必須**
    - クラッシュ deobfuscation のため、リリース後 1 年以上保持
    - 公開後は Git LFS or 非公開バケットへ移行 (launch_checklist Phase 0)

🔴 release build 検証手順 (本スクリプト実行後):
    1. APK/AAB を実機 (Android) または TestFlight (iOS) で起動
    2. 主要画面を全部触る: Map / Horoscope / Observe / Stella 相談 /
       Cosmic Pro 購入フロー / Sign in
    3. クラッシュ時は build/symbols/<platform>/<version>/ から
       `flutter symbolize -i <crash.txt> -d <symbol.symbols>` で
       スタックトレース復号
    4. R8 minify が初有効なため、プラグイン由来のクラッシュは
       proguard-rules.pro に keep ルール追加で対処
"""
from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
SOLARA = HERE.parent
PUBSPEC = SOLARA / "pubspec.yaml"


def read_version() -> str:
    """pubspec.yaml の `version: 1.0.0+1` から `1.0.0+1` を返す。"""
    text = PUBSPEC.read_text(encoding="utf-8")
    m = re.search(r"^version:\s*(\S+)\s*$", text, re.MULTILINE)
    if not m:
        sys.exit("[build_release] pubspec.yaml の version 行が読めない")
    return m.group(1)


def symbols_dir(platform: str, version: str) -> Path:
    """build/symbols/<platform>/<version>/ を返す (作成は flutter 任せ)。"""
    return SOLARA / "build" / "symbols" / platform / version


def build_command(platform: str, version: str, gcp_project_number: int | None) -> list[str]:
    """flutter build コマンドを構築。"""
    target_arg = {
        "apk": "apk",
        "aab": "appbundle",
        "ios": "ios",
    }.get(platform)
    if target_arg is None:
        sys.exit(f"[build_release] unknown platform: {platform}")

    sym_dir = symbols_dir(platform, version)
    cmd = [
        "flutter",
        "build",
        target_arg,
        "--release",
        "--obfuscate",
        f"--split-debug-info={sym_dir}",
    ]
    # Android/AAB のみ: Play Integrity 用 Cloud Project Number を dart-define で注入
    # (= AppAttestClient._kCloudProjectNumber、設計 v0.7 §7.3)。
    # 0 / 未指定 → AppAttestClient は Android 経路を bypass (= Worker log_only で通過)。
    if platform in ("apk", "aab") and gcp_project_number is not None and gcp_project_number > 0:
        cmd.append(f"--dart-define=SOLARA_GCP_PROJECT_NUMBER={gcp_project_number}")
    # iOS は App Store Connect 経由 dSYM 別アップなので --no-codesign しない。
    # AAB は Play Console 提出時に R8 ProGuard map も自動取り込みされる。
    return cmd


def resolve_gcp_project_number(arg_value: int | None) -> int | None:
    """Cloud Project Number を解決。優先順位: CLI > env SOLARA_GCP_PROJECT_NUMBER > None。"""
    if arg_value is not None and arg_value > 0:
        return arg_value
    env_val = os.environ.get("SOLARA_GCP_PROJECT_NUMBER")
    if env_val:
        try:
            n = int(env_val)
            if n > 0:
                return n
        except ValueError:
            pass
    return None


def main() -> int:
    parser = argparse.ArgumentParser(description="Solara release build helper")
    parser.add_argument("platform", choices=["apk", "aab", "ios"])
    parser.add_argument("--version", help="pubspec を上書きするバージョン文字列")
    parser.add_argument(
        "--release-mode",
        action="store_true",
        help="実際にビルドする (省略時は dry-run)",
    )
    parser.add_argument(
        "--gcp-project-number",
        type=int,
        default=None,
        help=(
            "Play Integrity 用 Cloud Project Number (12 桁数字)。Android/AAB のみ。"
            " 未指定時は env SOLARA_GCP_PROJECT_NUMBER を見る。"
            " どちらも未設定なら Android 経路は bypass で release ビルド (= Worker log_only で通過)。"
        ),
    )
    args = parser.parse_args()

    version = args.version or read_version()
    sym_dir = symbols_dir(args.platform, version)
    gcp = resolve_gcp_project_number(args.gcp_project_number)

    cmd = build_command(args.platform, version, gcp)

    print("┌─ Solara Release Build ─────────────────────────────")
    print(f"│ platform   : {args.platform}")
    print(f"│ version    : {version}")
    print(f"│ symbols    : {sym_dir.relative_to(SOLARA)}")
    if args.platform in ("apk", "aab"):
        if gcp is None:
            print(f"│ GCP project: (未設定 = Play Integrity bypass)")
        else:
            print(f"│ GCP project: {gcp}")
    print(f"│ command    : {' '.join(cmd)}")
    print(f"│ mode       : {'EXECUTE' if args.release_mode else 'DRY RUN'}")
    print("└────────────────────────────────────────────────────")

    if not args.release_mode:
        print()
        print("[dry-run] 実行するには `--release-mode` を付けて再実行")
        print()
        print("実行後の手動作業:")
        print(f"  1. {sym_dir.relative_to(SOLARA)} を外部ストレージへバックアップ")
        print("  2. 実機/TestFlight で release build を起動して主要画面を全部触る")
        print("  3. クラッシュ時は flutter symbolize でスタック復号")
        return 0

    # 実行
    sym_dir.mkdir(parents=True, exist_ok=True)
    print(f"[build_release] {sym_dir} ensured")
    print(f"[build_release] running: {' '.join(cmd)}")
    print()

    env = os.environ.copy()
    result = subprocess.run(cmd, cwd=SOLARA, env=env)
    if result.returncode != 0:
        print()
        print(f"[build_release] ❌ flutter build failed (exit {result.returncode})")
        return result.returncode

    print()
    print("[build_release] ✅ build succeeded")
    print()
    print("次のステップ:")
    print(f"  1. シンボル退避: {sym_dir.relative_to(SOLARA)} をリリースアーカイブに保存")
    print("  2. 実機/TestFlight で release build を起動")
    print("  3. 主要画面 (Map / Horoscope / Observe / Stella / Cosmic Pro) を全部確認")
    print("  4. クラッシュ時 → flutter symbolize -i <stack.txt> -d <*.symbols>")
    return 0


if __name__ == "__main__":
    sys.exit(main())
