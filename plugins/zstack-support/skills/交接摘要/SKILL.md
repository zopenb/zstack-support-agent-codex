---
name: "ZStackSupport:交接摘要"
description: Generate a channel-safe handoff summary from current case analysis results.
---

# 交接摘要

从当前案例证据和分析结果中，生成一份渠道安全的交接文档。

## 交接文档结构

```text
## 交接摘要

- 问题摘要：
- 影响范围：
- 时间线：
- 关键对象：
- 最强证据：
- 已确认：
- 较可能：
- 可能：
- 证据缺失：
- 已执行操作：
- 已排除方向：
- 参考证据边界：
- 下一责任人：
- 客户安全下一步行动：
- 闭环决策：
```

## 关键规则

1. **只包含已分析的证据**：不要把猜测或未验证的假设写进交接文档
2. **渠道安全**：不包含凭证、内部 URL、原始 MCP 载荷、许可证内容、客户原始日志
3. **参考证据边界明确**：GitHub 源码参考、ZStack知识社区(BBS) 参考和外部 Web/厂商论坛参考必须标注"参考证据，非当前客户证据"
4. **行动建议必须安全**：所有推荐的下一步行动必须是只读或客户安全的
5. **闭环决策一致**：交接文档中的闭环决策必须与当前分析结果一致

如当前事件尚未进行分析，先使用 `@ZStackSupport:事件分析` 完成分析，再生成交接文档。

完整安全策略参考 [ZStack Support Knowledge](../ZStack%20Support%20Knowledge/SKILL.md)。
