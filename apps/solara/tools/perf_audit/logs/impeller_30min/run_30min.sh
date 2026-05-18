#!/bin/bash
# 30-min Impeller fd leak verification on A101FC (PID 27901)
# Galaxy DEBUG toggle (_kDebugDisableMotionStop=true) で連続描画継続
# 60s × 30 sample, fd/sync_file/PSS/native/java/cpu 収集
#
# Usage: bash run_30min.sh
# Output: data.csv (sample列), logcat_post.txt (テスト後ログ)

export PATH="$PATH:/c/Users/cojif/AppData/Local/Android/Sdk/platform-tools"

DEV=df1daf14
PID=27901
PKG=com.solodevlab.solara
SAMPLES=30
INTERVAL=60

DIR="$(dirname "$0")"
CSV="$DIR/data.csv"

# ヘッダ
echo "sample,elapsed_s,timestamp,fd_total,sync_file,pss_kb,native_kb,java_kb,cpu_pct" > "$CSV"

# logcat バッファ clear (post 取得を綺麗にする)
adb -s $DEV logcat -c

START=$(date +%s)
echo "[$(date '+%H:%M:%S')] 30-min Impeller fd leak test start (PID=$PID)"

for i in $(seq 1 $SAMPLES); do
  TS=$(date '+%H:%M:%S')
  ELAPSED=$(( $(date +%s) - START ))

  # fd_total
  FD=$(adb -s $DEV shell "run-as $PKG ls /proc/$PID/fd 2>/dev/null | wc -l" | tr -d '\r')
  # sync_file count
  SF=$(adb -s $DEV shell "run-as $PKG ls -l /proc/$PID/fd 2>/dev/null | grep -c sync_file" | tr -d '\r')
  # meminfo (PSS / Native / Dalvik)
  MEM=$(adb -s $DEV shell "dumpsys meminfo $PID 2>/dev/null")
  PSS=$(echo "$MEM" | grep -E "TOTAL PSS:" | awk '{print $3}' | tr -d '\r')
  NAT=$(echo "$MEM" | grep -E "^\s*Native Heap" | awk '{print $3}' | tr -d '\r')
  JAV=$(echo "$MEM" | grep -E "^\s*Dalvik Heap" | awk '{print $3}' | tr -d '\r')
  # CPU% (top 1秒)
  CPU=$(adb -s $DEV shell "top -n 1 -p $PID -b 2>/dev/null | tail -1 | awk '{print \$9}'" | tr -d '\r')

  echo "$i,$ELAPSED,$TS,$FD,$SF,$PSS,$NAT,$JAV,$CPU" >> "$CSV"
  echo "[$TS] sample $i/$SAMPLES (elapsed=${ELAPSED}s) fd=$FD sync=$SF pss=${PSS}kb nat=${NAT}kb jav=${JAV}kb cpu=${CPU}%"

  # 最後のサンプルで sleep しない
  if [ $i -lt $SAMPLES ]; then
    sleep $INTERVAL
  fi
done

echo "[$(date '+%H:%M:%S')] sampling complete, capturing logcat..."

# logcat post 取得 (Adreno/FATAL/Too many open files/BLAST)
adb -s $DEV logcat -d > "$DIR/logcat_post.txt" 2>&1

echo "[$(date '+%H:%M:%S')] DONE. CSV=$CSV LOG=$DIR/logcat_post.txt"
