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
import shutil
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
SOLARA = HERE.parent
PUBSPEC = SOLARA / "pubspec.yaml"

# repo root の .env を環境変数へ読み込む (既存の値は setdefault で温存 = CLI/実環境変数が優先)。
# これで .env に SOLARA_RC_ANDROID_KEY / SOLARA_RC_IOS_KEY / SOLARA_GCP_PROJECT_NUMBER を
# 書いておくだけで、毎回 CLI で渡さなくても resolve_*() が拾う。
# parents[3] = repo root (mockup/generate_*.py と同じ辿り方: tools→solara→apps→AppCreate)。
_ENV_PATH = Path(__file__).resolve().parents[3] / ".env"
if _ENV_PATH.exists():
    for _line in _ENV_PATH.read_text(encoding="utf-8").splitlines():
        if "=" in _line and not _line.lstrip().startswith("#"):
            _k, _v = _line.split("=", 1)
            os.environ.setdefault(_k.strip(), _v.strip())


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


def build_command(
    platform: str,
    version: str,
    gcp_project_number: int | None,
    rc_android_key: str | None,
    rc_ios_key: str | None,
    google_server_client_id: str | None,
    google_ios_client_id: str | None,
) -> list[str]:
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
    # RevenueCat Public SDK key を dart-define で注入 (= PurchasesService._iosApiKey /
    # _androidApiKey)。未注入だと release で Purchases.configure が skip され appUserId が
    # null になり、Play Integrity middleware Step 3 が clientdata_uid_invalid で弾く
    # (enforced だと全 Android Pro が 401)。キーは公開 SDK key だがコミットせず CLI/env で渡す。
    if platform in ("apk", "aab") and rc_android_key:
        cmd.append(f"--dart-define=SOLARA_RC_ANDROID_KEY={rc_android_key}")
    if platform == "ios" and rc_ios_key:
        cmd.append(f"--dart-define=SOLARA_RC_IOS_KEY={rc_ios_key}")
    # Google Sign-In クライアント ID を dart-define で注入 (= SolaraAuth._googleServerClientId /
    # _googleIosClientId)。🔴 google_sign_in 7.x は **Android で serverClientId 必須**
    # (= Web OAuth client ID)。未注入だと release で
    #   GoogleSignInException(clientConfigurationError, "serverClientId must be provided on Android")
    # が出てサインイン不可 → Pro/クレジット購入 (サインイン必須) も検証できない。
    # serverClientId は Web client なので全プラットフォームで有用。iosClientId は iOS のみ。
    if google_server_client_id:
        cmd.append(
            f"--dart-define=SOLARA_GOOGLE_SERVER_CLIENT_ID={google_server_client_id}"
        )
    if platform == "ios" and google_ios_client_id:
        cmd.append(
            f"--dart-define=SOLARA_GOOGLE_IOS_CLIENT_ID={google_ios_client_id}"
        )
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


def resolve_rc_key(arg_value: str | None, env_name: str) -> str | None:
    """RevenueCat Public SDK key を解決。優先順位: CLI > env > None。"""
    if arg_value:
        return arg_value.strip()
    env_val = os.environ.get(env_name)
    if env_val and env_val.strip():
        return env_val.strip()
    return None


