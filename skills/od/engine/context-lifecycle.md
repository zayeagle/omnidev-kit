# Context Lifecycle (Load / Purge / Resume)

**Load on**: every `/od` activation, phase transitions, `/od compress`, `/od re`.

**Hard target**: HOT ≤150 · WARM ≤250 · Total resident ≤300 lines (excl. user message).

---

## 1. Three-Layer Model

| Layer | Budget | Content | Enter | Leave |
|-------|--------|---------|-------|-------|
| **HOT** | ≤150 | SKILL B摘要 + phase 指令 + 当前 task 切片 | task 开始时加载 | task 完成 → 卸载 |
| **WARM** | ≤250 | plan 当前 Group + design index + 3条决策 | phase 入口加载 | phase exit → purge, only ≤5行 transition |
| **COLD** | disk | features/, test-plan, tool raw, `*-history.md` | 显式 Grep/Read | 读后摘要→state file，标记 expired |

**Golden rule**: 磁盘有 state file → 禁止在对话中重复粘贴全文；用路径指针代替。

---

## 2. Content Classification

| Type | Unloadable? | Rule |
|------|-------------|------|
| Raw tool output | ✅ | Key info extracted → discard |
| Previous phase instruction | ✅ | Phase exit → purge |
| State files | ⚠️ | Section-only per phase (see §3) |
| User decisions | ❌ | Must persist to session-log/state files |

**Safely trimmable**: raw tool outputs, previous phase instructions, intermediate reasoning.  
**Never trim**: user decisions not yet in state files, active blockers, state files.

---

## 3. Per-Phase Section Loading

### `00-project-context.md` by phase
| Phase | Sections loaded |
|-------|-----------------|
| 0 | `Stack & Layers`, `Dependency Topology` |
| 1 | + `Architecture Patterns` |
| 2 | + `Domain Knowledge` (last 15 lines) |
| 3 | `Stack & Layers`, `AI Pitfall Guide`, `Stability Level` |
| 4 | `AI Pitfall Guide`, test conventions |
| 5 | `Stack & Layers`, deploy-relevant topology |

Use `Grep` with section header, never load full file if >60 lines.

### `02-plan.md` — Group-scoped
Phase 3/4: read frontmatter + `## Group N` only. Reload on group complete.

### `04-design.md` — Feature-scoped  
Phase 3: `grep '## Feature {FN}'` for current task (≈20-40 lines). Never load full file.

---

## 4. Phase Transition Protocol

### Exit Phase N
1. Persist outputs to state files (archive to `*-history.md` if overwriting)
2. Update `metrics.json` phase_exit event
3. Transition summary (≤5 lines): what was persisted, key concerns for next phase, user decisions
4. Mark unloadable: phase instruction, tool raw, intermediate reasoning

### Enter Phase N+1
1. Load new phase instruction file
2. Re-read state files from disk (NOT from conversation history)
3. Context should be: SKILL B摘要 + phase instruction + state slices + transition summary

#### After `/od re` (cold start, ≤200 lines)
1. `session-log.md` YAML + 恢复指引 (≤20 lines)
2. Active phase instruction
3. `02-plan.md` frontmatter + active group only
4. `03-progress.md` blockers only
5. `04-design.md` index only (`design_split:true`) or active feature section (`design_split:false`)

---

## 5. Phase Transition Purge (MANDATORY)

On every phase exit:
```
PURGE:
□ Previous phase instruction file
□ All tool raw outputs from previous phase
□ 04-design.md feature sections not in next task
□ 05-test-plan sections not under test
□ Transition summaries older than 1 phase

RETAIN (≤5 lines to session-log):
□ User decisions not yet in state files
□ Active blockers
```

---

## 6. Checkpoint & Progress Patterns

**Checkpoint** (≤12 lines):
```
✅ Phase N: [Name]
📦 [files]
📍 P0✅ P1⏭ P2✅ P3🔄
🔔 Next: Phase N+1
[Interactive prompt: 2-4 options]
```

**Instead of** full state file paste → use path pointers ("F2 设计见 `04-design.md` §F2，route `/api/user`")  
**Instead of** full test output → 3-column table (TC-ID / Result / Note)  
**Instead of** phase essay → standard 4-line checkpoint

---

## 7. Turn Budget

| Threshold | Action |
|-----------|--------|
| 15 turns same phase | 3-line summary → suggest `/od compress` |
| 25 turns total | **must** `/od compress` or `/od x` ↯ new session |
| 3+ consecutive Read same file | stop; summarize → state file; mark COLD |

---

## 8. `/od compress`

1. Archive `03-progress.md` → `03-progress-history.md`
2. Reset WARM: session-log frontmatter + plan active group + design index
3. Clear HOT: SKILL rules + phase instruction header only
4. Log `metrics.json`: `type: "compress"`, hot/warm lines

**Codex**: trigger at 15 turns. After compaction: reset HOT→80, WARM→40; rebuild from state files only.

---

## 9. Backtrack Rule

If Phase N+1 needs missing detail: check state files first → re-read source from project.  
**Forbidden**: scrolling conversation history for tool outputs; loading `*-history.md` full snapshots (except `/od ch` diff).

---

## 10. Config (`config.json`)

| Key | Default | Effect |
|-----|---------|--------|
| `context_mode` | `slim` | slim: aggressive unload |
| `max_hot_lines` | 150 | HOT budget |
| `max_resident_lines` | 300 | HOT+WARM budget |
| `checkpoint_max_lines` | 12 | Checkpoint output cap |
| `codex_max_turns_before_compress` | 15 | Codex compress threshold |

---

→ Integration: SKILL.md B.5/B.18 · [token-optimization.md](token-optimization.md) · [session-memory.md](session-memory.md)
