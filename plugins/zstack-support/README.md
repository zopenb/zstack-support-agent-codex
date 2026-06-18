# ZStack Support Agent（源码级分析）

ZStack Support Agent（源码级分析），基于证据优先方法论，结合 GitHub 源码分析（zstack + zstack-utility）、ZStack知识社区(BBS) 历史参考、Tavily 外部 Web/厂商论坛参考和 Jira/Confluence 内部只读参考，按问题类型动态选择直接回答、主动支持事件查证、单点查证、多来源查证或完整事件分析。具体 ZStack 客户事件先按问题性质路由：源码/机制/调用链/代码定位必须先查 GitHub，历史相似查 BBS，已知缺陷/版本跟踪查 Jira，版本边界/标准口径查 Confluence，OS/厂商/外部生态查 Tavily；需要并行时请显式要求“用多 agent 并行深查”。内置 E0-E5 证据分级体系、4 类中文公开标签和 11 种闭环决策类型。

> **Disclaimer:** 本套件辅助技术支持分析，所有输出应由工程师审核确认后再用于客户沟通。

## 适用角色

- **渠道工程师** — 快速分析 ZStack 支持事件，自动结合源码和 ZStack知识社区(BBS) 进行诊断
- **技术支持工程师** — 按照标准化流程输出结构化的分析报告和交接文档
- **技术支持团队负责人** — 通过统一的分析框架确保团队输出质量和一致性

## 快速命令

| 命令 | 说明 |
|------|------|
| `@事件分析` | 粘贴事件描述/错误日志/截图，自动完成证据分析+源码查证+ZStack知识社区参考+外部 Web 参考+闭环决策 |
| `@环境配置` | 快照或录入 GitHub、BBS、Tavily、Jira/Confluence 连接器变量，不输出密钥值 |
| `@交接摘要` | 从当前分析结果生成渠道安全的交接文档 |
| `@脱敏检查` | 检查文档是否包含敏感信息，确保可安全分享给客户 |

## 三种使用方式

| 使用方式 | 示例 | 行为 |
|----------|------|------|
| 直接问 | L3 网络是什么？ | 直接中文回答，不查 MCP |
| 具体支持事件 | 客户升级后云主机迁移失败，日志如下... | 先按问题性质路由：源码/机制类必须先查 GitHub；历史相似查 BBS；已知缺陷/版本跟踪查 Jira；版本边界/标准口径查 Confluence；OS/厂商问题查 Tavily；需要并行时请显式要求“用多 agent 并行深查” |
| 轻量证据答复 | 这个报错能忽略吗？怎么回复客户？ | 简洁回答，但 ZStack 具体问题至少查 2 个关键来源 |
| 单点查证 | 这个 API 在源码里怎么走？ / 有没有类似历史案例？ | 只查对应来源 |
| 完整事件分析 | 升级后云主机迁移失败，帮我分析根因和下一步 | 先结构化 Intake，再按需多来源查证和闭环 |
| 环境配置 | 快照当前配置 / 帮我录入连接器变量 | 只显示变量存在性、作用域和格式状态；录入密钥时走隐藏输入脚本 |

多轮追问建议继续带上技能名，例如：

```text
zstack-support:事件分析 继续上一个问题，查一下这个修复有没有合到 4.8.x
```

Codex 的技能触发由宿主控制，普通追问不一定会自动重新加载插件技能；继续指定 `事件分析` 可以避免多轮会话掉出工作流。

## 技能列表

| 技能 | 说明 |
|------|------|
| 事件分析 | 核心技能。先判断入口类型；低风险概念问题直接答，源码/机制类事件必须先查 GitHub，历史相似查 BBS，已知缺陷/版本跟踪查 Jira，版本边界/标准口径查 Confluence；需要并行时请显式要求“用多 agent 并行深查”；复杂事件输出 Intake、证据映射、参考证据、安全行动建议和闭环决策 |
| 源码查证 | 单点源码求证路径，默认只查 GitHub 源码、commit、tag、release branch、调用链和版本差异 |
| 环境配置 | 快照和引导录入插件 MCP 连接器环境变量，禁止在聊天中收集或输出真实密钥 |
| 连通检查 | 显式触发的只读 MCP 烟测，检查 GitHub、BBS、Tavily、Jira/Confluence 是否注入和可查询 |
| 交接摘要 | 从分析结果中提取问题摘要、影响范围、时间线、最强证据、已排除方向和下一步行动，生成渠道安全的交接文档 |
| 脱敏检查 | 逐项检查凭证、许可证、客户原始数据、内部系统引用、内部标识、证据标签完整性和 unsupported 根因声明 |

