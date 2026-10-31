"""Save five-second samples through the desktop options and inspect their streams."""

from concurrent.futures import ThreadPoolExecutor
import argparse
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from app import build_ydl_opts
from download_support import describe_error, redact_details


def sample(url, name):
    import yt_dlp
    from yt_dlp.utils import download_range_func
    directory = ROOT / "build/media-samples" / name
    directory.mkdir(parents=True, exist_ok=True)
    paths = []
    options = build_ydl_opts({}, str(directory), "mp4", "360p", False, lambda _: None)
    options.update({"download_ranges": download_range_func(None, [(0, 5)]), "force_keyframes_at_cuts": False,
                    "socket_timeout": 15, "retries": 1, "fragment_retries": 1, "extractor_retries": 1,
                    "post_hooks": [paths.append]})
    try:
        with yt_dlp.YoutubeDL(options) as ydl:
            ydl.extract_info(url, download=True)
        if not paths:
            raise ValueError("No completed sample file")
        probe = subprocess.check_output(["ffprobe", "-v", "error", "-show_entries", "stream=codec_type:format=duration",
                                         "-of", "json", paths[-1]], text=True, timeout=20)
        media = json.loads(probe)
        types = [stream["codec_type"] for stream in media.get("streams", [])]
        if "video" not in types or "audio" not in types:
            raise ValueError("Sample must contain both video and audio")
        return {"name": name, "url": url, "ok": True, "streams": types,
                "duration": media.get("format", {}).get("duration"), "bytes": Path(paths[-1]).stat().st_size}
    except Exception as exc:
        return {"name": name, "url": url, "ok": False, "code": describe_error(exc).code, "error": redact_details(exc)}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--drive-only", action="store_true")
    parser.add_argument("--input", type=Path, default=ROOT / "tests/source_urls.txt")
    args = parser.parse_args()
    if not args.input.is_file():
        parser.error("Provide a local URL file with --input; tests/source_urls.txt is intentionally not committed.")
    urls = [url.strip() for url in args.input.read_text(encoding="utf-8").splitlines() if url.strip()]
    checks = []
    if not args.drive_only:
        for pattern, name in [("youtube.com/shorts/", "youtube-short"), ("facebook.com/reel/", "facebook-reel"), ("tiktok.com/", "tiktok")]:
            match = next((url for url in urls if pattern in url), None)
            if match:
                checks.append((match, name))
    if args.drive_only:
        from drive_folders import is_drive_folder, list_drive_folder
        folders = [url for url in urls if is_drive_folder(url)]
        if not folders:
            parser.error("No Drive folder URL was found in the input file.")
        folder = list_drive_folder(folders[-1])
        checks = [(folder["entries"][0]["url"], "drive-playback")]
    if not checks:
        parser.error("No matching short-video test links were found in the input file.")
    results = []
    with ThreadPoolExecutor(max_workers=2) as pool:
        for result in pool.map(lambda check: sample(*check), checks):
            results.append(result)
            print(json.dumps(result), flush=True)
    report = ROOT / "build/media-sample-checks.json"
    if args.drive_only and report.exists():
        results = [item for item in json.loads(report.read_text()) if item["name"] != "drive-playback"] + results
    report.write_text(json.dumps(results, indent=2), encoding="utf-8")
