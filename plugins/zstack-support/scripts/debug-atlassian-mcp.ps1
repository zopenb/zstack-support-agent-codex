param(
    [string]$Url = "http://172.18.250.27:3340/mcp",
    [string]$HostName = "172.18.250.27",
    [int]$Port = 3340
)

$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

function Get-EnvValue {
    param([string]$Name)

    foreach ($scope in @("Process", "User", "Machine")) {
        $value = [Environment]::GetEnvironmentVariable($Name, $scope)
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            return [pscustomobject]@{
                Name = $Name
                Scope = $scope
                Value = $value
            }
        }
    }

    return $null
}

function Write-Check {
    param(
        [string]$Name,
        [bool]$Passed,
        [string]$Detail
    )

    $status = if ($Passed) { "PASS" } else { "FAIL" }
    Write-Host "$Name : $status - $Detail"
}

Write-Host "Atlassian MCP debug. Secret values will not be printed."
Write-Host "Target: $Url"

$authorization = Get-EnvValue "ATLASSIAN_AUTHORIZATION"
$legacyBasic = Get-EnvValue "ATLASSIAN_BASIC_AUTH"

if ($authorization) {
    Write-Check "Auth env" $true "ATLASSIAN_AUTHORIZATION exists in $($authorization.Scope)"
} else {
    Write-Check "Auth env" $false "ATLASSIAN_AUTHORIZATION is missing"
}

if ($legacyBasic) {
    Write-Host "Legacy note: ATLASSIAN_BASIC_AUTH also exists in $($legacyBasic.Scope). New installs should only use ATLASSIAN_AUTHORIZATION."
}

if (-not $authorization) {
    Write-Host "Fix: set ATLASSIAN_AUTHORIZATION to the full header value, for example: Basic <base64(username:password)>"
    exit 1
}

$authValue = $authorization.Value.Trim()
$shapeOk = $authValue -match '^Basic\s+\S+$'
Write-Check "Header shape" $shapeOk "expected: Basic <base64(username:password)>"

if ($shapeOk) {
    $encoded = ($authValue -replace '^Basic\s+', '').Trim()
    try {
        $decoded = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($encoded))
        Write-Check "Base64 decode" ($decoded -match ':') "checked username:password shape only; value is hidden"
    } catch {
        Write-Check "Base64 decode" $false "cannot decode as base64"
    }
}

$tcpOk = $false
try {
    $tcpOk = Test-NetConnection -ComputerName $HostName -Port $Port -InformationLevel Quiet
} catch {
    $tcpOk = $false
}
Write-Check "TCP reachability" $tcpOk "${HostName}:${Port}"

if (-not $tcpOk) {
    Write-Host "Fix: check company network/VPN/firewall/routing access to ${HostName}:${Port}."
    exit 2
}

try {
    $headers = @{
        Authorization = $authValue
        Accept = "application/json, text/event-stream"
        "Content-Type" = "application/json"
    }
    $body = @{
        jsonrpc = "2.0"
        id = 1
        method = "initialize"
        params = @{
            protocolVersion = "2025-03-26"
            capabilities = @{}
            clientInfo = @{
                name = "zstack-support-debug"
                version = "1.0"
            }
        }
    } | ConvertTo-Json -Depth 8 -Compress

    $response = Invoke-WebRequest -UseBasicParsing -Method Post -Uri $Url -Headers $headers -Body $body -TimeoutSec 15
    $contentType = ""
    if ($response.Headers -and $response.Headers["Content-Type"]) {
        $contentType = [string]$response.Headers["Content-Type"]
    }
    Write-Check "MCP initialize" ($response.StatusCode -eq 200) "HTTP $([int]$response.StatusCode), Content-Type=$contentType"

    $content = [string]$response.Content
    $serverOk = $content -match '"serverInfo"' -and $content -match '"tools"'
    Write-Check "MCP capability" $serverOk "initialize response should include serverInfo and tools capability"

    if ($serverOk) {
        Write-Host "Conclusion: remote MCP, network, and auth look usable. If Codex still reports configured-but-not-injected, inspect Codex client logs for zstack_atlassian_shared during tool discovery."
    } else {
        Write-Host "Conclusion: remote responded, but initialize did not look like a complete MCP response. Ask the shared MCP maintainer to inspect the service."
    }
} catch {
    $message = $_.Exception.Message
    $status = $null
    if ($_.Exception.Response) {
        try { $status = [int]$_.Exception.Response.StatusCode } catch { $status = $null }
    }

    $line = $null
    if ($_.InvocationInfo) {
        $line = $_.InvocationInfo.ScriptLineNumber
    }

    if ($status) {
        Write-Check "MCP initialize" $false "HTTP $status, $message"
    } elseif ($line) {
        Write-Check "MCP initialize" $false "line $line, $message"
    } else {
        Write-Check "MCP initialize" $false $message
    }

    Write-Host "Hint: 401/403 usually means auth or account permission; timeout usually means network/VPN; 5xx usually means shared MCP service trouble."
    exit 3
}
