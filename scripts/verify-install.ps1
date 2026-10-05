# 技能安装校验
#
# 存在理由：技能装错位置**不会报错**，只是静默不生效——模型看不到它，
# 用户也收不到任何提示。本脚本把"装了但没生效"变成一句可执行的检查。
#
# 依据（来自 DSH 源码的明文约定）：
#   "skill 可以是被扫描根目录顶层的目录 bundle `<name>/SKILL.md`，
#    也可以是平铺文件 `<name>.md`；刻意不支持发现嵌套的 `**/SKILL.md`。"
#   frontmatter 必填 `name`（kebab-case）与 `description`。
#
# 用法：
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify-install.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify-install.ps1 -Root .
#
# ⚠️ 本文件含中文，必须保存为 UTF-8 **with BOM**，否则 Windows PowerShell 5.1
#    会按 GBK 解码，中文行吞掉下一行代码，报出一堆假语法错误。

[CmdletBinding()]
param(
    # 要校验的扫描根目录。默认是 DSH 的全局技能目录。
    [string]$Root = (Join-Path $env:USERPROFILE '.dsh\skills')
)

$ErrorActionPreference = 'Stop'
$fail = 0
$warn = 0

function Fail([string]$msg) { Write-Host "  [FAIL] $msg" -ForegroundColor Red; $script:fail++ }
function Warn([string]$msg) { Write-Host "  [WARN] $msg" -ForegroundColor Yellow; $script:warn++ }
function Pass([string]$msg) { Write-Host "  [ OK ] $msg" -ForegroundColor Green }

Write-Host ""
Write-Host "=== 技能安装校验 ===" -ForegroundColor Cyan
Write-Host "  扫描根: $Root"

