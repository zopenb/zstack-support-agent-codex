# 渠道安全策略

本仓库面向渠道支持工作流。不得包含内部系统、客户原始证据、凭证、许可证或私有支持数据。

## 允许提交

- 核心工作流文档
- Codex 规则和提示
- 脱敏模板
- 仅占位符的环境变量示例
- 共享 `.mcp.json`，仅包含环境变量引用和只读 GitHub/ZStack知识社区(BBS)/Tavily/Atlassian MCP 配置
- 公开源码、ZStack知识社区(BBS)、Tavily 和 Atlassian MCP 设置说明，不含真实凭证

## 禁止提交

- `.env`、`.env.local`、Token、密码、Cookie、私钥、许可证文件、授权头
- 客户日志、截图、抓包、dump、CSV、XLSX、DOCX、PDF、ZIP、RAR、HAR 或生成的报告
- 内部支持归档、支持 SQL、内部 GitLab、CRM 或私有知识库引用
- Jira/Confluence 原文、内部 URL、未脱敏附件、评论内容或任何写操作痕迹
- 内部 URL、内部 IP、真实账户名、原始 MCP 载荷、原始提供者 JSON 或缓存产物

## MCP 边界

渠道 MCP 默认必须只读。ZStack知识社区(BBS)、GitHub 源码、Tavily 和 Atlassian MCP 必须使用环境变量凭证，仅暴露批准的只读工具。服务器可见不够；只有在成功的只读结构化查询之后才记录“结构化查询成功”。

Atlassian MCP 必须使用共享远端 `zstack_atlassian_shared`，通过 `ATLASSIAN_AUTHORIZATION` 注入完整 `Basic <base64(username:password)>` Header；该值可由安装脚本从 `ATLASSIAN_BASIC_AUTH=base64(username:password)` 派生。只允许 Jira/Confluence 只读查证。输出时只允许脱敏摘要、工单号、状态、版本边界和可公开行动建议；禁止输出内部 URL、账号、Token、原始页面内容、原始工单描述、评论原文或未脱敏附件。

GitHub 访问应在第一版 Agent 工作流中使用 GitHub MCP 只读模式。`gh` 可作为后续运维/调试回退。不要引入非标准 GitHub CLI 替代品。

## 发布检查

分享本项目前验证：

- 不存在仅内部名称或端点
- 不存在 OpenCode、Claude Code 或 Codex 适配器资产
- 不存在非标准 GitHub CLI 依赖
- 不存在 `.env`、缓存、生成输出或原始案例证据
- 所有凭证为占位符
- Codex 规则未重新引入内部系统

## 脱敏检查清单

- 无 `.env` 值、Token、密码、Cookie、私钥或授权头
- 无许可证内容或许可证衍生的客户身份
- 无客户原始日志、截图、抓包、dump、CSV、DOCX、PDF、ZIP 或生成的报告
- 无内部支持归档、SQL 分析、内部 GitLab、CRM 或私有知识库引用
- Jira/Confluence 内容已脱敏，未输出内部 URL、原文、评论、附件或写操作
- 无内部 URL、内部 IP、真实账户名、原始 MCP 载荷或提供者 JSON
- 证据断言标注了“已确认 / 较可能 / 可能 / 证据缺失”和 `E0-E5` 级别
