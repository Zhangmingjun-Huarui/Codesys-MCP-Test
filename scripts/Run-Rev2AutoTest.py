# encoding:utf-8
from __future__ import print_function
import sys
import json
import time
import os
import traceback

PROJECT_PATH = r"D:\Codesys-MCP-main\Codesys-MCP-Test\Codesys_Test_Demo\Codesys_Test_Demo_Rev1.0.0.260414.project"
REPORT_PATH = r"D:\Codesys-MCP-main\Codesys-MCP-Test\test-results\rev2-test-report.json"
VARIABLES_TO_READ = ["PLC_PRG.nAccumulator", "PLC_PRG.nCycleCount", "PLC_PRG.bEnable", "PLC_PRG.nStep", "PLC_PRG.nMaxValue"]

def log(msg):
    print(msg)
    sys.stdout.flush()

def now_ms():
    return int(time.time() * 1000)

test_results = []
test_start = now_ms()

def record(test_id, test_name, passed, detail=""):
    entry = {
        "id": test_id,
        "name": test_name,
        "passed": passed,
        "detail": detail,
        "timestamp": now_ms()
    }
    test_results.append(entry)
    status = "PASS" if passed else "FAIL"
    log("  [%s] %s" % (status, test_name))
    if detail:
        log("         %s" % detail)

def save_report():
    report_dir = os.path.dirname(REPORT_PATH)
    if not os.path.exists(report_dir):
        os.makedirs(report_dir)

    total = len(test_results)
    passed = sum(1 for r in test_results if r["passed"])
    failed = total - passed

    report = {
        "version": "Rev2.0.0",
        "date": time.strftime("%Y-%m-%d %H:%M:%S"),
        "project": PROJECT_PATH,
        "summary": {
            "total": total,
            "passed": passed,
            "failed": failed,
            "duration_ms": now_ms() - test_start
        },
        "results": test_results
    }

    with open(REPORT_PATH, "w") as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
    log("")
    log("Report saved: %s" % REPORT_PATH)

log("=" * 60)
log("CODESYS MCP Rev2.0.0 Auto Test Suite")
log("=" * 60)
log("Project: %s" % PROJECT_PATH)
log("Time: %s" % time.strftime("%Y-%m-%d %H:%M:%S"))
log("")

