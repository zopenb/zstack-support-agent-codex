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

if ([string]::IsNullOrWhiteSpace($CodexExe)) {
    $candidates = @(
        (Join-Path $env:LOCALAPPDATA "OpenAI\Codex\bin\*\codex.exe"),
        (Get-Command codex -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1)
    ) | Where-Object { $_ }

    foreach ($candidate in $candidates) {
        $resolved = Get-ChildItem -Path $candidate -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -ExpandProperty FullName -First 1
        if ($resolved -and (Test-Path -LiteralPath $resolved)) {
            $CodexExe = $resolved
            break
        }
    }
}

if ([string]::IsNullOrWhiteSpace($CodexExe) -or -not (Test-Path -LiteralPath $CodexExe)) {
    throw "codex.exe was not found. Pass -CodexExe <path>."
}

Write-Host "Codex executable: $CodexExe"
Write-Host "Marketplace root: $MarketplaceRoot"

& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $scriptDir "validate-codex-plugin-mcp.ps1") -Path (Join-Path $pluginRoot ".mcp.json")

Write-Host "Atlassian shared MCP configured: zstack_atlassian_shared -> http://172.18.250.27:3340/mcp"

& $CodexExe plugin marketplace add $MarketplaceRoot
& $CodexExe plugin add "$PluginName@$MarketplaceName"

$atlassianAuth = [Environment]::GetEnvironmentVariable("ATLASSIAN_BASIC_AUTH", "Process")
if ([string]::IsNullOrEmpty($atlassianAuth)) {
    $atlassianAuth = [Environment]::GetEnvironmentVariable("ATLASSIAN_BASIC_AUTH", "User")
}
if ([string]::IsNullOrEmpty($atlassianAuth)) {
    $atlassianAuth = [Environment]::GetEnvironmentVariable("ATLASSIAN_BASIC_AUTH", "Machine")
}
if (-not [string]::IsNullOrEmpty($atlassianAuth)) {
    if ($atlassianAuth -match '^\s*Basic\s+') {
        Write-Warning "ATLASSIAN_BASIC_AUTH should be only base64(username:password), without the 'Basic ' prefix."
    } else {
        try {
            $decoded = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($atlassianAuth))
            if ($decoded -notmatch ':') {
                Write-Warning "ATLASSIAN_BASIC_AUTH decoded successfully but does not look like username:password."
            } else {
                $authorization = "Basic $atlassianAuth"
                [Environment]::SetEnvironmentVariable("ATLASSIAN_AUTHORIZATION", $authorization, "User")
                [Environment]::SetEnvironmentVariable("ATLASSIAN_AUTHORIZATION", $authorization, "Process")
                Write-Host "Derived environment variable present: ATLASSIAN_AUTHORIZATION"
            }
        } catch {
            Write-Warning "ATLASSIAN_BASIC_AUTH does not look like valid base64(username:password)."
        }
    }
}

$requiredEnv = @(
    "GITHUB_MCP_TOKEN",
    "ZSTACK_BBS_AUTHORIZATION",
    "TAVILY_HIKARI_TOKEN",
    "ATLASSIAN_BASIC_AUTH",
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
