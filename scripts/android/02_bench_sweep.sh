#!/usr/bin/env bash
# llama-bench sweep on the Pixel 7 (llama.cpp b3600, same as the Pi 3):
#   model x weight quant x KV-cache type x prefill length x decode length, batch=1.
# llama-bench does a warm-up run itself; -r 3 = 3 measured runs (mean and std reported).
#
# Usage (from repo root, in Termux, phone unplugged, screen on, nothing else running):
#   bash scripts/android/02_bench_sweep.sh                      # full sweep
#   PILOT=1 bash scripts/android/02_bench_sweep.sh              # quick pipeline check
#   THREADS_LIST="1 2 4 6 8" MODELS=qwen2.5-0.5b-instruct QUANTS=q4_0 KVS=f16 \
#     PP=128 TG=128 bash scripts/android/02_bench_sweep.sh      # find the best thread count
#
# Env knobs (defaults in brackets):
#   MODELS   [smollm2-135m-instruct smollm2-360m-instruct qwen2.5-0.5b-instruct]
#   QUANTS   [fp16 q8_0 q4_0 q4_k_m]     KVS [f16 q8_0 q4_0]
#   THREADS_LIST [4]   CORES [4-7]  (taskset CPU list; 4-7 = A78 + X1 big cores)
#   PP [128,256,1024,2048]   TG [128,512]   PG ["1024,128 2048,128"]  (prefill then decode)
#   BATCH [128] (matches the Pi 3 runs)   REPS [3]   COOLDOWN [30] seconds between configs
set -euo pipefail
cd "$(dirname "$0")/../.."

BENCH=llama.cpp/build/bin/llama-bench
MODELS="${MODELS:-smollm2-135m-instruct smollm2-360m-instruct qwen2.5-0.5b-instruct}"
QUANTS="${QUANTS:-fp16 q8_0 q4_0 q4_k_m}"
KVS="${KVS:-f16 q8_0 q4_0}"
THREADS_LIST="${THREADS_LIST:-4}"
CORES="${CORES:-4-7}"
PP="${PP:-128,256,1024,2048}"
TG="${TG:-128,512}"
PG="${PG:-1024,128 2048,128}"
BATCH="${BATCH:-128}"
REPS="${REPS:-3}"
COOLDOWN="${COOLDOWN:-30}"
if [ -n "${PILOT:-}" ]; then
  MODELS=smollm2-135m-instruct; QUANTS="q8_0 q4_0"; KVS="f16 q8_0"
  PP=128,256; TG=128; PG="256,64"; REPS=1; COOLDOWN=5
fi

STAMP=$(date +%Y%m%d-%H%M%S)
OUT=results/android/raw/$STAMP
mkdir -p "$OUT"
{
  echo "device=Pixel 7  stamp=$STAMP  llama=$(git -C llama.cpp describe --tags --always)"
  echo "models=$MODELS quants=$QUANTS kvs=$KVS threads=$THREADS_LIST cores=$CORES batch=$BATCH reps=$REPS"
  echo "android=$(getprop ro.build.version.release 2>/dev/null) build=$(getprop ro.build.id 2>/dev/null)"
  echo "battery_level=$(cat /sys/class/power_supply/battery/capacity 2>/dev/null)%"
} | tee "$OUT/meta.txt"

PIN=(); command -v taskset >/dev/null && [ -n "$CORES" ] && PIN=(taskset -c "$CORES")

bash scripts/android/syslog.sh "$OUT/syslog.csv" & LOGPID=$!
[ -x "$BENCH" ] || { echo "llama-bench not found at $BENCH. Run scripts/android/00_setup_termux.sh first (inside Termux on the phone)."; exit 1; }
trap 'kill $LOGPID 2>/dev/null || true' EXIT
sleep 10   # idle baseline for the power log

n=0
for m in $MODELS; do
  for q in $QUANTS; do
    f=models/$m-$q.gguf
    [ -f "$f" ] || { echo "missing $f, skipping"; continue; }
    for kv in $KVS; do
      # Quantized V-cache needs flash attention. For f16 KV also run FA off, to match the Pi.
      if [ "$kv" = f16 ]; then FAS="0 1"; else FAS="1"; fi
      for fa in $FAS; do
        for t in $THREADS_LIST; do
          n=$((n + 1))
          tag="$m-$q-kv$kv-fa$fa-t$t"
          echo "== [$n] $tag   $(date +%T)"
          pg_args=(); for x in $PG; do pg_args+=(-pg "$x"); done
          echo "$(date +%s) start $tag" >> "$OUT/events.log"
          ${PIN[@]+"${PIN[@]}"} "$BENCH" -m "$f" -t "$t" -b "$BATCH" -ngl 0 -fa "$fa" -ctk "$kv" -ctv "$kv" \
            -p "$PP" -n "$TG" ${pg_args[@]+"${pg_args[@]}"} -r "$REPS" -o csv \
            > "$OUT/$tag.csv" 2> "$OUT/$tag.log" || echo "   FAILED (see $OUT/$tag.log)"
          echo "$(date +%s) end $tag" >> "$OUT/events.log"
          sleep "$COOLDOWN"
        done
      done
    done
  done
done

python3 scripts/android/to_benchmarks_csv.py "$OUT"
echo "done -> $OUT"
