@echo off

echo Automated CODESYS Device Connection Test
echo =====================================
echo MCP Server Path: D:\Codesys-MCP-main\Codesys-MCP-main
echo Project Path: D:\Codesys-MCP-main\Codesys-MCP-Test\projects\Accumulator_Rev1.0.0.260412.project
echo.

REM Check CODESYS services
echo === Checking CODESYS Services ===
sc query "CODESYS Control Win V3 - x64"
echo.
sc query "CODESYS Gateway V3"
echo.
sc query "CODESYS ServiceControl"
echo.

REM Build MCP server
echo === Building MCP Server ===
cd /d D:\Codesys-MCP-main\Codesys-MCP-main
npm run build
echo.

REM Test device scan
echo === Test 1: Device Scan ===
echo {
  "tool": "scan_devices",
  "arguments": {}
} | node dist/server.js --mode headless
echo.

REM Test device login
echo === Test 2: Device Login ===
echo {
  "tool": "connect_to_device",
  "arguments": {
    "projectFilePath": "D:\Codesys-MCP-main\Codesys-MCP-Test\projects\Accumulator_Rev1.0.0.260412.project"
  }
} | node dist/server.js --mode headless
echo.

REM Test application state
echo === Test 3: Application State ===
echo {
  "tool": "get_application_state",
  "arguments": {
    "projectFilePath": "D:\Codesys-MCP-main\Codesys-MCP-Test\projects\Accumulator_Rev1.0.0.260412.project"
  }
} | node dist/server.js --mode headless
echo.

REM Test variable read
echo === Test 4: Read Variable ===
echo {
  "tool": "read_variable",
  "arguments": {
    "projectFilePath": "D:\Codesys-MCP-main\Codesys-MCP-Test\projects\Accumulator_Rev1.0.0.260412.project",
    "variablePath": "PLC_PRG.nAccumulator"
  }
} | node dist/server.js --mode headless
echo.

REM Test variable write
echo === Test 5: Write Variable ===
echo {
  "tool": "write_variable",
  "arguments": {
    "projectFilePath": "D:\Codesys-MCP-main\Codesys-MCP-Test\projects\Accumulator_Rev1.0.0.260412.project",
    "variablePath": "PLC_PRG.bEnable",
    "value": "TRUE"
  }
} | node dist/server.js --mode headless
echo.

echo Test completed!
echo.
pause
