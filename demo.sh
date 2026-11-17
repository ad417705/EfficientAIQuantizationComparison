#!/usr/bin/env bash
# Live demo for slide 18: run the same model and prompt on this device and print a
# results card with speed, memory, power, energy per token, temperature and a quick
# 5-question accuracy check. Works on the Pixel 7 (Termux), Raspberry Pi 5 and Raspberry Pi 3.
#
# Usage:  bash demo.sh                 # full demo (answer + 5-question check)
#         bash demo.sh --quick         # skip the 5-question check (saves ~1 min on the Pi 3)
#         MODEL=path/to.gguf LLAMA=path/to/llama-cli bash demo.sh
#
# Power: Pi 5 = measured (PMIC rails). Pixel 7 = measured (battery; phone must be unplugged).
#        Pi 3 = ESTIMATED from CPU load (1.4 W idle .. 3.5 W full), same as our results.

QUICK=0; [ "$1" = "--quick" ] && QUICK=1
PROMPT="Q: Why is the sky blue? Answer in two sentences.
A:"
N_PREDICT=64
TMP=$(mktemp -d "${TMPDIR:-/tmp}/demo.XXXXXX")
trap 'rm -f "$TMP/run"; rm -rf "$TMP"' EXIT

# ---------- which device is this? ----------
if [ -n "$TERMUX_VERSION" ] || [ -d /data/data/com.termux ]; then
  DEV=pixel; NAME="Google Pixel 7"
elif vcgencmd pmic_read_adc >/dev/null 2>&1; then
  DEV=pi5; NAME="Raspberry Pi 5"
else
  DEV=pi3; NAME="Raspberry Pi 3"
fi

# ---------- find llama-cli and the model ----------
if [ -z "$LLAMA" ]; then
  for c in ./llama.cpp/build/bin/llama-cli ~/EfficientAIQuantizationComparison/llama.cpp/build/bin/llama-cli \
           ~/llama.cpp/build/bin/llama-cli ~/llama.cpp/llama-cli ./llama-cli; do
    [ -x "$c" ] && { LLAMA=$c; break; }
  done
fi
if [ -z "$MODEL" ]; then
  MODEL=$(find . ./models ~/EfficientAIQuantizationComparison/models ~/llama.cpp/models ~/models \
          -maxdepth 1 -iname 'qwen2.5-0.5b-instruct-q4_0.gguf' 2>/dev/null | head -1)
fi
[ -x "$LLAMA" ] || { echo "llama-cli not found. Run with LLAMA=/path/to/llama-cli"; exit 1; }
[ -f "$MODEL" ] || { echo "Qwen Q4_0 model not found. Run with MODEL=/path/to/model.gguf"; exit 1; }

RUN=("$LLAMA")
# On the Pixel, pin to the big cores like in our benchmarks.
[ "$DEV" = pixel ] && command -v taskset >/dev/null && RUN=(taskset -c 4-7 "$LLAMA")

# ---------- power / temperature sampler (runs in the background) ----------
read_power_mw() {   # prints power in mW
  case $DEV in
    pi5)
      vcgencmd pmic_read_adc | awk -F'[ =]+' '
        { n=$2; v=$NF; sub(/[AV]$/, "", v)
          if (n ~ /_A$/) a[substr(n,1,length(n)-2)]=v; else if (n ~ /_V$/) u[substr(n,1,length(n)-2)]=v }
        END { s=0; for (k in a) if (k in u) s+=a[k]*u[k]; printf "%.0f\n", s*1000 }' ;;
    pixel)
      if [ -r /sys/class/power_supply/battery/current_now ] && [ -r /sys/class/power_supply/battery/voltage_now ]; then
        awk -v i="$(cat /sys/class/power_supply/battery/current_now)" -v v="$(cat /sys/class/power_supply/battery/voltage_now)" \
          'BEGIN{ if (i<0) i=-i; printf "%.0f\n", i/1e6 * v/1e6 * 1000 }'
      elif command -v termux-battery-status >/dev/null; then
        termux-battery-status | tr -d ' ,"' | awk -F: '
          $1=="current"{i=$2} $1=="voltage"{v=$2}
          END{ if (i=="") exit; if (i<0) i=-i; if (v=="" || v==0) v=3870; if (v<100) v=v*1000;
               printf "%.0f\n", i/1e6 * v/1000 * 1000 }'
      fi ;;
    pi3)
      read -r _ u n s i w q sq st _ < /proc/stat
      t=$((u+n+s+i+w+q+sq+st))
      if [ -n "$P3T" ] && [ $((t-P3T)) -gt 0 ]; then
        echo $(( 1400 + 21 * 100 * ((t-P3T) - (i-P3I)) / (t-P3T) ))
      fi
      P3T=$t; P3I=$i ;;
  esac
}
read_temp_c() {
  case $DEV in
    pi3|pi5) vcgencmd measure_temp 2>/dev/null | grep -o '[0-9.]*' ;;
    pixel)   command -v termux-battery-status >/dev/null &&
             termux-battery-status | tr -d ' ,"' | awk -F: '$1=="temperature"{print $2}' ;;
  esac
}
sampler() {
  while [ -e "$TMP/run" ]; do
    read_power_mw >> "$TMP/power"   # no subshell, so the Pi 3 keeps its CPU counters
    t=$(read_temp_c);   [ -n "$t" ] && echo "$t" >> "$TMP/temp"
    sleep 0.5
  done
}

