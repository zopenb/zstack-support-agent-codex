param(
    [switch]$CheckNetwork,
    [switch]$CheckAtlassianInitialize,
    [string]$CodexExe
)

$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$pluginRoot = Split-Path -Parent $scriptDir

function Write-Check {
    param(
        [ValidateSet("PASS", "WARN", "FAIL", "OPTIONAL")]
        [string]$Status,
        [string]$Name,
        [string]$Detail,
        [string]$Fix = ""
    )

    $line = "{0,-8} {1} - {2}" -f $Status, $Name, $Detail
    Write-Host $line
    if (-not [string]::IsNullOrWhiteSpace($Fix)) {
        Write-Host ("         Fix: {0}" -f $Fix)
    }
}

function Get-FirstCommand {
    param([string]$Name)
    return Get-Command $Name -ErrorAction SilentlyContinue | Select-Object -First 1
}

function Invoke-Version {
    param(
        [string]$FilePath,
        [string[]]$ArgumentList
    )

    try {
        $output = & $FilePath @ArgumentList 2>&1 | Select-Object -First 1
        return [pscustomobject]@{
            Ok = ($LASTEXITCODE -eq 0 -or $null -eq $LASTEXITCODE)
            Output = [string]$output
            Error = $null
        }
    } catch {
        return [pscustomobject]@{
            Ok = $false
            Output = ""
            Error = $_.Exception.Message
        }
    }
}

function Resolve-CodexExe {
    param([string]$ExplicitPath)

    $candidates = @()
    if (-not [string]::IsNullOrWhiteSpace($ExplicitPath)) {
        $candidates += $ExplicitPath
    }
    if (-not [string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
        $candidates += (Join-Path $env:LOCALAPPDATA "OpenAI\Codex\bin\*\codex.exe")
    }
    $cmd = Get-FirstCommand "codex"
    if ($cmd) {
        $candidates += $cmd.Source
    }

    foreach ($candidate in ($candidates | Where-Object { $_ } | Select-Object -Unique)) {
        $resolvedItems = Get-ChildItem -Path $candidate -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending
        foreach ($item in $resolvedItems) {
            if (-not (Test-Path -LiteralPath $item.FullName)) {
                continue
            }
            $version = Invoke-Version -FilePath $item.FullName -ArgumentList @("--version")
            if ($version.Ok) {
                return [pscustomobject]@{
                    Path = $item.FullName
                    Version = $version.Output
                    Source = "usable"
                    Error = $null
                }
            }
            if ($item.FullName -match "\\WindowsApps\\") {
                Write-Check -Status "WARN" -Name "Codex WindowsApps entry" -Detail "Found but cannot execute: $($item.FullName)" -Fix "Use the local Codex bin path or pass -CodexExe <path>."
            }
        }
    }

    return $null
}

function Test-Python {
    param(
        [string]$Name,
        [string]$Path
    )

    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path)) {
        Write-Check -Status "WARN" -Name $Name -Detail "Python executable not found."
        return
    }

    $code = "import sys; print(sys.version.split()[0]); import docx; print(getattr(docx, '__version__', 'unknown'))"
    try {
        $output = & $Path -c $code 2>&1
        if ($LASTEXITCODE -eq 0 -and $output.Count -ge 2) {
            Write-Check -Status "PASS" -Name $Name -Detail "Python $($output[0]), python-docx $($output[1])"
        } else {
            $message = (($output | Select-Object -First 1) -join "")
            Write-Check -Status "WARN" -Name $Name -Detail "Python found but python-docx check failed: $message" -Fix "Use Codex bundled Python, or install python-docx for manual terminal use."
        }
    } catch {
        Write-Check -Status "WARN" -Name $Name -Detail "Python check failed: $($_.Exception.Message)" -Fix "Use Codex bundled Python, or install a normal Python distribution."
    }
}

function Get-EnvValue {
    param([string]$Name)

    foreach ($scope in @("Process", "User", "Machine")) {
        $value = [Environment]::GetEnvironmentVariable($Name, $scope)
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            return [pscustomobject]@{
                Scope = $scope
                Value = $value
            }
        }
    }
    return $null
}

function Test-BasicHeaderShape {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $false
    }
    if ($Value.Trim() -notmatch '^Basic\s+\S+$') {
        return $false
    }
    $encoded = ($Value.Trim() -replace '^Basic\s+', '').Trim()
    try {
        $decoded = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($encoded))
        return ($decoded -match ':')
    } catch {
        return $false
    }
}

