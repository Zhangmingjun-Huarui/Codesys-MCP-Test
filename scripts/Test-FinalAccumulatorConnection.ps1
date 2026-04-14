Write-Host "CODESYS Device Connection Test with Accumulator Project"
Write-Host "================================================="

$projectPath = "D:\Codesys-MCP-main\Codesys-MCP-Test\projects\Accumulator_Rev1.0.0.260412.project"

Write-Host "Project Path: $projectPath"
Write-Host ""

# Test 1: Device Scan
Write-Host "=== Test 1: Device Scan ==="
$scanInput = @{
    tool = "scan_devices"
    arguments = @{}
} | ConvertTo-Json -Compress

$scanOutput = $scanInput | node "dist\server.js" --mode headless 2>&1
Write-Host "Scan Output:"
Write-Host $scanOutput

if ($scanOutput -match "SCRIPT_SUCCESS") {
    Write-Host "✓ Device scan successful" -ForegroundColor Green
} else {
    Write-Host "✗ Device scan failed" -ForegroundColor Red
}

Write-Host ""

# Test 2: Device Login
Write-Host "=== Test 2: Device Login ==="
$loginInput = @{
    tool = "connect_to_device"
    arguments = @{
        projectFilePath = $projectPath
    }
} | ConvertTo-Json -Compress

$loginOutput = $loginInput | node "dist\server.js" --mode headless 2>&1
Write-Host "Login Output:"
Write-Host $loginOutput

if ($loginOutput -match "SCRIPT_SUCCESS") {
    Write-Host "✓ Device login successful" -ForegroundColor Green
} else {
    Write-Host "✗ Device login failed" -ForegroundColor Red
}

Write-Host ""

# Test 3: Application State
Write-Host "=== Test 3: Application State ==="
$stateInput = @{
    tool = "get_application_state"
    arguments = @{
        projectFilePath = $projectPath
    }
} | ConvertTo-Json -Compress

$stateOutput = $stateInput | node "dist\server.js" --mode headless 2>&1
Write-Host "State Output:"
Write-Host $stateOutput

if ($stateOutput -match "SCRIPT_SUCCESS") {
    Write-Host "✓ Application state check successful" -ForegroundColor Green
} else {
    Write-Host "✗ Application state check failed" -ForegroundColor Red
}

Write-Host ""

# Test 4: Read Variable
Write-Host "=== Test 4: Read Variable (PLC_PRG.nAccumulator) ==="
$readInput = @{
    tool = "read_variable"
    arguments = @{
        projectFilePath = $projectPath
        variablePath = "PLC_PRG.nAccumulator"
    }
} | ConvertTo-Json -Compress

$readOutput = $readInput | node "dist\server.js" --mode headless 2>&1
Write-Host "Read Output:"
Write-Host $readOutput

if ($readOutput -match "SCRIPT_SUCCESS") {
    Write-Host "✓ Variable read successful" -ForegroundColor Green
} else {
    Write-Host "✗ Variable read failed" -ForegroundColor Red
}

Write-Host ""

# Test 5: Write Variable
Write-Host "=== Test 5: Write Variable (PLC_PRG.bEnable = TRUE) ==="
$writeInput = @{
    tool = "write_variable"
    arguments = @{
        projectFilePath = $projectPath
        variablePath = "PLC_PRG.bEnable"
        value = "TRUE"
    }
} | ConvertTo-Json -Compress

$writeOutput = $writeInput | node "dist\server.js" --mode headless 2>&1
Write-Host "Write Output:"
Write-Host $writeOutput

if ($writeOutput -match "SCRIPT_SUCCESS") {
    Write-Host "✓ Variable write successful" -ForegroundColor Green
} else {
    Write-Host "✗ Variable write failed" -ForegroundColor Red
}

Write-Host ""
Write-Host "Test completed!"
