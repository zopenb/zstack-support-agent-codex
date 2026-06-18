# 查证路由规则

本规则用于决定是否回答、追问、单点查证、多方查证或深查。所有技能优先引用本文件，避免在多个技能中重复维护路由逻辑。默认工作模式为“支持工程优先”：具体 ZStack 支持事件必须主动查证，只有低风险概念问题才直接回答。

## 入口判断

收到用户问题后，先判断问题类型，再决定是否使用 MCP 或完整事件分析。

| 类型 | 触发条件 | 动作 |
|------|----------|------|
| 低风险直答 | 概念解释、通用机制、常见排查思路；不涉及具体版本、客户现场、报错、兼容性、客户回复口径、根因定论 | 直接回答，不查 MCP |
| 支持事件默认查证 | 用户粘贴客户反馈、日志、告警、失败 API、错误文本、截图转写、版本异常、兼容性问题、客户回复口径；即使没有明确说“分析”也属于支持事件 | 先按问题性质路由。源码/机制/调用链/代码定位必须先查 GitHub；历史相似再查 BBS；已知缺陷/版本跟踪再查 Jira；版本边界/标准口径加查 Confluence；OS/厂商/外部生态加查 Tavily。输出可以简洁，但必须说明证据边界 |
| 轻量证据答复 | 用户问具体报错能否忽略、是否预期、兼容性边界、客户口径、是否影响功能；已有错误文本或截图可形成搜索词 | 简洁回答，但 ZStack 具体问题至少查 2 个关键来源；客户口径类优先 BBS/Jira，机制类优先 GitHub |
| 最小补充信息 | 缺少版本、错误文本、对象类型、操作路径；无法形成有效搜索词 | 先问最小必要信息 |
| 单点求证 | 用户只问源码、历史案例、官方文档或外部生态资料中的一个方向 | 只查对应来源 |
| 多方并行查证 | 升级后异常、迁移、存储、网络、HA、数据风险、正式根因分析、需要多来源互相印证 | 由主 agent 查证汇总；用户显式要求多 agent / 并行深查时才尝试 subagent 路径 |
| 修复版本/回合确认 | 用户问哪个版本修复、是否合入某个版本线、是否回合到 4.x/5.x、fixVersion 是否真实发布、某版本是否包含某修复 | 必须同时查 Jira/Confluence 与 GitHub 提交/tag/分支；不能只靠 Jira fixVersion 下结论 |
| 深查 | 证据不足、来源冲突、调用链未追完、历史案例过多、日志量大、或多来源查证耗时明显 | 由主 agent 深查；用户明确要求多 agent / 并行深查时才尝试 subagent 路径 |

具体 ZStack 支持事件默认进入“支持事件默认查证”，不要求用户显式说“分析”。完整大报告仍只在用户明确要求完整分析、故障、根因、交接、闭环或提报研发材料时输出。简单概念问题不要默认跑完整工作流；但具体报错、兼容性、能否忽略、客户回复口径不能纯直答。

## 多轮追问 / 上下文续问

如果当前问题包含“这个修复”“这个问题”“继续查”“有没有合到某版本”“那 Jira 呢”“源码呢”“有没有类似案例”等指代上一轮事件的表达，必须继承上一轮已识别的故障对象、错误文本、版本、Jira/BBS/GitHub 线索和证据边界继续查证。

如果当前 Codex 宿主没有再次触发本技能，插件无法强制接管普通对话。首次分析结束时应提示：

```text
后续追问请继续在本线程使用 `@事件分析` 或 `zstack-support:事件分析`，并保留上一轮问题上下文。
```

如果用户已经重新指定本技能，严禁把续问当成全新问题从零开始；先复用上一轮上下文，再补查缺口。

## 轻量证据答复

轻量证据答复用于替代“完整大报告”和“无查证短答”之间的空档。目标是快速给出可交付口径，同时保留关键证据边界。

触发场景：

- 用户问“这个报错能否忽略”“是否正常”“是否影响功能”“怎么回复客户”
- 问题包含具体错误文本、OS/版本、组件名、截图转写或安装输出
- 需要判断兼容性、预期行为、组件边界或已知问题

