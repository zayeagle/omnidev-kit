# Interactive Prompt Adapter (Cross-Platform)

**Load when**: any decision point in the Decision Matrix (§3), checkpoint (B.8), B.0, skill-composition, stash, session resume, Phase 5 consent.

**Principle**: Native UI first. Missing/failure → §8 **Markdown table** (not a drawn "popup"). **Always STOP — WAIT**. Forbid timeout auto-pick; forbid "show then auto-continue".

→ PAL: SKILL.md §F.2

---

## 0. Hard Rules

| Platform | Tool (MUST try first) |
|----------|------------------------|
| **Cursor** | `AskQuestion` — §4 |
| **Claude Code** | `AskUserQuestion` — §5 |
| **Codex** | `request_user_input` — §6 (needs flag; **forbid** default `autoResolutionMs`) |
| **CLI** | §8 Markdown fallback table |

1. Short chat summary (Phase 0 ≤6 lines; checkpoint ≤12 lines)
2. Forbid `od_interactive` / YAML metadata in chat → session-log only
3. Native success → do not also print an options table
4. Labels and §8 always use `/od …` or `$od …` (forbid "reply 1/2/3")
5. Tool exists but skipped = **violation**; no tool → §8 + environment hint
6. **STOP — WAIT** until UI pick or next Signal A/B
7. `interactive_mode` defaults to `true`. Setting `false` requires explicit user `/od cfg -i off` confirm (via `b0_confirm`); otherwise keep popups
8. **Workers / sub-agents must not** prompt the user or make product decisions alone; only Orchestrator calls this file
9. Codex: **do not set** `autoResolutionMs` by default. Only when `config.codex_auto_resolve: true` and the decision point marks `allow_auto_resolve` (non-default path)
10. **Chat UX ban**: never emit box-drawing / pad-aligned frames (`+--+`, `╔═║└┘│─`, double `||` borders, code-fence "cards"). §8 = Markdown `|` table only; §9 = plain numbered lines

---

## 1. Entry: `present_options`

```
INPUT:  decision_point (from §3), options[{id,label}]?, title_zh?, allow_multiple?, blocking?
OUTPUT: selected id(s) | null; method: cursor_ask|claude_ask|codex_input|md_table|text_fallback
```

| Step | Action |
|------|--------|
| A | `interactive_mode=false` → §9 |
| B | resolve platform (`platform_override` → activation §2) |
| C | native in list → §3 catalog → §4/§5/§6 |
| D | missing/error → §8 Markdown table (with platform hint) |
| E | **STOP — WAIT** |

**UI pick** (same-turn tool return) = valid advance. Next **typed** message still needs `/od` or `$od`.

---

## 2. Never-Do

| ❌ | ✅ |
|---|---|
| Skip native UI (including S-level) | Call matching §3 catalog + §4/§5/§6 |
| Codex default `autoResolutionMs` | Omit the field; wait for user |
| Auto-continue after §8 table | STOP — WAIT |
| Worker asks user | Write disk only; return ≤30 lines to Orchestrator |
| Phase 5 numbered prose options | `deploy_consent` / `deploy_prod` catalog |
| Drawn frames / "fake modal" ASCII | Copy §8 table template verbatim |

---

## 3. Decision Matrix + Option Catalogs

Every decision point: **same turn** `present_options`. `checkpoint` (B.8) is **also required** at every phase end.

| Phase / Flow | decision_point | When |
|--------------|----------------|------|
| 0 | `phase0_complexity` | M/L/XL complexity confirm |
| 0 | `phase0_s_fastpath` | **S-level also must popup** (confirm fast path / upgrade) |
| board | `board_mode` / `board_confirm_start` / `board_next` / `board_resume` | [board.md](board.md) · §3.10 |
| 1 | `blueprint_approach` | Approach selection |
| 1 | `assumptions_confirm` | Design assumptions confirm |
| 1 | `open_questions` | Open questions batch confirm |
| 2 | `phase2_plan_ready` | Design+plan+test plan done, before development |
| 3 | `pre_dev` | Pre-Dev Scope (B.15: M/L/XL required; S only when off-scope) |
| 3 | `change_impact` | Change Impact (B.15: L/XL each group; M when off-scope) |
| 3 | `checkpoint` | Phase end |
| 4 | `test_layers` | Layer disputes / skip E2E etc. |
| 4 | `test_gate_fail` | Disposition after gate failure |
| 4 | `gap_backfill` | Gap Backfill path |
| 4 | `checkpoint` | Phase end |
| 5 | `deploy_consent` | Legacy asset fix consent |
| 5 | `deploy_prod` | Production deploy execution (B.0) |
| 5 | `checkpoint` | Phase end |
| re / ch / st / skill / ps / up | `up_confirm` etc. | matching flow (§3.6) |

