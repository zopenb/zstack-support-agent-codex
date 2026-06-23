---
name: "ZStackSupport:变更方案"
description: Generate a ZStack operation change proposal DOCX by editing the bundled standard Word template after a support issue is analyzed and a customer-facing change plan is needed. Use for ZStack change方案, 运维变更方案, 实施变更, 回退方案, 风险评估, 变更计划, or when converting event-analysis output into the company standard change proposal document.
---

# 变更方案

基于标准 Word 模板输出 ZStack 运维变更方案。必须复制并修改 `assets/2021XX-XX项目XX问题-ZStack变更方案模板v1.2.docx`，不要从空白文档重造。

## 工作流

1. 先基于事件分析结果、客户现场信息和变更目标，补全变更方案内容。AI 负责判断和撰写，脚本只负责把内容写进模板。
2. 若缺少变更窗口、执行人、监督人、回退条件、验证动作、影响范围等关键事实，只补问最小必要信息；不要让脚本编造。
3. 选择 Python：优先使用 Codex Desktop 提供的 bundled Python；只有在普通终端手工运行时，才要求系统 Python 已安装 `python-docx`。不要因为系统 `python` 是 Windows Store alias 就判定技能不可用。
4. 先导出模板风险 checklist 操作清单：

```powershell
<python.exe> scripts/generate_change_proposal.py --print-checklist
```

5. AI 逐项判断本次变更是否真的执行 checklist 中的某个“操作”。只有实际执行该操作时，才在 JSON 里写 `checklist_items` 或 `checklist_decisions`。
6. 使用脚本生成 DOCX：

```powershell
<python.exe> scripts/generate_change_proposal.py input.json --out output.docx
```

7. 若当前任务需要交付 DOCX，按文档技能的规则渲染并检查页面 PNG；发现版式问题后修改并重新渲染。LibreOffice/`soffice` 只用于自动 PDF/PNG 视觉 QA，不是生成 DOCX 的硬依赖；若不可用，说明“DOCX 已生成，未完成自动视觉渲染 QA”，不要暗示生成失败。

## Checklist 规则

- checklist 是人工/AI 审核结论，不是关键词搜索结果。
- 默认不勾选任何 checklist 行。
- 只使用 `checklist_items` 精确填写模板“操作”列里的操作名，或使用 `checklist_decisions` 写出逐项判断。
- 不要用“业务、授权、许可证、平台、变更、回退、风险、功能、服务、告警、验证、网络、云主机”等泛词推断 checklist。
- `checklist_keywords` 属于旧兼容字段，脚本会忽略；不要再使用。
- 风险正文可以写本次变更的具体风险；模板 checklist 只标记实际执行的模板高/中风险运维操作。
- 如果某个操作是否涉及不确定，保持空白并在方案正文或待确认项中说明，不要勾“是”。

## 模板约束

- 保留模板的封面、一级/二级标题、配置信息表、风险 checklist、回退方案、紧急预案和变更计划结构。
- 只替换模板中的项目、问题、变更步骤、风险预案、回退方案、执行计划等业务内容。
- 保持主题字体；正文和表格行间距统一为 1.5。
- 重要标签、风险级别、执行/回退/验证动作、用户用 `**重点**` 标出的内容必须加粗。
- 客户交付版本不得包含凭证、原始 MCP 载荷、未脱敏客户日志或没有证据支撑的根因断言。

## 脚本边界

`scripts/generate_change_proposal.py` 是模板渲染器：

- 默认读取本技能 `assets/` 下的标准模板。
- 支持 `--template` 指定新版模板。
- 支持 `--print-checklist` 输出模板 checklist 行，供 AI 审核。
- 按 JSON 写入模板并统一主题字体、1.5 倍行距、重点加粗。
- 不生成业务内容、不补默认步骤、不根据关键词判断风险 checklist。

输入字段参考 [输入结构](references/input-schema.md)。使用 Codex 工作区提供的 Python 运行脚本；在脱离 Codex 的终端手工运行时，才使用本机 Python + `python-docx`。不要把脚本改成依赖本机全局包的流程。
