<#
.SYNOPSIS
Simplified CODESYS Device Scan and Login Test

.DESCRIPTION
Tests CODESYS MCP device scan and login functionality
#>

param(
    [string]$McpServerPath = "D:\Codesys-MCP-main\Codesys-MCP-main",
    [string]$ProjectPath = "D:\Codesys-MCP-Test\TestProject_WAVE\TestProject_WAVE.project"
)

Write-Host "CODESYS Device Scan and Login Test"
Write-Host "=================================="

# Test 1: Device Scan
Write-Host "\n=== Test 1: Device Scan ==="
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

# Test 2: Device Login
Write-Host "\n=== Test 2: Device Login ==="
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

Write-Host "\nTest completed!"
