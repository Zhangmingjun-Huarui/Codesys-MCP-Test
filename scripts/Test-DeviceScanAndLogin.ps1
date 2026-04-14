<#
.SYNOPSIS
CODESYS 设备扫描与登录测试脚本

.DESCRIPTION
此脚本用于测试 CODESYS MCP 的设备扫描和登录功能，验证解决方案的有效性。

.PARAMETER McpServerPath
MCP 服务器的路径

.PARAMETER ProjectPath
测试项目的路径

.PARAMETER TestCount
测试次数，默认为 5

.EXAMPLE
.est-DeviceScanAndLogin.ps1 -McpServerPath "D:\Codesys-MCP-main\Codesys-MCP-main" -ProjectPath "D:\Codesys-MCP-Test\TestProject_WAVE\TestProject_WAVE.project"

.NOTES
Author: TRAE AI
Date: 2026-04-13
#>

param(
    [string]$McpServerPath = "D:\Codesys-MCP-main\Codesys-MCP-main",
    [string]$ProjectPath = "D:\Codesys-MCP-Test\TestProject_WAVE\TestProject_WAVE.project",
    [int]$TestCount = 5
)

# 导入必要的模块
Import-Module -Name Microsoft.PowerShell.Utility

# 全局变量
$TestResults = @()
$TotalTests = $TestCount
$PassedTests = 0
$FailedTests = 0
$TotalScanTime = 0
$TotalLoginTime = 0

# 函数：执行 MCP 工具
function Invoke-McpTool {
    param(
        [string]$ToolName,
        [hashtable]$Parameters = @{}
    )
    
    $startTime = Get-Date
    
    try {
        # 构建命令
        $cmd = "node" 
        $args = @("dist\server.js", "--mode", "headless")
        
        # 构建 JSON 输入
        $inputJson = @{
            tool = $ToolName
            arguments = $Parameters
        } | ConvertTo-Json -Compress
        
        # 执行命令
        $output = $inputJson | & $cmd $args 2>&1
        
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalSeconds
        
        # 解析输出
        $result = @{
            Success = $false
            Output = $output -join "`n"
            Duration = $duration
            Error = $null
        }
        
        # 检查是否成功
        if ($result.Output -match "SCRIPT_SUCCESS") {
            $result.Success = $true
        }
        
        return $result
    } catch {
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalSeconds
        
        return @{
            Success = $false
            Output = $_.Exception.Message
            Duration = $duration
            Error = $_.Exception
        }
    }
}

# 函数：测试设备扫描
function Test-DeviceScan {
    Write-Host "=== Test Device Scan ===" -ForegroundColor Cyan
    
    $result = Invoke-McpTool -ToolName "scan_devices"
    
    Write-Host "Scan result:"
    Write-Host $result.Output
    Write-Host "Scan time: $($result.Duration.ToString('F2')) seconds"
    
    # 检查是否成功
    if ($result.Success) {
        Write-Host "✓ Device scan successful" -ForegroundColor Green
        return @{
            Success = $true
            Duration = $result.Duration
            Details = $result.Output
        }
    } else {
        Write-Host "✗ Device scan failed" -ForegroundColor Red
        return @{
            Success = $false
            Duration = $result.Duration
            Details = $result.Output
            Error = $result.Error
        }
    }
}

# 函数：测试设备登录
function Test-DeviceLogin {
    param(
        [string]$ProjectPath
    )
    
    Write-Host "=== Test Device Login ===" -ForegroundColor Cyan
    
    $result = Invoke-McpTool -ToolName "connect_to_device" -Parameters @{
        projectFilePath = $ProjectPath
    }
    
    Write-Host "Login result:"
    Write-Host $result.Output
    Write-Host "Login time: $($result.Duration.ToString('F2')) seconds"
    
    # 检查是否成功
    if ($result.Success) {
        Write-Host "✓ Device login successful" -ForegroundColor Green
        return @{
            Success = $true
            Duration = $result.Duration
            Details = $result.Output
        }
    } else {
        Write-Host "✗ Device login failed" -ForegroundColor Red
        return @{
            Success = $false
            Duration = $result.Duration
            Details = $result.Output
            Error = $result.Error
        }
    }
}

