import hashlib
import importlib.util
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
from unittest.mock import patch
import urllib.error


ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("updater", ROOT / "scripts/update-resh.py")
updater = importlib.util.module_from_spec(spec)
spec.loader.exec_module(updater)


class ReleaseUpdates(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        (self.root / "Formula").mkdir()
        (self.root / "templates").mkdir()
        shutil.copy(ROOT / "templates/resh.rb.in", self.root / "templates/resh.rb.in")
        self.formula = self.root / "Formula/resh.rb"
        self.release = {"tag_name": "v0.1.0", "draft": False, "prerelease": False, "immutable": True}
        self.archives = {name: name.encode() for name in updater.ARCHIVES.values()}
        self.digests = {name: hashlib.sha256(data).hexdigest() for name, data in self.archives.items()}
        self.failed_attestation = None
        self.corrupt_checksum = False
        self.enterContext(patch.object(updater, "ROOT", self.root))
        self.enterContext(patch.object(updater, "github", side_effect=self.github))
        self.enterContext(patch.object(updater, "run", side_effect=self.gh))

    def github(self, path):
        if path == "releases/latest":
            return self.release
        if path == "commits/v0.1.0":
            return {"sha": "a" * 40}
        raise AssertionError(path)

    def gh(self, *arguments):
        if arguments[:3] == ("gh", "release", "download"):
            directory = Path(arguments[arguments.index("--dir") + 1])
            for name, data in self.archives.items():
                (directory / name).write_bytes(data)
            manifest = dict(self.digests)
            if self.corrupt_checksum:
                manifest["resh-macos-arm64.tar.gz"] = "0" * 64
            (directory / "checksums.txt").write_text("".join(f"{digest}  {name}\n" for name, digest in manifest.items()))
        elif arguments[:3] == ("gh", "attestation", "verify"):
            if Path(arguments[3]).name == self.failed_attestation:
                raise subprocess.CalledProcessError(1, arguments)
        else:
            raise AssertionError(arguments)

    def test_verified_release(self):
        updater.update()
        text = self.formula.read_text()
        self.assertIn('version "0.1.0"', text)
        for digest in self.digests.values():
            self.assertIn(f'sha256 "{digest}"', text)
        updater.update()
        self.assertEqual(self.formula.read_text(), text)

    def test_untrusted_provenance(self):
        for name in ["checksums.txt", *self.archives]:
            with self.subTest(asset=name):
                self.failed_attestation = name
                with self.assertRaises(subprocess.CalledProcessError):
                    updater.update()
                self.assertFalse(self.formula.exists())

    def test_mismatched_checksum(self):
        self.corrupt_checksum = True
        with self.assertRaisesRegex(ValueError, "Checksum mismatch"):
            updater.update()
        self.assertFalse(self.formula.exists())

    def test_mutable_release(self):
        self.release["immutable"] = False
        with self.assertRaisesRegex(ValueError, "immutable"):
            updater.update()
        self.assertFalse(self.formula.exists())

    def test_no_stable_release(self):
        error = urllib.error.HTTPError("https://api.github.com", 404, "Not Found", {}, None)
        with patch.object(updater, "github", side_effect=error):
            updater.update()
        self.assertFalse(self.formula.exists())

    def test_older_release(self):
        self.formula.write_text('class Resh < Formula\n  version "0.2.0"\nend\n')
        with self.assertRaisesRegex(ValueError, "downgrade"):
            updater.update()
        self.assertIn('version "0.2.0"', self.formula.read_text())
