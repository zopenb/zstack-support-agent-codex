param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

function Read-Text([string]$Path) {
    return [System.IO.File]::ReadAllText((Resolve-Path -LiteralPath $Path), [System.Text.Encoding]::UTF8)
}

function Assert-Contains([string]$Path, [string]$Pattern, [string]$Message) {
    $text = Read-Text $Path
    if ($text -notmatch $Pattern) {
        throw "$Message ($Path)"
    }
}

function Assert-NotContains([string]$Path, [string]$Pattern, [string]$Message) {
    $text = Read-Text $Path
    if ($text -match $Pattern) {
        throw "$Message ($Path)"
    }
}

function U([int[]]$Codes) {
    return -join ($Codes | ForEach-Object { [char]$_ })
}

$pluginJsonPath = Join-Path $Root ".codex-plugin\plugin.json"
$pluginJson = Read-Text $pluginJsonPath | ConvertFrom-Json

$defaultCn = U @(0x9ed8,0x8ba4)
$autoStartCn = U @(0x81ea,0x52a8,0x542f,0x52a8)
$sameIncidentFirst = U @(0x5386,0x53f2,0x76f8,0x540c,0x6545,0x969c,0x4f18,0x5148,0x68c0,0x7d22)
$sourceHard = U @(0x6e90,0x7801,0x786c,0x7ea6,0x675f)
$firstGithub = (U @(0x9996,0x4e2a,0x67e5,0x8bc1,0x52a8,0x4f5c,0x5fc5,0x987b,0x662f)) + " GitHub"
$githubIncomplete = "GitHub " + (U @(0x6e90,0x7801,0x67e5,0x8bc1,0x672a,0x5b8c,0x6210))
$explicitOnly = U @(0x53ea,0x6709,0x7528,0x6237,0x660e,0x786e,0x8981,0x6c42)

if ($pluginJson.description -match "default subagent|$defaultCn subagent|$defaultCn.*subagent") {
    throw "plugin.json description must not promise default subagent execution"
}

function Find-SkillDir([string]$Name) {
    $skillsRoot = Join-Path $Root "skills"
    foreach ($skillFile in Get-ChildItem -LiteralPath $skillsRoot -Recurse -Filter "SKILL.md") {
        $text = Read-Text $skillFile.FullName
        if ($text -match "(?m)^name:\s*[""']?$([regex]::Escape($Name))[""']?\s*$") {
            return $skillFile.Directory.FullName
        }
    }
    throw "Skill '$Name' not found under $skillsRoot"
}

$prefix = "ZStackSupport:"
$eventDir = Find-SkillDir ($prefix + [string]([char]0x4e8b) + [string]([char]0x4ef6) + [string]([char]0x5206) + [string]([char]0x6790))
$sourceDir = Find-SkillDir ($prefix + [string]([char]0x6e90) + [string]([char]0x7801) + [string]([char]0x67e5) + [string]([char]0x8bc1))
$connectivityDir = Find-SkillDir ($prefix + [string]([char]0x8fde) + [string]([char]0x901a) + [string]([char]0x68c0) + [string]([char]0x67e5))
$envConfigDir = Find-SkillDir ($prefix + [string]([char]0x73af) + [string]([char]0x5883) + [string]([char]0x914d) + [string]([char]0x7f6e))
$handoffDir = Find-SkillDir ($prefix + [string]([char]0x4ea4) + [string]([char]0x63a5) + [string]([char]0x6458) + [string]([char]0x8981))
$redactionDir = Find-SkillDir ($prefix + [string]([char]0x8131) + [string]([char]0x654f) + [string]([char]0x68c0) + [string]([char]0x67e5))
$knowledgeDir = Find-SkillDir ($prefix + [string]([char]0x77e5) + [string]([char]0x8bc6) + [string]([char]0x5e93))

$eventSkill = Join-Path $eventDir "SKILL.md"
$sourceSkill = Join-Path $sourceDir "SKILL.md"
$connectivityAgent = Join-Path $connectivityDir "agents\openai.yaml"
$envConfigAgent = Join-Path $envConfigDir "agents\openai.yaml"
$handoffAgent = Join-Path $handoffDir "agents\openai.yaml"
$redactionAgent = Join-Path $redactionDir "agents\openai.yaml"
$knowledgeAgent = Join-Path $knowledgeDir "agents\openai.yaml"
$eventAgent = Join-Path $eventDir "agents\openai.yaml"
$sourceAgent = Join-Path $sourceDir "agents\openai.yaml"
$template = Join-Path $eventDir "references\subagent-prompts.md"
$snapshotScript = Join-Path $Root "scripts\snapshot-user-env.ps1"
$dependencyScript = Join-Path $Root "scripts\check-local-dependencies.ps1"