Write-Host "ZStack Support Agent local dependency check"
Write-Host "Secret values are not printed."
Write-Host "Plugin root: $pluginRoot"
Write-Host ""

$psVersion = $PSVersionTable.PSVersion.ToString()
if ($PSVersionTable.PSEdition -eq "Desktop" -and $PSVersionTable.PSVersion.Major -ge 5) {
    Write-Check -Status "PASS" -Name "PowerShell" -Detail "Windows PowerShell $psVersion"
} elseif ($PSVersionTable.PSVersion.Major -ge 7) {
    Write-Check -Status "PASS" -Name "PowerShell" -Detail "PowerShell $psVersion"
} else {
    Write-Check -Status "FAIL" -Name "PowerShell" -Detail "PowerShell $psVersion is too old." -Fix "Use Windows PowerShell 5.1 or PowerShell 7+."
}

$codex = Resolve-CodexExe -ExplicitPath $CodexExe
if ($codex) {
    Write-Check -Status "PASS" -Name "Codex CLI" -Detail "$($codex.Version) at $($codex.Path)"
} else {
    Write-Check -Status "FAIL" -Name "Codex CLI" -Detail "No executable Codex CLI found." -Fix "Install Codex Desktop or pass -CodexExe <path>."
}

$git = Get-FirstCommand "git"
if ($git) {
    $version = Invoke-Version -FilePath $git.Source -ArgumentList @("--version")
    Write-Check -Status "PASS" -Name "Git" -Detail "$($version.Output) at $($git.Source)"
} else {
    Write-Check -Status "WARN" -Name "Git" -Detail "git was not found on PATH." -Fix "Install Git for Windows for development, update, and push workflows."
}

$ssh = Get-FirstCommand "ssh"
if ($ssh) {
    Write-Check -Status "PASS" -Name "OpenSSH" -Detail "ssh found at $($ssh.Source)"
} else {
    Write-Check -Status "WARN" -Name "OpenSSH" -Detail "ssh was not found on PATH." -Fix "Install Windows OpenSSH Client if GitHub SSH push is needed."
}

$systemPython = Get-FirstCommand "python"
if ($systemPython) {
    $version = Invoke-Version -FilePath $systemPython.Source -ArgumentList @("--version")
    if ($version.Output -match "Python was not found|Microsoft Store|App execution aliases") {
        Write-Check -Status "WARN" -Name "System Python" -Detail "PATH points to Windows Store alias, not a usable Python." -Fix "Use Codex bundled Python or install Python and disable the Store alias."
    } else {
        Test-Python -Name "System Python" -Path $systemPython.Source
    }
} else {
    Write-Check -Status "WARN" -Name "System Python" -Detail "python was not found on PATH." -Fix "This is OK inside Codex if bundled Python is available."
}

$bundledPythonCandidates = @()
if (-not [string]::IsNullOrWhiteSpace($env:USERPROFILE)) {
    $bundledPythonCandidates += (Join-Path $env:USERPROFILE ".cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe")
}
$bundledPython = $bundledPythonCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if ($bundledPython) {
    Test-Python -Name "Codex bundled Python" -Path $bundledPython
} else {
    Write-Check -Status "WARN" -Name "Codex bundled Python" -Detail "Bundled Python path not found." -Fix "Open the task in Codex Desktop, or use system Python with python-docx."
}

$soffice = Get-FirstCommand "soffice"
$knownSoffice = @(
    "$env:ProgramFiles\LibreOffice\program\soffice.exe",
    "${env:ProgramFiles(x86)}\LibreOffice\program\soffice.exe",
    "$env:LOCALAPPDATA\Programs\LibreOffice\program\soffice.exe"
) | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -First 1
if ($soffice) {
    $version = Invoke-Version -FilePath $soffice.Source -ArgumentList @("--version")
    Write-Check -Status "PASS" -Name "LibreOffice" -Detail "$($version.Output) at $($soffice.Source)"
} elseif ($knownSoffice) {
    $version = Invoke-Version -FilePath $knownSoffice -ArgumentList @("--version")
    Write-Check -Status "PASS" -Name "LibreOffice" -Detail "$($version.Output) at $knownSoffice"
} else {
    Write-Check -Status "OPTIONAL" -Name "LibreOffice" -Detail "soffice not found. DOCX generation still works; automated PDF/PNG visual QA will be skipped."
}

