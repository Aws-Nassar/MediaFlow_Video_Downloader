"""Check native folder preview, light mode and Arabic without downloading a folder."""

import argparse
import json
from pathlib import Path
import re
import subprocess
import time
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--adb", required=True)
    parser.add_argument("--serial", default="emulator-5554")
    parser.add_argument("--folder-url")
    parser.add_argument("--expected-items", type=int, default=2)
    args = parser.parse_args()
    if not args.folder_url:
        local_urls = ROOT / "tests/source_urls.txt"
        if not local_urls.is_file():
            parser.error("Supply --folder-url or create the local tests/source_urls.txt file.")
        args.folder_url = next(url for url in local_urls.read_text(encoding="utf-8").splitlines() if "drive.google.com/drive/folders/" in url)
    if not args.serial.startswith("emulator-"):
        raise SystemExit("Only use an isolated emulator.")

    def adb(*commands, binary=False):
        data = subprocess.check_output([args.adb, "-s", args.serial, *commands], timeout=40)
        return data if binary else data.decode("utf-8", errors="replace")

    def dump():
        result = adb("shell", "uiautomator", "dump", "/sdcard/mediaflow-ui.xml")
        assert "dumped" in result
        return ET.fromstring(adb("exec-out", "cat", "/sdcard/mediaflow-ui.xml"))

    def tap(text):
        node = next((node for node in dump().iter("node") if node.get("text") == text), None)
        assert node is not None, f"Missing control: {text}"
        x1, y1, x2, y2 = map(int, re.findall(r"\d+", node.get("bounds")))
        adb("shell", "input", "tap", str((x1 + x2) // 2), str((y1 + y2) // 2))
        time.sleep(1)

    def screenshot(name):
        (ROOT / "build/previews" / name).write_bytes(adb("exec-out", "screencap", "-p", binary=True))

    adb("shell", "input", "keyevent", "KEYCODE_WAKEUP")
    adb("shell", "wm", "dismiss-keyguard")
    adb("shell", "am", "start", "-n", "com.mediaflow.android/.MainActivity", "-a", "android.intent.action.SEND",
        "-t", "text/plain", "--es", "android.intent.extra.TEXT", args.folder_url)
    time.sleep(2)
    tap("Preview link")
    preview_ok = False
    for _ in range(12):
        values = [node.get("text", "") for node in dump().iter("node")]
        if any("Drive folder" in value and f"{args.expected_items} items" in value for value in values):
            preview_ok = True
            break
        time.sleep(1)
    assert preview_ok, "Folder preview failed"
    screenshot("android-drive-preview.png")
    tap("Settings")
    tap("Light mode")
    assert any(node.get("text") == "Appearance" for node in dump().iter("node")), "Theme switch did not retain Settings"
    screenshot("android-light.png")
    tap("Language")
    tap("العربية")
    assert any(node.get("text") == "الإعدادات" for node in dump().iter("node")), "Arabic navigation missing"
    screenshot("android-arabic.png")
    tap("اللغة")
    tap("English")
    tap("Light mode")
    tap("History")
    screenshot("android-dark-history.png")
    report = {"drive_folder_preview": True, "light_mode": True, "arabic_navigation": True, "settings_tab_survives_recreation": True}
    (ROOT / "build/android-validation/ui-result.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
