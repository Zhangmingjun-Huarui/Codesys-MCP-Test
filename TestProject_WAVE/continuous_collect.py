# encoding:utf-8
from __future__ import print_function
import sys
import json
import time
import os

output_file = r"D:\Codesys-MCP-main\Codesys-MCP-Test\TestProject_WAVE\data\latest.json"
history_file = r"D:\Codesys-MCP-main\Codesys-MCP-Test\TestProject_WAVE\data\history.json"
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
sample_count = 60
sample_interval = 1000

def log(msg):
    print(msg)
    sys.stdout.flush()

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
    log("STEP4: Login successful")

    state = onlineapp.application_state
    log("STEP5: Application state: %s" % str(state))

    if not state == ApplicationState.run:
        onlineapp.start()
        log("STEP6: Application started")
    else:
        log("STEP6: Application already running")

    system.delay(500)

    data_dir = os.path.dirname(output_file)
    if not os.path.exists(data_dir):
        os.makedirs(data_dir)

    log("STEP7: Starting continuous data collection (%d samples, %dms interval)..." % (sample_count, sample_interval))
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

        result = {"project": project_path, "collectedAt": time.time() * 1000, "samples": samples}
        with open(output_file, "w") as f:
            json.dump(result, f, indent=2)

        output_val = sample["values"].get("GVL_WebInterface.rSineOutput", "?")
        running = sample["values"].get("GVL_WebInterface.xSineRunning", "?")
        enable = sample["values"].get("GVL_WebInterface.xSineEnable", "?")
        log("  Sample %d/%d: rSineOutput=%s, xSineRunning=%s, xSineEnable=%s" % (i + 1, sample_count, output_val, running, enable))

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
        log("STEP8: History updated (%d records)" % len(history))
    except Exception as he:
        log("WARN: History update failed: %s" % str(he))

    log("ALL_STEPS_COMPLETE: Continuous collection finished!")
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
