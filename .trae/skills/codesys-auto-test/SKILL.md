---
name: "codesys-auto-test"
description: "CODESYS MCP automated testing: deploy PLC project, collect variables, web monitor verification. Invoke when user needs CODESYS project testing, PLC deployment, variable monitoring, or full integration test."
---

# CODESYS MCP Automated Testing Skill

## 1. Test Environment Configuration

### 1.1 Software Dependencies

| Component | Version | Path |
|-----------|---------|------|
| CODESYS IDE | 3.5.19.50 | `C:\Program Files\CODESYS 3.5.19.50\CODESYS\Common\CODESYS.exe` |
| CODESYS Profile | CODESYS V3.5 SP19 Patch 5 | Default installation |
| CODESYS Control Win V3 x64 | 3.5.19.50 | Windows Service |
| CODESYS Gateway V3 | 3.5.19.50 | Windows Service |
| Node.js | >= 16.x | For Web monitor backend |
| PowerShell | 5.1 | Windows built-in |
| MCP Server | codesys-mcp v2.0.0 | `D:\Codesys-MCP-main\Codesys-MCP-main` |

### 1.2 Directory Structure

```
D:\Codesys-MCP-main\Codesys-MCP-Test\
├── templates\                          # Project template library
│   ├── template_registry.json          # Template registry (UTF-8 no BOM)
│   └── Accumulator_Rev1.0.0.260412.project  # Verified template
├── projects\                           # Test project output
├── scripts\                            # Automation scripts
│   ├── Start-FullAutoDeploy.ps1        # Full auto deploy entry
│   ├── deploy_and_collect.py           # CODESYS Python script
│   ├── Collect-VariableData.ps1        # Standalone data collection
│   ├── New-ProjectFromTemplate.ps1     # Create project from template
│   └── Run-IntegrationTest.ps1         # Integration test suite
├── web-monitor\                        # Web monitoring system
│   ├── backend\
│   │   ├── server.js                   # Express + WebSocket server
│   │   ├── package.json
│   │   └── data\                       # Collected data
│   │       ├── latest.json             # Latest samples
│   │       └── history.json            # Historical records
│   └── frontend\
│       └── index.html                  # Responsive monitoring UI
└── .trae\skills\codesys-auto-test\     # This skill
```

### 1.3 Windows Services Required

| Service Name | Must Be Running |
|-------------|----------------|
| CODESYS Control Win V3 - x64 | YES |
| CODESYS Gateway V3 | YES |
| CODESYS ServiceControl | YES |

### 1.4 MCP Script Engine Known Issues

| Issue | Root Cause | Solution |
|-------|-----------|----------|
| `online.create_online_application()` returns "Stack empty" | MCP watcher uses `exec()` with custom globals, CODESYS internal state incomplete | Use `--runscript` direct execution instead of MCP `exec()` |
| `print(msg, flush=True)` TypeError | IronPython does not support `flush` keyword | Use `print(msg); sys.stdout.flush()` |
| JSON BOM parsing error | PowerShell `WriteAllText` adds UTF-8 BOM | Use `New-Object System.Text.UTF8Encoding $false` |
| `library_manager` import fails | Not available in scriptengine | Import each module individually with try/except |
| ScriptManager cache stale | MCP server caches loaded templates | Disable cache in `script-manager.ts` or restart MCP |
| `connect_to_device` kills persistent session | `--runscript` mode spawns new CODESYS and exits | Rev2.0.0: auto re-launches persistent instance after connect |
| `write_variable` type mismatch | String values not converted to Python types | Rev2.0.0: auto-converts BOOL/INT/FLOAT, with verification read-back |

---

## 2. Detailed Operation Steps

### Step 1: Ensure PLC Runtime Services Running

```powershell
# Check and start services
$svc = Get-Service -Name "CODESYS Control Win V3 - x64"
if ($svc.Status -ne "Running") { Start-Service -Name "CODESYS Control Win V3 - x64" }

$gw = Get-Service -Name "CODESYS Gateway V3"
if ($gw.Status -ne "Running") { Start-Service -Name "CODESYS Gateway V3" }
```

**Verification**: `Get-Service -Name "CODESYS*" | Select-Object Name, Status` — all should show "Running"

### Step 2: Start Web Monitor Backend

```powershell
cd D:\Codesys-MCP-main\Codesys-MCP-Test\web-monitor\backend
node server.js
```

**Verification**: Access http://localhost:3000 returns HTTP 200

### Step 3: Full Auto Deploy + Run + Collect

