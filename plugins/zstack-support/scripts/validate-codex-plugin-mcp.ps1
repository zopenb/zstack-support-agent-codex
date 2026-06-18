param(
    [string]$Path = ".mcp.json"
)

$ErrorActionPreference = "Stop"
$resolvedPath = (Resolve-Path -LiteralPath $Path).ProviderPath
$configDir = Split-Path -Parent $resolvedPath
$config = Get-Content -LiteralPath $resolvedPath -Raw | ConvertFrom-Json
$servers = $config.mcpServers

if ($null -eq $servers) {
    throw "mcpServers is required by the current Codex plugin installer"
}

foreach ($serverName in $servers.PSObject.Properties.Name) {
    if ($serverName -notmatch '^[a-zA-Z0-9_-]+$') {
        throw "Invalid MCP server name '$serverName'; use only letters, numbers, underscore, and hyphen"
    }
}

$github = $servers.github
if ($null -eq $github) {
    throw "github MCP server is required"
}
if ($github.bearer_token_env_var -ne "GITHUB_MCP_TOKEN") {
    throw "github must use bearer_token_env_var=GITHUB_MCP_TOKEN"
}
if ($github.type -ne "streamable_http") {
    throw "github must use type=streamable_http"
}
if ($null -ne $github.headers) {
    throw "github must not use raw headers"
}

$bbs = $servers.'zstack-bbs'
if ($null -eq $bbs) {
    throw "zstack-bbs MCP server is required"
}
if ($bbs.type -ne "streamable_http") {
    throw "zstack-bbs must use type=streamable_http"
}
if ($bbs.env_http_headers.Authorization -ne "ZSTACK_BBS_AUTHORIZATION") {
    throw "BBS must use env_http_headers.Authorization=ZSTACK_BBS_AUTHORIZATION"
}
if ($bbs.http_headers.'X-MCP-Readonly' -ne "true") {
    throw "BBS must preserve X-MCP-Readonly=true"
}
if ($null -ne $bbs.headers) {
    throw "BBS must not use raw headers"
}

$tavily = $servers.'tavily_hikari'
if ($null -eq $tavily) {
    throw "tavily_hikari MCP server is required"
}
if ($tavily.type -ne "streamable_http") {
    throw "tavily_hikari must use type=streamable_http"
}
if ($tavily.url -ne "https://tavily.zopen1.com/mcp") {
    throw "tavily_hikari must use the approved Tavily MCP URL"
}
if ($tavily.bearer_token_env_var -ne "TAVILY_HIKARI_TOKEN") {
    throw "tavily_hikari must use bearer_token_env_var=TAVILY_HIKARI_TOKEN"
}
if ($null -ne $tavily.headers) {
    throw "tavily_hikari must not use raw headers"
}

$legacyAtlassian = $servers.'zstack_atlassian'
if ($null -ne $legacyAtlassian) {
    throw "legacy zstack_atlassian MCP server is not allowed; use zstack_atlassian_shared"
}

$atlassian = $servers.'zstack_atlassian_shared'
if ($null -eq $atlassian) {
    throw "zstack_atlassian_shared MCP server is required"
}
if ($atlassian.type -ne "streamable_http") {
    throw "zstack_atlassian_shared must use type=streamable_http"
}
if ($atlassian.url -ne "http://172.18.250.27:3340/mcp") {
    throw "zstack_atlassian_shared must use the approved shared Atlassian MCP URL"
}
if ($atlassian.enabled -ne $true) {
    throw "zstack_atlassian_shared must set enabled=true"
}
if ($atlassian.http_headers.Accept -ne "application/json, text/event-stream") {
    throw "zstack_atlassian_shared must preserve Accept=application/json, text/event-stream"
}
if ($atlassian.env_http_headers.Authorization -ne "ATLASSIAN_AUTHORIZATION") {
    throw "zstack_atlassian_shared must use env_http_headers.Authorization=ATLASSIAN_AUTHORIZATION"
}
foreach ($field in @("command", "args", "cwd", "env", "startup_timeout_sec", "tool_timeout_sec")) {
    if ($null -ne $atlassian.$field) {
        throw "zstack_atlassian_shared must not use local adapter field '$field'"
    }
}
foreach ($legacyScript in @("scripts\zstack-atlassian-mcp.js", "scripts\zstack-atlassian-mcp.ps1")) {
    if (Test-Path -LiteralPath (Join-Path $configDir $legacyScript)) {
        throw "legacy local Atlassian adapter script must be removed: $legacyScript"
    }
}

$raw = Get-Content -LiteralPath $resolvedPath -Raw
$allowedRefs = @(
    'ATLASSIAN_AUTHORIZATION'
)
$rawWithoutAllowedRefs = $raw
foreach ($ref in $allowedRefs) {
    $rawWithoutAllowedRefs = $rawWithoutAllowedRefs.Replace($ref, "")
}
if ($rawWithoutAllowedRefs -match 'github_pat_|Basic Ym|Bearer github_pat|\$\{') {
    throw "MCP config contains a concrete secret or unsupported variable interpolation"
}

Write-Output "Codex plugin MCP config OK: $resolvedPath"
