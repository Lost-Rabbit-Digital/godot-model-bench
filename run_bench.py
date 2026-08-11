#!/usr/bin/env python3
"""Godot Model Bench — OpenRouter budget-model benchmark harness.

Runs a fixed Godot 4.7 GDScript challenge (challenge/PROMPT.md) against a list of
OpenRouter models, evaluates each submission with a headless Godot test runner
(tests/runner.gd), gives failing models ONE repair round fed with the failure log,
then scores everything and writes results/report.md.

Usage:
  python3 run_bench.py                     # full run, all models
  python3 run_bench.py --only deepseek/deepseek-v4-flash-0731
  python3 run_bench.py --skip google/gemini-3.6-flash
  python3 run_bench.py --no-repair         # single attempt only
"""

import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed

BASE = os.path.dirname(os.path.abspath(__file__))
RESULTS = os.path.join(BASE, "results")
ENV_PATH = os.path.expanduser("~/.hermes/.env")
STOCK_GODOT = os.path.expanduser("~/Godot/godot-4.7.1-stock")
SYMLINK_GODOT = "/home/dmcha/.local/bin/godot"
GODOT = STOCK_GODOT if os.path.exists(STOCK_GODOT) else SYMLINK_GODOT
GDLINT_BIN = os.path.expanduser("~/venvs/gdlint/bin/gdlint")
API_URL = "https://openrouter.ai/api/v1/chat/completions"

# Per-round config (set in main(); defaults are round 1)
ROUND = 1
RUNNER_SCRIPT = "res://tests/runner.gd"
SUBMISSIONS = os.path.join(BASE, "submissions_round1")
SUBMIT_LIVE = "submission"
SUBMIT_FILES = ("beehive.gd", "honey_math.gd")
PROMPT_PATH = os.path.join(BASE, "challenge", "PROMPT.md")
REPORT_FILE = "report.md"
MAX_TOKENS = 16384
FREE_MODE = False

# Per-round configuration: prompt, runner, submission dir, live dir, file names, max_tokens.
# Each round maps (round_num) -> (prompt, runner_path, submissions_dir, submit_live, submit_files, max_tokens).
ROUNDS = {
    1: ("PROMPT.md", "res://tests/runner.gd", os.path.join(BASE, "submissions_round1"), "submission", ("beehive.gd", "honey_math.gd"), 16384),
    2: ("PROMPT2.md", "res://tests/runner2.gd", os.path.join(BASE, "submissions_round2"), "submission2", ("greenhouse.gd", "thermostat.gd"), 32768),
    3: ("PROMPT3.md", "res://tests/runner3.gd", os.path.join(BASE, "submissions_round3"), "submission3", ("pegboard.gd", "bouncy_ball.gd"), 32768),
    4: ("PROMPT4.md", "res://tests/runner4.gd", os.path.join(BASE, "submissions_round4"), "submission4", ("juice_hud.gd", "hud_sparkle.gd"), 65536),
    5: ("PROMPT5.md", "res://tests/runner5.gd", os.path.join(BASE, "submissions_round5"), "submission5", ("npc_controller.gd",), 65536),
    6: ("PROMPT6.md", "res://tests/runner6.gd", os.path.join(BASE, "submissions_round6"), "submission6", ("char_animator.gd",), 65536),
    7: ("PROMPT7.md", "res://tests/runner7.gd", os.path.join(BASE, "submissions_round7"), "submission7", ("spell_vfx.gd",), 65536),
}

MODELS = [
    ("inclusionai/ling-3.0-flash", "Ling 3.0 Flash"),
    ("meta/muse-spark-1.2", "Muse Spark 1.2"),
    ("qwen/qwen3.8-max", "Qwen3.8 Max"),
    ("deepseek/deepseek-v4-flash-0731", "DeepSeek V4 Flash"),
    ("thinkingmachines/inkling-small", "Inkling Small"),
    ("qwen/qwen3.7-flash", "Qwen3.7 Flash"),
    ("poolside/laguna-s-2.1", "Laguna S 2.1"),
    ("google/gemini-3.6-flash", "Gemini 3.6 Flash"),
    ("google/gemini-3.5-flash-lite", "Gemini 3.5 Flash Lite"),
    ("meituan/longcat-2.0", "LongCat 2.0"),
    ("kwaipilot/kat-coder-air-v2.5", "Kat Coder Air v2.5"),
    ("aion-labs/aion-3.0-mini", "Aion 3.0 Mini"),
    ("nex-agi/nex-n2-pro", "Nex N2 Pro"),
    ("z-ai/glm-5.2", "GLM 5.2"),
    ("minimax/minimax-m3", "MiniMax M3"),
]

