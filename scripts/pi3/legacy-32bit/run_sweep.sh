#!/bin/bash
# ^ "shebang" line — tells the system to run this with bash

# Move into the llama.cpp folder so ./llama-bench and ./models/ work
cd ~/llama.cpp

# Define an output file where all benchmark results will go
OUT=~/sweep_results.txt

# Write a header line to the file ( > overwrites, >> appends)
# $(date) is replaced with the current timestamp
echo "=== Sweep started: $(date) ===" > "$OUT"

# Loop over each model name. The backslash \ just continues
# the line so it's readable.
for MODEL in \
  SmolLM2-135M-Instruct-f16 \
  SmolLM2-135M-Instruct-Q8_0 \
  SmolLM2-135M-Instruct-Q4_K_M \
  SmolLM2-360M-Instruct-f16 \
  SmolLM2-360M-Instruct-Q8_0 \
  SmolLM2-360M-Instruct-Q4_K_M
do
  # Blank line + a section header for this model, with a timestamp
  echo "" >> "$OUT"
  echo "=== $MODEL - $(date) ===" >> "$OUT"

  # Run the benchmark on this model with your standard settings:
  #   -p 128   prefill 128 tokens
  #   -n 128   generate 128 tokens
  #   -t 4     use 4 CPU threads
  #   -b 128   batch size 128 (keeps memory lower)
  #   -r 3     repeat 3 times and average (for mean ± std)
  # 2>&1 means "also capture errors into the file," so if a model
  # fails to load, we see the error instead of losing it.
  ./llama-bench -m "models/${MODEL}.gguf" -p 128 -n 128 -t 4 -b 128 -r 3 >> "$OUT" 2>&1
done

# Final footer so we know the whole sweep ended cleanly
echo "" >> "$OUT"
echo "=== Sweep finished: $(date) ===" >> "$OUT"
