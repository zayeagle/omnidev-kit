# Interactive Prompt Adapter (Cross-Platform)

**Load when**: any decision point, checkpoint (B.8), B.0 confirmation, skill-composition §4, stash, session resume.

**Principle**: **弹窗交互是 OmniDev 的主要工作模式**（`interactive_mode: true` 默认开启）。Claude Code 与 Codex 在任意协作模式下均 **必须先调用原生交互工具**；仅当工具不可用或调用失败时，才在同一 turn 使用伪弹窗文本回退。

→ Platform PAL: SKILL.md §F.2

---

## 0. Primary Mode Declaration

| Platform | Primary (MUST try first) | When |
|----------|--------------------------|------|
| **Cursor** | `AskQuestion` | `interactive_mode=true` |
| **Claude Code** | `AskUserQuestion` | **所有模式** — Default / Plan / 任意协作模式 |
| **Codex** | `request_user_input` | **所有模式** — Plan / Default / Code（需 feature flag，见 §C.1） |
| **CLI / Other** | Pseudo-popup text §E | always |

**Hard rule**: `interactive_mode=true` 时，决策点 **禁止** 仅用 prose 问「是否继续？」而不调用工具。Checkpoint 摘要（≤12 行）输出后，**同一 turn 必须** 发起工具调用。

---

## 1. Entry: `present_options(options, config)`

Every engine file saying "use platform interactive prompt" or legacy "AskQuestion" MUST call this logic:

```
INPUT:
  options: [{id, label_zh, label_en?, default?}, ...]  // 2-6 items
  config: {interactive_mode, platform_override}
  title_zh: string                    // e.g. "OmniDev · Phase 2 检查点"
  allow_multiple: bool (default false)
  blocking: bool (default true for B.0 delete/deploy)
  decision_point: string             // for logging, e.g. "phase0_complexity"

OUTPUT:
  selected: id | [ids] | null (cancel)
  method: cursor_ask | claude_ask | codex_input | pseudo_popup | text_fallback
```

---

## 2. Resolution Order (try in sequence, same turn)

### Step A — Check `interactive_mode`

| `interactive_mode` | Behavior |
|--------------------|----------|
| `false` | Skip to **Step E** (minimal text) — user opted out via `/od cfg -i off` |
| `true` | Continue Step B — **primary popup mode** |

### Step B — Resolve platform

Use `config.platform_override` or SKILL.md §F.1 / activation.md §2 detection.

### Step C — Native UI (MANDATORY attempt when interactive_mode=true)

| Platform | Tool | Invocation rule |
|----------|------|-----------------|
| **cursor** | `AskQuestion` | Same turn as checkpoint; Chinese `label`; `allow_multiple` for multi-select |
| **claude_code** | `AskUserQuestion` | **Same turn, tool call required** — use §4 copy-paste templates |
| **codex** | `request_user_input` | **Same turn, tool call required** — use §5 copy-paste templates; try even in Default/Code mode |

**On native tool error, timeout, or "unavailable in this chat mode"**: log `prompt_fallback: native_failed` → Step D immediately (same turn).

### Step D — Pseudo-Popup Fallback (Codex / Claude when native fails)

Use §E structured pseudo-popup — visually接近弹窗，带标题、选项表、默认标记。**STOP — WAIT**.

### Step E — Minimal Text (interactive_mode=false only)

Numbered list per legacy §F.2 CLI pattern.

---

## 3. Never-Do List

| ❌ Forbidden | ✅ Required |
|-------------|------------|
| Skip prompt because tool "might not work" | **Call tool first**; fallback only after error |
| Checkpoint prose only, end turn without tool | Checkpoint + **tool call same turn** |
| Assume option 1 without showing options | Show options via tool or pseudo-popup |
| Proceed after tool error | Pseudo-popup §E same turn |
| Codex: skip `request_user_input` because not Plan mode | Try tool; if unavailable → §E + document §C.1 flag |
| Claude: describe options in chat instead of `AskUserQuestion` | **Invoke tool** with §4 template |

