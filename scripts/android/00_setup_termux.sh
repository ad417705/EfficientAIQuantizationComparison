#!/data/data/com.termux/files/usr/bin/bash
# One-time setup on the Pixel 7, inside Termux (install Termux from F-Droid, not the Play Store).
# Builds the SAME llama.cpp version the Pi 3 uses (b3600), so device differences are hardware,
# not software. Run from the repo root:  bash scripts/android/00_setup_termux.sh
set -euo pipefail

LLAMA_TAG="${LLAMA_TAG:-b3600}"

pkg update -y
pkg install -y git cmake clang make python curl util-linux termux-api

[ -d llama.cpp ] || git clone --depth 1 --branch "$LLAMA_TAG" https://github.com/ggerganov/llama.cpp
cd llama.cpp
cmake -B build -DCMAKE_BUILD_TYPE=Release -DGGML_OPENMP=OFF
cmake --build build -j8 --target llama-bench llama-cli llama-server llama-perplexity llama-quantize

echo
echo "Built $(git describe --tags --always) -> llama.cpp/build/bin"
echo "CPU features (want asimddp = dot-product, i8mm is absent on Tensor G2):"
grep -m1 -o 'Features.*' /proc/cpuinfo
echo "Core layout (Tensor G2: cpu0-3 A55 little, cpu4-5 A78, cpu6-7 X1):"
for c in /sys/devices/system/cpu/cpu[0-9]*; do
  echo "  $(basename $c): max $(( $(cat $c/cpufreq/cpuinfo_max_freq 2>/dev/null || echo 0) / 1000 )) MHz"
done
