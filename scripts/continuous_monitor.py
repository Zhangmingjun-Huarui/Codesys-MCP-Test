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
sample_interval = 1000
continuous_mode = True

def log(msg):
    print(msg)
    sys.stdout.flush()

def save_connection_status(status, app_state):
    status_data = {
        "timestamp": time.time() * 1000,
        "datetime": time.strftime("%Y-%m-%d %H:%M:%S"),
        "status": status,
        "application_state": app_state,
        "project": project_path,
        "monitoring": continuous_mode
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
    log("PROJECT_OPENED: %s" % project_path)

    app = proj.active_application
    log("APPLICATION: %s" % app.get_name())

    onlineapp = online.create_online_application(app)
    log("ONLINE_APP_CREATED")

    onlineapp.login(OnlineChangeOption.Try, True)
    log("LOGIN_SUCCESS")

    state = onlineapp.application_state
    log("APP_STATE: %s" % str(state))

    if not state == ApplicationState.run:
        onlineapp.start()
        log("APP_STARTED")

    save_connection_status("connected", str(state))
    log("")
    log("========================================")
    log("CONTINUOUS MONITORING MODE ACTIVE")
    log("========================================")
    log("")

    sample_count = 0
    while continuous_mode:
        system.delay(sample_interval)
        sample_count += 1
        
        sample = {"timestamp": time.time() * 1000, "values": {}}
        for var_name in variables:
            try:
                val = onlineapp.read_value(var_name)
                sample["values"][var_name] = str(val)
            except Exception as ve:
                sample["values"][var_name] = "ERROR: %s" % str(ve)
        
        samples.append(sample)
        if len(samples) > 100:
            samples = samples[-100:]

        acc_val = sample["values"].get("PLC_PRG.nAccumulator", "?")
        current_state = str(onlineapp.application_state)
        
        log("SAMPLE_%d: nAccumulator=%s, State=%s" % (sample_count, acc_val, current_state))

        result = {"project": project_path, "collectedAt": time.time() * 1000, "samples": samples}
        with open(output_file, "w") as f:
            json.dump(result, f, indent=2)

        try:
            history = []
            if os.path.exists(history_file):
                with open(history_file, "r") as f:
                    history = json.load(f)
            history.append(sample)
            if len(history) > 10000:
                history = history[-10000:]
            with open(history_file, "w") as f:
                json.dump(history, f, indent=2)
        except:
            pass

        save_connection_status("connected", current_state)

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
