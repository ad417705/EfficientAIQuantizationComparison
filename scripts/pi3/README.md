# Raspberry Pi 3 runs

Same llama.cpp version (b3600), models, sweep structure, 100-prompt set and output format as the
Pi 5 (`scripts/pi5`) and the Pixel 7 (`scripts/android`), so the three devices can be compared row
for row. The Pi 3 has 4 Cortex-A53 cores at 1.2 GHz (NEON, no dot-product instructions) and only
1 GB of RAM, so the defaults are trimmed:

| | Pi 5 / Pixel 7 | Pi 3 |
|---|---|---|
| Prefill lengths | 128, 256, 1024, 2048 | 128, 256 |
| Decode lengths | 128, 512 | 128 |
| Prefill then decode | 1024+128, 2048+128 | 512+128 |
| Qwen2.5-0.5B FP16 | yes | skipped (~1 GB, does not fit) |
| 100 prompts | 3 passes, all 12 models | 1 pass, Qwen Q8_0 / Q4_0 / Q4_K_M by default |
| Energy | measured (PMIC / battery) | **estimated** from CPU load (see below) |

Any of these can be changed with environment variables or arguments (see the top of each script).

## OS

Use **Raspberry Pi OS Lite (64-bit)** if you can: flash it with Raspberry Pi Imager and turn on SSH
in Imager's settings. The Pi 5 and Pixel 7 both run 64-bit, so this keeps the comparison about the
hardware. The scripts also run on the old 32-bit Raspbian Buster image; `meta.txt` records which
one was used (`aarch64` or `armv7l`), and the 32-bit results from the first Pi 3 runs are kept in
`results/pi3/legacy-32bit/`.

## Steps

Run everything over SSH, from the repo root on the Pi:

```bash
git clone -b RaspberryPi3 https://github.com/ad417705/EfficientAIQuantizationComparison.git
cd EfficientAIQuantizationComparison

bash scripts/pi3/00_setup.sh            # apt packages + build llama.cpp b3600 (~40-60 min on a Pi 3)
bash scripts/pi3/01_get_models.sh       # 11 GGUF files into ./models (~3.7 GB)

PILOT=1 bash scripts/pi3/02_bench_sweep.sh                         # ~5-minute pipeline check
nohup bash scripts/pi3/02_bench_sweep.sh > sweep-pi3.log 2>&1 &    # full sweep (~12 h)
tail -3 sweep-pi3.log                                              # progress

bash scripts/pi3/03_run_prompts.sh --models smollm2-135m-instruct --quants q4_0   # pilot
nohup bash scripts/pi3/03_run_prompts.sh > prompts-pi3.log 2>&1 &                 # Qwen, ~6-7 h
```

`nohup ... &` keeps a run going after you close SSH. Before the build, give the Pi at least 1 GB of
swap (`00_setup.sh` prints the command if it is lower), or the compiler can run out of memory.

## Results

- `results/pi3/raw/<stamp>/`: llama-bench CSVs, `meta.txt`, `events.log`, `power.csv` (temperature,
  clock, throttle flags, CPU load, free memory, estimated power at 1 Hz). Rows are also appended to
  `results/benchmarks.csv` with `device=Raspberry Pi 3`.
- Estimated energy per token:
  `python3 scripts/android/energy.py results/pi3/raw/<stamp> results/pi3/raw/<stamp>/power.csv > results/pi3/energy_pi3.csv`
- `results/pi3/prompts/<stamp>/`: 100-prompt outputs with `power.csv`. Summary:
  `python3 scripts/android/summarize_prompts.py results/pi3/prompts/<stamp> results/pi3/prompts/<stamp>/power.csv > results/pi3/prompts_summary_pi3.csv`

Commit `results/pi3/` and `results/benchmarks.csv` (the `.gitignore` already keeps model files and
llama.cpp out), then push the `RaspberryPi3` branch.

## Notes

- **Energy is an estimate.** The Pi 3 cannot read its own power. `scripts/pi3/temp_log.sh` uses the
  same model as the first Pi 3 runs: 1.4 W idle to 3.5 W at full load, linear in CPU use
  (`IDLE_MW` / `MAX_MW` to change it). Its `status` column says `Estimated`. Report it separately from
  the Pi 5 and Pixel 7 numbers, which are measured.
- The Pi 3 throttles at about 80 °C (and the first runs saw it from 71 °C). Use a heatsink if you have
  one. A non-zero `throttled` value in `power.csv` means the run was slowed and should be noted or repeated.
- Use a proper 2.5 A supply. Under-voltage also shows in `throttled` (bit 0x1 / 0x10000).
- Models larger than the free RAM are skipped and listed in `<run>/skipped.txt` (`FORCE=1` to try anyway).
