#!/usr/bin/env bash
# 100-prompt end-to-end run on the Raspberry Pi 5 (same runner as the Pixel 7, llama-server b3600).
# Power is logged to results/pi5/prompts/<stamp>/power.csv by scripts/pi5/power_log.sh.
# Usage (repo root):  bash scripts/pi5/03_run_prompts.sh                      # full: 12 configs x 3 passes
#                     bash scripts/pi5/03_run_prompts.sh --models smollm2-135m-instruct --quants q4_0 --runs 1   # pilot
# Summary afterwards:
#   python3 scripts/android/summarize_prompts.py results/pi5/prompts/<stamp> results/pi5/prompts/<stamp>/power.csv
cd "$(dirname "$0")/../.."
exec python3 scripts/android/03_run_prompts.py --device "Raspberry Pi 5" --cores 0-3 --threads 4 \
  --n-predict 128 --results-dir results/pi5 --logger scripts/pi5/power_log.sh --log-name power.csv "$@"
