# Release Process

Step-by-step guide for creating a DJ-Engine release — from building the engine binary to packaging games and publishing to GitHub.

## Overview

A full release consists of:
1. **Engine binary** — compiled `.exe` (Windows) and/or Linux binary
2. **Game packages** — `.djpak` (playable) and/or `.djproj` (editable) archives
3. **GitHub Release** — tagged release with binaries and packages attached

## Prerequisites

- Access to the [DJ-Engine](https://github.com/djmsqrvve/DJ-Engine) source repo
- Rust 1.94.0 (pinned in `rust-toolchain.toml`)
- Linux build environment (native or WSL2)
- For Windows cross-compilation: `gcc-mingw-w64-x86-64`
- Python 3 (for JSON minification in `.djpak` packaging)
- `zip` utility
- `sha256sum` utility

Install build dependencies:
```bash
sudo apt-get install -y pkg-config libasound2-dev libudev-dev libwayland-dev \
  libxkbcommon-dev libx11-dev libvulkan-dev clang lld cmake \
  gcc-mingw-w64-x86-64 zip python3
```

## Step 1: Build the Engine

### Via Makefile (recommended)

```bash
# From the dj-engine-releases repo root:
make build-engine DJ_ENGINE_DIR=/dev/DJ-Engine
```

This builds both Linux and Windows binaries. Output goes to `releases/`.

### Via script directly

```bash
# Linux only:
./scripts/build-engine.sh /dev/DJ-Engine --platform linux

# Windows only:
./scripts/build-engine.sh /dev/DJ-Engine --platform windows

# Both:
./scripts/build-engine.sh /dev/DJ-Engine --platform all
```

### What happens

1. The script validates the DJ-Engine directory structure
2. Builds with `--release` and LTO optimizations
3. Outputs versioned binaries: `dj_engine-{version}-{platform}.{ext}`

## Step 2: Package a Game

### Package as `.djpak` (playable)

```bash
# Via Makefile:
make package-djpak PROJECT_DIR=/dev/DJ-Engine/games/dev/doomexe

# Via script:
./scripts/package-djpak.sh /dev/DJ-Engine/games/dev/doomexe doomexe.djpak
```

What the script does:
1. Validates `project.json` exists and is valid
2. Generates a runtime `manifest.json` (strips editor metadata)
3. Minifies all JSON files (scenes, story graphs, database)
4. Copies binary assets unchanged
5. Generates SHA-256 checksums for all files
6. Creates the sealed `.djpak` ZIP archive

### Package as `.djproj` (editable)

```bash
# Via Makefile:
make package-djproj PROJECT_DIR=/dev/DJ-Engine/games/dev/doomexe

# Via script:
./scripts/package-djproj.sh /dev/DJ-Engine/games/dev/doomexe doomexe.djproj
```

What the script does:
1. Validates `project.json` and all referenced scenes/story graphs
2. Creates a ZIP archive of the full project tree
3. Excludes build artifacts (`.git`, `target`, `node_modules`, etc.)

## Step 3: Verify Packages

Always verify `.djpak` packages before release:

```bash
# Via Makefile:
make verify PACKAGE=doomexe.djpak

# Via script:
./scripts/verify-djpak.sh doomexe.djpak
```

The verifier runs 5 checks:
1. ZIP integrity
2. `manifest.json` validation
3. `checksum.sha256` existence
4. Checksum matching (all files)
5. Scene and story graph reference validation

## Step 4: Create a GitHub Release

### Via GitHub Actions (recommended)

Go to the [Actions tab](https://github.com/djmsqrvve/dj-engine-releases/actions) and run the appropriate workflow:

**Release Engine:**
- Workflow: `release-engine.yml`
- Inputs: engine repo ref (branch/tag/commit), version tag, whether to create a release
- Builds both platforms in parallel
- Creates a GitHub Release with binaries attached

**Release Game:**
- Workflow: `release-game.yml`
- Inputs: game name, format (djpak/djproj/both), engine ref, version
- Packages the game and creates a GitHub Release

**Note:** All workflows are `workflow_dispatch` only (manual trigger) to avoid GitHub Actions billing costs. See the workflow files for comments on how to re-enable automatic triggers when you have credits.

### Manual release

If you prefer to create releases manually:

1. Tag the release:
   ```bash
   git tag -a v0.1.0 -m "DJ-Engine 0.1.0 + DoomExe 0.1.0"
   git push origin v0.1.0
   ```

2. Go to https://github.com/djmsqrvve/dj-engine-releases/releases/new
3. Select the tag
4. Upload the binaries and packages
5. Write release notes (see template below)

### Release Notes Template

```markdown
## DJ-Engine v{version}

### Engine Binaries

| Platform | File | SHA-256 |
|----------|------|---------|
| Windows x86_64 | `dj_engine-{version}-windows-x86_64.exe` | `{hash}` |
| Linux x86_64 | `dj_engine-{version}-linux-x86_64` | `{hash}` |

### Games

| Game | Format | File |
|------|--------|------|
| DoomExe | Playable | `doomexe-{version}.djpak` |
| DoomExe | Editable | `doomexe-{version}.djproj` |

### Quick Start

\```bash
# Play DoomExe:
./dj_engine --play doomexe.djpak

# Open in editor:
./dj_engine --open doomexe.djproj
\```

### What's New
- {changelog entries}
```

## Step 5: Validate the Release

After publishing:

1. Download the release artifacts from GitHub
2. Verify the engine runs: `./dj_engine --play doomexe.djpak`
3. Verify the editor opens: `./dj_engine --open doomexe.djproj`
4. Check that checksums match the ones in the release notes

### Via GitHub Actions

Run the `validate-packages.yml` workflow to automatically test packaging scripts and format compliance.

## Release Cadence

There is no fixed release schedule yet. Releases are cut when:
- A meaningful set of engine features has shipped
- A game update is ready for distribution
- A critical bug fix needs to be distributed

## File Naming Conventions

| Artifact | Pattern | Example |
|----------|---------|---------|
| Engine binary | `dj_engine-{version}-{platform}.{ext}` | `dj_engine-0.1.0-windows-x86_64.exe` |
| Game package | `{game}-{version}.djpak` | `doomexe-0.1.0.djpak` |
| Editable project | `{game}-{version}.djproj` | `doomexe-0.1.0.djproj` |

See [spec/VERSION_COMPAT.md](../spec/VERSION_COMPAT.md) for full versioning rules.