### 3.1 `checkpoint` (B.8)

- prompt: `Phase [N] complete. Choose next step:`
- options: `next`→(/od n) · `revise`→(/od ad) · `help`→(/od h) · `cancel`→(/od x)

### 3.2 `phase0_complexity`

- prompt: `Complexity: {complexity} — {reason_short}. Recommended: {phases}. Confirm?`
- options: `confirm`→(/od n) Confirm · `adjust`→(/od ad) Adjust · `cancel`→(/od x)
- §8 rows must match this catalog only (do not invent `/od sk` / `/od al` here)

### 3.2b `phase0_s_fastpath` (S-level mandatory)

- prompt: `Assessed as S (fast path). Confirm go straight to development, or upgrade complexity?`
- options: `fast`→confirm S → development [default] (/od n) · `upgrade`→upgrade to M/L (/od ad) · `cancel`→(/od x)

### 3.3 `blueprint_approach`

- prompt: `Select a technical approach (see comparison above):`
- options: `approach_a` / `approach_b` / `approach_c?` / `revise`

### 3.4 `assumptions_confirm`

- prompt: `Accept the design assumptions above? (includes blocking items)`
- options: `accept`→accept [default] (/od n) · `revise`→revise assumptions (/od ad) · `cancel`→(/od x)

### 3.5 `open_questions` · `skill_select`

| id | notes |
|----|-------|
| `open_questions` | Prose table first; `accept_defaults`[default] · `review_one_by_one` · `cancel` |
| `skill_select` | `allow_multiple: true`; skill list + `od_only` + `cancel` |

Codex multi-select: sequential single-select or §8 "multi-select OK; explain in next message".

### 3.6 Resume / Change / B.0 / Push / Update

| id | options |
|----|---------|
| `resume` | `continue`[default] · `restart` · `cancel` |
| `resume_payload` | `resume_execute`[default] · `change_full`(/od ch) · `restart` · `cancel` |
| `change_confirm` | `proceed`[default] · `revise` · `cancel` |
| `b0_confirm` | `yes` · `no`[default] · `clarify` — **blocking** |
| `push_confirm` | `commit` · `edit_msg` · `cancel` (/od ps) |
| `up_confirm` | after `/od up`/`/od i` diff: `apply`[default] · `switch_scope` · `cancel` — show resolved `scope`+path in prompt |

### 3.10 Flow Board (`board_*`) — [board.md](board.md)

| id | When | options |
|----|------|---------|
| `board_mode` | `/od board` idle wizard step 1 | `manual`[default] · `auto` · `cancel` |
| `board_confirm_start` | after mode (+ skip) chosen | `start`[default] · `edit` · `cancel` |
| `board_next` | manual mode phase-end pause | `next`[default]→`/od board next` · `revise`→`/od ad` · `end`→`/od x` |
| `board_resume` | `start` while already running/paused | `continue`[default] · `reset`→`/od board reset` · `cancel` |

Skip optional phases: Cursor/Claude may use multi-select on phases 1/2/4/5; Codex sequential or free-text `1,5` / `none`. Never offer skip for 0 or 3.

### 3.11 Phase 2 `phase2_plan_ready`

- prompt: `Design/plan/test plan ready. Confirm enter development?`
- options: `next`→(/od n) · `revise`→(/od ad) · `cancel`→(/od x)

### 3.12 Phase 3 `pre_dev` · `change_impact`

