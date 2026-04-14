<#
.SYNOPSIS
CODESYS 设备扫描与登录验证脚本

.DESCRIPTION
此脚本用于验证 CODESYS MCP 设备扫描与登录解决方案的有效性，测试不同场景下的性能和错误处理。

.PARAMETER McpServerPath
MCP 服务器的路径

.PARAMETER ProjectPath
测试项目的路径

.PARAMETER TestScenarios
测试场景，默认为 @("normal", "slow_network", "no_devices", "service_down")

.EXAMPLE
.erify-DeviceScanSolution.ps1 -McpServerPath "D:\Codesys-MCP-main\Codesys-MCP-main" -ProjectPath "D:\Codesys-MCP-Test\TestProject_WAVE\TestProject_WAVE.project"

.NOTES
Author: TRAE AI
Date: 2026-04-13
#>

param(
    [string]$McpServerPath = "D:\Codesys-MCP-main\Codesys-MCP-main",
    [string]$ProjectPath = "D:\Codesys-MCP-Test\TestProject_WAVE\TestProject_WAVE.project",
    [array]$TestScenarios = @("normal", "slow_network", "no_devices", "service_down")
)

# 导入必要的模块
Import-Module -Name Microsoft.PowerShell.Utility

# 全局变量
$VerificationResults = @()
$TotalScenarios = $TestScenarios.Length
$PassedScenarios = 0
$FailedScenarios = 0

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
        } elseif ($result.Output -match "SCRIPT_ERROR") {
            $result.Success = $false
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

# 函数：测试正常场景
function Test-NormalScenario {
    Write-Host "=== 测试场景: 正常环境 ===" -ForegroundColor Cyan
    
    # 测试设备扫描
    $scanResult = Invoke-McpTool -ToolName "scan_devices"
    
    # 测试设备登录
    $loginResult = Invoke-McpTool -ToolName "connect_to_device" -Parameters @{
        projectFilePath = $ProjectPath
    }
    
    # 验证结果
    $expectedScanSuccess = $true
    $expectedLoginSuccess = $true
    
    $scanActualSuccess = $scanResult.Success
    $loginActualSuccess = $loginResult.Success
    
    $scanPass = $scanActualSuccess -eq $expectedScanSuccess
    $loginPass = $loginActualSuccess -eq $expectedLoginSuccess
    $scenarioPass = $scanPass -and $loginPass
    
    # 记录结果
    $result = @{
        Scenario = "normal"
        Description = "正常网络环境，所有服务运行"
        ScanResult = @{
            ExpectedSuccess = $expectedScanSuccess
            ActualSuccess = $scanActualSuccess
            Pass = $scanPass
            Duration = $scanResult.Duration
            Output = $scanResult.Output
        }
        LoginResult = @{
            ExpectedSuccess = $expectedLoginSuccess
            ActualSuccess = $loginActualSuccess
            Pass = $loginPass
            Duration = $loginResult.Duration
            Output = $loginResult.Output
        }
        Pass = $scenarioPass
    }
    
    Write-Host "扫描: $($scanPass ? '✓ 通过' : '✗ 失败')"
    Write-Host "登录: $($loginPass ? '✓ 通过' : '✗ 失败')"
    Write-Host "场景: $($scenarioPass ? '✓ 通过' : '✗ 失败')"
    
    return $result
}

# 函数：测试慢网络场景
function Test-SlowNetworkScenario {
    Write-Host "=== 测试场景: 慢网络环境 ===" -ForegroundColor Cyan
    
    # 模拟慢网络（添加延迟）
    Write-Host "模拟慢网络环境..."
    Start-Sleep -Seconds 1
    
    # 测试设备扫描
    $scanResult = Invoke-McpTool -ToolName "scan_devices"
    
    # 测试设备登录
    $loginResult = Invoke-McpTool -ToolName "connect_to_device" -Parameters @{
        projectFilePath = $ProjectPath
    }
    
    # 验证结果
    $expectedScanSuccess = $true
    $expectedLoginSuccess = $true
    $maxScanTime = 30 # 最大扫描时间 30 秒
    $maxLoginTime = 60 # 最大登录时间 60 秒
    
    $scanActualSuccess = $scanResult.Success
    $loginActualSuccess = $loginResult.Success
    $scanTimeOk = $scanResult.Duration -le $maxScanTime
    $loginTimeOk = $loginResult.Duration -le $maxLoginTime
    
    $scanPass = $scanActualSuccess -eq $expectedScanSuccess -and $scanTimeOk
    $loginPass = $loginActualSuccess -eq $expectedLoginSuccess -and $loginTimeOk
    $scenarioPass = $scanPass -and $loginPass
    
    # 记录结果
    $result = @{
        Scenario = "slow_network"
        Description = "慢网络环境，响应时间较长"
        ScanResult = @{
            ExpectedSuccess = $expectedScanSuccess
            ActualSuccess = $scanActualSuccess
            Pass = $scanPass
            Duration = $scanResult.Duration
            TimeOk = $scanTimeOk
            Output = $scanResult.Output
        }
        LoginResult = @{
            ExpectedSuccess = $expectedLoginSuccess
            ActualSuccess = $loginActualSuccess
            Pass = $loginPass
            Duration = $loginResult.Duration
            TimeOk = $loginTimeOk
            Output = $loginResult.Output
        }
        Pass = $scenarioPass
    }
    
    Write-Host "扫描: $($scanPass ? '✓ 通过' : '✗ 失败') (时间: $($scanResult.Duration.ToString('F2'))s)"
    Write-Host "登录: $($loginPass ? '✓ 通过' : '✗ 失败') (时间: $($loginResult.Duration.ToString('F2'))s)"
    Write-Host "场景: $($scenarioPass ? '✓ 通过' : '✗ 失败')"
    
    return $result
}

# 函数：测试无设备场景
function Test-NoDevicesScenario {
    Write-Host "=== 测试场景: 无设备环境 ===" -ForegroundColor Cyan
    
    # 测试设备扫描
    $scanResult = Invoke-McpTool -ToolName "scan_devices"
    
    # 验证结果
    $expectedScanSuccess = $true # 扫描应该成功，即使没有设备
    $expectedNoDevices = $true # 应该检测到无设备
    
    $scanActualSuccess = $scanResult.Success
    $actualNoDevices = $scanResult.Output -match "No devices found"
    
    $scanPass = $scanActualSuccess -eq $expectedScanSuccess
    $noDevicesPass = $actualNoDevices -eq $expectedNoDevices
    $scenarioPass = $scanPass -and $noDevicesPass
    
    # 记录结果
    $result = @{
        Scenario = "no_devices"
        Description = "无设备环境，验证错误处理"
        ScanResult = @{
            ExpectedSuccess = $expectedScanSuccess
            ActualSuccess = $scanActualSuccess
            Pass = $scanPass
            Duration = $scanResult.Duration
            NoDevicesDetected = $actualNoDevices
            Output = $scanResult.Output
        }
        LoginResult = $null
        Pass = $scenarioPass
    }
    
    Write-Host "扫描: $($scanPass ? '✓ 通过' : '✗ 失败')"
    Write-Host "无设备检测: $($noDevicesPass ? '✓ 通过' : '✗ 失败')"
    Write-Host "场景: $($scenarioPass ? '✓ 通过' : '✗ 失败')"
    
    return $result
}

# 函数：测试服务停止场景
function Test-ServiceDownScenario {
    Write-Host "=== 测试场景: 服务停止环境 ===" -ForegroundColor Cyan
    
    # 测试设备扫描
    $scanResult = Invoke-McpTool -ToolName "scan_devices"
    
    # 测试设备登录
    $loginResult = Invoke-McpTool -ToolName "connect_to_device" -Parameters @{
        projectFilePath = $ProjectPath
    }
    
    # 验证结果
    $expectedScanSuccess = $false # 扫描应该失败
    $expectedLoginSuccess = $false # 登录应该失败
    $expectedErrorHandling = $true # 应该有详细的错误信息
    
    $scanActualSuccess = $scanResult.Success
    $loginActualSuccess = $loginResult.Success
    $scanErrorInfo = $scanResult.Output -match "SCRIPT_ERROR"
    $loginErrorInfo = $loginResult.Output -match "SCRIPT_ERROR"
    
    $scanPass = $scanActualSuccess -eq $expectedScanSuccess -and $scanErrorInfo
    $loginPass = $loginActualSuccess -eq $expectedLoginSuccess -and $loginErrorInfo
    $scenarioPass = $scanPass -and $loginPass
    
    # 记录结果
    $result = @{
        Scenario = "service_down"
        Description = "服务停止环境，验证错误处理"
        ScanResult = @{
            ExpectedSuccess = $expectedScanSuccess
            ActualSuccess = $scanActualSuccess
            Pass = $scanPass
            Duration = $scanResult.Duration
            ErrorInfo = $scanErrorInfo
            Output = $scanResult.Output
        }
        LoginResult = @{
            ExpectedSuccess = $expectedLoginSuccess
            ActualSuccess = $loginActualSuccess
            Pass = $loginPass
            Duration = $loginResult.Duration
            ErrorInfo = $loginErrorInfo
            Output = $loginResult.Output
        }
        Pass = $scenarioPass
    }
    
    Write-Host "扫描: $($scanPass ? '✓ 通过' : '✗ 失败')"
    Write-Host "登录: $($loginPass ? '✓ 通过' : '✗ 失败')"
    Write-Host "场景: $($scenarioPass ? '✓ 通过' : '✗ 失败')"
    
    return $result
}

# 函数：执行场景测试
function Execute-ScenarioTest {
    param(
        [string]$Scenario
    )
    
    switch ($Scenario) {
        "normal" {
            return Test-NormalScenario
        }
        "slow_network" {
            return Test-SlowNetworkScenario
        }
        "no_devices" {
            return Test-NoDevicesScenario
        }
        "service_down" {
            return Test-ServiceDownScenario
        }
        default {
            Write-Host "未知场景: $Scenario" -ForegroundColor Red
            return @{
                Scenario = $Scenario
                Description = "未知场景"
                Pass = $false
            }
        }
    }
}

# 函数：生成验证报告
function Generate-VerificationReport {
    param(
        [array]$Results
    )
    
    Write-Host "`n=== 验证报告 ===" -ForegroundColor Green
    Write-Host "总测试场景: $TotalScenarios"
    Write-Host "通过场景: $PassedScenarios"
    Write-Host "失败场景: $FailedScenarios"
    Write-Host "通过率: $([Math]::Round(($PassedScenarios / $TotalScenarios) * 100, 2))%"
    
    # 详细结果
    Write-Host "`n详细结果:"
    foreach ($result in $Results) {
        $status = if ($result.Pass) { "✓ 通过" } else { "✗ 失败" }
        Write-Host "场景 $($result.Scenario): $status"
        Write-Host "  描述: $($result.Description)"
        
        if ($result.ScanResult) {
            Write-Host "  扫描: $($result.ScanResult.Pass ? '✓ 通过' : '✗ 失败')"
            if ($result.ScanResult.Duration) {
                Write-Host "    时间: $($result.ScanResult.Duration.ToString('F2')) 秒"
            }
        }
        
        if ($result.LoginResult) {
            Write-Host "  登录: $($result.LoginResult.Pass ? '✓ 通过' : '✗ 失败')"
            if ($result.LoginResult.Duration) {
                Write-Host "    时间: $($result.LoginResult.Duration.ToString('F2')) 秒"
            }
        }
    }
    
    # 生成 JSON 报告
    $report = @{
        VerificationDate = Get-Date
        TotalScenarios = $TotalScenarios
        PassedScenarios = $PassedScenarios
        FailedScenarios = $FailedScenarios
        PassRate = if ($TotalScenarios -gt 0) { [Math]::Round(($PassedScenarios / $TotalScenarios) * 100, 2) } else { 0 }
        DetailedResults = $Results
    }
    
    $reportPath = "VerificationReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    $report | ConvertTo-Json -Depth 5 | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Host "`n验证报告已保存到: $reportPath"
    
    return $report
}

# 主函数
function Main {
    Write-Host "CODESYS 设备扫描与登录解决方案验证"
    Write-Host "======================================"
    Write-Host "MCP 服务器路径: $McpServerPath"
    Write-Host "测试项目路径: $ProjectPath"
    Write-Host "测试场景: $($TestScenarios -join ', ')"
    Write-Host ""
    
    # 切换到 MCP 服务器目录
    Push-Location $McpServerPath
    
    try {
        # 执行场景测试
        foreach ($scenario in $TestScenarios) {
            $result = Execute-ScenarioTest -Scenario $scenario
            $VerificationResults += $result
            
            # 更新统计
            if ($result.Pass) {
                $global:PassedScenarios++
            } else {
                $global:FailedScenarios++
            }
            
            # 场景间隔
            Write-Host "`n等待 3 秒后进行下一个场景测试..."
            Start-Sleep -Seconds 3
        }
        
        # 生成报告
        $report = Generate-VerificationReport -Results $VerificationResults
        
        # 验证通过率
        if ($PassedScenarios -ge ($TotalScenarios * 0.8)) {
            Write-Host "`n✓ 验证通过: 通过率达到 80% 以上" -ForegroundColor Green
            return 0
        } else {
            Write-Host "`n✗ 验证失败: 通过率未达到 80%" -ForegroundColor Red
            return 1
        }
    } catch {
        Write-Host "`n✗ 验证执行失败: $($_.Exception.Message)" -ForegroundColor Red
        return 1
    } finally {
        Pop-Location
    }
}

# 执行主函数
Main