$wordType = [type]::GetTypeFromProgID("Word.Application")
if ($wordType) {
    Write-Check -Status "OPTIONAL" -Name "Microsoft Word COM" -Detail "Word.Application is registered. This can help manual or future automated visual checks."
} else {
    Write-Check -Status "OPTIONAL" -Name "Microsoft Word COM" -Detail "Word.Application is not registered. This does not block DOCX generation."
}

$envChecks = @(
    [pscustomobject]@{ Name = "GITHUB_MCP_TOKEN"; Kind = "GitHubToken" },
    [pscustomobject]@{ Name = "ZSTACK_BBS_AUTHORIZATION"; Kind = "Basic" },
    [pscustomobject]@{ Name = "TAVILY_HIKARI_TOKEN"; Kind = "Token" },
    [pscustomobject]@{ Name = "ATLASSIAN_AUTHORIZATION"; Kind = "Basic" }
)
foreach ($item in $envChecks) {
    $value = Get-EnvValue $item.Name
    if (-not $value) {
        Write-Check -Status "WARN" -Name $item.Name -Detail "Missing." -Fix "Set this Windows user environment variable if the corresponding MCP connector is needed."
        continue
    }

    $shapeOk = $true
    if ($item.Kind -eq "Basic") {
        $shapeOk = Test-BasicHeaderShape $value.Value
    } elseif ($item.Kind -eq "GitHubToken") {
        $shapeOk = ($value.Value -match '^(github_pat_|ghp_|gho_|ghu_|ghs_|ghr_)')
    }

    if ($shapeOk) {
        Write-Check -Status "PASS" -Name $item.Name -Detail "Present in $($value.Scope); format looks valid."
    } else {
        Write-Check -Status "WARN" -Name $item.Name -Detail "Present in $($value.Scope), but format looks unexpected." -Fix "Check the documented token/header format without pasting the value into chat."
    }
}

$legacyAtlassian = Get-EnvValue "ATLASSIAN_BASIC_AUTH"
if ($legacyAtlassian) {
    Write-Check -Status "WARN" -Name "ATLASSIAN_BASIC_AUTH" -Detail "Legacy variable exists in $($legacyAtlassian.Scope). New installs should use ATLASSIAN_AUTHORIZATION only." -Fix "[Environment]::SetEnvironmentVariable('ATLASSIAN_BASIC_AUTH', `$null, 'User')"
}

if ($CheckNetwork) {
    Write-Host ""
    Write-Host "Network reachability"
    $targets = @(
        [pscustomobject]@{ Name = "github"; Host = "api.githubcopilot.com"; Port = 443 },
        [pscustomobject]@{ Name = "zstack-bbs"; Host = "mcp.zopen.top"; Port = 16666 },
        [pscustomobject]@{ Name = "tavily_hikari"; Host = "tavily.zopen1.com"; Port = 443 },
        [pscustomobject]@{ Name = "zstack_atlassian_shared"; Host = "172.18.250.27"; Port = 3340 }
    )

    foreach ($target in $targets) {
        $ok = $false
        try {
            $ok = [bool](Test-NetConnection -ComputerName $target.Host -Port $target.Port -InformationLevel Quiet -WarningAction SilentlyContinue)
        } catch {
            $ok = $false
        }

        if ($ok) {
            Write-Check -Status "PASS" -Name $target.Name -Detail "$($target.Host):$($target.Port) is reachable."
        } else {
            Write-Check -Status "WARN" -Name $target.Name -Detail "$($target.Host):$($target.Port) is not reachable." -Fix "Check company network, VPN, proxy, firewall, or remote MCP service status."
        }
    }
} else {
    Write-Host ""
    Write-Check -Status "OPTIONAL" -Name "Network checks" -Detail "Skipped. Re-run with -CheckNetwork to test MCP TCP reachability."
}

if ($CheckAtlassianInitialize) {
    Write-Host ""
    Write-Host "Atlassian MCP initialize check"
    $debugScript = Join-Path $scriptDir "debug-atlassian-mcp.ps1"
    if (Test-Path -LiteralPath $debugScript) {
        & powershell -NoProfile -ExecutionPolicy Bypass -File $debugScript
    } else {
        Write-Check -Status "FAIL" -Name "Atlassian initialize" -Detail "debug-atlassian-mcp.ps1 not found."
    }
}
