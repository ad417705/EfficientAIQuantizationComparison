# Efficient AI: Comparing Quantization Across Hardware

CSC 4814 group project. We measure how INT8/INT4 weight quantization and KV-cache
quantization change latency, throughput, memory, energy and accuracy for small language
models on edge hardware.

**Results at a glance:** [`results/SUMMARY_3devices.md`](results/SUMMARY_3devices.md) compares all
three devices. Per-device detail is in [`results/android/SUMMARY.md`](results/android/SUMMARY.md)
(Pixel 7, including the MLC LLM GPU runs) and in `results/pi5/`.

## Hardware

| Device | CPU | RAM | OS | Energy measurement |
|---|---|---|---|---|
| Raspberry Pi 3 | 4x Cortex-A53 | 1 GB | Raspbian Buster 32-bit | none |
| Raspberry Pi 5 | 4x Cortex-A76 | 4 GB | Raspberry Pi OS (Debian 13) 64-bit | PMIC rails (`vcgencmd pmic_read_adc`) |
| Pixel 7 (Tensor G2), Hung Nguyen | 2x X1 + 2x A78 used | 8 GB | Android 13, Termux | battery voltage and current over adb |

## Runtimes

- **llama.cpp b3600** (GGUF, CPU, 4 threads, batch 128): the same build on every device, so the
  differences come from the hardware.
- **MLC LLM** (OpenCL GPU, Pixel 7 only, through the LM-Meter app), for a runtime comparison.

## Models and quantization settings

Models: SmolLM2-135M-Instruct, SmolLM2-360M-Instruct, Qwen2.5-0.5B-Instruct (the official Qwen GGUFs
and bartowski's SmolLM2 GGUFs).

| Proposal label | llama.cpp setting |
|---|---|
| FP16 reference | `fp16` GGUF |
| INT8 (W8A8) | `Q8_0` (activations are quantized to 8-bit inside the matmul) |
| INT4 (W4A8) | `Q4_0`; `Q4_K_M` is kept for comparison with the Pi 3 runs |
| KV-cache quant | `-ctk/-ctv q8_0` or `q4_0`, which needs flash attention (`-fa 1`) |

Every sweep covers 3 models x 4 weight types x 4 KV/flash-attention settings. Each setting runs prefill of
128/256/1024/2048 tokens, decode of 128/512 tokens, and decode of 128 tokens after a 1024- or 2048-token
prompt, with 3 repetitions after a warm-up. A separate run sends a fixed set of 100 prompts
([`data/prompts_readable.md`](data/prompts_readable.md)) through llama-server, 3 passes each, to
measure end-to-end latency, peak memory, energy per answer and an accuracy proxy.

## Repository layout

```
scripts/            Pi 3 scripts
scripts/android/    Pixel 7: Termux setup, model download, sweep, 100-prompt run, energy and summary tools
scripts/pi5/        Raspberry Pi 5: setup, sweep, 100-prompt run, PMIC power logger
scripts/compare_devices.py   builds the three-device table
data/               the 100-prompt set
results/benchmarks.csv       shared table, one row per device x model x quant x test
results/android/    Pixel 7 raw runs, power logs, energy tables, MLC results, SUMMARY.md
results/pi5/        Pi 5 raw runs (with power.csv), energy and prompt summaries
notes/              setup log and planning
```

## Reproducing

### Raspberry Pi 5 (see `scripts/pi5/README.md`)

```bash
git clone -b RaspberryPi https://github.com/joeln1011/EfficientAIQuantizationComparison.git
cd EfficientAIQuantizationComparison
bash scripts/pi5/00_setup.sh                     # build llama.cpp b3600 (~10-15 min)
bash scripts/pi5/01_get_models.sh                # 12 GGUF files into ./models (~4.5 GB)
PILOT=1 bash scripts/pi5/02_bench_sweep.sh       # 3-minute pipeline check
nohup bash scripts/pi5/02_bench_sweep.sh > sweep-pi5.log 2>&1 &     # full sweep (~8 h)
nohup bash scripts/pi5/03_run_prompts.sh > prompts-pi5.log 2>&1 &   # 100 prompts (~3.5 h)

d=results/pi5/raw/<stamp>
python3 scripts/android/energy.py $d $d/power.csv > results/pi5/energy_pi5.csv
```

### Pixel 7 (in Termux on the phone, from the repo root)

```bash
pkg install -y git && git clone -b Android https://github.com/joeln1011/EfficientAIQuantizationComparison.git
cd EfficientAIQuantizationComparison
bash scripts/android/00_setup_termux.sh          # build llama.cpp b3600 (~10 min)
bash scripts/android/01_get_models.sh            # 12 GGUF files into ./models
PILOT=1 bash scripts/android/02_bench_sweep.sh   # pipeline check
nohup bash scripts/android/02_bench_sweep.sh > sweep.log 2>&1 &
nohup python3 scripts/android/03_run_prompts.py --n-predict 128 > prompts-run.log 2>&1 &
```

Energy on the Pixel: Termux can't read the battery voltage, so a Mac logs it over wireless adb while
the phone is **unplugged**, with the screen kept on:

```bash
bash scripts/android/power_log_adb.sh results/android/power/<name>.csv     # on the Mac, Ctrl-C to stop
python3 scripts/android/energy.py results/android/raw/<stamp> results/android/power/<name>*.csv
python3 scripts/android/summarize.py                                       # all models -> llamacpp_summary.csv
```

## Measurement rules

- Nothing else running, with a cooldown between configs (30 s for sweeps, 20 s for prompt runs).
- Pixel: unplugged, battery above 50% at the start, screen on. Readings taken while charging are discarded.
- Pi: log the temperature and throttle flags. A non-zero `throttled` value means the run was slowed.
- Energy is whole-device power x time / tokens. `net_J_per_tok` subtracts the idle power measured between configs.
