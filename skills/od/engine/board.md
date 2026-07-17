# OmniDev Flow Board

**Load when**: `/od board` · `$od board` · `board start|next|apply|run` · Phase 0 open when `config.board_ui: true` and status is `idle` (optional offer).

**Principle**: One shared state machine for all platforms. Shells differ (Cursor Canvas optional · Codex/Claude popup wizard · Markdown table everywhere). **Default mode = manual. Only `board start` begins execution.**

→ PAL: SKILL.md §F · Interactive catalogs: [interactive-prompt.md](interactive-prompt.md) §3.10 · Templates: `templates/flow-board.*`

---

## 0. Hard Rules

1. **Default `mode`: `manual`**. Never assume autopilot.
2. **No phase work until `status` is `running` or `paused` after a successful `start`.** Showing the board alone must not advance phases.
3. **Required phases** `0` (Assessment) and `3` (Development) cannot be skipped. Reject `--skip` that includes them.
4. **Hard gates never auto**: `b0_confirm`, `deploy_prod`, `pre_dev` (M/L/XL). Even `mode=auto` must STOP — WAIT; **after user confirms proceed, resume autopilot same turn** (§2.5).
5. **Disk is truth**: `docs/omnidev-state/flow-board.json`. Chat/Canvas are views. After Codex compaction, re-read this file.
6. Prefix: Cursor/Claude `/od board …` · Codex `$od board …` (either prefix accepted on all platforms per Signal A).
7. **Autopilot resume is mandatory**: while `mode=auto`, never leave the user stranded after a successful hard-gate confirm — continue until next hard gate or `status=done`.

---

## 1. State File

**Path**: `docs/omnidev-state/flow-board.json`

**Seed**: On `/od i` / `/od up` / first `/od board`, if missing → copy from skill `templates/flow-board.json`.

```json
{
  "schema_version": 1,
  "status": "idle",
  "mode": "manual",
  "autopilot": false,
  "current_phase": 0,
  "phases_enabled": [0, 1, 2, 3, 4, 5],
  "phases_skipped": [],
  "phases_done": [],
  "started_at": null,
  "updated_at": null,
  "last_action": null
}
```

| Field | Values | Notes |
|-------|--------|-------|
| `status` | `idle` \| `running` \| `paused` \| `done` \| `cancelled` | `idle` = not started |
| `mode` | `manual` \| `auto` | Set at `start`; locked until reset |
| `autopilot` | `true` \| `false` | `true` when `mode=auto` or `/od auto`/`/od al`; drives resume-after-confirm |
| `phases_enabled` | subset of 0–5 | Must include 0 and 3 |
| `phases_skipped` | phases user opted out | Derived / stored for metrics |
| `current_phase` | 0–5 | Next/active phase |

