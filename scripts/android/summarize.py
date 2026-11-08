"""Combine the per-run energy CSVs into results/android/llamacpp_summary.csv and print a
headline table (KV f16, flash attention off = closest to the Pi setup).

    python3 scripts/android/summarize.py
"""
import csv, glob, re
from pathlib import Path

A = Path("results/android")
files = ["energy_135m.csv", "energy_360m.csv", "energy_qwen_part1.csv", "energy_qwen_part2.csv"]
rows = []
for f in files:
    rows += list(csv.DictReader(open(A / f)))
# 360M FP16 KV-f16 FA-off: the first run had no energy (phone briefly charging), use the redo.
redo = [r for r in csv.DictReader(open(A / "energy_360m_fp16_redo.csv")) if "-fa0-" in r["config"]]
rows = [r for r in rows if not (r["config"] in {x["config"] for x in redo})] + redo

out = []
for r in rows:
    m = re.match(r"(.+)-instruct-(fp16|q8_0|q4_0|q4_k_m)-kv(\w+?)-fa(\d)-t(\d+)", r["config"])
    model, quant, kv, fa, t = m.groups()
    out.append({"model": model, "quant": quant, "kv": kv, "fa": fa, "threads": t, **{k: r[k] for k in
                ["test", "tok_s", "std", "power_mW", "power_src", "J_per_tok", "net_J_per_tok"]}})
order = {"smollm2-135m": 0, "smollm2-360m": 1, "qwen2.5-0.5b": 2}
qo = {"fp16": 0, "q8_0": 1, "q4_0": 2, "q4_k_m": 3}
out.sort(key=lambda r: (order[r["model"]], qo[r["quant"]], r["kv"], r["fa"]))
with open(A / "llamacpp_summary.csv", "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=list(out[0])); w.writeheader(); w.writerows(out)

idx = {(r["model"], r["quant"], r["kv"], r["fa"], r["test"]): r for r in out}
print("| Model | Weights | Prefill 256 tok/s | Prefill 2048 tok/s | Decode tok/s | Decode J/token | Prefill J/token |")
print("|---|---|---|---|---|---|---|")
for m in order:
    for q in qo:
        g = lambda t, k="tok_s": idx[(m, q, "f16", "0", t)][k]
        print(f"| {m} | {q} | {float(g('pp256')):.0f} | {float(g('pp2048')):.0f} | {float(g('tg128')):.1f} | {g('tg128','J_per_tok')} | {g('pp256','J_per_tok')} |")
