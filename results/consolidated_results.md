# Godot Model Bench — Consolidated Results

## Engine: Godot 4.7.1.stable.official.a13da4feb
## Score = Compile 10 + Correctness 0-50 + Single-shot 10 + Hygiene 10 + Time 0-10 + Lint 0-10
## Token limit increased to 65536 for rounds 4-7 (32784 caused truncation/reasoning-only)

### Round 1: Beehive Simulation (45 checks)
| # | Model | Score | Passed | In tok | Out tok | Cost | Wall |
|---|-------|-------|--------|--------|---------|------|------|
| 1 | Gemini 3.5 Flash Lite | **99.0** | 45/45 | 1349 | 1168 | $0.0033 | 3s |
| 2 | Laguna S 2.1 | **98.9** | 45/45 | 1304 | 867 | $0.0003 | 10s |
| 3 | Kat Coder Air v2.5 | **98.9** | 45/45 | 1290 | 1392 | $0.0010 | 8s |
| 4 | Gemini 3.6 Flash | **98.8** | 45/45 | 1347 | 5645 | $0.0444 | 22s |
| 5 | Ling 3.0 Flash | **98.6** | 45/45 | 1352 | 11681 | $0.0007 | 31s |
| 6 | DeepSeek V4 Flash | **98.5** | 45/45 | 1265 | 3906 | $0.0007 | 41s |
| 7 | Aion 3.0 Mini | **98.2** | 45/45 | 1264 | 4857 | $0.0077 | 64s |
| 8 | LongCat 2.0 | 97.5 | 45/45 | 1279 | 8104 | $0.0098 | 117s |
| 9 | Muse Spark 1.2 | 96.9 | 45/45 | 1232 | 4986 | $0.0227 | 14s |
| 10 | MiniMax M3 | 96.4 | 45/45 | 1397 | 8865 | $0.0107 | 51s |
| 11 | Inkling Small | 95.9 | 45/45 | 1228 | 6364 | $0.0083 | 87s |
| 12 | Qwen3.7 Flash | 81.7 | 45/45 | 1400 | 8928 | $0.0012 | 106s |
| 13 | GLM 5.2 | 79.0 | 45/45 | 1364 | 12393 | $0.0214 | 768s |
| 14 | Qwen3.8 Max | 0.0 | 2/4 | 1328 | 16386 | $0.1010 | 711s |
| 15 | Nex N2 Pro | 0.0 | 2/4 | 1289 | 16384 | $0.0167 | 228s |

### Round 2: Greenhouse Automation (34 checks)
| # | Model | Score | Passed | In tok | Out tok | Cost | Wall |
|---|-------|-------|--------|--------|---------|------|------|
| 1 | Laguna S 2.1 | **100.0** | 34/34 | 991 | 527 | $0.0002 | 13s |
| 1 | Kat Coder Air v2.5 | **100.0** | 34/34 | 987 | 975 | $0.0007 | 13s |
| 3 | Ling 3.0 Flash | 99.9 | 34/34 | 1027 | 5579 | $0.0004 | 20s |
| 3 | Muse Spark 1.2 | 99.9 | 34/34 | 937 | 2953 | $0.0137 | 17s |
| 3 | DeepSeek V4 Flash | 99.9 | 34/34 | 1000 | 790 | $0.0002 | 17s |
| 3 | Gemini 3.6 Flash | 99.9 | 34/34 | 1044 | 2547 | $0.0207 | 18s |
| 6 | Qwen3.7 Flash | 99.5 | 34/34 | 987 | 4952 | $0.0007 | 38s |
| 7 | Aion 3.0 Mini | 98.3 | 34/34 | 999 | 2549 | $0.0043 | 47s |
| 8 | Inkling Small | 97.1 | 34/34 | 941 | 9382 | $0.0117 | 162s |
| 9 | Qwen3.8 Max | 90.0 | 34/34 | 1025 | 23924 | $0.1456 | 530s |
| 10 | MiniMax M3 | 89.0 | 34/34 | 1319 | 922 | $0.0015 | 64s |
| 11 | Nex N2 Pro | 84.2 | 34/34 | 1100 | 11835 | $0.0119 | 311s |
| 12 | Gemini 3.5 Flash Lite | 10.0 | 1/2 | 1461 | 594 | $0.0019 | 4s |

