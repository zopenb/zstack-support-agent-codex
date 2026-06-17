---
name: 连通检查
description: Diagnose GitHub MCP, ZStack Knowledge Community (BBS) MCP, Tavily MCP, and Atlassian MCP connectivity status.
---

# MCP 连通检查

对 GitHub MCP、ZStack知识社区(BBS) MCP、Tavily MCP 和 Atlassian MCP 执行渐进式只读烟测。连通检查只验证工具是否可用，不作为事件分析证据。

Atlassian 只检查插件声明的共享远端 `zstack_atlassian_shared` / Jira / Confluence 工具。不要把旧的 `zstack_atlassian` 本机适配器、`support_archive`、`support_sql_analyst` 或其他旧全局 MCP 目标计入通过条件。

## 中文状态

| 状态 | 含义 |
|------|------|
| 工具可见 | 能看到 MCP 服务器或工具，但尚未证明可查询 |
| 已连接 | MCP 初始化成功，但尚未完成结构化查询 |
| 结构化查询成功 | 已完成只读查询并返回可解析数据 |
| MCP 查询未完成 | 超时、认证失败、schema 不匹配、权限不足、网络失败或只完成部分检查 |
| 未配置 | 当前 Codex 配置中没有对应 MCP，或缺少必要环境变量 |
| 已配置但未注入 | `codex mcp list` 可见且本地协议测试可用，但当前对话没有暴露对应工具 |

## GitHub MCP 冒烟检查

目标仓库：

```text
owner: zstackio
repo: zstack
```

检查步骤：

```text
第 1 步（工具可见）：检查是否能看到 github 服务器或 mcp__github__ 工具
第 2 步（已连接）：检查 MCP 初始化和工具列表是否成功
第 3 步（结构化查询）：对 zstackio/zstack 执行只读仓库查询
第 4 步（文件读取）：读取 README.md 等顶层文件
```

输出格式：

```text
GitHub MCP 冒烟检查：
第 1 步（工具可见）：通过 / 未通过
第 2 步（已连接）：通过 / 未通过
第 3 步（结构化查询）：通过 / 未通过
第 4 步（文件读取）：通过 / 未通过
最终状态：结构化查询成功 / MCP 查询未完成 / 未配置
诊断建议：
```

如果未配置，提示：

> GitHub MCP 未配置。设置 `GITHUB_MCP_TOKEN` 环境变量，重启 Codex 或打开新线程。

## ZStack知识社区(BBS) MCP 冒烟检查

检查步骤：

```text
第 1 步（工具可见）：检查是否能看到 zstack-bbs 服务器或 bbs_* 工具
第 2 步（已连接）：检查 MCP 初始化是否成功
第 3 步（结构化查询）：执行 bbs_latest 或 bbs_search 只读查询
最终状态：结构化查询成功 / MCP 查询未完成 / 未配置
```

如果未配置，提示：

> ZStack知识社区(BBS) MCP 未配置。获取团队提供的 ZStack知识社区账号后，设置 `ZSTACK_BBS_AUTHORIZATION` 环境变量，重启 Codex 或打开新线程。

## Tavily MCP 冒烟检查

检查步骤：

```text
第 1 步（工具可见）：检查是否能看到 tavily_hikari 服务器或 Tavily 搜索工具
第 2 步（已连接）：检查 MCP 初始化是否成功
第 3 步（结构化查询）：执行只读搜索测试，例如 Red Hat virtio Windows disk timeout
最终状态：结构化查询成功 / MCP 查询未完成 / 未配置
```

如果未配置，提示：

> Tavily MCP 未配置。设置 `TAVILY_HIKARI_TOKEN` 环境变量，重启 Codex 或打开新线程。

Tavily 结果只能作为 E3 公开 Web/外部论坛参考，不能单独关闭当前事件。

## Atlassian MCP 冒烟检查

检查步骤：

```text
第 1 步（工具注入）：检查当前对话是否能看到 zstack_atlassian_shared 服务器或 Jira/Confluence 查询工具
第 2 步（共享远端配置）：如果工具未注入，使用 codex mcp get/list 确认 zstack_atlassian_shared 是否 enabled，URL 是否为 http://172.18.250.27:3340/mcp，且不是 command/args/cwd 形式的本机适配器
第 3 步（认证变量）：检查是否存在 ATLASSIAN_AUTHORIZATION 环境变量；它应为完整 `Basic <base64(username:password)>`。如果缺失，提示直接设置 `ATLASSIAN_AUTHORIZATION`。如果只存在旧变量 `ATLASSIAN_BASIC_AUTH`，说明这是旧配置，安装脚本可迁移，但推荐改为单变量配置。连通检查不得输出变量值
第 4 步（结构化查询）：优先用当前对话注入的 Jira/Confluence 工具执行只读查询；如果工具未注入但 codex mcp get/list 显示共享远端配置存在，最终状态写为“已配置但未注入”
最终状态：结构化查询成功 / MCP 查询未完成 / 已配置但未注入 / 未配置
```

如果未配置，提示：

> Atlassian MCP 未配置。确认插件声明了 `zstack_atlassian_shared`，设置 `ATLASSIAN_AUTHORIZATION=Basic <base64(username:password)>`，再重启 Codex 或打开新线程。

如果 `codex mcp get zstack_atlassian_shared` 显示 `zstack_atlassian_shared` 为 enabled，URL 指向 `http://172.18.250.27:3340/mcp`，但当前对话仍看不到 Jira/Confluence 工具，最终状态必须写为“已配置但未注入”，提示：

> Atlassian 共享远端 MCP 已配置，但当前 Codex 对话未注入 Jira/Confluence 工具。优先检查 Codex 日志中的 `zstack_atlassian_shared` 是否认证失败、网络不可达或停在工具加载阶段；不要回退到旧的本机 Node 适配器。

如果当前对话未注入工具，但 `codex mcp get/list` 能看到共享远端配置，应明确区分：

```text
第 1 步（工具注入）：未通过
第 2 步（共享远端配置）：通过
第 3 步（认证变量）：通过
第 4 步（结构化查询）：未通过（当前对话工具未注入）
最终状态：已配置但未注入
```

不要把这种情况写成“未配置”或泛化为“MCP 查询未完成”。

Atlassian 结果只能作为 E3 内部参考，不能直接输出内部原文、内部 URL、账号、Token 或未脱敏附件。

## 规则

- 不输出敏感信息：不打印 Token 值、Authorization 头、原始 MCP 载荷。
- 只读：所有检查操作必须只读，不创建、修改或删除任何资源。
- 不绕过证据标签：连通检查结果不能作为事件分析的客户证据。
