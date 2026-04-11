# DJ-Engine Releases

Public distribution repository for **DJ-Engine** binaries and games built with it.

## Downloads

| Artifact | Platform | Format | Description |
|----------|----------|--------|-------------|
| `dj_engine.exe` | Windows x86_64 | Binary | DJ-Engine editor + runtime player |
| `dj_engine` | Linux x86_64 | Binary | DJ-Engine editor + runtime player |
| `doomexe.djpak` | Cross-platform | `.djpak` | DoomExe (hamster narrator JRPG) — playable package |
| `doomexe.djproj` | Cross-platform | `.djproj` | DoomExe — editable project (open in DJ-Engine Editor) |

## Quick Start

### Playing a Game

```bash
# Windows
dj_engine.exe --play doomexe.djpak

# Linux
./dj_engine --play doomexe.djpak
```

### Opening a Project in the Editor

```bash
# Windows
dj_engine.exe --open doomexe.djproj

# Linux
./dj_engine --open doomexe.djproj
```

## .dj Project Formats

DJ-Engine uses two project formats for distribution:

### `.djproj` — Editable Project

A ZIP archive containing the full, human-readable project tree. Designed for game developers who want to open, edit, and save projects in the DJ-Engine Editor.

Contents:
- `project.json` — Project manifest (name, version, settings, scene/story graph refs)
- `scenes/` — Scene JSON files (tile maps, entity placements, collision)
- `story_graphs/` — Story graph JSON files (dialogue trees, branching logic)
- `database/` — Game database (items, enemies, NPCs, loot tables)
- `assets/` — Audio (`.ogg`, `.mid`), sprites, palettes, Lua scripts
- `data/` — Custom document registry and documents

### `.djpak` — Playable Package

A sealed ZIP archive for end-users who just want to play. Data is minified, editor metadata is stripped, and an integrity checksum is included.

Contents:
- `manifest.json` — Minimal runtime manifest
- `scenes/` — Minified scene data
- `story_graphs/` — Minified story graph data
- `database/` — Merged game database
- `assets/` — Audio and sprite assets
- `checksum.sha256` — File integrity verification

See [spec/DJPROJ_FORMAT.md](spec/DJPROJ_FORMAT.md) and [spec/DJPAK_FORMAT.md](spec/DJPAK_FORMAT.md) for full specifications.

## Building from Source

### Prerequisites

- Rust 1.94.0 (pinned)
- Linux build dependencies (for cross-compilation to Windows):
  ```bash
  sudo apt-get install -y pkg-config libasound2-dev libudev-dev libwayland-dev \
    libxkbcommon-dev libx11-dev libvulkan-dev clang lld cmake \
    gcc-mingw-w64-x86-64
  ```

### Build Engine Binaries

```bash
make build-engine DJ_ENGINE_DIR=/path/to/DJ-Engine
```

### Package a Game

```bash
# Editable project
make package-djproj PROJECT_DIR=/path/to/game/project

# Playable package
make package-djpak PROJECT_DIR=/path/to/game/project
```

## CI/CD

All workflows are `workflow_dispatch` only (manual trigger) to avoid GitHub Actions billing costs.

| Workflow | Purpose | Inputs |
|----------|---------|--------|
| `release-engine.yml` | Build & release DJ-Engine binaries | Engine repo ref |
| `release-game.yml` | Package & release a game | Game name, format, engine ref |
| `validate-packages.yml` | Validate `.djproj`/`.djpak` compliance | Package path |

## Documentation

| Document | Purpose |
|----------|---------|
| [AGENTS.md](AGENTS.md) | Instructions for Devin and future release agents |
| [INTEGRATION.md](INTEGRATION.md) | How this repo fits into the Helix ecosystem |
| [ENGINE_AGENT_HANDOFF.md](ENGINE_AGENT_HANDOFF.md) | What the DJ-Engine agent needs to implement |
| [TESTING.md](TESTING.md) | Bug testing, verification, and tracking procedures |
| [AGENT_PROMPT_DJ_ENGINE.md](AGENT_PROMPT_DJ_ENGINE.md) | Full engine-side implementation spec (7 tasks) |
| [spec/DJPROJ_FORMAT.md](spec/DJPROJ_FORMAT.md) | `.djproj` format specification |
| [spec/DJPAK_FORMAT.md](spec/DJPAK_FORMAT.md) | `.djpak` format specification |
| [spec/VERSION_COMPAT.md](spec/VERSION_COMPAT.md) | Version compatibility matrix |

## Related Repositories

| Repo | Role in Ecosystem |
|------|-------------------|
| [DJ-Engine](https://github.com/djmsqrvve/DJ-Engine) | Engine source code (Rust/Bevy 0.18) — we compile and package from this |
| [Helix2000](https://github.com/djmsqrvve/Helix2000) | 2D MMORPG (React/Phaser/Colyseus) — sibling game project |
| [helix_3d](https://github.com/djmsqrvve/helix_3d) | 3D renderer (Rust/Bevy) — sibling engine |
| [helix_standardization](https://github.com/djmsqrvve/helix_standardization) | Canonical TOML entity data — upstream data source for games |
| [helix-tools](https://github.com/djmsqrvve/helix-tools) | 3D asset pipeline (GLTF, Blender, animation) |
| [docs](https://github.com/djmsqrvve/docs) | Centralized ecosystem documentation |

## License

MIT License — see [LICENSE](LICENSE).
