# Context Occupancy Protocol

→ Platform mapping: SKILL.md §F (Platform Abstraction Layer)
 (上下文占用控制)

**Load on**: every `/od` activation, phase transitions, `/od compress`, `/od re`.

**Distinction from token-optimization.md**: Token 优化关注总消耗（Sub-Agent、工具、历史）；**本协议关注同一时刻窗口内「驻留内容」体积**。

**Hard target**: **Hot context ≤150 lines** · **Warm context ≤250 lines** · **Total resident ≤300 lines** (excluding current user message).

---

## 1. Three-Layer Model

```
┌─────────────────────────────────────────────────────────┐
│  HOT  (≤150 lines) — 当前 turn 执行任务必需              │
│  SKILL 核心规则摘要 · 当前 phase 指令 · 当前 task 切片   │
├─────────────────────────────────────────────────────────┤
│  WARM (≤250 lines) — 本阶段可复用，阶段结束卸载          │
│  02-plan 当前 Group · 04-design index · session 决策 3条 │
├─────────────────────────────────────────────────────────┤
│  COLD — 仅在磁盘，按需 Read 切片，禁止常驻               │
│  features/*.md · 05-test-plan 其他 feature · 历史对话    │
│  已完成 phase 指令 · 工具 raw 输出 · 01-blueprint 全文   │
└─────────────────────────────────────────────────────────┘
```

| Layer | 进入方式 | 离开方式 |
|-------|---------|---------|
| **HOT** | 当前 task 必需 | task 完成 → 卸载 feature 切片 |
| **WARM** | phase 入口 Read frontmatter + active section | phase exit → 卸载，只留 ≤5 行 transition summary |
| **COLD** | 显式 `Read offset/limit` 或 `Grep` | 读后立即摘要到 state file，标记 expired |

**Golden rule**: 磁盘有 state file → **禁止**在对话中重复粘贴其全文；用路径指针代替（例："见 `features/F2.md` step 2"）。

---

## 2. Config (`config.json`)

| Key | Default | Effect |
|-----|---------|--------|
| `context_mode` | `"slim"` | `slim` / `standard` — slim 启用更激进卸载 |
| `max_hot_lines` | `150` | HOT 层行数上限 |
| `max_resident_lines` | `300` | HOT+WARM 合计上限 |
| `checkpoint_max_lines` | `12` | Checkpoint 输出上限 |
| `00_context_sections` | auto | 按 phase 加载 project-context 切片（§4） |

---

## 3. Per-Phase Hot/Warm Manifest

### Phase 0

| Layer | Content | Max lines |
|-------|---------|-----------|
| HOT | Phase 0 指令 + 扫描结论摘要 | 80 |
| WARM | — | 0 |
| COLD | package.json/go.mod 全文 | — |

### Phase 1

| HOT | 指令 + 方案对比表（≤2 方案 for M） | 100 |
| WARM | 用户已选方案 + 假设表 | 40 |
| COLD | 源码 scan raw、01-blueprint 草稿过程 | — |

### Phase 2

