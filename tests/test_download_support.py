"""Real local HTTP transfers exercise integrity, cancellation, and safe naming."""

import hashlib
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
import socket
import tempfile
import threading
import unittest

from download_support import DownloadCancelled, describe_error, download_direct, fetch_direct_info, redact_details, validate_url


DATA = bytes(range(256)) * 4096


class Handler(BaseHTTPRequestHandler):
    counts = {}
    ranges = []
    protocol_version = "HTTP/1.1"

    def log_message(self, *_):
        pass

    def do_HEAD(self):
        self.send_response(200)
        self.send_header("Content-Type", "application/octet-stream")
        self.send_header("Content-Length", str(len(DATA)))
        self.send_header("Content-Disposition", "attachment; filename*=UTF-8''%D9%85%D9%84%D9%81.zip")
        self.end_headers()

    def do_GET(self):
        self.counts[self.path] = self.counts.get(self.path, 0) + 1
        if self.path == "/html":
            self.send_response(200)
            self.send_header("Content-Type", "text/html")
            self.send_header("Content-Length", "0")
            self.end_headers()
            return
        offset = int(self.headers.get("Range", "bytes=0-").split("=")[1].split("-")[0])
        if self.headers.get("Range"):
            self.ranges.append(offset)
        self.send_response(206 if offset else 200)
        self.send_header("Content-Type", "application/octet-stream")
        self.send_header("Content-Length", str(len(DATA) - offset))
        self.send_header("ETag", '"test-v1"')
        self.send_header("Content-Disposition", 'attachment; filename="../unsafe.zip"')
        if offset:
            self.send_header("Content-Range", f"bytes {offset}-{len(DATA) - 1}/{len(DATA)}")
        self.end_headers()
        content = DATA[offset:]
        if self.path == "/interrupt" and self.counts[self.path] == 1:
            self.wfile.write(content[:256 * 1024])
            self.wfile.flush()
            self.connection.shutdown(socket.SHUT_RDWR)
            self.connection.close()
            return
        try:
            self.wfile.write(content)
        except (BrokenPipeError, ConnectionError):
            pass


class Transfers(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
        threading.Thread(target=cls.server.serve_forever, daemon=True).start()
        cls.url = f"http://127.0.0.1:{cls.server.server_port}"

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()

    def test_complete_file_and_filename_cannot_escape_destination(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(download_direct(self.url + "/file", folder, lambda _: None, threading.Event()))
            self.assertTrue(path.resolve().is_relative_to(Path(folder).resolve()))
            self.assertEqual(hashlib.sha256(path.read_bytes()).digest(), hashlib.sha256(DATA).digest())
            self.assertFalse(list(Path(folder).rglob("*.part")))

    def test_disconnect_retries_and_resumes_without_corruption(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(download_direct(self.url + "/interrupt", folder, lambda _: None, threading.Event()))
            self.assertEqual(path.read_bytes(), DATA)
            self.assertIn(256 * 1024, Handler.ranges)

    def test_html_is_not_reported_as_a_downloaded_file(self):
        with tempfile.TemporaryDirectory() as folder:
            with self.assertRaisesRegex(ValueError, "web page"):
                download_direct(self.url + "/html", folder, lambda _: None, threading.Event())
            self.assertFalse(list(Path(folder).rglob("*.part")))

    def test_cancel_keeps_partial_without_finalizing(self):
        event = threading.Event()
        with tempfile.TemporaryDirectory() as folder:
            with self.assertRaises(DownloadCancelled):
                download_direct(self.url + "/cancel", folder, lambda _: event.set(), event)
            files = list(Path(folder).rglob("*.part"))
            self.assertEqual(len(files), 1)
            self.assertFalse(list(Path(folder).rglob("*.zip")))

    def test_existing_file_is_preserved(self):
        with tempfile.TemporaryDirectory() as folder:
            first = Path(download_direct(self.url + "/duplicates", folder, lambda _: None, threading.Event()))
            first.write_bytes(b"keep my file")
            second = Path(download_direct(self.url + "/duplicates", folder, lambda _: None, threading.Event()))
            self.assertNotEqual(first, second)
            self.assertEqual(first.read_bytes(), b"keep my file")
            self.assertEqual(second.read_bytes(), DATA)

    def test_international_download_filename(self):
        self.assertEqual(fetch_direct_info(self.url + "/metadata")["title"], "ملف.zip")

    def test_only_http_links_are_accepted(self):
        for url in ["file:///C:/secret", "ftp://example.com/a", "javascript:alert(1)", "https://user:password@example.com", "https://", "bad link"]:
            with self.subTest(url=url), self.assertRaises(ValueError):
                validate_url(url)

    def test_error_details_do_not_expose_signed_tokens(self):
        details = redact_details("Failed https://example.org/file?token=secret#fragment\nAuthorization: Bearer sensitive")
        self.assertNotIn("secret", details)
        self.assertNotIn("sensitive", details)

    def test_storage_and_login_errors_have_different_actions(self):
        self.assertEqual(describe_error("[Errno 28] No space left on device").code, "DISK_FULL")
        self.assertEqual(describe_error("HTTP Error 429").code, "RATE_LIMIT")
        self.assertEqual(describe_error("You must login first").code, "LOGIN_REQUIRED")


if __name__ == "__main__":
    unittest.main()
