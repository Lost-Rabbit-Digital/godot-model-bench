#!/usr/bin/env python3
"""Record MP4 videos of Godot benchmark submissions under Xvfb.

Usage:
  python3 record_round.py --round 4 --only model_name
  python3 record_round.py --round 4

Each model's submission dir must already contain the GDScript files.
This script:
  1. Copies the model's files into the live submission dir (submissionN/)
  2. Runs godot under xvfb-run with --write-movie, capturing an AVI
  3. Converts the AVI to MP4 via ffmpeg
  4. Saves the MP4 to results/recordings/

Also captures a screenshot at a fixed frame for visual comparison.
"""
import json
import os
import re
import shutil
import subprocess
import sys

BASE = os.path.dirname(os.path.abspath(__file__))
RESULTS = os.path.join(BASE, "results")
RECORDINGS = os.path.join(RESULTS, "recordings")
SCREENSHOTS = os.path.join(RESULTS, "screenshots")
SYMLINK_GODOT = "/home/dmcha/.local/bin/godot"
STOCK_GODOT = os.path.expanduser("~/Godot/godot-4.7.1-stock")
GODOT = STOCK_GODOT if os.path.exists(STOCK_GODOT) else SYMLINK_GODOT

ROUNDS = {
    4: ("PROMPT4.md", "res://tests/runner4.gd", "submission4",
        ("juice_hud.gd", "hud_sparkle.gd"), "res://tests/runner4.gd"),
    5: ("PROMPT5.md", "res://tests/runner5.gd", "submission5",
        ("npc_controller.gd",), "res://tests/runner5.gd"),
    6: ("PROMPT6.md", "res://tests/runner6.gd", "submission6",
        ("char_animator.gd",), "res://tests/runner6.gd"),
    7: ("PROMPT7.md", "res://tests/runner7.gd", "submission7",
        ("spell_vfx.gd",), "res://tests/runner7.gd"),
}

# Active models (same as round 3+ active roster)
ACTIVE_MODELS = [
    ("inclusionai/ling-3.0-flash", "Ling 3.0 Flash"),
    ("meta/muse-spark-1.2", "Muse Spark 1.2"),
    ("deepseek/deepseek-v4-flash-0731", "DeepSeek V4 Flash"),
    ("qwen/qwen3.7-flash", "Qwen3.7 Flash"),
    ("poolside/laguna-s-2.1", "Laguna S 2.1"),
    ("google/gemini-3.6-flash", "Gemini 3.6 Flash"),
    ("google/gemini-3.5-flash-lite", "Gemini 3.5 Flash Lite"),
    ("aion-labs/aion-3.0-mini", "Aion 3.0 Mini"),
    ("tencent/hy3", "Tencent Hy3"),
    ("xiaomi/mimo-v2.5-pro", "Xiaomi MiMo V2.5 Pro"),
    ("kwaipilot/kat-coder-air-v2.5", "Kat Coder Air v2.5"),
]


def slug(model_id: str) -> str:
    return model_id.replace("/", "_").replace(":", "_")


def record_model(round_num: int, model_id: str, label: str) -> bool:
    if round_num not in ROUNDS:
        print("Unknown round %d" % round_num)
        return False

    _, runner, submit_live, submit_files, _ = ROUNDS[round_num]
    submissions_dir = os.path.join(BASE, "submissions_round%d" % round_num)
    model_dir = os.path.join(submissions_dir, slug(model_id))

    if not os.path.isdir(model_dir):
        print("  No submission dir for %s — skipping" % model_id)
        return False

    # Copy model's files into the live submission dir
    live_dir = os.path.join(BASE, submit_live)
    os.makedirs(live_dir, exist_ok=True)
    for fname in submit_files:
        src = os.path.join(model_dir, fname)
        dst = os.path.join(live_dir, fname)
        if os.path.exists(src):
            shutil.copy2(src, dst)
        else:
            # Try attempt2
            src2 = os.path.join(model_dir, fname)
            if os.path.exists(src2):
                shutil.copy2(src2, dst)

    # Re-import to pick up new class_names
    subprocess.run([GODOT, "--headless", "--path", BASE, "--import"],
                   capture_output=True, text=True, timeout=30)

    # Build a recording runner that captures screenshots during the run
    # We wrap the existing runner with a movie + screenshot capture
    avi_path = os.path.join(RESULTS, "%s_r%d.avi" % (slug(model_id), round_num))
    mp4_path = os.path.join(RECORDINGS, "%s_r%d.mp4" % (slug(model_id), round_num))
    os.makedirs(RECORDINGS, exist_ok=True)

    # Run under xvfb with movie recording
    cmd = ["xvfb-run", "-a", GODOT, "--path", BASE, "-s", runner,
           "--no-header", "--rendering-driver", "opengl3",
           "--write-movie", avi_path]
    print("  Recording: %s" % " ".join(cmd[:3] + [cmd[3][:40] + "..." if len(cmd[3]) > 40 else cmd[3]]))

    try:
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
        if p.returncode != 0 and "BENCH_TIMEOUT" in (p.stderr or ""):
            print("  TIMEOUT for %s" % model_id)
        result_line = [l for l in (p.stdout or "").splitlines() if "BENCH_RESULT" in l]
        if result_line:
            print("  %s" % result_line[0])
    except subprocess.TimeoutExpired:
        print("  TIMEOUT for %s" % model_id)

    # Convert to MP4
    if os.path.exists(avi_path) and os.path.getsize(avi_path) > 0:
        os.makedirs(RECORDINGS, exist_ok=True)
        mp4_path = os.path.join(RECORDINGS, "%s_r%d.mp4" % (slug(model_id), round_num))
        subprocess.run(["ffmpeg", "-y", "-i", avi_path,
                        "-c:v", "libx264", "-crf", "20",
                        "-pix_fmt", "yuv420p", mp4_path],
                       capture_output=True, timeout=120)
        if os.path.exists(mp4_path) and os.path.getsize(mp4_path) > 0:
            print("  MP4 saved: %s (%d bytes)" % (mp4_path, os.path.getsize(mp4_path)))
        # Clean up AVI
        os.unlink(avi_path)
    else:
        print("  No AVI produced — rendering may not be available")

    return os.path.exists(mp4_path)


def main():
    args = sys.argv[1:]
    round_num = 4
    only = None
    if "--round" in args:
        round_num = int(args[args.index("--round") + 1])
    if "--only" in args:
        only = set(args[args.index("--only") + 1].split(","))
    if "--round-dir" in args:
        # Allow custom submissions dir
        pass

    if round_num not in ROUNDS:
        print("Supported rounds: %s" % list(ROUNDS.keys()))
        sys.exit(1)

    print("Recording round %d submissions..." % round_num)
    print("-" * 60)

    for mid, label in ACTIVE_MODELS:
        if only and mid not in only:
            continue
        print("\n%s (%s)" % (label, mid))
        record_model(round_num, mid, label)


if __name__ == "__main__":
    main()