| id | prompt | options |
|----|--------|---------|
| `pre_dev` | Pre-Dev scope above. Confirm start implementation? | `proceed`[default]→`/od y` · `revise`→`/od ad` · `cancel`→`/od x` |
| `change_impact` | Change impact above. Confirm continue? | `proceed`[default]→`/od y` · `revise`→`/od ad` · `cancel`→`/od x` |

Native missing → §8 table with those three rows only (no ASCII frame).

### 3.13 Phase 4 `test_layers` · `test_gate_fail` · `gap_backfill`

| id | options |
|----|---------|
| `test_layers` | `accept_plan`[default] · `skip_e2e` (must record B.0 reason) · `revise` · `cancel` |
| `test_gate_fail` | `fix_rerun`[default] · `waive` (B.0+reason) · `backfill` · `cancel` |
| `gap_backfill` | `backfill_docs` · `implement_now`[default] · `skip_with_reason` · `cancel` |

### 3.14 Phase 5 `deploy_consent` · `deploy_prod`

| id | options |
|----|---------|
| `deploy_consent` | `apply_fix`[default] · `docs_only` · `cancel` |
| `deploy_prod` | `yes` · `no`[default] · `clarify` — **blocking** |

---

## 4. Cursor — `AskQuestion`

```json
{
  "title": "<title_zh>",
  "questions": [{
    "id": "<decision_point>",
    "prompt": "<from §3>",
    "options": [{"id": "<id>", "label": "<label>"}],
    "allow_multiple": false
  }]
}
```

Must call same turn; once per message. No tool → §8 + Cursor hint.

---

## 5. Claude Code — `AskUserQuestion`

Same JSON as §4. Must call same turn.

---

## 6. Codex — `request_user_input`

```json
{
  "questions": [{
    "header": "<title_zh>",
    "question": "<prompt from §3>",
    "options": [{"label": "<label>"}]
  }]
}
```

- **Do not** add `autoResolutionMs` (unless `codex_auto_resolve: true`)
- Map label order back to §3 `id`

### 6.1 Enable popup

```toml
# ~/.codex/config.toml
[features]
default_mode_request_user_input = true
```

When unavailable, hint once per session → §8 STOP — WAIT. May record `codex_popup_hint_shown: true` in config.

---

## 8. Markdown Fallback Table

(Legacy name in logs: `pseudo_popup` → prefer method `md_table`.)

**Copy this template exactly.** Fill Action/Send from §3. Do **not** add borders, `||` columns, `+--+`, box-drawing, or pad spaces to "align" a frame.

```markdown
### OmniDev · [title]

[one-line prompt from §3]

| | Action | Send |
|---|--------|------|
| **1** | [Option A] · default | `/od y` |
| **2** | [Option B] | `/od ad` |
| **3** | Cancel | `/od x` |

Reply with a full `/od` / `$od` command — bare `1`/`2`/`3` invalid.
```

`pre_dev` example Send column: `/od y` · `/od ad` · `/od x`. Other catalogs may use `/od n` etc.

Hint (one line, native missing only): `No native UI here. Cursor: Claude/GPT or Plan · Codex: enable default_mode_request_user_input.`

**STOP — WAIT**. Forbid YAML in chat; forbid "reply 1/2/3"; **forbid any drawn UI**.

---

## 9. Minimal Text — only when `interactive_mode=false`

Plain numbered lines only (same ban on frames):

```markdown
Choose (full /od or $od; bare numbers invalid):
1. [A] (default) → /od y
2. [B] → /od ad
3. Cancel → /od x
```

---

## 10. Logging (session-log only)

```json
{"type":"interactive_prompt","method":"cursor_ask|claude_ask|codex_input|md_table|text_fallback","platform":"cursor","decision_point":"phase0_complexity","native_attempted":true}
```

---

## 11. Quick Reference

| Platform | Primary | Fallback |
|----------|---------|----------|
| Cursor | §4 | §8 |
| Claude | §5 | §8 |
| Codex | §6 (no autoResolution) | §6.1 + §8 |
| CLI | §8 | §9 |
