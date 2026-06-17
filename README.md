# ZStack Support Agent Codex 插件市场

这是 ZStack Support Agent（源码级分析）的 Codex 插件分发仓库。插件内置事件分析、源码查证、连通检查、交接摘要、脱敏检查和 ZStack Support Knowledge 知识库，并通过 MCP 对接 GitHub、ZStack 知识社区(BBS)、Tavily、Jira/Confluence。

## 安装方式

从本仓库根目录执行：

```powershell
powershell -ExecutionPolicy Bypass -File .\plugins\zstack-support\scripts\install.ps1
```

也可以手动安装：

```powershell
codex plugin marketplace add .
codex plugin add zstack-support@zstack-support-local
```

从 GitHub 分发安装：

```powershell
codex plugin marketplace add zopenb/zstack-support-agent-codex --ref main
codex plugin add zstack-support@zstack-support-local
```

安装后请重启 Codex，或打开一个新线程再运行 `zstack-support:连通检查`。

## 使用方式

| 用法 | 示例 | 预期行为 |
|------|------|----------|
| 直接问 | `L3 网络是什么？` | 直接中文回答，不查 MCP |
| 单点查证 | `这个 API 在源码里怎么走？` | 只查 GitHub 源码 |
| 历史案例 | `有没有类似历史案例？` | 只查 BBS/Jira 等历史来源 |
| 完整事件分析 | `升级后云主机迁移失败，帮我分析根因和下一步` | 按事件分析流程做多来源查证和闭环 |
| 连通检查 | `zstack-support:连通检查` | 只读检查 GitHub、BBS、Tavily、Atlassian MCP |

## 需要配置的环境变量

插件不保存任何账号、密码或 Token。每位同学都需要在自己的 Windows 用户环境变量里配置：

```text
GITHUB_MCP_TOKEN
ZSTACK_BBS_AUTHORIZATION
TAVILY_HIKARI_TOKEN
ATLASSIAN_AUTHORIZATION
```

不要把真实 Token、密码、base64 值或完整 Authorization Header 写入仓库、截图、文档或工单。

## 每个 Token 怎么获取

| 环境变量 | 获取方式 | 填写格式 |
|----------|----------|----------|
| `GITHUB_MCP_TOKEN` | 在 GitHub 创建 Personal Access Token：`Settings -> Developer settings -> Personal access tokens`。优先使用 fine-grained token；用于公开源码查证时，只需要仓库元数据和内容的只读权限。 | 原始 token，例如 `github_pat_...` |
| `ZSTACK_BBS_AUTHORIZATION` | 向团队获取 ZStack 知识社区(BBS) 账号。将 `username:password` 转为 base64，再加 `Basic ` 前缀。 | `Basic <base64(username:password)>` |
| `TAVILY_HIKARI_TOKEN` | 向 Tavily Hikari MCP 网关维护者获取。当前插件使用团队网关 `https://tavily.zopen1.com/mcp`。 | 原始 token |
| `ATLASSIAN_AUTHORIZATION` | 使用 Jira/Confluence 账号，服务地址为 `http://jira.zstack.io` 和 `http://confluence.zstack.io`。将 `username:password` 转为 base64，再加 `Basic ` 前缀。 | `Basic <base64(username:password)>` |

## Basic Auth 编码方式

在 PowerShell 中执行：

```powershell
$pair = 'username:password'
$base64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($pair))
$base64
```

然后按下面格式配置：

```text
ZSTACK_BBS_AUTHORIZATION=Basic <base64>
ATLASSIAN_AUTHORIZATION=Basic <base64>
```

`ATLASSIAN_AUTHORIZATION` 必须包含 `Basic ` 前缀。旧环境如果还有 `ATLASSIAN_BASIC_AUTH=<base64>`，安装脚本会尝试迁移，但新安装只推荐使用 `ATLASSIAN_AUTHORIZATION`。

## Windows 环境变量录入

PowerShell 用户变量方式：