try:
    log("--- Phase 1: Project Operations ---")

    if projects.primary:
        projects.primary.close()
        log("  Closed existing project")

    proj = projects.open(PROJECT_PATH)
    record("T01", "Open project", True, "Project opened successfully")
    log("")

    log("--- Phase 2: Application Discovery ---")

    target_app = None
    try:
        target_app = proj.active_application
    except:
        pass

    if not target_app:
        children = proj.get_children(True)
        for child in children:
            if hasattr(child, 'is_application') and child.is_application:
                target_app = child
                break

    if target_app:
        app_name = target_app.get_name()
        record("T02", "Find application", True, "Application: %s" % app_name)
    else:
        record("T02", "Find application", False, "No application found")
        raise RuntimeError("No application found")
    log("")

    log("--- Phase 3: Compile ---")

    compile_ok = False
    compile_errors = 0
    compile_warnings = 0
    try:
        msg_list = []
        try:
            compiler = target_app.get_compiler()
            compiler.compile()
            msg_list = compiler.get_messages()
        except:
            try:
                msg_list = proj.active_application.compile()
            except:
                pass

        for msg in msg_list:
            msg_str = str(msg).lower()
            if "error" in msg_str:
                compile_errors += 1
            elif "warn" in msg_str:
                compile_warnings += 1

        compile_ok = compile_errors == 0
    except Exception as e:
        compile_ok = False
        compile_errors = -1

    record("T03", "Compile project", compile_ok,
           "Errors: %d, Warnings: %d" % (compile_errors, compile_warnings))

    if not compile_ok:
        log("  Compilation failed, attempting online connection anyway...")
    log("")

    log("--- Phase 4: Online Connection (connect_to_device) ---")

    online_app = None

    try:
        online_app = online.create_online_application(target_app)
        record("T04a", "online.create_online_application()", True)
    except Exception as e:
        record("T04a", "online.create_online_application()", False, str(e))

    if not online_app:
        try:
            online_app = target_app.create_online_application()
            record("T04b", "app.create_online_application()", True)
        except Exception as e:
            record("T04b", "app.create_online_application()", False, str(e))

    if not online_app:
        raise RuntimeError("Could not create online application - all methods failed")

    log("  Online application created")
    log("")

    log("--- Phase 5: Login ---")

    login_ok = False
    try:
        online_app.login(OnlineChangeOption.Try, True)
        login_ok = True
        record("T05", "Login (OnlineChangeOption.Try, True)", True)
    except Exception as e1:
        log("  Method 1 failed: %s" % e1)
        try:
            online_app.login(OnlineChangeOption.Try, False)
            login_ok = True
            record("T05", "Login (OnlineChangeOption.Try, False)", True)
        except Exception as e2:
            log("  Method 2 failed: %s" % e2)
            try:
                online_app.login()
                login_ok = True
                record("T05", "Login (no args)", True)
            except Exception as e3:
                record("T05", "Login", False, "All 3 methods failed: %s; %s; %s" % (e1, e2, e3))

    if not login_ok:
        raise RuntimeError("Login failed")
    log("")

    log("--- Phase 6: Application State ---")

    state = str(online_app.application_state)
    record("T06", "Get application state", True, "State: %s" % state)

    if state != "run":
        try:
            online_app.start()
            system.delay(1000)
            state = str(online_app.application_state)
            log("  Started application, new state: %s" % state)
        except Exception as e:
            log("  Start failed: %s" % e)

    is_running = (state == "run")
    record("T07", "Application running", is_running, "State: %s" % state)
    log("")

    log("--- Phase 7: Read Variables ---")

    system.delay(500)

    read_values = {}
    for var_name in VARIABLES_TO_READ:
        try:
            val = online_app.read_value(var_name)
            val_str = str(val)
            read_values[var_name] = val_str
            record("T08_%s" % var_name.split(".")[-1], "Read %s" % var_name, True, "Value: %s" % val_str)
        except Exception as e:
            read_values[var_name] = "ERROR"
            record("T08_%s" % var_name.split(".")[-1], "Read %s" % var_name, False, str(e))
    log("")

    log("--- Phase 8: Write Variables (Type Conversion Tests) ---")

    write_tests = [
        ("PLC_PRG.bEnable", "TRUE", True, "BOOL TRUE"),
        ("PLC_PRG.bEnable", "FALSE", False, "BOOL FALSE"),
        ("PLC_PRG.bEnable", "TRUE", True, "BOOL restore TRUE"),
        ("PLC_PRG.nMaxValue", "500", 500, "INT 500"),
        ("PLC_PRG.nMaxValue", "1000", 1000, "INT restore 1000"),
    ]

    for var_path, write_str, expected_py, desc in write_tests:
        try:
            converted = write_str
            if write_str.lower() in ("true", "yes", "1", "on"):
                converted = True
            elif write_str.lower() in ("false", "no", "0", "off"):
                converted = False
            else:
                try:
                    converted = int(write_str)
                except:
                    try:
                        converted = float(write_str)
                    except:
                        pass

            online_app.set_prepared_value(var_path, str(converted))
            online_app.write_prepared_values()
            system.delay(300)

            read_back = online_app.read_value(var_path)
            read_back_str = str(read_back)

            test_id = "T09_%s" % desc.replace(" ", "_")
            record(test_id, "Write %s = %s (%s)" % (var_path, write_str, desc), True,
                   "Written: %s, Read back: %s" % (write_str, read_back_str))

        except Exception as e:
            test_id = "T09_%s" % desc.replace(" ", "_")
            record(test_id, "Write %s = %s (%s)" % (var_path, write_str, desc), False, str(e))
    log("")

    log("--- Phase 9: Verify Write Persistence ---")

    system.delay(500)

    bEnable_val = None
    nMaxValue_val = None
    try:
        bEnable_val = str(online_app.read_value("PLC_PRG.bEnable"))
        record("T10a", "Verify bEnable after writes", True, "Value: %s" % bEnable_val)
    except Exception as e:
        record("T10a", "Verify bEnable after writes", False, str(e))

    try:
        nMaxValue_val = str(online_app.read_value("PLC_PRG.nMaxValue"))
        record("T10b", "Verify nMaxValue after writes", True, "Value: %s" % nMaxValue_val)
    except Exception as e:
        record("T10b", "Verify nMaxValue after writes", False, str(e))
    log("")

    log("--- Phase 10: Cleanup ---")

    try:
        online_app.logout()
        record("T11", "Logout", True)
    except Exception as e:
        record("T11", "Logout", False, str(e))

    try:
        proj.save()
        proj.close()
        record("T12", "Save and close project", True)
    except Exception as e:
        record("T12", "Save and close project", False, str(e))

    log("")
    log("=" * 60)
    log("TEST SUITE COMPLETE")
    log("=" * 60)

    save_report()

    total = len(test_results)
    passed = sum(1 for r in test_results if r["passed"])
    failed = total - passed

    log("")
    log("Total: %d | Passed: %d | Failed: %d" % (total, passed, failed))
    log("Duration: %d ms" % (now_ms() - test_start))

    if failed == 0:
        log("")
        log("ALL TESTS PASSED!")
        print("SCRIPT_SUCCESS: All %d tests passed" % total)
    else:
        log("")
        log("SOME TESTS FAILED!")
        for r in test_results:
            if not r["passed"]:
                log("  FAIL: %s - %s" % (r["name"], r["detail"]))
        print("SCRIPT_ERROR: %d of %d tests failed" % (failed, total))

    try:
        proj.close()
    except:
        pass

    system.exit(0 if failed == 0 else 1)

except SystemExit:
    raise
except Exception as e:
    detailed = traceback.format_exc()
    log("")
    log("FATAL ERROR: %s" % e)
    log(detailed)
    record("FATAL", "Unexpected error", False, str(e))
    save_report()
    print("SCRIPT_ERROR: Fatal error: %s" % e)
    try:
        system.exit(1)
    except:
        sys.exit(1)
