"""Pixel 7: end-to-end run of the fixed 100-prompt set through llama-server (llama.cpp b3600).

For each model x quant x KV-cache type: start llama-server, do 1 warm-up pass over a few
prompts, then N measured passes over all prompts (greedy, no prompt cache). Records per
prompt: prefill ms, decode ms, tokens, tokens/s, peak RSS of the server, and whether the
expected answer appears in the output (a cheap accuracy proxy).

Standard library only, so it runs in Termux / Pi OS without extra installs.

    python3 scripts/android/03_run_prompts.py                                   # full
    python3 scripts/android/03_run_prompts.py --models smollm2-135m-instruct \
        --quants q4_0 --runs 1                                                   # pilot
"""
import argparse
import json
import os
import platform
import re
import shutil
import subprocess
import sys
import time
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def peak_rss_mb(pid):
    """Peak RSS (Linux/Android: VmHWM) or current RSS (macOS) of the server, in MB."""
    try:
        with open(f"/proc/{pid}/status") as f:
            for line in f:
                if line.startswith("VmHWM:"):
                    return int(line.split()[1]) / 1024
    except OSError:
        pass
    try:
        out = subprocess.check_output(["ps", "-o", "rss=", "-p", str(pid)], text=True)
        return int(out.strip()) / 1024
    except Exception:
        return None


def post(url, body, timeout=600):
    req = urllib.request.Request(url, data=json.dumps(body).encode(),
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read())


def wait_ready(url, proc, timeout=180):
    t0 = time.time()
    while time.time() - t0 < timeout:
        if proc.poll() is not None:
            raise RuntimeError("llama-server exited early, see server.log")
        try:
            with urllib.request.urlopen(url + "/health", timeout=2) as r:
                if r.status == 200:
                    return
        except Exception:
            time.sleep(0.5)
    raise TimeoutError("llama-server did not become ready")


def run_config(args, model, quant, kv, prompts, out_f, log_dir):
    gguf = Path(args.models_dir) / f"{model}-{quant}.gguf"
    if not gguf.exists():
        print(f"  missing {gguf}, skipping")
        return
    port = args.port
    cmd = [str(Path(args.llama) / "build/bin/llama-server"), "-m", str(gguf),
           "-t", str(args.threads), "-ngl", "0", "-c", str(args.ctx),
           "-np", "1", "-fa", "-ctk", kv, "-ctv", kv, "--port", str(port)]
    if args.cores and shutil.which("taskset"):
        cmd = ["taskset", "-c", args.cores] + cmd
    log = open(log_dir / f"server-{model}-{quant}-kv{kv}.log", "w")
    proc = subprocess.Popen(cmd, stdout=log, stderr=subprocess.STDOUT)
    url = f"http://127.0.0.1:{port}"
    try:
        wait_ready(url, proc)
        body = {"n_predict": args.n_predict, "temperature": 0, "top_k": 1,
                "cache_prompt": False, "stop": ["\n\n", "\nQ:"]}
        for p in prompts[:5]:                                   # warm-up, not recorded
            post(url + "/completion", {**body, "prompt": p["prompt"]})
        for run in range(args.runs):
            for p in prompts:
                t0 = time.perf_counter()
                r = post(url + "/completion", {**body, "prompt": p["prompt"]})
                wall = (time.perf_counter() - t0) * 1000
                tm = r.get("timings", {})
                text = r.get("content", "")
                row = {
                    "device": args.device, "model": model, "quant": quant, "kv": kv,
                    "run": run, "id": p["id"], "category": p["category"],
                    "prompt_tokens": tm.get("prompt_n"), "prefill_ms": tm.get("prompt_ms"),
                    "gen_tokens": tm.get("predicted_n"), "decode_ms": tm.get("predicted_ms"),
                    "prefill_tok_s": tm.get("prompt_per_second"),
                    "decode_tok_s": tm.get("predicted_per_second"),
                    "wall_ms": wall, "peak_rss_mb": peak_rss_mb(proc.pid),
                    "correct": bool(re.search(r"\b" + re.escape(p["answer"]) + r"\b", text, re.I)),
                    "output": text, "unix_ts": time.time(),
                }
                out_f.write(json.dumps(row) + "\n")
                out_f.flush()
            print(f"  run {run + 1}/{args.runs} done")
    finally:
        proc.terminate()
        proc.wait(timeout=30)
        log.close()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--device", default="Pixel 7")
    ap.add_argument("--threads", type=int, default=4)
    ap.add_argument("--cores", default="4-7", help="taskset CPU list (4-7 = big cores)")
    ap.add_argument("--models", default="smollm2-135m-instruct,smollm2-360m-instruct,qwen2.5-0.5b-instruct")
    ap.add_argument("--quants", default="fp16,q8_0,q4_0,q4_k_m")
    ap.add_argument("--kvs", default="f16", help="KV-cache types, e.g. f16,q8_0,q4_0")
    ap.add_argument("--runs", type=int, default=3)
    ap.add_argument("--n-predict", type=int, default=64)
    ap.add_argument("--ctx", type=int, default=4096)
    ap.add_argument("--port", type=int, default=8089)
    ap.add_argument("--llama", default=str(ROOT / "llama.cpp"))
    ap.add_argument("--models-dir", default=str(ROOT / "models"))
    ap.add_argument("--prompts", default=str(ROOT / "data/prompts.jsonl"))
    args = ap.parse_args()

    prompts = [json.loads(l) for l in open(args.prompts)]
    out_dir = ROOT / "results" / "android" / "prompts" / time.strftime("%Y%m%d-%H%M%S")
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "meta.json").write_text(json.dumps({**vars(args), "platform": platform.platform()}, indent=2))

    syslog = subprocess.Popen(["bash", str(ROOT / "scripts/android/syslog.sh"), str(out_dir / "syslog.csv")])
    try:
        with open(out_dir / "prompts_results.jsonl", "w") as out_f:
            for model in args.models.split(","):
                for quant in args.quants.split(","):
                    for kv in args.kvs.split(","):
                        print(f"== {model} {quant} kv={kv}")
                        run_config(args, model, quant, kv, prompts, out_f, out_dir)
                        time.sleep(int(os.environ.get("COOLDOWN", "20")))
    finally:
        syslog.terminate()
    print(f"done -> {out_dir}")


if __name__ == "__main__":
    sys.exit(main())