# ---------- 1) the live answer, with memory and power sampling ----------
if [ "$DEV" = pixel ] && command -v termux-battery-status >/dev/null &&
   termux-battery-status | grep -q '"plugged": *"PLUGGED'; then
  echo "NOTE: phone is plugged in, so the power reading will be wrong. Unplug it for the demo."
fi
echo "=== $NAME: Qwen2.5-0.5B, 4-bit (Q4_0), 4 threads ==="
echo "$PROMPT"
touch "$TMP/run"; sampler & SPID=$!
"${RUN[@]}" -m "$MODEL" -t 4 -n $N_PREDICT --temp 0 --no-display-prompt -p "$PROMPT" 2> "$TMP/log" &
LPID=$!
PEAK_KB=0
while kill -0 $LPID 2>/dev/null; do
  h=$(awk '/VmHWM/{print $2}' /proc/$LPID/status 2>/dev/null)
  [ -n "$h" ] && [ "$h" -gt "$PEAK_KB" ] && PEAK_KB=$h
  sleep 0.2
done
wait $LPID
rm -f "$TMP/run"; wait $SPID 2>/dev/null
echo

# Parse llama.cpp's timing lines (works for both old and new log formats).
PF_TPS=$(awk '/prompt eval time/{for(i=1;i<=NF;i++) if($i=="tokens" && $(i+1)=="per") print $(i-1)}' "$TMP/log" | tail -1)
read -r EV_MS EV_TOK DEC_TPS < <(awk '/eval time/ && !/prompt eval/{
    for(i=1;i<=NF;i++){ if($i=="=") ms=$(i+1); if($i=="/") n=$(i+1); if($i=="tokens" && $(i+1)=="per") tps=$(i-1) } }
    END{print ms, n, tps}' "$TMP/log")
PF_MS=$(awk '/prompt eval time/{for(i=1;i<=NF;i++) if($i=="=") print $(i+1)}' "$TMP/log" | tail -1)

AVG_MW=$( [ -s "$TMP/power" ] && awk '{s+=$1; n++} END{printf "%.0f", s/n}' "$TMP/power")
MAX_T=$(  [ -s "$TMP/temp" ]  && sort -n "$TMP/temp" | tail -1)
J_TOK=""
if [ -n "$AVG_MW" ] && [ -n "$EV_TOK" ] && [ "$EV_TOK" -gt 0 ] 2>/dev/null; then
  J_TOK=$(awk -v p="$AVG_MW" -v a="$PF_MS" -v b="$EV_MS" -v n="$EV_TOK" 'BEGIN{printf "%.3f", p/1000*(a+b)/1000/n}')
fi
case $DEV in pi3) PSRC="ESTIMATED from CPU load";; pi5) PSRC="measured, PMIC";; pixel) PSRC="measured, battery";; esac

# ---------- 2) quick accuracy check: 5 questions from our 100-prompt set ----------
ACC="skipped (--quick)"
if [ $QUICK = 0 ]; then
  echo "Quick accuracy check (5 questions from our 100-prompt set):"
  ok=0
  while IFS='|' read -r q a; do
    out=$("${RUN[@]}" -m "$MODEL" -t 4 -n 12 --temp 0 --no-display-prompt -p "Q: $q
A:" 2>/dev/null | awk 'BEGIN{RS=""} NR==1' | sed '/^Q:/,$d' | tr '\n' ' ')
    if echo "$out" | grep -qiw -- "$a"; then ok=$((ok+1)); mark="correct"; else mark="WRONG"; fi
    printf "  %-48s -> %-24s [%s]\n" "$q" "$(echo "$out" | cut -c1-24)" "$mark"
  done <<'EOF'
What is the capital of France?|Paris
What is the largest planet in the solar system?|Jupiter
What is the chemical symbol for gold?|Au
What is the capital of Japan?|Tokyo
Which planet is known as the Red Planet?|Mars
EOF
  ACC="$ok / 5 correct"
fi

# ---------- 3) results card ----------
echo
echo "+------------------------------------------------------+"
printf "| %-52s |\n" "RESULTS: $NAME"
echo "+------------------------------------------------------+"
printf "| %-20s %-31s |\n" "Prefill speed"   "${PF_TPS:-n/a} tokens/s"
printf "| %-20s %-31s |\n" "Decode speed"    "${DEC_TPS:-n/a} tokens/s"
printf "| %-20s %-31s |\n" "Peak memory"     "$((PEAK_KB/1024)) MB"
printf "| %-20s %-31s |\n" "Average power"   "$( [ -n "$AVG_MW" ] && awk -v p="$AVG_MW" 'BEGIN{printf "%.2f W", p/1000}' || echo n/a)"
printf "| %-20s %-31s |\n" ""                "($PSRC)"
printf "| %-20s %-31s |\n" "Energy per token" "${J_TOK:-n/a}${J_TOK:+ J}"
printf "| %-20s %-31s |\n" "Max temperature" "${MAX_T:-n/a}${MAX_T:+ C}"
printf "| %-20s %-31s |\n" "Quick accuracy"  "$ACC"
echo "+------------------------------------------------------+"
