"""File transfers and actionable errors, independent of the desktop UI."""

from dataclasses import dataclass
from email.message import Message
import hashlib
import http.client
import json
import os
from pathlib import Path
import re
import socket
import time
from urllib.error import HTTPError, URLError
from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit
from urllib.request import Request, urlopen
from urllib.request import HTTPCookieProcessor, build_opener
from http.cookiejar import MozillaCookieJar


class DownloadCancelled(Exception):
    pass


def validate_url(value):
    value = str(value).strip()
    try:
        parsed = urlsplit(value)
        valid = parsed.scheme.lower() in {"http", "https"} and parsed.hostname and parsed.port != 0
    except ValueError:
        valid = False
    if not valid or any(c.isspace() for c in value):
        raise ValueError("Invalid URL. Paste a complete http:// or https:// link.")
    if parsed.username is not None or parsed.password is not None:
        raise ValueError("URLs containing passwords are not supported.")
    return value


def redact_details(raw):
    def redact_url(match):
        try:
            p = urlsplit(match[0])
            return urlunsplit((p.scheme, p.hostname or "", p.path, "[redacted]" if p.query else "", ""))
        except ValueError:
            return "[URL]"
    text = re.sub(r"\x1b\[[0-9;]*m", "", str(raw))
    text = re.sub(r'https?://[^\s<>\"]+', redact_url, text)
    return re.sub(r"(?im)(authorization|cookie|token|password)\s*[:=]\s*[^\r\n]+", r"\1=[redacted]", text)[-5000:]


@dataclass(frozen=True)
class DownloadFailure:
    code: str
    title: str
    message: str
    actions: tuple


def describe_error(error):
    message = str(error).lower()
    cases = [
        (("no space", "enospc", "errno 28"), "DISK_FULL", "Storage is full", "There is not enough free space to finish saving this file.", ("Free up space in the save folder", "Retry to resume available partial files")),
        (("429", "rate limit", "too many requests"), "RATE_LIMIT", "The source is limiting requests", "The source has temporarily limited downloads.", ("Wait before retrying", "Reduce concurrent downloads")),
        (("permission denied", "errno 13", "access is denied"), "PERMISSION", "Cannot write to the save folder", "The app cannot create or update files in this location.", ("Choose a writable save folder", "Check free space and file permissions")),
        (("invalid url", "urls containing passwords"), "INVALID_INPUT", "Check the download link", "Paste a complete HTTP or HTTPS link without embedded passwords.", ("Copy the complete link from your browser",)),
        (("drm",), "DRM", "Protected media", "The source uses DRM-protected media.", ("Use the source's supported offline viewing feature",)),
        (("403", "forbidden", "candownload"), "ACCESS_DENIED", "The source denied access", "The server refused this download. Login or download restrictions may apply.", ("Check sharing permissions", "Refresh login cookies for content you can access")),
        (("401", "sign in", "private", "login", "cookies"), "LOGIN_REQUIRED", "This link needs your account", "The source requires an authenticated session.", ("Choose browser cookies in Settings", "Or import a Netscape-format cookies.txt file")),
        (("404", "removed", "expired", "not found"), "UNAVAILABLE", "The link is unavailable", "The file or post may have been removed, or its link expired.", ("Open the link in your browser", "Copy a fresh sharing link")),
        (("javascript", "challenge", "nsig", "js runtime"), "EXTRACTOR_UPDATE", "The source changed its player", "The media extractor or JavaScript runtime needs attention.", ("Update yt-dlp and its EJS scripts", "Install Deno or a supported JavaScript runtime")),
        (("ffmpeg", "ffprobe"), "PROCESSING", "Media processing failed", "FFmpeg is needed to merge streams and convert audio or video.", ("Check the FFmpeg path in Settings", "Try another format and check free space")),
        (("unsupported url", "no suitable extractor", "cloud folder"), "UNSUPPORTED", "This link needs another source handler", "This source or folder is not handled by the current downloader.", ("Try a direct file link in Original file mode", "Cloud folders need a dedicated integration")),
        (("requested format", "no video", "not a video"), "FORMAT_UNAVAILABLE", "That media format is unavailable", "The source did not provide a matching playable stream.", ("Choose Best Available", "Try Audio mode or check the post URL")),
        (("timeout", "timed out", "connection", "resolve", "network", "incomplete"), "NETWORK", "Connection interrupted", "The connection ended before the operation completed.", ("Check your connection", "Retry; compatible partial downloads can resume")),
    ]
    for needles, code, title, description, actions in cases:
        if any(needle in message for needle in needles):
            return DownloadFailure(code, title, description, actions)
    return DownloadFailure("DOWNLOAD_FAILED", "Download failed", "The app could not finish this download.", ("Check the link in your browser", "Retry or update the download engine", "Read the error details below"))