```powershell
[Environment]::SetEnvironmentVariable('GITHUB_MCP_TOKEN', '<github-token>', 'User')
[Environment]::SetEnvironmentVariable('ZSTACK_BBS_AUTHORIZATION', 'Basic <bbs-base64>', 'User')
[Environment]::SetEnvironmentVariable('TAVILY_HIKARI_TOKEN', '<tavily-token>', 'User')
[Environment]::SetEnvironmentVariable('ATLASSIAN_AUTHORIZATION', 'Basic <atlassian-base64>', 'User')
```

图形界面方式：

1. 打开开始菜单。
2. 搜索“编辑账户的环境变量”。
3. 点击“环境变量”。
4. 在“用户变量”中新增上面四个变量。
5. 保存后重启 Codex，或打开新线程。

不打印密钥的检查方式：

```powershell
$names = @(
  'GITHUB_MCP_TOKEN',
  'ZSTACK_BBS_AUTHORIZATION',
  'TAVILY_HIKARI_TOKEN',
  'ATLASSIAN_AUTHORIZATION'
)

foreach ($name in $names) {
  [pscustomobject]@{
    Name = $name
    Present = [bool](
      [Environment]::GetEnvironmentVariable($name, 'User') -or
      [Environment]::GetEnvironmentVariable($name, 'Machine') -or
      [Environment]::GetEnvironmentVariable($name, 'Process')
    )
  }
} | Format-Table -AutoSize
```

## Jira/Confluence MCP 接入说明

Atlassian 使用共享远端 MCP，不需要每位同学单独安装本机 Node 适配器：

```text
MCP server id: zstack_atlassian_shared
URL: http://172.18.250.27:3340/mcp
认证变量: ATLASSIAN_AUTHORIZATION
```

插件的 `.mcp.json` 已声明该远端服务。连通检查时应优先读取插件 `.mcp.json` 判断是否已配置，而不是只检查 `~/.codex/config.toml`。

常见状态解释：

| 状态 | 含义 | 处理方式 |
|------|------|----------|
| 结构化查询成功 | 当前 Codex 会话已注入 Jira/Confluence 工具，查询可用 | 正常使用 |
| 已配置但未注入 | 插件 `.mcp.json` 已声明，`ATLASSIAN_AUTHORIZATION` 也存在，但当前会话没暴露 Jira/Confluence 工具 | 重启 Codex 或新开线程；仍失败时检查 Codex 日志中的 `zstack_atlassian_shared` |
| MCP 查询未完成 | 插件声明和变量存在，但远端网络、认证或 MCP 初始化失败 | 运行 `plugins\zstack-support\scripts\debug-atlassian-mcp.ps1` 定位网络、Header 或远端服务问题 |
| 未配置 | 插件声明缺失，或 `ATLASSIAN_AUTHORIZATION` 缺失 | 重新安装插件并配置环境变量 |

不要回退到旧的 `zstack_atlassian` 本机适配器、`support_archive`、`support_sql_analyst` 或其他旧目标。

## 验证安装

```powershell
codex plugin list
codex mcp list
```

期望看到这些 MCP server：

```text
github
zstack-bbs
tavily_hikari
zstack_atlassian_shared
```

然后运行：

```text
zstack-support:连通检查
```

## 更新插件

从 GitHub 更新：

```powershell
codex plugin marketplace upgrade zstack-support-local
codex plugin add zstack-support@zstack-support-local
```

本地开发更新时，修改插件后刷新 `.codex-plugin/plugin.json` 里的 cachebuster 版本，例如：

```text
2.9.6+codex.local-YYYYMMDDHHMMSS
```

然后重新执行安装脚本或 `codex plugin add zstack-support@zstack-support-local`。更新后请新开 Codex 线程测试，避免旧线程继续使用旧缓存。

## 更多文档

- 插件说明：[plugins/zstack-support/README.md](plugins/zstack-support/README.md)
- MCP 连接器说明：[plugins/zstack-support/CONNECTORS.md](plugins/zstack-support/CONNECTORS.md)
- 连通检查技能：[plugins/zstack-support/skills/连通检查/SKILL.md](plugins/zstack-support/skills/连通检查/SKILL.md)