def mask_key(key: str | None) -> str:
    """SDK key を表示用にマスク (先頭プレフィックスのみ残す)。"""
    if not key:
        return "(未設定)"
    if len(key) <= 8:
        return key[:2] + "…"
    return key[:8] + "…" + f"({len(key)} chars)"


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
    parser.add_argument(
        "--rc-android-key",
        default=None,
        help=(
            "RevenueCat Android Public SDK key (goog_xxx)。Android/AAB のみ。"
            " 未指定時は env SOLARA_RC_ANDROID_KEY を見る。"
            " 未設定だと release で Purchases.configure が skip され appUserId=null となり"
            " Play Integrity が clientdata_uid_invalid で弾く。キーはコミットしないこと。"
        ),
    )
    parser.add_argument(
        "--rc-ios-key",
        default=None,
        help=(
            "RevenueCat iOS Public SDK key (appl_xxx)。iOS のみ。"
            " 未指定時は env SOLARA_RC_IOS_KEY を見る。キーはコミットしないこと。"
        ),
    )
    args = parser.parse_args()

    version = args.version or read_version()
    sym_dir = symbols_dir(args.platform, version)
    gcp = resolve_gcp_project_number(args.gcp_project_number)
    rc_android_key = resolve_rc_key(args.rc_android_key, "SOLARA_RC_ANDROID_KEY")
    rc_ios_key = resolve_rc_key(args.rc_ios_key, "SOLARA_RC_IOS_KEY")
    # Google Sign-In クライアント ID は env (.env 自動読込) からのみ解決 (CLI 引数は設けない)。
    google_server_client_id = resolve_rc_key(None, "SOLARA_GOOGLE_SERVER_CLIENT_ID")
    google_ios_client_id = resolve_rc_key(None, "SOLARA_GOOGLE_IOS_CLIENT_ID")

    cmd = build_command(
        args.platform,
        version,
        gcp,
        rc_android_key,
        rc_ios_key,
        google_server_client_id,
        google_ios_client_id,
    )

    print("┌─ Solara Release Build ─────────────────────────────")
    print(f"│ platform   : {args.platform}")
    print(f"│ version    : {version}")
    print(f"│ symbols    : {sym_dir.relative_to(SOLARA)}")
    if args.platform in ("apk", "aab"):
        if gcp is None:
            print(f"│ GCP project: (未設定 = Play Integrity bypass)")
        else:
            print(f"│ GCP project: {gcp}")
        if rc_android_key is None:
            print(f"│ RC android : (未設定 = configure skip / appUserId=null)")
        else:
            print(f"│ RC android : {mask_key(rc_android_key)}")
    if args.platform == "ios":
        print(f"│ RC ios     : {mask_key(rc_ios_key)}")
    # Google Sign-In: serverClientId は Android 必須。未設定だと release でサインイン不可。
    if args.platform in ("apk", "aab") and google_server_client_id is None:
        print("│ Google     : [NG] serverClientId 未設定 = Android サインイン不可")
    elif google_server_client_id is not None:
        print(f"│ Google     : serverClientId OK ({google_server_client_id[:16]}…)")
    else:
        print("│ Google     : serverClientId 未設定")
    # command 表示はキーをマスクして漏洩を防ぐ (ログ/スクショ対策)。
    masked_cmd = [
        re.sub(r"(SOLARA_RC_(?:ANDROID|IOS)_KEY=)(\S+)", r"\1***", part)
        for part in cmd
    ]
    print(f"│ command    : {' '.join(masked_cmd)}")
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
    print(f"[build_release] running: {' '.join(masked_cmd)}")
    print()

    # Windows では `flutter` は `flutter.bat`。Python 3.13+ の subprocess.run は
    # shell=False で .bat 拡張子を自動解決しないため、shutil.which() でフルパスに
    # 展開してから渡す (Mac/Linux でも shutil.which が動くので両対応)。
    resolved = shutil.which(cmd[0])
    if resolved:
        cmd[0] = resolved
    elif os.name == 'nt':
        # which が見つけられない異常系: cmd 経由 fallback (PATH に flutter.bat があれば動く)
        print(f"[build_release] [WARN] shutil.which('{cmd[0]}') が None、shell 経由 fallback")
        cmd = ["cmd", "/c", *cmd]

    env = os.environ.copy()
    result = subprocess.run(cmd, cwd=SOLARA, env=env)
    if result.returncode != 0:
        print()
        print(f"[build_release] [FAIL] flutter build failed (exit {result.returncode})")
        return result.returncode

    print()
    print("[build_release] [OK] build succeeded")
    print()
    print("次のステップ:")
    print(f"  1. シンボル退避: {sym_dir.relative_to(SOLARA)} をリリースアーカイブに保存")
    print("  2. 実機/TestFlight で release build を起動")
    print("  3. 主要画面 (Map / Horoscope / Observe / Stella / Cosmic Pro) を全部確認")
    print("  4. クラッシュ時 → flutter symbolize -i <stack.txt> -d <*.symbols>")
    return 0


if __name__ == "__main__":
    sys.exit(main())
