"""Three-device comparison table (Raspberry Pi 3, Raspberry Pi 5, Pixel 7), llama.cpp b3600 CPU,
4 threads, KV cache f16, flash attention off. Writes results/compare_devices.csv and prints Markdown.

    python3 scripts/compare_devices.py [pi3_benchmarks.csv]
Pi 3 rows come from the team's results/benchmarks.csv (RaspberryPI branch, first sweep only,
not the later throttled long-context runs).
"""
import csv, sys
from pathlib import Path

MODELS = {"smollm2-135m": "SmolLM2-135M-Instruct", "smollm2-360m": "SmolLM2-360M-Instruct",
          "qwen2.5-0.5b": "Qwen2.5-0.5B-Instruct"}
QUANTS = ["fp16", "q8_0", "q4_0", "q4_k_m"]
pi3_file = sys.argv[1] if len(sys.argv) > 1 else "results/benchmarks.csv"

pi3 = {}
for r in csv.DictReader(open(pi3_file)):
    if r["device"] != "Raspberry Pi 3" or "throttled" in r["notes"] or "ctx" in r["test"]:
        continue
    q = r["quant"].lower().replace("f16", "fp16")
    key = (r["model"], q, r["test"].split()[0])
    pi3.setdefault(key, float(r["tokens_per_sec"]))

def load(path, model_key):
    out = {}
    for r in csv.DictReader(open(path)):
        c = r.get("config")
        if c:  # energy_*.csv
            m, rest = c.split("-instruct-")
            q, kv, fa = rest.split("-kv")[0], rest.split("-kv")[1].split("-fa")[0], rest.split("-fa")[1][0]
        else:  # llamacpp_summary.csv
            m, q, kv, fa = r["model"], r["quant"], r["kv"], r["fa"]
        if kv == "f16" and fa == "0":
            out[(m, q, r["test"])] = (float(r["tok_s"]), r["J_per_tok"])
    return out

pixel = load("results/android/llamacpp_summary.csv", "model")
pi5 = load("results/pi5/energy_pi5.csv", "config")

rows = []
for m, name in MODELS.items():
    for q in QUANTS:
        g = lambda d, t, i=0: d.get((m, q, t), (None, None))[i]
        rows.append({"model": name, "quant": q,
                     "pp128_pi3": pi3.get((name, q, "pp128")), "pp128_pi5": g(pi5, "pp128"), "pp128_pixel7": g(pixel, "pp128"),
                     "tg128_pi3": pi3.get((name, q, "tg128")), "tg128_pi5": g(pi5, "tg128"), "tg128_pixel7": g(pixel, "tg128"),
                     "J_per_tok_tg128_pi5": g(pi5, "tg128", 1), "J_per_tok_tg128_pixel7": g(pixel, "tg128", 1)})
with open("results/compare_devices.csv", "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=list(rows[0])); w.writeheader(); w.writerows(rows)

fmt = lambda x, d=1: "n/a" if x in (None, "") else (f"{float(x):.{d}f}")
print("| Model | Weights | Prefill 128 tok/s (Pi 3 / Pi 5 / Pixel 7) | Decode 128 tok/s (Pi 3 / Pi 5 / Pixel 7) | Decode J/token (Pi 5 / Pixel 7) |")
print("|---|---|---|---|---|")
for r in rows:
    print(f"| {r['model'].replace('-Instruct','')} | {r['quant']} | {fmt(r['pp128_pi3'])} / {fmt(r['pp128_pi5'],0)} / {fmt(r['pp128_pixel7'],0)} | "
          f"{fmt(r['tg128_pi3'])} / {fmt(r['tg128_pi5'])} / {fmt(r['tg128_pixel7'])} | {fmt(r['J_per_tok_tg128_pi5'],3)} / {fmt(r['J_per_tok_tg128_pixel7'],3)} |")
