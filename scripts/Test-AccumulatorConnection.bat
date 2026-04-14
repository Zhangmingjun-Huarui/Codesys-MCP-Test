@echo off

echo CODESYS Device Connection Test with Accumulator Project
echo ================================================
echo Project Path: D:\Codesys-MCP-main\Codesys-MCP-Test\projects\Accumulator_Rev1.0.0.260412.project
echo.

REM Change to MCP server directory
cd /d D:\Codesys-MCP-main\Codesys-MCP-main

echo === Test 1: Device Scan ===
echo.
echo [SCAN] Scanning for devices...
echo.

REM Test device scan
node dist\server.js --mode headless << EOF
{
  "tool": "scan_devices",
  "arguments": {}
}
EOF

echo.
echo === Test 2: Device Login ===
echo.
echo [LOGIN] Connecting to device...
echo.

REM Test device login
node dist\server.js --mode headless << EOF
{
  "tool": "connect_to_device",
  "arguments": {
    "projectFilePath": "D:\Codesys-MCP-main\Codesys-MCP-Test\projects\Accumulator_Rev1.0.0.260412.project"
  }
}
EOF

echo.
echo === Test 3: Application State ===
echo.
echo [STATE] Checking application state...
echo.

REM Test application state
node dist\server.js --mode headless << EOF
{
  "tool": "get_application_state",
  "arguments": {
    "projectFilePath": "D:\Codesys-MCP-main\Codesys-MCP-Test\projects\Accumulator_Rev1.0.0.260412.project"
  }
}
EOF

echo.
echo === Test 4: Read Variable ===
echo.
echo [READ] Reading variable PLC_PRG.nAccumulator...
echo.

REM Test variable read
node dist\server.js --mode headless << EOF
{
  "tool": "read_variable",
  "arguments": {
    "projectFilePath": "D:\Codesys-MCP-main\Codesys-MCP-Test\projects\Accumulator_Rev1.0.0.260412.project",
    "variablePath": "PLC_PRG.nAccumulator"
  }
}
EOF

echo.
echo === Test 5: Write Variable ===
echo.
echo [WRITE] Writing variable PLC_PRG.bEnable = TRUE...
echo.

REM Test variable write
node dist\server.js --mode headless << EOF
{
  "tool": "write_variable",
  "arguments": {
    "projectFilePath": "D:\Codesys-MCP-main\Codesys-MCP-Test\projects\Accumulator_Rev1.0.0.260412.project",
    "variablePath": "PLC_PRG.bEnable",
    "value": "TRUE"
  }
}
EOF

echo.
echo Test completed!
echo.
pause
