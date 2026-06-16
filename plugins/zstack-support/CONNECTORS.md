# 连接器

## 能力层级

**独立能力**（无连接器也完全可用）：
- 事件分析：证据优先全流程分析（Intake → 证据映射 → 安全行动 → 闭环决策）
- 交接摘要：从分析结果生成渠道安全交接文档
- 脱敏检查：文档安全检查
- 所有工作流方法论、案例模板、安全策略完整可用

**增强能力**（连接工具后增强）：
- GitHub → 自动只读查询 zstackio/zstack 和 zstackio/zstack-utility 源码，解释 API/配置/调用路径等产品机制，用事件关键词搜索相关代码
- ZStack知识社区(BBS) → 自动查询历史相似事件，提供相似症状参考和可复用验证动作
- Tavily → 搜索外部公开 Web、OS/厂商文档和论坛，辅助分析 Linux、Windows、Red Hat、Ubuntu、内核、QEMU/KVM、libvirt、Ceph、GPU 驱动等非 ZStack 问题
- Atlassian → 只读查询 Jira 工单和 Confluence 内部文档，辅助确认已知缺陷、需求编号、内部说明和版本边界

## GitHub 连接器

使用 GitHub 官方远程 MCP 服务器。当前分发包默认通过环境变量注入 Bearer Token。

### 开启步骤

1. 设置 Windows 用户或机器环境变量 `GITHUB_MCP_TOKEN`
2. 重启 Codex 或打开新线程
3. 运行 `codex mcp list`，确认 `github` 为 enabled
4. 运行 `zstack-support:连通检查`

### 认证方式

- **环境变量（当前分发包默认）**：设置本机环境变量 `GITHUB_MCP_TOKEN`
- **OAuth**：如后续改为 Codex OAuth 连接器模式，应移除 `.mcp.json` 中的 `bearer_token_env_var` 依赖，并重新验证插件安装行为

### 权限说明

- 免费 GitHub 用户即可使用基础功能（仓库浏览、代码搜索、文件读取）
- 部分高级功能可能需要 Copilot 订阅

> 没有连接器也完全可以使用——源码查证和 ZStack知识社区参考部分会标注“MCP 查询未完成”并跳过，核心分析基于当前案例证据独立运行。

## ZStack知识社区(BBS) 连接器

用于查询历史相似事件作为参考证据。

### 当前配置

套件已预配置 ZStack知识社区 MCP 连接（`.mcp.json`），连接信息：
- MCP server id：`zstack-bbs`（Codex 要求 server id 只能包含字母、数字、下划线和短横线）
- URL：`https://mcp.zopen.top:16666/mcp`
- 传输协议：streamable-http
- 认证：Basic Auth，通过本机环境变量 `ZSTACK_BBS_AUTHORIZATION` 注入完整 `Authorization` 头

### 可用工具

- `bbs_search` — 按关键词搜索 BBS 帖子
- `bbs_get_thread` — 获取指定帖子详情
- `bbs_latest` — 获取最新帖子列表
- `bbs_get_forum` — 获取论坛板块信息

### 开启步骤

1. 设置本机环境变量 `ZSTACK_BBS_AUTHORIZATION`
2. 在套件页面打开 **ZStack知识社区(BBS)** 连接器开关
3. 等待状态变为 connected

### 更换账号

如需使用自己的 BBS 账号，设置本机环境变量 `ZSTACK_BBS_AUTHORIZATION` 为完整 Basic Authorization 值：
```
ZSTACK_BBS_AUTHORIZATION=Basic <base64(username:password)>
```

> 没有连接器也完全可以使用——ZStack知识社区参考部分会标注“MCP 查询未完成”并跳过，核心分析基于当前案例证据独立运行。

## Tavily 外部 Web/厂商论坛连接器

