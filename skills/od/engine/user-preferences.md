# User Preferences Memory (用户偏好档案)

## Overview

自动、被动地采集用户在 `/od` 会话中表现出的行为模式和偏好，持久化为结构化档案。每次 `/od` 激活时轻量加载，让 AI "记住"用户习惯。

## 1. 偏好档案文件

**路径**: `docs/omnidev-state/user-preferences.md` （全局级，不分分支）

**大小限制**: 控制在 **30 行以内**。这是一个高频加载文件，必须极致精简。

## 2. 档案格式

```markdown
---
last_updated: 2026-06-03T08:30:00+08:00
---

## 工作流偏好
- complexity_skip: [S 任务从不生成状态文件]
- phase_skip_pattern: [通常跳过 Blueprint，只做 Plan → Dev → Test]
- checkpoint_style: [偏好简洁，不需要详细 checkpoint 输出]

## 代码风格
- naming: [变量用 camelCase，文件用 kebab-case]
- comments_language: [代码注释用英文]
- error_format: [{code, data, message} 统一格式]
- quotes: [单引号]

## 交互偏好
- output_verbosity: [concise | detailed]  # 默认 concise
- language: [回复用中文，代码注释用英文]
- confirm_style: [快速确认，不需要重复展示已知信息]

## 技术偏好
- test_framework: [jest + react-testing-library]
- api_style: [RESTful, 不用 GraphQL]
- state_management: [zustand]
- orm: [prisma]
```

## 3. 采集规则（被动学习）

以下场景自动采集，**无需用户显式触发**：

| 信号类型 | 采集条件 | 写入字段 |
|---------|---------|---------|
| **Phase 跳过模式** | 用户连续 2 次在同类型任务中跳过同一 phase | `phase_skip_pattern` |
| **Checkpoint 偏好** | 用户在 checkpoint 输出后立即输入 `/od n` 不看内容 | `checkpoint_style: concise` |
| **代码风格纠正** | 用户修改 AI 生成的代码风格（命名、引号、缩进等） | `naming` / `quotes` 等 |
| **输出语言偏好** | 用户要求"用中文回复"或"comments in English" | `language` / `comments_language` |
| **技术栈偏好** | 用户指定或纠正框架/库选择 | `test_framework` / `orm` 等 |
| **API 格式偏好** | 用户纠正返回格式 | `error_format` / `api_style` |
| **输出详细程度** | 用户说"简洁点"/"详细点"/"不用解释" | `output_verbosity` |

### 采集约束

1. **置信度门槛**: 同一偏好信号出现 **2 次以上** 才写入档案。单次可能是个例。
2. **不重复**: 已存在的偏好不重复写入，只在值变更时更新。
3. **不阻塞**: 偏好采集在后台静默进行，不向用户展示"已记录您的偏好"之类的提示。
4. **可覆盖**: 新偏好覆盖旧偏好（用户习惯可能变化）。
5. **与 evolution-log 互补**: evolution-log 记录错误修正和规则演化（重型），user-preferences 记录日常行为习惯（轻型）。两者不重复。

## 4. 加载规则

| 场景 | 行为 |
|------|------|
| **每次 `/od` 激活** | 在读取 `config.json` 的同时读取 `user-preferences.md`（如果存在）。文件很小（< 30 行），对上下文开销可忽略。 |
| **Phase 3 开发** | 参考 `## 代码风格` 和 `## 技术偏好` 指导代码生成。 |
| **Phase Checkpoint** | 参考 `checkpoint_style` 和 `output_verbosity` 调整输出详细程度。 |

## 5. 用户可控

- **查看**: `/od cfg` 同时展示 config.json 和 user-preferences.md 的内容。
- **清除**: 用户可以手动删除 `user-preferences.md` 重置所有偏好。
- **编辑**: 用户可以直接编辑文件，AI 下次激活时会读取最新版本。