默认查证策略：

- ZStack 组件、API、脚本、配置、错误文本：优先 GitHub 源码
- 兼容性、已知问题、客户口径：优先 BBS、Jira 或 Confluence
- OS、内核、驱动、第三方生态：优先 Tavily 或厂商文档
- ZStack 具体事件的轻量答复也必须至少查 2 个关键来源；如果问题涉及源码、机制、调用链、错误文本、类名、配置键、API、kvmagent、管理节点下发字段或代码定位，GitHub 必须是第一个关键来源。Jira/BBS/Confluence 只能补充历史和内部跟踪，不能替代 GitHub 源码查证
- 如果用户问“哪个版本修复 / 有没有合到某版本线 / 是否回合到 4.8.x / fixVersion 是否已经发布”，不得使用轻量证据答复的 1-2 来源限制，必须进入“修复版本/回合确认”路径。

## 源码优先硬约束

凡是问题包含以下任一特征，必须先完成 GitHub 查证，再查询 Jira/BBS/Confluence：

```text
源码 / 代码 / 调用链 / 机制 / 实现 / API / 类名 / 方法名 / 配置键 / 下发字段 /
kvmagent / management-server / KVMHost.java / vm_plugin.py / 报错堆栈 / NoneType / machineType / pciePortNums
```

执行要求：

- 首个查证动作必须是 GitHub code/search/commit/tag/branch 或文件读取。
- 若 GitHub MCP 不可用，必须明确写“GitHub 源码查证未完成”，并禁止输出“源码已确认”“代码逻辑确认”等结论。
- Jira/Confluence/BBS 只能作为内部跟踪、历史案例或设计背景；不得替代源码证据。
- 源码/版本 subagent 只允许查询 GitHub；不得查询 Jira、Confluence、BBS 或 Tavily。
- 如果主流程已经先查了 Jira/BBS，发现问题实际是源码/机制类，必须立即切回 GitHub，不得继续扩大 Jira/Confluence 搜索。

输出结构：

```text
结论：
适用条件：
依据：
影响范围：
建议验证：
客户回复口径：
证据边界：
```

轻量证据答复不要求输出完整 Intake、案例目录、完整证据映射和闭环决策，但必须说明依据和边界。

## 来源路由

| 来源 | 适用问题 | 不适用边界 |
|------|----------|------------|
| GitHub | API、类名、配置键、错误文本、调用链、源码机制、版本差异 | 不能证明客户环境实际行为；但源码/机制类结论必须先有 GitHub 查证 |
| ZStack知识社区(BBS) | 历史相似案例、相似症状、可复用验证动作 | 不能单独作为当前事件根因 |
| 官网文档 | 配置含义、官方限制、操作步骤、产品功能边界 | 不能替代当前现场证据 |
| Tavily | Linux、Windows、Red Hat、Ubuntu、kernel、QEMU/KVM、libvirt、Ceph、GPU、vLLM/SGLang 等外部生态问题 | 只能使用脱敏查询词，不能单独闭环 |
| Jira | 已知缺陷、需求编号、修复状态、影响版本、修复版本、组件归属、研发结论 | 只读内部参考，不能直接向客户输出原文、评论、附件或内部 URL |
| Confluence | 内部说明、版本边界、操作规范、发布说明补充、兼容性矩阵、产品口径 | 只读内部参考，不能直接向客户输出原文、附件或内部 URL |

## 日志路径路由

涉及 ZStack 日志收集时，必须引用 `log-paths.md` 的基准路径。不要根据通用 Linux 习惯临时编造路径。

确定路径：

```text
管理节点：/usr/local/zstack/apache-tomcat/logs/management-server.log*
计算节点：/var/log/zstack/zstack-kvmagent.log*
```

禁止默认建议：

```text
/var/log/zstack/management-server.log*
/var/log/zstack/kvmagent.log*
```

如果用户没有说明对象是管理节点还是计算节点，或涉及未列出的组件日志，先问最小补充信息或给只读定位命令：

