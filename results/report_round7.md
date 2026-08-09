# Godot Model Bench — round 7 results

- Engine: Godot 4.7.1.stable.official.a13da4feb
- Challenge: PROMPT7.md
- 28 checks; one repair round allowed; time 0..10 (faster = better); gdlint 0..10 (fewer issues = better)

| # | Model | Score | Time | Lint | Checks | Comp | Tests | 1-shot | Hyg | Att | Wall s | Lint # | In tok | Out tok | Est $ |
|---|-------|-------|------|------|--------|------|-------|--------|-----|-----|--------|--------|--------|---------|-------|
| 1 | Aion 3.0 Mini | **85.0** | 10.0 | 10 | 25/28 | 10 | 45 | 0 | 10 | 2 | 113 | 0 | 978 | 3471 | $0.0055 |
| 2 | Tencent Hy3 | **77.0** | 0.0 | 7 | 28/28 | 10 | 50 | 0 | 10 | 2 | 640 | 3 | 1391 | 21051 | $0.0113 |

## Per-model failure summary (first attempt)

**aion-labs/aion-3.0-mini** (score 85.0)
  - FAIL  texture is not null  --  null texture
  - FAIL  finished=true before burst (idle)  --  finished=false
  - FAIL  becomes finished after burst + enough ticks  --  finished=false

**tencent/hy3** (score 77.0)
  - FAIL  texture is not null  --  null texture

