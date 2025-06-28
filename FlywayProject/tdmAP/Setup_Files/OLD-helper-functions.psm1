Function Install-Dbatools {
    param (
        $autoContinue = $false,
        $trustCert = $true
    )

    if (Get-InstalledModule | Where-Object { $_.Name -like "dbatools" }) {
        Write-Host "  dbatools PowerShell Module is installed." -ForegroundColor Green
        return $true
    }

    Write-Host "  dbatools PowerShell Module is not installed" -ForegroundColor DarkCyan
    Write-Host "    Installing dbatools (requires admin privileges)." -ForegroundColor DarkCyan

    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $runningAsAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $runningAsAdmin) {
        Write-Error "    Script not running as admin. Please either install dbatools manually, or run this script as an administrator."
        return $false
    }

    if ($autoContinue) {
        Install-Module dbatools -Confirm:$False -Force
    } else {
        Install-Module dbatools
    }

    Write-Host "  Importing dbatools PowerShell module." -ForegroundColor DarkCyan
    Import-Module dbatools

    if ($trustCert) {
        Write-Warning "Note: For convenience, trustCert is set to true. This is not best practice."
    }

    if ($trustCert -ne $true) {
        Write-Host "    Updating dbatools configuration (for this session only) to trust server certificates, and not to encrypt connections." -ForegroundColor DarkCyan
        Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $true
        Set-DbatoolsConfig -FullName sql.connection.encrypt -Value $false
    }

    return $true
}
Export-ModuleMember -Function Install-Dbatools

Function New-SampleDatabases {
    param (
        [bool]$WinAuth,
        [string]$sqlInstance,
        [string]$sourceDb,
        [string]$targetDb,
        [string]$fullRestoreCreateScript,
        [string]$subsetCreateScript,
        [PSCredential]$SqlCredential,
        [bool]$TrustServerCertificate = $true,
        [bool]$Encrypt = $false
    )

    Write-Verbose "  If exists, dropping the source and target databases"
    if ($WinAuth) {
        $dbsToDelete = Get-DbaDatabase -SqlInstance $sqlInstance -Database $sourceDb,$targetDb -TrustServerCertificate:$TrustServerCertificate -Encrypt:$Encrypt
    } else {
        $dbsToDelete = Get-DbaDatabase -SqlInstance $sqlInstance -Database $sourceDb,$targetDb -SqlCredential $SqlCredential -TrustServerCertificate:$TrustServerCertificate -Encrypt:$Encrypt
    }

    foreach ($db in $dbsToDelete.Name) {
        $sql = "ALTER DATABASE $db SET single_user WITH ROLLBACK IMMEDIATE; DROP DATABASE $db;"
        Invoke-DbaQuery -SqlInstance $sqlInstance -Query $sql -SqlCredential $SqlCredential -TrustServerCertificate:$TrustServerCertificate -Encrypt:$Encrypt
    }

    New-DbaDatabase -SqlInstance $sqlInstance -Name $sourceDb, $targetDb -SqlCredential $SqlCredential -TrustServerCertificate:$TrustServerCertificate -Encrypt:$Encrypt | Out-Null

    Invoke-DbaQuery -SqlInstance $sqlInstance -Database $sourceDb -File $fullRestoreCreateScript -SqlCredential $SqlCredential -TrustServerCertificate:$TrustServerCertificate -Encrypt:$Encrypt | Out-Null
    Invoke-DbaQuery -SqlInstance $sqlInstance -Database $targetDb -File $subsetCreateScript -SqlCredential $SqlCredential -TrustServerCertificate:$TrustServerCertificate -Encrypt:$Encrypt | Out-Null

    $totalFullRestoreOrders = (Invoke-DbaQuery -SqlInstance $sqlInstance -Database $sourceDb -Query "SELECT COUNT (*) AS TotalOrders FROM dbo.Orders" -SqlCredential $SqlCredential -TrustServerCertificate:$TrustServerCertificate -Encrypt:$Encrypt).TotalOrders
    $totalSubsetOrders = (Invoke-DbaQuery -SqlInstance $sqlInstance -Database $targetDb -Query "SELECT COUNT (*) AS TotalOrders FROM dbo.Orders" -SqlCredential $SqlCredential -TrustServerCertificate:$TrustServerCertificate -Encrypt:$Encrypt).TotalOrders    

    if ($totalFullRestoreOrders -ne 830) {
        Write-Error "    There should be 830 rows in $sourceDb, but there are $totalFullRestoreOrders."
        return $false
    }
    if ($totalSubsetOrders -ne 0) {
        Write-Error "    There should be 0 rows in $targetDb, but there are $totalSubsetOrders."
        return $false
    }

    return $true
}
Export-ModuleMember -Function New-SampleDatabases

