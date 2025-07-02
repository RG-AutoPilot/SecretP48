$iAgreeToTheRedgateEula = $true

Write-Host "=============================================================================================" -ForegroundColor Blue
Write-Host "AUTHENTICATING TDM LICENSE / TRIAL" -ForegroundColor Cyan
Write-Host "=============================================================================================" -ForegroundColor Blue

if (-not $iAgreeToTheRedgateEula) {
    Write-Host "The Redgate EULA can be found here: https://www.red-gate.com/support/license/" -ForegroundColor DarkCyan
    $response = Read-Host "> Do you agree to the Redgate End User License Agreement (EULA)? (Y/N)"
    if ($response.Trim().ToUpper() -ne "Y") {
        Write-Host "Redgate EULA not accepted. Exiting gracefully." -ForegroundColor Yellow
        exit 0
    }
}

# Check for offline permit using both User and Machine scopes
$offlinePermitPath = [Environment]::GetEnvironmentVariable("REDGATE_LICENSING_PERMIT_PATH", "User")
if (-not $offlinePermitPath) {
    $offlinePermitPath = [Environment]::GetEnvironmentVariable("REDGATE_LICENSING_PERMIT_PATH", "Machine")
}

if ($offlinePermitPath) {
    Write-Host "Offline permit already detected at: $offlinePermitPath" -ForegroundColor Green
    Write-Host "Skipping online authentication..." -ForegroundColor Yellow
    exit 0
}

Write-Host "INFO: Authorizing rgsubset, and starting a trial (if not already started):" -ForegroundColor Cyan
Write-Host "CMD:  rgsubset auth login --i-agree-to-the-eula --start-trial" -ForegroundColor Blue
& rgsubset auth login --i-agree-to-the-eula --start-trial

Write-Host ""
Write-Host "INFO: Authorizing rganonymize, and starting a trial (if not already started):" -ForegroundColor Cyan
Write-Host "CMD:  rganonymize auth login --i-agree-to-the-eula --start-trial" -ForegroundColor Blue
& rganonymize auth login --i-agree-to-the-eula --start-trial

Write-Host ""
Write-Host "✅ Authentication complete." -ForegroundColor Green
