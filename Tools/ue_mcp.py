#!/usr/bin/env python3
import urllib.request
import json
import base64
import sys
import os

BASE_URL = os.environ.get("UE_MCP_URL", "http://127.0.0.1:9900/mcp")
SESSION_FILE = "/tmp/ue_mcp_session.json"

def get_session():
    if os.path.exists(SESSION_FILE):
        try:
            with open(SESSION_FILE, "r") as f:
                data = json.load(f)
                return data["session_id"]
        except Exception:
            pass
    return init_session()

def init_session():
    init_req = urllib.request.Request(
        BASE_URL,
        data=json.dumps({
            "jsonrpc": "2.0",
            "id": 1,
            "method": "initialize",
            "params": {
                "protocolVersion": "2024-11-05",
                "capabilities": {},
                "clientInfo": {"name": "python-ue-mcp", "version": "1.0"}
            }
        }).encode("utf-8"),
        headers={"Content-Type": "application/json"}
    )
    with urllib.request.urlopen(init_req, timeout=10) as resp:
        session_id = resp.headers.get("Mcp-Session-Id")

    notif_req = urllib.request.Request(
        BASE_URL,
        data=json.dumps({
            "jsonrpc": "2.0",
            "method": "notifications/initialized"
        }).encode("utf-8"),
        headers={"Content-Type": "application/json", "Mcp-Session-Id": session_id}
    )
    with urllib.request.urlopen(notif_req, timeout=10):
        pass

    with open(SESSION_FILE, "w") as f:
        json.dump({"session_id": session_id}, f)
    return session_id

def call_tool(toolset_name, tool_name, arguments=None):
    if arguments is None:
        arguments = {}
    session_id = get_session()
    
    payload = {
        "jsonrpc": "2.0",
        "id": 100,
        "method": "tools/call",
        "params": {
            "name": "call_tool",
            "arguments": {
                "toolset_name": toolset_name,
                "tool_name": tool_name,
                "arguments": arguments
            }
        }
    }
    
    req = urllib.request.Request(
        BASE_URL,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json", "Mcp-Session-Id": session_id}
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            if "result" in data and "content" in data["result"]:
                txt = data["result"]["content"][0]["text"]
                try:
                    return json.loads(txt)
                except Exception:
                    return txt
            return data
    except Exception as e:
        session_id = init_session()
        req = urllib.request.Request(
            BASE_URL,
            data=json.dumps(payload).encode("utf-8"),
            headers={"Content-Type": "application/json", "Mcp-Session-Id": session_id}
        )
        with urllib.request.urlopen(req, timeout=30) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            if "result" in data and "content" in data["result"]:
                txt = data["result"]["content"][0]["text"]
                try:
                    return json.loads(txt)
                except Exception:
                    return txt
            return data

def capture_image(output_path):
    res = call_tool("EditorToolset.EditorAppToolset", "CaptureEditorImage", {})
    raw = res.get("returnValue") or res.get("image") or res
    if isinstance(raw, dict):
        raw = raw.get("data") or raw.get("bytes") or str(raw)
    with open(output_path, "wb") as f:
        f.write(base64.b64decode(raw))
    print(f"Captured editor screenshot to {output_path}")

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "screenshot":
        out = sys.argv[2] if len(sys.argv) > 2 else "screenshot.png"
        capture_image(out)
    elif len(sys.argv) > 2:
        toolset = sys.argv[1]
        tool = sys.argv[2]
        args = json.loads(sys.argv[3]) if len(sys.argv) > 3 else {}
        print(json.dumps(call_tool(toolset, tool, args), indent=2))
    else:
        print("Usage: ue_mcp.py <toolset> <tool> [json_args] OR ue_mcp.py screenshot <out.png>")
