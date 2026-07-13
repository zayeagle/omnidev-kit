# Interactive Prompt Adapter (Cross-Platform)

**Load when**: any decision point, checkpoint (B.8), B.0 confirmation, skill-composition §4, stash, session resume.

**Principle**: **弹窗交互是 OmniDev 的主要工作模式**（`interactive_mode: true` 默认开启）。Cursor / Claude Code / Codex 在任意协作模式下均 **必须先调用原生交互工具**；仅当工具不在列表中、调用报错或超时后，才在同一 turn 使用伪弹窗文本回退。

→ Platform PAL: SKILL.md §F.2

---

## 0. Primary Mode Declaration

| Platform | Primary (MUST try first) | When |
|----------|--------------------------|------|
| **Cursor** | `AskQuestion` | `interactive_mode=true` — **§4 模板** |
| **Claude Code** | `AskUserQuestion` | **所有模式** — §5 模板 |
| **Codex** | `request_user_input` | **所有模式** — §6 模板（需 feature flag，见 §7） |
| **CLI / Other** | Pseudo-popup text §8 | always |

**Hard rule**: `interactive_mode=true` 时，决策点 **禁止** 仅用 prose 问「是否继续？」而不调用工具。Checkpoint / Phase 摘要（≤6 行）输出后，**同一 turn 必须** 发起原生工具调用。

**Chat cleanliness**（防「输出很乱」）:
1. 对话里只输出 **短摘要**（Phase 0 ≤6 行；checkpoint ≤12 行）
2. 完整评估 / 元数据写入 `session-log.md`，**禁止**把 `od_interactive` / `decision_point` / `platform` 等键值对贴进对话
3. 原生弹窗成功时：**禁止**再输出选项表或伪弹窗
4. 伪弹窗仅在原生失败后出现，且用 §8 干净格式（无 YAML frontmatter）

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
  decision_point: string             // for logging ONLY (session-log), e.g. "phase0_complexity"

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
| **cursor** | `AskQuestion` | **Same turn** — use §4 copy-paste templates. If tool **absent from tool list**, go Step D (do not invent prose options first). |
| **claude_code** | `AskUserQuestion` | **Same turn** — §5 templates |
| **codex** | `request_user_input` | **Same turn** — §6 templates; try even in Default/Code mode |

**On native tool missing, error, timeout, or "unavailable in this chat mode"**: log `prompt_fallback: native_failed` to session-log → Step D immediately (same turn).

**Cursor note**: 部分模型（Composer / Auto / 部分第三方）在 Agent 模式可能不提供 `AskQuestion`。检测方式：当前 turn 的 tool list 是否含 `AskQuestion`。缺失 → §8 伪弹窗 + 一行提示（见 §8）；有工具却跳过调用 = **违规**。

### Step D — Pseudo-Popup Fallback

Use §8 structured pseudo-popup — **干净表格**，无 YAML 元数据块。阻塞决策（B.0 destructive）：**STOP — WAIT**。非阻塞检查点（B.8、Phase 0、resume）：**自动继续默认选项** — 展示表格后立即推进.

### Step E — Minimal Text (interactive_mode=false only)

Numbered list per §9.

---

## 3. Never-Do List

| ❌ Forbidden | ✅ Required |
|-------------|------------|
| Skip prompt because tool "might not work" | **Call tool first** if present; fallback only after missing/error |
| Cursor: dump full Phase 0 assessment + options table in chat | ≤6 行摘要 + `AskQuestion`（或 §8） |
| Cursor: skip `AskQuestion` when tool is in list | **Invoke §4 template** same turn |
| Checkpoint prose only, end turn without tool | Checkpoint + **tool call same turn** |
| Paste `od_interactive:` / `decision_point:` into chat | Log those fields to **session-log only** |
| Tell user to reply bare `1` / `2` / `3` | Always show **`/od …` commands** |
| Assume option 1 without showing options | Show options via tool or pseudo-popup |
| Proceed after tool error | Pseudo-popup §8 same turn |
| Codex: skip `request_user_input` because not Plan mode | Try tool; if unavailable → §8 + document §7 flag |
| Claude: describe options in chat instead of `AskUserQuestion` | **Invoke tool** with §5 template |

---

## 4. Cursor — `AskQuestion` Templates (COPY-PASTE)

