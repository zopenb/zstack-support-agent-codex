# 显式 subagent 并行深查模板

只有用户明确要求“多 agent / 子 agent / subagent / 并行深查 / 多路并行深查”时，才使用本模板。普通 `@事件分析` 由主 agent 查证和汇总，不自行拉起并行 agent。

## 用户请求模板

```text
@ZStackSupport:事件分析 用多 agent 并行深查：<粘贴客户反馈、日志、告警、错误文本或版本问题>
```

## 主 agent 调度模板

```text
请使用 Codex subagents 并行深查此 ZStack 支持事件。

Spawn 4 个 subagents：

1. 源码/版本 agent
   范围：只查 GitHub 源码、commit、tag、release branch、调用链、版本差异。
   禁止：Jira、Confluence、BBS、Tavily。

2. 历史案例 agent
   范围：只查 ZStack知识社区(BBS) 相似案例、差异、可复用验证动作。
   禁止：Jira、Confluence。

3. 内部跟踪 agent
   范围：只查 Jira/Confluence，输出脱敏摘要、状态、影响版本、修复版本、版本边界。
   禁止：输出内部原文、内部 URL、评论原文、附件、账号或 Token。

4. 文档/外部 agent
   范围：只查官网文档、发布说明、Tavily/厂商/OS 外部资料。
   要求：使用脱敏查询词。

Wait for all subagents that are critical to the conclusion. 超时或失败的来源必须标注“查证未完成”，不得当成未命中。

每个 subagent 按以下格式输出：

来源：
查询词：
命中：
相关性：高 / 中 / 低
能支持的判断：
不能支持的判断：
证据边界：
下一步：

主 agent 最后合并结果，标注来源冲突、未完成来源和结论边界。
```

## 降级输出

```text
Subagent 状态：未触发
原因：当前会话未暴露 subagent 调度工具 / 宿主策略未允许当前任务派发 subagent / subagent 调用失败
降级动作：由主 agent 继续完成 GitHub/BBS/Jira/Confluence/Tavily 查证
```
