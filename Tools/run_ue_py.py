#!/usr/bin/env python3
import sys
import os
import json
import urllib.request
import time

LOG_PATH = "/mnt/ssd_storage/RA21_UE5/RA21_Spatial_OS/Saved/Logs/RA21_Spatial_OS.log"
REMOTE_URL = "http://127.0.0.1:30010/remote/object/call"

def run_py_file(script_path):
    abs_path = os.path.abspath(script_path)
    
    # get current log size
    start_pos = 0
    if os.path.exists(LOG_PATH):
        start_pos = os.path.getsize(LOG_PATH)
        
    payload = {
        "objectPath": "/Script/Engine.Default__KismetSystemLibrary",
        "functionName": "ExecuteConsoleCommand",
        "parameters": {
            "Command": f"py {abs_path}"
        }
    }
    
    req = urllib.request.Request(
        REMOTE_URL,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="PUT"
    )
    
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            resp.read()
    except Exception as e:
        print("Error calling Remote Control:", e)
        return False

    time.sleep(0.5)
    
    # Read newly appended logs
    if os.path.exists(LOG_PATH):
        with open(LOG_PATH, "r", errors="ignore") as f:
            f.seek(start_pos)
            new_logs = f.read()
            for line in new_logs.splitlines():
                if "LogPython:" in line or "Error:" in line or "Warning:" in line:
                    print(line)
    return True

if __name__ == "__main__":
    if len(sys.argv) > 1:
        run_py_file(sys.argv[1])
    else:
        print("Usage: run_ue_py.py <path_to_script.py>")
