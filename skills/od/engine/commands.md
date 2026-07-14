# OmniDev Command Reference

→ Platform mapping: SKILL.md §F (Platform Abstraction Layer)

All commands require **`/od` prefix**. Short aliases are used **after** `/od` (e.g. `/od n`, not bare `n`).

**Strict rule**: bare `1`, `n`, `y`, `continue` without `/od` do **NOT** advance workflow. Resume → **`/od re` only**.

## Core Commands

| Command | Alias | Description |
|---------|-------|-------------|
| `/od [requirement]` | — | Guided workflow: assess → recommend phases → may skip |
| `/od -f [requirement]` | — | Fast mode: skip blueprint/plan, go straight to development (S-level confirm rules) |
| `/od -p [requirement]` | — | Plan only: blueprint + plan, no code |
| `/od h` | `/od help` | Show all commands |
| `/od ob` | `/od onboard` | Scan project, generate context docs |
| `/od rp` | `/od report` | Generate weekly report |
| `/od gv` | `/od governance` | AI governance and cost audit (manual) |
| `/od gv --scope <...>` | — | phase0–5 / learning / cost / compliance / quality |
| `/od gv --since <7d\|14d\|30d\|90d>` | — | Audit time window (default 14d) |
| `/od rv` | `/od review` | Code review (read-only) |
| `/od qa` | — | Testing phase shortcut (Phase 4) |
| `/od ch [new requirement]` | `/od change` | Requirement change management |
| `/od ln` | `/od learn` | Self-learning: error review + rule evolution |
| `/od ln -r` | — | View learning log and pending proposals |
| `/od ln -a` | — | Auto-apply all pending proposals |
| `/od ln --rb [N]` | — | Roll back the Nth evolution |
| `/od up` | `/od update` | Update OmniDev Kit (**default scope: `project`**) |
| `/od up --scope project\|user` | `/od up -s …` | Update with explicit install scope |
| `/od i <url>` | `/od install` | Install from Git (**default scope: `project`**) |
| `/od i <url> --scope project\|user` | `/od i … -s …` | Install with explicit install scope |
| `/od ps` | `/od push` | Commit and push (requires user confirm) |
| `/od st` | `/od stash` | Stash task context |
| `/od po` | `/od pop` | Restore stashed context |
| `/od sy` | `/od sync` | Sync to GitHub Issue / Jira |
| `/od db` | `/od dashboard` | Generate efficiency ROI dashboard |
| `/od re` | `/od resume` | Resume last session |
| `/od re [instruction or requirement]` | `/od resume […]` | **Resume session + handle payload** (see session-memory §6.1) |

**`/od re [payload]` examples**:

| Command | Behavior |
|---------|----------|
| `/od re` | Pure breakpoint resume |
| `/od re continue Group 3` | Resume + continue from Group 3 (type-B hint) |
| `/od re ch login switch to OAuth` | Resume + requirement change flow |
| `/od re -f fix 500 error` | Resume + fast development mode |
| `/od re n` | Resume + enter next phase |
| `/od re add Excel export` | Resume + classify (default D: merge into current phase) |
| `/od cfg` | `/od config` | View configuration |
| `/od cfg -i on\|off` | — | Toggle interactive mode; **off requires `b0_confirm` popup first**, then write config |

## Flow Board (control plane)

→ Full protocol: [engine/board.md](board.md). Codex: `$od board …` (same args).

| Command | Alias | Description |
|---------|-------|-------------|
| `/od board` | — | Open board (mode + phases). **Does not start** |
| `/od board start [--mode manual\|auto] [--skip N,N]` | — | **Only entry that starts execution** (default `--mode manual`) |
| `/od board next` | — | Manual mode: advance after pause |
| `/od board apply --skip N,N` | — | Set skip plan while idle |
| `/od board run [--skip N,N]` | — | `start --mode auto` then continuous advance |
| `/od board reset` | — | Back to idle |

Required phases **0** and **3** cannot be skipped. Hard gates still confirm in `auto`.

## Phase Navigation

| Command | Alias | Description |
|---------|-------|-------------|
| `/od n` | `/od next` | Next phase (board paused → treat as `board next` when manual) |
| `/od ad [content]` | `/od adj` | Revise current phase output |
| `/od sk [phase]` | `/od skip` | Skip phase (0–5); board idle → updates skip plan |
| `/od bk [phase]` | `/od back` | Go back to phase |
| `/od al` | `/od all` | Run remaining phases (≈ `board run`; **includes deploy_autonomy: full** — production execution still needs confirm) |

