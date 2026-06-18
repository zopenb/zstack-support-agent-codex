---
name: 环境配置
description: Configure and inspect ZStack Support Agent Windows user environment variables for MCP connectors. Use when users ask to set up, snapshot, diagnose, or verify GITHUB_MCP_TOKEN, ZSTACK_BBS_AUTHORIZATION, TAVILY_HIKARI_TOKEN, ATLASSIAN_AUTHORIZATION, Jira/Confluence auth, GitHub token, BBS auth, Tavily token, or plugin connector variables through chat.
---

# ZStack 环境配置

使用本技能帮助用户配置和快照插件所需 Windows 用户环境变量。不要要求用户把 Token、密码、Authorization 或 base64 值直接粘贴到聊天里。

## 支持变量

```text
GITHUB_MCP_TOKEN
ZSTACK_BBS_AUTHORIZATION
TAVILY_HIKARI_TOKEN
ATLASSIAN_AUTHORIZATION
```

Jira/Confluence 只使用 `ATLASSIAN_AUTHORIZATION=Basic <base64(username:password)>`，不再要求 `JIRA_USERNAME`、`JIRA_PASSWORD`、`CONFLUENCE_USERNAME`、`CONFLUENCE_PASSWORD`。

## 快照当前配置

当用户问“快照配置 / 检查变量 / 看看配置好了没 / 为什么 MCP 没注入”时，运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\plugins\zstack-support\scripts\snapshot-user-env.ps1
```

输出只包含：

- 变量名
- 是否存在
- 发现作用域
- 格式检查
- 修复建议

不得输出真实变量值、Token、密码、Authorization Header 或 base64 内容。

## 引导录入配置

当用户要“配置变量 / 录入 token / 初始化连接器”时，说明不要在聊天里粘贴密钥，并运行隐藏输入脚本：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\plugins\zstack-support\scripts\set-user-env.ps1
```

如果用户只想补齐缺失项，运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\plugins\zstack-support\scripts\set-user-env.ps1 -SkipExisting
```

脚本会用隐藏输入接收密钥，写入 Windows 用户变量和当前进程变量。

## 配置后动作

配置或修改变量后，提示用户：

```text
请重启 Codex 或打开新线程，再运行 zstack-support:连通检查。
```

如果快照显示变量存在但 MCP 仍未注入，建议继续运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\plugins\zstack-support\scripts\debug-atlassian-mcp.ps1
```

只在 Atlassian/Jira/Confluence 未注入时运行该脚本。

## 安全边界

- 不在聊天中收集密钥。
- 不输出变量值。
- 不把密钥写入 `.mcp.json`、`config.toml`、README、日志或仓库文件。
- 不建议配置旧变量 `ATLASSIAN_BASIC_AUTH`。
- 如果用户粘贴了真实密钥，提醒立即轮换。
