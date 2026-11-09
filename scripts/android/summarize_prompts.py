"""Summarize a 100-prompt llama-server run (results/android/prompts/<stamp>) with the Mac-side
adb power log. One row per model x weight type: accuracy (exact-answer match, averaged over
passes and per category), time to first token, decode speed (total tokens / total decode time),
end-to-end latency, peak server memory, and whole-phone energy per prompt and per generated token.

    python3 scripts/android/summarize_prompts.py results/android/prompts/20261108-102450 \
        results/android/power/prompts.csv > results/android/prompts_summary.csv
"""
import csv, json, sys, bisect, statistics as st
from collections import defaultdict

rows = [json.loads(l) for l in open(sys.argv[1] + "/prompts_results.jsonl")]
pw = []
for r in csv.DictReader(open(sys.argv[2])):
    if r["status"] not in ("Charging", "Full", "Not charging"):
        pw.append((float(r["unix_ts"]), float(r["power_mW"])))
pw.sort(); pt = [p[0] for p in pw]

g = defaultdict(list)
for r in rows:
    g[(r["model"].replace("-instruct", ""), r["quant"])].append(r)

out = csv.writer(sys.stdout)
out.writerow(["model", "quant", "prompts", "acc_all", "acc_qa", "acc_reasoning", "acc_fewshot",
              "ttft_ms_mean", "decode_tok_s", "gen_tokens_mean", "e2e_ms_mean", "e2e_ms_p95",
              "peak_rss_mb", "power_mW", "J_per_prompt", "J_per_gen_token"])
for (m, q), rs in g.items():
    acc = lambda c=None: 100 * st.mean(r["correct"] for r in rs if c is None or r["category"] == c)
    gen = sum(r["gen_tokens"] or 0 for r in rs); dec = sum(r["decode_ms"] or 0 for r in rs) / 1000
    walls = sorted(r["wall_ms"] for r in rs)
    a = rs[0]["unix_ts"] - rs[0]["wall_ms"] / 1000; b = rs[-1]["unix_ts"]
    i, j = bisect.bisect_left(pt, a), bisect.bisect_left(pt, b)
    p = st.mean(x[1] for x in pw[i:j]) if j > i else None
    e = p / 1000 * (b - a) if p else None
    out.writerow([m, q, len(rs), f"{acc():.1f}", f"{acc('qa'):.1f}", f"{acc('reasoning'):.1f}", f"{acc('fewshot'):.1f}",
                  f"{st.mean(r['prefill_ms'] for r in rs):.0f}", f"{gen / dec:.1f}", f"{gen / len(rs):.1f}",
                  f"{st.mean(walls):.0f}", f"{walls[int(0.95 * len(walls))]:.0f}",
                  f"{max(r['peak_rss_mb'] or 0 for r in rs):.0f}",
                  f"{p:.0f}" if p else "", f"{e / len(rs):.2f}" if e else "", f"{e / gen:.3f}" if e else ""])
