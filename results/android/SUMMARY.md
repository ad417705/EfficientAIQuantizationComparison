# Android results: Pixel 7 (Tensor G2), llama.cpp b3600 CPU and MLC LLM GPU

Setup: 4 threads pinned to the big cores (4-7), batch 128, llama-bench with 3 repetitions after a warm-up.
The phone ran unplugged with the screen on. Whole-phone power came from the battery's voltage and current,
read over wireless adb about 1.6 times per second. "J/token" is whole-phone energy for that test divided
by the tokens it processed, idle power included. Full data: `llamacpp_summary.csv` (every model, weight,
KV-cache and flash-attention combination, 8 tests each); per-run files: `energy_*.csv`; MLC: `mlc_summary.csv`.

## llama.cpp on CPU (KV cache f16, flash attention off)

| Model | Weights | Prefill 256 tok/s | Prefill 2048 tok/s | Decode tok/s | Decode J/token | Prefill J/token |
|---|---|---|---|---|---|---|
| smollm2-135m | fp16 | 276 | 175 | 53.4 | 0.1438 | 0.0287 |
| smollm2-135m | q8_0 | 326 | 137 | 83.3 | 0.0486 | 0.0190 |
| smollm2-135m | q4_0 | 262 | 127 | 92.0 | 0.0429 | 0.0206 |
| smollm2-135m | q4_k_m | 227 | 115 | 86.0 | 0.0444 | 0.0254 |
| smollm2-360m | fp16 | 93 | 55 | 20.5 | 0.2197 | 0.0581 |
| smollm2-360m | q8_0 | 102 | 48 | 35.5 | 0.1318 | 0.0513 |
| smollm2-360m | q4_0 | 82 | 45 | 41.9 | 0.1066 | 0.0563 |
| smollm2-360m | q4_k_m | 69 | 38 | 34.4 | 0.1230 | 0.0681 |
| qwen2.5-0.5b | fp16 | 91 | 61 | 14.9 | 0.3486 | 0.1017 |
| qwen2.5-0.5b | q8_0 | 91 | 52 | 28.9 | 0.1519 | 0.0622 |
| qwen2.5-0.5b | q4_0 | 100 | 62 | 35.9 | 0.1395 | 0.0880 |
| qwen2.5-0.5b | q4_k_m | 68 | 48 | 31.9 | 0.1585 | 0.0800 |

## Findings

1. **Weight quantization is the main win for generation.** Q4_0 decodes 1.7x (135M), 2.0x (360M) and
   2.4x (Qwen 0.5B) faster than FP16, and it uses 2.1x to 3.4x less energy per generated token. Decode is
   limited by memory bandwidth, so smaller weights help directly.
2. **Q8_0 is almost as good as Q4_0** and gives the fastest short-prompt prefill on the SmolLM2 models. The
   Tensor G2 has 8-bit dot-product instructions (asimddp), so the INT8 path (≈W8A8) is cheap.
3. **Q4_K_M is slower than Q4_0 everywhere** (5 to 32%) and uses slightly more energy. Unpacking K-quants
   costs more on this CPU, which has no i8mm.
4. **Quantization does little for prefill.** Prefill is compute-bound. FP16 is about as fast as the
   quantized models and is often the fastest at 2048 tokens.
5. **Flash attention slows long prompts on this CPU.** In b3600, turning it on (which V-cache quantization
   requires) cuts 2048-token prefill by 12 to 44%. Decode is roughly unchanged.
6. **KV-cache quantization (q8_0, q4_0) gives no speed or energy gain** at these model sizes and context
   lengths. The KV cache is small next to the weights, so the extra dequantization work cancels the
   memory saving.
7. **llama.cpp on the CPU beats MLC LLM on the GPU for decode** by 2 to 5x. MLC's GPU was busy only 21 to 33%
   of decode time, so per-token CPU overhead dominates for models this small.

## MLC LLM on GPU (OpenCL, LM-Meter app, 100 prompts)

| Model | Weights | Time to first token | Decode tok/s |
|---|---|---|---|
| SmolLM2-135M | FP16 (q0f16) | 2.28 s | 17.6 |
| SmolLM2-135M | INT4 (q4f16_1) | 1.56 s | 18.2 |
| SmolLM2-360M | FP16 | 7.62 s | 12.5 |
| SmolLM2-360M | INT4 | 4.89 s | 15.4 |
| Qwen2.5-0.5B | FP16 | 9.05 s | 13.1 |
| Qwen2.5-0.5B | INT4 | 6.12 s | 16.5 |

## Caveats

- Energy is whole-phone (screen included), idle about 0.35 to 1.1 W. `net_J_per_tok` in the CSVs subtracts
  the idle level measured between configs.
- Short tests (pp128, 135M decode) last only a few seconds, so their energy figures are noisier.
- For 360M, wireless adb dropped twice. About a third of those configs use an estimate from Termux's
  current reading with interpolated voltage (`power_src = syslog`). The FP16 / KV f16 / FA-off config
  was rerun for its energy.
- The first config of each run starts with a cool phone, so it may run at higher clocks than later ones.
- The first 135M sweep (folder 20261107-110023) ran while charging. It is superseded by 20261108-071040.