# Round 2 field: GLM 5.2 and LongCat 2.0 cut per user request.
ROUND2_MODELS = [(mid, label) for mid, label in MODELS
                 if mid not in ("z-ai/glm-5.2", "meituan/longcat-2.0")]

# Active roster (round 3+). Four models dropped 2026-08 per user decisions:
#   qwen/qwen3.8-max    531s wall, $0.146, ~24k output tokens for ~90 lines (0.0 time pts)
#   nex-agi/nex-n2-pro  311s wall; burned the ENTIRE 32k output budget on reasoning
#                       with zero content on first attempt (both rounds)
#   minimax/minimax-m3  insufficient: needed repair (extended Node, not Node2D)
#   thinkingmachines/inkling-small  insufficient: 162s wall, 9.4k tokens for ~90 lines
# Added 2026-08 per user request: tencent/hy3 (Tencent Hy3), xiaomi/mimo-v2.5-pro
# (Xiaomi MiMo V2.5 Pro). Verified against the OR catalog before the run.
ACTIVE_MODELS = [(mid, label) for mid, label in ROUND2_MODELS
                 if mid not in ("qwen/qwen3.8-max", "nex-agi/nex-n2-pro",
                                "minimax/minimax-m3", "thinkingmachines/inkling-small")]
ACTIVE_MODELS += [
    ("tencent/hy3", "Tencent Hy3"),
    ("xiaomi/mimo-v2.5-pro", "Xiaomi MiMo V2.5 Pro"),
    ("openai/gpt-5.6-luna", "GPT-5.6 Luna"),
    ("thinkingmachines/inkling", "Inkling"),
    ("x-ai/grok-4.5", "Grok 4.5"),
    ("aion-labs/aion-3.0-mini", "Aion 3.0 Mini"),
    ("z-ai/glm-5.2", "GLM 5.2"),
    ("moonshotai/kimi-k2.7-code", "Kimik2.7 Code"),
    ("stepfun/step-3.7-flash", "Step 3.7 Flash"),
    ("x-ai/grok-build-0.1", "Grok Build 0.1"),
    ("inclusionai/ring-2.6-1t", "Ring 2.6 1T"),
    ("ibm-granite/granite-4.1-8b", "Granite 4.1 8B"),
    ("mistralai/mistral-medium-3-5", "Mistral Medium 3.5"),
    ("xiaomi/mimo-v2.5", "Xiaomi MiMo V2.5"),
    ("arcee-ai/trinity-large-thinking", "Trinity Large Thinking"),
    ("meta/muse-glimmer-30b", "Muse Glimmer 30B"),
    ("upstage/solar-pro4", "Solar Pro 4"),
]

# Free tier (OpenRouter :free variants, $0). Trimmed 2026-08 to the two lagunas
# only — ling-3.0-tiny and north-mini-code burned the whole output budget on
# reasoning with zero content (all rounds), nemotron nano omni over-reasoned on
# round 1, and gemma-4-31b-it:free never responded (upstream 429 on every request).
FREE_MODELS = [
    ("poolside/laguna-s-2.1:free", "Laguna S 2.1 (free)"),
    ("poolside/laguna-xs-2.1:free", "Laguna XS 2.1 (free)"),
]

SYSTEM_MSG = ("You are an expert Godot 4.7 GDScript programmer. "
              "Follow the user's specification exactly.")

FENCE_RE = re.compile(r"```[a-zA-Z0-9_]*\s*\n(.*?)```", re.S)


def load_key() -> str:
    with open(ENV_PATH) as f:
        for line in f:
            line = line.strip()
            if line.startswith("OPENROUTER_API_KEY="):
                v = line.split("=", 1)[1].strip().strip('"').strip("'")
                if v:
                    return v
    raise SystemExit("OPENROUTER_API_KEY not found in %s" % ENV_PATH)


def load_pricing() -> dict:
    """model_id -> (prompt_per_1m, completion_per_1m) from the OR catalog."""
    try:
        with open("/tmp/or_models.json") as f:
            data = json.load(f)
        out = {}
        for m in data.get("data", []):
            p = m.get("pricing", {})
            try:
                pp = float(p.get("prompt", 0) or 0) * 1_000_000
                cp = float(p.get("completion", 0) or 0) * 1_000_000
            except (TypeError, ValueError):
                pp = cp = 0.0
            out[m["id"]] = (pp, cp)
        return out
    except Exception:
        return {}


def slug(model_id: str) -> str:
    return model_id.replace("/", "_").replace(":", "_")


