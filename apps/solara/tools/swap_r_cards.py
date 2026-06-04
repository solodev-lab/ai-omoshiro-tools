"""r 付きカード画像を本番ファイル名へ差し替える (オーナー指示 2026-06-04)。

assets/card-images/ 内の rXXX.webp を XXX.webp へ差し替える:
  1. 元の XXX.webp を _original/ へ退避 (初回のみ・可逆性確保)
  2. rXXX.webp の中身で XXX.webp を上書き
  3. rXXX.webp を削除
対応する XXX.webp が無い r ファイルはスキップ (報告のみ)。
Flutter の asset は `assets/card-images/` をディレクトリ指定 = サブフォルダ
(_original/) は非バンドル。コード変更不要 (ファイル名据置で中身だけ差替)。
"""
import os
import shutil

BASE = os.path.join(os.path.dirname(__file__), "..", "assets", "card-images")
BASE = os.path.abspath(BASE)
ORIG = os.path.join(BASE, "_original")


def main():
    os.makedirs(ORIG, exist_ok=True)
    r_files = sorted(
        f for f in os.listdir(BASE)
        if f.startswith("r") and f.lower().endswith(".webp")
    )
    if not r_files:
        print("r 付き画像が見つかりませんでした (差し替えなし)。")
        return

    swapped, skipped = [], []
    for rf in r_files:
        target = rf[1:]  # rM03.webp -> M03.webp
        tpath = os.path.join(BASE, target)
        rpath = os.path.join(BASE, rf)
        if not os.path.exists(tpath):
            skipped.append(rf)
            continue
        bpath = os.path.join(ORIG, target)
        if not os.path.exists(bpath):
            shutil.copy2(tpath, bpath)  # 元(白枠)を退避 (初回のみ)
        shutil.copy2(rpath, tpath)      # r 版で上書き
        os.remove(rpath)                # r ファイル削除
        swapped.append(target)

    print(f"差し替え {len(swapped)} 枚: {swapped}")
    if skipped:
        print(f"スキップ (対応する本番ファイル無し) {len(skipped)} 枚: {skipped}")
    print(f"元画像の退避先: {ORIG}")


if __name__ == "__main__":
    main()
