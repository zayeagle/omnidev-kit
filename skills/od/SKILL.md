---
name: od
description: >-
  OmniDev AI-driven development workflow. Use ONLY when the user's message starts with /od
  (e.g. /od h, /od re, /od ob, /od rp, /od rv, /od qa, /od ch, /od ln, /od gv).
  Do not load or follow this skill for normal chat without the /od prefix.
---

# OmniDev Workflow Skill — Full Specification

This file is the **single source of truth** for all OmniDev rules. **Everything below applies only when the current user message starts with `/od`**. No OmniDev behavior on non-`/od` turns.

---

## A. Command Reference (On-Demand)

**DO NOT read the command table into context on every activation.**

- Full reference: `engine/commands.md`. Load ONLY on `/od h` or `/od help`.
- For all other commands, route from rules below — no need for the full table.

---

## B. Core Rules

### B.0 First Principle — 不确定就问，禁止自我发挥

**最高优先级规则，贯穿所有 phase。任何规则与此冲突时，以此条为准。**

凡遇到**不确定、有歧义、有多种可能**的情况，**一律停下来问用户确认**。禁止自我发挥。

**典型场景**：需求模糊→问确认；多种技术方案→列出让用户选；代码风格不确定→查 user-preferences 或问；删改现有代码→说明理由问确认。

**执行方式**：`interactive_mode=true` 用 AskQuestion；`false` 用文字提问。问完 **STOP — WAIT**。

**判断标准**：如果你需要说"我假设/猜测/应该是/大概是…"——停下来问。

**需求阶段应用**：需求模糊/关键信息缺失时，必须确认核心诉求、最终目标、交付效果、本质问题后才可执行。

**修复阶段应用**：Bug/Security Fix 禁止直接发补丁。必须：诊断根因→输出方案（含影响范围+回归风险）→多方案择优→等用户确认后再修复。

### B.1 Activation & Tool Execution
- OmniDev activates **only** on `/od` prefix.
- First action on any `/od` message MUST be a tool call — zero text before tools.
- Ad-hoc requests (e.g. `/od 这里加个按钮`) → find file, edit, apply directly.
- Image attachments: tool calls FIRST, then explain.

### B.2 Workflow Philosophy
- Phase order: **Blueprint → Plan → Dev → Test → Deploy**. Forward only, any phase skippable.
- Complexity (S/M/L/XL) provides recommendations, not mandates.

### B.3 State File Isolation
- Global: `docs/omnidev-state/` (`00-project-context.md`, `metrics.json`, `config.json`, `user-preferences.md`)
- Branch: `docs/omnidev-state/[branch]/` (`01-blueprint.md` ~ `06-release-notes.md`, `session-log.md`)
- Stash: `docs/omnidev-state/stash/`

### B.4 Interactive Quick-Select

At every decision point, use **AskQuestion** (when `interactive_mode=true`) to present 2-4 concise choices.

- All labels use Chinese. User can always reply with any `/od` command directly.
- When `interactive_mode=false`: brief text prompt.

### B.5 Context Lifecycle Management (加载 / 摘要 / 卸载)

**核心原则**: 通过 "少读 + 摘要替代 + 沉淀后卸载" 控制上下文膨胀。

#### B.5.1 按需加载 (Load)
- 只读 `context_requires` 声明的文件；不在列表中的不读。
- 跳过不存在的文件；禁止预读下游产物。
- 扫描需 `scan:` 授权；结果超 `scan_limit` 只取前 N 条。

#### B.5.2 摘要替代 (Summarize-then-discard)

| Tool Output Type | Rule |
|-----------------|------|
| Read > 100 lines | Extract key info (signatures, interfaces, config), reference summary only |
| Grep/Glob > 20 matches | Keep top 10 relevant, note "N more omitted" |
| Shell > 50 lines | Extract errors/stats/final state, discard process logs |
| git diff > 30 files | Group by directory, show top 20 details only |

#### B.5.3 沉淀后卸载 & 转场协议

**详细的卸载规则、依赖链、转场协议在 `engine/context-protocol.md`**。仅在 Phase 转场时加载。

核心要点：
- 卸载 = 信息从对话历史转移到 state file，后续 phase 可重新读取。
- State files 永不卸载；用户决策永不丢弃。
- 不确定是否后续需要 → 保留。

### B.6 Configuration (`config.json`)

```json
{
  "interactive_mode": true,
  "ask_mode_after_od": true,
  "update_source_url": "https://github.com/zayeagle/omnidev-kit.git"
}
```

- `/od cfg` — display config. `/od cfg -i on|off` — toggle interactive mode.
- On first `/od` activation: read `docs/omnidev-state/config.json` if exists; else assume defaults.

### B.7 Interactive Mode Decision Points

When `interactive_mode=true`, use AskQuestion at:

