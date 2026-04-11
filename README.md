# DJ-Engine Releases

Public distribution repository for **[DJ-Engine](https://github.com/djmsqrvve/DJ-Engine)** binaries and games built with it.

DJ-Engine is a custom Bevy 0.18 game framework for narrative-heavy JRPGs, procedural 2D animation, and palette-driven corruption effects. This repo handles the distribution side — compiled engine binaries, packaged games, format specifications, and release automation.

For the full project vision, release strategy, and current status, see [docs/VISION.md](docs/VISION.md).

## Status

> **Pre-release** — Format specs, packaging scripts, and CI workflows are ready. Engine-side runtime loading (`.djpak`/`.djproj` support) is being implemented in DJ-Engine. No compiled binaries or packaged games have been published yet.

**First release target:** `dj_engine.exe` + `doomexe.djpak` — download two files, run `dj_engine.exe --play doomexe.djpak`, play the game.

## Downloads

Once the first release is published, artifacts will be available on the [Releases page](https://github.com/djmsqrvve/dj-engine-releases/releases).

| Artifact | Platform | Format | Description |
|----------|----------|--------|-------------|
| `dj_engine.exe` | Windows x86_64 | Binary | DJ-Engine editor + runtime player |
| `dj_engine` | Linux x86_64 | Binary | DJ-Engine editor + runtime player |
| `doomexe.djpak` | Cross-platform | `.djpak` | DoomExe — playable dark-fantasy JRPG with hamster narrator |
| `doomexe.djproj` | Cross-platform | `.djproj` | DoomExe — editable project (open in DJ-Engine Editor) |

## Quick Start

### Playing a Game

```bash
# Windows
dj_engine.exe --play doomexe.djpak

# Linux
chmod +x dj_engine
./dj_engine --play doomexe.djpak
```

For a detailed walkthrough, see [docs/HOW_TO_PLAY.md](docs/HOW_TO_PLAY.md).

### Opening a Project in the Editor

```bash
# Windows
dj_engine.exe --open doomexe.djproj

# Linux
./dj_engine --open doomexe.djproj
```

## About DoomExe

DoomExe is the first game distributed through this repo. It's a dark-fantasy horror JRPG prototype built with DJ-Engine, featuring:
- A **hamster narrator** guiding the player
- **3 combat areas**: Cellar, Corrupted Grove, Haunted Crypt
- A **Lich boss** encounter and victory screen
- Full combat with items, loot tables, consumables, and abilities
- Story graphs with branching dialogue

## .dj Project Formats

DJ-Engine uses two project formats for distribution:

### `.djproj` — Editable Project

A ZIP archive containing the full, human-readable project tree. For game developers who want to open, modify, and save projects in the DJ-Engine Editor.

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

- Rust 1.94.0 (pinned in DJ-Engine's `rust-toolchain.toml`)
- Linux build environment (native, WSL2, or Codespaces)
- For Windows cross-compilation: `gcc-mingw-w64-x86-64`
- Python 3 (for JSON minification)
- `zip` and `sha256sum` utilities

```bash
sudo apt-get install -y pkg-config libasound2-dev libudev-dev libwayland-dev \
  libxkbcommon-dev libx11-dev libvulkan-dev clang lld cmake \
  gcc-mingw-w64-x86-64 zip python3
```

### Build Engine Binaries

```bash
make build-engine DJ_ENGINE_DIR=/dev/DJ-Engine
```

### Package a Game

```bash
# Editable project
make package-djproj PROJECT_DIR=/dev/DJ-Engine/games/dev/doomexe

# Playable package
make package-djpak PROJECT_DIR=/dev/DJ-Engine/games/dev/doomexe
```

For the full release workflow, see [docs/RELEASE_PROCESS.md](docs/RELEASE_PROCESS.md).

## CI/CD

All workflows are `workflow_dispatch` only (manual trigger) to avoid GitHub Actions billing costs. See the workflow files for comments on how to re-enable automatic triggers when credits are available.

| Workflow | Purpose | Inputs |
|----------|---------|--------|
| `release-engine.yml` | Build & release DJ-Engine binaries | Engine repo ref, version, create release toggle |
| `release-game.yml` | Package & release a game | Game name, format, engine ref, version |
| `validate-packages.yml` | Validate packaging scripts and format compliance | Test packaging toggle, engine ref |

## Documentation

| Document | Description |
|----------|-------------|
| [docs/VISION.md](docs/VISION.md) | Project vision, release strategy, current status, ecosystem context |
| [docs/HOW_TO_PLAY.md](docs/HOW_TO_PLAY.md) | End-user guide — downloading and playing a game |
| [docs/RELEASE_PROCESS.md](docs/RELEASE_PROCESS.md) | Step-by-step release workflow for maintainers |
| [spec/DJPROJ_FORMAT.md](spec/DJPROJ_FORMAT.md) | `.djproj` editable project format specification |
| [spec/DJPAK_FORMAT.md](spec/DJPAK_FORMAT.md) | `.djpak` playable package format specification |
| [spec/VERSION_COMPAT.md](spec/VERSION_COMPAT.md) | Version compatibility matrix and naming conventions |
| [AGENT_PROMPT_DJ_ENGINE.md](AGENT_PROMPT_DJ_ENGINE.md) | Agent prompt for DJ-Engine to implement format support |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Contribution guidelines |
| [SECURITY.md](SECURITY.md) | Security policy and vulnerability reporting |
| [CHANGELOG.md](CHANGELOG.md) | Release history |

## Related Repositories

| Repository | Purpose |
|-----------|---------|
| [DJ-Engine](https://github.com/djmsqrvve/DJ-Engine) | Engine source — editor, runtime, 21 gameplay systems, 2,097+ tests |
| [Helix2000](https://github.com/djmsqrvve/Helix2000) | 2D side-scrolling MMORPG (TypeScript/Phaser/Colyseus) |
| [helix_3d](https://github.com/djmsqrvve/helix_3d) | 3D rendering prototype (Rust/Bevy) |
| [helix_standardization](https://github.com/djmsqrvve/helix_standardization) | Shared game data — 2,681 entities in TOML |
| [helix-tools](https://github.com/djmsqrvve/helix-tools) | Asset pipeline — GLTF standardization, Blender tools |

## License

MIT License — see [LICENSE](LICENSE).