def extract_files(text: str):
    """Return (list_of_sources, used_fallback, first_block_class_hint).

    Each round expects a specific number of files (len(SUBMIT_FILES)).
    The model should output one fenced code block per file, in order.
    If fewer blocks are found, we try to split a single raw block by
    class_name/extends markers as a fallback (rounds 1/2 only).
    """
    blocks = [b.strip() for b in FENCE_RE.findall(text) if b.strip()]
    n_expected = len(SUBMIT_FILES)
    if len(blocks) >= n_expected:
        return blocks[:n_expected], False
    # Fallback: try to split a single block
    if len(blocks) >= 1:
        raw = blocks[0]
        # Split by script headers when a model returned several files in one block.
        # A single response may contain several scripts in one fenced block.
        # Prefer class_name headers when there are enough of them; otherwise use
        # extends headers. Treating every class_name and extends line as a split
        # point can produce files containing only a class declaration.
        class_starts = [m.start() for m in re.finditer(r"(?m)^class_name\s+", raw)]
        extends_starts = [m.start() for m in re.finditer(r"(?m)^extends\s+", raw)]
        starts = class_starts if len(class_starts) >= n_expected else extends_starts
        if len(starts) >= n_expected:
            starts.sort()
            files = []
            for i in range(n_expected):
                start = starts[i]
                end = starts[i + 1] if i + 1 < len(starts) else len(raw)
                files.append(raw[start:end].strip())
            return files, True
    # Last resort: if only 1 expected, use whatever we got
    if n_expected == 1 and blocks:
        return [blocks[0]], True
    return [""] * n_expected, True


def chat(api_key: str, model: str, messages, max_tokens: int = None):
    if max_tokens is None:
        mt = MAX_TOKENS
    else:
        mt = max_tokens
    payload = {
        "model": model,
        "messages": messages,
        "temperature": 0.2,
        "max_tokens": mt,
        "top_p": 0.9,
    }
    req = urllib.request.Request(
        API_URL,
        data=json.dumps(payload).encode(),
        headers={"Authorization": "Bearer " + api_key,
                 "Content-Type": "application/json"},
    )
    last_err = None
    for attempt in range(5):
        try:
            t0 = time.time()
            with urllib.request.urlopen(req, timeout=420) as resp:
                body = json.loads(resp.read().decode())
            dur = time.time() - t0
            return body, dur
        except urllib.error.HTTPError as e:
            last_err = "HTTP %s: %s" % (e.code, e.read()[:300].decode(errors="replace"))
            if e.code in (429, 500, 502, 503, 529):
                time.sleep(15 * (attempt + 1))  # free tier upstream pools need long backoff
                continue
            return {"error": last_err}, 0.0
        except Exception as e:
            last_err = "%s: %s" % (type(e).__name__, e)
            time.sleep(15 * (attempt + 1))
    return {"error": last_err}, 0.0


def response_text(body: dict) -> tuple:
    """Return (content, finish_reason, usage_dict, reasoning_only)."""
    if "error" in body:
        return "", "error", {}, False
    try:
        ch = body["choices"][0]
        msg = ch.get("message", {}) or {}
        content = msg.get("content", "") or ""
        return content, ch.get("finish_reason", ""), body.get("usage", {}), (content == "")
    except Exception:
        return "", "error", {}, False


def run_eval(record_mp4: str = None) -> dict:
    avi_path = os.path.join(RESULTS, record_mp4.replace(".mp4", ".avi")) if record_mp4 else None
    if record_mp4:
        # Run under Xvfb with real rendering for video capture (no --headless)
        cmd = ["xvfb-run", "-a", GODOT, "--path", BASE, "-s", RUNNER_SCRIPT,
               "--rendering-driver", "opengl3",
               "--write-movie", avi_path, "--no-header"]
    else:
        cmd = [GODOT, "--headless", "--path", BASE, "-s", RUNNER_SCRIPT]
    t0 = time.time()
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=180)
    except subprocess.TimeoutExpired:
        return {"passed": 0, "total": 0, "exit": -1, "stderr": "TIMEOUT",
                "lines": [], "stdout": "", "dur": 180.0, "failure_details": []}
    dur = time.time() - t0
    out = p.stdout or ""
    err = p.stderr or ""
    m = re.search(r"BENCH_RESULT:\s*(\d+)/(\d+)", out)
    if m:
        passed, total = int(m.group(1)), int(m.group(2))
    else:
        passed, total = 0, 0
    lines = [l for l in out.splitlines() if l.startswith(("PASS ", "FAIL "))]
    # Also capture failure categories and non-determinism markers
    fail_lines = [l for l in out.splitlines() if l.startswith(("FAIL_CAT ", "FLAKY ", "FAIL_CAT_SUMMARY"))]
    result = {"passed": passed, "total": total, "exit": p.returncode,
            "stdout": out, "stderr": err, "lines": lines, "dur": dur,
            "failure_details": fail_lines}
    # Convert AVI to MP4 if recording was requested
    if record_mp4:
        avi_path = os.path.join(RESULTS, record_mp4.replace(".mp4", ".avi"))
        mp4_path = os.path.join(RESULTS, "recordings", record_mp4)
        if os.path.exists(avi_path) and os.path.getsize(avi_path) > 0:
            os.makedirs(os.path.dirname(mp4_path), exist_ok=True)
            subprocess.run(["ffmpeg", "-y", "-i", avi_path,
                            "-c:v", "libx264", "-crf", "20",
                            "-pix_fmt", "yuv420p", mp4_path],
                           capture_output=True, timeout=120)
            os.unlink(avi_path)
            result["mp4"] = mp4_path if os.path.exists(mp4_path) else None
        else:
            result["mp4"] = None
        return result
    return {"passed": passed, "total": total, "exit": p.returncode,
            "stdout": out, "stderr": err, "lines": lines, "dur": dur,
            "failure_details": fail_lines}


