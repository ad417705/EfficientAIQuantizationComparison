#!/usr/bin/env bash
# One-time setup on the Raspberry Pi 3 (Raspberry Pi OS Lite 64-bit recommended; 32-bit also works).
# Builds the SAME llama.cpp version as the Pi 5 and Pixel 7 (b3600), so differences are hardware.
# The Pi 3 has only 1 GB RAM: the build uses 2 jobs, and a 1 GB+ swap file is strongly advised.
# Run from the repo root:  bash scripts/pi3/00_setup.sh
set -euo pipefail
cd "$(dirname "$0")/../.."
LLAMA_TAG="${LLAMA_TAG:-b3600}"
JOBS="${JOBS:-2}"

sudo apt update
sudo apt install -y git cmake build-essential curl python3 util-linux

swap_mb=$(awk '/SwapTotal/ {print int($2/1024)}' /proc/meminfo)
if [ "$swap_mb" -lt 1000 ]; then
  echo "!! Swap is only ${swap_mb} MB. The build can run out of memory on a 1 GB Pi."
  echo "   Raise it first, e.g. on Raspberry Pi OS:"
  echo "     sudo sed -i 's/^CONF_SWAPSIZE=.*/CONF_SWAPSIZE=1024/' /etc/dphys-swapfile && sudo systemctl restart dphys-swapfile"
  echo "   (or JOBS=1 bash scripts/pi3/00_setup.sh to build slowly with less memory)"
fi

[ -d llama.cpp ] || git clone --depth 1 --branch "$LLAMA_TAG" https://github.com/ggerganov/llama.cpp
cd llama.cpp
TARGETS="llama-bench llama-cli llama-server llama-perplexity"
# b3600 needs CMake >= 3.14. Raspbian Buster ships 3.13, so fall back to the Makefile there.
if cmake --version | awk 'NR==1 {split($3, v, "."); exit !(v[1] > 3 || (v[1] == 3 && v[2] >= 14))}'; then
  cmake -B build -DCMAKE_BUILD_TYPE=Release
  cmake --build build -j"$JOBS" --target $TARGETS
else
  make -j"$JOBS" $TARGETS
  mkdir -p build/bin && for t in $TARGETS; do ln -sf "../../$t" "build/bin/$t"; done
fi

echo
echo "Built $(git describe --tags --always) -> llama.cpp/build/bin"
echo "Board: $(tr -d '\0' < /proc/device-tree/model)"
echo "Arch: $(uname -m)  (aarch64 = 64-bit OS, armv7l = 32-bit OS)"
echo "OS: $(. /etc/os-release && echo "$PRETTY_NAME")"
echo "CPU features (Cortex-A53: asimd yes, asimddp no):"
grep -m1 -o -E '(Features|flags).*' /proc/cpuinfo
free -m
