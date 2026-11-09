#!/usr/bin/env bash
# llama-bench sweep on the Raspberry Pi 3 (llama.cpp b3600, same as the Pi 5 and Pixel 7):
#   model x weight quant x KV-cache type, batch=1, prefill / decode / prefill-then-decode.
# Same structure and output format as scripts/pi5/02_bench_sweep.sh, trimmed for 1 GB RAM and a
# CPU about 10x slower: shorter prompts (no 1024/2048), one decode length, and models that do not
# fit in free RAM are skipped (set FORCE=1 to try anyway).
# llama-bench does a warm-up run itself; -r 3 = 3 measured runs (mean and std reported).
#
# Usage (from repo root, on the Pi, over SSH, nothing else running; a heatsink is recommended):
#   PILOT=1 bash scripts/pi3/02_bench_sweep.sh                          # ~5-minute pipeline check
#   nohup bash scripts/pi3/02_bench_sweep.sh > sweep-pi3.log 2>&1 &     # full sweep (~12 h)
#   MODELS=qwen2.5-0.5b-instruct bash scripts/pi3/02_bench_sweep.sh     # one model only
# Temperature, clock, throttling and an ESTIMATED power (from CPU load) go to <run>/power.csv
# (scripts/pi3/temp_log.sh). Estimated energy per token afterwards:
#   python3 scripts/android/energy.py results/pi3/raw/<stamp> results/pi3/raw/<stamp>/power.csv
#
# Env knobs (defaults in brackets):
#   MODELS   [smollm2-135m-instruct smollm2-360m-instruct qwen2.5-0.5b-instruct]
#   QUANTS   [fp16 q8_0 q4_0 q4_k_m]     KVS [f16 q8_0 q4_0]
#   THREADS_LIST [4]   CORES [0-3]
#   PP [128,256]   TG [128]   PG ["512,128"]  (prefill then decode)
#   BATCH [128] (matches the Pi 5 and Pixel runs)   REPS [3]   COOLDOWN [30] seconds between configs
set -euo pipefail
cd "$(dirname "$0")/../.."

BENCH=llama.cpp/build/bin/llama-bench
MODELS="${MODELS:-smollm2-135m-instruct smollm2-360m-instruct qwen2.5-0.5b-instruct}"
QUANTS="${QUANTS:-fp16 q8_0 q4_0 q4_k_m}"
KVS="${KVS:-f16 q8_0 q4_0}"
THREADS_LIST="${THREADS_LIST:-4}"
CORES="${CORES:-0-3}"
PP="${PP:-128,256}"
TG="${TG:-128}"
PG="${PG:-512,128}"
BATCH="${BATCH:-128}"
REPS="${REPS:-3}"
COOLDOWN="${COOLDOWN:-30}"
if [ -n "${PILOT:-}" ]; then
  MODELS=smollm2-135m-instruct; QUANTS="q8_0 q4_0"; KVS="f16 q8_0"
  PP=64; TG=32; PG="128,32"; REPS=1; COOLDOWN=5
fi

STAMP=$(date +%Y%m%d-%H%M%S)
OUT=results/pi3/raw/$STAMP
mkdir -p "$OUT"
{
  echo "device=Raspberry Pi 3  stamp=$STAMP  llama=$(git -C llama.cpp describe --tags --always)"
  echo "models=$MODELS quants=$QUANTS kvs=$KVS threads=$THREADS_LIST cores=$CORES batch=$BATCH reps=$REPS"
  echo "os=$(. /etc/os-release && echo "$PRETTY_NAME") ($(uname -m)) kernel=$(uname -r)"
  echo "board=$(tr -d '\0' < /proc/device-tree/model)"
} | tee "$OUT/meta.txt"

PIN=(); command -v taskset >/dev/null && [ -n "$CORES" ] && PIN=(taskset -c "$CORES")

bash scripts/pi3/temp_log.sh "$OUT/power.csv" & LOGPID=$!
[ -x "$BENCH" ] || { echo "llama-bench not found at $BENCH. Run bash scripts/pi3/00_setup.sh first."; exit 1; }
trap 'kill $LOGPID 2>/dev/null || true' EXIT
sleep 10   # idle baseline for the power log

n=0
for m in $MODELS; do
  for q in $QUANTS; do
    f=models/$m-$q.gguf
    [ -f "$f" ] || { echo "missing $f, skipping"; continue; }
    # 1 GB RAM: skip a model bigger than the free memory (it would thrash swap for hours).
    need=$(( $(stat -c %s "$f") / 1048576 + 50 ))
    avail=$(awk '/MemAvailable/ {print int($2/1024)}' /proc/meminfo)
    if [ "$need" -gt "$avail" ] && [ -z "${FORCE:-}" ]; then
      echo "skip $f: needs ~${need} MB, ${avail} MB free (FORCE=1 to try)" | tee -a "$OUT/skipped.txt"; continue
    fi
    for kv in $KVS; do
      # Quantized V-cache needs flash attention. For f16 KV also run FA off, to match the Pi 3.
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
