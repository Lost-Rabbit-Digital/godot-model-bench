# Godot Model Bench — round 3 results (FREE tier)

- Engine: Godot 4.7.1.stable.official.a13da4feb
- Challenge: PROMPT3.md
- 16 checks; one repair round allowed; time 0..10 (faster = better); gdlint 0..10 (fewer issues = better)

| # | Model | Score | Time | Lint | Checks | Comp | Tests | 1-shot | Hyg | Att | Wall s | Lint # | In tok | Out tok | Est $ |
|---|-------|-------|------|------|--------|------|-------|--------|-----|-----|--------|--------|--------|---------|-------|
| 1 | Laguna S 2.1 (free) | **81.0** | 10.0 | 10 | 13/16 | 10 | 41 | 0 | 10 | 2 | 50 | 0 | 1249 | 775 | $0.0000 |
| 2 | Laguna XS 2.1 (free) | **77.0** | 0.0 | 7 | 16/16 | 10 | 50 | 0 | 10 | 2 | 63 | 4 | 1516 | 1866 | $0.0000 |

## Per-model failure summary (first attempt)

**poolside/laguna-s-2.1:free** (score 81.0)
  - FAIL  balls spread horizontally from pegs (x-range > 120)  --  too few in-bounds samples=13
  - FAIL  loop recycled balls (signal fired)  --  recycled=0
  - FAIL  no balls stuck below LOOP_Y  --  stuck=200

**poolside/laguna-xs-2.1:free** (score 77.0)
  - FAIL  pegboard.gd loads/parses  --  load failed or unparseable