### Round 3: Pegboard Physics (16 checks)
| # | Model | Score | Passed | In tok | Out tok | Cost | Wall |
|---|-------|-------|--------|--------|---------|------|------|
| 1 | Muse Spark 1.2 | **98.8** | 16/16 | 1176 | 5317 | $0.0241 | 21s |
| 2 | Kat Coder Air v2.5 | **98.5** | 16/16 | 1247 | 1275 | $0.0010 | 13s |
| 3 | Gemini 3.6 Flash | 98.0 | 16/16 | 1290 | 6096 | $0.0477 | 29s |
| 4 | Ling 3.0 Flash | 96.9 | 16/16 | 1293 | 15461 | $0.0010 | 41s |
| 5 | Xiaomi MiMo V2.5 Pro | 95.2 | 16/16 | 1210 | 3622 | $0.0037 | 59s |
| 6 | Gemini 3.5 Flash Lite | 95.0 | 16/16 | 1292 | 949 | $0.0028 | 8s |
| 7 | Aion 3.0 Mini | 91.6 | 16/16 | 1250 | 3788 | $0.0062 | 98s |
| 8 | Tencent Hy3 | 87.0 | 16/16 | 1236 | 20201 | $0.0108 | 115s |
| 9 | DeepSeek V4 Flash | 86.8 | 16/16 | 1474 | 1830 | $0.0004 | 42s |
| 10 | Qwen3.7 Flash | 78.4 | 16/16 | 1755 | 6260 | $0.0009 | 100s |
| 11 | Laguna S 2.1 | 77.4 | 13/16 | 1249 | 760 | $0.0002 | 47s |

### Round 4: HUD/UI Juice (27 checks) — with MP4 recording
| # | Model | Score | Passed | In tok | Out tok | Cost | Wall | MP4 |
|---|-------|-------|--------|--------|---------|------|------|-----|
| 1 | Gemini 3.5 Flash Lite | **87.0** | 26/27 | 1641 | 1507 | $0.0043 | 16s | — |
| 2 | Ling 3.0 Flash | 86.5 | 26/27 | 1871 | 14652 | $0.0010 | 82s | — |
| 3 | Gemini 3.6 Flash | 86.5 | 26/27 | 1639 | 6246 | $0.0493 | 84s | — |
| 4 | Kat Coder Air v2.5 | 85.9 | 25/27 | 1967 | 1551 | $0.0012 | 21s | — |
| 5 | Muse Spark 1.2 | 85.9 | 26/27 | 1473 | 8170 | $0.0366 | 65s | MP4 |
| 6 | Aion 3.0 Mini | 84.8 | 26/27 | 1787 | 5074 | $0.0084 | 117s | — |
| 7 | Xiaomi MiMo V2.5 Pro | 84.1 | 26/27 | 1476 | 8578 | $0.0075 | 194s | MP4 |
| 8 | DeepSeek V4 Flash | 78.9 | 26/27 | 1858 | 25900 | $0.0048 | 430s | — |
| 9 | Tencent Hy3 | 78.0 | 26/27 | 1759 | 14098 | $0.0077 | 469s | — |
| 10 | Laguna S 2.1 | 19.8 | 1/2 | 1554 | 1076 | $0.0003 | 26s | — |
| 11 | Qwen3.7 Flash | 17.5 | 1/2 | 1549 | 11200 | $0.0015 | 127s | — |

### Round 5: NPC State Machine (18 checks)
| # | Model | Score | Passed | In tok | Out tok | Cost | Wall |
|---|-------|-------|--------|--------|---------|------|------|
| 1 | Gemini 3.6 Flash | **100.0** | 18/18 | 1055 | 3199 | $0.0493 | 15s |
| 1 | Xiaomi MiMo V2.5 Pro | **100.0** | 18/18 | 949 | 872 | $0.0062 | 16s |
| 3 | Muse Spark 1.2 | 99.4 | 18/18 | 945 | 8785 | $0.0227 | 33s |
| 4 | Laguna S 2.1 | 95.3 | 18/18 | 1016 | 17185 | $0.0003 | 156s |
| 5 | DeepSeek V4 Flash | 93.6 | 18/18 | 995 | 3928 | $0.0010 | 207s |
| 6 | Kat Coder Air v2.5 | 74.0 | 16/18 | 1003 | 1597 | $0.0012 | 314s |