Function New-SampleDatabasesAutopilot {
    param (
        [bool]$WinAuth,
        [string]$sqlInstance,
        [string]$sourceDb,
        [string]$targetDb,
        [string]$schemaCreateScript,
        [string]$productionDataInsertScript,
        [string]$testDataInsertScript,
        [PSCredential]$SqlCredential,
        [bool]$TrustServerCertificate = $true,
        [bool]$Encrypt = $false
    )

    Write-Host "  If exists, dropping the source and target databases" -ForegroundColor DarkCyan
    if ($WinAuth) {
        $dbsToDelete = Get-DbaDatabase -SqlInstance $sqlInstance -Database $sourceDb,$targetDb -TrustServerCertificate:$TrustServerCertificate -Encrypt:$Encrypt
    } else {
        $dbsToDelete = Get-DbaDatabase -SqlInstance $sqlInstance -Database $sourceDb,$targetDb -SqlCredential $SqlCredential -TrustServerCertificate:$TrustServerCertificate -Encrypt:$Encrypt
    }

    foreach ($db in $dbsToDelete.Name) {
        Write-Host "    Dropping database $db" -ForegroundColor DarkCyan
        $sql = "ALTER DATABASE $db SET single_user WITH ROLLBACK IMMEDIATE; DROP DATABASE $db;"
        Invoke-DbaQuery -SqlInstance $sqlInstance -Query $sql -SqlCredential $SqlCredential -TrustServerCertificate:$TrustServerCertificate -Encrypt:$Encrypt
    }

    New-DbaDatabase -SqlInstance $sqlInstance -Name $sourceDb, $targetDb -SqlCredential $SqlCredential -TrustServerCertificate:$TrustServerCertificate -Encrypt:$Encrypt | Out-Null

    Invoke-DbaQuery -SqlInstance $sqlInstance -Database $sourceDb -File $schemaCreateScript -SqlCredential $SqlCredential -TrustServerCertificate:$TrustServerCertificate -Encrypt:$Encrypt | Out-Null
    Invoke-DbaQuery -SqlInstance $sqlInstance -Database $sourceDb -File $productionDataInsertScript -SqlCredential $SqlCredential -TrustServerCertificate:$TrustServerCertificate -Encrypt:$Encrypt | Out-Null

    Invoke-DbaQuery -SqlInstance $sqlInstance -Database $targetDb -File $schemaCreateScript -SqlCredential $SqlCredential -TrustServerCertificate:$TrustServerCertificate -Encrypt:$Encrypt | Out-Null

    $totalFullRestoreOrders = (Invoke-DbaQuery -SqlInstance $sqlInstance -Database $sourceDb -Query "SELECT COUNT (*) AS TotalOrders FROM Sales.Orders" -SqlCredential $SqlCredential -TrustServerCertificate:$TrustServerCertificate -Encrypt:$Encrypt).TotalOrders
    $totalSubsetOrders = (Invoke-DbaQuery -SqlInstance $sqlInstance -Database $targetDb -Query "SELECT COUNT (*) AS TotalOrders FROM Sales.Orders" -SqlCredential $SqlCredential -TrustServerCertificate:$TrustServerCertificate -Encrypt:$Encrypt).TotalOrders

    if ($totalFullRestoreOrders -ne 830) {
        Write-Error "    There should be 830 rows in $sourceDb, but there are $totalFullRestoreOrders."
        return $false
    }
    if ($totalSubsetOrders -ne 0) {
        Write-Error "    There should be 0 rows in $targetDb, but there are $totalSubsetOrders."
        return $false
    }

    return $true
}
Export-ModuleMember -Function New-SampleDatabasesAutopilot

# (Other functions omitted for brevity – let me know if you want those updated too.)