用于查询公开 Web、OS/厂商文档和技术论坛，作为非 ZStack 问题的参考来源。例如 Linux/Windows 故障、Red Hat/Ubuntu 文档、内核、QEMU/KVM、libvirt、Ceph、GPU 驱动、vLLM/SGLang 等。

### 当前配置

套件已预配置 Tavily MCP 连接（`.mcp.json`），连接信息：
- MCP server id：`tavily_hikari`
- URL：`https://tavily.zopen1.com/mcp`
- 传输协议：streamable-http
- 认证：Bearer Token，通过本机环境变量 `TAVILY_HIKARI_TOKEN` 注入

### 开启步骤

1. 设置本机环境变量 `TAVILY_HIKARI_TOKEN`
2. 重启 Codex 或打开新线程
3. 运行 `codex mcp list`，确认 `tavily_hikari` 为 enabled
4. 运行 `zstack-support:连通检查`

### 证据边界

- Tavily 查询只能使用脱敏后的关键词，不得包含客户名称、内网地址、Token、许可证、完整日志包或其他敏感信息
- Tavily 结果属于 E3 公开外部参考，只能用于生成排查假设、验证动作和背景说明
- Tavily 结果不是当前客户现场证据，不能单独支撑根因结论，也不能单独闭环事件

## Atlassian Jira/Confluence 连接器

用于只读查询 Jira 工单和 Confluence 内部文档，作为已知缺陷、需求编号、内部说明和版本边界的参考来源。

### 当前配置

套件已预配置 Atlassian MCP 连接（`.mcp.json`），连接信息：
- MCP server id：`zstack_atlassian_shared`
- URL：`http://172.18.250.27:3340/mcp`
- 传输协议：streamable-http
- 只读保护：共享远端服务只应暴露 Jira/Confluence 查询类工具，不允许创建、更新或评论内容
- 认证：通过本机环境变量 `ATLASSIAN_AUTHORIZATION` 注入完整 Authorization Header；安装脚本会从 `ATLASSIAN_BASIC_AUTH=base64(username:password)` 派生该运行时变量，不在插件内保存真实密码

### 环境变量

```text
ATLASSIAN_BASIC_AUTH
ATLASSIAN_AUTHORIZATION
```

`ATLASSIAN_BASIC_AUTH` 必须放在 Windows 用户或机器环境变量中，值只写 `base64(username:password)`，不要带 `Basic ` 前缀。运行 `scripts\install.ps1` 后会自动派生 `ATLASSIAN_AUTHORIZATION=Basic <base64>`，这是 Codex 当前 `env_http_headers` 能识别的运行时 Header 变量。不要把密码、base64 值或完整 Header 写入 `.mcp.json`、`config.toml` 或插件仓库。

### 共享服务要求

Atlassian 连接器不再使用每台电脑本机 Node 适配器。分发给同事前，应确认目标电脑能访问共享远端 MCP：

```powershell
codex mcp get zstack_atlassian_shared
```

`codex mcp get zstack_atlassian_shared` 中的 URL 应为 `http://172.18.250.27:3340/mcp`，并且不能出现 `command`、`args`、`cwd` 等本机适配器字段。如果工具未注入但共享远端配置存在，连通检查应报告“已配置但未注入”，不要误判为“未配置”。

### 开启步骤

1. 设置 Windows 环境变量 `ATLASSIAN_BASIC_AUTH=base64(username:password)`
2. 运行插件安装脚本，自动生成 `ATLASSIAN_AUTHORIZATION=Basic <base64>`
3. 重启 Codex 或打开新线程
4. 运行 `codex mcp list`，确认 `zstack_atlassian_shared` 为 enabled
5. 运行 `zstack-support:连通检查`

### 证据边界

- Atlassian 查询只能用于内部参考，不直接面向客户转述原文
- 只能输出脱敏后的工单号、标题摘要、状态、版本边界和可公开行动建议
- 不创建、不更新、不评论 Jira/Confluence 内容
- 不输出内部 URL、账号、Token、原始页面内容、原始工单描述或未脱敏附件
