# encoding:utf-8
from __future__ import print_function
import sys
import time

project_path = r"D:\Codesys-MCP-main\Codesys-MCP-Test\TestProject_WAVE\SineWave_Rev0.0.1.260412.project"

def log(msg):
    print(msg)
    sys.stdout.flush()

try:
    if projects.primary:
        projects.primary.close()

    proj = projects.open(project_path)
    log("STEP1: Project opened")

    app = proj.active_application
    onlineapp = online.create_online_application(app)
    onlineapp.login(OnlineChangeOption.Try, True)
    log("STEP2: Login successful")

    state = onlineapp.application_state
    log("STEP3: Application state: %s" % str(state))

    if not state == ApplicationState.run:
        onlineapp.start()
        log("STEP4: Application started")
    else:
        log("STEP4: Application already running")

    system.delay(500)

    # Enable the sine wave
    onlineapp.write_value("GVL_WebInterface.xSineEnable", True)
    log("STEP5: xSineEnable set to TRUE")

    system.delay(500)

    # Verify the value
    val = onlineapp.read_value("GVL_WebInterface.xSineEnable")
    log("STEP6: Verified xSineEnable = %s" % str(val))

    output_val = onlineapp.read_value("GVL_WebInterface.rSineOutput")
    log("STEP7: rSineOutput = %s" % str(output_val))

    running = onlineapp.read_value("GVL_WebInterface.xSineRunning")
    log("STEP8: xSineRunning = %s" % str(running))

    # Keep the project open for manual testing
    log("SINE_WAVE_ENABLED: Sine wave has been enabled successfully!")
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