def _strip_class_name(src: str) -> str:
    """Remove class_name declarations to avoid global-class cache conflicts.
    Multiple submissions in the same project dir with the same class_name
    cause 'Class X hides a global script class' parse errors. The harness
    loads scripts by path (load()), so class_name is never needed at runtime."""
    lines = []
    for line in src.splitlines():
        stripped = line.lstrip()
        if stripped.startswith("class_name "):
            lines.append("# " + line)  # comment it out
        else:
            lines.append(line)
    return "\n".join(lines)


def write_submission(sources: list) -> None:
    sub_dir = os.path.join(BASE, SUBMIT_LIVE)
    os.makedirs(sub_dir, exist_ok=True)
    expected = set(SUBMIT_FILES)
    for name in os.listdir(sub_dir):
        if name.endswith(".gd") and name not in expected:
            os.unlink(os.path.join(sub_dir, name))
    for i, src in enumerate(sources):
        src = _strip_class_name(src)
        fname = SUBMIT_FILES[i] if i < len(SUBMIT_FILES) else "file%d.gd" % i
        with open(os.path.join(sub_dir, fname), "w") as f:
            f.write(src)


def _lint_to_pts(issues: int) -> int:
    if issues <= 0:
        return 10
    if issues <= 2:
        return 9
    if issues <= 5:
        return 7
    if issues <= 10:
        return 5
    if issues <= 20:
        return 3
    return 0


def gdlint_score(model_dir: str, attempt_num: int):
    """Run gdlint (gdtoolkit) on the counted attempt's code. Returns (points, issue_count)."""
    if not os.path.exists(GDLINT_BIN):
        return 0, -1
    resp = os.path.join(model_dir, "attempt%d_response.txt" % attempt_num)
    if not os.path.exists(resp):
        return 0, -1
    content = open(resp).read()
    if not content.strip():
        return 0, -1
    sources, fallback = extract_files(content)
    if not any(s.strip() for s in sources):
        return 0, -1
    tmpdir = tempfile.mkdtemp(prefix="gdlint_bench_")
    try:
        paths = []
        for i, src in enumerate(sources):
            p = os.path.join(tmpdir, "submission_%d.gd" % i)
            with open(p, "w") as f:
                f.write(src)
            paths.append(p)
        p = subprocess.run([GDLINT_BIN] + paths, capture_output=True, text=True,
                           timeout=30, cwd=BASE)
        out = (p.stdout or "") + "\n" + (p.stderr or "")
    finally:
        shutil.rmtree(tmpdir, ignore_errors=True)
    # gdlint's summary line is authoritative ("Failure: N problems found"); it also
    # covers parse failures, which are NOT emitted as "Error:" lines.
    m = re.search(r"Failure:\s*(\d+)\s*problems? found", out)
    issues = int(m.group(1)) if m else 0
    return _lint_to_pts(issues), issues


def style_score(beehive_src: str) -> int:
    s = 0
    typed = len(re.findall(r"->\s*(?:int|float|String|bool|Dictionary|Array|Variant|void)\b", beehive_src))
    if typed >= 6:
        s += 5
    ann = len(re.findall(r":\s*(?:int|float|String|bool|Dictionary|Array|Variant)\b", beehive_src))
    if ann >= 10:
        s += 3
    if len(re.findall(r"^\s*#", beehive_src, re.M)) >= 3:
        s += 2
    return s