## 显式并行深查

进入多来源查证、修复版本/回合确认、正式根因分析、来源冲突或深查路径时，事件分析默认由主 agent 查证汇总。需要并行时请在请求中明确写“用多 agent 并行深查”；若宿主未暴露或不允许 subagent，会明确降级为主 agent 查证。

显式并行深查拆分：

```text
源码/版本 agent：只查 GitHub 源码、commit、tag、release branch、调用链、版本差异；不得查询 Jira/Confluence/BBS/Tavily。
历史案例 agent：ZStack知识社区(BBS) 相似案例、差异、可复用验证动作。
内部跟踪 agent：Jira 缺陷/需求状态、影响版本、修复版本、关联项；必要时补 Confluence 内部口径。
文档/外部 agent：官网文档、Confluence 文档边界、Tavily 厂商/OS/外部生态资料。
```

## 快速上手：配置 MCP 连接器

本套件通过 MCP 连接器对接 GitHub、ZStack知识社区(BBS)、Tavily 和 Atlassian，实现源码查证、历史参考、外部 Web/厂商论坛参考和内部只读工单/文档参考的自动化分析。当前分发包默认通过 Windows 环境变量注入凭据。

### 需要配置的环境变量

```text
GITHUB_MCP_TOKEN
ZSTACK_BBS_AUTHORIZATION
TAVILY_HIKARI_TOKEN
ATLASSIAN_AUTHORIZATION
```

`ATLASSIAN_AUTHORIZATION` 需要手动配置为完整 Header 值：`Basic <base64(username:password)>`。

Jira/Confluence 现在只需要 **1 个变量**：`ATLASSIAN_AUTHORIZATION`。不再要求分别配置 `JIRA_USERNAME`、`JIRA_PASSWORD`、`CONFLUENCE_USERNAME`、`CONFLUENCE_PASSWORD`，也不推荐继续使用旧的 `ATLASSIAN_BASIC_AUTH`。

### 每个凭据怎么获取

| 环境变量 | 获取方式 | 填写格式 |
|----------|----------|----------|
| `GITHUB_MCP_TOKEN` | 在 GitHub 个人设置中创建 Personal Access Token：**Settings → Developer settings → Personal access tokens**。优先使用 fine-grained token；用于公开 ZStack 源码查证时，只需只读仓库元数据和内容权限。如果团队有 GitHub/Copilot MCP 统一要求，以管理员要求为准。 | 原始 token，例如 `github_pat_...` |
| `ZSTACK_BBS_AUTHORIZATION` | 向团队获取 ZStack知识社区(BBS) 账号。将 `username:password` 转成 base64，再加 `Basic ` 前缀。 | `Basic <base64(username:password)>` |
| `TAVILY_HIKARI_TOKEN` | 向 Tavily Hikari MCP 网关维护者获取。当前插件连接的是团队网关 `https://tavily.zopen1.com/mcp`，不要默认把公网 Tavily token 当成可用值。 | 原始 token |
| `ATLASSIAN_AUTHORIZATION` | 使用 Jira/Confluence 账号，服务地址为 `http://jira.zstack.io` 和 `http://confluence.zstack.io`。将 `username:password` 转成 base64，再加 `Basic ` 前缀。 | `Basic <base64(username:password)>` |

### Basic Auth 怎么编码

在 PowerShell 中执行：

```powershell
$pair = 'username:password'
$base64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($pair))
$base64
```

然后这样使用：

```text
ZSTACK_BBS_AUTHORIZATION=Basic <base64>
ATLASSIAN_AUTHORIZATION=Basic <base64>
```

