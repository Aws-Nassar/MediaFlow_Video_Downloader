from pathlib import Path
import tempfile
import threading
import unittest
from unittest.mock import patch

from drive_folders import FolderPage, download_drive_folder, safe_name


class DriveFolderChecks(unittest.TestCase):
    def test_folder_markup_keeps_unicode_and_nested_link_text(self):
        parser = FolderPage()
        parser.feed('<title>Shared &amp; visible</title><a href="https://drive.google.com/file/d/abc/view"><span>ملف</span>.mp4</a>')
        self.assertEqual(parser.title, "Shared & visible")
        self.assertEqual(parser.links[0][1], "ملف.mp4")
        self.assertNotIn("/", safe_name("../../unsafe/video.mp4"))

    def test_denied_original_can_use_an_available_playback_copy(self):
        entry = {"id": "file1234", "name": "video.mp4", "url": "https://drive.google.com/file/d/file1234/view", "folder": False}
        folder = {"id": "folder123", "title": "Videos", "entries": [entry]}
        with tempfile.TemporaryDirectory() as temporary:
            def playback(item, directory):
                self.assertEqual(item["id"], "file1234")
                path = directory / "playback.mp4"
                path.write_bytes(b"verified playable copy")
                return [str(path)]
            with patch("drive_folders.list_drive_folder", return_value=folder), patch("drive_folders.download_direct", side_effect=PermissionError("HTTP 403")):
                paths = download_drive_folder("https://drive.google.com/drive/folders/folder123", temporary,
                                              lambda _: None, threading.Event(), media_fallback=playback)
            self.assertEqual(len(paths), 1)
            self.assertTrue(Path(paths[0]).resolve().is_relative_to(Path(temporary).resolve()))

    def test_original_only_does_not_silently_substitute_a_playback_copy(self):
        folder = {"id": "folder123", "title": "Videos", "entries": [
            {"id": "file1234", "name": "video.mp4", "url": "https://drive.google.com/file/d/file1234/view", "folder": False}]}
        with tempfile.TemporaryDirectory() as temporary, patch("drive_folders.list_drive_folder", return_value=folder), patch("drive_folders.download_direct", side_effect=PermissionError("HTTP 403")):
            with self.assertRaises(PermissionError):
                download_drive_folder("https://drive.google.com/drive/folders/folder123", temporary, lambda _: None, threading.Event())


if __name__ == "__main__":
    unittest.main()