def fetch_attempt(api_key: str, model_id: str, prompt: str, attempt: int, failure_log: str = ""):
    if attempt == 1:
        messages = [
            {"role": "system", "content": SYSTEM_MSG},
            {"role": "user", "content": prompt},
        ]
    else:
        messages = [
            {"role": "system", "content": SYSTEM_MSG},
            {"role": "user", "content": prompt},
            {"role": "user", "content": (
                "Your previous submission FAILED validation. Here is the Godot 4.7 "
                "headless test runner log (PASS/FAIL per check, plus any script errors):\n\n"
                + failure_log[-6000:] +
                "\n\nFix ALL failing checks. Re-read the original specification. "
                "Output the complete corrected source code in the same strict format: "
                "one gdscript fenced code block per file, in order, no prose.")},
        ]
    body, dur = chat(api_key, model_id, messages)
    content, finish, usage, reasoning_only = response_text(body)
    files, fallback = extract_files(content)
    return {
        "content": content, "finish": finish, "usage": usage, "duration": dur,
        "files": files, "fallback": fallback,
        "reasoning_only": reasoning_only, "error": body.get("error"),
    }


def load_cached_attempt(model_dir: str, attempt: int):
    """Reuse a previously fetched response if it exists on disk."""
    resp_path = os.path.join(model_dir, "attempt%d_response.txt" % attempt)
    meta_path = os.path.join(model_dir, "attempt%d_meta.json" % attempt)
    if not os.path.exists(resp_path) or not os.path.exists(meta_path):
        return None
    content = open(resp_path).read()
    meta = json.load(open(meta_path))
    files, fallback = extract_files(content)
    return {
        "content": content, "finish": meta.get("finish", ""), "usage": meta.get("usage", {}),
        "duration": meta.get("duration", 0.0), "files": files,
        "fallback": fallback, "reasoning_only": content.strip() == "",
    }


def save_attempt(model_dir: str, attempt: int, a: dict) -> None:
    with open(os.path.join(model_dir, "attempt%d_response.txt" % attempt), "w") as f:
        f.write(a["content"])
    meta = {"finish": a["finish"], "usage": a["usage"], "duration": a["duration"],
            "fallback_parse": a["fallback"]}
    if a.get("error"):
        meta["error"] = a["error"]
    with open(os.path.join(model_dir, "attempt%d_meta.json" % attempt), "w") as f:
        json.dump(meta, f, indent=1)
    expected = set(SUBMIT_FILES)
    for name in os.listdir(model_dir):
        if name.endswith(".gd") and name not in expected:
            os.unlink(os.path.join(model_dir, name))
    for i, src in enumerate(a["files"]):
        fname = SUBMIT_FILES[i] if i < len(SUBMIT_FILES) else "file%d.gd" % i
        with open(os.path.join(model_dir, fname), "w") as f:
            f.write(src)


