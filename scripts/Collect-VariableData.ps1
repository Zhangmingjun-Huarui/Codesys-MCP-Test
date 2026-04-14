param(
    [string]$ProjectPath = "D:\Codesys-MCP-main\Codesys-MCP-Test\projects\Accumulator_Rev1.0.0.260412.project",
    [string]$VariablesJson = "",
    [string]$OutputFile = "D:\Codesys-MCP-main\Codesys-MCP-Test\web-monitor\backend\data\latest.json",
    [int]$SampleIntervalMs = 500,
    [int]$SampleCount = 1,
    [string]$CodesysExe = "C:\Program Files\CODESYS 3.5.19.50\CODESYS\Common\CODESYS.exe",
    [string]$Profile = "CODESYS V3.5 SP19 Patch 5",
    [switch]$KeepConnection = $true
)

$ErrorActionPreference = "Stop"

$dataDir = Split-Path $OutputFile -Parent
if (-not (Test-Path $dataDir)) {
    New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
}

$variables = @("PLC_PRG.nAccumulator", "PLC_PRG.nCycleCount", "PLC_PRG.bEnable", "PLC_PRG.nStep", "PLC_PRG.nMaxValue")
if ($VariablesJson -and (Test-Path $VariablesJson)) {
    $varConfig = Get-Content $VariablesJson -Raw | ConvertFrom-Json
    $variables = $varConfig.variables | ForEach-Object { $_.name }
}

$varList = ($variables | ForEach-Object { "'$_'" }) -join ", "
$statusFile = Join-Path $dataDir "connection_status.json"

$scriptPath = Join-Path $dataDir "_collect.py"
$keepConnectionStr = if ($KeepConnection) { "True" } else { "False" }

$scriptContent = @"
# encoding:utf-8
from __future__ import print_function
import sys
import json
import time
import os

output_file = r"$OutputFile"
history_file = r"$($dataDir)\history.json"
status_file = r"$statusFile"
project_path = r"$ProjectPath"
variables = [$varList]
sample_count = $SampleCount
sample_interval = $SampleIntervalMs
keep_connection = $keepConnectionStr

def log(msg):
    print(msg)
    sys.stdout.flush()

def save_status(status, app_state):
    try:
        data = {
            "timestamp": time.time() * 1000,
            "datetime": time.strftime("%Y-%m-%d %H:%M:%S"),
            "status": status,
            "application_state": app_state,
            "project": project_path
        }
        with open(status_file, "w") as f:
            json.dump(data, f, indent=2)
    except:
        pass

samples = []

try:
    if projects.primary:
        projects.primary.close()

    proj = projects.open(project_path)
    log("Project opened")

    app = proj.active_application
    onlineapp = online.create_online_application(app)
    onlineapp.login(OnlineChangeOption.Try, True)
    log("Logged in")

    if not onlineapp.application_state == ApplicationState.run:
        onlineapp.start()
        log("Application started")

    state = str(onlineapp.application_state)
    save_status("connected", state)

    for i in range(sample_count):
        system.delay(sample_interval)
        sample = {"timestamp": time.time() * 1000, "values": {}}
        for var_name in variables:
            try:
                val = onlineapp.read_value(var_name)
                sample["values"][var_name] = str(val)
            except Exception as ve:
                sample["values"][var_name] = "ERROR: %s" % str(ve)
        samples.append(sample)

    if keep_connection:
        current_state = str(onlineapp.application_state)
        save_status("connected", current_state)
        proj.save()
        log("CONNECTION_MAINTAINED: YES")
        log("APPLICATION_STATE: %s" % current_state)
        log("COLLECT_SUCCESS")
    else:
        onlineapp.logout()
        proj.close()
        save_status("disconnected", "closed")
        log("COLLECT_SUCCESS")

    result = {"project": project_path, "collectedAt": time.time() * 1000, "samples": samples}
    with open(output_file, "w") as f:
        json.dump(result, f, indent=2)

    try:
        history = []
        if os.path.exists(history_file):
            with open(history_file, "r") as f:
                history = json.load(f)
        history.extend(samples)
        if len(history) > 10000:
            history = history[-10000:]
        with open(history_file, "w") as f:
            json.dump(history, f, indent=2)
    except:
        pass

except Exception as e:
    log("ERROR: %s" % str(e))
    import traceback
    log(traceback.format_exc())
    save_status("error", str(e))
    try:
        proj.close()
    except:
        pass
    sys.exit(1)
"@

Set-Content -Path $scriptPath -Value $scriptContent -Encoding UTF8

$resultFile = Join-Path $dataDir "_collect_result.txt"
if (Test-Path $resultFile) { Remove-Item $resultFile -Force }

$proc = Start-Process -FilePath $CodesysExe -ArgumentList "--profile=`"$Profile`"", "--runscript=`"$scriptPath`"" -PassThru -NoNewWindow

$timeout = 90
$elapsed = 0
while (-not (Test-Path $OutputFile) -and $elapsed -lt $timeout) {
    Start-Sleep -Seconds 1
    $elapsed++
}

if (Test-Path $OutputFile) {
    Write-Host "Data collected successfully" -ForegroundColor Green
    if ($KeepConnection) {
        Write-Host "Connection maintained: YES" -ForegroundColor Cyan
    }
    Get-Content $OutputFile
} else {
    Write-Host "Timeout waiting for data collection" -ForegroundColor Red
}

if (-not $KeepConnection -and -not $proc.HasExited) {
    Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
}

Remove-Item $scriptPath -Force -ErrorAction SilentlyContinue
