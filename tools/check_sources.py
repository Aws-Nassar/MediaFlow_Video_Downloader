"""Bounded, anonymous source checks. Never records an entire live stream."""

import argparse
from concurrent.futures import ThreadPoolExecutor
import json
import os
from pathlib import Path
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from download_support import describe_error, redact_details, validate_url
from drive_folders import is_drive_folder, list_drive_folder


def check_one(url, timeout):
    start = time.monotonic()
    try:
        process = subprocess.run([sys.executable, str(Path(__file__).resolve()), "--worker", url],
                                 capture_output=True, text=True, encoding="utf-8", timeout=timeout,
                                 env={**os.environ, "PYTHONIOENCODING": "utf-8"})
        if process.returncode != 0:
            raise RuntimeError(process.stderr or process.stdout)
        result = json.loads(process.stdout)
    except subprocess.TimeoutExpired:
        result = {"ok": False, "code": "TIMEOUT", "error": f"Metadata check exceeded {timeout} seconds"}
    except Exception as exc:
        result = {"ok": False, "code": describe_error(exc).code, "error": redact_details(exc)}
    result.update(url=url, elapsed=round(time.monotonic() - start, 1))
    return result


def worker(url):
    import yt_dlp
    options = {"quiet": True, "no_warnings": True, "skip_download": True, "extract_flat": "in_playlist",
               "socket_timeout": 15, "retries": 1, "extractor_retries": 1, "cachedir": False,
               "noplaylist": True, "playlistend": 10}
    deno = ROOT / "tools" / "deno.exe"
    if deno.is_file():
        options["js_runtimes"] = {"deno": {"path": str(deno)}}
    try:
        if is_drive_folder(url):
            folder = list_drive_folder(url)
            print(json.dumps({"ok": True, "stage": "folder_listing_only", "title": folder["title"],
                              "extractor": "DriveFolder", "entries_checked": len(folder["entries"])}))
            return
        with yt_dlp.YoutubeDL(options) as ydl:
            info = ydl.extract_info(validate_url(url), download=False)
        if not info:
            raise ValueError("The source returned no metadata")
        entries = list(info.get("entries") or [])
        result = {"ok": True, "stage": "metadata_only", "title": info.get("title"),
                  "extractor": info.get("extractor_key"), "is_live": info.get("is_live", False),
                  "formats": len(info.get("formats") or []), "entries_checked": len(entries)}
    except Exception as exc:
        result = {"ok": False, "code": describe_error(exc).code, "error": redact_details(exc)}
    print(json.dumps(result, ensure_ascii=True))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--worker")
    parser.add_argument("--input", type=Path, default=ROOT / "tests/source_urls.txt")
    parser.add_argument("--output", type=Path, default=ROOT / "build/source-checks.json")
    parser.add_argument("--timeout", type=int, default=75)
    args = parser.parse_args()
    if args.worker:
        worker(args.worker)
        return
    if not args.input.is_file():
        parser.error("Provide --input with a local URL file; user sharing links are not committed.")
    urls = [validate_url(line) for line in args.input.read_text(encoding="utf-8").splitlines() if line.strip() and not line.startswith("#")]
    args.output.parent.mkdir(parents=True, exist_ok=True)
    results = []
    with ThreadPoolExecutor(max_workers=3) as pool:
        for result in pool.map(lambda url: check_one(url, args.timeout), urls):
            results.append(result)
            print(f'{len(results)}/{len(urls)} {"METADATA OK" if result["ok"] else result["code"]}: {result["url"]}', flush=True)
            args.output.write_text(json.dumps({"yt_dlp": __import__("yt_dlp.version", fromlist=["__version__"]).__version__,
                                              "anonymous": True, "checks": results}, indent=2), encoding="utf-8")
    print(f'Report saved: {args.output}')


if __name__ == "__main__":
    main()