| HOT | 指令 + 当前正在写的 1 个 feature 模板 | 120 |
| WARM | 04-design index | 60 |
| COLD | 其他 features/*.md、scan raw | — |

### Phase 3

| HOT | 指令 + 02-plan **当前 Group 段落** + 1×features/FN.md | 150 |
| WARM | 04-design index + 03-progress snapshot（3 task） | 80 |
| COLD | 05-test-plan、01-blueprint、已完成 Group、git diff 全文 | — |

### Phase 4

| HOT | 指令 + **当前 layer** 测试表 + 1 个 TC 执行结果 | 120 |
| WARM | Test Strategy Summary + gate status + smoke 汇总 | 60 |
| COLD | 其他 layer/feature 表、coverage raw、E2E trace、test log | — |

### Phase 5

| HOT | 指令 + deploy checklist | 80 |
| WARM | 05-test-report 摘要（§1 only） | 40 |
| COLD | 全量 test plan、源码 | — |

---

## 4. Section-Level Loading (`00-project-context.md`)

Never load full file if >60 lines. Read by phase:

| Phase | Sections to load |
|-------|------------------|
| 0 | `Stack & Layers`, `Dependency Topology` |
| 1 | + `Architecture Patterns` |
| 2 | + `Domain Knowledge` (last 15 lines only) |
| 3 | `Stack & Layers`, `AI Pitfall Guide`, `Stability Level` |
| 4 | `AI Pitfall Guide`, test conventions, `Test Strategy Summary` from plan |
| 5 | `Stack & Layers`, deploy-relevant topology |

Use `Grep` with section header or `Read offset/limit`.

---

## 5. `02-plan.md` — Group-Scoped Loading

Phase 3/4 MUST NOT load full plan if >80 lines:

1. Read YAML frontmatter (always)
2. Read **only** `## Group N` matching `last_task_group` from session-log
3. Read Traceability row for active group only
4. Reload plan frontmatter + next group on group complete

---

## 6. Conversation History Discipline

### 6.1 Forbidden in assistant messages

- Pasting state file contents already on disk
- Repeating Read/Grep/Shell output verbatim after summary written
- Checkpoint blocks > `checkpoint_max_lines`
- Quoting earlier phase instruction text

### 6.2 Required patterns

| Instead of | Use |
|------------|-----|
| 500-line design dump | "F2 设计见 `features/F2.md`，入口 route `/api/user`" |
| Full test results | 表格 3 列：TC-ID / Result / Note |
| Long Pre-Dev Scope | 表格 ≤15 行 + "确认？" |
| Phase progress essay | 标准 4 行 checkpoint 模板（§7） |

### 6.3 Turn budget

| Threshold | Action |
|-----------|--------|
| 15 turns in same phase | 输出 3 行阶段摘要 → 建议 `/od compress` |
| 25 turns total | **必须** `/od compress` 或 `/od x` 新会话 |
| 3+ consecutive Read same file | 停止；摘要写入 state；标记 COLD |

---

## 7. Checkpoint Output (≤12 lines)

```
✅ Phase N: [Name]
📦 [file1, file2]
📍 P0✅ P1⏭ P2✅ P3🔄
🔔 Next: Phase N+1
[Platform interactive prompt (§F.2): 2-4 options]
```

No progress essay. No file content echo.

---

## 8. Phase Transition Purge (MANDATORY)

On every phase exit, **before** loading next phase:

```
PURGE list (stop retaining in working memory):
□ Previous phase instruction file
□ All tool raw outputs from previous phase
□ features/FN.md not in next task
□ 05-test-plan sections not under test
□ Solution comparison / approach B text
□ Transition summaries older than 1 phase

RETAIN (≤5 lines written to session-log or stated once):
□ User decisions not yet in state files
□ Active blockers
```

Then load next phase per §3 manifest only.

---

## 9. `/od compress` — Context Occupancy Edition

In addition to progress archive to `03-progress-history.md` ([special-flows.md](special-flows.md) §4, [document-history.md](document-history.md)):

1. Output **Context Occupancy Report** (≤8 lines):

   ```
   📊 Context Occupancy
   HOT: ~N lines (budget 150)
   WARM: ~N lines (budget 250)
   Purged: [list categories]
   Reload from: [state file paths if needed]
   ```

2. Reset WARM to: session-log frontmatter + 02-plan active group + 04-design index
3. Clear HOT except: SKILL rules + current phase instruction header
4. Log `metrics.json` event: `type: "compress"`, `hot_lines_before`, `hot_lines_after`

---

## 10. `/od re` — Cold Start

Max resident on resume: **200 lines** (stricter than session-memory §8):

1. session-log YAML + 恢复指引（≤20 lines）
2. Active phase instruction
3. 02-plan frontmatter + active group ONLY
4. 03-progress blockers section ONLY
5. 04-design index ONLY
6. **Skip** 00-project-context until phase needs it (load §4 slice on first use)

Do NOT replay prior conversation. User decisions come from session-log + state files only.

---

## 11. Platform-Specific Occupancy Rules

### 11.1 Codex — Compaction Coexistence

Codex performs automatic context compaction. To avoid conflicts with OmniDev occupancy controls:

| Rule | OmniDev default | Codex adjustment |
|------|----------------|------------------|
| HOT budget | 150 lines | 150 lines (unchanged) |
| WARM budget | 250 lines | 250 lines (unchanged) |
| Turn-based compress trigger | 25 turns | **15 turns** (stay ahead of Codex compaction) |
| Phase purge (§8) | Full purge on phase exit | Full purge; assume all non-state-file context is lost after compaction |
| `/od compress` scope | Progress archive + occupancy report + purge | Progress archive only; skip occupancy report (line counts unreliable). Codex handles its own compaction. |
| After compaction event | N/A | Reset HOT to 80, WARM to 40 (defensive defaults). Rebuild from state files only. |
| `/od re` cold start | ≤200 lines | ≤200 lines; same as standard. `session-log.md` YAML frontmatter is the authoritative state source. |

**Codex rule**: There is no event signal for "compaction just happened." If context appears truncated, summaries are present, or tool outputs reference earlier work that the model can't recall → assume compaction occurred. Defensively reload from state files.

### 11.2 Platform Config

| Key | Default | Effect |
|-----|---------|--------|
| `codex_conservative_occupancy` | `true` | Enable Codex-specific defensive occupancy rules |
| `codex_max_turns_before_compress` | `15` | Turn-based compress threshold for Codex |

---

## 12. Integration

- [context-protocol.md](context-protocol.md) §12 — occupancy guards
- [token-optimization.md](token-optimization.md) — tool output caps
- SKILL.md B.18 — activation rule
- SKILL.md §F.8 — Codex compaction awareness
- Phase files — `context_occupancy` yaml block
