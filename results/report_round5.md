# Godot Model Bench — round 5 results

- Engine: Godot 4.7.1.stable.official.a13da4feb
- Challenge: PROMPT5.md
- 18 checks; one repair round allowed; time 0..10 (faster = better); gdlint 0..10 (fewer issues = better)

| # | Model | Score | Time | Lint | Checks | Comp | Tests | 1-shot | Hyg | Att | Wall s | Lint # | In tok | Out tok | Est $ |
|---|-------|-------|------|------|--------|------|-------|--------|-----|-----|--------|--------|--------|---------|-------|
| 1 | Aion 3.0 Mini | **97.0** | 10.0 | 7 | 18/18 | 10 | 50 | 10 | 10 | 1 | 57 | 3 | 994 | 4470 | $0.0070 |
| 2 | Ling 3.0 Flash | **88.3** | 8.3 | 10 | 18/18 | 10 | 50 | 0 | 10 | 2 | 119 | 0 | 1279 | 22616 | $0.0014 |
| 3 | Tencent Hy3 | **87.0** | 0.0 | 7 | 18/18 | 10 | 50 | 10 | 10 | 1 | 422 | 4 | 979 | 18305 | $0.0098 |
| 4 | Solar Pro 4 | **100.0** | 10.0 | 10 | 18/18 | 10 | 50 | 10 | 10 | 1 | 15 | 0 | 1013 | 786 | $0.0001 |
| 5 | Muse Glimmer 30B | **96.3** | 6.3 | 10 | 18/18 | 10 | 50 | 10 | 10 | 1 | 164 | 0 | 961 | 12825 | $0.0196 |
| 6 | Nemotron 3.5 Lightning (free) | **85.2** | 8.2 | 10 | 17/18 | 10 | 47 | 0 | 10 | 2 | 90 | 0 | 1019 | 9410 | $0.0000 |
| 7 | Sakana Namazu | **0.0** | 0.0 | 0 | 1/2 | 0 | 0 | 0 | 0 | 2 | 0 | -1 | 0 | 0 | $0.0000 |

| 8 | Nemotron 3.5 Lightning | **72.6** | 3.6 | 7 | 15/18 | 10 | 42 | 0 | 10 | 2 | 276 | 5 | 1394 | 19838 | $0.0051 |
| 9 | LFM 2.5 2.6B (free) | **0.0** | 0.0 | 0 | 1/2 | 0 | 0 | 0 | 0 | 2 | 602 | -1 | 1011 | 2620 | $0.0000 |
## Per-model failure summary (first attempt)

**aion-labs/aion-3.0-mini** (score 97.0)
  - clean pass

**inclusionai/ling-3.0-flash** (score 88.3)
  - FAIL  attack fires when in range  --  attacks=0

**tencent/hy3** (score 87.0)
  - clean pass

**upstage/solar-pro4** (score 100.0)
  - clean pass (18/18 attempt 1)

**meta/muse-glimmer-30b** (score 96.3)
  - clean pass (18/18 attempt 1)
**nvidia/nemotron-3.5-lightning:free** (score 85.2)
  - 17/18 attempt 1 (1 check short)

**sakana/sakana-namazu** (score 0.0)
  - API blocked: OpenRouter 404 guardrail/data-policy restriction

**nvidia/nemotron-3.5-lightning** (score 72.6)
  - FAIL  npc_controller.gd loads/parses  --  load() returned null or unparseable script  [spec]
  - **Failure categories**:
    - Missing API: 1

**liquid/lfm-2.5-2.6b:free** (score 0.0)
  - FAIL  npc_controller extends CharacterBody2D  --  got RefCounted  [logic]
  - **Failure categories**:
    - Logic/Spec: 1

