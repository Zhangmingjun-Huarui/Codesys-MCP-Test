# encoding:utf-8
from __future__ import print_function
import sys
import time

project_path = r"D:\Codesys-MCP-main\Codesys-MCP-Test\TestProject_WAVE\SineWave_Rev0.0.1.260412.project"

def log(msg):
    print(msg)
    sys.stdout.flush()

try:
    log("Starting enable_sinewave_simple.py...")

    if projects.primary:
        log("Closing existing project...")
        projects.primary.close()

    log("Opening project: %s" % project_path)
    proj = projects.open(project_path)
    log("STEP1: Project opened")

    app = proj.active_application
    log("STEP2: Application: %s" % app.get_name())

    log("Creating online application...")
    onlineapp = online.create_online_application(app)
    log("STEP3: Online application created")

    log("Logging in (Try, download=True)...")
    onlineapp.login(OnlineChangeOption.Try, True)
    log("STEP4: Login successful")

    state = onlineapp.application_state
    log("STEP5: Application state: %s" % str(state))

    if state == ApplicationState.run:
        log("Application already running")
    else:
        log("Starting application...")
        onlineapp.start()
        log("Application started")

    system.delay(500)

    log("Writing xSineEnable = TRUE...")
    onlineapp.write_value("GVL_WebInterface.xSineEnable", True)
    log("STEP6: xSineEnable set to TRUE")

    system.delay(500)

    val = onlineapp.read_value("GVL_WebInterface.xSineEnable")
    log("STEP7: Verified xSineEnable = %s" % str(val))

    output_val = onlineapp.read_value("GVL_WebInterface.rSineOutput")
    log("STEP8: rSineOutput = %s" % str(output_val))

    running = onlineapp.read_value("GVL_WebInterface.xSineRunning")
    log("STEP9: xSineRunning = %s" % str(running))

    log("SINE_WAVE_ENABLED: Success!")
    log("CODESYS UI will remain open for manual testing.")
except Exception as e:
    log("ERROR: %s" % str(e))
    import traceback
    log(traceback.format_exc())
    sys.exit(1)
