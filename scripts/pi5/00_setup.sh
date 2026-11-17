#!/usr/bin/env bash
# One-time setup on the Raspberry Pi 5 (Raspberry Pi OS 64-bit). Builds the SAME llama.cpp
# version as the Pixel 7 and the Pi 3 runs (b3600), so device differences are hardware, not software.
# Run from the repo root:  bash scripts/pi5/00_setup.sh
set -euo pipefail
cd "$(dirname "$0")/../.."
LLAMA_TAG="${LLAMA_TAG:-b3600}"

sudo apt update
sudo apt install -y git cmake build-essential curl python3 util-linux

[ -d llama.cpp ] || git clone --depth 1 --branch "$LLAMA_TAG" https://github.com/ggerganov/llama.cpp
cd llama.cpp
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j4 --target llama-bench llama-cli llama-server llama-perplexity

echo
echo "Built $(git describe --tags --always) -> llama.cpp/build/bin"
echo "Board: $(tr -d '\0' < /proc/device-tree/model)"
echo "CPU features (Cortex-A76: asimddp yes, i8mm no):"
grep -m1 -o 'Features.*' /proc/cpuinfo
echo "Power reading check (should list rails with currents and volts):"
vcgencmd pmic_read_adc | head -4 || echo "vcgencmd pmic_read_adc not available"
