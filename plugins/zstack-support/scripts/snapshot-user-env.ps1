$ErrorActionPreference = "Stop"

function Get-EnvSnapshot {
    param([string]$Name)

    $scopes = @("Process", "User", "Machine")
    $found = @()
    foreach ($scope in $scopes) {
        $value = [Environment]::GetEnvironmentVariable($Name, $scope)
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            $found += [pscustomobject]@{
                Scope = $scope
                Value = $value
            }
        }
    }

    return $found
}

function Test-BasicHeaderShape {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return "缺失"
    }

    $trimmed = $Value.Trim()
    if ($trimmed -notmatch '^Basic\s+\S+$') {
        return "格式异常：应为 Basic <base64(username:password)>"
    }

    $encoded = ($trimmed -replace '^Basic\s+', '').Trim()
    try {
        $decoded = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($encoded))
        if ($decoded -match ':') {
            return "通过"
        }
        return "格式异常：base64 可解码但不含 username:password 分隔符"
    } catch {
        return "格式异常：Basic 后不是合法 base64"
    }
}

function Test-TokenShape {
    param(
        [string]$Name,
        [string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return "缺失"
    }

    if ($Name -eq "GITHUB_MCP_TOKEN") {
        if ($Value -match '^(github_pat_|ghp_|gho_|ghu_|ghs_|ghr_)') {
            return "通过"
        }
        return "存在，但不像常见 GitHub token 前缀"
    }

    if ($Name -eq "TAVILY_HIKARI_TOKEN") {
        return "存在"
    }

    return "存在"
}

$items = @(
    [pscustomobject]@{
        Name = "GITHUB_MCP_TOKEN"
        Kind = "Token"
        Fix = "设置 GitHub Personal Access Token。"
    },
    [pscustomobject]@{
        Name = "ZSTACK_BBS_AUTHORIZATION"
        Kind = "Basic"
        Fix = "设置为 Basic <base64(username:password)>。"
    },
    [pscustomobject]@{
        Name = "TAVILY_HIKARI_TOKEN"
        Kind = "Token"
        Fix = "设置团队 Tavily Hikari MCP token。"
    },
    [pscustomobject]@{
        Name = "ATLASSIAN_AUTHORIZATION"
        Kind = "Basic"
        Fix = "设置为 Basic <base64(username:password)>，用于共享 Jira/Confluence MCP。"
    }
)

Write-Host "ZStack Support Agent environment snapshot"
Write-Host "Secret values are not printed."
Write-Host ""

$rows = foreach ($item in $items) {
    $values = Get-EnvSnapshot $item.Name
    $present = $values.Count -gt 0
    $scopes = if ($present) { ($values | ForEach-Object { $_.Scope }) -join "," } else { "-" }
    $firstValue = if ($present) { $values[0].Value } else { "" }
    $shape = if ($item.Kind -eq "Basic") {
        Test-BasicHeaderShape $firstValue
    } else {
        Test-TokenShape -Name $item.Name -Value $firstValue
    }

    [pscustomobject]@{
        Name = $item.Name
        Present = $present
        Scope = $scopes
        Format = $shape
        Suggestion = if ($present -and $shape -eq "通过") { "无需处理" } elseif ($present -and $shape -eq "存在") { "必要时运行连通检查" } else { $item.Fix }
    }
}

$rows | Format-Table -AutoSize

$legacyBasic = Get-EnvSnapshot "ATLASSIAN_BASIC_AUTH"
if ($legacyBasic.Count -gt 0) {
    Write-Host ""
    Write-Host "Legacy note: ATLASSIAN_BASIC_AUTH exists. New installs should use ATLASSIAN_AUTHORIZATION only."
}

Write-Host ""
Write-Host "To configure interactively without printing secrets, run:"
Write-Host "powershell -NoProfile -ExecutionPolicy Bypass -File .\plugins\zstack-support\scripts\set-user-env.ps1"
Write-Host ""
Write-Host "After changes, restart Codex or open a new thread before running zstack-support:连通检查."