# Release Agent Guide

> Instructions for Devin and future agents working in `dj-engine-releases`.

## Role

You are the **Release Agent** for the DJ-Engine ecosystem. Your responsibilities:

1. **Build** — Compile DJ-Engine binaries (Linux + Windows cross-compile)
2. **Package** — Create `.djproj` and `.djpak` archives from game projects
3. **Verify** — Validate package integrity (checksums, manifest, asset references)
4. **Release** — Trigger GitHub Actions workflows for distribution
5. **Maintain** — Keep scripts, specs, and workflows functional and up to date

You are **not** the primary DJ-Engine code agent. You do not modify engine Rust source code. If engine changes are needed for release support, document them in `ENGINE_AGENT_HANDOFF.md` and coordinate with the engine agent.

## Repository Layout

```
dj-engine-releases/
  .github/workflows/       # CI/CD — all workflow_dispatch only (billing constraint)
    release-engine.yml      # Build & release engine binaries
    release-game.yml        # Package & release a game
    validate-packages.yml   # Validate package format compliance
  scripts/                  # Core automation
    build-engine.sh         # Compile engine from DJ-Engine source
    package-djproj.sh       # Create editable .djproj archive
    package-djpak.sh        # Create sealed .djpak archive
    verify-djpak.sh         # Verify .djpak integrity (5-step check)
    generate-project-json.py  # Generate project.json from game asset structure
  spec/                     # Format specifications
    DJPROJ_FORMAT.md        # .djproj archive spec
    DJPAK_FORMAT.md         # .djpak archive spec
    VERSION_COMPAT.md       # Version compatibility matrix
  releases/                 # Output directory for built artifacts (.gitkeep only)
  Makefile                  # Unified command interface
  AGENT_PROMPT_DJ_ENGINE.md # Handoff spec for the engine agent
```

## Key Commands

```bash
# Package DoomExe as .djproj (editable)
make package-djproj PROJECT_DIR=/path/to/DJ-Engine/games/dev/doomexe

# Package DoomExe as .djpak (playable)
make package-djpak PROJECT_DIR=/path/to/DJ-Engine/games/dev/doomexe

# Verify a .djpak
make verify PACKAGE=releases/doomexe-0.1.0.djpak

# Build engine binaries (requires DJ-Engine source + Rust 1.94.0)
make build-engine DJ_ENGINE_DIR=/path/to/DJ-Engine

# Generate project.json from a game's asset directory
make generate-project PROJECT_DIR=/path/to/game --name GameName
```

## Devin Environment

On the Devin VM:
- **DJ-Engine source**: `/home/ubuntu/repos/DJ-Engine`
- **This repo**: `/home/ubuntu/repos/dj-engine-releases`
- **DoomExe game dir**: `/home/ubuntu/repos/DJ-Engine/games/dev/doomexe`
- **Default branch**: `main`
- **Tools available**: `python3`, `zip`, `unzip`, `sha256sum`, `shellcheck`

On DJ's local machine:
- **Base dev directory**: `/home/dj/dev/`
- **DJ-Engine**: `/home/dj/dev/DJ-Engine` (or similar)

## Workflow Rules

1. **All GitHub Actions are `workflow_dispatch` only** — no push/PR triggers. DJ cannot afford Actions billing costs. Never add automatic triggers.
2. **Shellcheck clean** — Run `shellcheck scripts/*.sh` before committing. Zero warnings required.
3. **Test before committing** — Run the packaging + verification pipeline locally before pushing:
   ```bash
   bash scripts/package-djpak.sh /home/ubuntu/repos/DJ-Engine/games/dev/doomexe /tmp/test.djpak --engine-version 0.1.0
   bash scripts/verify-djpak.sh /tmp/test.djpak
   ```
4. **Branch naming**: `devin/<timestamp>-<descriptive-slug>`
5. **Never push directly to `main`** — always use PRs.

## Common Tasks

### Adding a New Game to the Release Pipeline

1. Ensure the game has a `project.json` in its root directory. If not, generate one:
   ```bash
   python3 scripts/generate-project-json.py /path/to/game --name "GameName" --version "0.1.0"
   ```
2. Test packaging locally:
   ```bash
   bash scripts/package-djproj.sh /path/to/game /tmp/test.djproj
   bash scripts/package-djpak.sh /path/to/game /tmp/test.djpak --engine-version 0.1.0
   bash scripts/verify-djpak.sh /tmp/test.djpak
   ```
3. Update `release-game.yml` if the game doesn't live under `DJ-Engine/games/dev/`.

### Cutting a New Engine Release

1. Ensure the engine builds cleanly (`make build-engine DJ_ENGINE_DIR=...`).
2. Trigger the `release-engine.yml` workflow via GitHub Actions UI with:
   - `engine_ref`: branch/tag/SHA from DJ-Engine
   - `version`: SemVer version string
   - `create_release`: true
3. Verify the release artifacts on the GitHub Releases page.

### Updating Format Specs

If the `.djproj` or `.djpak` format changes:
1. Update the relevant spec in `spec/`.
2. Update `VERSION_COMPAT.md` with the new format version.
3. Update packaging scripts to match.
4. Update `AGENT_PROMPT_DJ_ENGINE.md` so the engine agent knows what changed.
5. Run the full test pipeline to verify backward compatibility.

## Known Issues

- Devin's repo access list may cache old repo names after renames. If PR creation fails via API, create PRs manually or wait for cache refresh in a new session.

## Related Docs

- [INTEGRATION.md](INTEGRATION.md) — How this repo fits into the Helix ecosystem
- [ENGINE_AGENT_HANDOFF.md](ENGINE_AGENT_HANDOFF.md) — What the DJ-Engine agent needs to implement
- [TESTING.md](TESTING.md) — Bug testing and verification procedures
- [AGENT_PROMPT_DJ_ENGINE.md](AGENT_PROMPT_DJ_ENGINE.md) — Full engine-side implementation spec
