---
name: "ZStackSupport:脱敏检查"
description: Review documents or case summaries for internal channel-safe sharing. Checks for secrets, raw customer data, raw internal content, and unsupported claims.
---

# 脱敏检查

对提供的文档或事件分析摘要进行渠道安全分享检查，返回通过/未通过清单和需要修改的具体位置。

## 检查清单

逐项检查以下内容：

1. **凭证与密钥**：`.env` 值、Token、密码、Cookie、私钥、授权头
2. **许可证内容**：许可证密钥或许可证衍生的客户身份信息
3. **客户原始数据**：原始日志、截图、抓包文件、dump、CSV、DOCX、PDF、ZIP 或生成的报告
4. **内部系统引用**：内部支持归档、SQL 分析、内部 GitLab、CRM、私有知识库；BBS/Jira/Confluence 的编号、标题摘要和可点击链接允许保留，原始正文、评论、附件不允许
5. **内部标识**：内部 IP、真实账户名、原始 MCP 载荷、提供者 JSON；BBS/Jira/Confluence 链接不作为问题项
6. **证据标签完整性**：所有断言是否标注了“已确认 / 较可能 / 可能 / 证据缺失”和 `E0-E5` 级别
7. **无证据根因声明**：E0-E2 级别的断言是否被当作最终根因

## 输出格式

```text
## 脱敏检查结果

| 检查项 | 状态 | 问题位置 |
|--------|------|----------|
| 凭证与密钥 | 通过/未通过 | （未通过时标注具体位置） |
| 许可证内容 | 通过/未通过 | |
| 客户原始数据 | 通过/未通过 | |
| 内部系统引用 | 通过/未通过 | |
| 内部标识 | 通过/未通过 | |
| 证据标签完整性 | 通过/未通过 | |
| 无证据根因声明 | 通过/未通过 | |

## 需要修改的部分

（列出具体需要修改的段落或位置，以及修改建议。不打印敏感值本身，只标注类别和位置。）
```

## 规则

- 不打印敏感值本身，只标注类别和位置
- 如果全部通过，明确标注"文档可安全分享"
- 如果有未通过项，给出具体修改建议
- 检查标准与项目 SECURITY.md 保持一致

完整安全策略参考 [ZStack Support Knowledge](../ZStack%20Support%20Knowledge/SKILL.md)。
