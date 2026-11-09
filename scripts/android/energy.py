"""Speed + energy summary for one llama-bench sweep folder (results/android/raw/<stamp>).

Power source: Termux syslog.csv has battery current at 1 Hz but no voltage; the Mac-side
adb logs (results/android/power/*.csv) have voltage. Power = |current| x voltage, with
voltage interpolated from the adb logs (it changes slowly), so gaps in the adb log are filled.
Where the adb log covers a test its power is used directly (power_src=adb); the Termux
current reading lags and sometimes flips sign, so syslog-based rows are rougher.

Each llama-bench row = 1 warm-up + REPS runs; its window is [its test_time, next row's test_time).
J/token = mean whole-phone power in that window x avg seconds per run / tokens per run.
'net' subtracts the idle baseline (median power in the 25 s cooldowns between configs).

    python3 scripts/android/energy.py results/android/raw/20261107-131645 results/android/power/smollm2-360m*.csv
    python3 scripts/android/energy.py results/pi5/raw/<stamp> results/pi5/raw/<stamp>/power.csv   # Pi 5
"""
import csv, sys, glob, bisect, statistics as st
from datetime import datetime, timezone
from pathlib import Path

raw = Path(sys.argv[1]); power_files = sys.argv[2:]

# adb voltage / power samples
adb = []
for f in power_files:
    for r in csv.DictReader(open(f)):
        try: adb.append((float(r["unix_ts"]), int(r["voltage_uV"]) / 1e6, float(r["power_mW"]) if r["status"] not in ("Charging", "Full", "Not charging") else None, r["status"]))
        except (ValueError, KeyError): pass
adb.sort(); at = [a[0] for a in adb]

def volt(t):
    i = bisect.bisect_left(at, t)
    if i == 0: return adb[0][1]
    if i >= len(adb): return adb[-1][1]
    (t0, v0, *_), (t1, v1, *_) = adb[i - 1], adb[i]
    return v0 + (v1 - v0) * (t - t0) / (t1 - t0)

# syslog current -> power
sl = []
for r in (csv.DictReader(open(raw / "syslog.csv")) if (raw / "syslog.csv").exists() else []):
    try:
        t, ua = float(r["unix_ts"]), int(r["batt_uA"])
    except (ValueError, KeyError): continue
    sl.append((t, abs(ua) / 1e6 * volt(t) * 1000 if ua < 0 else None))  # mW; charging -> None
st_t = [s[0] for s in sl]

def mean_in(series, ts, a, b, idx=1):
    i, j = bisect.bisect_left(ts, a), bisect.bisect_left(ts, b)
    v = [x[idx] for x in series[i:j] if x[idx] is not None]
    return (sum(v) / len(v), len(v)) if v else (None, 0)

# config windows from events.log
ev = [l.split() for l in open(raw / "events.log")]
starts = {n: int(t) for t, k, n in ev if k == "start"}
ends = {n: int(t) for t, k, n in ev if k == "end"}
idle = []
names = sorted(starts, key=starts.get)
for a, b in zip(names, names[1:]):
    if a in ends:
        m, n = mean_in(adb, at, ends[a] + 3, starts[b] - 1, idx=2)
        if n < 10: m, n = mean_in(sl, st_t, ends[a] + 3, starts[b] - 1)
        if m: idle.append(m)
base = st.median(idle) if idle else 0

w = csv.writer(sys.stdout)
w.writerow(["config", "test", "tok_s", "std", "power_mW", "power_src", "J_per_tok", "net_J_per_tok"])
for name in names:
    rows = list(csv.DictReader(open(raw / f"{name}.csv")))
    tts = [datetime.strptime(r["test_time"], "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=timezone.utc).timestamp() for r in rows]
    for k, r in enumerate(rows):
        a = tts[k]; b = tts[k + 1] if k + 1 < len(rows) else ends.get(name, a + 60)
        p, n = mean_in(sl, st_t, a, b)
        pa, na = mean_in(adb, at, a, b, idx=2)
        npmt, ngen = int(r["n_prompt"]), int(r["n_gen"])
        test = f"pp{npmt}" if ngen == 0 else (f"tg{ngen}" if npmt == 0 else f"pp{npmt}+tg{ngen}")
        toks = npmt + ngen
        sec = int(r["avg_ns"]) / 1e9
        src = "adb" if pa and na >= 3 else ("syslog" if p else "")
        pw = pa if src == "adb" else p   # adb is the reliable source; syslog current lags/flips sign
        jt = pw / 1000 * sec / toks if pw else None
        jn = (pw - base) / 1000 * sec / toks if pw else None
        w.writerow([name, test, f"{float(r['avg_ts']):.1f}", f"{float(r['stddev_ts']):.1f}",
                    f"{pw:.0f}" if pw else "", src,
                    f"{jt:.4f}" if jt else "", f"{jn:.4f}" if jn else ""])
print(f"# idle baseline {base:.0f} mW from {len(idle)} cooldowns", file=sys.stderr)
