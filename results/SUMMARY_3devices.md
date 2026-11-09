# Three-device comparison: Raspberry Pi 3, Raspberry Pi 5, Pixel 7

The same llama.cpp version (b3600) runs on the CPU of every device, with 4 threads and batch 128.
The KV cache is f16 and flash attention is off, which matches the Pi 3 runs. The model files are
identical GGUFs. Sources: Pi 3 rows come from the team's `results/benchmarks.csv` on the RaspberryPI
branch (first sweep). The Pi 5 rows come from `results/pi5/`, and the Pixel 7 rows from `results/android/`.
Full table: `results/compare_devices.csv`, built by `scripts/compare_devices.py`.

| | Raspberry Pi 3 | Raspberry Pi 5 | Pixel 7 |
|---|---|---|---|
| CPU | 4x Cortex-A53 1.2 GHz | 4x Cortex-A76 2.4 GHz | 2x X1 + 2x A78 (cores 4-7 used) |
| Memory | 1 GB LPDDR2 | 4 GB LPDDR4X | 8 GB LPDDR5 |
| OS | Raspbian Buster 32-bit | Raspberry Pi OS (Debian 13) 64-bit | Android 13, Termux |
| Energy measured | no | yes, PMIC rails | yes, battery |

## Speed and energy

| Model | Weights | Prefill 128 tok/s (Pi 3 / Pi 5 / Pixel 7) | Decode 128 tok/s (Pi 3 / Pi 5 / Pixel 7) | Decode J/token (Pi 5 / Pixel 7) |
|---|---|---|---|---|
| SmolLM2-135M | fp16 | 5.4 / 101 / 279 | 5.1 / 19.3 / 53.4 | 0.280 / 0.144 |
| SmolLM2-135M | q8_0 | 19.5 / 201 / 338 | 7.1 / 60.7 / 83.3 | 0.101 / 0.049 |
| SmolLM2-135M | q4_0 | n/a / 195 / 268 | n/a / 82.4 / 92.0 | 0.091 / 0.043 |
| SmolLM2-135M | q4_k_m | 10.1 / 168 / 238 | 4.6 / 73.3 / 86.0 | 0.074 / 0.044 |
| SmolLM2-360M | fp16 | 3.3 / 46 / 102 | 2.1 / 10.0 / 20.5 | 0.525 / 0.220 |
| SmolLM2-360M | q8_0 | 5.3 / 72 / 111 | 3.0 / 23.6 / 35.5 | 0.246 / 0.132 |
| SmolLM2-360M | q4_0 | n/a / 70 / 91 | n/a / 36.0 / 41.9 | 0.175 / 0.107 |
| SmolLM2-360M | q4_k_m | 2.9 / 60 / 77 | 1.8 / 33.1 / 34.4 | 0.186 / 0.123 |
| Qwen2.5-0.5B | fp16 | n/a / 40 / 93 | n/a / 7.6 / 14.9 | 0.666 / 0.349 |
| Qwen2.5-0.5B | q8_0 | 4.0 / 63 / 107 | 2.4 / 16.7 / 28.9 | 0.326 / 0.152 |
| Qwen2.5-0.5B | q4_0 | 4.0 / 63 / 108 | 2.5 / 25.2 / 35.9 | 0.232 / 0.140 |
| Qwen2.5-0.5B | q4_k_m | 2.0 / 53 / 78 | 1.4 / 22.1 / 31.9 | 0.286 / 0.159 |

## Findings

1. **Pixel 7 > Pi 5 >> Pi 3.** The Pi 5 decodes 5 to 18x faster than the Pi 3. The Pixel 7 decodes
   1.1 to 2.1x faster than the Pi 5 (leaving out the cold-start outlier below). The gap is widest for FP16,
   which needs the most memory bandwidth.
2. **The Pi 3's gap is partly software.** It runs a 32-bit OS, so llama.cpp can't use the 64-bit
   dot-product kernels the other two devices rely on. It also throttled at 71 to 75 °C. The Pi 5 peaked
   at 76 °C with no throttling.
3. **The slower the memory, the more quantization pays off.** Going from FP16 to Q4_0 speeds up decode
   2.8 to 3.6x on the Pi 5, against 1.7 to 2.4x on the Pixel. The weights have to be streamed from memory
   for every token, and that matters more on the Pi.
4. **Q4_0 is the best format on the two 64-bit devices.** On the Pi 3, Q4_K_M is the slowest format, slower
   even than FP16 for SmolLM2-135M. K-quant unpacking costs a lot without dot-product instructions.
5. **The Pixel 7 is about twice as energy-efficient as the Pi 5** (Qwen Q4_0: 0.14 against 0.23 J per
   generated token), even though the Pixel figure includes the screen. Part of the Pi 5's cost is its
   roughly 1.9 W idle draw.
6. **Accuracy is a property of the weights, not the device.** On the 100-prompt set, Qwen2.5-0.5B scores
   91 to 97% on both the Pi 5 and the Pixel with every weight type.

## 100-prompt end-to-end (Qwen2.5-0.5B, average per answer)

| Device | Weights | Accuracy | Time to first token | Answer time | Peak memory | Energy |
|---|---|---|---|---|---|---|
| Pi 5 | FP16 | 95% | 0.85 s | 12.7 s | 1244 MB | 66.6 J |
| Pi 5 | Q4_0 | 91% | 0.52 s | 3.8 s | 516 MB | 24.7 J |
| Pixel 7 | FP16 | 95% | 0.65 s | 7.9 s | 1304 MB | 27.5 J |
| Pixel 7 | Q4_0 | 94% | 0.65 s | 3.9 s | 511 MB | 13.3 J |

## Caveats

- The Pi 3 has no energy data. Its sweep left out some settings (Q4_0 for SmolLM2, FP16 for Qwen), shown as n/a.
- The Pi 5 SmolLM2-135M FP16 decode of 19.3 tok/s is the run's very first config and looks like a
  cold-start outlier. The same weights with flash attention on decode at about 29 to 30 tok/s.
- The two energy methods differ. The Pi 5 reading sums the PMIC rails, so it excludes power-supply
  losses and USB devices. The Pixel reading is the whole phone from the battery, screen included.
