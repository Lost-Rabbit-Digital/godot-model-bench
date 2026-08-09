#!/usr/bin/env python3
"""Generate all_results.json and all_results.js from benchmark reports + manual data."""
import json, os

BASE = os.path.dirname(os.path.abspath(__file__))
RESULTS = os.path.join(BASE, "results")

def parse_report(path, tier="paid", strip_free_suffix=False):
    if not os.path.exists(path):
        return []
    lines = open(path).read().splitlines()
    header_line = None
    for i, line in enumerate(lines):
        if line.startswith("| # | Model"):
            header_line = i
            break
    if header_line is None:
        return []
    header_cells = [c.strip() for c in lines[header_line].strip("|").split("|")]
    has_mp4 = "MP4" in header_cells
    models = []
    for line in lines[header_line + 2:]:
        line = line.strip()
        if not line.startswith("| ") or "| **" not in line:
            if "## " in line:
                break
            continue
        cells = [c.strip() for c in line.strip("|").split("|")]
        expected = 16 + (1 if has_mp4 else 0)
        if len(cells) != expected:
            continue
        label = cells[1].replace(" ⭐", "").strip()
        if strip_free_suffix:
            label = label.replace(" (free)", "").strip()
        score = float(cells[2].strip("*, "))
        passed, total = cells[5].split("/")
        wall = int(cells[11])
        lint_n = int(cells[12])
        in_tok = int(cells[13])
        out_tok = int(cells[14])
        cost = float(cells[15].lstrip("$"))
        comp = int(cells[6])
        tests = int(cells[7])
        shot = int(cells[8])
        mp4 = cells[16] if has_mp4 and len(cells) > 16 else ""
        models.append({
            "label": label, "score": score, "passed": int(passed), "total": int(total),
            "comp": comp, "tests": tests, "shot": shot, "wall": wall,
            "lint_n": lint_n, "in_tok": in_tok, "out_tok": out_tok, "cost": cost,
            "tier": tier, "mp4": mp4 if mp4 else None
        })
    return models

ALL_DATA = {"rounds": []}

# Rounds 1-3: parse from paid + free reports (they have all models)
for rnd, name, checks, report, free_report in [
    (1, "Beehive Simulation", 45, "report.md", "report_round1_free.md"),
    (2, "Greenhouse Automation", 34, "report_round2.md", "report_round2_free.md"),
    (3, "Pegboard Physics", 16, "report_round3.md", "report_round3_free.md"),
]:
    models = parse_report(os.path.join(RESULTS, report), "paid")
    models += parse_report(os.path.join(RESULTS, free_report), "free", strip_free_suffix=True)
    r = {"num": rnd, "name": name, "checks": checks, "models": models}
    ALL_DATA["rounds"].append(r)

# Round 4: from report + manual data for Muse/Mimo
r4_models = parse_report(os.path.join(RESULTS, "report_round4.md"))
# Add Muse Spark and Mimo from separate --record runs
r4_models.append({"label": "Muse Spark 1.2", "score": 85.9, "passed": 26, "total": 27,
    "comp": 10, "tests": 48, "shot": 0, "wall": 65, "lint_n": 1, "in_tok": 1473, "out_tok": 8170,
    "cost": 0.0366, "tier": "paid",
    "mp4": "meta_muse-spark-1.2_r4.mp4, meta_muse-spark-1.2_r4_attempt2.mp4"})
r4_models.append({"label": "Xiaomi MiMo V2.5 Pro", "score": 84.1, "passed": 26, "total": 27,
    "comp": 10, "tests": 48, "shot": 0, "wall": 194, "lint_n": 0, "in_tok": 1476, "out_tok": 8578,
    "cost": 0.0075, "tier": "paid",
    "mp4": "xiaomi_mimo-v2.5-pro_r4.mp4, xiaomi_mimo-v2.5-pro_r4_attempt2.mp4"})
ALL_DATA["rounds"].append({"num": 4, "name": "HUD/UI Juice", "checks": 27, "models": r4_models})

