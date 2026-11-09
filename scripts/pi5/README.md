# Raspberry Pi 5 runs

Same llama.cpp version (b3600), models, sweep and 100-prompt set as the Pixel 7 (`scripts/android`),
so differences between devices come from the hardware, not the software.
The Pi 5 has 4 Cortex-A76 cores (asimddp, no i8mm) and can read its own power from the PMIC,
so energy per token comes out of the box. No external meter is needed.

Run everything from the repo root on the Pi:

```bash
bash scripts/pi5/00_setup.sh            # apt packages + build llama.cpp b3600 (~10-15 min)
bash scripts/pi5/01_get_models.sh       # 12 GGUF files into ./models (~4.5 GB)

PILOT=1 bash scripts/pi5/02_bench_sweep.sh          # 2-minute check of the whole pipeline
nohup bash scripts/pi5/02_bench_sweep.sh > sweep-pi5.log 2>&1 &   # full sweep, all 3 models
tail -3 sweep-pi5.log                               # progress

bash scripts/pi5/03_run_prompts.sh --models smollm2-135m-instruct --quants q4_0 --runs 1   # pilot
nohup bash scripts/pi5/03_run_prompts.sh > prompts-pi5.log 2>&1 &                          # full
```

Results:

- `results/pi5/raw/<stamp>/`: llama-bench CSVs, `events.log`, `power.csv` (power, temperature, clock,
  throttle flags at about 2 Hz). Rows are also appended to `results/benchmarks.csv`.
- Energy per token: `python3 scripts/android/energy.py results/pi5/raw/<stamp> results/pi5/raw/<stamp>/power.csv`
- `results/pi5/prompts/<stamp>/`: 100-prompt outputs, with `power.csv`. Summary:
  `python3 scripts/android/summarize_prompts.py results/pi5/prompts/<stamp> results/pi5/prompts/<stamp>/power.csv`

Notes:

- Power is the sum of the PMIC rails (SoC, RAM and on-board supplies). It excludes USB devices and the
  power supply's own losses, so it reads a little below wall power. Unplug USB devices you don't need.
- The Pi 5 throttles at about 80 to 85 °C without a cooler. `power.csv` logs temperature and the
  `throttled` flags. A non-zero value means the run was slowed and should be noted or repeated.
