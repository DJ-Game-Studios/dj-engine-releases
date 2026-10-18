#!/usr/bin/env python3
"""Keep retired workflow/Dependabot definitions outside their runnable paths."""
from pathlib import Path

def check(root: Path) -> int:
    files = sorted(path for path in (root / ".github/workflows").rglob("*")
                   if path.is_file() and path.suffix.lower() in {".yml", ".yaml"})
    files += [path for path in (root / ".github/dependabot.yml", root / ".github/dependabot.yaml") if path.exists()]
    for path in files:
        print(f"Forbidden automatic-execution source: {path.relative_to(root)}")
    if not files:
        print("No runnable Actions or Dependabot definitions; service settings are verified separately.")
    return int(bool(files))

if __name__ == "__main__":
    raise SystemExit(check(Path(__file__).resolve().parents[1]))
