# CineFlow Skills

面向 **CineFlow**（Flutter + Go 的 Emby 第三方播放器）项目的 AI 编码技能包，
可直接被 **DeepSeek Harness (DSH)** 及其他支持 `SKILL.md` 约定的编码代理发现与加载。

> **本仓库的定位**：把「AI 怎么做这个项目」这套作业口径**版本化**，
> 使技能能被安装、升级、审计，而不是散落在某台机器的 `~/.dsh/skills` 里。

---

## 快速安装

> ⚠️ **最关键的一条**：技能必须是**扫描根的直接子项**（`<扫描根>/<name>/SKILL.md`）。
> DSH **刻意不支持**发现嵌套的 `**/SKILL.md`。
> 因此 **不要** clone 到 `~/.dsh/skills/cineflow-skills/`——那会多套一层，
> **27 个技能一个都不会被发现，且没有任何报错**。
> 装完请立刻跑 [`scripts/verify-install.ps1`](scripts/verify-install.ps1) 自检。

### 方式一：把这个仓库**直接**作为扫描根（推荐）

```bash
# ✅ 正确：仓库根 == 扫描根
git clone https://github.com/bsfcxz/cineflow-skills.git ~/.dsh/skills
```

Windows PowerShell：

```powershell
git clone https://github.com/bsfcxz/cineflow-skills.git "$env:USERPROFILE\.dsh\skills"
```

> 该目录若已存在其他技能，clone 会失败。此时改用方式三（只取需要的）。

### 方式二：克隆到**项目内**的扫描根（随项目走，团队共享）

DSH 会扫描项目根下的两个目录，**优先级高于全局**：

| 优先级 | 来源 | 路径 |
|---|---|---|
| 100 | `project-dsh` | `<项目根>/.dsh/skills` |
| 200 | `project-agents` | `<项目根>/.agents/skills` |
| 400 | `user-dsh` | `<dshHome>/skills` |

```bash
cd <你的 CineFlow 项目根>
git clone https://github.com/bsfcxz/cineflow-skills.git .dsh/skills
```

### 方式三：只取需要的技能（目录已有内容时）

```bash
git clone --depth 1 https://github.com/bsfcxz/cineflow-skills.git /tmp/cfs
cp -r /tmp/cfs/mp-code-review /tmp/cfs/mp-tdd ~/.dsh/skills/   # 按需选
```

