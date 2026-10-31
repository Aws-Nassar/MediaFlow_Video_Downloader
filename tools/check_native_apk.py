"""Exercise the installed APK on an isolated Android emulator using a local file."""

import argparse
import hashlib
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
import re
import subprocess
import threading
import time
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
PAYLOAD = bytes(range(256)) * 4096
PACKAGE = "com.mediaflow.android"


class FileServer(BaseHTTPRequestHandler):
    def log_message(self, *_):
        pass

    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-Type", "application/zip")
        self.send_header("Content-Disposition", 'attachment; filename="native-integrity.zip"')
        self.send_header("Content-Length", str(len(PAYLOAD)))
        self.end_headers()
        self.wfile.write(PAYLOAD)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--adb", type=Path, required=True)
    parser.add_argument("--serial", default="emulator-5554")
    args = parser.parse_args()
    if not args.serial.startswith("emulator-"):
        raise SystemExit("This check is restricted to emulator sessions.")

    def adb(*arguments, binary=False):
        data = subprocess.check_output([str(args.adb), "-s", args.serial, *arguments], timeout=40)
        return data if binary else data.decode("utf-8", errors="replace")

    server = ThreadingHTTPServer(("127.0.0.1", 0), FileServer)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    try:
        adb("shell", "input", "keyevent", "KEYCODE_WAKEUP")
        adb("shell", "wm", "dismiss-keyguard")
        adb("shell", "settings", "put", "system", "screen_off_timeout", "1800000")
        adb("shell", "pm", "grant", PACKAGE, "android.permission.POST_NOTIFICATIONS")
        link = f"http://10.0.2.2:{server.server_port}/native-integrity.zip"
        adb("shell", "am", "start", "-n", PACKAGE + "/.MainActivity", "-a", "android.intent.action.SEND",
            "-t", "text/plain", "--es", "android.intent.extra.TEXT", link)
        time.sleep(2)
        dumped = adb("shell", "uiautomator", "dump", "/sdcard/mediaflow-validation.xml")
        if "dumped" not in dumped:
            raise AssertionError("Could not inspect the emulator UI; no stale XML will be used")
        xml = adb("exec-out", "cat", "/sdcard/mediaflow-validation.xml")
        root = ET.fromstring(xml)
        node = next((node for node in root.iter("node") if node.get("text") == "Add to downloads"), None)
        if node is None:
            raise AssertionError("Native download button is missing")
        x1, y1, x2, y2 = map(int, re.findall(r"\d+", node.get("bounds")))
        adb("shell", "input", "tap", str((x1 + x2) // 2), str((y1 + y2) // 2))
        job = None
        for _ in range(30):
            time.sleep(1)
            try:
                jobs = json.loads(adb("exec-out", "run-as", PACKAGE, "cat", "files/downloads.json"))
                job = next((j for j in jobs if j["url"] == link), None)
                if job and job["state"] in ["completed", "failed", "cancelled"]:
                    break
            except (subprocess.CalledProcessError, json.JSONDecodeError):
                pass
        if not job or job["state"] != "completed":
            raise AssertionError(f"APK file transfer did not complete: {job}")
        # The shell can read emulated external storage; run-as has a different storage mount.
        saved = adb("exec-out", "cat", job["files"][0], binary=True)
        assert hashlib.sha256(saved).digest() == hashlib.sha256(PAYLOAD).digest(), "Saved file is corrupt"
        preview = ROOT / "build/previews"
        preview.mkdir(parents=True, exist_ok=True)
        (preview / "android-dark.png").write_bytes(adb("exec-out", "screencap", "-p", binary=True))
        result = {"native_launch": True, "share_intent": True, "queued_download": True,
                  "completed_file_sha256": hashlib.sha256(saved).hexdigest(), "bytes": len(saved)}
        (ROOT / "build/android-validation/result.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
        print(json.dumps(result, indent=2))
    finally:
        server.shutdown()
        server.server_close()


if __name__ == "__main__":
    main()
