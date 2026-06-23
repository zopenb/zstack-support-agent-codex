# ZStack Support Agent Codex 插件市场

这是 ZStack Support Agent（源码级分析）的 Codex 插件分发仓库。插件内置事件分析、源码查证、连通检查、变更方案、故障报告、交接摘要、脱敏检查和 ZStack Support Knowledge 知识库，并通过 MCP 对接 GitHub、ZStack 知识社区(BBS)、Tavily、Jira/Confluence。

## 安装方式

建议先做本机依赖检查。脚本只输出组件状态、路径和格式判断，不打印 Token、Authorization 或 base64 明文。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\plugins\zstack-support\scripts\check-local-dependencies.ps1
```

需要同时检查 MCP 远端 TCP 连通性时：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\plugins\zstack-support\scripts\check-local-dependencies.ps1 -CheckNetwork
```

从本仓库根目录执行：

```powershell
powershell -ExecutionPolicy Bypass -File .\plugins\zstack-support\scripts\install.ps1
```

推荐使用安装脚本。脚本会优先选择 `%LOCALAPPDATA%\OpenAI\Codex\bin\*\codex.exe` 下的可执行入口，避免裸 `codex` 命令命中 WindowsApps 包路径后出现“拒绝访问”。如果诊断脚本报告可用 Codex 路径，也可以显式传入：

```powershell
powershell -ExecutionPolicy Bypass -File .\plugins\zstack-support\scripts\install.ps1 -CodexExe "C:\path\to\codex.exe"
```

仅当本机 `codex` 命令可直接执行时，才手动安装：

```powershell
codex plugin marketplace add .
codex plugin add zstack-support@zstack-support-local
```

从 GitHub 分发手动安装时也一样，先确认 `codex` 命令可执行：

```powershell
codex plugin marketplace add zopenb/zstack-support-agent-codex --ref main
codex plugin add zstack-support@zstack-support-local
```

安装后请重启 Codex，或打开一个新线程再运行 `ZStackSupport:连通检查`。

## 使用方式

| 用法 | 示例 | 预期行为 |
|------|------|----------|
| 直接问 | `L3 网络是什么？` | 直接中文回答，不查 MCP |
| 具体支持事件 | `客户升级后云主机迁移失败，日志如下...` | 先按问题性质路由：源码/机制类必须先查 GitHub；历史相似查 BBS；已知缺陷/版本跟踪查 Jira；版本边界/标准口径查 Confluence；OS/厂商问题查 Tavily；需要并行时请显式要求“用多 agent 并行深查” |
| 单点查证 | `这个 API 在源码里怎么走？` | 只查 GitHub 源码 |
| 历史案例 | `有没有类似历史案例？` | 只查 BBS/Jira 等历史来源 |
| 完整事件分析 | `升级后云主机迁移失败，帮我分析根因和下一步` | 输出完整 Intake、证据映射、多来源查证和闭环 |
| 变更方案 | `ZStackSupport:变更方案 基于上面的分析生成标准变更方案` | 复制并修改标准 Word 模板，输出 ZStack 运维变更方案 DOCX |
| 故障报告 | `ZStackSupport:故障报告 基于上面的分析生成标准故障报告` | 复制并修改标准 Word 模板，输出 ZStack 企业版故障分析报告 DOCX |
| 环境配置 | `ZStackSupport:环境配置 快照当前配置` | 只显示变量存在性、作用域和格式状态，不输出密钥值 |
| 连通检查 | `ZStackSupport:连通检查` | 只读检查 GitHub、BBS、Tavily、Atlassian MCP |

多轮追问建议继续带上技能名，例如：

```text
ZStackSupport:事件分析 继续上一个问题，查一下这个修复有没有合到 4.8.x
```

Codex 的技能触发由宿主控制，普通追问不一定会自动重新加载插件技能；继续指定 `事件分析` 可以避免多轮会话掉出工作流。

## 显式并行深查

进入多来源查证、修复版本/回合确认、正式根因分析、来源冲突或深查路径时，事件分析默认由主 agent 查证汇总。需要并行时请在请求中明确写“用多 agent 并行深查”；若宿主未暴露或不允许 subagent，会明确降级为主 agent 查证。

