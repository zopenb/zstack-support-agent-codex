param(
    [string]$MarketplaceRoot,
    [string]$MarketplaceName = "zstack-support-local",
    [string]$PluginName = "zstack-support",
    [string]$CodexExe
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$pluginRoot = Split-Path -Parent $scriptDir
if ([string]::IsNullOrWhiteSpace($MarketplaceRoot)) {
    $MarketplaceRoot = Split-Path -Parent (Split-Path -Parent $pluginRoot)
}

function Test-CodexExecutable {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path)) {
        return $false
    }

    try {
        & $Path --version *> $null
        return ($LASTEXITCODE -eq 0 -or $null -eq $LASTEXITCODE)
    } catch {
        if ($Path -match "\\WindowsApps\\") {
            Write-Warning "Codex candidate is a WindowsApps package path but cannot be executed directly: $Path"
            Write-Warning "Use the local Codex bin path under %LOCALAPPDATA%\OpenAI\Codex\bin or pass -CodexExe <path>."
        } else {
            Write-Warning "Codex candidate cannot be executed: $Path"
        }
        return $false
    }
}

if ([string]::IsNullOrWhiteSpace($CodexExe)) {
    $candidates = @(
        (Join-Path $env:LOCALAPPDATA "OpenAI\Codex\bin\*\codex.exe"),
        (Get-Command codex -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1)
    ) | Where-Object { $_ }

    foreach ($candidate in $candidates) {
        $resolved = Get-ChildItem -Path $candidate -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -ExpandProperty FullName -First 1
        if ($resolved -and (Test-CodexExecutable $resolved)) {
            $CodexExe = $resolved
            break
        }
    }
} elseif (-not (Test-CodexExecutable $CodexExe)) {
    throw "codex.exe was found but cannot be executed: $CodexExe. Pass a usable -CodexExe <path>."
}

if ([string]::IsNullOrWhiteSpace($CodexExe) -or -not (Test-Path -LiteralPath $CodexExe)) {
    throw "codex.exe was not found. Run scripts\check-local-dependencies.ps1 to locate a usable Codex executable, then pass -CodexExe <path>."
}

Write-Host "Codex executable: $CodexExe"
Write-Host "Marketplace root: $MarketplaceRoot"

& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $scriptDir "validate-codex-plugin-mcp.ps1") -Path (Join-Path $pluginRoot ".mcp.json")

Write-Host "Atlassian shared MCP configured: zstack_atlassian_shared -> http://172.18.250.27:3340/mcp"

& $CodexExe plugin marketplace add $MarketplaceRoot
& $CodexExe plugin add "$PluginName@$MarketplaceName"

function Get-EnvValue {
    param([string]$Name)

    foreach ($scope in @("Process", "User", "Machine")) {
        $value = [Environment]::GetEnvironmentVariable($Name, $scope)
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            return $value
        }
    }

    return $null
}

$atlassianAuthorization = Get-EnvValue "ATLASSIAN_AUTHORIZATION"
$legacyAtlassianBasic = Get-EnvValue "ATLASSIAN_BASIC_AUTH"

if (-not [string]::IsNullOrWhiteSpace($atlassianAuthorization)) {
    if ($atlassianAuthorization -notmatch '^\s*Basic\s+\S+') {
        Write-Warning "ATLASSIAN_AUTHORIZATION should be the complete header value: Basic <base64(username:password)>."
    } else {
        Write-Host "Environment variable present: ATLASSIAN_AUTHORIZATION"
    }
} elseif (-not [string]::IsNullOrWhiteSpace($legacyAtlassianBasic)) {
    Write-Warning "ATLASSIAN_BASIC_AUTH is deprecated. Set ATLASSIAN_AUTHORIZATION='Basic <base64(username:password)>' directly for new installations."

    $authorization = $null
    if ($legacyAtlassianBasic -match '^\s*Basic\s+\S+') {
        $authorization = $legacyAtlassianBasic.Trim()
    } else {
        try {
            $decoded = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($legacyAtlassianBasic))
            if ($decoded -notmatch ':') {
                Write-Warning "ATLASSIAN_BASIC_AUTH decoded successfully but does not look like username:password."
            } else {
                $authorization = "Basic $legacyAtlassianBasic"
            }
        } catch {
            Write-Warning "ATLASSIAN_BASIC_AUTH does not look like valid base64(username:password)."
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($authorization)) {
        [Environment]::SetEnvironmentVariable("ATLASSIAN_AUTHORIZATION", $authorization, "User")
        [Environment]::SetEnvironmentVariable("ATLASSIAN_AUTHORIZATION", $authorization, "Process")
        Write-Host "Migrated legacy Atlassian variable to: ATLASSIAN_AUTHORIZATION"
    }
}

$requiredEnv = @(
    "GITHUB_MCP_TOKEN",
    "ZSTACK_BBS_AUTHORIZATION",
    "TAVILY_HIKARI_TOKEN",
    "ATLASSIAN_AUTHORIZATION"
)
foreach ($name in $requiredEnv) {
    $present =
        -not [string]::IsNullOrEmpty([Environment]::GetEnvironmentVariable($name, "Process")) -or
        -not [string]::IsNullOrEmpty([Environment]::GetEnvironmentVariable($name, "User")) -or
        -not [string]::IsNullOrEmpty([Environment]::GetEnvironmentVariable($name, "Machine"))

    if ($present) {
        Write-Host "Environment variable present: $name"
    } else {
        Write-Warning "Environment variable missing: $name"
    }
}

& $CodexExe mcp list

Write-Host "Install complete. Restart Codex or open a new thread before running the connectivity skill."
