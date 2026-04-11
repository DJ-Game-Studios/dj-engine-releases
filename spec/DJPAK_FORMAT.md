# `.djpak` Format Specification

> Version: 1.0.0
> Engine Compatibility: DJ-Engine 0.1.0+ (Bevy 0.18)

## Overview

A `.djpak` file is a **ZIP archive** (renamed with the `.djpak` extension) containing a sealed, playable game package. It is the distribution format for end-users who want to play a game built with DJ-Engine. Data is minified, editor metadata is stripped, and an integrity checksum is included.

## Archive Structure

```
<game-name>.djpak (ZIP)
  manifest.json             # REQUIRED — Runtime manifest (minimal)
  scenes/                   # REQUIRED — Minified scene files
    *.json
  story_graphs/             # OPTIONAL — Minified story graph files
    *.json
  database/                 # OPTIONAL — Merged game database
    database.json
  assets/                   # OPTIONAL — Binary assets (unchanged)
    audio/
    music/
    sprites/
    palettes/
    scripts/
  checksum.sha256           # REQUIRED — SHA-256 checksums for all files
```

## manifest.json Schema

The runtime manifest is a stripped-down version of `project.json`, containing only what the runtime player needs:

```json
{
  "format_version": "1.0.0",
  "name": "Game Name",
  "version": "0.1.0",
  "engine_version": "0.1.0",
  "default_resolution": { "width": 1280, "height": 720 },
  "target_fps": 60,
  "vsync": true,
  "pixel_perfect": true,
  "input_profile": "jrpg",
  "localization": {
    "languages": ["en"],
    "default_language": "en"
  },
  "paths": {
    "scenes": "scenes",
    "story_graphs": "story_graphs",
    "database": "database",
    "assets": "assets"
  },
  "startup": {
    "default_scene_id": "starter",
    "default_story_graph_id": "intro",
    "entry_script": null
  },
  "scenes": [
    { "id": "scene_id", "path": "scenes/scene_id.json" }
  ],
  "story_graphs": [
    { "id": "graph_id", "path": "story_graphs/graph_id.json" }
  ],
  "packed_at": "2026-04-11T21:00:00Z",
  "source_project_id": "uuid-from-original-project"
}
```

## checksum.sha256 Format

One line per file, SHA-256 hash followed by two spaces and the relative path:

```
a1b2c3d4...  manifest.json
e5f6a7b8...  scenes/starter.json
9c0d1e2f...  assets/audio/hit.ogg
```

## Key Differences from `.djproj`

| Property | `.djproj` | `.djpak` |
|----------|-----------|----------|
| Editable in Editor | Yes | No |
| Editor preferences | Included | Stripped |
| JSON formatting | Pretty-printed | Minified |
| Autosave settings | Included | Stripped |
| Integrity checksums | No | Yes |
| Custom data registry | Included | Stripped (baked into database) |
| Purpose | Development | Distribution |

## Validation Rules

1. `manifest.json` MUST exist at the archive root
2. `manifest.json` MUST contain `format_version`, `name`, `engine_version`
3. `checksum.sha256` MUST exist at the archive root
4. Every file listed in `checksum.sha256` MUST exist in the archive
5. Every file in the archive (except `checksum.sha256` itself) MUST be listed in `checksum.sha256`
6. SHA-256 hashes MUST match the actual file contents
7. Every `SceneRef.path` in `scenes` MUST reference an existing file
8. Every `StoryGraphRef.path` in `story_graphs` MUST reference an existing file
9. `startup.default_scene_id` (if set) MUST match an `id` in `scenes`
10. All paths MUST use forward slashes

## How the Engine Loads a `.djpak`

1. Detect `.djpak` extension on the `--play` CLI argument
2. Verify `checksum.sha256` integrity (fail fast on mismatch)
3. Extract the ZIP archive to a read-only temporary directory
4. Parse `manifest.json` to construct a runtime `Project` equivalent
5. Load the startup scene and story graph
6. Launch the Runtime Preview loop (title screen -> dialogue -> overworld)
7. Save data goes to a user-scoped save directory (not back into the .djpak)

## Packaging a `.djpak`

```bash
# From a project directory:
scripts/package-djpak.sh /path/to/project/dir output.djpak
```

The packaging script:
1. Validates `project.json` exists
2. Generates `manifest.json` (strips editor metadata, adds engine_version + timestamps)
3. Minifies all JSON scene and story graph files
4. Copies binary assets unchanged
5. Generates `checksum.sha256` for every file
6. Creates a ZIP archive with `.djpak` extension

## Security Considerations

- The `.djpak` format does NOT execute arbitrary code by default
- Lua scripts in `assets/scripts/` are sandboxed by the engine's mlua integration
- Checksum verification prevents tampering with distributed packages
- The engine MUST refuse to load a `.djpak` with mismatched checksums
