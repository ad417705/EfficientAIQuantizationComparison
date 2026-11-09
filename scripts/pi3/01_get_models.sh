#!/usr/bin/env bash
# Same GGUF files as the Pi 5 and Pixel 7, into ./models.
# Qwen2.5-0.5B FP16 (~1 GB) does not fit in the Pi 3's 1 GB RAM, so it is skipped unless ALL=1.
# Usage (repo root): bash scripts/pi3/01_get_models.sh      or   ALL=1 bash scripts/pi3/01_get_models.sh
set -euo pipefail
cd "$(dirname "$0")/../.."
mkdir -p models
HF=https://huggingface.co

get() {  # url  dest
  if [ -s "$2" ]; then echo "have $2"; return; fi
  echo "-> $2"
  curl -fL --retry 3 -o "$2.part" "$1" && mv "$2.part" "$2" \
    || { rm -f "$2.part"; echo "!! failed: $1"; FAILED=1; }
}
FAILED=0

QWEN_QUANTS="q8_0 q4_0 q4_k_m"; [ -n "${ALL:-}" ] && QWEN_QUANTS="fp16 $QWEN_QUANTS"
for q in $QWEN_QUANTS; do
  get "$HF/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-$q.gguf" \
      "models/qwen2.5-0.5b-instruct-$q.gguf"
done

for size in 135M 360M; do
  lower=$(echo "$size" | tr A-Z a-z)
  for q in f16 Q8_0 Q4_0 Q4_K_M; do
    ql=$(echo "$q" | tr A-Z a-z); [ "$ql" = f16 ] && ql=fp16
    get "$HF/bartowski/SmolLM2-$size-Instruct-GGUF/resolve/main/SmolLM2-$size-Instruct-$q.gguf" \
        "models/smollm2-$lower-instruct-$ql.gguf"
  done
done

ls -lh models/*.gguf
df -h . | tail -1
[ "$FAILED" = 0 ] || { echo "Some downloads failed; rerun to retry."; exit 1; }
