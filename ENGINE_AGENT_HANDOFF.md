# Engine Agent Handoff

> What the DJ-Engine agent needs to know about the release pipeline and what's ready for integration.
>
> Original engine integration handoff: 2026-04-11. Its engine tasks and product-readiness statements are historical and must be reconciled with the active Helix agent before use.
>
> Maintenance update, 2026-10-17: use `make validate-local` for blocking ShellCheck and synthetic packaging/verification. All four GitHub workflows are retired. Actual engine, game and platform readiness are separate owner gates; this cleanup does not assign gameplay work or publish a release.

## TL;DR

The local packaging gate passes against its synthetic fixture. That does not establish current DoomExe or engine-loader readiness. The original integration tasks below describe the April 11 plan; consult the active engine/gameplay owner rather than treating them as unfinished work today.

## What's Ready (Releases Repo Side)

| Component | Status | Location |
|-----------|--------|----------|
| `.djpak` packaging script | Working | `scripts/package-djpak.sh` |
| `.djproj` packaging script | Working | `scripts/package-djproj.sh` |
| `.djpak` verification script | Working (bug fixed) | `scripts/verify-djpak.sh` |
| `project.json` generator | Working | `scripts/generate-project-json.py` |
| `.djpak` format spec | Complete | `spec/DJPAK_FORMAT.md` |
| `.djproj` format spec | Complete | `spec/DJPROJ_FORMAT.md` |
| Version compatibility spec | Complete | `spec/VERSION_COMPAT.md` |
| Historical workflows (all 4) | Retired; not runnable | `.github/workflows-archive/` |
| Makefile | Complete | `Makefile` |
| DoomExe `project.json` | Already exists in DJ-Engine | `games/dev/doomexe/project.json` |

### DoomExe project.json (Already Exists)

The DoomExe game in `DJ-Engine/games/dev/doomexe/project.json` already has:
- 4 scenes: `overworld`, `cellar`, `corrupted_grove`, `haunted_crypt`
- 2 story graphs: `intro`, `hamster_narrator`
- Proper `default_scene_id` and `default_story_graph_id`
- Full settings block matching the engine's `Project` struct schema

**Task 5 from AGENT_PROMPT_DJ_ENGINE.md is already complete.**

### Test Packages Available

You can generate test `.djpak` and `.djproj` files from DoomExe:

```bash
# From the dj-engine-releases repo root:
bash scripts/package-djpak.sh /path/to/DJ-Engine/games/dev/doomexe /tmp/doomexe.djpak --engine-version 0.1.0
bash scripts/package-djproj.sh /path/to/DJ-Engine/games/dev/doomexe /tmp/doomexe.djproj

# Verify integrity:
bash scripts/verify-djpak.sh /tmp/doomexe.djpak
```

These produce real, valid test artifacts for developing the engine loaders.

## What the Engine Agent Needs to Implement

See `AGENT_PROMPT_DJ_ENGINE.md` for the full spec. Summary of remaining tasks:

### Task 1: CLI Argument Support (Priority: High)
- Add `--play <path.djpak>` and `--open <path.djproj>` flags
- Create `LaunchMode` resource (`Play(PathBuf)`, `Edit(PathBuf)`, `Editor`)
- Parse before `App::new()`, insert as Bevy resource
- File: `engine/src/main.rs`

### Task 2: .djpak Loader (Priority: High)
- Open ZIP, verify `checksum.sha256`, parse `manifest.json`
- Extract to read-only temp dir (`tempfile::TempDir`)
- Convert `DjpakManifest` → engine's `Project` struct
- Mount as `MountedProject`, launch Runtime Preview
- New file: `engine/src/data/djpak.rs`
- Dependencies to add: `zip = "2"`, `sha2 = "0.10"`, `tempfile = "3"`

### Task 3: .djproj Loader (Priority: Medium)
- Similar to `.djpak` but writable extraction
- Load `project.json` via existing `loader::load_project()`
- On save: re-zip back to `.djproj` path
- New file: `engine/src/data/djproj.rs`

### Task 4: Makefile Export Commands (Priority: Low)
- Add `package-djproj` and `package-djpak` targets to DJ-Engine's Makefile
- Convenience wrappers — the scripts in this repo do the real work

### Task 6: Integration Tests (Priority: Medium)
- Round-trip `.djproj` test
- `.djpak` checksum verification test
- CLI flag parsing tests
- Manifest-to-Project conversion test

### Task 7: E2E Validation (Priority: Low — blocked on Tasks 1-3)
- Build engine, package DoomExe, run `dj_engine.exe --play doomexe.djpak`
- Verify title screen loads and game is playable

## Schema Reference

### manifest.json (what the engine's .djpak loader must parse)

```json
{
  "format_version": "1.0.0",
  "name": "DoomExe",
  "version": "0.1.0",
  "engine_version": "0.1.0",
  "default_resolution": { "width": 1280, "height": 720 },
  "target_fps": 60,
  "vsync": true,
  "pixel_perfect": true,
  "input_profile": "jrpg",
  "localization": { "languages": ["en"], "default_language": "en" },
  "paths": {
    "scenes": "scenes",
    "story_graphs": "story_graphs",
    "database": "database",
    "assets": "assets"
  },
  "startup": {
    "default_scene_id": "overworld",
    "default_story_graph_id": "intro",
    "entry_script": null
  },
  "scenes": [
    { "id": "overworld", "path": "scenes/overworld.json" },
    { "id": "cellar", "path": "scenes/cellar.json" }
  ],
  "story_graphs": [
    { "id": "intro", "path": "story_graphs/intro.json" }
  ],
  "packed_at": "2026-04-11T21:00:00Z",
  "source_project_id": "uuid-from-project.json"
}
```

### project.json (what the engine already loads for .djproj)

The engine's existing `Project` struct should already handle `project.json`. The `.djproj` loader just needs to extract the ZIP and call the existing loader.

### checksum.sha256 format

```
<sha256-hex>  <relative-path>
a1b2c3d4...  manifest.json
e5f6a7b8...  scenes/overworld.json
```

Two spaces between hash and path. One line per file. `checksum.sha256` itself is not listed.

## Constraints Reminder

- **DO NOT** restore GitHub Actions execution, including `workflow_dispatch`; use the maintained local gate
- **DO NOT** break the existing 2,097+ tests
- **DO NOT** modify the Runtime Preview state machine — wire it to load from extracted dir
- **DO** keep zero clippy warnings
- **DO** ensure `make dev-exe` still works (Windows cross-compile)

## Communication

- File issues or leave PR comments on [dj-engine-releases](https://github.com/DJ-Game-Studios/dj-engine-releases) if packages are malformed or specs need updating
- The release agent monitors this repo and will update packaging scripts / specs as needed
- Coordinate via DJ if schema changes are needed that affect both repos
