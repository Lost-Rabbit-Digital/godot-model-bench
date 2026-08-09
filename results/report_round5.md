# Godot Model Bench — round 5 results

- Engine: Godot 4.7.1.stable.official.a13da4feb
- Challenge: PROMPT5.md
- 18 checks; one repair round allowed; time 0..10 (faster = better); gdlint 0..10 (fewer issues = better)

| # | Model | Score | Time | Lint | Checks | Comp | Tests | 1-shot | Hyg | Att | Wall s | Lint # | In tok | Out tok | Est $ |
|---|-------|-------|------|------|--------|------|-------|--------|-----|-----|--------|--------|--------|---------|-------|
| 1 | Aion 3.0 Mini | **97.0** | 10.0 | 7 | 18/18 | 10 | 50 | 10 | 10 | 1 | 57 | 3 | 994 | 4470 | $0.0070 |
| 2 | Ling 3.0 Flash | **88.3** | 8.3 | 10 | 18/18 | 10 | 50 | 0 | 10 | 2 | 119 | 0 | 1279 | 22616 | $0.0014 |
| 3 | Tencent Hy3 | **87.0** | 0.0 | 7 | 18/18 | 10 | 50 | 10 | 10 | 1 | 422 | 4 | 979 | 18305 | $0.0098 |

## Per-model failure summary (first attempt)

**aion-labs/aion-3.0-mini** (score 97.0)
  - clean pass

**inclusionai/ling-3.0-flash** (score 88.3)
  - FAIL  attack fires when in range  --  attacks=0

**tencent/hy3** (score 87.0)
  - clean pass

