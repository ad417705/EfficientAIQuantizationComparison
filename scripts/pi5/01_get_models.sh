#!/usr/bin/env bash
# Same 12 GGUF files as the Pixel 7 (Qwen official GGUFs + bartowski SmolLM2), into ./models.
exec bash "$(dirname "$0")/../android/01_get_models.sh"