### 安装后自检（强烈建议）

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify-install.ps1 -Root "$env:USERPROFILE\.dsh\skills"
```

退出码 `0` 才会被正常发现。它会检查层级、frontmatter、交叉引用与行尾，
**把「装了但静默失效」变成一句可执行的判断**。

---

## 技能清单

### 工程类（20）

| 技能 | 用途 |
|---|---|
| `mp-code-review` | 双轴审查：Standards（是否守本仓库规范）+ Spec（是否实现对了需求），两轴用**并行子代理**互不污染 |
| `mp-diagnosing-bugs` | 系统化排障：先复现、再最小化、再定位，禁止「猜着改」 |
| `mp-tdd` | 测试驱动开发流程 |
| `mp-domain-modeling` | 领域建模；含 `ADR-FORMAT.md` / `GLOSSARY-FORMAT.md` 模板 |
| `mp-codebase-design` | 代码结构设计；含 `DESIGN-IT-TWICE.md`（设计两遍再选） |
| `mp-improve-codebase-architecture` | 架构改进流程 |
| `mp-to-spec` | 把模糊需求转成可执行规格 |
| `mp-to-tickets` | 把规格拆成任务卡 |
| `mp-implement` / `mp-implement-spec` | 实现流程（后者面向已有规格） |
| `mp-prototype` | 原型验证 |
| `mp-research` | 技术调研 |
| `mp-wayfinder` | 大范围探索 / 路线规划 |
| `mp-triage` | 问题分诊（含 `OUT-OF-SCOPE.md` 的「什么不做」） |
| `mp-pr` | 提交 PR 的规范流程 |
| `mp-retro` | 复盘 |
| `mp-wizard` | 交互式引导（配 `template.sh`） |
| `mp-ask-matt` | 问答式求助 |
| `mp-grill-with-docs` | 结合文档追问需求 |
| `mp-setup-matt-pocock-skills` | ⚠️ **本仓库不建议运行**（见下方「注意事项」） |

### 协作类（7）

| 技能 | 用途 |
|---|---|
| `mp-grill-me` / `mp-grilling` | 反向追问：让 AI 先问清需求再动手 |
| `mp-handoff` | 交接文档格式 |
| `mp-writing-for-agents` | ★ **怎么写给 AI 看的文档**（对 AGENTS.md 这类文件是刚需） |
| `mp-teach` | 教学式讲解 |
| `mp-to-questionnaire` | 转成问卷 |
| `mp-wait-what` | 澄清误解 |

---

## 与 CineFlow 项目自带技能的分工

CineFlow 仓库内另有一套 `cineflow-*` 技能（`.github/skills/`，当前**刻意不入库**），
两者是**互补**关系：

| | `cineflow-*`（项目自带） | `mp-*`（本仓库） |
|---|---|---|
| 内容 | **本项目的具体事实**：Emby 协议实测坑、播放内核约束、发布铁律 D1–D10 | **通用工程方法**：怎么审查、怎么排障、怎么写规格 |
| 来源 | 本项目踩坑沉淀 | 上游 Matt Pocock 的方法论 |
| 改动 | 随项目演进 | 尽量不动，便于向上游同步 |

**用法**：`mp-*` 提供「怎么做」，`cineflow-*` 提供「这个项目是什么样」。
两者同时加载时，**项目自带的事实优先**（`AGENTS.md` 的优先级规则）。

---

## 注意事项

### 1. `mp-setup-matt-pocock-skills` 不要运行

它会引导你建立 `docs/agents/issue-tracker.md` 等一套**独立的**工作流约定。
CineFlow 已有自己的体系（`AGENTS.md` + `docs/AI-MEMORY.md` + `docs/task-board.md`），
两套并行会互相打架。**只借鉴其格式与思路，不套用其流程。**

### 2. 上游假设是 TypeScript/JS 项目

部分技能提到 `package.json`、`dependency-cruiser` 等。
用在 Flutter + Go 项目上需要**本地化适配**——本仓库的技能已按 CineFlow 的技术栈
做过说明调整，但仍可能会有残留的 JS 语境。

### 3. 技能间的交叉引用已重写

上游技能用 `/code-review` 这类短名互相调用。因为本仓库统一加了 `mp-` 前缀
（沿用 CineFlow 既有的 `cineflow-*` / `patrol-*` 命名约定以避免重名），
**47 处交叉引用已批量重写为 `/mp-xxx`**。

### 4. 目录结构要求（最关键）

```
<扫描根>/                    ← 如 ~/.dsh/skills
├── mp-code-review/
│   └── SKILL.md            ← 必须是「扫描根的直接子项」
└── mp-tdd/
    └── SKILL.md
```

`SKILL.md` 的 frontmatter 要求：
- `name`：**必填**，必须 kebab-case，**且应与目录名一致**
- `description`：**必填**
- 可选：`whenToUse`、`metadata`、`disable-model-invocation`、`user-invocable`

---

## 来源与许可

本仓库的技能内容来自 **[mattpocock/skills](https://github.com/mattpocock/skills)**
（作者 Matt Pocock，**MIT**），经以下改动：

1. **扁平化**：上游是 `skills/<分类>/<name>/SKILL.md`（两层嵌套），
   而 DSH 只发现扫描根的直接子项 → 提升到顶层。
2. **加 `mp-` 前缀**：避免与 CineFlow 既有的 `cineflow-*` 及其他技能重名。
3. **同步 frontmatter `name`**：与目录名保持一致。
4. **重写交叉引用**：`/name` → `/mp-name`（47 处）。
5. **按 CineFlow 技术栈补充说明**。

上游的 **LICENSE、README、CHANGELOG、GLOSSARY 与 `.agents/` 写作规范**
完整保留在 [`_upstream/`](_upstream/)，以满足 MIT 的署名要求：

> Copyright (c) 2026 Matt Pocock
> Licensed under the MIT License.

本仓库自身的整理与适配部分同样以 **MIT** 发布。

---

## 升级上游

```bash
cd /tmp && curl -sL -o mp.zip \
  https://codeload.github.com/mattpocock/skills/zip/refs/heads/main
unzip -q mp.zip
# 对比 skills-main/ 与 _upstream/，按上述 5 条改动重新生成
```

> 上游更新后**不要直接覆盖**：`mp-` 前缀、扁平化、交叉引用这三步必须重做，
> 否则技能会静默失效（装了但发现不了）。
