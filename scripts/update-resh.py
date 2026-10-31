#!/usr/bin/env python3
"""Publish a formula only after verifying immutable upstream release artifacts."""

import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import urllib.error
import urllib.request


REPOSITORY = "CruelAddict/resh"
ROOT = Path(__file__).resolve().parents[1]
ARCHIVES = {arch: f"resh-macos-{arch}.tar.gz" for arch in ("arm64", "x86_64")}


def github(path):
    headers = {"Accept": "application/vnd.github+json", "User-Agent": "resh-tap-updater"}
    token = os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN")
    if token:
        headers["Authorization"] = f"Bearer {token}"
    request = urllib.request.Request(f"https://api.github.com/repos/{REPOSITORY}/{path}", headers=headers)
    with urllib.request.urlopen(request, timeout=60) as response:
        return json.load(response)


def run(*arguments):
    subprocess.run(arguments, check=True)


def update():
    try:
        release = github("releases/latest")
    except urllib.error.HTTPError as error:
        if error.code != 404:
            raise
        print("No stable resh release yet; the formula will be created after the first release.")
        return

    tag = release["tag_name"]
    if release["draft"] or release["prerelease"] or not re.fullmatch(r"v(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)", tag):
        raise ValueError("Expected a stable vMAJOR.MINOR.PATCH release")
    if not release.get("immutable"):
        raise ValueError("The upstream release must be immutable")

    version = tag[1:]
    formula = ROOT / "Formula/resh.rb"
    if formula.exists():
        current = re.search(r'^  version "([0-9.]+)"$', formula.read_text(), re.MULTILINE)
        if not current:
            raise ValueError("Cannot read the current formula version")
        if tuple(map(int, version.split("."))) < tuple(map(int, current[1].split("."))):
            raise ValueError("Refusing to downgrade the formula")
        if current[1] == version:
            print(f"resh {version} is already current.")
            return

    commit = github(f"commits/{tag}")["sha"]
    if not re.fullmatch(r"[a-f0-9]{40}", commit):
        raise ValueError("Invalid upstream source commit")

    with tempfile.TemporaryDirectory(prefix="resh-tap-") as directory:
        files = ["checksums.txt", *ARCHIVES.values()]
        command = ["gh", "release", "download", tag, "--repo", REPOSITORY, "--dir", directory]
        for name in files:
            command.extend(["--pattern", name])
        run(*command)

        digests = {}
        for name in files:
            path = Path(directory) / name
            run("gh", "attestation", "verify", str(path), "--repo", REPOSITORY,
                "--signer-workflow", f"{REPOSITORY}/.github/workflows/release.yml",
                "--source-ref", f"refs/tags/{tag}", "--source-digest", commit,
                "--deny-self-hosted-runners")
            with path.open("rb") as archive:
                digests[name] = hashlib.file_digest(archive, "sha256").hexdigest()

        manifest = {}
        for line in (Path(directory) / "checksums.txt").read_text().splitlines():
            digest, name = line.split()
            if name in manifest or not re.fullmatch(r"[a-f0-9]{64}", digest):
                raise ValueError("Invalid or duplicate checksum entry")
            manifest[name] = digest
        for name in ARCHIVES.values():
            if manifest.get(name) != digests[name]:
                raise ValueError(f"Checksum mismatch for {name}")

    text = (ROOT / "templates/resh.rb.in").read_text()
    text = text.replace("@VERSION@", version)
    for arch, name in ARCHIVES.items():
        text = text.replace(f"@{arch.upper()}_SHA256@", digests[name])
    formula.write_text(text)
    print(f"Prepared resh {version} from verified release {tag} ({commit}).")


if __name__ == "__main__":
    update()
