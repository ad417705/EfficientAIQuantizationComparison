"""Turn an LM-Meter (MLC LLM) capture into per-request prefill/decode numbers.

    python3 scripts/android/parse_mlc.py results/android/mlc/option2_<stamp> [--append]

Reads tvm_mlc.log (model, prompt length per request) and traces/trace_<req>.json
(Chrome-trace B/E events). Writes <capture>/requests.csv. With --append, also adds
mean/std rows per model to results/benchmarks.csv in the team format.
"""
import csv, json, re, statistics, sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def spans(events):
    """name -> list of durations (ms) from matched B/E pairs (and X events)."""
    open_, out = {}, defaultdict(list)
    for e in sorted(events, key=lambda e: e["ts"]):
        n = e["name"]
        if e["ph"] == "B":
            open_[n] = e["ts"]
        elif e["ph"] == "E" and n in open_:
            out[n].append((open_.pop(n), e["ts"]))
        elif e["ph"] == "X":
            out[n].append((e["ts"], e["ts"] + e.get("dur", 0)))
    return out


def parse(cap):
    cap = Path(cap)
    log = (cap / "tvm_mlc.log").read_text(errors="replace")
    # model per request: last "model": ... seen before the request id appears
    req_model, req_len, model = {}, {}, None
    for line in log.splitlines():
        m = re.search(r'"model": "[^"]*/([^"/]+)"', line)
        if m:
            model = m.group(1)
        m = re.search(r"req_id=(\S+).*total_input_len=(\d+)", line)
        if m:
            req_model.setdefault(m.group(1), model)
            req_len.setdefault(m.group(1), int(m.group(2)))
    rows = []
    first_seen = set()
    files = sorted((cap / "traces").glob("trace_*.json"))
    for f in sorted((cap / "traces").glob("trace_*.json")):
        req = f.stem.replace("trace_", "")
        # trace files are cumulative across requests: keep only this request's events
        sp = spans([e for e in json.load(open(f)) if e.get("tid") == req])
        pre = [b for n, v in sp.items() if n.startswith("prefill (") for b in v]
        dec = [b for n, v in sp.items() if n.startswith("decode (") for b in v]
        samp = [b for n, v in sp.items() if n.startswith("sample token (") for b in v]
        if not pre:
            continue
        p_start, p_end = min(s for s, _ in pre), max(e for _, e in pre)
        n_in = req_len.get(req)
        n_dec = len(dec)
        # decode wall time: end of prefill-step sampling -> end of last sampled token
        first_tok = min((e for s, e in samp if e >= p_end), default=p_end)
        last_tok = max((e for _, e in samp), default=p_end)
        dec_kernel_ms = sum(e - s for s, e in dec) / 1e3
        dec_wall_ms = (last_tok - first_tok) / 1e3
        order = min(s for s, _ in pre)
        rows.append({
            "_t": order,
            "request": req, "model": req_model.get(req), "prompt_tokens": n_in,
            # MLC launches GPU work asynchronously: the "prefill" span is only the launch.
            # The GPU finishes inside the first softmax (sync point), so time-to-first-token
            # is the honest prefill latency and is what prefill_tok_s uses.
            "prefill_launch_ms": round((p_end - p_start) / 1e3, 3),
            "ttft_ms": round((first_tok - p_start) / 1e3, 3),
            "prefill_tok_s": round(n_in / ((first_tok - p_start) / 1e6), 2) if n_in else None,
            "decode_tokens": n_dec,
            "decode_wall_ms": round(dec_wall_ms, 3),
            "decode_tok_s": round(n_dec / (dec_wall_ms / 1e3), 2) if dec_wall_ms else None,
            "decode_kernel_ms": round(dec_kernel_ms, 3),
        })
    rows.sort(key=lambda r: r.pop("_t"))
    # The app's prompts.json starts with 5 short warm-up prompts per model load (OpenCL kernels
    # compile on first use). Flag them and keep them out of the means. WARMUP=1 for old captures.
    import os
    n_warm = int(os.environ.get("WARMUP", "5"))
    seen = defaultdict(int)
    for r in rows:
        r["seq"] = seen[r["model"]]
        r["warmup"] = seen[r["model"]] < n_warm
        seen[r["model"]] += 1
    out = cap / "requests.csv"
    with open(out, "w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=list(rows[0]))
        w.writeheader(); w.writerows(rows)
    return rows, out


def append_shared(rows, cap):
    by = defaultdict(list)
    for r in rows:
        by[r["model"]].append(r)
    shared = ROOT / "results" / "benchmarks.csv"
    with open(shared, "a", newline="") as fh:
        w = csv.writer(fh)
        for model, rs in by.items():
            name, quant = re.match(r"(.+)-(q\w+?)-MLC", model).groups() if model and "-MLC" in model else (model, "?")
            for test, key in (("prefill (chat prompts)", "prefill_tok_s"), ("decode (chat)", "decode_tok_s")):
                v = [r[key] for r in rs if r[key] and not r["warmup"]]
                if not v:
                    continue
                std = statistics.stdev(v) if len(v) > 1 else 0
                w.writerow([name, quant, "", "", "Pixel 7", "Android (MLC LLM, OpenCL GPU)", "", "",
                            test, f"{statistics.mean(v):.2f}", f"{std:.2f}", "",
                            f"runtime=MLC n={len(v)} capture={Path(cap).name}"])


if __name__ == "__main__":
    rows, out = parse(sys.argv[1])
    print(f"{len(rows)} requests -> {out}")
    for r in rows:
        print(r)
    if "--append" in sys.argv:
        append_shared(rows, sys.argv[1]); print("appended to results/benchmarks.csv")
