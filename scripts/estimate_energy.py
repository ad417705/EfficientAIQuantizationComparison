#!/usr/bin/env python3
"""Estimate per-run energy from sweep log + monitor CSV.
Pi 3B power model: idle 1.4W, full-load 3.5W, linear with CPU util.
This is an estimate, not a direct measurement."""
import csv, re, sys
from datetime import datetime
from pathlib import Path

IDLE_W, MAX_W = 1.4, 3.5
HEADER_RE = re.compile(
    r'=== (.+?) - (\w{3} \d{2} \w{3} \d{4} \d{1,2}:\d{2}:\d{2} [AP]M) (\w+) ===')

def main(sweep_path, monitor_path, out_path):
    runs = []
    for line in Path(sweep_path).read_text().splitlines():
        m = HEADER_RE.match(line.strip())
        if m:
            dt = datetime.strptime(m.group(2), '%a %d %b %Y %I:%M:%S %p')
            runs.append((m.group(1), dt.timestamp()))
    samples = []
    with Path(monitor_path).open() as f:
        for row in csv.DictReader(f):
            try: samples.append((int(row['timestamp']), int(row['cpu_util_pct']), row['throttled_hex']))
            except: pass
    if not runs or not samples:
        sys.exit('no data')
    results = []
    for i, (label, start) in enumerate(runs):
        if any(x in label.lower() for x in ['started','finished']): continue
        end = runs[i+1][1] if i+1 < len(runs) else samples[-1][0]
        in_win = [(u,t) for ts,u,t in samples if start <= ts < end]
        if not in_win: continue
        avg_util = sum(u for u,_ in in_win) / len(in_win)
        duration = end - start
        avg_power = IDLE_W + (avg_util/100.0) * (MAX_W - IDLE_W)
        energy_j = avg_power * duration
        throttled = any(int(t,16) & 0xF for _,t in in_win)
        results.append({'label': label, 'duration_s': round(duration,1),
                        'avg_cpu_util_pct': round(avg_util,1),
                        'avg_power_w': round(avg_power,3),
                        'energy_j': round(energy_j,1),
                        'throttled_during_run': throttled})
    with Path(out_path).open('w', newline='') as f:
        w = csv.DictWriter(f, fieldnames=list(results[0].keys()))
        w.writeheader(); w.writerows(results)
    print(f'wrote {len(results)} rows to {out_path}')
    for r in results:
        print(f"  {r['label'][:55]:55s}  {r['duration_s']:>6.1f}s  "
              f"{r['avg_cpu_util_pct']:>5.1f}%  {r['avg_power_w']:>5.3f}W  "
              f"{r['energy_j']:>7.1f}J"
              f"{'  [THROTTLED]' if r['throttled_during_run'] else ''}")

if __name__ == '__main__':
    main(*sys.argv[1:])