---

## 4. Claude Code — `AskUserQuestion` Templates (COPY-PASTE)

**Schema** (match platform tool definition):

```json
{
  "title": "<title_zh>",
  "questions": [{
    "id": "<question_id>",
    "prompt": "<prompt_zh>",
    "options": [
      {"id": "<option_id>", "label": "<label_zh>"}
    ],
    "allow_multiple": false
  }]
}
```

**Invocation contract**:
1. Output checkpoint summary (≤12 lines) in assistant text **first**
2. **Immediately** call `AskUserQuestion` with matching template below — **do not end turn without this call**
3. `allow_multiple: true` only when `allow_multiple` input is true (skill-composition, stash)
4. Map `options[].id` back to workflow routing (`next` → `/od n`, etc.)

---

### 4.1 Phase Checkpoint (B.8)

```json
{
  "title": "OmniDev · 阶段检查点",
  "questions": [{
    "id": "checkpoint_next",
    "prompt": "Phase [N] 已完成。请选择下一步：",
    "options": [
      {"id": "next", "label": "继续下一阶段 (/od n)"},
      {"id": "revise", "label": "修订当前产出 (/od ad)"},
      {"id": "help", "label": "查看命令 (/od h)"},
      {"id": "cancel", "label": "取消 (/od x)"}
    ]
  }]
}
```

### 4.2 Phase 0 — Complexity Confirmation

```json
{
  "title": "OmniDev · 复杂度确认",
  "questions": [{
    "id": "phase0_complexity",
    "prompt": "请确认需求复杂度与推荐阶段：",
    "options": [
      {"id": "confirm", "label": "确认复杂度与阶段 [默认]"},
      {"id": "adjust", "label": "调整复杂度 / 跳过阶段"},
      {"id": "cancel", "label": "取消"}
    ]
  }]
}
```

### 4.3 Phase 1 — Approach Selection

```json
{
  "title": "OmniDev · 方案选择",
  "questions": [{
    "id": "blueprint_approach",
    "prompt": "请选择技术方案（见上方对比表）：",
    "options": [
      {"id": "approach_a", "label": "方案 A: [名称]"},
      {"id": "approach_b", "label": "方案 B: [名称]"},
      {"id": "approach_c", "label": "方案 C: [名称]（如有）"},
      {"id": "revise", "label": "重新分析需求"}
    ]
  }]
}
```

### 4.4 Resume — `/od re`

```json
{
  "title": "OmniDev · 恢复会话",
  "questions": [{
    "id": "resume_action",
    "prompt": "检测到未完成任务。如何继续？",
    "options": [
      {"id": "continue", "label": "继续上次进度 [默认]"},
      {"id": "restart", "label": "重新开始"},
      {"id": "cancel", "label": "取消"}
    ]
  }]
}
```

### 4.5 Resume with Payload — `/od re [xxx]`

```json
{
  "title": "OmniDev · 恢复并处理变更",
  "questions": [{
    "id": "resume_payload",
    "prompt": "Payload: [摘要]。请选择处理方式：",
    "options": [
      {"id": "resume_execute", "label": "从断点继续并处理 payload [默认]"},
      {"id": "change_full", "label": "先走变更流程更新文档 (/od ch)"},
      {"id": "restart", "label": "payload 作为新需求，从 Phase 0 开始"},
      {"id": "cancel", "label": "取消"}
    ]
  }]
}
```

### 4.6 Change Impact — `/od ch`

```json
{
  "title": "OmniDev · 需求变更",
  "questions": [{
    "id": "change_confirm",
    "prompt": "变更影响见上方报告。是否继续同步文档？",
    "options": [
      {"id": "proceed", "label": "继续同步 [默认]"},
      {"id": "revise", "label": "修改变更描述"},
      {"id": "cancel", "label": "取消"}
    ]
  }]
}
```

### 4.7 B.0 — Destructive / Critical Confirmation

