# Godot Model Bench — round 3 results

- Engine: Godot 4.7.1.stable.official.a13da4feb
- Challenge: PROMPT3.md
- 16 checks; one repair round allowed; time 0..10 (faster = better); gdlint 0..10 (fewer issues = better)

| # | Model | Score | Time | Lint | Checks | Comp | Tests | 1-shot | Hyg | Att | Wall s | Lint # | In tok | Out tok | Est $ |
|---|-------|-------|------|------|--------|------|-------|--------|-----|-----|--------|--------|--------|---------|-------|
| 1 | Muse Spark 1.2 | **98.6** | 8.6 | 10 | 16/16 | 10 | 50 | 10 | 10 | 1 | 21 | 0 | 1176 | 5317 | $0.0241 |
| 2 | Kat Coder Air v2.5 | **98.5** | 9.5 | 9 | 16/16 | 10 | 50 | 10 | 10 | 1 | 13 | 2 | 1247 | 1275 | $0.0010 |
| 3 | Gemini 3.6 Flash | **97.8** | 7.8 | 10 | 16/16 | 10 | 50 | 10 | 10 | 1 | 29 | 0 | 1290 | 6096 | $0.0477 |
| 4 | Ling 3.0 Flash | **96.4** | 6.4 | 10 | 16/16 | 10 | 50 | 10 | 10 | 1 | 41 | 0 | 1293 | 15461 | $0.0010 |
| 5 | Gemini 3.5 Flash Lite | **95.0** | 10.0 | 5 | 16/16 | 10 | 50 | 10 | 10 | 1 | 8 | 9 | 1292 | 949 | $0.0028 |
| 6 | Aion 3.0 Mini | **90.2** | 0.2 | 10 | 16/16 | 10 | 50 | 10 | 10 | 1 | 98 | 0 | 1250 | 3788 | $0.0062 |
| 7 | DeepSeek V4 Flash | **86.3** | 6.3 | 10 | 16/16 | 10 | 50 | 0 | 10 | 2 | 42 | 0 | 1474 | 1830 | $0.0004 |
| 8 | Qwen3.7 Flash | **77.0** | 0.0 | 7 | 16/16 | 10 | 50 | 0 | 10 | 2 | 100 | 4 | 1755 | 6260 | $0.0009 |
| 9 | Laguna S 2.1 | **76.8** | 5.8 | 10 | 13/16 | 10 | 41 | 0 | 10 | 2 | 47 | 0 | 1249 | 760 | $0.0002 |

## Per-model failure summary (first attempt)

**meta/muse-spark-1.2** (score 98.6)
  - clean pass

**kwaipilot/kat-coder-air-v2.5** (score 98.5)
  - clean pass

**google/gemini-3.6-flash** (score 97.8)
  - clean pass

**inclusionai/ling-3.0-flash** (score 96.4)
  - clean pass

**google/gemini-3.5-flash-lite** (score 95.0)
  - clean pass

**aion-labs/aion-3.0-mini** (score 90.2)
  - clean pass

**deepseek/deepseek-v4-flash-0731** (score 86.3)
  - FAIL  bouncy_ball extends RigidBody2D  --  got Node2D

**qwen/qwen3.7-flash** (score 77.0)
  - FAIL  balls spread horizontally from pegs (x-range > 120)  --  too few in-bounds samples=13
  - FAIL  loop recycled balls (signal fired)  --  recycled=0
  - FAIL  no balls stuck below LOOP_Y  --  stuck=200

**poolside/laguna-s-2.1** (score 76.8)
  - FAIL  balls spread horizontally from pegs (x-range > 120)  --  too few in-bounds samples=14
  - FAIL  loop recycled balls (signal fired)  --  recycled=0
  - FAIL  no balls stuck below LOOP_Y  --  stuck=200