def is_direct_url(url):
    p = urlsplit(url)
    return (p.hostname == "raw.githubusercontent.com"
            or p.hostname == "github.com" and "/releases/download/" in p.path
            or bool(re.search(r"\.(zip|7z|rar|pdf|docx?|xlsx?|pptx?|apk|exe|iso|tar|gz|txt|csv|json|png|jpe?g|webp)$", p.path, re.I)))


def normalize_file_url(url):
    p = urlsplit(validate_url(url))
    if p.hostname in {"drive.google.com", "docs.google.com"}:
        match = re.search(r"/file/d/([\w-]+)", p.path)
        if match:
            return "https://drive.usercontent.google.com/download?" + urlencode({"id": match[1], "export": "download", "confirm": "t"})
    if p.hostname == "github.com" and "/blob/" in p.path:
        return urlunsplit(("https", "raw.githubusercontent.com", p.path.replace("/blob/", "/", 1), p.query, ""))
    if p.hostname in {"dropbox.com", "www.dropbox.com"}:
        query = [(k, v) for k, v in parse_qsl(p.query, keep_blank_values=True) if k not in {"dl", "raw"}]
        return urlunsplit((p.scheme, p.netloc, p.path, urlencode(query + [("dl", "1")]), ""))
    return url


def _open(url, headers=None, method="GET", cookie_file=""):
    request = Request(normalize_file_url(url), headers={"User-Agent": "MediaFlow/2.2", "Accept-Encoding": "identity", **(headers or {})}, method=method)
    opener = urlopen
    if cookie_file:
        jar = MozillaCookieJar(cookie_file)
        jar.load(ignore_discard=True, ignore_expires=True)
        opener = build_opener(HTTPCookieProcessor(jar)).open
    response = opener(request, timeout=25)
    validate_url(response.url)
    if response.headers.get_content_type() in {"text/html", "application/xhtml+xml"} and not response.headers.get("Content-Disposition"):
        drive_original = urlsplit(response.url).hostname in {"drive.usercontent.google.com", "drive.google.com", "docs.google.com"}
        response.close()
        if drive_original:
            raise PermissionError("HTTP 403: Google Drive did not provide the original file. Use Video mode to try an available playback copy, or check download permissions.")
        raise ValueError("This link is a web page, not a direct file. Use Video mode for media pages, or check the file's sharing permissions.")
    return response


def _filename(response, url):
    disposition = Message()
    disposition["Content-Disposition"] = response.headers.get("Content-Disposition", "")
    raw = disposition.get_filename() or Path(urlsplit(url).path).name or "download"
    safe = re.sub(r'[\\/:*?"<>|\x00-\x1f]', "_", raw).strip(". ")
    if not safe:
        safe = "download"
    if safe.split(".")[0].upper() in {"CON", "PRN", "AUX", "NUL", *[f"COM{i}" for i in range(1, 10)], *[f"LPT{i}" for i in range(1, 10)]}:
        safe = "_" + safe
    # Preserve the extension while limiting path length.
    suffix = Path(safe).suffix[:20]
    return safe[:160 - len(suffix)] + suffix if len(safe) > 160 else safe


