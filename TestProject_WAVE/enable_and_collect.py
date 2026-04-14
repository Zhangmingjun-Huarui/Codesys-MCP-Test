# encoding:utf-8
from __future__ import print_function
import sys
import json
import time
import os

output_file = r"D:\Codesys-MCP-main\Codesys-MCP-Test\TestProject_WAVE\data\latest.json"
project_path = r"D:\Codesys-MCP-main\Codesys-MCP-Test\TestProject_WAVE\SineWave_Rev0.0.1.260412.project"
variables = [
    "GVL_WebInterface.xSineEnable",
    "GVL_WebInterface.rSineAmplitude",
    "GVL_WebInterface.rSineFrequency",
    "GVL_WebInterface.rSineOffset",
    "GVL_WebInterface.rSineOutput",
    "GVL_WebInterface.xSineRunning",
    "GVL_WebInterface.diCycleCount"
]

def log(msg):
    print(msg)
    sys.stdout.flush()

try:
    if projects.primary:
        projects.primary.close()

    proj = projects.open(project_path)
    log("STEP1: Project opened")

    app = proj.active_application
    log("STEP2: Application: %s" % app.get_name())

    onlineapp = online.create_online_application(app)
    log("STEP3: Online application created")

    onlineapp.login(OnlineChangeOption.KeepOldVariables, False)
    log("STEP4: Login successful (keep old variables, no download)")

    state = onlineapp.application_state
    log("STEP5: Application state: %s" % str(state))

    if state == ApplicationState.run:
        log("STEP6: Application already running - no need to start")
    else:
        onlineapp.start()
        log("STEP6: Application started")

    system.delay(500)

    onlineapp.write_value("GVL_WebInterface.xSineEnable", True)
    log("STEP7: xSineEnable set to TRUE - Sine wave ENABLED!")

    system.delay(1000)

    data_dir = os.path.dirname(output_file)
    if not os.path.exists(data_dir):
        os.makedirs(data_dir)

    samples = []
    log("STEP8: Starting continuous data collection (press Ctrl+C in CODESYS to stop)...")
    for i in range(300):
        system.delay(1000)
        sample = {"timestamp": time.time() * 1000, "values": {}}
        for var_name in variables:
            try:
                val = onlineapp.read_value(var_name)
                sample["values"][var_name] = str(val)
            except Exception as ve:
                sample["values"][var_name] = "ERROR: %s" % str(ve)
        samples.append(sample)

        if len(samples) > 60:
            samples = samples[-60:]

        result = {"project": project_path, "collectedAt": time.time() * 1000, "samples": samples}
        with open(output_file, "w") as f:
            json.dump(result, f, indent=2)

        output_val = sample["values"].get("GVL_WebInterface.rSineOutput", "?")
        running = sample["values"].get("GVL_WebInterface.xSineRunning", "?")
        enable = sample["values"].get("GVL_WebInterface.xSineEnable", "?")
        log("  [%d] rSineOutput=%s, xSineRunning=%s, xSineEnable=%s" % (i + 1, output_val, running, enable))

    log("DATA_COLLECTION_COMPLETE: 300 samples collected.")
    log("CODESYS UI is kept open for manual testing.")
except Exception as e:
    log("ERROR: %s" % str(e))
    import traceback
    log(traceback.format_exc())
    try:
        if 'proj' in dir():
            proj.close()
    except:
        pass
    sys.exit(1)