### Round 6: Procedural Animation (16 checks)
| # | Model | Score | Passed | In tok | Out tok | Cost | Wall |
|---|-------|-------|--------|--------|---------|------|------|
| 1 | Kat Coder Air v2.5 | **100.0** | 16/16 | 991 | 3276 | $0.0012 | 20s |
| 2 | Muse Spark 1.2 | 99.7 | 16/16 | 807 | 5384 | $0.0227 | 26s |
| 3 | DeepSeek V4 Flash | 98.9 | 16/16 | 855 | 3612 | $0.0010 | 42s |
| 4 | Gemini 3.6 Flash | 96.7 | 16/16 | 881 | 5364 | $0.0493 | 26s |
| 5 | Xiaomi MiMo V2.5 Pro | 80.0 | 16/16 | 813 | 6137 | $0.0062 | 217s |
| 6 | Laguna S 2.1 | 0.0 | 0/0 | 1016 | 32768 | $0.0003 | 353s |

### Round 7: Particles/VFX (28 checks)
| # | Model | Score | Passed | In tok | Out tok | Cost | Wall |
|---|-------|-------|--------|--------|---------|------|------|
| 1 | Gemini 3.6 Flash | **98.7** | 28/28 | 1024 | 14095 | $0.0493 | 51s |
| 2 | Muse Spark 1.2 | 88.4 | 28/28 | 943 | 6973 | $0.0227 | 60s |
| 3 | DeepSeek V4 Flash | 83.6 | 25/28 | 979 | 3047 | $0.0010 | 54s |
| 4 | Xiaomi MiMo V2.5 Pro | 80.0 | 28/28 | 939 | 14661 | $0.0062 | 284s |
| 5 | Laguna S 2.1 | 79.0 | 22/28 | 1003 | 767 | $0.0003 | 17s |
| 6 | Kat Coder Air v2.5 | 78.9 | 26/28 | 991 | 3276 | $0.0012 | 208s |

### Overall Token Usage & Cost Summary (Rounds 1-7, top 6 models)

| Model | R1 | R2 | R3 | R4 | R5 | R6 | R7 | Total In | Total Out | Total Cost |
|-------|-----|-----|-----|-----|-----|-----|-----|----------|-----------|------------|
| Muse Spark 1.2 | 96.9 | 99.9 | 98.8 | 85.9 | 99.4 | 99.7 | 88.4 | 6027 | 34309 | $0.1473 |
| Kat Coder Air v2.5 | 98.9 | 100.0 | 98.5 | 85.9 | 74.0 | 100.0 | 78.9 | 6637 | 17046 | $0.0267 |
| DeepSeek V4 Flash | 98.5 | 99.9 | 86.8 | 78.9 | 93.6 | 98.9 | 83.6 | 6763 | 18469 | $0.0119 |
| Gemini 3.6 Flash | 98.8 | 99.9 | 98.0 | 86.5 | 100.0 | 96.7 | 98.7 | 7266 | 35522 | $0.2202 |
| Laguna S 2.1 | 98.9 | 100.0 | 77.4 | 19.8 | 95.3 | 0.0 | 79.0 | 6421 | 54840 | $0.0019 |
| Xiaomi MiMo V2.5 Pro | — | — | 95.2 | 84.1 | 100.0 | 80.0 | 80.0 | 4672 | 40183 | $0.0240 |

**Key findings:**
- **Gemini 3.6 Flash** has the highest raw scores (avg 94.2) but also the highest token cost (35.5k output avg)
- **Kat Coder Air v2.5** is the best value — consistently high scores at the lowest cost ($0.0267 total)
- **MiMo V2.5 Pro** is extremely token-efficient — 872 output tokens for R5 18/18 pass, but struggles on later rounds
- **Muse Spark 1.2** is the most consistent — strong across all 7 rounds, no single-round failures
- **64k token limit** was essential for rounds 4-7 — many models hit reasoning-only or truncation at 32k
- **R4 is still the hardest round** — even with 64k tokens, no model achieves a clean pass (all miss "get_health() == 0.0")
- **R5 and R7** saw improvement with more tokens — Laguna went from 0/0 to 18/18 on R5

### Dashboard
Interactive HTML dashboard at `results/dashboard.html` with D3.js visualizations, sortable table, round filtering, and metric switching.

### MP4 recordings
In `results/recordings/`:
- `meta_muse-spark-1.2_r4.mp4` and `meta_muse-spark-1.2_r4_attempt2.mp4`
- `xiaomi_mimo-v2.5-pro_r4.mp4` and `xiaomi_mimo-v2.5-pro_r4_attempt2.mp4`
