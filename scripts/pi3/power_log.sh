#!/usr/bin/env bash
# Pi 3B power/thermal logger. No PMIC like Pi 5, so power is ESTIMATED from CPU
# utilization against published idle/full-load figures (1.4W / 3.5W). Columns match
# Joel's Pi 5 power_log.sh so scripts/android/energy.py works unchanged.
OUT="${1:-power.csv}"
mkdir -p "$(dirname "$OUT")"
echo "unix_ts,voltage_uV,current_uA,power_mW,status,temp_c,arm_mhz,throttled" > "$OUT"
prev_total=0; prev_idle=0
while true; do
  ts=$(date +%s.%N | cut -c1-14)
  read -r cpu user nice system idle iowait irq softirq steal rest < /proc/stat
  total=$((user + nice + system + idle + iowait + irq + softirq + steal))
  dt=$((total - prev_total)); di=$((idle - prev_idle))
  if [ $prev_total -gt 0 ] && [ $dt -gt 0 ]; then
    util=$(( 100 * (dt - di) / dt ))
  else util=0; fi
  prev_total=$total; prev_idle=$idle
  # Pi 3B: idle ~1.4W, full load ~3.5W. power_mW = 1400 + util% * 21
  pmw=$(( 1400 + util * 21 ))
  cua=$(( pmw * 1000 / 5 ))   # 5V rail -> current in µA
  t=$(vcgencmd measure_temp | grep -o '[0-9.]*')
  f=$(( $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq) / 1000 ))
  thr=$(vcgencmd get_throttled | cut -d= -f2)
  echo "$ts,5000000,$cua,$pmw,Pi3,$t,$f,$thr" >> "$OUT"
  sleep 0.5
done
