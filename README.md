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

## Interactive Submission Viewer

A Godot UI to run and observe any round's model submission live, instead of
just headless test results. It stages a chosen submission into the round's live
dir and drives it with a per-round visualization.

```bash
godot --path .                          # open the viewer menu (rounds -> models)
godot --path . -- --round 3 --model meta_muse-spark-1.2   # jump straight into a round
godot --path . -- --round 7 --model reference             # run the reference
```

Each round gets a visualization tailored to its submission type:

| Round | What the viewer shows |
|-------|------------------------|
| 1 | Hive hexagon with honey fill, worker bees, season wheel; tick/harvest/buy buttons + auto-tick |
| 2 | Greenhouse frame, live temperature/heater, sprinkler drops; temp-set and report buttons |
| 3 | Galton-board physics: drawn pegs + bouncy balls falling through; recycled counter, reset/freeze |
| 4 | The HUD Control itself + buttons to drive set_health / add_score / pulse, and a sparkle spawner |
| 5 | NPC rectangle with patrol waypoints, detection/attack ranges, click-to-move target, live state label |
| 6 | The animated character (body + eyes) with moving / attack / auto-demo controls |
| 7 | Particle burst with flash quad; Burst button + auto-repeat, particle/lifetime readout |

Every submission view is also framed by a **model-identity header + submission metadata
panel** so you can assess qualitative differences at a glance, not just the passing battery:

- **Model accent color** — each model slug gets a deterministic color (golden-ratio hue
  spacing) used for the header strip, a swatch, and a subtle tint behind the world, so
  switching models is visually obvious even when the submission draws nothing.
- **Score badge** — colored by result: green (full pass), amber (partial pass), red
  (gate never met — broken/empty battery). Shows `score | passed/total checks | tier`.
- **Submission metadata block** — pulled live from `attemptN_meta.json` and
  `results/all_results.json`: cost ($), in/out tokens (+ reasoning-token share), API
  response time, total wall time (API + eval), gdlint issues, and whether a repair round
  was used. Lets you tell apart two models that both pass (e.g. cheap+fast vs
  expensive+slow) before you even look at the world.

The viewer is under `viewer/`:

```
viewer/menu.tscn          Main menu (round selector + model list)
viewer/menu.gd
viewer/stage.tscn         Stage shell (back button, world, error display)
viewer/stage.gd
viewer/viewer_state.gd    Autoload: round/mode config + staging (copies a model's
                          .gd files into the live dir, stripping class_name) +
                          model label/accent/score lookups + attempt-meta loader
viewer/drivers/
  base_driver.gd          Shared driver base (world + control panel layout, model
                          header + metadata block, per-model accent tint)
  round1.gd ... round7.gd Per-round visualization
```

Notes:
- The viewer writes the selected model's files to the round's live dir
  (`submission/`, `submission2/`, ...) exactly like `run_bench.py` does, so
  submissions that reference each other by path (e.g. `pegboard.gd` loading
  `res://submission3/bouncy_ball.gd`) resolve correctly.
- `xvfb-run -a godot --path . -- --round 3 --model reference --shot /tmp/x.png`
  (add `--shot <path>` to any round/model launch) saves a screenshot and quits.
  A dummy `--headless` renderer has no viewport texture, so screenshot capture
  fails fast with a diagnostic instead of hanging.
- Headless smoke test for all 7 rounds:

```bash
godot --headless --path . -s tests/viewer_smoke.gd
```

- Catalog smoke test for every complete cached model submission:

```bash
godot --headless --path . -s tests/viewer_catalog.gd
```

- Normalize/migrate cached submissions after importing old benchmark data:

```bash
python3 organize_submissions.py       # report only
python3 organize_submissions.py --apply
```

There is exactly one cache root per round: `submissions_round1/` through
`submissions_round7/`. Incomplete or response-only model directories remain
visible in the menu but are disabled instead of accidentally launching stale
code from a previous selection.

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
submissions_round1/ Cached model outputs + API responses (round 1)
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
viewer/             Interactive submission viewer (menu + stage + per-round drivers)
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
