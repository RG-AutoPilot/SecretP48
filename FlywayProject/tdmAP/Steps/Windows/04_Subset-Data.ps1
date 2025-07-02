# 04_Subset-Data.ps1 - Subsets the source database into the target database using rgsubset

# ===========================
# File Name: 04_Subset-Data.ps1
# Version: 1.0.0
# Author: Redgate Software Ltd
# Last Updated: 2025-04-23
# Description: TDM Data Treatment: Subset target database to prferred specification
# Last Update Comment:
# ===========================
param (
    [switch]$previewOnly,
    [string]$sqlInstance,
    [string]$sourceDb,
    [string]$targetDb,
    [string]$subsetterOptionsFile,
    [string]$autopilotRootDir,
    [string]$sourceConnectionString,
    [string]$targetConnectionString,
    [string]$logLevel = "information",
    [bool]$autoContinue = $false,
    [bool]$acceptAllDefaults = $false
)

Write-Host $sourceConnectionString
Write-Host $targetConnectionString
Write-Host $subsetterOptionsFile
# Normalize relative paths from the config if they start with '.\' or './'
function Normalize-Path {
    param (
        [string]$path
    )
    if ($path -match '^[.][\\/]' ) {
        return Join-Path $autopilotRootDir ($path -replace '^[.][\\/]', '')
    }
    return $path
}


# Apply normalization (Change any .\ paths)
$subsetterOptionsFile      = Normalize-Path $subsetterOptionsFile

Write-Host "Running rgsubset to copy data..." -ForegroundColor DarkCyan																		  																	   
# === Build the real argument list ===
$rgsubsetArgs = @(
    'run'
    '--database-engine=sqlserver'
    "--source-connection-string=$sourceConnectionString"
    "--target-connection-string=$targetConnectionString"
    '--target-database-write-mode=Overwrite'
    "--log-level=$logLevel"
)

if (-not [string]::IsNullOrWhiteSpace($subsetterOptionsFile)) {
    $rgsubsetArgs += "--options-file=$subsetterOptionsFile"
}

# === Redact Sensitive Information ===
$previewArgs = $rgsubsetArgs.ForEach({
    if ($_ -like "--*connection-string=*") {
        # Find and redact only the password inside the connection string
        return ($_ -replace '(?i)(Password|Pwd)=.*?(;|$)', '${1}=[REDACTED]$2')
    }
    return $_
})

if ($previewOnly) {
	Write-Host "`n> CLI Command Example:" -ForegroundColor Cyan
	Write-Host "  rgsubset $($previewArgs -join ' ')" -ForegroundColor Blue  -BackgroundColor Black 
	Write-Host ""
    return
}
Write-Host $rgsubsetArgs
# === Execute the real command ===
try {
    & rgsubset @rgsubsetArgs | Tee-Object -Variable rgsubsetOutput

    if ($LASTEXITCODE -ne 0 -or ($rgsubsetOutput -match "ERROR")) {
        throw "rgsubset failed with exit code $LASTEXITCODE."
    }

    Write-Host "rgsubset completed successfully." -ForegroundColor Green
} catch {
    Write-Error "Subsetting failed: $_"
    exit 1
}