## Confirmation

Interactive confirmations use platform native prompt (SKILL.md §F.2). User confirms via UI **or** `/od y` / `/od x` / `/od n` etc. — not bare aliases.

| Command | Alias | Description |
|---------|-------|-------------|
| `/od y` | `/od confirm` | Confirm current operation |
| `/od x` | `/od cancel` | Cancel / end session |
| `/od em [msg]` | — | Edit commit message (`/od ps` flow) |
| `/od ln y` | — | Accept all learning proposals |
| `/od ln y [N,N]` | — | Accept proposals by number |
| `/od ln x` | — | Reject all proposals |
| `/od ln ad [N] [feedback]` | — | Adjust specified proposal |

## Config Options (`config.json`)

| Key | Default | Description |
|-----|---------|-------------|
| `interactive_mode` | `true` | **Primary working mode** — Decision Matrix §3 popups throughout; platforms §4/§5/§6; failure → §8 STOP-WAIT |
| `board_ui` | `true` | Enable flow board (`/od board`); seed `flow-board.json` on install |
| `board_default_mode` | `"manual"` | Wizard default: manual step-by-step |
| `board_cursor_canvas` | `true` | Cursor: materialize Canvas from `templates/board.canvas.tsx` when useful |
| `board_required_phases` | `[0, 3]` | Phases that cannot be skipped |
| `codex_auto_resolve` | `false` | Whether Codex may use `autoResolutionMs` (forbidden by default; keep interactive wait) |
| `ask_mode_after_od` | `true` | Enter Q&A mode after `/od` |
| `update_source_url` | kit repo URL | `/od up` / `/od i` source |
| `install_scope` | `"project"` | Default install scope for `/od up` / `/od i` when flag omitted (`project` \| `user`) |
| `auto_checkpoint` | `false` | git stash before Phase 3 (not commit) |
| `confirmation_level` | `"auto"` | `full` / `reduced` / `minimal` — B.15 |
| `coverage_gate` | `false` | Whether unmet coverage blocks |
| `e2e_tool` | `"playwright"` | E2E tool: playwright / cypress / browser_mcp / auto |
| `e2e_required_fullstack` | `true` | Force E2E for fullstack requirements |
| `unit_gate_blocking` | `true` | Unpassed UNIT blocks Phase 4 completion |
| `regression_mode` | `"targeted"` | targeted / full |
| `allow_e2e_sub_agent` | `true` | Phase 4 E2E may use sub-agent to isolate Playwright output |
| `deploy_modes` | `["docker","k8s","binary"]` | Default deploy modes supported in Phase 5 |
| `deploy_autonomy` | `"conservative"` | `conservative` = legacy changes to deploy/Makefile need user consent; `full` = full pipeline may add/change autonomously |
| `deploy_use_makefile` | `true` | Phase 5 root Makefile as one-click deploy entry |
| `sub_agents` | `"auto"` | `off` / `auto` / `on` — T2 Task Worker (in-phase parallelism) |
| `phase_workers` | `"auto"` | `off` / `auto` / `on` — T1 Phase Worker (outsource whole phase; see multi-agent-architecture.md) |
| `design_split` | `true` | Design index + `features/*.md` |
| `log_token_estimates` | `true` | Write metrics on phase_exit |
| `max_read_lines` | `150` | Max lines per Read |
| `context_mode` | `"slim"` | `slim` / `standard` — context occupancy strategy |
| `max_hot_lines` | `150` | HOT layer line cap |
| `max_resident_lines` | `300` | HOT+WARM combined cap |
| `checkpoint_max_lines` | `12` | Checkpoint output cap |
| `platform_override` | `null` | Manual platform override: `"cursor"`, `"claude_code"`, `"codex"`, `"cli_other"`, or `null` (auto) |
| `codex_compaction_multiplier` | `1.3` | Codex token estimate multiplier (compensate invisible compaction cost) |
| `codex_conservative_occupancy` | `true` | Whether Codex uses defensive context occupancy |
| `codex_thread_overhead_tokens` | `4000` | Token overhead per Codex sub-agent thread |
| `codex_max_turns_before_compress` | `15` | Codex compress turn threshold (more conservative than default 25) |
| `jira_base_url` | — | `/od sy` Jira (optional) |
| `jira_project_key` | — | Jira project key (optional) |

See [engine/context-lifecycle.md](engine/context-lifecycle.md), [engine/token-optimization.md](engine/token-optimization.md), [engine/metrics.md](engine/metrics.md), SKILL.md §F.8 (Codex compaction).
