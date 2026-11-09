#!/usr/bin/env bash
# Download the GGUF files into ./models (works in Termux or on a Mac).
# Qwen comes from Qwen's official GGUF repo, the same files the Pi 3 runs used.
# SmolLM2 comes from bartowski's GGUF builds (same quant types).
# Usage: bash scripts/android/01_get_models.sh
set -euo pipefail
mkdir -p models
HF=https://huggingface.co

get() {  # url  dest
  if [ -s "$2" ]; then echo "have $2"; return; fi
  echo "-> $2"
  curl -fL --retry 3 -o "$2.part" "$1" && mv "$2.part" "$2" \
    || { rm -f "$2.part"; echo "!! failed: $1"; FAILED=1; }
}
FAILED=0

# Qwen2.5-0.5B-Instruct (official): fp16, q8_0, q4_0, q4_k_m
for q in fp16 q8_0 q4_0 q4_k_m; do
  get "$HF/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-$q.gguf" \
      "models/qwen2.5-0.5b-instruct-$q.gguf"
done

# SmolLM2-135M / 360M Instruct: f16, Q8_0, Q4_0, Q4_K_M
for size in 135M 360M; do
  lower=$(echo "$size" | tr A-Z a-z)
  for q in f16 Q8_0 Q4_0 Q4_K_M; do
    ql=$(echo "$q" | tr A-Z a-z); [ "$ql" = f16 ] && ql=fp16
    get "$HF/bartowski/SmolLM2-$size-Instruct-GGUF/resolve/main/SmolLM2-$size-Instruct-$q.gguf" \
        "models/smollm2-$lower-instruct-$ql.gguf"
  done
done

ls -lh models/*.gguf
if [ "$FAILED" = 1 ]; then
  echo "Some downloads failed. Tell Claude which ones; the fallback is converting on the Mac."
  exit 1
fi
