# 变更方案输入结构

生成脚本读取 UTF-8 JSON。JSON 内容应由 AI 基于事件分析和用户补充信息先完成判断后再传给脚本；脚本只渲染模板，不负责补业务逻辑。

## 示例

```json
{
  "cover_title": "ZStack运维变更方案",
  "change_title": "ZStack授权导入变更",
  "risk_level": "低",
  "document_date": "2026-06-22",
  "software_info": "ZStack Cloud 版本：待补充；授权文件类型：待补充",
  "hardware_config": "本次变更不涉及硬件配置调整。",
  "business_info": "本次变更不涉及业务资源删除、迁移、网络或存储调整；实际影响范围以客户现场确认为准。",
  "overview": [
    "本文档用于说明 ZStack 授权导入变更的目标、步骤、风险、回退方案和执行计划。",
    "本次变更目标为导入客户确认的授权文件，并在导入后验证授权状态和相关功能可用性。"
  ],
  "change_principles": [
    "变更前确认授权文件来源、适用版本、授权对象和客户审批结果。",
    "变更过程不执行业务资源删除、网络调整、存储调整或底层系统变更。"
  ],
  "overall_flow": [
    "变更前检查授权文件和平台状态。",
    "执行授权导入。",
    "验证授权状态和相关功能显示。",
    "观察平台告警和客户确认结果。"
  ],
  "detailed_steps": [
    "登录 ZStack 管理界面并确认当前授权状态。",
    "按审批通过的授权文件执行导入。",
    "导入后刷新授权页面并确认有效期、授权容量和功能模块显示。",
    "确认平台无新增异常告警。"
  ],
  "risks": [
    "授权文件版本、平台版本或授权对象不匹配，可能导致导入失败。",
    "授权内容与客户预期不一致，可能导致相关商业功能未生效。"
  ],
  "risk_mitigations": [
    "执行前由客户或项目负责人确认授权文件和变更窗口。",
    "导入前记录当前授权状态，导入后立即进行页面和功能验证。"
  ],
  "rollback_plan": [
    "若导入失败或授权状态异常，停止后续操作并保留导入结果截图和错误信息。",
    "如平台支持恢复原授权文件，按客户确认的原授权文件恢复。",
    "回退后重新验证授权状态和相关功能显示。"
  ],
  "emergency_plan": [
    "若导入后出现非预期业务影响，立即通知客户负责人和 ZStack 技术支持负责人，暂停后续操作并启动回退或升级处理。"
  ],
  "change_plan": [
    "变更时间：待补充",
    "变更执行人：待补充 联系电话 待补充",
    "变更监督人：待补充 联系电话 待补充"
  ],
  "checklist_items": []
}
```

## 字段说明

- `cover_title`：封面主标题；通常保留“ZStack运维变更方案”。
- `change_title`：封面第二行，通常为“项目/问题 + 变更”。
- `risk_level`：封面风险等级，由 AI 根据实际变更影响判断。
- `document_date`：封面日期。
- `software_info`、`hardware_config`、`business_info`：写入模板“2.1 配置信息”表格。
- `overview`：写入“变更概述”。
- `change_principles`：写入“2.2 变更原则及变更范围”。
- `overall_flow`：写入“2.3 变更整体流程”。
- `detailed_steps`：写入“2.4 变更具体步骤”。
- `risks`：写入“3.1 风险清单”。这里写本次变更的真实风险，不等同于模板 checklist 勾选。
- `risk_mitigations`：写入“3.2 风险预案”。
- `rollback_plan`：写入“回退方案”。
- `emergency_plan`：写入“紧急预案”。
- `change_plan`：写入“变更计划”。也可使用 `change_time`、`executor`、`executor_phone`、`supervisor`、`supervisor_phone` 让脚本拼成基础计划行。
- `checklist_items`：模板风险 checklist 的精确操作名数组。只有 AI 判断本次确实执行该操作时才填写。
- `checklist_decisions`：可选的逐项判断数组，格式如 `{"operation": "底层网络变更", "involved": true, "reason": "..."}`；脚本只使用 `involved=true` 的 `operation` 标记“是”。
- `mark_unmatched_checklist_as_no`：布尔值。只有用户明确要求把未涉及项写“否”时才设为 `true`，否则保持空白。

## Checklist 审核方法

1. 运行 `python scripts/generate_change_proposal.py --print-checklist` 获取模板中的 `module`、`operation`、`impact`、`level`。
2. AI 结合实际变更步骤逐项判断是否执行该 operation。
3. 只有实际执行模板 operation 时才写入 `checklist_items`。
4. 如果只是页面查看、只读检查、日志检索、授权状态确认、导入授权文件等不等同于模板 operation 的动作，不要因为文本相似而勾选。

文本中可使用 `**重点内容**` 标记加粗。
