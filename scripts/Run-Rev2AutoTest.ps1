param(
    [string]$ProjectPath = "D:\Codesys-MCP-main\Codesys-MCP-Test\Codesys_Test_Demo\Codesys_Test_Demo_Rev1.0.0.260414.project",
    [string]$CodesysExe = "C:\Program Files\CODESYS 3.5.19.50\CODESYS\Common\CODESYS.exe",
    [string]$Profile = "CODESYS V3.5 SP19 Patch 5",
    [string]$TestScript = "D:\Codesys-MCP-main\Codesys-MCP-Test\scripts\Run-Rev2AutoTest.py",
    [string]$ReportPath = "D:\Codesys-MCP-main\Codesys-MCP-Test\test-results\rev2-test-report.json"
)

$ErrorActionPreference = "Stop"
$startTime = Get-Date

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  CODESYS MCP Rev2.0.0 Automated Test Suite" -ForegroundColor Cyan
Write-Host "  Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[Phase 0] Pre-flight checks..." -ForegroundColor Yellow

if (-not (Test-Path $CodesysExe)) {
    Write-Host "  ERROR: CODESYS not found at: $CodesysExe" -ForegroundColor Red
    exit 1
}
Write-Host "  CODESYS IDE: OK" -ForegroundColor Green

if (-not (Test-Path $ProjectPath)) {
    Write-Host "  ERROR: Project not found at: $ProjectPath" -ForegroundColor Red
    exit 1
}
Write-Host "  Project file: OK" -ForegroundColor Green

if (-not (Test-Path $TestScript)) {
    Write-Host "  ERROR: Test script not found at: $TestScript" -ForegroundColor Red
    exit 1
}
Write-Host "  Test script: OK" -ForegroundColor Green

Write-Host ""
Write-Host "[Phase 1] Checking PLC services..." -ForegroundColor Yellow

$services = @("CODESYS Control Win V3 - x64", "CODESYS Gateway V3", "CODESYS ServiceControl")
$allRunning = $true
foreach ($svcName in $services) {
    $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
    if ($svc.Status -eq "Running") {
        Write-Host "  $svcName : Running" -ForegroundColor Green
    } else {
        Write-Host "  $svcName : NOT RUNNING - Starting..." -ForegroundColor Yellow
        try {
            Start-Service -Name $svcName -ErrorAction Stop
            Start-Sleep -Seconds 3
            Write-Host "  $svcName : Started" -ForegroundColor Green
        } catch {
            Write-Host "  $svcName : FAILED TO START - $_" -ForegroundColor Red
            $allRunning = $false
        }
    }
}

