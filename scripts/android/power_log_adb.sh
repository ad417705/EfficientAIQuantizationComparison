#!/usr/bin/env bash
# Run on the MAC while the phone is connected over *wireless* adb and UNPLUGGED.
# Termux can't read the Pixel's battery voltage/current, but `adb shell` can.
# Samples whole-phone power ~2x per second into a CSV (unix_ts in seconds, same clock as
# the phone's events.log, so energy per config can be matched later).
#
# One-time wireless setup (phone and Mac on the same Wi-Fi), with the cable still plugged in:
#   adb tcpip 5555 && adb connect "$(adb shell ip -f inet addr show wlan0 | awk '/inet /{print $2}' | cut -d/ -f1)":5555
#   then unplug the cable and check `adb devices` still lists the phone.
#
# Usage: bash scripts/android/power_log_adb.sh results/android/power/<name>.csv   (Ctrl-C to stop)
OUT="${1:-power.csv}"
mkdir -p "$(dirname "$OUT")"
echo "unix_ts,voltage_uV,current_uA,power_mW,status" > "$OUT"
adb shell 'P=/sys/class/power_supply/battery; while true; do
  echo "$(date +%s.%N | cut -c1-14),$(cat $P/voltage_now),$(cat $P/current_now),$(cat $P/status)"; sleep 0.5; done' |
while IFS=, read -r ts v i st; do
  p=$(awk -v v="$v" -v i="$i" 'BEGIN{x=v*i/1e9; if(x<0)x=-x; printf "%.0f", x}')
  echo "$ts,$v,$i,$p,$st" | tee -a "$OUT" | awk -F, 'NR%10==1{print "power " $4 " mW  (" $5 ")"}'
done