# Rounds 5-7: combine data from all runs (reports only have latest 3-model run)
# Round 5: 6-model run (DeepSeek, Kat, Laguna, Gemini, Muse, Mimo) + 3-model run (Ling, Aion, Hy3)
r5_models = [
    # From first 6-model run
    {"label": "Gemini 3.6 Flash", "score": 100.0, "passed": 18, "total": 18, "comp": 10, "tests": 50, "shot": 10,
     "wall": 15, "lint_n": 0, "in_tok": 1055, "out_tok": 3199, "cost": 0.0493, "tier": "paid"},
    {"label": "Xiaomi MiMo V2.5 Pro", "score": 100.0, "passed": 18, "total": 18, "comp": 10, "tests": 50, "shot": 10,
     "wall": 16, "lint_n": 0, "in_tok": 949, "out_tok": 872, "cost": 0.0062, "tier": "paid"},
    {"label": "Muse Spark 1.2", "score": 99.4, "passed": 18, "total": 18, "comp": 10, "tests": 50, "shot": 10,
     "wall": 33, "lint_n": 0, "in_tok": 945, "out_tok": 8785, "cost": 0.0227, "tier": "paid"},
    {"label": "Laguna S 2.1", "score": 95.3, "passed": 18, "total": 18, "comp": 10, "tests": 50, "shot": 10,
     "wall": 156, "lint_n": 0, "in_tok": 1016, "out_tok": 17185, "cost": 0.0003, "tier": "paid"},
    {"label": "DeepSeek V4 Flash", "score": 93.6, "passed": 18, "total": 18, "comp": 10, "tests": 50, "shot": 10,
     "wall": 207, "lint_n": 0, "in_tok": 995, "out_tok": 3928, "cost": 0.0010, "tier": "paid"},
    {"label": "Kat Coder Air v2.5", "score": 74.0, "passed": 16, "total": 18, "comp": 10, "tests": 50, "shot": 0,
     "wall": 314, "lint_n": 0, "in_tok": 1003, "out_tok": 1597, "cost": 0.0012, "tier": "paid"},
    # From second 3-model run
    {"label": "Ling 3.0 Flash", "score": 88.3, "passed": 18, "total": 18, "comp": 10, "tests": 50, "shot": 0,
     "wall": 119, "lint_n": 0, "in_tok": 1279, "out_tok": 22616, "cost": 0.0014, "tier": "paid"},
    {"label": "Aion 3.0 Mini", "score": 97.0, "passed": 18, "total": 18, "comp": 10, "tests": 50, "shot": 10,
     "wall": 57, "lint_n": 3, "in_tok": 994, "out_tok": 4470, "cost": 0.0070, "tier": "paid"},
    {"label": "Tencent Hy3", "score": 87.0, "passed": 18, "total": 18, "comp": 10, "tests": 50, "shot": 10,
     "wall": 422, "lint_n": 4, "in_tok": 979, "out_tok": 18305, "cost": 0.0098, "tier": "paid"},
]
ALL_DATA["rounds"].append({"num": 5, "name": "NPC State Machine", "checks": 18, "models": r5_models})

# Round 6: 6-model run + 3-model run
r6_models = [
    {"label": "Kat Coder Air v2.5", "score": 100.0, "passed": 16, "total": 16, "comp": 10, "tests": 50, "shot": 10,
     "wall": 20, "lint_n": 0, "in_tok": 991, "out_tok": 3276, "cost": 0.0012, "tier": "paid"},
    {"label": "Muse Spark 1.2", "score": 99.7, "passed": 16, "total": 16, "comp": 10, "tests": 50, "shot": 10,
     "wall": 26, "lint_n": 0, "in_tok": 807, "out_tok": 5384, "cost": 0.0227, "tier": "paid"},
    {"label": "DeepSeek V4 Flash", "score": 98.9, "passed": 16, "total": 16, "comp": 10, "tests": 50, "shot": 10,
     "wall": 42, "lint_n": 0, "in_tok": 855, "out_tok": 3612, "cost": 0.0010, "tier": "paid"},
    {"label": "Gemini 3.6 Flash", "score": 96.7, "passed": 16, "total": 16, "comp": 10, "tests": 50, "shot": 10,
     "wall": 26, "lint_n": 3, "in_tok": 881, "out_tok": 5364, "cost": 0.0493, "tier": "paid"},
    {"label": "Ling 3.0 Flash", "score": 100.0, "passed": 16, "total": 16, "comp": 10, "tests": 50, "shot": 10,
     "wall": 45, "lint_n": 0, "in_tok": 894, "out_tok": 17562, "cost": 0.0011, "tier": "paid"},
    {"label": "Aion 3.0 Mini", "score": 97.2, "passed": 16, "total": 16, "comp": 10, "tests": 50, "shot": 10,
     "wall": 67, "lint_n": 2, "in_tok": 854, "out_tok": 6117, "cost": 0.0092, "tier": "paid"},
    {"label": "Tencent Hy3", "score": 85.0, "passed": 16, "total": 16, "comp": 10, "tests": 50, "shot": 10,
     "wall": 168, "lint_n": 10, "in_tok": 834, "out_tok": 17051, "cost": 0.0091, "tier": "paid"},
]
ALL_DATA["rounds"].append({"num": 6, "name": "Procedural Animation", "checks": 16, "models": r6_models})

