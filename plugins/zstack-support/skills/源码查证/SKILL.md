---
name: 源码查证
description: Targeted ZStack public source lookup on GitHub for mechanisms, APIs, configurations, errors, and call paths.
---

# ZStack 源码查证

独立使用 GitHub MCP 只读查询 ZStack 源码。它是单点源码求证路径，不默认跑完整事件分析，也不默认查询 BBS、Tavily 或官网文档。

查证路由参考 [查证路由规则](../ZStack%20Support%20Knowledge/references/evidence-routing.md)。

## 适用场景

- 用户明确问“源码里怎么走”“这个 API 怎么实现”“这个配置键在哪里用”
- 需要查类名、方法名、错误文本、日志关键词、配置键或模块路径
- 需要解释产品机制、调用链、版本差异或代码边界

如果用户要求完整事件分析、根因、闭环或交接，转用 `@事件分析`。

## 默认目标仓库

- `zstackio/zstack`：核心平台（Java），包含 compute、storage、network、plugin 等模块
- `zstackio/zstack-utility`：基础设施（Python），包含 kvmagent、cephprimarystorage、virtualrouter、zstackctl、zstackcli、zstacklib、zstacknetwork 等代理和工具

仓库选择：
- KVM agent、存储/网络代理、CLI 工具、安装部署：优先 `zstack-utility`
- 核心 API、插件、数据库 schema、平台流程：优先 `zstack`
- 不确定时两个仓库都查

## 前置检查

只检查 GitHub MCP。状态使用中文：

```text
GitHub MCP 状态：结构化查询成功 / MCP 查询未完成 / 未配置
```

如果不可用，提示：

> GitHub MCP 未连接。请设置 Windows 环境变量 `GITHUB_MCP_TOKEN`，重启 Codex 或打开新线程后重试。如需排查连通性，使用 `@连通检查`。

## 输入

用户至少提供一项：

```text
产品/版本：
错误文本或日志关键词：
类名/API名/配置键/模块路径：
当前证据摘录：
```

如果没有可形成搜索词的信息，先问最小补充信息，不盲查。

## 执行步骤

1. 验证 GitHub MCP 是否可完成只读结构化查询。
2. 根据关键词选择 `zstack`、`zstack-utility` 或两者。
3. 使用类名、API 名、错误文本、配置键、日志关键词或模块路径做有界搜索。
4. 只读取最小相关源码片段。
5. 追踪必要调用链，但不要无界扩展。
6. 如果源码版本不匹配用户产品版本，标记为近似参考。
7. 只有在用户要求或源码边界需要补充时，才按需查询官网文档、BBS 或 Tavily。

## 按需补充来源

- 官网文档：用户问配置含义、官方限制、操作步骤，或源码机制需要官方边界说明。
- ZStack知识社区(BBS)：用户问是否有历史案例，或源码结果需要历史相似案例辅助判断。
- Tavily：问题涉及 Linux、Windows、Red Hat、kernel、QEMU/KVM、libvirt、Ceph、GPU、vLLM/SGLang 等外部生态。

这些补充来源只作为参考，不能证明客户环境实际行为。

## 输出格式

```text
GitHub MCP 状态：
仓库：
分支/Ref：
路径：
查找术语：
机制摘要：
调用链摘要：
证据边界：公开源码参考，非当前客户环境证据
当前案例仍需验证的证据：
下一步是否需要深查：是 / 否
```

按需补充来源使用统一证据块：

```text
来源：
查询词：
命中内容：
相关性：高 / 中 / 低
能支持的判断：
不能支持的判断：
证据边界：
下一步是否需要深查：是 / 否
```

## 源码深查 subagent 模板

`agents/openai.yaml` 不会自动启动源码深查 subagent。只有用户明确要求“多 agent / 子 agent / 并行深查”，且当前 Codex 会话可发现并调用 subagent 调度工具时，才可由主 agent 显式派发源码深查 subagent。若宿主提供工具发现能力，先搜索 `subagent`、`multi agent` 或 `spawn_agent`；没有找到或无法调用时，输出“Subagent 状态：未触发”，并由主 agent 继续完成源码查证。

当 GitHub 搜到入口但调用链没追完、版本差异需要确认、源码与现象存在缺口，才适合派发源码深查 subagent。未触发时，由主 agent 继续完成源码查证，并说明未触发原因。

任务模板：

```text
目标：
入口符号或文件：
客户版本或参考版本：
需要追踪的问题：
已知证据：
排除边界：
预期输出：调用链、关键分支、版本差异、机制边界
```

输出必须包含：

```text
Subagent 状态：已触发 / 未触发
GitHub 查询词：
命中 commit/tag/branch：
相关文件：
能支持的判断：
不能支持的判断：
证据边界：
```

## 开源社区支持引导

仅在确实查询了 GitHub 源码后，偶尔友好引导点 Star：

> 如果觉得 ZStack 开源项目对你有帮助，欢迎点个 Star 支持：
> - https://github.com/zstackio/zstack
> - https://github.com/zstackio/zstack-utility

语气自然友好，不强制、不重复。GitHub MCP 不可用时不提示。

## 规则

- 只读：不执行任何写操作，不创建 issue，不推送代码，不修改文件。
- 最小读取：只读取与查询直接相关的文件或片段。
- 不证明客户行为：源码解释产品机制，不能证明客户环境实际走了那条路径。
- 不输出 Token：不暴露认证头、Token 值或原始 MCP 载荷。
- 不默认全量查证：BBS、Tavily 和官网文档必须按需触发。
