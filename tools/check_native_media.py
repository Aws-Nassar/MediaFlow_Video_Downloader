"""Download one short test video in an isolated emulator and inspect its streams."""

import argparse
import json
from pathlib import Path
import re
import subprocess
import time
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = "com.mediaflow.android"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--adb", required=True)
    parser.add_argument("--serial", default="emulator-5554")
    parser.add_argument("--url")
    parser.add_argument("--timeout", type=int, default=150)
    args = parser.parse_args()
    if not args.url:
        local_urls = ROOT / "tests/source_urls.txt"
        if not local_urls.is_file():
            parser.error("Supply --url with a short test video or create the local tests/source_urls.txt file.")
        args.url = next(url for url in local_urls.read_text(encoding="utf-8").splitlines() if "youtube.com/shorts/" in url)
    if not args.serial.startswith("emulator-"):
        raise SystemExit("This tool only runs against an isolated emulator.")

    def adb(*commands, binary=False):
        data = subprocess.check_output([args.adb, "-s", args.serial, *commands], timeout=40)
        return data if binary else data.decode("utf-8", errors="replace")

    def tap(label):
        result = adb("shell", "uiautomator", "dump", "/sdcard/mediaflow-media.xml")
        if "dumped" not in result:
            raise AssertionError("Cannot read current emulator UI")
        root = ET.fromstring(adb("exec-out", "cat", "/sdcard/mediaflow-media.xml"))
        node = next((node for node in root.iter("node") if node.get("text") == label), None)
        if node is None:
            raise AssertionError(f"Missing UI control: {label}")
        x1, y1, x2, y2 = map(int, re.findall(r"\d+", node.get("bounds")))
        adb("shell", "input", "tap", str((x1 + x2) // 2), str((y1 + y2) // 2))

    adb("shell", "input", "keyevent", "KEYCODE_WAKEUP")
    adb("shell", "wm", "dismiss-keyguard")
    adb("shell", "am", "start", "-n", PACKAGE + "/.MainActivity", "-a", "android.intent.action.SEND",
        "-t", "text/plain", "--es", "android.intent.extra.TEXT", args.url)
    time.sleep(2)
    tap("Best")
    time.sleep(1)
    tap("360p")
    tap("Add to downloads")
    # Verify the foreground service continues when the Activity is not visible.
    adb("shell", "input", "keyevent", "KEYCODE_HOME")
    job = None
    for _ in range(args.timeout // 2):
        time.sleep(2)
        jobs = json.loads(adb("exec-out", "run-as", PACKAGE, "cat", "files/downloads.json"))
        job = next((job for job in reversed(jobs) if job["url"] == args.url), None)
        if job and job["state"] in ["completed", "failed", "cancelled"]:
            break
    result = {"url": args.url, "background_download": True, "state": job.get("state") if job else "not_queued"}
    if job and job["state"] == "completed":
        destination = ROOT / "build/media-samples/android-media.mp4"
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(adb("exec-out", "cat", job["files"][0], binary=True))
        media = json.loads(subprocess.check_output(["ffprobe", "-v", "error", "-show_entries", "stream=codec_type:format=duration", "-of", "json", str(destination)], text=True))
        result["streams"] = [stream["codec_type"] for stream in media.get("streams", [])]
        result["duration"] = media.get("format", {}).get("duration")
        result["bytes"] = destination.stat().st_size
        result["ok"] = "video" in result["streams"] and "audio" in result["streams"]
    else:
        result.update(ok=False, details=job.get("details") if job else "No queued job")
        adb("shell", "am", "force-stop", PACKAGE)
    (ROOT / "build/android-validation/media-result.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
    print(json.dumps(result, indent=2))
    if not result["ok"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
