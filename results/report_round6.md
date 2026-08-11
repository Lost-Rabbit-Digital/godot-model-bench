# Godot Model Bench — round 6 results

- Engine: Godot 4.7.1.stable.official.a13da4feb
- Challenge: PROMPT6.md
- 16 checks; one repair round allowed; time 0..10 (faster = better); gdlint 0..10 (fewer issues = better)

| # | Model | Score | Time | Lint | Checks | Comp | Tests | 1-shot | Hyg | Att | Wall s | Lint # | In tok | Out tok | Est $ |
|---|-------|-------|------|------|--------|------|-------|--------|-----|-----|--------|--------|--------|---------|-------|
| 1 | Ling 3.0 Flash | **100.0** | 10.0 | 10 | 16/16 | 10 | 50 | 10 | 10 | 1 | 45 | 0 | 894 | 17562 | $0.0011 |
| 2 | Aion 3.0 Mini | **97.2** | 8.2 | 9 | 16/16 | 10 | 50 | 10 | 10 | 1 | 67 | 2 | 854 | 6117 | $0.0092 |
| 3 | Tencent Hy3 | **85.0** | 0.0 | 5 | 16/16 | 10 | 50 | 10 | 10 | 1 | 168 | 10 | 834 | 17051 | $0.0091 |
| 4 | Solar Pro 4 | **100.0** | 10.0 | 10 | 16/16 | 10 | 50 | 10 | 10 | 1 | 22 | 0 | 871 | 1191 | $0.0002 |
| 5 | Muse Glimmer 30B | **91.2** | 4.2 | 7 | 16/16 | 10 | 50 | 10 | 10 | 1 | 107 | 5 | 823 | 8345 | $0.0128 |

## Per-model failure summary (first attempt)

**inclusionai/ling-3.0-flash** (score 100.0)
  - clean pass

**aion-labs/aion-3.0-mini** (score 97.2)
  - clean pass

**tencent/hy3** (score 85.0)
  - clean pass

**upstage/solar-pro4** (score 100.0)
  - clean pass (16/16 attempt 1)

**meta/muse-glimmer-30b** (score 91.2)
  - clean pass (16/16 attempt 1)
