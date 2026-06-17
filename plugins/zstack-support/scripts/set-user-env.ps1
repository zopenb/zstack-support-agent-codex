param(
    [switch]$SkipExisting
)

$ErrorActionPreference = "Stop"

function Get-EnvValue {
    param([string]$Name)

    foreach ($scope in @("User", "Machine", "Process")) {
        $value = [Environment]::GetEnvironmentVariable($Name, $scope)
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            return $value
        }
    }

    return $null
}

function Read-SecretPlainText {
    param([string]$Prompt)

    $secure = Read-Host -Prompt $Prompt -AsSecureString
    if ($secure.Length -eq 0) {
        return ""
    }

    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    } finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}

function Set-UserEnvIfProvided {
    param(
        [string]$Name,
        [string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        Write-Host "Skipped: $Name"
        return
    }

    if ($SkipExisting -and -not [string]::IsNullOrWhiteSpace((Get-EnvValue $Name))) {
        Write-Host "Kept existing: $Name"
        return
    }

    [Environment]::SetEnvironmentVariable($Name, $Value, "User")
    [Environment]::SetEnvironmentVariable($Name, $Value, "Process")
    Write-Host "Set user variable: $Name"
}

function Convert-ToBasicAuthorization {
    param(
        [string]$Username,
        [string]$Password
    )

    if ([string]::IsNullOrWhiteSpace($Username) -or [string]::IsNullOrWhiteSpace($Password)) {
        return ""
    }

    $pair = "${Username}:${Password}"
    $base64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($pair))
    return "Basic $base64"
}

Write-Host "ZStack Support Agent environment setup"
Write-Host "Secret values are accepted interactively and will not be printed."
Write-Host "Press Enter to skip any item you do not want to set now."
Write-Host ""

$githubToken = Read-SecretPlainText "GitHub token for GITHUB_MCP_TOKEN"
Set-UserEnvIfProvided -Name "GITHUB_MCP_TOKEN" -Value $githubToken

$tavilyToken = Read-SecretPlainText "Tavily token for TAVILY_HIKARI_TOKEN"
Set-UserEnvIfProvided -Name "TAVILY_HIKARI_TOKEN" -Value $tavilyToken

$bbsUser = Read-Host -Prompt "ZStack BBS username for ZSTACK_BBS_AUTHORIZATION"
$bbsPassword = Read-SecretPlainText "ZStack BBS password"
$bbsAuthorization = Convert-ToBasicAuthorization -Username $bbsUser -Password $bbsPassword
Set-UserEnvIfProvided -Name "ZSTACK_BBS_AUTHORIZATION" -Value $bbsAuthorization

$atlassianUser = Read-Host -Prompt "Jira/Confluence username for ATLASSIAN_AUTHORIZATION"
$atlassianPassword = Read-SecretPlainText "Jira/Confluence password"
$atlassianAuthorization = Convert-ToBasicAuthorization -Username $atlassianUser -Password $atlassianPassword
Set-UserEnvIfProvided -Name "ATLASSIAN_AUTHORIZATION" -Value $atlassianAuthorization

Write-Host ""
Write-Host "Current variable presence:"
$names = @(
    "GITHUB_MCP_TOKEN",
    "ZSTACK_BBS_AUTHORIZATION",
    "TAVILY_HIKARI_TOKEN",
    "ATLASSIAN_AUTHORIZATION"
)

foreach ($name in $names) {
    [pscustomobject]@{
        Name = $name
        Present = -not [string]::IsNullOrWhiteSpace((Get-EnvValue $name))
    }
} | Format-Table -AutoSize

Write-Host "Restart Codex or open a new thread after changing user environment variables."
