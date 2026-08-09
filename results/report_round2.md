# Godot Model Bench — round 2 results

- Engine: Godot 4.7.1.stable.official.a13da4feb
- Challenge: PROMPT2.md
- 34 checks; one repair round allowed; time 0..10 (faster = better); gdlint 0..10 (fewer issues = better)

| # | Model | Score | Time | Lint | Checks | Comp | Tests | 1-shot | Hyg | Att | Wall s | Lint # | In tok | Out tok | Est $ |
|---|-------|-------|------|------|--------|------|-------|--------|-----|-----|--------|--------|--------|---------|-------|
| 1 | Laguna S 2.1 | **100.0** | 10.0 | 10 | 34/34 | 10 | 50 | 10 | 10 | 1 | 13 | 0 | 991 | 527 | $0.0002 |
| 2 | Kat Coder Air v2.5 | **100.0** | 10.0 | 10 | 34/34 | 10 | 50 | 10 | 10 | 1 | 13 | 0 | 987 | 975 | $0.0007 |
| 3 | Ling 3.0 Flash | **99.9** | 9.9 | 10 | 34/34 | 10 | 50 | 10 | 10 | 1 | 20 | 0 | 1027 | 5579 | $0.0004 |
| 4 | Muse Spark 1.2 | **99.9** | 9.9 | 10 | 34/34 | 10 | 50 | 10 | 10 | 1 | 17 | 0 | 937 | 2953 | $0.0137 |
| 5 | DeepSeek V4 Flash | **99.9** | 9.9 | 10 | 34/34 | 10 | 50 | 10 | 10 | 1 | 17 | 0 | 1000 | 790 | $0.0002 |
| 6 | Gemini 3.6 Flash | **99.9** | 9.9 | 10 | 34/34 | 10 | 50 | 10 | 10 | 1 | 18 | 0 | 1044 | 2547 | $0.0207 |
| 7 | Qwen3.7 Flash | **99.5** | 9.5 | 10 | 34/34 | 10 | 50 | 10 | 10 | 1 | 38 | 0 | 987 | 4952 | $0.0007 |
| 8 | Aion 3.0 Mini | **98.3** | 9.3 | 9 | 34/34 | 10 | 50 | 10 | 10 | 1 | 47 | 1 | 999 | 2549 | $0.0043 |
| 9 | Inkling Small | **97.1** | 7.1 | 10 | 34/34 | 10 | 50 | 10 | 10 | 1 | 162 | 0 | 941 | 9382 | $0.0117 |
| 10 | Qwen3.8 Max | **90.0** | 0.0 | 10 | 34/34 | 10 | 50 | 10 | 10 | 1 | 530 | 0 | 1025 | 23924 | $0.1456 |
| 11 | MiniMax M3 | **89.0** | 9.0 | 10 | 34/34 | 10 | 50 | 0 | 10 | 2 | 64 | 0 | 1319 | 922 | $0.0015 |
| 12 | Nex N2 Pro | **84.2** | 4.2 | 10 | 34/34 | 10 | 50 | 0 | 10 | 2 | 311 | 0 | 1100 | 11835 | $0.0119 |
| 13 | Gemini 3.5 Flash Lite | **10.0** | 0.0 | 0 | 1/2 | 0 | 0 | 0 | 10 | 2 | 4 | 2 | 1461 | 594 | $0.0019 |

## Per-model failure summary (first attempt)

**poolside/laguna-s-2.1** (score 100.0)
  - clean pass

**kwaipilot/kat-coder-air-v2.5** (score 100.0)
  - clean pass

**inclusionai/ling-3.0-flash** (score 99.9)
  - clean pass

**meta/muse-spark-1.2** (score 99.9)
  - clean pass

**deepseek/deepseek-v4-flash-0731** (score 99.9)
  - clean pass

**google/gemini-3.6-flash** (score 99.9)
  - clean pass

**qwen/qwen3.7-flash** (score 99.5)
  - clean pass

**aion-labs/aion-3.0-mini** (score 98.3)
  - clean pass

**thinkingmachines/inkling-small** (score 97.1)
  - clean pass

**qwen/qwen3.8-max** (score 90.0)
  - clean pass

**minimax/minimax-m3** (score 89.0)
  - FAIL  greenhouse extends Node2D  --  got Node

**nex-agi/nex-n2-pro** (score 84.2)
  - FAIL  greenhouse extends Node2D  --  got RefCounted
  - FAIL  thermostat extends Node  --  got RefCounted

**google/gemini-3.5-flash-lite** (score 10.0)
  - FAIL  greenhouse.gd loads/parses  --  load() returned null or unparseable script
  - FAIL  thermostat.gd loads/parses  --  load() returned null or unparseable script

## Roster note (2026-08)

Dropped after this round per user decision — response times make them unsuitable for interactive/agentic use:

- **qwen/qwen3.8-max** — 531s wall, $0.146, ~24,000 output tokens for ~90 lines of code (0.0 time points)
- **nex-agi/nex-n2-pro** — 311s wall; also burned the entire 32k output budget on reasoning with zero content on first attempt (both rounds)