```powershell
powershell -ExecutionPolicy Bypass -File "D:\Codesys-MCP-main\Codesys-MCP-Test\scripts\Start-FullAutoDeploy.ps1"
```

This single command performs:
1. Ensures PLC runtime and Gateway services are running
2. Closes existing CODESYS instances
3. Opens project in CODESYS via `--runscript`
4. Compiles project (implicit in `login`)
5. Logs in to PLC device (`onlineapp.login(OnlineChangeOption.Try, True)`)
6. Downloads application to PLC
7. Starts PLC application (`onlineapp.start()`)
8. Collects 20 variable samples at 500ms intervals
9. Saves data to `latest.json` and `history.json`
10. Logs out and closes project

**Expected Duration**: 30-60 seconds

### Step 4: Verify Data via API

```powershell
$data = Invoke-RestMethod -Uri "http://localhost:3000/api/variables/latest"
$data.samples[-1].values
```

**Expected Output**:
```
PLC_PRG.nAccumulator: INT#<0-999>
PLC_PRG.nCycleCount:  DINT#0
PLC_PRG.bEnable:      TRUE
PLC_PRG.nStep:        INT#1
PLC_PRG.nMaxValue:    INT#1000
```

### Step 5: Run Integration Test Suite

```powershell
powershell -ExecutionPolicy Bypass -File "D:\Codesys-MCP-main\Codesys-MCP-Test\scripts\Run-IntegrationTest.ps1"
```

**Expected Output**: `ALL 10 TESTS PASSED!`

---

## 3. Key Verification Points

### 3.1 PLC Program Verification

| Check Point | Expected | How to Verify |
|-------------|----------|---------------|
| Project compiles | 0 errors, 0 warnings | `mcp_codesys_compile_project` |
| Login succeeds | No exception | `onlineapp.login()` returns |
| Application state | `ApplicationState.run` | `onlineapp.application_state` |
| nAccumulator increments | Value increases each sample | Compare consecutive samples |
| nAccumulator resets at 1000 | nAccumulator returns to 0 | Long-running observation |
| nCycleCount increments | +1 after each full cycle | After nAccumulator resets |
| bEnable controls accumulation | Setting FALSE stops increment | Write FALSE, observe |

### 3.2 Web Monitor Verification

| Check Point | Expected | How to Verify |
|-------------|----------|---------------|
| Login API | Returns token + role | POST /api/login |
| Templates API | Returns template list | GET /api/templates |
| Alarm config API | Returns alarm thresholds | GET /api/alarm-config |
| Latest data API | Returns sample array | GET /api/variables/latest |
| History API | Returns historical records | GET /api/variables/history |
| CSV export | Returns CSV text | GET /api/variables/export?format=csv |
| WebSocket push | Real-time data on connect | ws://localhost:3000/ws |
| User roles | admin/operator/viewer | Login with different credentials |

### 3.3 Integration Test Checklist (10 items)

1. Template Registry Check — JSON valid, templates > 0
2. Template Project File — File exists, size > 10KB
3. Project Directory — Output project file exists
4. Web Monitor Login — admin login returns role=admin
5. Templates API — Returns >= 1 template
6. Alarm Config API — nAccumulator alarm thresholds present
7. Variable Data API — Returns samples with valid PLC_PRG.* values
8. User Permission — viewer login returns role=viewer
9. Frontend File — index.html contains correct variable names
10. Backend Server — HTTP 200 on /

---

## 4. Test Tools and Version Information

### 4.1 MCP Tools Used

| MCP Tool | Purpose | Notes |
|----------|---------|-------|
| `create_project` | Create project from template | Uses Standard.project template |
| `create_pou` | Create PLC program POU | Must specify type=Program, language=ST |
| `set_pou_code` | Set POU declaration and implementation | Separate declaration/implementation |
| `create_gvl` | Create global variable list | For external variable access |
| `compile_project` | Build project | Must pass before deploy |
| `connect_to_device` | Login to PLC | Rev2.0.0: fixed persistent session issue |
| `read_variable` | Read PLC variable | Requires active connection |
| `write_variable` | Write PLC variable | Rev2.0.0: auto type conversion + verification |

### 4.2 Direct CODESYS Script Execution (Recommended)

For operations requiring `online.create_online_application()`, use direct `--runscript`:

```powershell
Start-Process -FilePath $CodesysExe -ArgumentList "--profile=`"$Profile`"", "--runscript=`"$ScriptPath`"" -NoNewWindow
```

This bypasses MCP's `exec()` mechanism and runs in CODESYS main thread context.

### 4.3 CODESYS Python Script Template

```python
# encoding:utf-8
from __future__ import print_function
import sys