# Round 7: 6-model run (first) + 3-model run
r7_models = [
    {"label": "Gemini 3.6 Flash", "score": 98.7, "passed": 28, "total": 28, "comp": 10, "tests": 50, "shot": 10,
     "wall": 51, "lint_n": 0, "in_tok": 1024, "out_tok": 14095, "cost": 0.0493, "tier": "paid"},
    {"label": "Muse Spark 1.2", "score": 88.4, "passed": 28, "total": 28, "comp": 10, "tests": 48, "shot": 0,
     "wall": 60, "lint_n": 0, "in_tok": 943, "out_tok": 6973, "cost": 0.0227, "tier": "paid"},
    {"label": "DeepSeek V4 Flash", "score": 83.6, "passed": 25, "total": 28, "comp": 10, "tests": 50, "shot": 0,
     "wall": 54, "lint_n": 0, "in_tok": 979, "out_tok": 3047, "cost": 0.0010, "tier": "paid"},
    {"label": "Xiaomi MiMo V2.5 Pro", "score": 80.0, "passed": 28, "total": 28, "comp": 10, "tests": 48, "shot": 0,
     "wall": 284, "lint_n": 0, "in_tok": 939, "out_tok": 14661, "cost": 0.0062, "tier": "paid"},
    {"label": "Laguna S 2.1", "score": 79.0, "passed": 22, "total": 28, "comp": 10, "tests": 48, "shot": 0,
     "wall": 17, "lint_n": 0, "in_tok": 1003, "out_tok": 767, "cost": 0.0003, "tier": "paid"},
    {"label": "Kat Coder Air v2.5", "score": 78.9, "passed": 26, "total": 28, "comp": 10, "tests": 48, "shot": 0,
     "wall": 208, "lint_n": 0, "in_tok": 991, "out_tok": 3276, "cost": 0.0012, "tier": "paid"},
    {"label": "Ling 3.0 Flash", "score": 98.2, "passed": 28, "total": 28, "comp": 10, "tests": 50, "shot": 10,
     "wall": 102, "lint_n": 0, "in_tok": 1039, "out_tok": 25630, "cost": 0.0014, "tier": "paid"},
    {"label": "Aion 3.0 Mini", "score": 85.0, "passed": 25, "total": 28, "comp": 10, "tests": 50, "shot": 0,
     "wall": 113, "lint_n": 0, "in_tok": 978, "out_tok": 3471, "cost": 0.0055, "tier": "paid"},
    {"label": "Tencent Hy3", "score": 77.0, "passed": 28, "total": 28, "comp": 10, "tests": 50, "shot": 0,
     "wall": 640, "lint_n": 3, "in_tok": 1391, "out_tok": 21051, "cost": 0.0113, "tier": "paid"},
]
ALL_DATA["rounds"].append({"num": 7, "name": "Particles/VFX", "checks": 28, "models": r7_models})

# Write JSON
with open(os.path.join(RESULTS, "all_results.json"), "w") as f:
    json.dump(ALL_DATA, f, indent=2)

with open(os.path.join(RESULTS, "all_results.js"), "w") as f:
    f.write("const ALL_RESULTS = " + json.dumps(ALL_DATA) + ";\n")

# Print summary
print("Dashboard data updated:")
for r in ALL_DATA["rounds"]:
    print(f"  R{r['num']}: {r['name']} — {len(r['models'])} models")
print(f"\nTotal model-round entries: {sum(len(r['models']) for r in ALL_DATA['rounds'])}")
print(f"Total cost: ${sum(m['cost'] for r in ALL_DATA['rounds'] for m in r['models']):.4f}")
