# Godot Model Bench — round 1 results

- Engine: Godot 4.7.1.stable.official.a13da4feb
- Challenge: PROMPT.md
- 45 checks; one repair round allowed; time 0..10 (faster = better); gdlint 0..10 (fewer issues = better)

| # | Model | Score | Time | Lint | Checks | Comp | Tests | 1-shot | Hyg | Att | Wall s | Lint # | In tok | Out tok | Est $ |
|---|-------|-------|------|------|--------|------|-------|--------|-----|-----|--------|--------|--------|---------|-------|
| 1 | Gemini 3.5 Flash Lite | **99.0** | 10.0 | 9 | 45/45 | 10 | 50 | 10 | 10 | 1 | 3 | 2 | 1349 | 1168 | $0.0033 |
| 2 | Laguna S 2.1 | **98.9** | 9.9 | 9 | 45/45 | 10 | 50 | 10 | 10 | 1 | 10 | 2 | 1304 | 867 | $0.0003 |
| 3 | Kat Coder Air v2.5 | **98.9** | 9.9 | 9 | 45/45 | 10 | 50 | 10 | 10 | 1 | 8 | 2 | 1290 | 1392 | $0.0010 |
| 4 | Gemini 3.6 Flash | **98.8** | 9.8 | 9 | 45/45 | 10 | 50 | 10 | 10 | 1 | 22 | 1 | 1347 | 5645 | $0.0444 |
| 5 | Ling 3.0 Flash | **98.6** | 9.6 | 9 | 45/45 | 10 | 50 | 10 | 10 | 1 | 31 | 1 | 1352 | 11681 | $0.0007 |
| 6 | DeepSeek V4 Flash | **98.5** | 9.5 | 9 | 45/45 | 10 | 50 | 10 | 10 | 1 | 41 | 2 | 1265 | 3906 | $0.0007 |
| 7 | Aion 3.0 Mini | **98.2** | 9.2 | 9 | 45/45 | 10 | 50 | 10 | 10 | 1 | 64 | 2 | 1264 | 4857 | $0.0077 |
| 8 | LongCat 2.0 | **97.5** | 8.5 | 9 | 45/45 | 10 | 50 | 10 | 10 | 1 | 117 | 2 | 1279 | 8104 | $0.0098 |
| 9 | Muse Spark 1.2 | **96.9** | 9.9 | 7 | 45/45 | 10 | 50 | 10 | 10 | 1 | 14 | 4 | 1232 | 4986 | $0.0227 |
| 10 | MiniMax M3 | **96.4** | 9.4 | 7 | 45/45 | 10 | 50 | 10 | 10 | 1 | 51 | 4 | 1397 | 8865 | $0.0107 |
| 11 | Inkling Small | **95.9** | 8.9 | 7 | 45/45 | 10 | 50 | 10 | 10 | 1 | 87 | 3 | 1228 | 6364 | $0.0083 |
| 12 | Qwen3.7 Flash | **81.7** | 8.7 | 3 | 45/45 | 10 | 50 | 0 | 10 | 2 | 106 | 13 | 1400 | 8928 | $0.0012 |
| 13 | GLM 5.2 | **79.0** | 0.0 | 9 | 45/45 | 10 | 50 | 0 | 10 | 2 | 768 | 1 | 1364 | 12393 | $0.0214 |
| 14 | Qwen3.8 Max | **0.0** | 0.0 | 0 | 2/4 | 0 | 0 | 0 | 0 | 2 | 711 | -1 | 1328 | 16386 | $0.1010 |
| 15 | Nex N2 Pro | **0.0** | 0.0 | 0 | 2/4 | 0 | 0 | 0 | 0 | 2 | 228 | -1 | 1289 | 16384 | $0.0167 |

## Per-model failure summary (first attempt)

**google/gemini-3.5-flash-lite** (score 99.0)
  - clean pass

**poolside/laguna-s-2.1** (score 98.9)
  - clean pass

**kwaipilot/kat-coder-air-v2.5** (score 98.9)
  - clean pass

**google/gemini-3.6-flash** (score 98.8)
  - clean pass

**inclusionai/ling-3.0-flash** (score 98.6)
  - clean pass

**deepseek/deepseek-v4-flash-0731** (score 98.5)
  - clean pass

**aion-labs/aion-3.0-mini** (score 98.2)
  - clean pass

**meituan/longcat-2.0** (score 97.5)
  - clean pass

**meta/muse-spark-1.2** (score 96.9)
  - clean pass

**minimax/minimax-m3** (score 96.4)
  - clean pass

**thinkingmachines/inkling-small** (score 95.9)
  - clean pass

**qwen/qwen3.7-flash** (score 81.7)
  - FAIL  short_label(1500) == '1.50 kg'  --  got {:.2f} kg

**z-ai/glm-5.2** (score 79.0)
  - FAIL  beehive.gd exposes required API  --  missing: ["tick", "harvest", "buy_upgrade", "daily_production", "season_factor"]
  - FAIL  honey_math.gd exposes required API  --  missing: ["bottles_for", "jar_price", "short_label"]

**qwen/qwen3.8-max** (score 0.0) — output truncated (max_tokens)
  - FAIL  beehive.gd exposes required API  --  missing: ["tick", "harvest", "buy_upgrade", "daily_production", "season_factor"]
  - FAIL  honey_math.gd exposes required API  --  missing: ["bottles_for", "jar_price", "short_label"]

**nex-agi/nex-n2-pro** (score 0.0) — output truncated (max_tokens)
  - FAIL  beehive.gd exposes required API  --  missing: ["tick", "harvest", "buy_upgrade", "daily_production", "season_factor"]
  - FAIL  honey_math.gd exposes required API  --  missing: ["bottles_for", "jar_price", "short_label"]

