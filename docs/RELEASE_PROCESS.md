# DJ-Engine Releases — Release Process

Human-facing runbook for `djmsqrvve/dj-engine-releases` — the **public** distribution repo for DJ-Engine and its games.

## What gets released here

| Product | Workflow | Artifact | Tag scheme |
|---------|----------|----------|------------|
| DJ-Engine (the engine itself) | `release-engine.yml` | `dj_engine` (Linux), `dj_engine.exe` (Windows, future) | `v${version}` |
| Game as engine package | `release-game.yml` | `${game}-${ver}.djpak` + `.djproj` | `${game}-v${version}` |
| Game as standalone binary | `release-game-exe.yml` | `${game}-${ver}-linux-x64.tar.gz` + `${game}-${ver}-windows-x64.zip` | `${game}-v${version}` |

**Why three workflows:** a DJ-Engine game can ship in multiple forms and we let whoever publishes pick the mix. For `doomexe` specifically:

- **`.djpak` release-game.yml** — for players who already have `dj_engine` installed (tiny download, engine upgrades independently)
- **`.exe` release-game-exe.yml** — for players who just want to click and play (self-contained, bigger download)
- Both workflows can publish to the **same tag** (`doomexe-v0.1.0`) and `softprops/action-gh-release` appends — one GitHub Release ends up with all formats attached

## One-time setup

### 1. Create the PAT

Fine-grained PAT with:

| Scope | Repo |
|-------|------|
| Contents: read | `djmsqrvve/DJ-Engine` |
| Contents: write | `djmsqrvve/dj-engine-releases` |

Store as repo secret **`DJENGINE_RELEASE_PAT`** on `djmsqrvve/dj-engine-releases`. Also copy into KeePassXC (`studio-ops/team/wggs-vault.kdbx`) as `GitHub-DJENGINE_RELEASE_PAT`.

### 2. Confirm workflow permissions

`release-game-exe.yml` already declares `permissions: contents: write` on the `publish` job — it uses the default `GITHUB_TOKEN` to publish (same-repo write). No extra PAT needed for the publish step itself; the PAT is only for the cross-repo checkout of `DJ-Engine`.

## Cutting a doomexe release

### Option A — Standalone .exe only (fastest path for "give me a download link")

Web UI → Actions → **Release Game Standalone Binaries** → Run workflow. Fill in:

- `game_name`: `doomexe`
- `game_version`: `0.1.0`
- `engine_ref`: `main` (or a specific SHA)
- `create_release`: checked

Result: GitHub Release `doomexe-v0.1.0` with Linux tarball + Windows zip attached.

### Option B — .djpak engine package

Same UI pattern but **Release Game Package** workflow. Produces `.djpak` + `.djproj`, tagged `doomexe-v0.1.0`.

### Option C — Both

Run Option A and Option B against the same `game_version`. The second workflow appends its files to the existing release.

### Option D — Tag-driven (skip UI)

```bash
cd /path/to/DJ-Engine
git tag doomexe-v0.1.0
git push origin doomexe-v0.1.0
```

Tags matching `doomexe-v*`, `stratego-v*`, etc. trigger `release-game-exe.yml` automatically (see the `push: tags:` trigger). `release-game.yml` is still manual-dispatch only (cost-conscious design; flip to push-trigger if/when desired).

## After the release

- [ ] Open `https://github.com/djmsqrvve/dj-engine-releases/releases/tag/doomexe-v0.1.0` — verify assets attached
- [ ] Download the Windows zip, extract on a Windows machine, run `doomexe.exe` — confirms bundled `assets/` load correctly
- [ ] Append to [`master-track/data/releases.json`](../../../master-track/data/releases.json):
  ```json
  {
    "product": "doomexe",
    "version": "0.1.0",
    "tag": "doomexe-v0.1.0",
    "prerelease": false,
    "published_at": "...",
    "source_sha": "...",
    "release_url": "https://github.com/djmsqrvve/dj-engine-releases/releases/tag/doomexe-v0.1.0",
    "platforms": { "linux": "...", "windows": "..." },
    "artifacts": [ {"name": "...", "size_bytes": N, "sha256": "..."} ],
    "summary": "First public doomexe release. 3 zones, Iron Lich boss, self-contained .exe."
  }
  ```
- [ ] Commit `releases.json` to `master-track`
- [ ] Update the `doomexe` product `current_version` in `releases.json`

## Expected first-run snags

| Symptom | Cause | Fix |
|---------|-------|-----|
| "Resource not accessible by integration" on checkout of DJ-Engine | PAT missing or wrong scope | Regenerate PAT with `Contents:read` on `djmsqrvve/DJ-Engine`, update `DJENGINE_RELEASE_PAT` secret |
| `cargo build` fails with `dj_engine not found` | Sub-agent recon says `dj_engine = { path = "../../../engine" }` — ensure the DJ-Engine checkout is at `DJ-Engine/` relative to workspace root. The workflow already does this. |
| Asset files missing in extracted archive | `DJ-Engine/games/dev/<game>/assets` path assumption. Check the crate has that layout. doomexe does. |
| "Expected binary not found" in stage-artifact step | `--no-default-features` fails to produce a binary (maybe the crate needs a different feature flag). Check `release-smoke` target in DJ-Engine/Makefile for the actual working flags |

## What this setup does NOT do yet

- **No GameJolt upload** — can be added as a third job mirroring helix-viewer's approach (see `helix/helix_3d/.github/workflows/release-viewer.yml` for the gamejolt-cli stub)
- **No code signing** — Windows SmartScreen will warn users. Acceptable for v0.1.x; revisit at v1.0
- **No dj_engine.exe in release-engine.yml** — still Linux-only. Adding Windows matrix to `release-engine.yml` is the symmetric follow-up
- **No itch.io push** — `butler` CLI integration would be a nice sibling to the GameJolt CLI

## Links

- This workflow: [`.github/workflows/release-game-exe.yml`](../.github/workflows/release-game-exe.yml)
- Sibling workflows: [`release-game.yml`](../.github/workflows/release-game.yml), [`release-engine.yml`](../.github/workflows/release-engine.yml)
- DJ-Engine source: https://github.com/djmsqrvve/DJ-Engine (private)
- doomexe crate: `DJ-Engine/games/dev/doomexe/`
- Strategy doc: [`studio-ops/releases/DJENGINE_SUBRELEASES_PROPOSAL.md`](../../../studio-ops/releases/DJENGINE_SUBRELEASES_PROPOSAL.md)
- Cross-product release log: [`master-track/data/releases.json`](../../../master-track/data/releases.json)