def main():
    global ROUND, RUNNER_SCRIPT, SUBMISSIONS, SUBMIT_LIVE, SUBMIT_FILES, PROMPT_PATH, REPORT_FILE, MAX_TOKENS, FREE_MODE
    args = sys.argv[1:]
    only = skip = None
    no_repair = "--no-repair" in args
    free_mode = "--free" in args
    record = "--record" in args
    FREE_MODE = free_mode
    workers = 2 if free_mode else 4  # free tier is heavily rate-limited
    if "--round" in args:
        rnd = int(args[args.index("--round") + 1])
        if rnd in ROUNDS:
            ROUND = rnd
            prompt_name, runner, submissions_dir, submit_live, submit_files, max_tok = ROUNDS[rnd]
            RUNNER_SCRIPT = runner
            SUBMISSIONS = submissions_dir
            SUBMIT_LIVE = submit_live
            PROMPT_PATH = os.path.join(BASE, "challenge", prompt_name)
            REPORT_FILE = "report_round%d.md" % rnd
            SUBMIT_FILES = submit_files
            MAX_TOKENS = max_tok
    if "--only" in args:
        only = set(args[args.index("--only") + 1].split(","))
    if "--skip" in args:
        skip = set(args[args.index("--skip") + 1].split(","))

    if ROUND == 1:
        model_pool = MODELS
    elif ROUND == 2:
        model_pool = ROUND2_MODELS
    else:
        model_pool = ACTIVE_MODELS
    if free_mode:
        model_pool = FREE_MODELS
        REPORT_FILE = "report_round%d_free.md" % ROUND
    selected = [(mid, label) for mid, label in model_pool
                if (only is None or mid in only) and (skip is None or mid not in skip)]
    if not selected:
        raise SystemExit("no models selected")

    api_key = load_key()
    pricing = load_pricing()
    prompt = open(PROMPT_PATH).read()
    os.makedirs(SUBMISSIONS, exist_ok=True)
    os.makedirs(RESULTS, exist_ok=True)
    os.makedirs(os.path.join(RESULTS, "recordings"), exist_ok=True)

    print("Benchmarking %d models on Godot 4.7.1 (%s) [round %d, max_tokens %d]" %
          (len(selected), GODOT, ROUND, MAX_TOKENS))
    print("-" * 70)

    # ---- Phase 1: attempt 1 fetch (parallel, cached if already fetched) ----
    results = {}
    to_fetch = []
    for mid, _ in selected:
        d = os.path.join(SUBMISSIONS, slug(mid))
        os.makedirs(d, exist_ok=True)
        cached = load_cached_attempt(d, 1)
        if cached is not None:
            results[mid] = {"attempts": [cached], "eval": [], "scores": {}}
            print("cached  %-45s (reusing attempt 1)" % mid)
        else:
            results[mid] = {"attempts": [], "eval": [], "scores": {}}
            to_fetch.append((mid, d))

    if to_fetch:
        with ThreadPoolExecutor(max_workers=workers) as ex:
            futs = {ex.submit(fetch_attempt, api_key, mid, prompt, 1): (mid, d)
                    for mid, d in to_fetch}
            for fut in as_completed(futs):
                mid, d = futs[fut]
                a1 = fut.result()
                results[mid]["attempts"].append(a1)
                save_attempt(d, 1, a1)
                fin = a1["finish"]
                truncated = " (TRUNCATED)" if fin == "length" else ""
                ro = " (REASONING-ONLY, no content)" if a1["reasoning_only"] else ""
                print("fetched %-45s %6d in  %5d out%s%s" % (
                    mid, a1["usage"].get("prompt_tokens", 0),
                    a1["usage"].get("completion_tokens", 0), truncated, ro))

    # ---- Phase 2: eval attempt 1 (sequential) ----
    for mid, _ in selected:
        a1 = results[mid]["attempts"][0]
        write_submission(a1["files"])
        rec_name = "%s_r%d.mp4" % (slug(mid), ROUND) if record else None
        ev = run_eval(record_mp4=rec_name)
        results[mid]["eval"].append(ev)
        print("eval1  %-45s %3d/%-3d" % (mid, ev["passed"], ev["total"]))

    # ---- Phase 3: repair round (parallel) ----
    if not no_repair:
        needs_repair = [mid for mid, _ in selected
                        if results[mid]["eval"][0]["passed"] < results[mid]["eval"][0]["total"]]
        repair_fetch = []
        for mid in needs_repair:
            d = os.path.join(SUBMISSIONS, slug(mid))
            cached2 = load_cached_attempt(d, 2)
            if cached2 is not None:
                results[mid]["attempts"].append(cached2)
                print("cached  %-45s (reusing attempt 2)" % mid)
            else:
                repair_fetch.append((mid, d))
        if repair_fetch:
            print("Repair round for %d model(s): %s" % (len(repair_fetch),
                  ", ".join(mid for mid, _ in repair_fetch)))
            with ThreadPoolExecutor(max_workers=workers) as ex:
                futs = {ex.submit(fetch_attempt, api_key, mid, prompt, 2,
                                  failure_log=_failure_log(results[mid])): (mid, d)
                        for mid, d in repair_fetch}
                for fut in as_completed(futs):
                    mid, d = futs[fut]
                    a2 = fut.result()
                    results[mid]["attempts"].append(a2)
                    save_attempt(d, 2, a2)
                    print("fetched repair %-35s %5d out" % (mid, a2["usage"].get("completion_tokens", 0)))

        # ---- Phase 4: eval attempt 2 ----
        for mid, _ in selected:
            if len(results[mid]["attempts"]) < 2:
                continue
            a2 = results[mid]["attempts"][1]
            write_submission(a2["files"])
            rec_name = "%s_r%d_attempt2.mp4" % (slug(mid), ROUND) if record else None
            ev = run_eval(record_mp4=rec_name)
            results[mid]["eval"].append(ev)
            print("eval2  %-45s %3d/%-3d" % (mid, ev["passed"], ev["total"]))

    # ---- Score ----
    write_report(results, selected, pricing)
    print("-" * 70)
    print("Done. Report: %s" % os.path.join(RESULTS, REPORT_FILE))


def _failure_log(r: dict) -> str:
    ev = r["eval"][0]
    fails = [l for l in ev["lines"] if l.startswith("FAIL ")]
    # Extract categorized failure details (from updated runners)
    fail_cats = {}
    for l in ev.get("failure_details", []):
        if l.startswith("FAIL_CAT "):
            parts = l.replace("FAIL_CAT  ", "").split("  --  ", 1)
            cat = parts[0].strip() if parts else "unknown"
            detail = parts[1].strip() if len(parts) > 1 else ""
            fail_cats.setdefault(cat, []).append(detail)
    errs = [l for l in ev["stderr"].splitlines() if l.strip()]
    body = "\n".join(fails[:25])
    if errs:
        body += "\n--- script errors ---\n" + "\n".join(errs[:15])
    if not body:
        body = "(no checks ran)"
    return body