if (-not $allRunning) {
    Write-Host "  ERROR: Not all PLC services could be started" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[Phase 2] Closing existing CODESYS instances..." -ForegroundColor Yellow
$existing = Get-Process -Name "CODESYS" -ErrorAction SilentlyContinue
if ($existing) {
    $existing | Stop-Process -Force
    Start-Sleep -Seconds 3
    Write-Host "  Closed $($existing.Count) CODESYS process(es)" -ForegroundColor Green
} else {
    Write-Host "  No existing CODESYS processes" -ForegroundColor Green
}

Write-Host ""
Write-Host "[Phase 3] Running test script via --runscript..." -ForegroundColor Yellow
Write-Host "  Script: $TestScript" -ForegroundColor Gray
Write-Host "  Timeout: 180 seconds" -ForegroundColor Gray
Write-Host ""

$proc = Start-Process -FilePath $CodesysExe `
    -ArgumentList "--profile=`"$Profile`"", "--runscript=`"$TestScript`"" `
    -PassThru -NoNewWindow -RedirectStandardOutput "D:\Codesys-MCP-main\Codesys-MCP-Test\test-results\codesys-stdout.log" `
    -RedirectStandardError "D:\Codesys-MCP-main\Codesys-MCP-Test\test-results\codesys-stderr.log"

$timeout = 180
$elapsed = 0
$reportFound = $false

while (-not $proc.HasExited -and $elapsed -lt $timeout) {
    Start-Sleep -Seconds 1
    $elapsed++

    if ($elapsed % 15 -eq 0) {
        Write-Host "  Waiting... ($elapsed/$timeout s)" -ForegroundColor DarkGray
    }

    if ((Test-Path $ReportPath) -and -not $reportFound) {
        $reportFound = $true
        Write-Host "  Report file detected at ${elapsed}s" -ForegroundColor DarkGray
    }
}

if (-not $proc.HasExited) {
    Write-Host "  TIMEOUT: CODESYS did not finish in $timeout seconds" -ForegroundColor Red
    $proc | Stop-Process -Force
    exit 1
}

$exitCode = $proc.ExitCode
Write-Host "  CODESYS exited with code: $exitCode" -ForegroundColor $(if ($exitCode -eq 0) { "Green" } else { "Yellow" })
Write-Host ""

if (Test-Path "D:\Codesys-MCP-main\Codesys-MCP-Test\test-results\codesys-stdout.log") {
    Write-Host "[Phase 4] CODESYS output log:" -ForegroundColor Yellow
    $logContent = Get-Content "D:\Codesys-MCP-main\Codesys-MCP-Test\test-results\codesys-stdout.log" -ErrorAction SilentlyContinue
    if ($logContent) {
        $logContent | ForEach-Object { Write-Host "  $_" }
    }
    Write-Host ""
}

Write-Host "[Phase 5] Test Report" -ForegroundColor Yellow

if (Test-Path $ReportPath) {
    $report = Get-Content $ReportPath -Raw | ConvertFrom-Json
    $summary = $report.summary

    Write-Host ""
    Write-Host "  ============================================================" -ForegroundColor Cyan
    Write-Host "  REV2.0.0 TEST RESULTS" -ForegroundColor Cyan
    Write-Host "  ============================================================" -ForegroundColor Cyan
    Write-Host "  Version:   $($report.version)" -ForegroundColor White
    Write-Host "  Date:      $($report.date)" -ForegroundColor White
    Write-Host "  Project:   $($report.project)" -ForegroundColor White
    Write-Host "  Duration:  $($summary.duration_ms) ms" -ForegroundColor White
    Write-Host ""
    Write-Host "  Total:     $($summary.total)" -ForegroundColor White
    Write-Host "  Passed:    $($summary.passed)" -ForegroundColor Green
    Write-Host "  Failed:    $($summary.failed)" -ForegroundColor $(if ($summary.failed -gt 0) { "Red" } else { "Green" })
    Write-Host ""
    Write-Host "  --------------------------------------------------------------" -ForegroundColor Gray

    foreach ($r in $report.results) {
        $icon = if ($r.passed) { "[PASS]" } else { "[FAIL]" }
        $color = if ($r.passed) { "Green" } else { "Red" }
        Write-Host "  $icon $($r.name)" -ForegroundColor $color
        if ($r.detail) {
            Write-Host "         $($r.detail)" -ForegroundColor DarkGray
        }
    }

    Write-Host "  ============================================================" -ForegroundColor Cyan
    Write-Host ""

    $totalDuration = (Get-Date) - $startTime
    Write-Host "  Total wall time: $($totalDuration.TotalSeconds.ToString('F1')) seconds" -ForegroundColor White
    Write-Host "  Report file: $ReportPath" -ForegroundColor White
    Write-Host ""

    if ($summary.failed -eq 0) {
        Write-Host "  >>> ALL TESTS PASSED! <<<" -ForegroundColor Green
        Write-Host ""
        exit 0
    } else {
        Write-Host "  >>> $($summary.failed) TEST(S) FAILED <<<" -ForegroundColor Red
        Write-Host ""
        exit 1
    }
} else {
    Write-Host "  ERROR: Report file not found at: $ReportPath" -ForegroundColor Red
    Write-Host "  CODESYS may have crashed before completing tests." -ForegroundColor Red

    if (Test-Path "D:\Codesys-MCP-main\Codesys-MCP-Test\test-results\codesys-stderr.log") {
        Write-Host ""
        Write-Host "  Error log:" -ForegroundColor Yellow
        Get-Content "D:\Codesys-MCP-main\Codesys-MCP-Test\test-results\codesys-stderr.log" | ForEach-Object { Write-Host "  $_" }
    }
    exit 1
}
