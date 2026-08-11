# Godot Model Bench — round 7 results

- Engine: Godot 4.7.1.stable.official.a13da4feb
- Challenge: PROMPT7.md
- 28 checks; one repair round allowed; time 0..10 (faster = better); gdlint 0..10 (fewer issues = better)

| # | Model | Score | Time | Lint | Checks | Comp | Tests | 1-shot | Hyg | Att | Wall s | Lint # | In tok | Out tok | Est $ |
|---|-------|-------|------|------|--------|------|-------|--------|-----|-----|--------|--------|--------|---------|-------|
| 1 | Grok 4.5 | **100.0** | 10.0 | 10 | 28/28 | 10 | 50 | 10 | 10 | 1 | 15 | 0 | 1172 | 1032 | $0.0083 |
| 2 | GPT-5.6 Luna | **89.2** | 9.2 | 10 | 28/28 | 10 | 50 | 0 | 10 | 2 | 58 | 0 | 1344 | 3207 | $0.0021 |
| 3 | Grok Build 0.1 | **87.9** | 7.9 | 10 | 28/28 | 10 | 50 | 0 | 10 | 2 | 130 | 0 | 1576 | 6468 | $0.0136 |
| 4 | Xiaomi MiMo V2.5 | **85.9** | 8.9 | 9 | 27/28 | 10 | 48 | 0 | 10 | 2 | 77 | 2 | 1272 | 2129 | $0.0007 |
| 5 | Inkling | **85.7** | 7.7 | 10 | 27/28 | 10 | 48 | 0 | 10 | 2 | 145 | 0 | 944 | 7964 | $0.0325 |
| 6 | Ring 2.6 1T | **84.0** | 6.0 | 10 | 27/28 | 10 | 48 | 0 | 10 | 2 | 235 | 0 | 1530 | 16144 | $0.0102 |
| 7 | Aion 3.0 Mini | **81.9** | 6.9 | 10 | 25/28 | 10 | 45 | 0 | 10 | 4 | 188 | 0 | 978 | 3471 | $0.0055 |
| 8 | Aion 3.0 Mini | **81.9** | 6.9 | 10 | 25/28 | 10 | 45 | 0 | 10 | 4 | 188 | 0 | 978 | 3471 | $0.0055 |
| 9 | Kimik2.7 Code | **80.0** | 4.0 | 10 | 22/24 | 10 | 46 | 0 | 10 | 2 | 348 | 0 | 944 | 21445 | $0.0752 |
| 10 | GLM 5.2 | **78.0** | 0.0 | 10 | 27/28 | 10 | 48 | 0 | 10 | 2 | 570 | 0 | 933 | 34129 | $0.0088 |
| 11 | Step 3.7 Flash | **10.0** | 0.0 | 0 | 0/1 | 0 | 0 | 0 | 10 | 2 | 193 | 0 | 992 | 14394 | $0.0166 |
| 12 | Mistral Medium 3.5 | **10.0** | 0.0 | 0 | 0/1 | 0 | 0 | 0 | 10 | 2 | 11 | 0 | 1001 | 861 | $0.0080 |
| 13 | Trinity Large Thinking | **10.0** | 0.0 | 0 | 0/1 | 0 | 0 | 0 | 10 | 2 | 101 | 7 | 913 | 2015 | $0.0019 |
| 14 | Granite 4.1 8B | **0.0** | 0.0 | 0 | 1/2 | 0 | 0 | 0 | 0 | 2 | 672 | -1 | 1039 | 17769 | $0.0018 |
| 15 | Muse Glimmer 30B | **10.0** | 0.0 | 0 | 0/1 | 0 | 0 | 0 | 10 | 2 | 178 | 0 | 959 | 7738 | $0.0119 |
| 16 | Solar Pro 4 | **10.0** | 0.0 | 0 | 0/1 | 0 | 0 | 0 | 10 | 2 | 28 | 0 | 991 | 877 | $0.0001 |
| 17 | Nemotron 3.5 Lightning (free) | **10.0** | 0.0 | 0 | 0/1 | 0 | 0 | 0 | 10 | 2 | 82 | 4 | 1000 | 19835 | $0.0000 |
| 18 | Sakana Namazu | **0.0** | 0.0 | 0 | 1/2 | 0 | 0 | 0 | 0 | 2 | 1 | -1 | 0 | 0 | $0.0000 |

