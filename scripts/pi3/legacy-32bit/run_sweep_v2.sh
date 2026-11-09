#!/bin/bash
cd ~/llama.cpp
OUT=~/sweep_v2_results.txt
MON=~/sweep_v2_monitor.csv

(
  echo "timestamp,temp_c,throttled_hex,cpu_util_pct" > "$MON"
  prev_total=0; prev_idle=0
  while true; do
    read -r cpu user nice system idle iowait irq softirq steal rest < /proc/stat
    total=$((user + nice + system + idle + iowait + irq + softirq + steal))
    diff_total=$((total - prev_total))
    diff_idle=$((idle - prev_idle))
    if [ $prev_total -gt 0 ] && [ $diff_total -gt 0 ]; then
      util=$(( (100 * (diff_total - diff_idle)) / diff_total ))
    else
      util=0
    fi
    prev_total=$total; prev_idle=$idle
    temp=$(vcgencmd measure_temp | sed "s/temp=//; s/'C$//")
    thr=$(vcgencmd get_throttled | sed "s/throttled=//")
    echo "$(date +%s),$temp,$thr,$util" >> "$MON"
    sleep 2
  done
) &
MON_PID=$!

echo "=== Sweep v2 started: $(date) ===" > "$OUT"

run_bench() {
  local LABEL="$1"; shift
  echo "" >> "$OUT"
  echo "=== $LABEL - $(date) ===" >> "$OUT"
  echo "throttle_before: $(vcgencmd get_throttled)" >> "$OUT"
  echo "temp_before: $(vcgencmd measure_temp)" >> "$OUT"
  "$@" >> "$OUT" 2>&1
  echo "throttle_after: $(vcgencmd get_throttled)" >> "$OUT"
  echo "temp_after: $(vcgencmd measure_temp)" >> "$OUT"
}

for MODEL in \
  Qwen2.5-0.5B-Instruct-Q8_0 \
  Qwen2.5-0.5B-Instruct-Q4_K_M \
  Qwen2.5-0.5B-Instruct-Q4_0 \
  SmolLM2-135M-Instruct-Q8_0 \
  SmolLM2-135M-Instruct-Q4_K_M \
  SmolLM2-360M-Instruct-Q8_0 \
  SmolLM2-360M-Instruct-Q4_K_M
do
  run_bench "${MODEL} + KVq8" \
    ./llama-bench -m "models/${MODEL}.gguf" -p 128 -n 128 -t 4 -b 128 -r 3 \
    -ctk q8_0 -ctv q8_0
done

for MODEL in \
  Qwen2.5-0.5B-Instruct-Q8_0 \
  SmolLM2-135M-Instruct-Q8_0 \
  SmolLM2-360M-Instruct-Q8_0
do
  run_bench "${MODEL} + ctx256" \
    ./llama-bench -m "models/${MODEL}.gguf" -p 256 -n 128 -t 4 -b 128 -r 3
  run_bench "${MODEL} + ctx512" \
    ./llama-bench -m "models/${MODEL}.gguf" -p 512 -n 128 -t 4 -b 128 -r 3
done

echo "" >> "$OUT"
echo "=== Sweep v2 finished: $(date) ===" >> "$OUT"
kill $MON_PID 2>/dev/null
