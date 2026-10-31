"""Public Drive folder enumeration and original-file downloads.

Uses Drive's public embedded folder view. Server access restrictions still apply.
"""

from html.parser import HTMLParser
from http.cookiejar import MozillaCookieJar
from pathlib import Path
import re
from urllib.parse import urlencode, urlsplit
from urllib.request import HTTPCookieProcessor, Request, build_opener

from download_support import DownloadCancelled, download_direct, validate_url


def is_drive_folder(url):
    p = urlsplit(url)
    return p.hostname in {"drive.google.com", "docs.google.com"} and bool(re.fullmatch(r"/drive/(?:u/\d+/)?folders/[\w-]+/?", p.path))


class FolderPage(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.links = []
        self.title = ""
        self._title = False
        self._href = None
        self._name = []

    def handle_starttag(self, tag, attrs):
        if tag == "title":
            self._title = True
        if tag == "a":
            self._href = dict(attrs).get("href")
            self._name = []

    def handle_data(self, data):
        if self._title:
            self.title += data
        if self._href is not None:
            self._name.append(data)

    def handle_endtag(self, tag):
        if tag == "title":
            self._title = False
        if tag == "a" and self._href is not None:
            self.links.append((self._href, "".join(self._name).strip()))
            self._href = None


def safe_name(name):
    name = re.sub(r'[\\/:*?"<>|\x00-\x1f]', "_", name).strip(". ")[:120] or "Untitled"
    if name.split(".")[0].upper() in {"CON", "PRN", "AUX", "NUL", *[f"COM{i}" for i in range(1, 10)], *[f"LPT{i}" for i in range(1, 10)]}:
        name = "_" + name
    return name


def list_drive_folder(url, cookie_file=""):
    if not is_drive_folder(validate_url(url)):
        raise ValueError("Invalid Google Drive folder URL")
    folder_id = urlsplit(url).path.rstrip("/").split("/")[-1]
    jar = MozillaCookieJar()
    if cookie_file:
        jar = MozillaCookieJar(cookie_file)
        jar.load(ignore_discard=True, ignore_expires=True)
    request = Request("https://drive.google.com/embeddedfolderview?" + urlencode({"id": folder_id}),
                      headers={"User-Agent": "Mozilla/5.0"})
    with build_opener(HTTPCookieProcessor(jar)).open(request, timeout=25) as response:
        page = response.read(8 * 1024 * 1024 + 1)
        if len(page) > 8 * 1024 * 1024:
            raise ValueError("Folder listing is too large. Open a smaller subfolder.")
        if urlsplit(response.url).hostname == "accounts.google.com":
            raise PermissionError("Login required to list this Drive folder")
    parser = FolderPage()
    parser.feed(page.decode("utf-8", errors="replace"))
    entries = []
    seen = set()
    for href, name in parser.links:
        p = urlsplit(href)
        if p.hostname not in {"drive.google.com", "docs.google.com"}:
            continue
        match = re.search(r"/(?:file/d|folders|document/d|spreadsheets/d|presentation/d)/([\w-]+)", p.path)
        if not match or match[1] in seen:
            continue
        seen.add(match[1])
        folder = "/folders/" in p.path
        entries.append({"id": match[1], "name": safe_name(name or match[1]), "url": href, "folder": folder})
    if not parser.title or "sign in" in parser.title.lower() or "request access" in parser.title.lower():
        raise PermissionError("Login required or access denied for this Drive folder")
    # Never treat an unexpected/login page as a successfully enumerated empty folder.
    if not entries and "flip-entries" not in page.decode("utf-8", errors="replace"):
        raise ValueError("Drive folder contents are unavailable. Check sharing permissions or try a smaller public subfolder.")
    return {"id": folder_id, "title": safe_name(parser.title), "entries": entries}


def download_drive_folder(url, output_dir, progress, cancel_event, cookie_file="", on_file=None, media_fallback=None):
    root = list_drive_folder(url, cookie_file)
    destination = Path(output_dir) / "Drive" / f'{root["title"]} [{root["id"][:8]}]'
    files = []
    visited = set()

    def visit(folder, directory, depth=0):
        if depth > 40 or len(visited) > 1000 or len(files) > 10000:
            raise ValueError("Folder is too large for one job. Download its subfolders separately.")
        if folder["id"] in visited:
            return
        visited.add(folder["id"])
        directory.mkdir(parents=True, exist_ok=True)
        for entry in folder["entries"]:
            if cancel_event.is_set():
                raise DownloadCancelled()
            if entry["folder"]:
                visit(list_drive_folder(entry["url"], cookie_file), directory / f'{entry["name"]} [{entry["id"][:8]}]', depth + 1)
                continue
            p = urlsplit(entry["url"])
            if p.hostname == "docs.google.com":
                kind = p.path.strip("/").split("/")[0]
                ext = {"document": "pdf", "spreadsheets": "xlsx", "presentation": "pptx"}.get(kind)
                if ext is None:
                    raise ValueError(f"This Drive document type needs an export handler: {kind}")
                download_url = f'https://docs.google.com/{kind}/d/{entry["id"]}/export?format={ext}'
                filename = entry["name"] + "." + ext
            else:
                download_url = "https://drive.usercontent.google.com/download?" + urlencode({"id": entry["id"], "export": "download", "confirm": "t"})
                filename = entry["name"]
            try:
                path = download_direct(download_url, directory, progress, cancel_event,
                                       target_dir=directory, target_name=safe_name(f'{entry["id"][:8]} - {filename}'), cookie_file=cookie_file)
                saved = [path]
            except (PermissionError, OSError) as exc:
                # Public playback can remain available when the original-file endpoint refuses a video.
                # Authentication and the media source's own restrictions still apply.
                if media_fallback is None or "403" not in str(exc) or p.hostname == "docs.google.com":
                    raise
                saved = media_fallback(entry, directory)
                if not saved:
                    raise ValueError("The source returned no completed playback files")
            files.extend(saved)
            if on_file:
                for path in saved:
                    on_file(path)
    visit(root, destination)
    return files
