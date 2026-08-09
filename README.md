# Godot Model Bench

Benchmarking LLMs on Godot 4.7 GDScript game-development tasks. Each "round" is a
self-contained challenge that tests a specific game-dev competency.

## Quick Start

```bash
# Run a specific round (must be run from the project directory)
python3 run_bench.py --round 4

# Run with recording (produces MP4 files for visual comparison)
python3 run_bench.py --round 4 --record

# Single attempt only (no repair round)
python3 run_bench.py --round 4 --no-repair

# Only specific models
python3 run_bench.py --round 4 --only "poolside/laguna-s-2.1,google/gemini-3.6-flash"
```

## Dashboard & UI audit

The results dashboard (`results/dashboard.html`) is a D3 + ECharts single-page report.
Rebuild its data and serve it locally:

```bash
./host_dashboard.sh            # rebuild data + serve + open browser
./host_dashboard.sh --no-build # just serve existing results
```

Every dashboard change should pass the Playwright UI audit before commit. It renders
the page at 1440×900 / 1024×768 / 1280×800 and programmatically checks for:

- clipped / cut-off SVG text labels (model names, value labels)
- overlapping SVG text elements
- chart text larger than the body font
- page-level horizontal overflow
- ECharts canvases rendering (non-blank) and fitting their containers
- console errors / JS exceptions

```bash
npx playwright install chromium   # once
npm run audit                    # exit 0 = clean, 1 = visual findings, 2 = JS errors
```

Screenshots land in `tests/audit-output/shots/` and the report in
`tests/audit-output/report.md` for vision-based review.

## Rounds

| Round | Challenge             | Files                              | Checks | Runner          |
|-------|-----------------------|-------------------------------------|--------|-----------------|
| 1     | Beehive simulation    | beehive.gd, honey_math.gd          | 45     | tests/runner.gd |
| 2     | Greenhouse automation | greenhouse.gd, thermostat.gd         | 34     | tests/runner2.gd|
| 3     | Pegboard physics      | pegboard.gd, bouncy_ball.gd          | 16     | tests/runner3.gd|
| 4     | HUD/juice UI          | juice_hud.gd, hud_sparkle.gd         | 27     | tests/runner4.gd|
| 5     | NPC state machine     | npc_controller.gd                     | 18     | tests/runner5.gd|
| 6     | Procedural animation  | char_animator.gd                     | 16     | tests/runner6.gd|
| 7     | Particles/VFX         | spell_vfx.gd                         | 28     | tests/runner7.gd|

## Scoring (0-100 max per model)
**Token limits:** Rounds 1-3 use 16k-32k tokens; rounds 4-7 use 65536 tokens (32k caused
reasoning-only/truncation failures on complex rounds).

- **Compile (10 pts)**: the test runner executed the full battery (>=10 checks ran)
- **Correctness (0-50 pts)**: proportional to PASS/total checks
- **Single-shot bonus (10 pts)**: all checks pass on first attempt (no repair)
- **Hygiene (10 pts)**: proper file extraction, typed code, no empty submissions
- **Time points (0-10 pts)**: normalized within the field (faster = more points)
- **Lint (0-10 pts)**: gdlint score (fewer style issues = more points)

## Recording & Visual Comparison

### MP4 Recording

Use `--record` to run each model's eval under Xvfb with real rendering:

```bash
python3 run_bench.py --round 4 --record
```

This produces MP4 files in `results/recordings/` showing the model's submission
running in the test scene. AVI files are converted to MP4 via ffmpeg.

**Requirements:**
- `xvfb-run` (Xvfb) must be installed
- `ffmpeg` must be installed
- Godot must support OpenGL3 rendering under Xvfb

### Standalone Recording

To record a specific submission without running the full benchmark:

```bash
python3 record_round.py --round 4 --only "poolside/laguna-s-2.1"
```

### Manual Test Run

To test a single submission against a runner (for debugging):

```bash
godot --headless --path . -s res://tests/runner4.gd
```

## Project Layout

```
challenge/          Prompt specs (PROMPT.md, PROMPT2.md, ... PROMPT7.md)
tests/              Test runners (runner.gd through runner7.gd)
submission/         Live dir for round 1 (harness writes model code here)
submission2/        Live dir for round 2
submission3/        Live dir for round 3
submission4/        Live dir for round 4
submission5/        Live dir for round 5
submission6/        Live dir for round 6
submission7/        Live dir for round 7
submissions/        Cached model outputs + API responses (round 1)
submissions_round2/ Cached outputs (round 2)
...
submissions_roundN/ Cached outputs (round N)
  reference/        Reference implementation
  <model_slug>/     Per-model: attempt1_response.txt, attempt1_meta.json,
                    <submit_files>, beehive.gd, honey_math.gd, etc.
results/            Generated reports + recordings
run_bench.py        Main benchmark harness
record_round.py     Standalone recording harness
capture_shots.py    Screenshot capture + HTML visual comparison
```

## Reference Implementations

Each round has a reference implementation in `submissions_roundN/reference/`.
These are verified to pass all checks in the corresponding runner. Use them as:
- A sanity check before running models
- A starting point for understanding the expected API

## Notes

- Godot 4.7.1 is required (`godot --version` should show 4.7.1.stable)
- The harness uses `xvfb-run` for rendering under headless Linux
- `class_name` is intentionally omitted from reference files to avoid global-class
  cache conflicts when multiple submissions are in the same project directory
- Rounds 4-7 extend beyond the original rounds 1-3 to cover UI/juice, NPC behavior,
  procedural animation, and VFX — the bread-and-butter of game development
