#!/usr/bin/env bash
# ~1 Hz thermal / clock / throttle / CPU-load logger for the Raspberry Pi 3, run ON the Pi.
# The Pi 3 cannot measure its own power. power_mW is an ESTIMATE from CPU load, using the same
# linear model as the earlier Pi 3 runs (scripts/pi3/legacy-32bit/estimate_energy.py):
#   power = IDLE_MW + (MAX_MW - IDLE_MW) x CPU utilisation     (defaults 1400 and 3500 mW, Pi 3B)
# status is "Estimated" so it is never mistaken for a measured value. Columns match the Pi 5 and
# Pixel logs, so scripts/android/energy.py and summarize_prompts.py work unchanged.
# Usage: bash scripts/pi3/temp_log.sh out.csv     (stop with Ctrl-C / kill)
OUT="${1:-power.csv}"
IDLE_MW="${IDLE_MW:-1400}"; MAX_MW="${MAX_MW:-3500}"
mkdir -p "$(dirname "$OUT")"
echo "unix_ts,voltage_uV,current_uA,power_mW,status,temp_c,arm_mhz,throttled,cpu_util_pct,mem_avail_mb" > "$OUT"
read -r _ u n s i w q sq st _ < /proc/stat; pt=$((u+n+s+i+w+q+sq+st)); pi=$((i+w))
while true; do
  sleep 1
  read -r _ u n s i w q sq st _ < /proc/stat; t=$((u+n+s+i+w+q+sq+st)); id=$((i+w))
  dt=$((t-pt)); util=0; [ "$dt" -gt 0 ] && util=$(( 100 * (dt - (id-pi)) / dt )); pt=$t; pi=$id
  p=$(( IDLE_MW + (MAX_MW - IDLE_MW) * util / 100 ))
  ts=$(date +%s.%N | cut -c1-14)
  temp=$(vcgencmd measure_temp 2>/dev/null | grep -o '[0-9.]*' || awk '{print $1/1000}' /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
  f=$(awk '{print int($1/1000)}' /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null)
  thr=$(vcgencmd get_throttled 2>/dev/null | cut -d= -f2)
  mem=$(awk '/MemAvailable/ {print int($2/1024)}' /proc/meminfo)
  echo "$ts,5000000,$((p * 200)),$p,Estimated,$temp,$f,$thr,$util,$mem" >> "$OUT"
done
