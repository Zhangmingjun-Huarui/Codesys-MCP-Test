# encoding:utf-8
from __future__ import print_function
import sys
import json
import time
import os
import traceback

output_file = r"D:\Codesys-MCP-main\Codesys-MCP-Test\web-monitor\backend\data\latest.json"
history_file = r"D:\Codesys-MCP-main\Codesys-MCP-Test\web-monitor\backend\data\history.json"
status_file = r"D:\Codesys-MCP-main\Codesys-MCP-Test\web-monitor\backend\data\connection_status.json"
project_path = r"D:\Codesys-MCP-main\Codesys-MCP-Test\projects\Accumulator_Rev1.0.0.260412.project"
variables = ["PLC_PRG.nAccumulator", "PLC_PRG.nCycleCount", "PLC_PRG.bEnable", "PLC_PRG.nStep", "PLC_PRG.nMaxValue"]
sample_count = 20
sample_interval = 500
keep_connection = True

def log(msg):
    print(msg)
    sys.stdout.flush()

def save_connection_status(status, app_state):
    status_data = {
        "timestamp": time.time() * 1000,
        "datetime": time.strftime("%Y-%m-%d %H:%M:%S"),
        "status": status,
        "application_state": app_state,
        "project": project_path
    }
    try:
        with open(status_file, "w") as f:
            json.dump(status_data, f, indent=2)
    except:
        pass

samples = []

try:
    if projects.primary:
        projects.primary.close()

    proj = projects.open(project_path)
    log("STEP1: Project opened")

    app = proj.active_application
    log("STEP2: Active application: %s" % app.get_name())

    onlineapp = online.create_online_application(app)
    log("STEP3: Online application created")

    onlineapp.login(OnlineChangeOption.Try, True)
    log("STEP4: Login successful (download + auto-start)")

    state = onlineapp.application_state
    log("STEP5: Application state: %s" % str(state))

    if not state == ApplicationState.run:
        onlineapp.start()
        log("STEP6: Application started")
    else:
        log("STEP6: Application already running")

    system.delay(1000)

    save_connection_status("connected", str(state))
    log("STEP7: Connection status saved")

    log("STEP8: Starting data collection (%d samples, %dms interval)..." % (sample_count, sample_interval))
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
        acc_val = sample["values"].get("PLC_PRG.nAccumulator", "?")
        log("  Sample %d/%d: nAccumulator=%s" % (i + 1, sample_count, acc_val))

    result = {"project": project_path, "collectedAt": time.time() * 1000, "samples": samples}
    with open(output_file, "w") as f:
        json.dump(result, f, indent=2)
    log("STEP9: Data saved to %s" % output_file)

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
        log("STEP10: History updated (%d records)" % len(history))
    except Exception as he:
        log("WARN: History update failed: %s" % str(he))

    if keep_connection:
        current_state = onlineapp.application_state
        save_connection_status("connected", str(current_state))
        log("STEP11: Keeping connection alive - NOT logging out")
        log("STEP12: Project saved (connection maintained)")
        proj.save()
        log("")
        log("========================================")
        log("CONNECTION_STATUS: CONNECTED")
        log("APPLICATION_STATE: %s" % str(current_state))
        log("MONITORING_AVAILABLE: YES")
        log("========================================")
        log("")
        log("DEPLOY_COMPLETE_WITH_CONNECTION: Application deployed and connection maintained!")
        log("Use continuous_monitor.py to continue monitoring variables.")
    else:
        onlineapp.logout()
        log("STEP11: Logged out")
        proj.save()
        proj.close()
        log("ALL_STEPS_COMPLETE: Deploy + Run + Collect finished successfully!")

except Exception as e:
    detailed_error = traceback.format_exc()
    log("ERROR: %s" % str(e))
    log(detailed_error)
    save_connection_status("error", str(e))
    try:
        if 'proj' in dir():
            proj.close()
    except:
        pass
    sys.exit(1)
