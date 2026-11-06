# Efficient AI: Comparing Quantization Across Hardware

CSC 4814 group project — measuring how INT8/INT4 quantization affects
latency, throughput, memory, and energy on edge hardware.

## Hardware
- Raspberry Pi 3 (1GB RAM, 32-bit Raspbian Buster) — this repo
- Android Pixel 7 — Hung Nguyen

## Runtime
- llama.cpp (GGUF models)

## Models
- Qwen2.5-0.5B-Instruct (primary)
- SmolLM2 (smoke test)

## Structure
- scripts/ — benchmark + measurement scripts
- results/ — raw numbers (CSV) and logs
- notes/   — setup log and planning

## Android (Pixel 7) — `Android` branch

Same llama.cpp build as the Pi 3 (**b3600**), CPU only, run inside Termux.

| Proposal label | Setting |
|---|---|
| FP16 reference | `fp16` GGUF |
| INT8 (W8A8) | `Q8_0` (activations quantized to 8-bit inside the matmul) |
| INT4 (W4A8) | `Q4_0`; `Q4_K_M` kept for comparison with the Pi |
| KV-cache quant | `-ctk/-ctv q8_0` or `q4_0`, needs flash attention (`-fa 1`) |

Models: SmolLM2-135M-Instruct, SmolLM2-360M-Instruct, Qwen2.5-0.5B-Instruct
(Qwen files are the official GGUFs, the same ones the Pi runs).

### Steps (in Termux on the phone, from the repo root)

```bash
pkg install -y git && git clone -b Android https://github.com/ad417705/EfficientAIQuantizationComparison
cd EfficientAIQuantizationComparison
bash scripts/android/00_setup_termux.sh      # build llama.cpp b3600 (~10 min)
bash scripts/android/01_get_models.sh        # 12 GGUF files into ./models (~3.3 GB)
termux-wake-lock                             # keep the CPU awake with the screen off

# 1. pilot: checks the whole pipeline in a few minutes
PILOT=1 bash scripts/android/02_bench_sweep.sh
python3 scripts/android/03_run_prompts.py --models smollm2-135m-instruct --quants q4_0 --runs 1

# 2. pick the thread count once
THREADS_LIST="1 2 4 6 8" MODELS=qwen2.5-0.5b-instruct QUANTS=q4_0 KVS=f16 \
  PP=128 TG=128 bash scripts/android/02_bench_sweep.sh

# 3. full sweep (hours; unplug the phone so the battery log measures energy)
bash scripts/android/02_bench_sweep.sh
python3 scripts/android/03_run_prompts.py
```

Each sweep writes raw llama-bench CSVs, a 1 Hz battery/thermal log (`syslog.csv`) and
start/end times (`events.log`) to `results/android/raw/<timestamp>/`, and appends summary
rows to the shared `results/benchmarks.csv` (KV type, flash attention and cores in `notes`).

Measurement rules: phone unplugged, battery above 50%, airplane mode, same room
temperature, and let it cool between sessions. Battery power (`voltage_now x current_now`)
is whole-phone draw, so subtract the idle baseline recorded in the first 10 s.