def _score(r: dict) -> dict:
    """Score a model's best attempt (first on ties). Includes wall time."""
    evals = r["eval"]
    atts = r["attempts"]
    best_idx = 0
    for i, ev in enumerate(evals):
        if ev["passed"] > evals[best_idx]["passed"]:
            best_idx = i
        elif ev["passed"] == evals[best_idx]["passed"] and i < best_idx:
            best_idx = i
    ev = evals[best_idx]
    att = atts[best_idx]
    battery_ran = ev["total"] >= 10  # real battery executed, not just the 2-4 load checks
    compile_pts = 10 if battery_ran else 0
    test_pts = round(50 * ev["passed"] / ev["total"]) if battery_ran else 0
    single_shot = 10 if (evals[0]["total"] >= 10 and evals[0]["passed"] == evals[0]["total"]) else 0
    hygiene = 10 if (not att["fallback"] and all(f.strip() for f in att["files"])) else 0
    # Total wall time to completion: API round-trips + local eval runs, all attempts.
    total_dur = sum(a["duration"] for a in atts) + sum(e["dur"] for e in evals)
    total = compile_pts + test_pts + single_shot + hygiene
    return {
        "best_idx": best_idx, "compile": compile_pts, "tests": test_pts,
        "single_shot": single_shot, "hygiene": hygiene,
        "total": total, "passed": ev["passed"], "total_checks": ev["total"],
        "attempts_used": len(evals), "dur": total_dur, "battery_ran": battery_ran,
        "fails_first": [l for l in evals[0]["lines"] if l.startswith("FAIL ")] if evals[0]["lines"] else [],
    }