显式并行深查拆分：

```text
源码/版本 agent：只查 GitHub 源码、commit、tag、release branch、调用链、版本差异；不得查询 Jira/Confluence/BBS/Tavily。
历史案例 agent：ZStack 知识社区(BBS) 相似案例、差异、可复用验证动作。
内部跟踪 agent：Jira 缺陷/需求状态、影响版本、修复版本、关联项；必要时补 Confluence 内部口径。
文档/外部 agent：官网文档、Confluence 文档边界、Tavily 厂商/OS/外部生态资料。
```

## 内部链接输出策略

本插件面向公司内部同事使用。BBS 帖子、Jira/TIC/SUG/BUG 工单和 Confluence 文档的编号、标题摘要和链接可以直接保留，并必须尽量输出为 Markdown 可点击链接。BBS 链接格式为 `[帖子标题](http://bbs.zstack.io/forum.php?mod=viewthread&tid=14121)`；Jira/TIC 链接格式为 `[TIC-5786](http://jira.zstack.io/browse/TIC-5786)`。不得输出 `forum.php?...` 这种相对链接，也不要把 `tid=14121` 包成不可跳转的伪链接。仍然禁止输出账号、Token、Authorization、原始页面正文、评论原文、附件、客户原始日志和原始 MCP 载荷。

## 需要配置的环境变量

插件不保存任何账号、密码或 Token。每位同学都需要在自己的 Windows 用户环境变量里配置：

```text
GITHUB_MCP_TOKEN
ZSTACK_BBS_AUTHORIZATION
TAVILY_HIKARI_TOKEN
ATLASSIAN_AUTHORIZATION
```

其中 Jira/Confluence 现在只需要 **1 个变量**：`ATLASSIAN_AUTHORIZATION`。不再要求分别配置 `JIRA_USERNAME`、`JIRA_PASSWORD`、`CONFLUENCE_USERNAME`、`CONFLUENCE_PASSWORD`，也不推荐继续使用旧的 `ATLASSIAN_BASIC_AUTH`。

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

如果诊断脚本提示旧变量仍存在，确认不再需要后可手动清理；不要把真实值粘贴到聊天或文档里：

```powershell
[Environment]::SetEnvironmentVariable('ATLASSIAN_BASIC_AUTH', $null, 'User')
```

## Word 模板生成依赖

`变更方案` 和 `故障报告` 技能通过 Python 脚本把 AI 写好的结构化内容写入标准 Word 模板。脚本本身只依赖 Python 和 `python-docx`，不生成业务内容、不硬编码根因/风险/步骤。

在 Codex Desktop 中优先使用 Codex bundled Python；如果系统 `python` 是 Windows Store alias，不代表技能不可用。只有脱离 Codex 在普通终端手工运行脚本时，才需要自行安装系统 Python 和 `python-docx`。

LibreOffice/`soffice` 不是生成 DOCX 的硬依赖，只用于自动把 DOCX 渲染成 PDF/PNG 做视觉 QA。未安装 LibreOffice 时，应说明“DOCX 已生成，未完成自动视觉渲染 QA”，不要写成生成失败。若本机安装了 Microsoft Word，诊断脚本会报告 Word COM 可用性，供人工或后续自动化验证参考。

## 环境配置与 Windows 变量录入

### 环境配置技能怎么用

`环境配置` 是专门用来配置和检查连接器变量的技能。它不会要求你把 Token、密码、Authorization 或 base64 值粘贴到聊天里，也不会在输出里打印真实密钥。

常用聊天命令：

```text
ZStackSupport:环境配置 快照当前配置
ZStackSupport:环境配置 帮我录入连接器变量
ZStackSupport:环境配置 只补充缺失变量
```

使用建议：

