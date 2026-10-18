#!/usr/bin/env python3
"""Preserved synthetic packaging gate; no engine build, release or deployment."""
import json
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]

def main():
    subprocess.run(["python3", "scripts/check-no-github-actions.py"], cwd=ROOT, check=True)
    subprocess.run(["shellcheck", *map(str, sorted((ROOT / "scripts").glob("*.sh")))], check=True)
    fixtures = json.loads((ROOT / "scripts/package-validation-fixtures.json").read_text())
    with tempfile.TemporaryDirectory(prefix="dj-release-package-gate-") as temporary:
        directory = Path(temporary)
        project = directory / "project"
        for relative, data in fixtures.items():
            path = project / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(json.dumps(data) + "\n")
        for relative in ("database", "assets/audio", "assets/music", "data"):
            (project / relative).mkdir(parents=True, exist_ok=True)
        subprocess.run(["bash", str(ROOT / "scripts/package-djproj.sh"), str(project), str(directory / "test.djproj")], check=True)
        package = directory / "test.djpak"
        subprocess.run(["bash", str(ROOT / "scripts/package-djpak.sh"), str(project), str(package), "--engine-version", "0.1.0"], check=True)
        subprocess.run(["bash", str(ROOT / "scripts/verify-djpak.sh"), str(package)], check=True)

if __name__ == "__main__":
    main()
