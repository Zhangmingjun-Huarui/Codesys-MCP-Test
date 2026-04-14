<#
.SYNOPSIS
CODESYS Device Connection Test with Accumulator Project

.DESCRIPTION
Tests actual device connection using the Accumulator project from the projects directory
#>

param(
    [string]$McpServerPath = "D:\Codesys-MCP-main\Codesys-MCP-main",
    [string]$ProjectPath = "D:\Codesys-MCP-main\Codesys-MCP-Test\projects\Accumulator_Rev1.0.0.260412.project",
    [int]$TestCount = 3
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
$TotalOperationTime = 0

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

# 函数：测试变量读取
function Test-ReadVariable {
    param(
        [string]$ProjectPath,
        [string]$VariablePath
    )
    
    Write-Host "=== Test Read Variable: $VariablePath ===" -ForegroundColor Cyan
    
    $result = Invoke-McpTool -ToolName "read_variable" -Parameters @{
        projectFilePath = $ProjectPath
        variablePath = $VariablePath
    }
    
    Write-Host "Read result:"
    Write-Host $result.Output
    Write-Host "Read time: $($result.Duration.ToString('F2')) seconds"
    
    # 检查是否成功
    if ($result.Success) {
        Write-Host "✓ Variable read successful" -ForegroundColor Green
        return @{
            Success = $true
            Duration = $result.Duration
            Details = $result.Output
        }
    } else {
        Write-Host "✗ Variable read failed" -ForegroundColor Red
        return @{
            Success = $false
            Duration = $result.Duration
            Details = $result.Output
            Error = $result.Error
        }
    }
}

# 函数：测试变量写入
function Test-WriteVariable {
    param(
        [string]$ProjectPath,
        [string]$VariablePath,
        [string]$Value
    )
    
    Write-Host "=== Test Write Variable: $VariablePath = $Value ===" -ForegroundColor Cyan
    
    $result = Invoke-McpTool -ToolName "write_variable" -Parameters @{
        projectFilePath = $ProjectPath
        variablePath = $VariablePath
        value = $Value
    }
    
    Write-Host "Write result:"
    Write-Host $result.Output
    Write-Host "Write time: $($result.Duration.ToString('F2')) seconds"
    
    # 检查是否成功
    if ($result.Success) {
        Write-Host "✓ Variable write successful" -ForegroundColor Green
        return @{
            Success = $true
            Duration = $result.Duration
            Details = $result.Output
        }
    } else {
        Write-Host "✗ Variable write failed" -ForegroundColor Red
        return @{
            Success = $false
            Duration = $result.Duration
            Details = $result.Output
            Error = $result.Error
        }
    }
}

# 函数：测试应用状态
function Test-ApplicationState {
    param(
        [string]$ProjectPath
    )
    
    Write-Host "=== Test Application State ===" -ForegroundColor Cyan
    
    $result = Invoke-McpTool -ToolName "get_application_state" -Parameters @{
        projectFilePath = $ProjectPath
    }
    
    Write-Host "State result:"
    Write-Host $result.Output
    Write-Host "State check time: $($result.Duration.ToString('F2')) seconds"
    
    # 检查是否成功
    if ($result.Success) {
        Write-Host "✓ Application state check successful" -ForegroundColor Green
        return @{
            Success = $true
            Duration = $result.Duration
            Details = $result.Output
        }
    } else {
        Write-Host "✗ Application state check failed" -ForegroundColor Red
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
    
    # 测试应用状态
    $stateResult = $null
    if ($loginResult.Success) {
        $stateResult = Test-ApplicationState -ProjectPath $ProjectPath
    }
    
    # 测试变量读取
    $readResult = $null
    if ($loginResult.Success) {
        $readResult = Test-ReadVariable -ProjectPath $ProjectPath -VariablePath "PLC_PRG.nAccumulator"
    }
    
    # 测试变量写入
    $writeResult = $null
    if ($loginResult.Success) {
        $writeResult = Test-WriteVariable -ProjectPath $ProjectPath -VariablePath "PLC_PRG.bEnable" -Value "TRUE"
    }
    
    # 记录结果
    $testResult = @{
        TestNumber = $TestNumber
        Timestamp = Get-Date
        ScanResult = $scanResult
        LoginResult = $loginResult
        StateResult = $stateResult
        ReadResult = $readResult
        WriteResult = $writeResult
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
    if ($stateResult) { $global:TotalOperationTime += $stateResult.Duration }
    if ($readResult) { $global:TotalOperationTime += $readResult.Duration }
    if ($writeResult) { $global:TotalOperationTime += $writeResult.Duration }
    
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
        $avgOperationTime = $TotalOperationTime / $TotalTests
        Write-Host "Average scan time: $($avgScanTime.ToString('F2')) seconds"
        Write-Host "Average login time: $($avgLoginTime.ToString('F2')) seconds"
        Write-Host "Average operation time: $($avgOperationTime.ToString('F2')) seconds"
    }
    
    # 详细结果
    Write-Host "`nDetailed results:"
    foreach ($result in $Results) {
        $status = if ($result.FullSuccess) { "✓ Success" } else { "✗ Failed" }
        Write-Host "Test $($result.TestNumber): $status"
        Write-Host "  Scan: $($result.ScanResult.Success.ToString().ToUpper()) ($($result.ScanResult.Duration.ToString('F2'))s)"
        Write-Host "  Login: $($result.LoginResult.Success.ToString().ToUpper()) ($($result.LoginResult.Duration.ToString('F2'))s)"
        if ($result.StateResult) {
            Write-Host "  State: $($result.StateResult.Success.ToString().ToUpper()) ($($result.StateResult.Duration.ToString('F2'))s)"
        }
        if ($result.ReadResult) {
            Write-Host "  Read: $($result.ReadResult.Success.ToString().ToUpper()) ($($result.ReadResult.Duration.ToString('F2'))s)"
        }
        if ($result.WriteResult) {
            Write-Host "  Write: $($result.WriteResult.Success.ToString().ToUpper()) ($($result.WriteResult.Duration.ToString('F2'))s)"
        }
    }
    
    # 生成 JSON 报告
    $report = @{
        TestDate = Get-Date
        TestEnvironment = @{
            McpServerPath = $McpServerPath
            ProjectPath = $ProjectPath
            TestCount = $TestCount
        }
        TestResults = @{
            TotalTests = $TotalTests
            PassedTests = $PassedTests
            FailedTests = $FailedTests
            SuccessRate = if ($TotalTests -gt 0) { [Math]::Round(($PassedTests / $TotalTests) * 100, 2) } else { 0 }
            AverageScanTime = if ($TotalTests -gt 0) { $TotalScanTime / $TotalTests } else { 0 }
            AverageLoginTime = if ($TotalTests -gt 0) { $TotalLoginTime / $TotalTests } else { 0 }
            AverageOperationTime = if ($TotalTests -gt 0) { $TotalOperationTime / $TotalTests } else { 0 }
        }
        DetailedResults = $Results
    }
    
    $reportPath = "AccumulatorConnectionTestReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    $report | ConvertTo-Json -Depth 5 | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Host "`nTest report saved to: $reportPath"
    
    # 生成 HTML 报告
    $htmlReport = Generate-HtmlReport -Report $report
    $htmlPath = "AccumulatorConnectionTestReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
    $htmlReport | Out-File -FilePath $htmlPath -Encoding UTF8
    Write-Host "HTML report saved to: $htmlPath"
    
    return $report
}

# 函数：生成 HTML 报告
function Generate-HtmlReport {
    param(
        [hashtable]$Report
    )
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>CODESYS Device Connection Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }
        h2 { color: #555; }
        table { border-collapse: collapse; width: 100%; margin: 20px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .success { color: green; }
        .failure { color: red; }
        .info { background-color: #f9f9f9; padding: 10px; margin: 10px 0; }
    </style>
</head>
<body>
    <h1>CODESYS Device Connection Test Report</h1>
    <div class="info">
        <p><strong>Test Date:</strong> $($Report.TestDate)</p>
        <p><strong>MCP Server Path:</strong> $($Report.TestEnvironment.McpServerPath)</p>
        <p><strong>Project Path:</strong> $($Report.TestEnvironment.ProjectPath)</p>
        <p><strong>Test Count:</strong> $($Report.TestEnvironment.TestCount)</p>
    </div>
    
    <h2>Test Results Summary</h2>
    <table>
        <tr>
            <th>Total Tests</th>
            <th>Passed Tests</th>
            <th>Failed Tests</th>
            <th>Success Rate</th>
            <th>Avg Scan Time (s)</th>
            <th>Avg Login Time (s)</th>
            <th>Avg Operation Time (s)</th>
        </tr>
        <tr>
            <td>$($Report.TestResults.TotalTests)</td>
            <td class="success">$($Report.TestResults.PassedTests)</td>
            <td class="failure">$($Report.TestResults.FailedTests)</td>
            <td>$($Report.TestResults.SuccessRate)%</td>
            <td>$($Report.TestResults.AverageScanTime.ToString('F2'))</td>
            <td>$($Report.TestResults.AverageLoginTime.ToString('F2'))</td>
            <td>$($Report.TestResults.AverageOperationTime.ToString('F2'))</td>
        </tr>
    </table>
    
    <h2>Detailed Results</h2>
    $(foreach ($result in $Report.DetailedResults) {
        $statusClass = if ($result.FullSuccess) { "success" } else { "failure" }
        $statusText = if ($result.FullSuccess) { "Success" } else { "Failed" }
        @"
    <h3>Test $($result.TestNumber): <span class="$statusClass">$statusText</span></h3>
    <table>
        <tr>
            <th>Operation</th>
            <th>Status</th>
            <th>Duration (s)</th>
        </tr>
        <tr>
            <td>Device Scan</td>
            <td class="$($result.ScanResult.Success ? 'success' : 'failure')">$($result.ScanResult.Success.ToString().ToUpper())</td>
            <td>$($result.ScanResult.Duration.ToString('F2'))</td>
        </tr>
        <tr>
            <td>Device Login</td>
            <td class="$($result.LoginResult.Success ? 'success' : 'failure')">$($result.LoginResult.Success.ToString().ToUpper())</td>
            <td>$($result.LoginResult.Duration.ToString('F2'))</td>
        </tr>
        $(if ($result.StateResult) {
            @"
        <tr>
            <td>Application State</td>
            <td class="$($result.StateResult.Success ? 'success' : 'failure')">$($result.StateResult.Success.ToString().ToUpper())</td>
            <td>$($result.StateResult.Duration.ToString('F2'))</td>
        </tr>
            "@
        })
        $(if ($result.ReadResult) {
            @"
        <tr>
            <td>Variable Read</td>
            <td class="$($result.ReadResult.Success ? 'success' : 'failure')">$($result.ReadResult.Success.ToString().ToUpper())</td>
            <td>$($result.ReadResult.Duration.ToString('F2'))</td>
        </tr>
            "@
        })
        $(if ($result.WriteResult) {
            @"
        <tr>
            <td>Variable Write</td>
            <td class="$($result.WriteResult.Success ? 'success' : 'failure')">$($result.WriteResult.Success.ToString().ToUpper())</td>
            <td>$($result.WriteResult.Duration.ToString('F2'))</td>
        </tr>
            "@
        })
    </table>
    "@
    })
</body>
</html>
"@
    
    return $html
}

# 主函数
function Main {
    Write-Host "CODESYS Device Connection Test with Accumulator Project"
    Write-Host "================================================="
    Write-Host "MCP Server Path: $McpServerPath"
    Write-Host "Project Path: $ProjectPath"
    Write-Host "Test Count: $TestCount"
    Write-Host ""
    
    # 检查项目文件是否存在
    if (-not (Test-Path $ProjectPath)) {
        Write-Host "Error: Project file not found: $ProjectPath" -ForegroundColor Red
        return 1
    }
    
    # 切换到 MCP 服务器目录
    Push-Location $McpServerPath
    
    try {
        # 执行测试
        for ($i = 1; $i -le $TestCount; $i++) {
            Test-FullFlow -ProjectPath $ProjectPath -TestNumber $i
            
            # 测试间隔
            if ($i -lt $TestCount) {
                Write-Host "`nWaiting 3 seconds before next test..."
                Start-Sleep -Seconds 3
            }
        }
        
        # 生成报告
        Generate-TestReport -Results $TestResults
        
        # 验证成功率
        if ($PassedTests -ge ($TotalTests * 0.9)) {
            Write-Host "`n✓ Test passed: Success rate达到 90% 以上" -ForegroundColor Green
            return 0
        } else {
            Write-Host "`n✗ Test failed: Success rate未达到 90%" -ForegroundColor Red
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