def fetch_direct_info(url, cookie_file=""):
    try:
        response = _open(url, method="HEAD", cookie_file=cookie_file)
    except HTTPError as error:
        if error.code not in {405, 501}:
            raise
        response = _open(url, {"Range": "bytes=0-0"}, cookie_file=cookie_file)
    with response:
        return {"title": _filename(response, url), "extractor": "Direct file", "extractor_key": "DirectFile",
                "webpage_url": url, "filesize": int(response.headers.get("Content-Length", 0)),
                "formats": [], "url": url, "is_direct_file": True}


def download_direct(url, output_dir, progress, cancel_event, retries=3, *, target_dir=None, target_name=None, cookie_file=""):
    """Stream to a partial file; only resume with a matching server validator."""
    validate_url(url)
    directory = Path(target_dir) if target_dir is not None else Path(output_dir) / "Files" / hashlib.sha256(url.encode()).hexdigest()[:16]
    directory.mkdir(parents=True, exist_ok=True)
    response = None
    for attempt in range(retries):
        if cancel_event.is_set():
            raise DownloadCancelled()
        try:
            response = _open(url, cookie_file=cookie_file)
            target = directory / (target_name or _filename(response, url))
            partial = target.with_name(target.name + ".part")
            metadata = partial.with_name(partial.name + ".json")
            validator = response.headers.get("ETag") or response.headers.get("Last-Modified")
            # Weak ETags are not valid If-Range validators.
            if validator and validator.startswith("W/"):
                validator = None
            previous = {}
            try:
                previous = json.loads(metadata.read_text(encoding="utf-8"))
            except (OSError, ValueError):
                pass
            offset = partial.stat().st_size if partial.is_file() else 0
            if offset and validator and previous.get("validator") == validator:
                response.close()
                response = _open(url, {"Range": f"bytes={offset}-", "If-Range": validator}, cookie_file=cookie_file)
                content_range = response.headers.get("Content-Range", "")
                if response.status != 206 or not content_range.startswith(f"bytes {offset}-"):
                    offset = 0
                    if response.status == 206:
                        response.close()
                        response = _open(url, cookie_file=cookie_file)
            else:
                offset = 0
            length = response.headers.get("Content-Length")
            total = offset + int(length) if length is not None else None
            metadata.write_text(json.dumps({"validator": validator}), encoding="utf-8")
            done = offset
            start = time.monotonic()
            last_update = 0
            with response, partial.open("ab" if offset else "wb") as output:
                while True:
                    if cancel_event.is_set():
                        raise DownloadCancelled()
                    data = response.read(128 * 1024)
                    if not data:
                        break
                    output.write(data)
                    done += len(data)
                    now = time.monotonic()
                    if now - last_update > 0.2:
                        speed = (done - offset) / max(0.01, now - start)
                        progress({"status": "downloading", "downloaded_bytes": done, "total_bytes": total,
                                  "speed": speed, "eta": (total - done) / speed if total and speed else None})
                        last_update = now
                output.flush()
                os.fsync(output.fileno())
            if total is not None and done != total:
                raise OSError("Connection interrupted: incomplete file")
            if cancel_event.is_set():
                raise DownloadCancelled()
            # Keep any existing completed file; use a distinct name for a new transfer.
            destination = target
            number = 1
            while destination.exists():
                destination = target.with_name(f"{target.stem} ({number}){target.suffix}")
                number += 1
            partial.replace(destination)
            metadata.unlink(missing_ok=True)
            return str(destination)
        except (URLError, TimeoutError, socket.timeout, ConnectionError, http.client.IncompleteRead, OSError) as error:
            if isinstance(error, PermissionError):
                raise
            if isinstance(error, HTTPError) and error.code not in {408, 429, 500, 502, 503, 504}:
                raise
            if attempt + 1 >= retries:
                raise
            if cancel_event.wait(min(2 ** attempt, 8)):
                raise DownloadCancelled() from None
        finally:
            if response is not None:
                response.close()