Assert-Contains $eventSkill ([regex]::Escape($sameIncidentFirst)) "event skill must keep same-incident-first support workflow"
Assert-Contains $eventSkill ([regex]::Escape($sourceHard)) "event skill must keep GitHub source hard constraint"
Assert-Contains $eventSkill ([regex]::Escape($githubIncomplete)) "event skill must define GitHub incomplete status"
Assert-Contains $sourceSkill ([regex]::Escape($firstGithub)) "source skill must require GitHub as first verification action"
Assert-Contains $template ([regex]::Escape($explicitOnly)) "subagent template must require explicit user request"

Assert-Contains $eventAgent "allow_implicit_invocation:\s*true" "event skill should remain implicitly invocable"
Assert-Contains $sourceAgent "allow_implicit_invocation:\s*true" "source skill should remain implicitly invocable"
Assert-Contains $connectivityAgent "allow_implicit_invocation:\s*false" "connectivity skill should be explicit only"
Assert-Contains $envConfigAgent "allow_implicit_invocation:\s*true" "environment config skill should remain implicitly invocable"
foreach ($agentFile in @($eventAgent, $sourceAgent, $connectivityAgent, $envConfigAgent, $handoffAgent, $redactionAgent, $knowledgeAgent)) {
    Assert-Contains $agentFile 'display_name:\s*"ZStackSupport:' "skill display name should use the ZStackSupport prefix"
    Assert-NotContains $agentFile 'display_name:\s*"ZStackSupport:ZStackSupport:' "skill display name should not duplicate the ZStackSupport prefix"
}
Assert-Contains $snapshotScript "Secret values are not printed" "environment snapshot must not print secret values"
Assert-Contains $dependencyScript "Secret values are not printed" "local dependency check must not print secret values"
Assert-Contains $dependencyScript "ATLASSIAN_BASIC_AUTH" "local dependency check must report legacy Atlassian variables"

$scanRoots = @(
    (Join-Path $Root "README.md"),
    (Join-Path $Root "skills"),
    (Join-Path $Root ".codex-plugin\plugin.json")
)

$dispatchCn = U @(0x6d3e,0x53d1)
$triggerCn = U @(0x89e6,0x53d1)
$preferredCn = U @(0x4f18,0x5148,0x4f7f,0x7528)
$dontWaitUserCn = U @(0x4e0d,0x7b49,0x5f85,0x7528,0x6237,0x8bf4)
$dontWaitUserExtraCn = U @(0x4e0d,0x7b49,0x5f85,0x7528,0x6237,0x989d,0x5916,0x8bf4)
$threeSourcesDefaultCn = "3 " + (U @(0x4e2a,0x53ca,0x4ee5,0x4e0a,0x6765,0x6e90)) + $defaultCn
$forbiddenPromise = "$defaultCn subagent|$defaultCn$dispatchCn subagent|$defaultCn$triggerCn subagent|$defaultCn$preferredCn subagent|$autoStartCn subagent|$dontWaitUserCn.*multi agent|$dontWaitUserExtraCn.*multi agent|$threeSourcesDefaultCn"
foreach ($path in $scanRoots) {
    if (Test-Path -LiteralPath $path -PathType Container) {
        Get-ChildItem -LiteralPath $path -Recurse -File | ForEach-Object {
            Assert-NotContains $_.FullName $forbiddenPromise "Found misleading subagent promise"
        }
    } elseif (Test-Path -LiteralPath $path) {
        Assert-NotContains $path $forbiddenPromise "Found misleading subagent promise"
    }
}

$repoRoot = Resolve-Path (Join-Path $Root "..\..")
$secretScan = Get-ChildItem -LiteralPath $repoRoot -Recurse -File |
    Where-Object {
        $_.FullName -notmatch '\\.git\\' -and
        $_.FullName -notmatch '\\plugins\\cache\\' -and
        $_.FullName -ne $PSCommandPath -and
        $_.Extension -notin @(".png", ".jpg", ".jpeg", ".gif", ".zip")
    } |
    Select-String -Pattern "github_pat_[A-Za-z0-9_]{20,}|ATLASSIAN_AUTHORIZATION=Basic [A-Za-z0-9+/=]{12,}|ZSTACK_BBS_AUTHORIZATION=Basic [A-Za-z0-9+/=]{12,}|zstack@123" -List

if ($secretScan) {
    $paths = ($secretScan | ForEach-Object { $_.Path } | Sort-Object -Unique) -join ", "
    throw "Potential concrete secret found: $paths"
}

Write-Output "ZStack support plugin consistency OK: $Root"