if (-not (Test-Path $Root)) {
    Fail "扫描根不存在：$Root"
    Write-Host ""
    Write-Host "安装方式：" -ForegroundColor Yellow
    Write-Host "  git clone https://github.com/bsfcxz/cineflow-skills.git `"$Root`""
    exit 1
}

$Root = (Resolve-Path $Root).Path

# ---- 1) 技能必须是扫描根的**直接子项** -------------------------------------
Write-Host ""
Write-Host "[1/6] 检查层级（必须是扫描根的直接子项）"

$skills = @()
foreach ($d in (Get-ChildItem $Root -Directory -ErrorAction SilentlyContinue)) {
    $md = Join-Path $d.FullName 'SKILL.md'
    if (Test-Path $md) { $skills += $d }
}

# 嵌套检测：扫描根之下、深度 >= 3 的 SKILL.md 都属于"发现不了"的
$nested = @()
foreach ($f in (Get-ChildItem $Root -Recurse -Filter 'SKILL.md' -ErrorAction SilentlyContinue)) {
    $rel = $f.FullName.Substring($Root.Length).TrimStart('\')
    $depth = ($rel -split '\\').Count - 1   # <name>/SKILL.md => 1
    if ($depth -ge 2) { $nested += $rel }
}

if ($skills.Count -eq 0) {
    Fail "扫描根下没有任何 <name>/SKILL.md"
} else {
    Pass "发现 $($skills.Count) 个技能（扫描根的直接子项）"
}
if ($nested.Count -gt 0) {
    Fail "有 $($nested.Count) 个 SKILL.md 嵌套过深，DSH **不会发现**它们："
    $nested | Select-Object -First 5 | ForEach-Object { Write-Host "         $_" -ForegroundColor DarkGray }
    Write-Host "         → 把技能目录提升到扫描根的直接子项" -ForegroundColor DarkGray
}

# ---- 2) 每个技能有 SKILL.md（由上面构造保证），检查 frontmatter ------------
Write-Host ""
Write-Host "[2/6] 检查 frontmatter（name / description 必填）"

$badFm = @()
foreach ($s in $skills) {
    $t = [System.IO.File]::ReadAllText((Join-Path $s.FullName 'SKILL.md'))
    if (-not $t.StartsWith('---')) { $badFm += "$($s.Name): 缺少 YAML frontmatter"; continue }
    if (-not [regex]::IsMatch($t, '(?m)^name:\s*\S+')) { $badFm += "$($s.Name): 缺少 name" }
    if (-not [regex]::IsMatch($t, '(?m)^description:\s*\S+')) { $badFm += "$($s.Name): 缺少 description" }
}
if ($badFm.Count -eq 0) { Pass "全部 $($skills.Count) 个技能 frontmatter 合法" }
else { $badFm | ForEach-Object { Fail $_ } }

# ---- 3) name 必须 kebab-case 且与目录名一致 --------------------------------
Write-Host ""
Write-Host "[3/6] 检查 name 与目录名一致（且为 kebab-case）"

$mismatch = @()
foreach ($s in $skills) {
    $t = [System.IO.File]::ReadAllText((Join-Path $s.FullName 'SKILL.md'))
    $m = [regex]::Match($t, '(?m)^name:\s*(\S+)')
    if (-not $m.Success) { continue }
    $n = $m.Groups[1].Value.Trim('"').Trim("'")
    if ($n -ne $s.Name) { $mismatch += "$($s.Name): frontmatter name=$n" }
    elseif ($n -notmatch '^[a-z0-9]+(-[a-z0-9]+)*$') { $mismatch += "$($s.Name): 不是 kebab-case" }
}
if ($mismatch.Count -eq 0) { Pass "全部一致且为 kebab-case" }
else { $mismatch | ForEach-Object { Warn $_ } }

# ---- 4) 交叉引用完整性 -----------------------------------------------------
Write-Host ""
Write-Host "[4/6] 检查技能间交叉引用"

$names = $skills.Name
$broken = @()
foreach ($s in $skills) {
    foreach ($f in (Get-ChildItem $s.FullName -Recurse -File -Include *.md -ErrorAction SilentlyContinue)) {
        $t = [System.IO.File]::ReadAllText($f.FullName)
        foreach ($ref in [regex]::Matches($t, '(?<![\w-])/(mp-[a-z0-9-]+)')) {
            $r = $ref.Groups[1].Value
            if ($names -notcontains $r) {
                $broken += "$($s.Name)/$($f.Name) -> /$r（不存在）"
            }
        }
    }
}
if ($broken.Count -eq 0) { Pass "无断开的 /mp-* 引用" }
else {
    $broken | Select-Object -Unique | Select-Object -First 8 | ForEach-Object { Fail $_ }
    if ($broken.Count -gt 8) { Write-Host "         …另有 $($broken.Count - 8) 处" -ForegroundColor DarkGray }
}

# ---- 5) 行尾必须 LF --------------------------------------------------------
Write-Host ""
Write-Host "[5/6] 检查行尾（CRLF 会破坏 .sh 脚本）"

$crlfFiles = @()
foreach ($f in (Get-ChildItem $Root -Recurse -File -Include *.md,*.sh,*.yaml,*.yml `
                    -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch '\\\.git\\' })) {
    $b = [System.IO.File]::ReadAllBytes($f.FullName)
    for ($i = 1; $i -lt $b.Length; $i++) {
        if ($b[$i] -eq 10 -and $b[$i - 1] -eq 13) { $crlfFiles += $f.FullName.Substring($Root.Length); break }
    }
}
if ($crlfFiles.Count -eq 0) { Pass "全部为 LF" }
else {
    Warn "有 $($crlfFiles.Count) 个文件是 CRLF（.sh 会报 '\r: command not found'）："
    $crlfFiles | Select-Object -First 5 | ForEach-Object { Write-Host "         $_" -ForegroundColor DarkGray }
    Write-Host "         → 本仓库的 .gitattributes 已强制 LF；若仍出现请检查本地 core.autocrlf" -ForegroundColor DarkGray
}

# ---- 6) 摘要 ---------------------------------------------------------------
Write-Host ""
Write-Host "[6/6] 结果"
Write-Host "  技能数: $($skills.Count)   失败: $fail   警告: $warn"

if ($skills.Count -gt 0) {
    Write-Host ""
    Write-Host "  已识别的技能:" -ForegroundColor Cyan
    # 不能把字符串用管道喂给 Write-Host：它不接受管道输入，会抛
    # ParameterBindingException；叠加 $ErrorActionPreference='Stop' 会让
    # **校验通过**的运行也以退出码 1 结束（实测踩过：前 5 项全 OK、
    # 失败计数为 0，却报"不通过"）。这是"门禁脚本自身的 bug 伪装成业务失败"，
    # 与 CineFlow AGENTS.md 记录的那类坑同源。
    $list = ($skills.Name | Sort-Object) -join ', '
    Write-Host "    $list"
}

Write-Host ""
if ($fail -gt 0) {
    Write-Host "结论：不通过（$fail 项失败）—— 技能不会被完整发现，请按上面提示修复。" -ForegroundColor Red
    exit 1
}

Write-Host "结论：通过。这些技能会被 DSH 发现并加载。" -ForegroundColor Green
if ($warn -gt 0) { Write-Host "（有 $warn 项警告，不影响加载）" -ForegroundColor Yellow }
exit 0