```bash
find /usr/local/zstack /var/log/zstack -maxdepth 6 -type f \
  \( -name '*management-server*.log*' -o -name '*kvmagent*.log*' -o -name '*zstack*.log*' \) \
  2>/dev/null | sort
```

## 修复版本 / 回合确认

凡是用户询问以下内容，必须进入本路径：

- 哪个版本修复
- 是否已经发布
- 是否合到某个版本线，例如 4.8.x、5.0.x、5.5.x
- fixVersion 是否可信
- 某缺陷、需求、告警、文案或行为变更是否包含在指定版本

强制查证顺序：

1. Jira：查内部缺陷/需求状态、fixVersion、影响版本、关联 issue。
2. GitHub：查公开提交、commit message、PR/merge 线索、tag、release branch、相关文件差异。
3. Confluence 或发布说明：仅在 Jira/GitHub 不足以解释版本边界时补充。
4. BBS：只作为历史现场/口径参考，不能证明代码合入。

GitHub 必查内容：

- 用 Jira key、缺陷号、需求号、错误文本、告警名、类名、资源类型等关键词搜索 commits 和 code。
- 查 `zstackio/zstack`、`zstackio/zstack-utility` 以及问题明确指向的相关仓库。
- 如果用户问具体版本线，优先查对应 tag/release branch 的文件内容或提交可达性；不要只查 master/main。
- 如果公开仓库没有命中，输出“GitHub 公开源码/提交未命中”，并说明这是证据边界，不等同于“没有修复”。

结论约束：

- 只有 Jira fixVersion，没有 GitHub commit/tag/分支证据时，只能说“内部跟踪标记/规划为某版本”，不能说“已在某版本修复”。
- 要回答“没有合到 4.8.x”，必须至少有以下之一：4.8.x tag/branch 查证未包含相关改动、提交不可达、发布说明/Confluence 明确排除，或 Jira 有明确未回合记录。
- 如果 GitHub 查询被限流、工具不可用或未完成，最终回答必须写“GitHub 提交/分支查证未完成，因此不能对是否合入指定版本线下最终结论”。
- Jira、BBS、Confluence 与 GitHub 结论冲突时，标注“来源冲突”，保守输出，不直接用 Jira 覆盖源码/提交证据。

本路径输出至少包含：

```text
Jira/内部跟踪：
GitHub 提交/分支查证：
指定版本线查证：
是否可确认已修复：
是否可确认已合入目标版本：
证据不足或冲突：
```

## 多方并行查证限制

- 普通多来源查证、修复版本/回合确认或深查默认由主 agent 完成。只有用户显式要求“多 agent / 子 agent / subagent / 并行深查 / 多路并行深查”时，才尝试发现并使用 `multi_agent_v1.spawn_agent` 等 subagent 调度工具并发查证。若宿主未暴露、不允许或调用失败，必须明确标注未触发原因并降级为主 agent 查证；不得假装已经并发。
- 只需要单一证据时，不启动多来源并行。
- 两个来源以内的轻量答复，可以由主 agent 直接并行调用工具完成。
- 输入不足时，不启动无效搜索，先问最小补充信息。
- 已有证据足够支撑当前回答时，不继续扩展来源。
- 所有查询必须只读，不输出 Token、Authorization、原始 MCP 载荷或未过滤的提供者输出。
- Tavily、BBS、Jira 和 Confluence 结果属于 E3 参考，不能单独关闭当前事件。

默认并发拆分：

```text
源码/版本 agent：只查 GitHub 源码、commit、tag、release branch、调用链、版本差异；禁止查询 Jira/Confluence/BBS/Tavily。
历史案例 agent：ZStack知识社区(BBS) 相似案例、差异、可复用验证动作。
内部跟踪 agent：Jira 缺陷/需求状态、影响版本、修复版本、关联项；必要时补 Confluence 内部口径。
文档/外部 agent：官网文档、Confluence 文档边界、Tavily 厂商/OS/外部生态资料。
```

主 agent 保持总控，负责当前证据整理、问题边界、最终合并和结论约束。子 agent 只负责各自来源，不跨来源扩展。主 agent 必须等待关键子 agent 结果再下最终结论；超时则标注“某来源查证未完成”，不得把未完成当成未命中。

