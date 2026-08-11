# Godot Model Bench — round 3 results (merged 11-model field, 2026-08-06)

- Engine: Godot 4.7.1.stable.official.a13da4feb
- Challenge: PROMPT3.md
- 16 checks; one repair round allowed; time 0..10 (faster = better); gdlint 0..10 (fewer issues = better)
- Hy3 + MiMo V2.5 Pro added to active roster; time points recomputed across all 11

| # | Model | Score | Time | Lint | Checks | Comp | Tests | 1-shot | Hyg | Att | Wall s | Lint # | In tok | Out tok | Est $ |
|---|-------|-------|------|------|--------|------|-------|--------|-----|-----|--------|--------|--------|---------|-------|
| 1 | Muse Spark 1.2 | **98.8** | 8.8 | 10 | 16/16 | 10 | 50 | 10 | 10 | 1 | 21 | 0 | 1176 | 5317 | $0.0241 |
| 2 | Kat Coder Air v2.5 | **98.5** | 9.5 | 9 | 16/16 | 10 | 50 | 10 | 10 | 1 | 13 | 2 | 1247 | 1275 | $0.0010 |
| 3 | Gemini 3.6 Flash | **98.0** | 8.0 | 10 | 16/16 | 10 | 50 | 10 | 10 | 1 | 29 | 0 | 1290 | 6096 | $0.0477 |
| 4 | Ling 3.0 Flash | **96.9** | 6.9 | 10 | 16/16 | 10 | 50 | 10 | 10 | 1 | 41 | 0 | 1293 | 15461 | $0.0010 |
| 5 | Xiaomi MiMo V2.5 Pro | **95.2** | 5.2 | 10 | 16/16 | 10 | 50 | 10 | 10 | 1 | 59 | 0 | 1210 | 3622 | $0.0037 |
| 6 | Gemini 3.5 Flash Lite | **95.0** | 10.0 | 5 | 16/16 | 10 | 50 | 10 | 10 | 1 | 8 | 9 | 1292 | 949 | $0.0028 |
| 7 | Aion 3.0 Mini | **91.6** | 1.6 | 10 | 16/16 | 10 | 50 | 10 | 10 | 1 | 98 | 0 | 1250 | 3788 | $0.0062 |
| 8 | Tencent Hy3 | **87.0** | 0.0 | 7 | 16/16 | 10 | 50 | 10 | 10 | 1 | 115 | 5 | 1236 | 20201 | $0.0108 |
| 9 | DeepSeek V4 Flash | **86.8** | 6.8 | 10 | 16/16 | 10 | 50 | 0 | 10 | 2 | 42 | 0 | 1474 | 1830 | $0.0004 |
| 10 | Qwen3.7 Flash | **78.4** | 1.4 | 7 | 16/16 | 10 | 50 | 0 | 10 | 2 | 100 | 4 | 1755 | 6260 | $0.0009 |
| 11 | Laguna S 2.1 | **77.4** | 6.4 | 10 | 13/16 | 10 | 41 | 0 | 10 | 2 | 47 | 0 | 1249 | 760 | $0.0002 |
| 12 | Muse Glimmer 30B | **80.0** | 0.0 | 10 | 16/16 | 10 | 50 | 0 | 10 | 2 | 281 | 0 | 1426 | 12499 | $0.0189 |
| 13 | Solar Pro 4 | **10.0** | 0.0 | 0 | 3/4 | 0 | 0 | 0 | 10 | 2 | 20 | 9 | 1272 | 768 | $0.0001 |
| 14 | Nemotron 3.5 Lightning (free) | **99.0** | 10.0 | 9 | 16/16 | 10 | 50 | 10 | 10 | 1 | 28 | 2 | 1293 | 7803 | $0.0000 |
| 15 | Sakana Namazu | **0.0** | 0.0 | 0 | 2/4 | 0 | 0 | 0 | 0 | 2 | 0 | -1 | 0 | 0 | $0.0000 |

| 16 | Nemotron 3.5 Lightning | **72.0** | 0.0 | 10 | 10/12 | 10 | 42 | 0 | 10 | 2 | 180 | 0 | 1701 | 7350 | $0.0020 |
| 17 | LFM 2.5 2.6B (free) | **0.0** | 0.0 | 0 | 2/4 | 0 | 0 | 0 | 0 | 2 | 593 | -1 | 1145 | 2292 | $0.0000 |
## Per-model failure summary (first attempt)

**meta/muse-spark-1.2** (score 98.8)
  - clean pass

**kwaipilot/kat-coder-air-v2.5** (score 98.5)
  - clean pass

**google/gemini-3.6-flash** (score 98.0)
  - clean pass

**inclusionai/ling-3.0-flash** (score 96.9)
  - clean pass

**xiaomi/mimo-v2.5-pro** (score 95.2)
  - clean pass

**google/gemini-3.5-flash-lite** (score 95.0)
  - clean pass

**aion-labs/aion-3.0-mini** (score 91.6)
  - clean pass

**tencent/hy3** (score 87.0)
  - clean pass

**deepseek/deepseek-v4-flash-0731** (score 86.8)
  - FAIL  bouncy_ball extends RigidBody2D  --  got Node2D

**qwen/qwen3.7-flash** (score 78.4)
  - FAIL  balls spread horizontally from pegs (x-range > 120)  --  too few in-bounds samples=13
  - FAIL  loop recycled balls (signal fired)  --  recycled=0
  - FAIL  no balls stuck below LOOP_Y  --  stuck=200

**poolside/laguna-s-2.1** (score 77.4)
  - FAIL  balls spread horizontally from pegs (x-range > 120)  --  too few in-bounds samples=14
  - FAIL  loop recycled balls (signal fired)  --  recycled=0
  - FAIL  no balls stuck below LOOP_Y  --  stuck=200**meta/muse-glimmer-30b** (score 80.0)
  - repair round needed (attempt 1 incomplete battery)
  - clean pass on attempt 2 (16/16)

**upstage/solar-pro4** (score 10.0)
  - repair round: battery still incomplete (3/4 checks attempt 1, gate not met)
**nvidia/nemotron-3.5-lightning:free** (score 99.0)
  - clean pass (16/16 attempt 1)

**sakana/sakana-namazu** (score 0.0)
  - API blocked: OpenRouter 404 "No endpoints available matching your guardrail restrictions and data policy"

**nvidia/nemotron-3.5-lightning** (score 72.0)
  - FAIL  pegboard.gd loads/parses  --  load failed or unparseable  [spec]
  - FAIL  bouncy_ball.gd loads/parses  --  load failed or unparseable  [spec]
  - **Failure categories**:
    - Missing API: 2

**liquid/lfm-2.5-2.6b:free** (score 0.0)
  - FAIL  pegboard extends Node2D  --  got RefCounted  [logic]
  - FAIL  bouncy_ball extends RigidBody2D  --  got RefCounted  [logic]
  - **Failure categories**:
    - Logic/Spec: 2

