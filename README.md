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