## 深查触发规则

`agents/openai.yaml` 只声明 UI 元数据和 MCP 依赖，不会自动创建或启动 subagent。Subagent 不是插件静态配置能力，必须由当前会话暴露 subagent 调度工具，并由主 agent 在满足触发条件时显式派发。当前 Codex 宿主若暴露并允许 `multi_agent_v1.spawn_agent`，且用户显式要求并行深查，才真实派发有界子任务；否则由主 agent 深查。

默认使用主 agent 深查；只有用户显式要求多 agent / 并行深查，且 subagent 工具可用、任务可拆分时，才使用 subagent 并发深查。

| 深查方向 | 触发条件 | 输出目标 |
|----------|----------|----------|
| 主 agent 深查 | subagent 工具不可用、任务过小不可拆、或只需要 1-2 个来源 | 当前主 agent 完成查证、合并和边界说明 |
| 源码/版本 subagent | GitHub 搜到入口但调用链没追完；版本差异需要确认；修复版本/回合确认需要 commit/tag/branch | 只输出 GitHub commit、tag、release branch、调用链、关键分支、版本差异、机制边界；不得查询 Jira/Confluence/BBS/Tavily |
| 历史案例 subagent | BBS 命中过多；需要筛选相似度；历史案例之间结论冲突 | BBS 相似案例排序、差异、可复用验证动作 |
| 内部跟踪 subagent | 需要 Jira 缺陷/需求、影响版本、修复版本、关联项，或 Confluence 内部口径 | Jira/Confluence 脱敏摘要、状态、版本边界、能/不能支持的判断 |
| 文档/外部 subagent | 需要官网文档、发布说明、Tavily/厂商/OS 外部资料 | 文档来源、外部资料、版本边界、能/不能支持的判断 |

文档/外部 agent 可以在 3 个及以上来源、正式根因分析、外部生态问题或发布说明查证时派发；任务范围仅限官网文档、发布说明、Tavily/厂商/OS 外部资料，不能替代 GitHub 源码 agent。

### Subagent 显式调度规则

满足以下条件时才尝试触发 subagent：

- 进入多方并行查证、修复版本/回合确认或深查。
- 用户明确要求“多 agent / 子 agent / subagent / 并行深查 / 多路并行深查”。
- 当前 Codex 会话可发现并调用 subagent 调度工具，例如 `multi_agent_v1.spawn_agent`。
- 任务可拆成互不覆盖的有界子任务。

当用户明确要求多 agent / 并行深查时，主 agent 必须先确认是否有 subagent 调度工具。若宿主提供工具发现能力，先搜索 `subagent`、`multi agent` 或 `spawn_agent`；若当前工具列表已明确存在 `multi_agent_v1.spawn_agent` 等可调用工具，且宿主策略允许当前任务派发 subagent，必须真实派发有界子任务。没有找到、宿主策略不允许或无法调用时，标注失败层为“工具未暴露 / subagent 未触发”，并降级为主 agent 查证。

如果只是低风险直答、单点求证或两个来源以内的轻量答复，不做 subagent 工具发现。

触发后：

- 主 agent 保持总控，继续整理问题、关键路径查证和最终合并。
- 源码/版本 subagent 只查 GitHub，不查 Jira/Confluence/BBS/Tavily；如果 GitHub 不可用，只能返回“GitHub 查证未完成”，不得改查 Jira。
- 历史案例 subagent 只查 BBS，不查 Jira/Confluence。
- 内部跟踪 subagent 只查 Jira/Confluence，不输出内部原文和内部 URL。
- 文档/外部 subagent 使用脱敏关键词查询官网文档、发布说明或 Tavily。
- 子 agent 输出必须使用统一证据块，并说明不能支持的判断。

未触发时必须明确状态：

```text
Subagent 状态：未触发
原因：当前会话未暴露 subagent 调度工具 / 宿主策略未允许当前任务派发 subagent / subagent 调用失败 / 任务不适合拆分 / 仅需 1-2 个来源
降级动作：由主 agent 继续完成必要查证
```

