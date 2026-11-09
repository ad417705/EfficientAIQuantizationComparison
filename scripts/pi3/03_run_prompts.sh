#!/usr/bin/env bash
# 100-prompt end-to-end run on the Raspberry Pi 3 (same runner as the Pi 5 and Pixel 7, llama-server b3600).
# The Pi 3 decodes at only ~2-7 tokens/s, so the defaults are trimmed: 1 pass, a 2048-token context
# (saves RAM), and Qwen2.5-0.5B without FP16 (does not fit in 1 GB). That is about 6-7 hours.
# Anything you pass is applied after these defaults, so it overrides them.
# Temperature, throttling and ESTIMATED power go to results/pi3/prompts/<stamp>/power.csv.
# Usage (repo root):
#   bash scripts/pi3/03_run_prompts.sh --models smollm2-135m-instruct --quants q4_0 --runs 1   # pilot (~15 min)
#   nohup bash scripts/pi3/03_run_prompts.sh > prompts-pi3.log 2>&1 &                          # Qwen, 3 quants
#   nohup bash scripts/pi3/03_run_prompts.sh --models smollm2-135m-instruct,smollm2-360m-instruct \
#     --quants fp16,q8_0,q4_0,q4_k_m > prompts-pi3-smol.log 2>&1 &                             # SmolLM2 too
# Summary afterwards:
#   python3 scripts/android/summarize_prompts.py results/pi3/prompts/<stamp> results/pi3/prompts/<stamp>/power.csv
cd "$(dirname "$0")/../.."
exec python3 scripts/android/03_run_prompts.py --device "Raspberry Pi 3" --cores 0-3 --threads 4 \
  --n-predict 128 --ctx 2048 --runs 1 --models qwen2.5-0.5b-instruct --quants q8_0,q4_0,q4_k_m \
  --results-dir results/pi3 --logger scripts/pi3/temp_log.sh --log-name power.csv "$@"
