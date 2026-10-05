# 安装校验 —— 确认技能真的能被 DSH 发现

> **为什么需要这个脚本**：技能装错位置**不会报错**，只是静默不生效
> （模型看不到它，你也不会收到任何提示）。本脚本把"装了但没生效"
> 变成一句可执行的检查。

## 用法

```powershell
# 校验默认位置（~/.dsh/skills）
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify-install.ps1

# 校验指定目录（如项目内的扫描根）
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify-install.ps1 -Root .dsh\skills

# 校验刚克隆下来、还没安装的目录
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify-install.ps1 -Root .
```

退出码 `0` = 通过；非 `0` = 有问题（具体原因会打印）。

## 检查项

| # | 检查 | 为什么 |
|---|---|---|
| 1 | 技能是**扫描根的直接子项** | DSH 源码明文："nested `**/SKILL.md` files are deliberately not discovered"。多一层嵌套 = 静默失效 |
| 2 | 每个技能有 `SKILL.md` | 目录 bundle 的必要条件 |
| 3 | frontmatter 含 `name`（kebab-case）与 `description` | DSH 的硬性要求，缺失会被跳过 |
| 4 | `name` 与**目录名一致** | 不一致会让调用名混乱 |
| 5 | 交叉引用 `/mp-xxx` **都有对应技能** | 断开引用会让技能引导到不存在的技能 |
| 6 | 行尾为 LF | CRLF 会让 `.sh` 报 `\r: command not found` |

## DSH 的扫描根与优先级

| 优先级 | 来源 | 路径 |
|---|---|---|
| 100 | `project-dsh` | `<项目根>/.dsh/skills` |
| 200 | `project-agents` | `<项目根>/.agents/skills` |
| 300 | custom | `Config.customSkillDirs` |
| 400 | `user-dsh` | `<dshHome>/skills`（通常是 `~/.dsh/skills`） |
| 500 | user-agents | `<agentsHome>/skills` |

项目根 = 最近的包含 `.git` 的祖先目录。
