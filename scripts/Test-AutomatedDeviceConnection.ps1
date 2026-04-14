<#
.SYNOPSIS
Automated CODESYS Device Connection Test

.DESCRIPTION
Automatically tests the complete CODESYS device connection workflow including device scan, login, status check, and variable operations.
#>

param(
    [string]$McpServerPath = "D:\Codesys-MCP-main\Codesys-MCP-main",
    [string]$ProjectPath = "D:\Codesys-MCP-main\Codesys-MCP-Test\projects\Accumulator_Rev1.0.0.260412.project",
    [int]$TestCount = 1
)

Write-Host "Automated CODESYS Device Connection Test"
Write-Host "====================================="
Write-Host "MCP Server Path: $McpServerPath"
Write-Host "Project Path: $ProjectPath"
Write-Host "Test Count: $TestCount"
Write-Host ""

# 检查 CODESYS 服务状态
Write-Host "=== Checking CODESYS Services ==="
try {
    $services = Get-Service -Name "CODESYS*" | Select-Object Name, Status
    $services | ForEach-Object {
        $statusColor = if ($_.Status -eq "Running") { "Green" } else { "Red" }
        Write-Host "  $($_.Name): $($_.Status)" -ForegroundColor $statusColor
    }
    
    # 确保必要的服务正在运行
    $controlService = Get-Service -Name "CODESYS Control Win V3 - x64"
    if ($controlService.Status -ne "Running") {
        Write-Host "Starting CODESYS Control Win V3 - x64 service..." -ForegroundColor Yellow
        Start-Service -Name "CODESYS Control Win V3 - x64"
        Start-Sleep -Seconds 5
    }
    
    $gatewayService = Get-Service -Name "CODESYS Gateway V3"
    if ($gatewayService.Status -ne "Running") {
        Write-Host "Starting CODESYS Gateway V3 service..." -ForegroundColor Yellow
        Start-Service -Name "CODESYS Gateway V3"
        Start-Sleep -Seconds 5
    }
    
} catch {
    Write-Host "Error checking CODESYS services: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# 构建 MCP 服务器
Write-Host "=== Building MCP Server ==="
try {
    Push-Location $McpServerPath
    $buildResult = npm run build 2>&1
    Write-Host "Build result:"
    Write-Host $buildResult
    
    if ($buildResult -match "error") {
        Write-Host "Build failed!" -ForegroundColor Red
        Pop-Location
        exit 1
    } else {
        Write-Host "Build successful!" -ForegroundColor Green
    }
} catch {
    Write-Host "Error building MCP server: $($_.Exception.Message)" -ForegroundColor Red
    Pop-Location
    exit 1
} finally {
    Pop-Location
}

Write-Host ""

# 函数：执行 MCP 命令
function Invoke-McpCommand {
    param(
        [string]$Command
    )
    
    try {
        Push-Location $McpServerPath
        
        # 构建命令
        $inputJson = $Command | ConvertTo-Json -Compress
        
        # 执行命令
        $output = $inputJson | node "dist/server.js" --mode headless 2>&1
        
        return @{
            Success = $output -match "SCRIPT_SUCCESS"
            Output = $output -join "`n"
        }
    } catch {
        return @{
            Success = $false
            Output = $_.Exception.Message
        }
    } finally {
        Pop-Location
    }
}

# 函数：测试设备扫描
function Test-DeviceScan {
    Write-Host "=== Test 1: Device Scan ==="
    
    $command = @{
        tool = "scan_devices"
        arguments = @{}
    }
    
    $result = Invoke-McpCommand -Command $command
    
    Write-Host "Scan Output:"
    Write-Host $result.Output
    
    if ($result.Success) {
        Write-Host "✓ Device scan successful" -ForegroundColor Green
        return $true
    } else {
        Write-Host "✗ Device scan failed" -ForegroundColor Red
        return $false
    }
}

# 函数：测试设备登录
function Test-DeviceLogin {
    param(
        [string]$ProjectPath
    )
    
    Write-Host "=== Test 2: Device Login ==="
    
    $command = @{
        tool = "connect_to_device"
        arguments = @{
            projectFilePath = $ProjectPath
        }
    }
    
    $result = Invoke-McpCommand -Command $command
    
    Write-Host "Login Output:"
    Write-Host $result.Output
    
    if ($result.Success) {
        Write-Host "✓ Device login successful" -ForegroundColor Green
        return $true
    } else {
        Write-Host "✗ Device login failed" -ForegroundColor Red
        return $false
    }
}

# 函数：测试应用状态
function Test-ApplicationState {
    param(
        [string]$ProjectPath
    )
    
    Write-Host "=== Test 3: Application State ==="
    
    $command = @{
        tool = "get_application_state"
        arguments = @{
            projectFilePath = $ProjectPath
        }
    }
    
    $result = Invoke-McpCommand -Command $command
    
    Write-Host "State Output:"
    Write-Host $result.Output
    
    if ($result.Success) {
        Write-Host "✓ Application state check successful" -ForegroundColor Green
        return $true
    } else {
        Write-Host "✗ Application state check failed" -ForegroundColor Red
        return $false
    }
}

# 函数：测试变量读取
function Test-ReadVariable {
    param(
        [string]$ProjectPath,
        [string]$VariablePath
    )
    
    Write-Host "=== Test 4: Read Variable ($VariablePath) ==="
    
    $command = @{
        tool = "read_variable"
        arguments = @{
            projectFilePath = $ProjectPath
            variablePath = $VariablePath
        }
    }
    
    $result = Invoke-McpCommand -Command $command
    
    Write-Host "Read Output:"
    Write-Host $result.Output
    
    if ($result.Success) {
        Write-Host "✓ Variable read successful" -ForegroundColor Green
        return $true
    } else {
        Write-Host "✗ Variable read failed" -ForegroundColor Red
        return $false
    }
}

# 函数：测试变量写入
function Test-WriteVariable {
    param(
        [string]$ProjectPath,
        [string]$VariablePath,
        [string]$Value
    )
    
    Write-Host "=== Test 5: Write Variable ($VariablePath = $Value) ==="
    
    $command = @{
        tool = "write_variable"
        arguments = @{
            projectFilePath = $ProjectPath
            variablePath = $VariablePath
            value = $Value
        }
    }
    
    $result = Invoke-McpCommand -Command $command
    
    Write-Host "Write Output:"
    Write-Host $result.Output
    
    if ($result.Success) {
        Write-Host "✓ Variable write successful" -ForegroundColor Green
        return $true
    } else {
        Write-Host "✗ Variable write failed" -ForegroundColor Red
        return $false
    }
}

# 执行测试
$testResults = @()
$totalPassed = 0
$totalFailed = 0

for ($i = 1; $i -le $TestCount; $i++) {
    Write-Host "`n=== Test Run $i/$TestCount ===" -ForegroundColor Yellow
    
    $runResult = @{
        TestRun = $i
        Timestamp = Get-Date
        Results = @{}
        OverallSuccess = $true
    }
    
    # 测试设备扫描
    $runResult.Results.Scan = Test-DeviceScan
    if (-not $runResult.Results.Scan) {
        $runResult.OverallSuccess = $false
    }
    
    # 测试设备登录
    $runResult.Results.Login = Test-DeviceLogin -ProjectPath $ProjectPath
    if (-not $runResult.Results.Login) {
        $runResult.OverallSuccess = $false
    }
    
    # 测试应用状态
    if ($runResult.Results.Login) {
        $runResult.Results.State = Test-ApplicationState -ProjectPath $ProjectPath
        if (-not $runResult.Results.State) {
            $runResult.OverallSuccess = $false
        }
    } else {
        $runResult.Results.State = $false
    }
    
    # 测试变量读取
    if ($runResult.Results.Login) {
        $runResult.Results.Read = Test-ReadVariable -ProjectPath $ProjectPath -VariablePath "PLC_PRG.nAccumulator"
        if (-not $runResult.Results.Read) {
            $runResult.OverallSuccess = $false
        }
    } else {
        $runResult.Results.Read = $false
    }
    
    # 测试变量写入
    if ($runResult.Results.Login) {
        $runResult.Results.Write = Test-WriteVariable -ProjectPath $ProjectPath -VariablePath "PLC_PRG.bEnable" -Value "TRUE"
        if (-not $runResult.Results.Write) {
            $runResult.OverallSuccess = $false
        }
    } else {
        $runResult.Results.Write = $false
    }
    
    $testResults += $runResult
    
    if ($runResult.OverallSuccess) {
        $totalPassed++
    } else {
        $totalFailed++
    }
    
    # 测试间隔
    if ($i -lt $TestCount) {
        Write-Host "`nWaiting 5 seconds before next test run..."
        Start-Sleep -Seconds 5
    }
}

# 生成测试报告
Write-Host "`n=== Test Report ===" -ForegroundColor Green
Write-Host "Total test runs: $TestCount"
Write-Host "Passed: $totalPassed"
Write-Host "Failed: $totalFailed"
Write-Host "Success rate: $([Math]::Round(($totalPassed / $TestCount) * 100, 2))%"

# 详细结果
Write-Host "`nDetailed results:"
foreach ($result in $testResults) {
    $status = if ($result.OverallSuccess) { "✓ Success" } else { "✗ Failed" }
    $statusColor = if ($result.OverallSuccess) { "Green" } else { "Red" }
    Write-Host "Test Run $($result.TestRun): $status" -ForegroundColor $statusColor
    Write-Host "  Scan: $($result.Results.Scan.ToString().ToUpper())"
    Write-Host "  Login: $($result.Results.Login.ToString().ToUpper())"
    Write-Host "  State: $($result.Results.State.ToString().ToUpper())"
    Write-Host "  Read: $($result.Results.Read.ToString().ToUpper())"
    Write-Host "  Write: $($result.Results.Write.ToString().ToUpper())"
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
        TotalTests = $TestCount
        PassedTests = $totalPassed
        FailedTests = $totalFailed
        SuccessRate = if ($TestCount -gt 0) { [Math]::Round(($totalPassed / $TestCount) * 100, 2) } else { 0 }
    }
    DetailedResults = $testResults
}

$reportPath = "AutomatedTestReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
$report | ConvertTo-Json -Depth 5 | Out-File -FilePath $reportPath -Encoding UTF8
Write-Host "`nTest report saved to: $reportPath"

# 验证结果
if ($totalPassed -ge ($TestCount * 0.8)) {
    Write-Host "`n✓ Automated test completed successfully!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n✗ Automated test failed!" -ForegroundColor Red
    exit 1
}
