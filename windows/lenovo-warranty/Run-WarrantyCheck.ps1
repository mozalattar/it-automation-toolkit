<#
.SYNOPSIS
    Bulk Lenovo warranty check: reads serial numbers from a text file and
    exports warranty status, model, purchase year and device age to CSV.

.DESCRIPTION
    Uses the community Get-LenovoInfo script from the PowerShell Gallery,
    which queries Lenovo's public warranty service. One serial per line in
    the input file; blank lines and lines starting with # are ignored.

.PARAMETER SerialsFile
    Text file with one serial number per line. Default: serials.txt next to this script.

.PARAMETER OutputFile
    CSV file to write. Default: warranty_results.csv next to this script.

.PARAMETER DelaySeconds
    Pause between lookups so Lenovo's service is not flooded. Default: 1.

.EXAMPLE
    .\Run-WarrantyCheck.ps1

.EXAMPLE
    .\Run-WarrantyCheck.ps1 -SerialsFile C:\Audit\serials.txt -OutputFile C:\Audit\results.csv

.NOTES
    Author: Mohammed AlAttar · https://github.com/mozalattar
    Requires: Windows PowerShell 5.1 or PowerShell 7, internet access.
#>
[CmdletBinding()]
param(
    [string]$SerialsFile = (Join-Path $PSScriptRoot 'serials.txt'),
    [string]$OutputFile  = (Join-Path $PSScriptRoot 'warranty_results.csv'),
    [ValidateRange(0, 30)]
    [int]$DelaySeconds   = 1
)

$ErrorActionPreference = 'Stop'

# --- Input file -------------------------------------------------------------
if (-not (Test-Path -LiteralPath $SerialsFile)) {
    $example = Join-Path $PSScriptRoot 'serials.example.txt'
    Write-Host "Serial list not found: $SerialsFile" -ForegroundColor Red
    if (Test-Path -LiteralPath $example) {
        Write-Host "Copy serials.example.txt to serials.txt and put one serial per line." -ForegroundColor Yellow
    }
    exit 1
}

$serials = @(Get-Content -LiteralPath $SerialsFile |
    ForEach-Object { ($_ -replace '\s', '').ToUpper() } |
    Where-Object { $_ -and -not $_.StartsWith('#') } |
    Select-Object -Unique)

if ($serials.Count -eq 0) {
    Write-Host "No serial numbers found in $SerialsFile." -ForegroundColor Yellow
    exit 1
}

# --- Get-LenovoInfo dependency -----------------------------------------------
if (-not (Get-Command Get-LenovoInfo -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Get-LenovoInfo from the PowerShell Gallery (current user only)..." -ForegroundColor Yellow
    try {
        Install-Script -Name Get-LenovoInfo -Scope CurrentUser -Force -ErrorAction Stop
    } catch {
        Write-Host "Could not install Get-LenovoInfo: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
    # Make the newly installed script visible in this session
    $scriptDirs = @(
        (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'WindowsPowerShell\Scripts'),
        (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Scripts')
    ) | Where-Object { Test-Path -LiteralPath $_ }
    foreach ($dir in $scriptDirs) {
        if (($env:PATH -split ';') -notcontains $dir) { $env:PATH = "$env:PATH;$dir" }
    }
    if (-not (Get-Command Get-LenovoInfo -ErrorAction SilentlyContinue)) {
        Write-Host "Get-LenovoInfo was installed but can't be found. Open a new PowerShell window and run this again." -ForegroundColor Red
        exit 1
    }
}

# --- Lookups ------------------------------------------------------------------
$total   = $serials.Count
$results = [System.Collections.Generic.List[object]]::new()
Write-Host ""
Write-Host "Checking $total serial number(s)..." -ForegroundColor Cyan
Write-Host ""

for ($i = 0; $i -lt $total; $i++) {
    $sn  = $serials[$i]
    $idx = $i + 1
    Write-Progress -Activity 'Lenovo warranty check' -Status "[$idx/$total] $sn" -PercentComplete (($idx / $total) * 100)

    try {
        $info = Get-LenovoInfo -Serialnumber $sn -Brief -ErrorAction Stop
        if (-not $info) { throw 'No warranty record returned.' }

        # Several warranty rows can exist; keep the one with the most days left
        $best = $info | Sort-Object { [int]$_.DaysLeft } -Descending | Select-Object -First 1
        $age  = [math]::Round([double]$best.YearsSinceBought, 1)

        $results.Add([PSCustomObject]@{
            Serial             = $sn
            ProductName        = $best.ProductName
            Model              = $best.Model
            WarrantyName       = $best.Name
            Status             = $best.Status
            DaysLeft           = $best.DaysLeft
            'Laptop Age (Yrs)' = $age
            'Year Purchased'   = (Get-Date).AddDays(-[double]$best.YearsSinceBought * 365.25).Year
            DeliveryType       = $best.DeliveryType
            Error              = ''
        })

        $color = switch ($best.Status) { 'Active' { 'Green' } 'Expired' { 'Red' } default { 'Yellow' } }
        Write-Host ("  [{0,3}/{1}]  {2,-12}  {3,-8}  Age: {4,4} yrs  {5}" -f $idx, $total, $sn, $best.Status, $age, $best.ProductName) -ForegroundColor $color
    }
    catch {
        $results.Add([PSCustomObject]@{
            Serial             = $sn
            ProductName        = ''
            Model              = ''
            WarrantyName       = ''
            Status             = 'ERROR'
            DaysLeft           = ''
            'Laptop Age (Yrs)' = ''
            'Year Purchased'   = ''
            DeliveryType       = ''
            Error              = $_.Exception.Message
        })
        Write-Host ("  [{0,3}/{1}]  {2,-12}  ERROR: {3}" -f $idx, $total, $sn, $_.Exception.Message) -ForegroundColor Yellow
    }

    if ($DelaySeconds -gt 0 -and $idx -lt $total) { Start-Sleep -Seconds $DelaySeconds }
}
Write-Progress -Activity 'Lenovo warranty check' -Completed

# --- Export and summary ---------------------------------------------------------
$results | Export-Csv -LiteralPath $OutputFile -NoTypeInformation -Encoding UTF8

$active  = @($results | Where-Object Status -eq 'Active').Count
$expired = @($results | Where-Object Status -eq 'Expired').Count
$errors  = @($results | Where-Object Status -eq 'ERROR').Count

Write-Host ""
Write-Host "Saved to: $OutputFile" -ForegroundColor Green
Write-Host ""
Write-Host "Summary" -ForegroundColor Cyan
Write-Host "  Total   : $total"
Write-Host "  Active  : $active"  -ForegroundColor Green
Write-Host "  Expired : $expired" -ForegroundColor Red
Write-Host "  Errors  : $errors"  -ForegroundColor Yellow
Write-Host ""