# 函数：测试完整流程
function Test-FullFlow {
    param(
        [string]$ProjectPath,
        [int]$TestNumber
    )
    
    Write-Host "`n=== Test $TestNumber/$TotalTests: Full Flow ===" -ForegroundColor Yellow
    
    # 测试设备扫描
    $scanResult = Test-DeviceScan
    
    # 测试设备登录
    $loginResult = Test-DeviceLogin -ProjectPath $ProjectPath
    
    # 记录结果
    $testResult = @{
        TestNumber = $TestNumber
        Timestamp = Get-Date
        ScanResult = $scanResult
        LoginResult = $loginResult
        FullSuccess = $scanResult.Success -and $loginResult.Success
    }
    
    $TestResults += $testResult
    
    # 更新统计
    if ($testResult.FullSuccess) {
        $global:PassedTests++
    } else {
        $global:FailedTests++
    }
    
    $global:TotalScanTime += $scanResult.Duration
    $global:TotalLoginTime += $loginResult.Duration
    
    return $testResult
}

# 函数：生成测试报告
function Generate-TestReport {
    param(
        [array]$Results
    )
    
    Write-Host "`n=== Test Report ===" -ForegroundColor Green
    Write-Host "Total tests: $TotalTests"
    Write-Host "Passed tests: $PassedTests"
    Write-Host "Failed tests: $FailedTests"
    Write-Host "Success rate: $([Math]::Round(($PassedTests / $TotalTests) * 100, 2))%"
    
    if ($TotalTests -gt 0) {
        $avgScanTime = $TotalScanTime / $TotalTests
        $avgLoginTime = $TotalLoginTime / $TotalTests
        Write-Host "Average scan time: $($avgScanTime.ToString('F2')) seconds"
        Write-Host "Average login time: $($avgLoginTime.ToString('F2')) seconds"
    }
    
    # 详细结果
    Write-Host "`nDetailed results:"
    foreach ($result in $Results) {
        $status = if ($result.FullSuccess) { "✓ Success" } else { "✗ Failed" }
        Write-Host "Test $($result.TestNumber): $status"
        Write-Host "  Scan: $($result.ScanResult.Success.ToString().ToUpper()) ($($result.ScanResult.Duration.ToString('F2'))s)"
        Write-Host "  Login: $($result.LoginResult.Success.ToString().ToUpper()) ($($result.LoginResult.Duration.ToString('F2'))s)"
    }
    
    # 生成 JSON 报告
    $report = @{
        TestDate = Get-Date
        TotalTests = $TotalTests
        PassedTests = $PassedTests
        FailedTests = $FailedTests
        SuccessRate = if ($TotalTests -gt 0) { [Math]::Round(($PassedTests / $TotalTests) * 100, 2) } else { 0 }
        AverageScanTime = if ($TotalTests -gt 0) { $TotalScanTime / $TotalTests } else { 0 }
        AverageLoginTime = if ($TotalTests -gt 0) { $TotalLoginTime / $TotalTests } else { 0 }
        DetailedResults = $Results
    }
    
    $reportPath = "TestReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    $report | ConvertTo-Json -Depth 5 | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Host "`nTest report saved to: $reportPath"
    
    return $report
}

# 主函数
function Main {
    Write-Host "CODESYS Device Scan and Login Test"
    Write-Host "=================================="
    Write-Host "MCP Server Path: $McpServerPath"
    Write-Host "Test Project Path: $ProjectPath"
    Write-Host "Test Count: $TestCount"
    Write-Host ""
    
    # 切换到 MCP 服务器目录
    Push-Location $McpServerPath
    
    try {
        # 执行测试
        for ($i = 1; $i -le $TestCount; $i++) {
            Test-FullFlow -ProjectPath $ProjectPath -TestNumber $i
            
            # 测试间隔
            if ($i -lt $TestCount) {
                Write-Host "`nWaiting 2 seconds before next test..."
                Start-Sleep -Seconds 2
            }
        }
        
        # 生成报告
        Generate-TestReport -Results $TestResults
        
        # 验证成功率
        if ($PassedTests -ge ($TotalTests * 0.95)) {
            Write-Host "`n✓ Test passed: Success rate达到 95% 以上" -ForegroundColor Green
            return 0
        } else {
            Write-Host "`n✗ Test failed: Success rate未达到 95%" -ForegroundColor Red
            return 1
        }
    } catch {
        Write-Host "`n✗ Test execution failed: $($_.Exception.Message)" -ForegroundColor Red
        return 1
    } finally {
        Pop-Location
    }
}

# 执行主函数
Main