| Decision Point | Action |
|----------------|--------|
| Phase 0: Complexity Assessment | Confirm rating; select phases |
| Phase Checkpoint | 2-4 next actions (B.8) |
| Phase 3: Pre-Dev Scope | Confirm / adjust / cancel |
| Phase 3: Post-Dev Impact | Confirm / modify / pause |
| `/od ch` Change Mgmt | Proceed / revise / cancel |
| B.14 Doc Sync Report | Confirm sync results / adjust / redo |
| `/od ps` Push | Commit / edit message / cancel |
| `/od ln` Learning | Adopt / reject / adjust |

### B.8 Next-Step Prompt (下一步提示)

When `ask_mode_after_od=true`: after every `/od` command completes, use AskQuestion to present **2-4 most contextually relevant** next actions.

**原则**: 不展示全部命令列表。根据当前状态（剩余阶段、未提交变更、任务复杂度）推断最合理的下一步。Option label 格式：`[说明] (/od [alias])`。

- `/od gv` 默认不作为常规选项（仅用户明确提及治理/成本时展示）。
- When `ask_mode_after_od=false`: skip next-step prompt entirely.
- Loop: 用户选择→执行→再展示；输入 `/od x`→关闭。

### B.9 Dynamic Skill Composition (On-Demand)

**DO NOT load by default.** File: `engine/skill-composition.md`.

Load ONLY when user message matches troubleshooting keywords:
`报错`, `异常`, `exception`, `error`, `failed`, `crash`, `排查`, `troubleshoot`, `debug`, `diagnose`, `fix`, `hotfix`, `修复`, `修bug`, `漏洞`, `查日志`, `log`, `OOM`, `timeout`, `超时`, `Pod`, `K8s`, `部署失败`

### B.10 Session Memory (会话记忆)

- Rules: `engine/session-memory.md`. Load on `/od x` and `/od re`. (Stash uses `engine/stash.md` which internally references session-log format.)
- Write: on `/od x` (session end), silently alongside closing summary.
- Read: on `/od re`, MUST read session-log for recovery context.
- Protection: if `status: in_progress` exists on same branch, warn user.

### B.11 User Preferences (用户偏好)

- File: `docs/omnidev-state/user-preferences.md` (global, ≤30 lines).
- Load: with `config.json` on every `/od` activation (overhead negligible).
- Collect passively: same signal 2+ times → write. Silent, no prompt.
- Scope: phase skip patterns, code style, verbosity, tech stack, language preferences.

### B.12 Stash & Pop

- Rules: `engine/stash.md`. Load ONLY on `/od st` or `/od po`.
- Storage: `docs/omnidev-state/stash/`. Max 5 entries; >30 day entries prompt expiry.

### B.13 AI Governance & Cost Audit (手工触发)

Command: `/od gv` (alias: `/od governance`). **Manual-only — never auto-triggered.**

- Load `engine/governance.md` only on explicit `/od gv`.
- Parameters: `--scope <all|phase0|...|cost|compliance|quality>`, `--since <7d|14d|30d|90d>`
- Output: governance audit report (read-only). Rule changes require `/od ln` approval.

### B.14 Document Synchronization on Requirement Changes (需求变更文档同步)

**最高优先级跨阶段规则。AI 必须主动感知需求变化，不依赖用户显式触发。**

#### 自我感知 — AI 主动识别需求变更

**每一轮用户输入，AI 都必须进行需求变更判断**，而非仅在 `/od ch` 时才触发。

**判断方法**: 将用户当前输入与已有 state files 中记录的需求进行比对，出现以下任一信号即判定为需求变更：

| 信号类型 | 典型表现 |
|----------|----------|
| **显式变更** | 用户执行 `/od ch`；用户说"改一下/换成/不要了/加个/去掉" |
| **隐式变更** | 用户在对话中描述了与已有 blueprint/plan 不一致的功能、流程或目标 |
| **补充需求** | 用户追加了原始需求中未提及的新功能、新约束、新边界条件 |
| **缩减需求** | 用户表示某功能"不做了/先不管/下期再说" |
| **技术回调** | 开发/测试中发现技术约束导致原需求不可行，需调整 |
| **偏差发现** | AI 自身发现当前执行方向与 state files 中记录的需求存在偏差 |

**判断后行为**:
- 若识别到需求变更 → **立即暂停当前工作**，先执行文档同步协议，再继续。
- 若无变更 → 正常继续当前 phase 工作。
- 若不确定是否构成变更 → 遵循 B.0 原则，问用户确认。

#### 同步范围
需求变更确认后，**必须扫描并同步所有已存在的 state files**：