**Schema** (match Cursor tool definition; field names may vary slightly by version):

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
1. Output **short** summary only（Phase 0: §2.1 的 ≤6 行；勿贴完整评估）
2. **Immediately** call `AskQuestion` with matching template — **do not end turn without this call** when tool exists
3. **Do not** also print an options table in chat when the tool call succeeds
4. `allow_multiple: true` only when input says so (skill-composition, stash)
5. Map `options[].id` back to workflow routing (`confirm`/`next` → treat as `/od n` intent after UI pick)
6. One `AskQuestion` per assistant message (Cursor limit)

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
  "title": "OmniDev · 复杂度与范围确认",
  "questions": [{
    "id": "phase0_complexity",
    "prompt": "复杂度: {complexity} — {reason_short}。推荐: {phases}。确认？",
    "options": [
      {"id": "confirm", "label": "确认 {complexity} + 推荐范围 [默认] → /od n"},
      {"id": "adjust", "label": "调整复杂度 / 范围 → /od ad"},
      {"id": "cancel", "label": "取消 → /od x"}
    ]
  }]
}
```

**Placeholder values** (fill from Phase 0 §2.1 before invoking):
- `{complexity}`: S / M / L / XL
- `{reason_short}`: ≤40 characters
- `{phases}`: e.g. "Blueprint→Plan→Dev→Test"

### 4.3 Phase 1 — Approach Selection

```json
{
  "title": "OmniDev · 方案选择",
  "questions": [{
    "id": "blueprint_approach",
    "prompt": "请选择技术方案（见上方对比）：",
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

### 4.9 Open Questions — Batch Confirmation

```json
{
  "title": "OmniDev · 开放问题确认",
  "questions": [{
    "id": "open_questions",
    "prompt": "{N} 个开放问题将使用默认值。确认？如需调整请选「逐个调整」。",
    "options": [
      {"id": "accept_defaults", "label": "全部接受默认值 [默认]"},
      {"id": "review_one_by_one", "label": "逐个调整"},
      {"id": "cancel", "label": "取消"}
    ]
  }]
}
```

**Usage**: Output open questions table as prose **first**, then invoke this template same turn.

---

## 5. Claude Code — `AskUserQuestion` Templates (COPY-PASTE)

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

### 5.1 Phase Checkpoint (B.8)

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

### 5.2 Phase 0 — Complexity Confirmation

```json
{
  "title": "OmniDev · 复杂度确认",
  "questions": [{
    "id": "phase0_complexity",
    "prompt": "复杂度: {complexity} — {reason_short}。推荐: {phases}。确认？",
    "options": [
      {"id": "confirm", "label": "确认复杂度与阶段 [默认]"},
      {"id": "adjust", "label": "调整复杂度 / 跳过阶段"},
      {"id": "cancel", "label": "取消"}
    ]
  }]
}
```

**Placeholder values**: same as Cursor §4.2.

### 5.3 Phase 1 — Approach Selection

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

### 5.4 Resume — `/od re`

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

### 5.5 Resume with Payload — `/od re [xxx]`

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

### 5.6 Change Impact — `/od ch`

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

### 5.7 B.0 — Destructive / Critical Confirmation

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

### 5.8 Skill Composition — Multi-Select

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

### 5.9 Open Questions — Batch Confirmation

```json
{
  "title": "OmniDev · 开放问题确认",
  "questions": [{
    "id": "open_questions",
    "prompt": "{N} 个开放问题将使用默认值。确认？如需调整请选「逐个调整」。",
    "options": [
      {"id": "accept_defaults", "label": "全部接受默认值 [默认]"},
      {"id": "review_one_by_one", "label": "逐个调整"},
      {"id": "cancel", "label": "取消"}
    ]
  }]
}
```

**Usage**: Output the open questions table (from Phase 1 §4) as prose in chat **first**, then invoke this template same turn. If user selects "逐个调整", re-invoke as sequential single-question prompts.

`{N}` = number of open questions.

---

## 6. Codex — `request_user_input` Templates (COPY-PASTE)

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

### 6.1 Phase Checkpoint (B.8)

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

### 6.2 Phase 0 — Complexity

```json
{
  "questions": [{
    "header": "OmniDev · 复杂度确认",
    "question": "复杂度: {complexity} — {reason_short}。推荐: {phases}。确认？",
    "options": [
      {"label": "确认复杂度与阶段 [默认]"},
      {"label": "调整复杂度 / 跳过阶段"},
      {"label": "取消"}
    ]
  }],
  "autoResolutionMs": 120000
}
```

**Placeholder values**: same as Cursor §4.2.

### 6.3 Resume / Change / B.0

Use same option labels as Claude §5.4–§5.7; replace `header` / `question` accordingly. B.0 templates: **no** `autoResolutionMs`.

### 6.4 Multi-Select (Codex has no native multi-select)

**Option A** — sequential single-select:
1. First prompt: "是否启用额外技能？" → Yes / No
2. If Yes → second prompt listing skills (single) OR use pseudo-popup §8 with comma-separated instruction

**Option B** — pseudo-popup §8 with `可多选，逗号分隔完整命令`

### 6.5 Open Questions — Batch Confirmation

```json
{
  "questions": [{
    "header": "OmniDev · 开放问题确认",
    "question": "{N} 个开放问题将使用默认值。确认？如需调整请选「逐个调整」。",
    "options": [
      {"label": "全部接受默认值 [默认]"},
      {"label": "逐个调整"},
      {"label": "取消"}
    ]
  }],
  "autoResolutionMs": 120000
}
```

**Usage**: Output the open questions table as prose **first**, then invoke this template same turn.

---

## 7. Codex Setup — Enable Popup in Default/Code Mode

OmniDev **requires** popup in all Codex modes. On first `/od` activation when platform=codex:

1. If `request_user_input` call returns unavailable → output **once per session**:

   ```markdown
   💡 **Codex 弹窗提示**：当前 Default/Code 模式未启用 `request_user_input`。
   请在 `~/.codex/config.toml` 添加：
   [features]
   default_mode_request_user_input = true
   然后重启 Codex。本次使用伪弹窗文本继续。
   ```

2. Continue with §8 pseudo-popup — **do not block workflow**

3. Log to session-log `## 关键决策`: `codex_popup: pseudo_fallback (flag not enabled)`

Document in project `docs/omnidev-state/config.json` note field optional:

```json
"codex_popup_hint_shown": true
```

---

## 8. Pseudo-Popup Fallback (§E) — Clean UX

When native tool fails or unavailable, use this **clean** format. **禁止**输出 YAML/`od_interactive:` 元数据块到对话（那些只写 session-log）。

```markdown
## OmniDev · [title_zh]

| 选项 | 下一条消息发送 |
|------|----------------|
| [选项A] [默认] | `/od n` |
| [选项B] | `/od ad` |
| 取消 | `/od x` |

> 请发送上表中的 **完整 `/od` 命令**。裸序号 `1` / `2` / `3` **无效**。
```

若因 Cursor 无 `AskQuestion` 工具而回退，在表格下追加一行（仅一次）：

```markdown
> 💡 当前模型可能无原生弹窗（AskQuestion）。可换 Claude/GPT，或改用 Plan 模式。
```

Multi-select: `> 可多选：下一条消息发送多个命令，或说明要启用的项`

**Rules**:
- ≤6 options + cancel
- Mark `[默认]` on recommended
- **阻塞决策（B.0 destructive）→ STOP — WAIT**；**非阻塞检查点（B.8、Phase 0、resume）→ 自动继续默认选项**
- Same visual structure every time
- **Never** say「回复 1 / 2 / 3」
- **Never** dump Requirement Analysis / Stability / Test Strategy into this block

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

Append to `session-log.md` or metrics event when prompt shown (**not** to chat):

```json
{"type":"interactive_prompt","method":"cursor_ask|claude_ask|codex_input|pseudo_popup|text_fallback","platform":"cursor","decision_point":"phase0_complexity","native_attempted":true}
```

If native failed: `"native_error": true, "error_hint": "tool_absent|unavailable in chat mode"`.

---

## 11. Platform Quick Reference

| Platform | Primary | Fallback | Setup |
|----------|---------|----------|-------|
| Cursor | `AskQuestion` §4 | pseudo-popup §8 | 若无工具：换模型或 Plan 模式 |
| Claude Code | `AskUserQuestion` §5 | pseudo-popup §8 | — |
| Codex | `request_user_input` §6 | pseudo-popup §8 | `default_mode_request_user_input=true` |
| CLI | pseudo-popup §8 | text §9 | — |

**弹窗不触发**:
1. `interactive_mode: true`？
2. Cursor: tool list 有 `AskQuestion` 却未调用 → **违规**，应调 §4；无工具 → §8 + 换模型提示
3. Claude: 必须 invoke §5，禁止只写选项
4. Codex: enable §7 flag → else §8
