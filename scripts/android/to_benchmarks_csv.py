"""Append a sweep's llama-bench CSVs to results/benchmarks.csv in the team's shared format.

    python3 scripts/android/to_benchmarks_csv.py results/android/raw/<stamp>

KV-cache type, flash attention and pinned cores go in the `notes` column, so the shared
schema stays the same as the Pi 3 rows.
"""
import csv
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SHARED = ROOT / "results" / "benchmarks.csv"
FIELDS = ["model", "quant", "params", "size_mib", "device", "os", "threads", "n_batch",
          "test", "tokens_per_sec", "std", "date", "notes"]
NAMES = {
    "qwen2.5-0.5b-instruct": "Qwen2.5-0.5B-Instruct",
    "smollm2-135m-instruct": "SmolLM2-135M-Instruct",
    "smollm2-360m-instruct": "SmolLM2-360M-Instruct",
}


def parse_name(path):
    m = re.match(r"(.+)-(fp16|q8_0|q4_0|q4_k_m)\.gguf$", Path(path).name)
    if not m:
        return Path(path).stem, "?"
    return NAMES.get(m.group(1), m.group(1)), m.group(2).upper().replace("FP16", "F16")


def test_label(n_prompt, n_gen):
    p, g = int(n_prompt), int(n_gen)
    if p and g:
        return f"pp{p}+tg{g} prefill+decode"
    return f"pp{p} prefill" if p else f"tg{g} decode"


def main(run_dir):
    run_dir = Path(run_dir)
    meta = (run_dir / "meta.txt").read_text() if (run_dir / "meta.txt").exists() else ""
    android = re.search(r"android=(\S*)", meta)
    os_name = f"Android {android.group(1)} (Termux)" if android and android.group(1) else "Android (Termux)"
    osm = re.search(r"^os=(.*?)(?: kernel=|$)", meta, re.M)
    if osm:
        os_name = osm.group(1).strip()
    dev = re.search(r"device=(.+?)\s{2}", meta)
    device = dev.group(1) if dev else "Pixel 7"
    cores = re.search(r"cores=(\S*)", meta)

    rows = []
    for f in sorted(run_dir.glob("*.csv")):
        if f.name in ("syslog.csv", "power.csv"):
            continue
        for r in csv.DictReader(open(f)):
            if "model_filename" not in r:
                continue
            model, quant = parse_name(r["model_filename"])
            notes = f"kv={r['type_k']} fa={r['flash_attn']}"
            if cores and cores.group(1):
                notes += f" cores={cores.group(1)}"
            notes += f" run={run_dir.name}"
            rows.append({
                "model": model, "quant": quant,
                "params": f"{int(r['model_n_params']) / 1e6:.2f}M",
                "size_mib": f"{int(r['model_size']) / 2**20:.2f}",
                "device": device, "os": os_name,
                "threads": r["n_threads"], "n_batch": r["n_batch"],
                "test": test_label(r["n_prompt"], r["n_gen"]),
                "tokens_per_sec": f"{float(r['avg_ts']):.2f}",
                "std": f"{float(r['stddev_ts']):.2f}",
                "date": r["test_time"][:10], "notes": notes,
            })

    new = not SHARED.exists()
    with open(SHARED, "a", newline="") as out:
        w = csv.DictWriter(out, fieldnames=FIELDS)
        if new:
            w.writeheader()
        w.writerows(rows)
    print(f"appended {len(rows)} rows to {SHARED.relative_to(ROOT)}")


if __name__ == "__main__":
    main(sys.argv[1])
