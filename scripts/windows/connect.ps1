$ErrorActionPreference = "Stop"

$AppDir = Join-Path $env:APPDATA "NJUPT-AutoConnect"
$ConfigPath = Join-Path $AppDir "config.json"
$SecretPath = Join-Path $AppDir "password.dpapi"
$FastPortalUrl = "http://10.10.244.11:801/eportal/portal/login"
$CheckUrl = "http://connect.rom.miui.com/generate_204"

function Ensure-AppDir {
    if (-not (Test-Path -LiteralPath $AppDir)) {
        New-Item -ItemType Directory -Path $AppDir | Out-Null
    }
}

function Normalize-Isp([string]$Value) {
    switch ($Value.Trim().ToLowerInvariant()) {
        "2" { return "cmcc" }
        "cmcc" { return "cmcc" }
        "mobile" { return "cmcc" }
        "3" { return "njupt" }
        "njupt" { return "njupt" }
        "edu" { return "njupt" }
        default { return "ctcc" }
    }
}

function Get-Suffix([string]$Isp) {
    switch ($Isp) {
        "cmcc" { return "@cmcc" }
        "njupt" { return "" }
        default { return "@njxy" }
    }
}

function Protect-Password([securestring]$Password) {
    Ensure-AppDir
    $Password | ConvertFrom-SecureString | Set-Content -LiteralPath $SecretPath -Encoding ASCII
}

function Read-ProtectedPassword {
    if (-not (Test-Path -LiteralPath $SecretPath)) {
        return $null
    }
    $encrypted = Get-Content -LiteralPath $SecretPath -Raw
    return $encrypted | ConvertTo-SecureString
}

function ConvertTo-PlainText([securestring]$Secure) {
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secure)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
    } finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
    }
}

function Save-Config($Config) {
    Ensure-AppDir
    $Config | ConvertTo-Json | Set-Content -LiteralPath $ConfigPath -Encoding UTF8
}

function Load-Config {
    if (-not (Test-Path -LiteralPath $ConfigPath)) {
        return $null
    }
    return Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
}

function Configure {
    Write-Host "First setup for NJUPT AutoConnect"
    $account = Read-Host "Account"
    Write-Host "ISP: 1=CTCC @njxy, 2=CMCC @cmcc, 3=NJUPT edu"
    $isp = Normalize-Isp (Read-Host "Choose ISP [1]")
    $password = Read-Host "Password" -AsSecureString
    $remember = Read-Host "Remember password on this Windows user? [Y/n]"
    $rememberPassword = $remember.Trim().ToLowerInvariant() -ne "n"

    if ($rememberPassword) {
        Protect-Password $password
    } elseif (Test-Path -LiteralPath $SecretPath) {
        Remove-Item -LiteralPath $SecretPath -Force
    }

    $config = [pscustomobject]@{
        Account = $account.Trim()
        Isp = $isp
        RememberPassword = $rememberPassword
    }
    Save-Config $config
    return @($config, $password)
}

function Test-Online {
    try {
        $response = Invoke-WebRequest -Uri $CheckUrl -TimeoutSec 4 -MaximumRedirection 0 -UseBasicParsing
        return $response.StatusCode -eq 204
    } catch {
        if ($_.Exception.Response -and [int]$_.Exception.Response.StatusCode -eq 204) {
            return $true
        }
        return $false
    }
}

function Build-LoginUrl($Config, [string]$Password) {
    $account = ",0,$($Config.Account)$(Get-Suffix $Config.Isp)"
    $pairs = [ordered]@{
        login_method = "1"
        user_account = $account
        user_password = $Password
    }
    $query = ($pairs.GetEnumerator() | ForEach-Object {
        "{0}={1}" -f [Uri]::EscapeDataString($_.Key), [Uri]::EscapeDataString([string]$_.Value)
    }) -join "&"
    return "$FastPortalUrl`?$query"
}

function Invoke-LoginRequest([string]$LoginUrl) {
    $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
    if ($null -ne $curl) {
        $output = & $curl.Source --noproxy "*" --silent --show-error --max-time 10 $LoginUrl 2>&1
        if ($LASTEXITCODE -eq 0) {
            return [string]$output
        }
        throw "curl.exe failed: $output"
    }

    $response = Invoke-WebRequest -Uri $LoginUrl -TimeoutSec 10 -UseBasicParsing
    return [string]$response.Content
}

function Test-Success([string]$Body) {
    return $Body.Contains('"result":1') -or $Body.Contains("认证成功") -or $Body.Contains("登录成功") -or $Body.Contains("success")
}

$config = Load-Config
$securePassword = $null

if ($null -eq $config) {
    $setup = Configure
    $config = $setup[0]
    $securePassword = $setup[1]
} elseif ($config.RememberPassword) {
    $securePassword = Read-ProtectedPassword
    if ($null -eq $securePassword) {
        Write-Host "Saved password was not found. Reconfigure."
        $setup = Configure
        $config = $setup[0]
        $securePassword = $setup[1]
    }
} else {
    $securePassword = Read-Host "Password" -AsSecureString
}

if ([string]::IsNullOrWhiteSpace($config.Account)) {
    throw "Account is empty. Delete $ConfigPath and run again."
}

if (Test-Online) {
    Write-Host "Already online. Nothing to do."
    exit 0
}

$plainPassword = ConvertTo-PlainText $securePassword
try {
    $loginUrl = Build-LoginUrl $config $plainPassword
    Write-Host "Opening NJUPT intranet login endpoint..."
    try {
        $body = Invoke-LoginRequest $loginUrl
        if (Test-Success $body) {
            Write-Host "Login request accepted."
            exit 0
        }
        Write-Host "Portal did not confirm success. Opening browser fallback..."
        Start-Process $loginUrl
        exit 2
    } catch {
        Write-Host "Portal request failed. Opening browser fallback..."
        Start-Process $loginUrl
        exit 2
    }
} finally {
    $plainPassword = $null
}