| State File | 同步内容 |
|------------|----------|
| `00-project-context.md` | 项目背景、业务域描述、技术约束 |
| `01-blueprint.md` | 需求分析、架构设计、流程图 |
| `02-plan.md` | 任务拆解、排期、依赖关系 |
| `03-progress.md` | 任务状态、完成度标记 |
| `04-design.md` | 技术方案、接口设计、数据模型 |
| `05-test-plan.md` | 测试用例、覆盖范围 |
| `06-release-notes.md` | 发布说明、变更记录 |

#### 执行协议
1. **识别**: AI 主动判断用户输入是否包含需求变更信号（见上表）。
2. **确认**: 向用户明确说明检测到的变更内容，获得确认后执行（遵循 B.0）。
3. **扫描**: 检查 `docs/omnidev-state/[branch]/` 下所有已存在的文件。
4. **影响分析**: 判断每个文件是否受本次变更影响。
5. **同步更新**: 对受影响的文件逐一更新，保持与最新需求一致。
6. **变更标记**: 在每个被更新的文件中追加变更记录：
   ```
   <!-- CHANGE_LOG: [日期] 因需求变更同步更新: [变更摘要] -->
   ```
7. **同步报告**: 完成同步后，向用户输出变更同步报告：
   ```
   🔄 需求变更文档同步完成
   📝 变更内容: [摘要]
   📄 已同步文件: [列表]
   ⏭️ 未受影响: [列表]
   ```

#### 约束
- **主动识别是义务，不是可选项** — 不可因"用户没说 /od ch"就忽略需求变化。
- 仅更新**已存在**的文件，不为尚未创建的下游产物提前创建。
- 同步操作不可静默跳过 — 即使判断某文件"影响很小"，也必须在报告中说明。
- 文件不存在则在报告中标注"尚未创建，后续阶段将基于最新需求生成"。

---

## C. Phase Execution Protocol

### C.0 Phase & Engine File Loading

| Target | File to Load |
|--------|-------------|
| Phase 0 / `/od onboard` | `phases/00-assessment.md` |
| Phase 1 & 2 | `phases/01-02-planning.md` |
| Phase 3 | `phases/03-development.md` |
| Phase 4 / `/od qa` | `phases/04-testing.md` |
| `/od push`, `/od change`, `/od report`, `/od compress`, `/od up`, `/od i` | `engine/special-flows.md` |
| `/od gv`, `/od governance` | `engine/governance.md` |
| `/od learn`, `/od ln` | `engine/evolution.md` |
| `/od h`, `/od help` | `engine/commands.md` |
| `/od st`, `/od po` | `engine/stash.md` |
| `/od x`, `/od re` | `engine/session-memory.md` |
| Phase transition (exit/enter) | `engine/context-protocol.md` |
| Troubleshooting/diagnosis | `engine/skill-composition.md` |

After reading the instruction file, follow its `context_requires` to load project state files.

### C.1 Phase Exit — Checkpoint & Learning

每个 phase 完成后，**先执行静默学习，再输出 checkpoint**。

#### Phase Exit Learning (静默)
1. Reflect: domain knowledge, architecture patterns discovered?
2. Append novel insights to `00-project-context.md` § Domain Knowledge (1-2 lines, max 50 total).
3. Log to `evolution-log.jsonl` with `type: "domain"` or `"architecture"`.

#### Checkpoint Output
```
✅ Phase N 完成: [Name]
📦 产出物: [state files created/updated]
📍 进度: Phase 0 ✅ → Phase 1 ✅ → Phase 2 🔄 → ...
🔜 下一阶段: Phase N+1 — [Name]
```

**Phase 3 special rules**:
- Before writing code: **Pre-Dev Scope Confirmation** (in `03-development.md` §2.1) MUST be confirmed.
- After each task group: **Change Impact Summary** (in `03-development.md` §2.2) MUST be confirmed.

**Checkpoint 后必须展示下一步提示** (B.8)。STOP — WAIT。

### C.2 Context Budget (概要)

常驻上下文目标 ≤ 400 行（SKILL.md + phase instruction + state files + preferences）。

- 详细预算表和裁剪规则见 `engine/context-protocol.md` §6-§8。
- 当上下文接近容量: 触发 `/od compress`; 标记 >3 轮的工具输出为过期; 从 state file 重读。

---

## D. Project Type Awareness
- **Legacy**: Follow existing conventions 100%. "Write code like a sensible veteran employee."
- **Greenfield**: Full modern conventions — OpenSpec / TDD / DDD, high coverage, deploy manifests.

## E. MCP Integration
During Phase 3 & 4, proactively use available MCP servers:
- **Database MCP**: Verify structures, insert mock data, check data flow.
- **Browser MCP (Playwright)**: Start server → visit → E2E test → screenshot/DOM verify.
- **Discovery**: Check `.cursor/mcp.json` before complex tasks. Suggest installation if critical MCP missing.