## Per-model failure summary (first attempt)

**x-ai/grok-4.5** (score 100.0)
  - clean pass

**openai/gpt-5.6-luna** (score 89.2)
  - FAIL  texture is not null  --  null texture  [api]
  - **Failure categories**:
    - API misuse: 1

**x-ai/grok-build-0.1** (score 87.9)
  - FAIL  particle amount == 32  --  got 8  [logic]
  - FAIL  particle lifetime == 0.6  --  got 1.0  [logic]
  - FAIL  one_shot == true  --  got false  [logic]
  - FAIL  get_particle_count() == 32  --  got 8  [logic]
  - FAIL  get_particle_lifetime() ~ 0.6  --  got 1.0  [logic]
  - **Failure categories**:
    - Logic/Spec: 5

**xiaomi/mimo-v2.5** (score 85.9)
  - FAIL  spell_vfx.gd loads/parses  --  load() returned null or unparseable script  [spec]
  - **Failure categories**:
    - Missing API: 1

**thinkingmachines/inkling** (score 85.7)
  - FAIL  texture is not null  --  null texture  [api]
  - **Failure categories**:
    - API misuse: 1

**inclusionai/ring-2.6-1t** (score 84.0)
  - FAIL  has get_particle_node  --  missing get_particle_node  [spec]
  - FAIL  finished=true before burst (idle)  --  finished=false  [logic]
  - FAIL  becomes finished after burst + enough ticks  --  finished=false  [timing]
  - **Failure categories**:
    - Missing API: 1
    - Logic/Spec: 1
    - Timing: 1

**aion-labs/aion-3.0-mini** (score 81.9)
  - FAIL  texture is not null  --  null texture  [api]
  - FAIL  finished=true before burst (idle)  --  finished=false  [logic]
  - FAIL  becomes finished after burst + enough ticks  --  finished=false  [timing]
  - **Failure categories**:
    - API misuse: 1
    - Logic/Spec: 1
    - Timing: 1

**aion-labs/aion-3.0-mini** (score 81.9)
  - FAIL  texture is not null  --  null texture  [api]
  - FAIL  finished=true before burst (idle)  --  finished=false  [logic]
  - FAIL  becomes finished after burst + enough ticks  --  finished=false  [timing]
  - **Failure categories**:
    - API misuse: 1
    - Logic/Spec: 1
    - Timing: 1

**moonshotai/kimi-k2.7-code** (score 80.0)
  - FAIL  texture is not null  --  null texture  [api]
  - FAIL  process_material exists  --  got null  [logic]
  - **Failure categories**:
    - API misuse: 1
    - Logic/Spec: 1

**z-ai/glm-5.2** (score 78.0)
  - FAIL  initial_velocity ~ 120  --  got 0.0  [logic]
  - **Failure categories**:
    - Logic/Spec: 1

**stepfun/step-3.7-flash** (score 10.0)
  - FAIL  spell_vfx.gd loads/parses  --  load() returned null or unparseable script  [spec]
  - **Failure categories**:
    - Missing API: 1

**mistralai/mistral-medium-3-5** (score 10.0)
  - FAIL  spell_vfx.gd loads/parses  --  load() returned null or unparseable script  [spec]
  - **Failure categories**:
    - Missing API: 1

**arcee-ai/trinity-large-thinking** (score 10.0)
  - FAIL  spell_vfx.gd loads/parses  --  load() returned null or unparseable script  [spec]
  - **Failure categories**:
    - Missing API: 1

**ibm-granite/granite-4.1-8b** (score 0.0)
  - FAIL  spell_vfx extends Node2D  --  got RefCounted  [logic]
  - **Failure categories**:
    - Logic/Spec: 1

**meta/muse-glimmer-30b** (score 10.0)
  - battery never ran (0/1 gate) both attempts

**upstage/solar-pro4** (score 10.0)
  - battery never ran (0/1 gate) both attempts
**nvidia/nemotron-3.5-lightning:free** (score 10.0)
  - battery never ran (0/1 gate) both attempts

**sakana/sakana-namazu** (score 0.0)
  - API blocked: OpenRouter 404 guardrail/data-policy restriction
