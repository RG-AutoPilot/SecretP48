###################################################################################################
# STEP 3b: Provision Databases
# File Name: 03b_Provision-Databases.ps1
# Version: 1.0.2
# Author: Redgate Software Ltd
# Last Updated: 2025-06-27
###################################################################################################

param (
    [string]$sqlInstance,
    [string]$username,
    [string]$password,
    [string]$encryptConnection,
    [string]$trustCert,
    [string]$winAuth,
    [string]$repoLocation
)

# === Convert string inputs to booleans ===
try {
    $winAuthParsed = [bool]::Parse($winAuth)
    $encryptParsed = [bool]::Parse($encryptConnection)
    $trustParsed   = [bool]::Parse($trustCert)
} catch {
    Write-Error "❌ Failed to parse one or more boolean parameters"
    exit 1
}

Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $trustParsed
Set-DbatoolsConfig -FullName sql.connection.encrypt -Value $encryptParsed

# === Fallback validation ===
if (-not $sqlInstance) { Write-Error "❌ Missing SQL instance"; exit 1 }
if (-not $repoLocation) { Write-Error "❌ Missing repo location"; exit 1 }

# === Diagnostic output ===
Write-Host "INFO: Parameters received:"
Write-Host "`tInstance: $sqlInstance"
Write-Host "`twinAuth: $winAuthParsed"
Write-Host "`tusername: $username"
Write-Host "`tpassword: (hidden)"
Write-Host "`tencryptConnection: $encryptParsed"
Write-Host "`ttrustCert: $trustParsed"
Write-Host "`tRepoLocation: $repoLocation"
Import-Module "$PSScriptRoot\..\..\Setup_Files\helper-functions.psm1" -Force


# === Defaults ===
$sourceDb = "Autopilot_FullRestore"
$targetDb = "Autopilot_Treated"

# === Derive script paths ===
$scriptFolder = Join-Path $repoLocation "Setup_Files\Sample_Database_Scripts"
$schemaCreateScript         = Join-Path $scriptFolder "CreateAutopilotDatabaseSchemaOnly.sql"
$productionDataInsertScript = Join-Path $scriptFolder "CreateAutopilotDatabaseProductionData.sql"
$testDataInsertScript       = Join-Path $scriptFolder "CreateAutopilotDatabaseTestData.sql"

$TrustServerCertificate = $trustParsed

# === Validate required files exist ===
if (-not (Test-Path $schemaCreateScript)) {
    Write-Error "❌ Missing schema creation script: $schemaCreateScript"
    exit 1
}
if (-not (Test-Path $productionDataInsertScript)) {
    Write-Error "❌ Missing production data insert script: $productionDataInsertScript"
    exit 1
}
if (-not (Test-Path $testDataInsertScript)) {
    Write-Error "❌ Missing test data insert script: $testDataInsertScript"
    exit 1
}

# === Create credential if needed ===
if (-not $winAuthParsed -and $username) {
    $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
    $SqlCredential = New-Object System.Management.Automation.PSCredential ($username, $securePassword)
}

# === Set environment variables for compatibility ===
[System.Environment]::SetEnvironmentVariable("sqlInstance", $sqlInstance)
[System.Environment]::SetEnvironmentVariable("sqlUser", $username)
[System.Environment]::SetEnvironmentVariable("sqlPassword", $password)
[System.Environment]::SetEnvironmentVariable("sourceDb", $sourceDb)
[System.Environment]::SetEnvironmentVariable("targetDb", $targetDb)
[System.Environment]::SetEnvironmentVariable("winAuth", $winAuthParsed)
[System.Environment]::SetEnvironmentVariable("TDM_AUTOPILOT_ROOT", $repoLocation)
[System.Environment]::SetEnvironmentVariable("schemaCreateScript", $schemaCreateScript)
[System.Environment]::SetEnvironmentVariable("productionDataInsertScript", $productionDataInsertScript)
[System.Environment]::SetEnvironmentVariable("testDataInsertScript", $testDataInsertScript)
[System.Environment]::SetEnvironmentVariable("TrustServerCertificate", $TrustServerCertificate)

# === Run provision logic ===
Write-Host "INFO: Beginning database provisioning..." -ForegroundColor Cyan
Write-Host "INFO: Creating fallback Autopilot databases..." -ForegroundColor Cyan

New-SampleDatabasesAutopilot `
    -WinAuth:$winAuthParsed `
    -sqlInstance:$sqlInstance `
    -sourceDb:$sourceDb `
    -targetDb:$targetDb `
    -schemaCreateScript:$schemaCreateScript `
    -productionDataInsertScript:$productionDataInsertScript `
    -testDataInsertScript:$testDataInsertScript `
    -SqlCredential:$SqlCredential
