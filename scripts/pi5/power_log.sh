#!/usr/bin/env bash
# ~2 Hz power / thermal logger for the Raspberry Pi 5, run ON the Pi alongside a sweep.
# The Pi 5's PMIC reports current and voltage for each supply rail (vcgencmd pmic_read_adc);
# power = sum over rails of current x voltage. This covers the SoC, RAM and on-board rails but
# not USB peripherals or the power supply's own losses, so it is a little below wall power.
# Columns match the Pixel's adb power log, so scripts/android/energy.py works unchanged.
# Usage: bash scripts/pi5/power_log.sh out.csv     (stop with Ctrl-C / kill)
OUT="${1:-power.csv}"
mkdir -p "$(dirname "$OUT")"
echo "unix_ts,voltage_uV,current_uA,power_mW,status,temp_c,arm_mhz,throttled" > "$OUT"
while true; do
  ts=$(date +%s.%N | cut -c1-14)
  read -r p ext < <(vcgencmd pmic_read_adc | awk -F'[ =]+' '
    { name=$2; val=$NF; sub(/[AV]$/, "", val)
      if (name ~ /_A$/) a[substr(name, 1, length(name)-2)] = val
      else if (name ~ /_V$/) v[substr(name, 1, length(name)-2)] = val
      if (name == "EXT5V_V") ext = val }
    END { s = 0; for (k in a) if (k in v) s += a[k] * v[k]; printf "%.0f %.0f\n", s * 1000, ext * 1e6 }')
  i=""; [ -n "$ext" ] && [ "$ext" != 0 ] && i=$(awk -v p="$p" -v e="$ext" 'BEGIN{printf "%.0f", -p/1000/(e/1e6)*1e6}')
  t=$(vcgencmd measure_temp | grep -o '[0-9.]*')
  f=$(( $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq) / 1000 ))
  thr=$(vcgencmd get_throttled | cut -d= -f2)
  echo "$ts,$ext,$i,$p,Pi5,$t,$f,$thr" >> "$OUT"
  sleep 0.5
done