```json
{
  "title": "OmniDev · 确认操作",
  "questions": [{
    "id": "b0_confirm",
    "prompt": "[具体操作描述]。此操作不可轻易撤销。",
    "options": [
      {"id": "yes", "label": "确认执行"},
      {"id": "no", "label": "不执行 [默认]"},
      {"id": "clarify", "label": "需要更多说明"}
    ]
  }]
}
```

**No `autoResolutionMs`** — blocking; omit timeout behavior.

### 4.8 Skill Composition — Multi-Select

```json
{
  "title": "OmniDev · 选择技能",
  "questions": [{
    "id": "skill_select",
    "prompt": "发现以下技能，请选择要启用的（可多选）：",
    "options": [
      {"id": "skill_1", "label": "[skill-name]: [description]"},
      {"id": "skill_2", "label": "[skill-name]: [description]"},
      {"id": "none", "label": "不使用额外技能"}
    ],
    "allow_multiple": true
  }]
}
```

---

## 5. Codex — `request_user_input` Templates (COPY-PASTE)

**Availability**: Plan mode always (when tool in list). **Default / Code mode** requires user enable:

```toml
# ~/.codex/config.toml
[features]
default_mode_request_user_input = true
```

Or CLI: `codex features enable default_mode_request_user_input` — restart Codex after change.

**Schema** (adapt field names to tool definition if different):

```json
{
  "questions": [{
    "header": "<title_zh>",
    "question": "<prompt_zh>",
    "options": [
      {"label": "<label_zh>"}
    ]
  }],
  "autoResolutionMs": 120000
}
```

**Invocation contract**:
1. Checkpoint summary (≤12 lines) in text **first**
2. **Same turn** call `request_user_input` — **never skip** because "not Plan mode"; try always when tool exists
3. Map selected `options[].label` index back to option `id` from §1 input
4. **Blocking** (B.0, Pre-Dev L/XL): **omit** `autoResolutionMs`
5. **Non-blocking** (B.8, skill select): `autoResolutionMs`: 60000–240000

---

### 5.1 Phase Checkpoint (B.8)

```json
{
  "questions": [{
    "header": "OmniDev · 阶段检查点",
    "question": "Phase [N] 已完成。请选择下一步：",
    "options": [
      {"label": "继续下一阶段 (/od n)"},
      {"label": "修订当前产出 (/od ad)"},
      {"label": "查看命令 (/od h)"},
      {"label": "取消 (/od x)"}
    ]
  }],
  "autoResolutionMs": 120000
}
```

### 5.2 Phase 0 — Complexity

```json
{
  "questions": [{
    "header": "OmniDev · 复杂度确认",
    "question": "请确认需求复杂度与推荐阶段：",
    "options": [
      {"label": "确认复杂度与阶段 [默认]"},
      {"label": "调整复杂度 / 跳过阶段"},
      {"label": "取消"}
    ]
  }],
  "autoResolutionMs": 120000
}
```

### 5.3 Resume / Change / B.0

Use same option labels as Claude §4.4–§4.7; replace `header` / `question` accordingly. B.0 templates: **no** `autoResolutionMs`.

### 5.4 Multi-Select (Codex has no native multi-select)

**Option A** — sequential single-select:
1. First prompt: "是否启用额外技能？" → Yes / No
2. If Yes → second prompt listing skills (single) OR use pseudo-popup §E with comma-separated instruction

**Option B** — pseudo-popup §E with `可多选，逗号分隔序号`

---

## 6. Standard Option Sets (id → label_zh)

### Phase checkpoint (B.8)

| id | label_zh |
|----|----------|
| `next` | 继续下一阶段 (`/od n`) |
| `revise` | 修订当前产出 (`/od ad`) |
| `help` | 查看命令 (`/od h`) |

Always include `cancel` → `/od x`.

### Phase 0 complexity

