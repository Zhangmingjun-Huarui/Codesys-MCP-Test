<#
.SYNOPSIS
Simple CODESYS Device Connection Test with Accumulator Project
#>

param(
    [string]$McpServerPath = "D:\Codesys-MCP-main\Codesys-MCP-main",
    [string]$ProjectPath = "D:\Codesys-MCP-main\Codesys-MCP-Test\projects\Accumulator_Rev1.0.0.260412.project"
)

Write-Host "CODESYS Device Connection Test with Accumulator Project"
Write-Host "================================================="
Write-Host "Project Path: $ProjectPath"
Write-Host ""

# 检查项目文件
if (-not (Test-Path $ProjectPath)) {
    Write-Host "Error: Project file not found" -ForegroundColor Red
    exit 1
}

# 切换到 MCP 服务器目录
Push-Location $McpServerPath

# Test 1: Device Scan
Write-Host "=== Test 1: Device Scan ==="
try {
    $inputJson = @{
        tool = "scan_devices"
        arguments = @{}
    } | ConvertTo-Json -Compress
    
    $output = $inputJson | node "dist\server.js" --mode headless 2>&1
    
    Write-Host "Scan Output:"
    Write-Host $output
    
    if ($output -match "SCRIPT_SUCCESS") {
        Write-Host "✓ Device scan successful" -ForegroundColor Green
    } else {
        Write-Host "✗ Device scan failed" -ForegroundColor Red
    }
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 2: Device Login
Write-Host "=== Test 2: Device Login ==="
try {
    $inputJson = @{
        tool = "connect_to_device"
        arguments = @{
            projectFilePath = $ProjectPath
        }
    } | ConvertTo-Json -Compress
    
    $output = $inputJson | node "dist\server.js" --mode headless 2>&1
    
    Write-Host "Login Output:"
    Write-Host $output
    
    if ($output -match "SCRIPT_SUCCESS") {
        Write-Host "✓ Device login successful" -ForegroundColor Green
    } else {
        Write-Host "✗ Device login failed" -ForegroundColor Red
    }
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 3: Application State
Write-Host "=== Test 3: Application State ==="
try {
    $inputJson = @{
        tool = "get_application_state"
        arguments = @{
            projectFilePath = $ProjectPath
        }
    } | ConvertTo-Json -Compress
    
    $output = $inputJson | node "dist\server.js" --mode headless 2>&1
    
    Write-Host "State Output:"
    Write-Host $output
    
    if ($output -match "SCRIPT_SUCCESS") {
        Write-Host "✓ Application state check successful" -ForegroundColor Green
    } else {
        Write-Host "✗ Application state check failed" -ForegroundColor Red
    }
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 4: Read Variable
Write-Host "=== Test 4: Read Variable (PLC_PRG.nAccumulator) ==="
try {
    $inputJson = @{
        tool = "read_variable"
        arguments = @{
            projectFilePath = $ProjectPath
            variablePath = "PLC_PRG.nAccumulator"
        }
    } | ConvertTo-Json -Compress
    
    $output = $inputJson | node "dist\server.js" --mode headless 2>&1
    
    Write-Host "Read Output:"
    Write-Host $output
    
    if ($output -match "SCRIPT_SUCCESS") {
        Write-Host "✓ Variable read successful" -ForegroundColor Green
    } else {
        Write-Host "✗ Variable read failed" -ForegroundColor Red
    }
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 5: Write Variable
Write-Host "=== Test 5: Write Variable (PLC_PRG.bEnable = TRUE) ==="
try {
    $inputJson = @{
        tool = "write_variable"
        arguments = @{
            projectFilePath = $ProjectPath
            variablePath = "PLC_PRG.bEnable"
            value = "TRUE"
        }
    } | ConvertTo-Json -Compress
    
    $output = $inputJson | node "dist\server.js" --mode headless 2>&1
    
    Write-Host "Write Output:"
    Write-Host $output
    
    if ($output -match "SCRIPT_SUCCESS") {
        Write-Host "✓ Variable write successful" -ForegroundColor Green
    } else {
        Write-Host "✗ Variable write failed" -ForegroundColor Red
    }
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Test completed!"

Pop-Location
