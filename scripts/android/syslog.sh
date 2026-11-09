#!/usr/bin/env bash
# 1 Hz logger for the Pixel 7: battery power (for energy per token), temperatures, CPU clocks.
# Unplug the phone while measuring: on battery, power = voltage_now * current_now is the
# whole-phone draw, so energy/token = (mean power during run - idle power) * time / tokens.
# Plugged in, the charger supplies the power and these numbers are meaningless.
# Usage: bash scripts/android/syslog.sh out.csv    (stop with kill / Ctrl-C)
OUT="${1:-syslog.csv}"
PS=/sys/class/power_supply/battery
rd() { cat "$1" 2>/dev/null || echo ""; }

echo "unix_ts,batt_uV,batt_uA,power_mW,batt_temp_c,max_zone_temp_c,cpu0_mhz,cpu4_mhz,cpu6_mhz" > "$OUT"
while true; do
  ts=$(date +%s.%N | cut -c1-14)
  v=$(rd $PS/voltage_now); i=$(rd $PS/current_now); bt=$(rd $PS/temp)
  # Fall back to termux-api when sysfs is locked down (slower, ~1 s per call).
  if [ -z "$i" ] && command -v termux-battery-status >/dev/null; then
    js=$(termux-battery-status)
    i=$(echo "$js" | grep -o '"current": *-\?[0-9]*' | grep -o -- '-\?[0-9]*$')
    bt=$(echo "$js" | grep -o '"temperature": *[0-9.]*' | grep -o '[0-9.]*$'); bt_is_c=1
  fi
  p=""; [ -n "$v" ] && [ -n "$i" ] && p=$(awk -v v="$v" -v i="$i" 'BEGIN{x=v*i/1e9; if(x<0)x=-x; printf "%.0f", x}')
  [ -n "$bt" ] && [ -z "${bt_is_c:-}" ] && bt=$(awk -v t="$bt" 'BEGIN{print t/10}')
  zmax=$(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -n | tail -1)
  [ -n "$zmax" ] && zmax=$(awk -v t="$zmax" 'BEGIN{print t/1000}')
  f() { x=$(rd /sys/devices/system/cpu/cpu$1/cpufreq/scaling_cur_freq); [ -n "$x" ] && echo $((x/1000)); }
  echo "$ts,$v,$i,$p,$bt,$zmax,$(f 0),$(f 4),$(f 6)" >> "$OUT"
  sleep 1
done
