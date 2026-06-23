# 故障报告输入结构

生成脚本读取 UTF-8 JSON。JSON 内容应由 AI 基于事件分析、证据边界和用户补充信息先完成判断后再传给脚本；脚本只渲染模板，不负责补业务逻辑。

## 示例

```json
{
  "report_title": "云平台数据库残留记录导致资源操作异常",
  "report_subtitle": "——问题故障报告",
  "project_name": "XX项目",
  "customer_name": "XX客户",
  "fault_impact_scope": "影响范围待补充。已知现象：待补充。",
  "customer_contact": "待补充",
  "reporter": "待补充",
  "software_product": "ZStack Cloud",
  "version": "待补充",
  "fault_start_time": "待补充",
  "business_recovery_time": "待补充",
  "fault_duration": "待补充",
  "fault_category": "软件",
  "responsible_department": "技术支持",
  "fault_level": "三级级别（一般）",
  "fault_description": [
    "故障情况描述：待补充。",
    "具体表现为：待补充。"
  ],
  "analysis_process": [
    "时间：待补充；动作：收集客户反馈和关键日志；结果：待补充。",
    "时间：待补充；动作：结合源码/历史案例/现场证据分析；结果：待补充。"
  ],
  "root_cause_analysis": [
    "原因分析：当前证据支持的结论待补充。",
    "证据边界：待补充。"
  ],
  "improvement_plan": [
    "后续改进与预防方案：待补充。",
    "责任人/责任团队：待补充。"
  ]
}
```

## 字段说明

- `report_title`：封面主标题，替换模板中的“云平台数据库残留XXXX”。
- `report_subtitle`：封面副标题，通常保留“——问题故障报告”。
- `project_name`：故障基本信息表“项目名称”。
- `customer_name`：故障基本信息表“客户名称”。
- `fault_impact_scope`：故障基本信息表“故障影响和范围”。
- `customer_contact`：故障基本信息表“客户联系人”。
- `reporter`：故障基本信息表“故障报告人”。
- `software_product`：故障基本信息表“软件产品”。
- `version`：故障基本信息表“版本号”。
- `fault_start_time`：故障基本信息表“故障发生时间”。
- `business_recovery_time`：故障基本信息表“业务恢复时间”。
- `fault_duration`：故障基本信息表“故障总耗时长”。
- `fault_category`：故障基本信息表“故障类别”，由 AI 根据事实填写“软件/硬件/其他”或更具体说明。
- `responsible_department`：故障基本信息表“故障责任部门”。
- `fault_level`：故障基本信息表“故障级别”，由 AI 根据影响和模板定义判断；不确定则写待确认。
- `fault_description`：写入“故障情况描述”正文单元格。
- `analysis_process`：写入“分析处理过程”表，建议按时间线或处理阶段列出。
- `root_cause_analysis`：写入“原因分析”表。根因未闭环时必须写证据边界。
- `improvement_plan`：写入“后续改进与预防方案”表。

文本中可使用 `**重点内容**` 标记加粗。数组会按条目写入多段；字符串会按换行拆分。
