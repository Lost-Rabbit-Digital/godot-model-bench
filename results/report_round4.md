# Godot Model Bench — round 4 results

- Engine: Godot 4.7.1.stable.official.a13da4feb
- Challenge: PROMPT4.md
- 27 checks; one repair round allowed; time 0..10 (faster = better); gdlint 0..10 (fewer issues = better)

| # | Model | Score | Time | Lint | Checks | Comp | Tests | 1-shot | Hyg | Att | Wall s | Lint # | In tok | Out tok | Est $ |
|---|-------|-------|------|------|--------|------|-------|--------|-----|-----|--------|--------|--------|---------|-------|
| 1 | Gemini 3.5 Flash Lite | **87.0** | 10.0 | 9 | 26/27 | 10 | 48 | 0 | 10 | 2 | 16 | 2 | 1641 | 1507 | $0.0043 |
| 2 | Ling 3.0 Flash | **86.5** | 8.5 | 10 | 26/27 | 10 | 48 | 0 | 10 | 2 | 82 | 0 | 1871 | 14652 | $0.0010 |
| 3 | Gemini 3.6 Flash | **86.5** | 8.5 | 10 | 26/27 | 10 | 48 | 0 | 10 | 2 | 84 | 0 | 1639 | 6246 | $0.0493 |
| 4 | Kat Coder Air v2.5 | **85.9** | 9.9 | 10 | 25/27 | 10 | 46 | 0 | 10 | 2 | 21 | 0 | 1967 | 1551 | $0.0012 |
| 5 | Aion 3.0 Mini | **84.8** | 7.8 | 9 | 26/27 | 10 | 48 | 0 | 10 | 2 | 117 | 1 | 1787 | 5074 | $0.0084 |
| 6 | DeepSeek V4 Flash | **78.8** | 0.8 | 10 | 26/27 | 10 | 48 | 0 | 10 | 2 | 430 | 0 | 1858 | 25900 | $0.0048 |
| 7 | Tencent Hy3 | **78.0** | 0.0 | 10 | 26/27 | 10 | 48 | 0 | 10 | 2 | 469 | 0 | 1759 | 14098 | $0.0077 |
| 8 | Qwen3.7 Flash | **10.0** | 0.0 | 0 | 1/2 | 0 | 0 | 0 | 10 | 2 | 127 | 0 | 1549 | 11200 | $0.0015 |
| 9 | Laguna S 2.1 | **10.0** | 0.0 | 0 | 1/2 | 0 | 0 | 0 | 10 | 2 | 26 | 0 | 1554 | 1076 | $0.0003 |
| 10 | Muse Glimmer 30B | **10.0** | 0.0 | 0 | 1/2 | 0 | 0 | 0 | 10 | 2 | 288 | 0 | 1489 | 6836 | $0.0108 |
| 11 | Solar Pro 4 | **10.0** | 0.0 | 0 | 1/2 | 0 | 0 | 0 | 10 | 2 | 29 | 0 | 1548 | 1020 | $0.0002 |
| 12 | Nemotron 3.5 Lightning (free) | **10.0** | 0.0 | 0 | 1/2 | 0 | 0 | 0 | 10 | 2 | 200 | 1 | 1541 | 27012 | $0.0000 |
| 13 | Sakana Namazu | **0.0** | 0.0 | 0 | 2/4 | 0 | 0 | 0 | 0 | 2 | 0 | -1 | 0 | 0 | $0.0000 |

| 14 | Nemotron 3.5 Lightning | **10.0** | 0.0 | 0 | 1/2 | 0 | 0 | 0 | 10 | 2 | 639 | 1 | 1951 | 41700 | $0.0106 |
| 15 | LFM 2.5 2.6B (free) | **0.0** | 0.0 | 0 | 2/4 | 0 | 0 | 0 | 0 | 2 | 602 | -1 | 1402 | 2314 | $0.0000 |
## Per-model failure summary (first attempt)

**google/gemini-3.5-flash-lite** (score 87.0)
  - FAIL  get_health() == 0.0  --  got 100.0

**inclusionai/ling-3.0-flash** (score 86.5)
  - FAIL  juice_hud.gd loads/parses  --  load() returned null or unparseable script

**google/gemini-3.6-flash** (score 86.5)
  - FAIL  get_health() == 0.0  --  got 100.0

**kwaipilot/kat-coder-air-v2.5** (score 85.9)
  - FAIL  juice_hud.gd loads/parses  --  load() returned null or unparseable script
  - FAIL  hud_sparkle.gd loads/parses  --  load() returned null or unparseable script

**aion-labs/aion-3.0-mini** (score 84.8)
  - FAIL  juice_hud.gd loads/parses  --  load() returned null or unparseable script

**deepseek/deepseek-v4-flash-0731** (score 78.8)
  - FAIL  juice_hud.gd loads/parses  --  load() returned null or unparseable script

**tencent/hy3** (score 78.0)
  - FAIL  juice_hud.gd loads/parses  --  load() returned null or unparseable script

**qwen/qwen3.7-flash** (score 10.0)
  - FAIL  juice_hud.gd loads/parses  --  load() returned null or unparseable script

**poolside/laguna-s-2.1** (score 10.0)
  - FAIL  juice_hud.gd loads/parses  --  load() returned null or unparseable script

**meta/muse-glimmer-30b** (score 10.0)
  - battery never ran (1/2 gate) both attempts

**upstage/solar-pro4** (score 10.0)
  - battery never ran (1/2 gate) both attempts
**nvidia/nemotron-3.5-lightning:free** (score 10.0)
  - battery never ran (1/2 gate) both attempts

**sakana/sakana-namazu** (score 0.0)
  - API blocked: OpenRouter 404 guardrail/data-policy restriction

**nvidia/nemotron-3.5-lightning** (score 10.0)
  - FAIL  juice_hud.gd loads/parses  --  load() returned null or unparseable script  [spec]
  - FAIL  hud_sparkle.gd loads/parses  --  load() returned null or unparseable script  [spec]
  - **Failure categories**:
    - Missing API: 2

**liquid/lfm-2.5-2.6b:free** (score 0.0)
  - FAIL  juice_hud extends Control  --  got RefCounted  [logic]
  - FAIL  hud_sparkle extends Node2D  --  got RefCounted  [logic]
  - **Failure categories**:
    - Logic/Spec: 2

