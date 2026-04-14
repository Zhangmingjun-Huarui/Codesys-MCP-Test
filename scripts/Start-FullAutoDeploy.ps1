param(
    [string]$ProjectPath = "D:\Codesys-MCP-main\Codesys-MCP-Test\projects\Accumulator_Rev1.0.0.260412.project",
    [string]$CodesysExe = "C:\Program Files\CODESYS 3.5.19.50\CODESYS\Common\CODESYS.exe",
    [string]$Profile = "CODESYS V3.5 SP19 Patch 5",
    [string]$ScriptPath = "D:\Codesys-MCP-main\Codesys-MCP-Test\scripts\deploy_and_collect.py",
    [switch]$KeepConnection = $true
)

$ErrorActionPreference = "Stop"
Write-Host "===== CODESYS Full Auto Deploy =====" -ForegroundColor Cyan

if ($KeepConnection) {
    Write-Host "  Mode: KEEP CONNECTION ALIVE" -ForegroundColor Cyan
} else {
    Write-Host "  Mode: STANDARD (will logout after deploy)" -ForegroundColor Yellow
}

Write-Host "[1/4] Ensuring PLC runtime service is running..." -ForegroundColor Yellow
$svc = Get-Service -Name "CODESYS Control Win V3 - x64" -ErrorAction SilentlyContinue
if ($svc.Status -ne "Running") {
    Start-Service -Name "CODESYS Control Win V3 - x64"
    Start-Sleep -Seconds 5
    Write-Host "  PLC runtime started." -ForegroundColor Green
} else {
    Write-Host "  PLC runtime already running." -ForegroundColor Green
}

$gw = Get-Service -Name "CODESYS Gateway V3" -ErrorAction SilentlyContinue
if ($gw.Status -ne "Running") {
    Start-Service -Name "CODESYS Gateway V3"
    Start-Sleep -Seconds 3
    Write-Host "  Gateway started." -ForegroundColor Green
} else {
    Write-Host "  Gateway already running." -ForegroundColor Green
}

Write-Host "[2/4] Closing existing CODESYS instances..." -ForegroundColor Yellow
Get-Process -Name "CODESYS" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 3
Write-Host "  Done." -ForegroundColor Green

Write-Host "[3/4] Deploying project and collecting data..." -ForegroundColor Yellow
Write-Host "  Project: $ProjectPath"
Write-Host "  Script: $ScriptPath"

$proc = Start-Process -FilePath $CodesysExe -ArgumentList "--profile=`"$Profile`"", "--runscript=`"$ScriptPath`"" -PassThru -NoNewWindow

$dataFile = "D:\Codesys-MCP-main\Codesys-MCP-Test\web-monitor\backend\data\latest.json"
$statusFile = "D:\Codesys-MCP-main\Codesys-MCP-Test\web-monitor\backend\data\connection_status.json"
$timeout = 120
$elapsed = 0
while (-not (Test-Path $dataFile) -and $elapsed -lt $timeout) {
    Start-Sleep -Seconds 1
    $elapsed++
    if ($elapsed % 10 -eq 0) {
        Write-Host "  Waiting... ($elapsed/$timeout s)" -ForegroundColor DarkGray
    }
}

if (Test-Path $dataFile) {
    Write-Host "[4/4] Data collection complete!" -ForegroundColor Green
    $data = Get-Content $dataFile -Raw | ConvertFrom-Json
    if ($data.samples.Count -gt 0) {
        $last = $data.samples[-1].values
        Write-Host ""
        Write-Host "===== Latest Variable Values =====" -ForegroundColor Cyan
        Write-Host "  nAccumulator = $($last.'PLC_PRG.nAccumulator')" -ForegroundColor White
        Write-Host "  nCycleCount  = $($last.'PLC_PRG.nCycleCount')" -ForegroundColor White
        Write-Host "  bEnable      = $($last.'PLC_PRG.bEnable')" -ForegroundColor White
        Write-Host "  nStep        = $($last.'PLC_PRG.nStep')" -ForegroundColor White
        Write-Host "  nMaxValue    = $($last.'PLC_PRG.nMaxValue')" -ForegroundColor White
        
        if ($KeepConnection -and (Test-Path $statusFile)) {
            $status = Get-Content $statusFile -Raw | ConvertFrom-Json
            Write-Host ""
            Write-Host "===== Connection Status =====" -ForegroundColor Cyan
            Write-Host "  Status: $($status.status)" -ForegroundColor Green
            Write-Host "  App State: $($status.application_state)" -ForegroundColor White
            Write-Host "  Time: $($status.datetime)" -ForegroundColor White
        }
        
        Write-Host ""
        Write-Host "===== SUCCESS =====" -ForegroundColor Green
        Write-Host "Web monitor: http://localhost:3000" -ForegroundColor Cyan
        
        if ($KeepConnection) {
            Write-Host ""
            Write-Host "========================================" -ForegroundColor Green
            Write-Host " CONNECTION MAINTAINED" -ForegroundColor Green
            Write-Host " You can continue monitoring via:" -ForegroundColor White
            Write-Host "   - Web UI: http://localhost:3000" -ForegroundColor Cyan
            Write-Host "   - API: GET /api/connection-status" -ForegroundColor Cyan
            Write-Host "   - API: GET /api/variables/latest" -ForegroundColor Cyan
            Write-Host "========================================" -ForegroundColor Green
        }
    }
} else {
    Write-Host "[4/4] TIMEOUT: Data collection did not complete in $timeout seconds" -ForegroundColor Red
    exit 1
}
