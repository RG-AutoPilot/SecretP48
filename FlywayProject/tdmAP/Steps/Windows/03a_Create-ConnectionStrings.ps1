###################################################################################################
# STEP 3a: Build and Export Source/Target Connection Strings for SQL Server
# File Name: 03a_Create-ConnectionStrings.ps1
# Version: 1.0.4
# Author: Redgate Software Ltd
# Last Updated: 2025-06-23
###################################################################################################

param (
    [string]$sqlInstance,
    [string]$username,
    [string]$password,
    [string]$encryptConnection,
    [string]$trustCert,
    [string]$winAuth
)

# === Convert string inputs to native booleans ===
try {
    $winAuth = [bool]::Parse($winAuth)
    $encryptConnectionTwo = [bool]::Parse($encryptConnection)
    $trustCertTwo = [bool]::Parse($trustCert)
} catch {
    Write-Error "❌ One or more parameters could not be parsed as boolean. Check input formatting."
    exit 1
}

# === Fallback values ===
if (-not $sqlInstance) { Write-Error "❌ Missing SQL instance"; exit 1 }
if (-not $username) { $username = "" }
if (-not $password) { $password = "" }

# === Import shared logic ===
Import-Module "$PSScriptRoot\..\..\Setup_Files\helper-functions.psm1" -Force

# === Diagnostic Echo ===
Write-Host "INFO: Parameters received:"
Write-Host "`tInstance: $sqlInstance"
Write-Host "`twinAuth: $winAuth"
Write-Host "`tusername: $username"
Write-Host "`tpassword: (hidden)"
Write-Host "`tencryptConnection: $encryptConnectionTwo"
Write-Host "`ttrustCert: $trustCertTwo"

# === Apply dbatools config ===
Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $trustCertTwo
Set-DbatoolsConfig -FullName sql.connection.encrypt -Value $encryptConnectionTwo



# === Build connection strings ===
#$trustCertValue = if ($trustCertTwo) { "yes" } else { "no" }
#$encryptValue   = if ($encryptConnectionTwo) { "yes" } else { "no" }

if ($winAuth) {
    $sourceConn = "server=$sqlInstance;database=$sourceDb;Trusted_Connection=yes;TrustServerCertificate=$trustCertValue;Encrypt=$encryptValue"
    $targetConn = "server=$sqlInstance;database=$targetDb;Trusted_Connection=yes;TrustServerCertificate=$trustCertValue;Encrypt=$encryptValue"
} else {
    $sourceConn = "server=$sqlInstance;database=$sourceDb;UID=$username;Password=$password;TrustServerCertificate=$trustCertValue;Encrypt=$encryptValue"
    $targetConn = "server=$sqlInstance;database=$targetDb;UID=$username;Password=$password;TrustServerCertificate=$trustCertValue;Encrypt=$encryptValue"
}

# === Export connection strings for downstream steps ===
[System.Environment]::SetEnvironmentVariable("sourceConnectionString", $sourceConn)
[System.Environment]::SetEnvironmentVariable("targetConnectionString", $targetConn)

Write-Host "INFO: Source and target connection strings generated." -ForegroundColor DarkCyan

# === Attempt actual connection ===
try {
    $instance = Connect-DbaInstance -SqlInstance $sqlInstance `
                                    -TrustServerCertificate:$trustCertValue `
                                    -Encrypt:$encryptValue
    Write-Host "✅ Successfully connected to SQL instance '$sqlInstance'."
    $instance.Query("SELECT GETDATE() AS [ServerTime]") | Out-Host
} catch {
    Write-Error "❌ Failed to connect to instance '$sqlInstance': $_"
}
