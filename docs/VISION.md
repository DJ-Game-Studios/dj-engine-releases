# Vision and Status

## What is DJ-Engine?

DJ-Engine is a custom Bevy 0.18 game framework built for **narrative-heavy JRPGs**, procedural 2D animation, and palette-driven corruption effects. It's not a general-purpose engine — it's purpose-built for data-authored story games where the content pipeline matters as much as the renderer.

The engine includes:
- A full **editor** for authoring scenes, story graphs, and custom game data
- A **runtime preview** system for playing authored content
- **21 gameplay systems** (combat, quests, inventory, dialogue, abilities, loot, Lua scripting, and more)
- A **custom document platform** for registering game-specific data types
- **2,097+ tests** with zero clippy warnings

Source: [github.com/djmsqrvve/DJ-Engine](https://github.com/djmsqrvve/DJ-Engine)

## What is This Repository?

This is the **public distribution repository** for DJ-Engine. It exists to:

1. **Distribute compiled engine binaries** — so users don't need a Rust toolchain to play games
2. **Distribute packaged games** — in two formats designed for different audiences
3. **Define the packaging formats** — `.djproj` (editable) and `.djpak` (playable)
4. **Automate the release pipeline** — scripts and CI workflows for building, packaging, and publishing

## Why a Separate Repo?

The DJ-Engine source repo is a Rust workspace with engine code, game code, tests, docs, and tooling. It's a development workspace, not a distribution channel. This repo separates **"how to build the engine"** from **"how to get a game running"**.

This also means:
- Users who just want to play a game never need to see Rust source code
- The release pipeline can evolve independently of engine development
- Format specifications and packaging scripts live in one clear place
- CI workflows for building releases don't interfere with the engine's own CI

## The Two Distribution Formats

DJ-Engine defines two project formats for different audiences:

### `.djproj` — Editable Project
A ZIP archive of the full, human-readable project. For game developers who want to open, modify, and save projects in the DJ-Engine Editor. Contains `project.json`, scenes, story graphs, database, assets, and custom data — all in pretty-printed JSON.

### `.djpak` — Playable Package
A sealed ZIP archive for end-users who just want to play. JSON is minified, editor metadata is stripped, and a SHA-256 checksum verifies integrity. The engine loads it into a read-only temp directory and runs the game. Save data goes to a user-scoped save directory, not back into the package.

See [spec/DJPROJ_FORMAT.md](../spec/DJPROJ_FORMAT.md) and [spec/DJPAK_FORMAT.md](../spec/DJPAK_FORMAT.md) for full specifications.

## Current Status

### What Exists

- Format specifications for `.djproj` and `.djpak` (v1.0.0)
- Packaging scripts: `package-djproj.sh`, `package-djpak.sh`, `verify-djpak.sh`
- Engine build script: `build-engine.sh` (Linux + Windows cross-compile)
- Project manifest generator: `generate-project-json.py`
- GitHub Actions workflows (all `workflow_dispatch` only — billing constraint)
- Agent prompt for DJ-Engine to implement runtime format loading
- Version compatibility specification

### What's In Progress

The DJ-Engine source repo needs to implement runtime support for the new formats:
- CLI argument parsing (`--play`, `--open` flags)
- `.djpak` loader with checksum verification
- `.djproj` loader with save-back functionality
- Integration tests and E2E validation

See [AGENT_PROMPT_DJ_ENGINE.md](../AGENT_PROMPT_DJ_ENGINE.md) for the full implementation sprint.

### What's Not Yet Built

- No compiled engine binaries have been released yet
- No packaged games have been published yet
- The first release target is: `dj_engine.exe` + `doomexe.djpak`

## First Release Target

The sprint goal is two files that work together:

1. **`dj_engine.exe`** — the compiled DJ-Engine editor + runtime player
2. **`doomexe.djpak`** — DoomExe packaged as a playable game

A user downloads both, runs `dj_engine.exe --play doomexe.djpak`, and plays a dark-fantasy horror JRPG with a hamster narrator.

## DoomExe

DoomExe is the primary sample game built with DJ-Engine. It's a dark-fantasy horror JRPG prototype featuring:
- A **hamster narrator** guiding the player through the story
- **3 combat areas**: Cellar, Corrupted Grove, Haunted Crypt
- A **Lich boss** encounter
- A **victory screen** upon completion
- Full combat with items, loot tables, consumables, and abilities
- Story graphs with branching dialogue

It serves as both the first game to distribute via this repo and the proof that DJ-Engine's packaging pipeline works end-to-end.

## The Broader Ecosystem

DJ-Engine is part of a larger ecosystem of game development tools:

| Repository | Purpose |
|-----------|---------|
| [DJ-Engine](https://github.com/djmsqrvve/DJ-Engine) | Engine source — editor, runtime, gameplay systems |
| **dj-engine-releases** (this repo) | Distribution — binaries, packages, release pipeline |
| [Helix2000](https://github.com/djmsqrvve/Helix2000) | 2D side-scrolling MMORPG (TypeScript/Phaser/Colyseus) |
| [helix_3d](https://github.com/djmsqrvve/helix_3d) | 3D rendering prototype (Rust/Bevy) |
| [helix_standardization](https://github.com/djmsqrvve/helix_standardization) | Shared game data — 2,681 entities in TOML |
| [helix-tools](https://github.com/djmsqrvve/helix-tools) | Asset pipeline — GLTF standardization, Blender tools |

DJ-Engine consumes data from `helix_standardization` through its Helix data plugin, enabling games to use a shared pool of abilities, items, mobs, quests, and other MMORPG entities.

## Long-Term Vision

DJ-Engine aims to be a **reusable multi-game authoring and runtime platform** — not a cleaned-up shell around one sample project. The release pipeline supports this by:
- Making it easy to package and distribute any game built with the engine
- Supporting both development-oriented (`.djproj`) and consumer-oriented (`.djpak`) distribution
- Defining stable format specifications that can evolve with versioning
- Automating the build-package-verify-release cycle

The goal is that future games can be created in the DJ-Engine Editor, packaged with these scripts, and distributed through this repo without needing to understand the engine internals.