def write_report(results, selected, pricing):
    raw = []
    for mid, label in selected:
        r = results[mid]
        s = _score(r)
        att = r["attempts"][s["best_idx"]]
        usage = att["usage"]
        pt, ct = usage.get("prompt_tokens", 0), usage.get("completion_tokens", 0)
        pp, cp = pricing.get(mid, (0.0, 0.0))
        cost = usage.get("cost") or ((pt * pp + ct * cp) / 1_000_000)
        reasoning_only = att["reasoning_only"] and len(r["attempts"]) == 1
        model_dir = os.path.join(SUBMISSIONS, slug(mid))
        lint_pts, lint_issues = gdlint_score(model_dir, s["best_idx"] + 1)
        if not s["battery_ran"]:
            lint_pts = 0  # code that never compiled/runs is not maintainable
        # Collect MP4 paths from eval runs if recording was done
        mp4_paths = []
        for ev in r["eval"]:
            if ev.get("mp4"):
                mp4_paths.append(os.path.relpath(ev["mp4"], RESULTS))
        # Extract failure categories from eval output
        fail_cats = {}
        ev1 = r["eval"][0] if r["eval"] else None
        if ev1:
            for l in ev1.get("failure_details", []):
                if l.startswith("FAIL_CAT "):
                    parts = l.replace("FAIL_CAT  ", "").split("  --  ", 1)
                    cat = parts[0].strip() if parts else "unknown"
                    fail_cats[cat] = fail_cats.get(cat, 0) + 1
        raw.append({
            "model": mid, "label": label, "s": s,
            "passed": s["passed"], "checks": s["total_checks"],
            "attempts": s["attempts_used"], "in_tok": pt, "out_tok": ct,
            "cost": cost, "dur": s["dur"], "fails": s["fails_first"],
            "fail_cats": fail_cats,
            "truncated": att["finish"] == "length", "reasoning_only": reasoning_only,
            "lint_pts": lint_pts, "lint_issues": lint_issues,
            "mp4": mp4_paths,
        })

    # Time points: normalized 0..10 within the field, only for submissions whose
    # battery actually ran. Faster (shorter total wall time) = more points.
    timed = [r for r in raw if r["s"]["battery_ran"]]
    if len(timed) >= 2:
        tmin = min(r["dur"] for r in timed)
        tmax = max(r["dur"] for r in timed)
        span = tmax - tmin
        for r in raw:
            if r["s"]["battery_ran"]:
                r["time_pts"] = round(10.0 * (tmax - r["dur"]) / span, 1) if span > 0 else 10.0
            else:
                r["time_pts"] = 0.0
    else:
        for r in raw:
            r["time_pts"] = 10.0 if r["s"]["battery_ran"] else 0.0
    for r in raw:
        r["total"] = r["s"]["total"] + r["time_pts"] + r["lint_pts"]

    rows = sorted(raw, key=lambda x: (-x["total"], -x["time_pts"]))

    with open(os.path.join(RESULTS, REPORT_FILE), "w") as f:
        f.write("# Godot Model Bench — round %d results%s\n\n" % (ROUND, " (FREE tier)" if FREE_MODE else ""))
        f.write("- Engine: Godot %s\n- Challenge: %s\n"
                "- %d checks; one repair round allowed; time 0..10 (faster = better); gdlint 0..10 (fewer issues = better)\n\n"
                % (_engine_version(), os.path.basename(PROMPT_PATH), max((r["checks"] for r in raw), default=0)))
        if any(r["mp4"] for r in raw):
            f.write("Recordings: see `results/recordings/` (MP4 files).\n\n")
        has_mp4 = any(r.get("mp4") for r in raw)
        if has_mp4:
            f.write("| # | Model | Score | Time | Lint | Checks | Comp | Tests | 1-shot | Hyg | Att | Wall s | Lint # | In tok | Out tok | Est $ | MP4 |\n")
            f.write("|---|-------|-------|------|------|--------|------|-------|--------|-----|-----|--------|--------|--------|---------|-------|-----|\n")
        else:
            f.write("| # | Model | Score | Time | Lint | Checks | Comp | Tests | 1-shot | Hyg | Att | Wall s | Lint # | In tok | Out tok | Est $ |\n")
            f.write("|---|-------|-------|------|------|--------|------|-------|--------|-----|-----|--------|--------|--------|---------|-------|\n")
        for i, r in enumerate(rows, 1):
            s = r["s"]
            mp4_cell = ""
            if has_mp4:
                mp4_names = [os.path.basename(p) for p in r.get("mp4", [])]
                mp4_cell = " | " + ", ".join(mp4_names) if mp4_names else " | -"
            f.write("| %d | %s | **%.1f** | %.1f | %d | %d/%d | %d | %d | %d | %d | %d | %.0f | %d | %d | %d | $%.4f%s |\n" % (
                i, r["label"], r["total"], r["time_pts"], r["lint_pts"], r["passed"], r["checks"],
                s["compile"], s["tests"], s["single_shot"], s["hygiene"],
                r["attempts"], r["dur"], r["lint_issues"], r["in_tok"], r["out_tok"], r["cost"], mp4_cell))
        f.write("\n## Per-model failure summary (first attempt)\n\n")
        for r in rows:
            f.write("**%s** (score %.1f)" % (r["model"], r["total"]))
            if r["reasoning_only"]:
                f.write(" — **no output content**: burned the entire output budget on reasoning")
            elif r["truncated"]:
                f.write(" — output truncated (max_tokens)")
            f.write("\n")
            if not r["fails"]:
                f.write("  - clean pass\n")
            else:
                for fl in r["fails"][:6]:
                    f.write("  - %s\n" % fl)
                if r.get("fail_cats"):
                    f.write("  - **Failure categories**:\n")
                    for cat, count in r["fail_cats"].items():
                        label = {"logic": "Logic/Spec", "api": "API misuse", "timing": "Timing",
                                 "spec": "Missing API", "style": "Style/Lint"}.get(cat, cat)
                        f.write("    - %s: %d\n" % (label, count))
            f.write("\n")

    print("\n%3s  %-44s %6s  %5s  %4s  %s/%s  %6s" % ("Rank", "Model", "Score", "Tpts", "Lint", "passed", "checks", "Wall s"))
    for i, r in enumerate(rows, 1):
        print("%3d  %-44s %6.1f  %5.1f  %4d  %d/%d  %6.0f%s" % (
            i, r["model"], r["total"], r["time_pts"], r["lint_pts"], r["passed"], r["checks"], r["dur"],
            "  [truncated]" if r["truncated"] else ""))

    if ROUND == 2 and not FREE_MODE:
        with open(os.path.join(RESULTS, REPORT_FILE), "a") as f:
            f.write("## Roster note (2026-08)\n\n"
                    "Dropped from the active roster after this round, per user decision:\n\n"
                    "- **qwen/qwen3.8-max** — 531s wall, $0.146, ~24,000 output tokens for ~90 lines of code "
                    "(0.0 time points)\n"
                    "- **nex-agi/nex-n2-pro** — 311s wall; also burned the entire 32k output budget on "
                    "reasoning with zero content on first attempt (both rounds)\n"
                    "- **minimax/minimax-m3** — insufficient: needed the repair round (extended Node, not Node2D)\n"
                    "- **thinkingmachines/inkling-small** — insufficient: 162s wall, 9.4k output tokens for "
                    "~90 lines of code\n")


def _engine_version() -> str:
    try:
        p = subprocess.run([GODOT, "--version"], capture_output=True, text=True, timeout=30)
        return p.stdout.strip() or p.stderr.strip() or "4.7.1"
    except Exception:
        return "4.7.1"


if __name__ == "__main__":
    main()
