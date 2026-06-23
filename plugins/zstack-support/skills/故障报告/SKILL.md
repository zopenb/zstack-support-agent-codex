---
name: "ZStackSupport:故障报告"
description: Generate a ZStack enterprise fault analysis report DOCX by editing the bundled standard Word template after a support incident has been analyzed. Use for 故障报告, 故障分析报告, 事故报告, 根因分析报告, RCA, 处理过程, 原因分析, 改进预防方案, or when converting event-analysis output into the company standard fault report document.
---

# 故障报告

基于标准 Word 模板输出 ZStack 企业版故障分析报告。必须复制并修改 `assets/ZStack企业版-故障分析报告模板V1.2.docx`，不要从空白文档重造。

## 工作流

1. 先基于事件分析结果、当前证据、客户确认信息和恢复结果补全报告内容。AI 负责判断和撰写，脚本只负责把内容写进模板。
2. 若缺少故障时间、恢复时间、影响范围、处理过程、原因分析、改进措施或证据边界，只补问最小必要信息；不要让脚本编造。
3. 选择 Python：优先使用 Codex Desktop 提供的 bundled Python；只有在普通终端手工运行时，才要求系统 Python 已安装 `python-docx`。不要因为系统 `python` 是 Windows Store alias 就判定技能不可用。
4. 可先导出模板结构，确认可填字段：

```powershell
<python.exe> scripts/generate_fault_report.py --print-template
```

5. 将报告内容整理为 JSON，字段参考 [输入结构](references/input-schema.md)。
6. 使用脚本生成 DOCX：

```powershell
<python.exe> scripts/generate_fault_report.py input.json --out output.docx
```

7. 若当前任务需要交付 DOCX，按文档技能的规则渲染并检查页面 PNG；发现版式问题后修改并重新渲染。LibreOffice/`soffice` 只用于自动 PDF/PNG 视觉 QA，不是生成 DOCX 的硬依赖；若不可用，说明“DOCX 已生成，未完成自动视觉渲染 QA”，不要暗示生成失败。

## 报告边界

- 故障报告是对已分析事件的正式输出，不是排查工具。
- 原因分析必须基于证据分级和当前结论；未闭环时写“初步判断/仍需确认”，不要写成确定根因。
- 处理过程应按时间线写实际动作、观察结果和责任边界，不要补不存在的操作。
- 后续改进与预防方案应由 AI 根据事件分析结论生成，可以包含客户侧、支持侧、产品侧或流程侧措施，但必须标清前提和责任人。
- 客户交付版本不得包含凭证、原始 MCP 载荷、未脱敏客户日志、内部原文或没有证据支撑的根因断言。

## 模板约束

- 保留模板的封面、故障基本信息表、分析处理过程表、原因分析表、后续改进与预防方案表。
- 只替换模板中的标题、基础信息和三个正文块内容。
- 保持主题字体；正文和表格行间距统一为 1.5。
- 重要标签、故障级别、关键时间点、根因结论、恢复动作、改进措施，以及用户用 `**重点**` 标出的内容必须加粗。

## 脚本边界

`scripts/generate_fault_report.py` 是模板渲染器：

- 默认读取本技能 `assets/` 下的标准模板。
- 支持 `--template` 指定新版模板。
- 支持 `--print-template` 输出模板字段和正文块名称。
- 按 JSON 写入模板并统一主题字体、1.5 倍行距、重点加粗。
- 不生成业务内容、不补默认根因、不补默认整改措施。

输入字段参考 [输入结构](references/input-schema.md)。使用 Codex 工作区提供的 Python 运行脚本；在脱离 Codex 的终端手工运行时，才使用本机 Python + `python-docx`。不要把脚本改成依赖本机全局包的流程。