def log(msg):
    print(msg)
    sys.stdout.flush()

try:
    if projects.primary:
        projects.primary.close()
    proj = projects.open(r"<PROJECT_PATH>")
    app = proj.active_application
    onlineapp = online.create_online_application(app)
    onlineapp.login(OnlineChangeOption.Try, True)
    if not onlineapp.application_state == ApplicationState.run:
        onlineapp.start()
    system.delay(500)
    val = onlineapp.read_value("PLC_PRG.nAccumulator")
    log("Value: %s" % val)
    onlineapp.logout()
    proj.close()
    log("SUCCESS")
except Exception as e:
    log("ERROR: %s" % str(e))
    sys.exit(1)
```

**Critical Notes for IronPython**:
- NO `print(msg, flush=True)` — use `print(msg); sys.stdout.flush()`
- NO f-strings — use `%` formatting
- NO `from scriptengine import *` — use global objects directly (`projects`, `online`, `OnlineChangeOption`, `ApplicationState`)
- `system.delay()` for waiting, NOT `time.sleep()`

---

## 5. Exception Handling

### 5.1 PLC Service Not Running

**Symptom**: `login()` fails or timeout
**Solution**:
```powershell
Start-Service -Name "CODESYS Control Win V3 - x64"
Start-Service -Name "CODESYS Gateway V3"
```

### 5.2 "Stack Empty" Error from MCP

**Symptom**: `SystemError: 堆栈为空。` when calling `online.create_online_application()`
**Root Cause**: MCP watcher's `exec()` cannot properly initialize CODESYS online module
**Solution**: Use `--runscript` direct execution instead of MCP tools

### 5.3 CODESYS Process Conflict

**Symptom**: Script hangs or fails to open project
**Solution**:
```powershell
Get-Process -Name "CODESYS" | Stop-Process -Force
Start-Sleep -Seconds 3
```

### 5.4 JSON BOM Parsing Error

**Symptom**: Node.js `JSON.parse` fails on template_registry.json
**Root Cause**: PowerShell adds UTF-8 BOM when writing files
**Solution**:
```powershell
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
```

### 5.5 Variable Name Not Found

**Symptom**: `read_value()` returns "invalid expression"
**Root Cause**: Variable path doesn't match POU declaration names
**Solution**: Verify POU uses `PLC_PRG` as task name, variable names match exactly (case-sensitive)

### 5.6 MCP ScriptManager Cache Stale

**Symptom**: Modified scripts not taking effect
**Root Cause**: `ScriptManager` caches loaded templates in memory
**Solution**: Restart MCP server process (requires user action)

---

## 6. Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| Rev1.0.0.260412 | 2026-04-12 | TRAE AI | Initial version - full test flow documented |
| | | | Fixed IronPython flush issue |
| | | | Fixed JSON BOM issue |
| | | | Documented MCP exec() limitation |
| | | | Created full auto deploy pipeline |
| | | | Web monitor with 10-point integration test |
| Rev2.0.0.260414 | 2026-04-14 | TRAE AI | Major bug fixes and refactoring |
| | | | **Fixed**: `connect_to_device` no longer kills persistent session |
| | | | **Fixed**: `write_variable` auto-converts types (BOOL/INT/FLOAT) |
| | | | **Added**: Post-write verification read-back |
| | | | **Improved**: `ensure_online_connection` simplified and hardened |
| | | | **Improved**: `connect_to_device` removed hardcoded test variable |
| | | | **Improved**: Server-side response parsing for connect/write tools |
| | | | Version bump to 2.0.0 |

---

## 7. Quick Reference Commands

```powershell
# Full auto deploy + collect (ONE COMMAND)
powershell -ExecutionPolicy Bypass -File "D:\Codesys-MCP-main\Codesys-MCP-Test\scripts\Start-FullAutoDeploy.ps1"

# Start web monitor
cd D:\Codesys-MCP-main\Codesys-MCP-Test\web-monitor\backend; node server.js

# Run integration tests
powershell -ExecutionPolicy Bypass -File "D:\Codesys-MCP-main\Codesys-MCP-Test\scripts\Run-IntegrationTest.ps1"

# Check PLC services
Get-Service -Name "CODESYS*" | Select-Object Name, Status

# Check latest data
Invoke-RestMethod -Uri "http://localhost:3000/api/variables/latest" | ConvertTo-Json

# Kill stuck CODESYS
Get-Process -Name "CODESYS" | Stop-Process -Force
```