| id | label_zh |
|----|----------|
| `confirm` | 确认复杂度与阶段 |
| `adjust` | 调整复杂度/跳过阶段 |
| `cancel` | 取消 |

### Resume (`/od re`)

| id | label_zh |
|----|----------|
| `continue` | 继续上次进度 |
| `restart` | 重新开始 |
| `cancel` | 取消 |

### Resume with payload (`/od re [xxx]`)

| id | label_zh |
|----|----------|
| `resume_execute` | 从断点继续并处理 payload [默认] |
| `change_full` | 先走变更流程更新文档 |
| `restart` | payload 作为新需求，从 Phase 0 开始 |
| `cancel` | 取消 |

---

## 7. Codex Setup — Enable Popup in Default/Code Mode (§C.1)

OmniDev **requires** popup in all Codex modes. On first `/od` activation when platform=codex:

1. If `request_user_input` call returns unavailable → output **once per session**:

   ```markdown
   💡 **Codex 弹窗提示**：当前 Default/Code 模式未启用 `request_user_input`。
   请在 `~/.codex/config.toml` 添加：
   [features]
   default_mode_request_user_input = true
   然后重启 Codex。本次使用伪弹窗文本继续。
   ```

2. Continue with §E pseudo-popup — **do not block workflow**

3. Log to session-log `## 关键决策`: `codex_popup: pseudo_fallback (flag not enabled)`

Document in project `docs/omnidev-state/config.json` note field optional:

```json
"codex_popup_hint_shown": true
```

---

## 8. Pseudo-Popup Fallback (§E) — Near-Native UX

When native tool fails or unavailable, use this **structured format** (not plain prose):

```markdown
---
od_interactive: pseudo_popup
decision_point: [phase_checkpoint|phase0_complexity|...]
platform: [codex|claude_code|cli_other]
---

## 🔘 [title_zh]

| # | 选项 | 命令 |
|---|------|------|
| 1 | [选项A] [默认] | `/od n` |
| 2 | [选项B] | `/od ad` |
| 3 | [选项C] | `/od h` |
| 4 | 取消 | `/od x` |

> **请选择**：点击选项，或在**下一条消息**输入完整 `/od` 命令（如 `/od n`）。裸序号 `1` 不会触发流程。
> 平台: [platform] · 模式: pseudo_popup（原生弹窗不可用）
```

Multi-select add row: `> 可多选：回复 `1,3` 或逗号分隔序号`

**Rules**:
- ≤6 options + cancel
- Mark `[默认]` on recommended
- **STOP — WAIT** after output (blocking=true)
- Same visual structure every time — user learns one pattern

---

## 9. Minimal Text (interactive_mode=false only)

```markdown
请选择（须用完整 `/od` 命令，裸序号无效）：

1. [选项A] [默认] → `/od n`
2. [选项B] → `/od ad`
3. 取消 → `/od x`
```

---

## 10. Logging

Append to `session-log.md` or metrics event when prompt shown:

```json
{"type":"interactive_prompt","method":"claude_ask|codex_input|pseudo_popup|text_fallback","platform":"claude_code","decision_point":"phase0_complexity","native_attempted":true}
```

If native failed: `"native_error": true, "error_hint": "unavailable in chat mode"`.

---

## 11. Platform Quick Reference

| Platform | Primary | First fallback | Last resort |
|----------|---------|----------------|-------------|
| Cursor | `AskQuestion` | Pseudo-popup §E | Text §9 |
| Claude Code | `AskUserQuestion` §4 | Pseudo-popup §E | Text §9 |
| Codex (all modes) | `request_user_input` §5 | Pseudo-popup §E | Text §9 |
| CLI / Other | Pseudo-popup §E | Text §9 | — |

**User report "弹窗不触发"**:
1. Verify `interactive_mode: true` (`/od cfg`)
2. Claude: agent must **call** `AskUserQuestion` — not describe it
3. Codex: enable `default_mode_request_user_input` (§7)
4. If still failing: pseudo-popup §E is correct fallback — ensure structured table appears
