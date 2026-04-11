# Helix Ecosystem Integration

> How `dj-engine-releases` fits into the broader DJ / Helix ecosystem.

## Ecosystem Map

```
                         ┌─────────────────────────┐
                         │  helix_standardization   │
                         │  (TOML Source of Truth)   │
                         └──────────┬──────────────┘
                                    │ entity data
                    ┌───────────────┼───────────────┐
                    ▼               ▼               ▼
           ┌──────────────┐ ┌─────────────┐ ┌──────────────┐
           │  Helix2000   │ │  helix_3d   │ │  DJ-Engine   │
           │  (2D Web)    │ │  (3D Rust)  │ │  (2D JRPG)   │
           │  React/Phaser│ │  Bevy       │ │  Bevy 0.18   │
           └──────────────┘ └─────────────┘ └──────┬───────┘
                                                    │
                                                    │ source code
                                                    ▼
                                         ┌─────────────────────┐
                                         │ dj-engine-releases   │ ◄── YOU ARE HERE
                                         │ (Build + Package +   │
                                         │  Distribute)         │
                                         └──────────┬──────────┘
                                                    │
                                         ┌──────────┴──────────┐
                                         ▼                     ▼
                                    dj_engine.exe        doomexe.djpak
                                    (engine binary)      (game package)
```

## This Repo's Role

`dj-engine-releases` is the **distribution layer**. It does not contain game logic or engine runtime code. It:

1. **Compiles** DJ-Engine source into platform binaries (`dj_engine.exe`, `dj_engine`)
2. **Packages** game projects into `.djproj` (editable) and `.djpak` (playable) archives
3. **Verifies** package integrity (checksums, manifest validation, asset references)
4. **Distributes** via GitHub Releases (workflow_dispatch triggered)

## Upstream Dependencies

| Repo | What We Use | How |
|------|------------|-----|
| [DJ-Engine](https://github.com/djmsqrvve/DJ-Engine) | Engine Rust source | `build-engine.sh` compiles it into binaries |
| [DJ-Engine](https://github.com/djmsqrvve/DJ-Engine) | Game project dirs (`games/dev/*`) | `package-djpak.sh` / `package-djproj.sh` package them |
| [helix_standardization](https://github.com/djmsqrvve/helix_standardization) | Entity TOML data (indirect) | DJ-Engine consumes standardized data; we package the result |

## Downstream Consumers

| Who | What They Get | Format |
|-----|--------------|--------|
| End-user players | `dj_engine.exe` + `game.djpak` | Binary + sealed archive |
| Game developers / modders | `dj_engine.exe` + `game.djproj` | Binary + editable archive |
| DJ-Engine agent | Format specs, packaging scripts | This repo's `spec/` and `scripts/` |
| Helix ecosystem CI | Validated packages | `validate-packages.yml` workflow |

## Data Flow

### Build Flow (Engine Binary)
```
DJ-Engine repo (Rust source)
  → build-engine.sh (cross-compile Linux + Windows)
    → releases/dj_engine-{version}-{platform}.{ext}
      → GitHub Releases (via release-engine.yml)
```

### Package Flow (Game)
```
DJ-Engine/games/dev/doomexe/ (game project dir)
  ├→ package-djproj.sh → doomexe-{version}.djproj (editable, pretty JSON)
  └→ package-djpak.sh  → doomexe-{version}.djpak  (sealed, minified, checksummed)
       → verify-djpak.sh (5-step integrity check)
         → GitHub Releases (via release-game.yml)
```

### Runtime Flow (End User)
```
dj_engine.exe --play doomexe.djpak
  → checksum verification
    → extract to read-only temp dir
      → parse manifest.json
        → load startup scene + story graph
          → Runtime Preview (Title → Dialogue → Overworld)
```

## Cross-Repo Coordination

### What This Repo Provides to DJ-Engine Agent

- **Format specs** (`spec/DJPAK_FORMAT.md`, `spec/DJPROJ_FORMAT.md`) — defines what the engine loaders must parse
- **Implementation spec** (`AGENT_PROMPT_DJ_ENGINE.md`) — full task breakdown for engine-side work
- **Handoff doc** (`ENGINE_AGENT_HANDOFF.md`) — what's ready, what's needed, current blockers
- **Test artifacts** — `.djpak` and `.djproj` files for testing engine loaders

### What DJ-Engine Agent Provides to This Repo

- **Engine source** — we compile it
- **Game project dirs** — we package them
- **`project.json` schema** — our packaging scripts must match the engine's Rust struct definitions
- **Bug reports** — if engine loaders find issues with our packages

### What helix_standardization Provides (Indirect)

- **Entity data** (mobs, abilities, items) flows through TOML → DJ-Engine → game database → `.djpak`
- If standardization schema changes, `database/` contents in packages may change
- This repo doesn't need to know about TOML internals — we just package whatever's in the game dir

## Helix-Tools Integration (Future)

As the Helix tooling ecosystem expands into focused repos:

| Tool Repo | Potential Integration |
|-----------|---------------------|
| **Helix-Model-Converter** | If DJ-Engine gains 3D asset support, converted GLTF files would be included in `assets/` |
| **Helix-Blender-Tools** | Exported sprites/animations for DJ-Engine games would end up in packages |
| **Helix-Import-Export** | Could feed assets directly into game project dirs before packaging |
| **Helix-Animation-Tools** | Animation data could be included in `.djproj`/`.djpak` `assets/` |

Currently none of these are direct dependencies — they're upstream of the game project directories.

## Version Alignment

| Component | Current Version | Pinned? |
|-----------|----------------|---------|
| DJ-Engine | 0.1.0 | Yes (Rust binary) |
| Bevy | 0.18 | Yes (engine dependency) |
| Format Version | 1.0.0 | Yes (archive schema) |
| DoomExe | 0.1.0 | Yes (first game) |

See [spec/VERSION_COMPAT.md](spec/VERSION_COMPAT.md) for the full compatibility matrix.

## Billing Constraint

All GitHub Actions workflows in this repo and across the Helix ecosystem use `workflow_dispatch` only. **No automatic push/PR triggers.** This is a billing constraint — DJ cannot afford GitHub Actions costs. This applies to:
- `release-engine.yml`
- `release-game.yml`
- `validate-packages.yml`

When the user has Actions credits again, triggers can be re-enabled (see comments in workflow files).