Also keep a human view: rewrite `docs/omnidev-state/flow-board.md` from [§5](#5-markdown-board-view) on every board mutation (≤40 lines).

---

## 2. Commands

| Command | Behavior |
|---------|----------|
| `/od board` / `$od board` | Open board UI ([§4](#4-platform-shells)). Do **not** start. |
| `/od board start [--mode manual\|auto] [--skip N,N]` | Validate → write state → `status=running` → enter first enabled phase |
| `/od board next` | **Manual only**. Advance to next enabled phase (or finish). If `idle`, error: run `start` first. |
| `/od board apply --skip N,N` | Update skip plan while `idle` (or before start wizard confirms). Locked after `running`. |
| `/od board run [--skip N,N]` | Alias: `start --mode auto` then continuous advance (§2.5) |
| `/od board reset` | Back to `idle`, clear done; keep last skip prefs optional |
| `/od auto [requirement?]` | **Autopilot entry** — same as `board run` (+ optional new requirement → Phase 0 first). Alias of `/od al` |
| `/od al` | Same as `/od auto` for remaining/full flow; sets `deploy_autonomy: full` intent for Phase 5 assets |

### 2.1 Flag parsing

- `--mode manual|auto` — default `manual` if omitted
- `--skip 1,5` or `--skip none` — optional phases only
- Unknown flags → B.0 clarify, do not start

### 2.2 `start` algorithm

1. Ensure `flow-board.json` exists (seed if needed).
2. If `status` is `running`/`paused` → prompt resume vs reset (`board_resume`).
3. Merge CLI flags into state; compute `phases_enabled` = all − skipped; force include 0, 3.
4. Set `status=running`, `current_phase` = min(enabled), `started_at`/`updated_at` now, `last_action=start`.
5. If `mode=auto` → set `autopilot=true` (also mirror in session-log YAML `autopilot: true`).
6. Write JSON + Markdown view.
7. Load phase instruction for `current_phase` and execute (same as normal `/od` phase entry).
8. On phase-end / decision:
   - **`manual`**: set `status=paused`, present `board_next` → **STOP — WAIT**
   - **`auto`**: follow §2.5 (soft auto-pick; hard gates STOP; after confirm → resume)

### 2.3 `next` algorithm (manual)

1. Require `mode=manual` and `status` in `running|paused`.
2. Mark `current_phase` done → append `phases_done`.
3. Next = smallest enabled phase > current; if none → `status=done`, checkpoint complete.
4. Else set `current_phase`, `status=running`, load that phase file, continue.

### 2.4 Relation to `/od n` / `/od sk` / `/od al` / `/od auto`

| Legacy | Board |
|--------|-------|
| `/od n` | If board `paused`/`running`, treat as `board next` when `mode=manual`; else normal phase next |
| `/od sk N` | If `idle`, update skip plan; if running, skip remaining optional phase N (not 0/3) |
| `/od al` / `/od auto` | `board run` (+ remaining phases if already mid-flow); respect hard gates; **resume-after-confirm** (§2.5) |

Prefer documenting `board *` + `/od auto` as the control-plane API; keep legacy `/od al` working.

### 2.5 Autopilot contract (`mode=auto` / `autopilot=true`)

**Goal**: One command runs the **entire** enabled phase pipeline. Soft decisions take catalog defaults. Hard gates ask the user once; **after affirmative confirm, continue automatically** until the next hard gate or `status=done` — no second `/od auto` required.

#### Soft gates (auto-accept **default** option; do **not** STOP)

| decision_point | Auto-pick |
|----------------|-----------|
| `phase0_complexity` / `phase0_s_fastpath` | `confirm` / `fast` |
| `checkpoint` (B.8) / `board_next` | `next` |
| `blueprint_approach` | first recommended / `approach_a` if marked default |
| `assumptions_confirm` | `accept` |
| `open_questions` | `accept_defaults` |
| `phase2_plan_ready` | `next` |
| `change_impact` (on-scope) | `proceed` |
| `test_layers` | `accept_plan` |
| `gap_backfill` | `implement_now` |
| `deploy_consent` | `apply_fix` when `deploy_autonomy: full` (set by `/od auto`/`/od al`) |

Log each soft auto-pick to session-log `## Key Decisions` as `autopilot_default: {id}`.

#### Hard gates (STOP — WAIT; show §8/native UI)

| decision_point | Notes |
|----------------|-------|
| `b0_confirm` | Always |
| `pre_dev` | Required for complexity M/L/XL |
| `deploy_prod` | Always (production execution) |
| `test_gate_fail` | Always (failure disposition) |

When presenting a hard gate under autopilot, footer **must** include:

`Autopilot paused · confirm to resume full flow · /od 1 or /od y`

Also set `pending_decision.autopilot_resume: true`.

#### Resume-after-confirm (mandatory)

After user affirms via UI pick / `/od y` / `/od n` (when that maps to proceed) / `/od 1` (default row) / bare `1` with pending:

1. Clear `pending_decision`.
2. If choice is **revise / cancel / no / non-default** → set `autopilot=false`, `mode=manual` (or `paused`), **STOP — WAIT**.
3. If choice is **proceed / yes / confirm / default** **and** `autopilot=true` (or `mode=auto`):
   - Keep `status=running`, `autopilot=true`
   - **Same activation**: continue remaining tasks in current phase, then remaining enabled phases, applying soft-gate defaults
   - Do **not** ask the user to send `/od auto` again
4. Repeat until next hard gate or all enabled phases `done`.

#### Start / mid-flow entry

| Command | Behavior |
|---------|----------|
| `/od auto` / `/od al` / `/od board run` | Idle → `start --mode auto` from first enabled phase. Mid-flow → set `mode=auto`,`autopilot=true`, continue from `current_phase` |
| `/od auto [requirement]` | Write requirement → Phase 0 assessment → soft-accept complexity → continue §2.5 |
| Chat hint (Phase 0 summary / board idle) | One line: `Full auto: /od auto  ·  confirms only at hard gates, then continues` |

---

## 3. Config (`config.json`)

| Key | Default | Description |
|-----|---------|-------------|
| `board_ui` | `true` | Offer / render board on `/od board` and optionally at Phase 0 idle |
| `board_default_mode` | `"manual"` | Pre-selected mode in wizard |
| `board_cursor_canvas` | `true` | Cursor: materialize Canvas from template when useful |
| `board_required_phases` | `[0, 3]` | Cannot skip |

---

## 4. Platform Shells

### 4.1 All platforms — Markdown view

Every board command: print ≤12-line summary + ensure `flow-board.md` updated. Never dump full JSON in chat.

### 4.2 Codex / Claude / CLI — Wizard (`board_wizard`)

When user runs bare `/od board` / `$od board` and `status=idle`:

1. `board_mode` — options: `manual`[default] · `auto` · `cancel`
2. Skip optional phases — Codex: sequential yes/no per optional phase **or** one question "skip list (e.g. 1,5 or none)". Claude: `allow_multiple` on optional phases if supported.
3. `board_confirm_start` — `start`[default] · `edit` · `cancel`

On `start` → run §2.2 with chosen mode/skip.

When `status=paused` and `mode=manual`: present `board_next` only (next / revise / end).

### 4.3 Cursor — Canvas (optional enhance)

When `board_cursor_canvas: true` and platform is Cursor:

1. Read skill `templates/board.canvas.tsx`.
2. Write/update workspace canvas at the host canvases path if writable:
   `~/.cursor/projects/<workspace-id>/canvases/omnidev-board.canvas.tsx`
   (If path unknown: write `docs/omnidev-state/omnidev-board.canvas.tsx` and tell user to open it; or skip Canvas and use wizard §4.2.)
3. Canvas buttons must emit Signal A prompts via `newComposerChat`, e.g. `/od board start --mode manual --skip none`.
4. Wizard (§4.2) remains the **guaranteed** path if Canvas unavailable.

### 4.4 Interactive catalogs

→ [interactive-prompt.md](interactive-prompt.md) §3.10: `board_mode`, `board_confirm_start`, `board_next`, `board_resume`.

---

## 5. Markdown Board View

Rewrite `docs/omnidev-state/flow-board.md` on each mutation:

```markdown
# OmniDev Flow Board

- status: {status}
- mode: {mode}
- current: Phase {N}

| Phase | Name | State |
|-------|------|-------|
| 0 | Assessment | done\|current\|pending\|skipped |
| 1 | Blueprint | … |
| 2 | Planning | … |
| 3 | Development | … |
| 4 | Testing | … |
| 5 | Deploy | … |

## Controls
- Start: `/od board start --mode manual` (default) or `--mode auto`
- Full autopilot: `/od auto` / `/od al` / `/od board run`
- Next (manual): `/od board next`
- Reset: `/od board reset`
- After hard-gate confirm in auto: continues automatically
```

Chat may show a 6-row compact table (same data), then STOP — WAIT when waiting for user.

---

## 6. Metrics

On `start` / `next` / `done` / `reset`, append to `metrics.json` events:

- `board_start` — `{ mode, skip }`
- `board_next` — `{ from, to }`
- `board_done` — `{ mode, phases_done }`
- `board_reset`

---

## 7. Install / Update Seed

On `/od i` and `/od up` after skills copy:

1. Ensure `docs/omnidev-state/` exists.
2. If `flow-board.json` missing → copy `templates/flow-board.json`.
3. If `flow-board.md` missing → copy `templates/flow-board.md`.
4. Merge config keys from §3 if absent (`board_ui`, `board_default_mode`, `board_cursor_canvas`).

Do **not** overwrite an existing in-progress `flow-board.json` on update.

---

## 8. Quick Reference

| User intent | Command |
|-------------|---------|
| Open controls (no run) | `/od board` |
| Manual run (default) | `/od board start` |
| **Full autopilot** | `/od auto` or `/od al` or `/od board run` |
| Autopilot + new requirement | `/od auto [requirement]` |
| Skip blueprint+deploy | `/od board start --mode auto --skip 1,5` |
| Continue after pause (manual) | `/od board next` |
| After hard-gate confirm (auto) | *(automatic resume — no extra command)* |
| Codex same | `$od auto` / `$od board run` … |