### 复测模板

```text
普通模式复测：
输入：镜像存储可用容量百分比<10%，ZStack-backup，4.8.0 备份服务器告警却提示镜像存储空间不够，哪个版本修复了？
期望：进入修复版本/回合确认；必须输出 Jira/内部跟踪、GitHub 提交/分支查证、指定版本线查证。

追问复测：
输入：这个修复有没有搞到 4.8.x 的哪个版本？
期望：必须查 GitHub commit/tag/branch 或明确 GitHub 查证未完成。

多 agent 复测：
输入：用多 agent 并行深查：镜像存储可用容量百分比<10%，ZStack-backup，4.8.0 备份服务器告警却提示镜像存储空间不够，哪个版本修复了？
期望：说明是否触发源码深查 subagent 和历史案例 subagent；若未触发，必须标注原因和降级动作。

源码优先复测：
输入：machineType=pc 时 pciePortNums 为什么没下发？kvmagent 里 NoneType + int 是哪段代码来的？
期望：首个查证动作必须是 GitHub；必须输出 GitHub 仓库、文件路径、查找术语和源码边界。Jira/BBS/Confluence 只能在 GitHub 之后作为补充参考。

失败层标注：
路由失败 / GitHub 未查 / 源码问题先查了 Jira / subagent 未触发 / 工具未暴露 / 结论越界
```

## 统一证据块

所有来源返回证据时使用以下小块格式，便于主流程汇总：

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

## 中文状态词

| 状态 | 含义 |
|------|------|
| 工具可见 | 能看到 MCP 服务器或工具，但尚未证明可查询 |
| 已连接 | MCP 初始化成功，但尚未完成结构化查询 |
| 结构化查询成功 | 已完成只读查询并返回可解析数据 |
| MCP 查询未完成 | 超时、认证失败、schema 不匹配、环境缺失或只完成部分检查 |
| 未配置 | 当前会话没有暴露对应 MCP 或缺少必要环境变量 |

## Jira / Confluence 路由

只允许通过只读 Atlassian MCP 查询 Jira/Confluence，不创建、不更新、不评论。

Jira/Confluence 必须通过插件声明的共享远端 `zstack_atlassian_shared` MCP 查询。不要使用旧的 `zstack_atlassian` 本机适配器、`support_archive`、`support_sql_analyst` 或其他旧的全局 MCP 目标替代 Jira/Confluence；如果当前线程没有暴露 Jira/Confluence 工具，应标注 MCP 未注入当前线程，并跳过该来源。

优先查 Jira：

- 用户提供 Jira key、SUG、TIC、BUG、需求号或缺陷号
- 问题涉及已知缺陷、需求跟踪、缺陷状态、修复版本、影响版本
- BBS、源码或文档提示已有内部跟踪

优先查 Confluence：

- 用户询问内部文档、标准口径、操作步骤、发布说明补充
- 问题涉及版本边界、兼容性矩阵、研发/产品说明
- 需要把公开文档与内部说明做边界对齐

同时查 Jira 和 Confluence：

- 正式根因分析需要确认“缺陷/需求状态 + 内部口径”
- 兼容性或升级问题存在客户风险，需要确认修复状态和版本边界
- Jira 与公开来源结论不完整，需要 Confluence 补充说明

输出限制：

- Jira 只输出脱敏摘要、工单号、状态、影响版本、修复版本、组件、可公开行动建议。
- Confluence 只输出脱敏摘要、适用版本、版本边界、可公开行动建议。
- 不输出内部 URL、账号、Token、原始页面内容、原始工单描述、评论原文或未脱敏附件。
- 若 Jira/Confluence 与公开源码、BBS 或文档结论冲突，标注“来源冲突”，不要直接覆盖当前分析。

## 公开标签

| 标签 | 含义 |
|------|------|
| 已确认 | 当前证据可直接支持 |
| 较可能 | 多个线索支持，但仍缺少闭环证据 |
| 可能 | 有方向性线索，但证据弱 |
| 证据缺失 | 当前没有足够证据支持 |