Atlassian 特别注意：`ATLASSIAN_AUTHORIZATION` 要填完整 Header 值，必须包含 `Basic ` 前缀。旧环境如果还配置了 `ATLASSIAN_BASIC_AUTH=<base64>`，安装脚本会兼容迁移，但新安装不再推荐使用旧变量。

### Windows 怎么录入

推荐先用技能快照当前配置：

```text
zstack-support:环境配置 快照当前配置
```

推荐方式：从 marketplace 仓库根目录运行交互式脚本，一次录入四个变量。脚本只写入 Windows 用户变量，不打印密钥内容。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\plugins\zstack-support\scripts\set-user-env.ps1
```

如果只想补充缺失变量，保留已有变量：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\plugins\zstack-support\scripts\set-user-env.ps1 -SkipExisting
```

也可以使用下面的一次性 PowerShell 模板。把尖括号内容替换成自己的值后执行；注意这类命令会进入本机命令历史，公共电脑上更推荐使用上面的交互式脚本。

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

Windows 图形界面方式：

1. 打开开始菜单。
2. 搜索“编辑账户的环境变量”。
3. 点击“环境变量”。
4. 在“用户变量”中新增上面四个变量。
5. 保存后重启 Codex 或打开新线程。

录入后，从 marketplace 仓库根目录运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\plugins\zstack-support\scripts\install.ps1
```

### 不打印密钥的检查方式

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

### GitHub 连接器

使用 GitHub 官方远程 MCP 服务器：

1. 设置 Windows 用户或机器环境变量 `GITHUB_MCP_TOKEN`
2. 重启 Codex 或打开新线程
3. 运行 `codex mcp list`，确认 `github` 为 enabled

不要把真实 Token 写入 `.mcp.json` 或插件仓库。

详细配置、ZStack知识社区(BBS) 和 Tavily 连接器说明参见 [CONNECTORS.md](CONNECTORS.md)。

## 连接器能力一览

| 连接器 | 增强能力 | 安装要求 |
|--------|----------|----------|
| **GitHub** | 自动只读查询 zstackio/zstack 和 zstackio/zstack-utility 源码，解释 API/配置/调用路径等产品机制 | Windows 环境变量 `GITHUB_MCP_TOKEN` |
| **ZStack知识社区(BBS)** | 自动查询历史相似事件，提供相似症状参考和可复用验证动作 | Windows 环境变量 `ZSTACK_BBS_AUTHORIZATION` |
| **Tavily** | 搜索外部公开 Web、OS/厂商文档和论坛，辅助分析 Linux、Windows、Red Hat、Ubuntu、内核、QEMU/KVM、libvirt、Ceph、GPU 驱动等非 ZStack 问题 | Windows 环境变量 `TAVILY_HIKARI_TOKEN` |
| **Atlassian** | 只读查询 Jira 工单和 Confluence 内部文档。Jira 用于已知缺陷、需求编号、修复状态、影响/修复版本；Confluence 用于内部说明、版本边界、操作规范、兼容性矩阵和产品口径 | 共享远端 MCP `zstack_atlassian_shared`；Windows 环境变量 `ATLASSIAN_AUTHORIZATION=Basic <base64(username:password)>` |

> 不连接任何连接器也可正常使用。源码、ZStack知识社区、外部 Web 和 Atlassian 参考部分会标注“MCP 查询未完成”并跳过，分析基于当前案例证据进行。Tavily 和 Atlassian 结果只作为 E3 参考，不能替代当前客户证据，也不能单独闭环事件。

## ZStack 日志路径基准

事件分析涉及日志收集时必须使用内置日志路径基准，避免生成不存在的路径。当前默认只认可以下常用路径：

```text
管理节点：/usr/local/zstack/apache-tomcat/logs/management-server.log*
计算节点：/var/log/zstack/zstack-kvmagent.log*
```

不要默认使用这些幻觉路径：

```text
/var/log/zstack/management-server.log*
/var/log/zstack/kvmagent.log*
```

组件或部署方式不确定时，先让用户执行只读定位命令：

```bash
find /usr/local/zstack /var/log/zstack -maxdepth 6 -type f \
  \( -name '*management-server*.log*' -o -name '*kvmagent*.log*' -o -name '*zstack*.log*' \) \
  2>/dev/null | sort
```
