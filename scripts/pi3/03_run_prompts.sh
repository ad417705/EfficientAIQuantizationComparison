#!/usr/bin/env bash
# 100-prompt run on the Raspberry Pi 3 (reuses Joel's Python runner).
# Pilot:  bash scripts/pi3/03_run_prompts.sh --models smollm2-135m-instruct --runs 1
# Full :  nohup bash scripts/pi3/03_run_prompts.sh > prompts-pi3.log 2>&1 &
cd "$(dirname "$0")/../.."
exec python3 scripts/android/03_run_prompts.py \
  --device "Raspberry Pi 3" --cores 0-3 --threads 4 \
  --llama "$HOME/llama.cpp" \
  --quants fp16,q8_0,q4_0,q4_k_m \
  --ctx 512 --n-predict 128 --runs 1 \
  --results-dir results/pi3 \
  --logger scripts/pi3/power_log.sh --log-name power.csv "$@"