1. 先发 `ZStackSupport:环境配置 快照当前配置`，确认四个变量是否存在、作用域在哪里、格式是否正确。
2. 如果缺变量，发 `ZStackSupport:环境配置 帮我录入连接器变量`。Codex 会打开一个可见 PowerShell 配置窗口，你在窗口里输入密钥；不要把密钥发到聊天里。
3. 如果只想补缺失项，发 `ZStackSupport:环境配置 只补充缺失变量`，已有变量会保留。
4. 窗口录入完成后，重启 Codex 或打开新线程。
5. 再运行 `ZStackSupport:环境配置 快照当前配置` 和 `ZStackSupport:连通检查` 验证。

快照输出只包含变量名、是否存在、作用域、格式检查和修复建议。录入窗口会写入 Windows 用户变量，并尽量同步到当前进程；但 MCP 工具注入通常仍需要重启 Codex 或新开线程。

如果你不通过聊天技能，也可以从仓库根目录手动打开同一个可见配置窗口。

### 手动录入环境变量

推荐先用技能快照当前配置：

```text
ZStackSupport:环境配置 快照当前配置
```

推荐方式：从仓库根目录打开可见 PowerShell 配置窗口，一次录入四个变量。脚本只写入 Windows 用户变量，不打印密钥内容。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\plugins\zstack-support\scripts\open-env-config-window.ps1
```

如果只想补充缺失变量，保留已有变量：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\plugins\zstack-support\scripts\open-env-config-window.ps1 -SkipExisting
```

也可以使用下面的一次性 PowerShell 模板。把尖括号内容替换成自己的值后执行；注意这类命令会进入本机命令历史，公共电脑上更推荐使用上面的可见配置窗口。

```powershell
$githubToken = '<github-token>'
$tavilyToken = '<tavily-token>'
$bbsUser = '<bbs-username>'
$bbsPassword = '<bbs-password>'
$atlassianUser = '<jira-confluence-username>'
$atlassianPassword = '<jira-confluence-password>'

$bbsAuth = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("$bbsUser`:$bbsPassword"))
$atlassianAuth = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("$atlassianUser`:$atlassianPassword"))

[Environment]::SetEnvironmentVariable('GITHUB_MCP_TOKEN', $githubToken, 'User')
[Environment]::SetEnvironmentVariable('TAVILY_HIKARI_TOKEN', $tavilyToken, 'User')
[Environment]::SetEnvironmentVariable('ZSTACK_BBS_AUTHORIZATION', $bbsAuth, 'User')
[Environment]::SetEnvironmentVariable('ATLASSIAN_AUTHORIZATION', $atlassianAuth, 'User')
```

手动 PowerShell 用户变量方式：

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

## ZStack 日志路径基准

插件内置日志路径基准，避免事件分析时再生成不存在的路径。当前默认只认可以下常用路径：

```text
管理节点：/usr/local/zstack/apache-tomcat/logs/management-server.log*
计算节点：/var/log/zstack/zstack-kvmagent.log*
```

不要默认使用这些幻觉路径：

```text
/var/log/zstack/management-server.log*
/var/log/zstack/kvmagent.log*
```

如果组件或部署方式不确定，先用只读命令定位：

```bash
find /usr/local/zstack /var/log/zstack -maxdepth 6 -type f \
  \( -name '*management-server*.log*' -o -name '*kvmagent*.log*' -o -name '*zstack*.log*' \) \
  2>/dev/null | sort
```

## 验证安装

如果裸 `codex` 命令不可执行，先运行 `check-local-dependencies.ps1` 查看可用 Codex 路径。

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
ZStackSupport:连通检查
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

然后重新执行安装脚本，或在确认 `codex` 命令可执行后运行 `codex plugin add zstack-support@zstack-support-local`。更新后请新开 Codex 线程测试，避免旧线程继续使用旧缓存。

## 更多文档

- 插件说明：[plugins/zstack-support/README.md](plugins/zstack-support/README.md)
- MCP 连接器说明：[plugins/zstack-support/CONNECTORS.md](plugins/zstack-support/CONNECTORS.md)
- 连通检查技能：[plugins/zstack-support/skills/连通检查/SKILL.md](plugins/zstack-support/skills/连通检查/SKILL.md)
- 日志路径基准：[plugins/zstack-support/skills/ZStack Support Knowledge/references/log-paths.md](plugins/zstack-support/skills/ZStack%20Support%20Knowledge/references/log-paths.md)
