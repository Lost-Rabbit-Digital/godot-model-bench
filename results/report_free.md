# Godot Model Bench — round 1 results (FREE tier)

- Engine: Godot 4.7.1.stable.official.a13da4feb
- Challenge: PROMPT.md
- 4 checks; one repair round allowed; time 0..10 (faster = better); gdlint 0..10 (fewer issues = better)

| # | Model | Score | Time | Lint | Checks | Comp | Tests | 1-shot | Hyg | Att | Wall s | Lint # | In tok | Out tok | Est $ |
|---|-------|-------|------|------|--------|------|-------|--------|-----|-----|--------|--------|--------|---------|-------|
| 1 | Gemma 4 31B IT (free) | **0.0** | 0.0 | 0 | 2/4 | 0 | 0 | 0 | 0 | 2 | 0 | -1 | 0 | 0 | $0.0000 |

## Per-model failure summary (first attempt)

**google/gemma-4-31b-it:free** (score 0.0)
  - FAIL  beehive.gd exposes required API  --  missing: ["tick", "harvest", "buy_upgrade", "daily_production", "season_factor"]
  - FAIL  honey_math.gd exposes required API  --  missing: ["bottles_for", "jar_price", "short_label"]

