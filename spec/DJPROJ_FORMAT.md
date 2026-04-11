# `.djproj` Format Specification

> Version: 1.0.0
> Engine Compatibility: DJ-Engine 0.1.0+ (Bevy 0.18)

## Overview

A `.djproj` file is a **ZIP archive** (renamed with the `.djproj` extension) containing a complete, human-readable DJ-Engine project. It is the editable distribution format — designed to be opened, modified, and saved in the DJ-Engine Editor.

## Archive Structure

```
<project-name>.djproj (ZIP)
  project.json              # REQUIRED — Project manifest
  scenes/                   # REQUIRED — Scene definition files
    *.json
  story_graphs/             # REQUIRED — Story graph files
    *.json
  database/                 # OPTIONAL — Game database files
    *.json
  assets/                   # OPTIONAL — Binary assets
    audio/                  # .ogg, .wav sound effects
    music/                  # .mid, .ogg background music
    sprites/                # .png sprite sheets
    palettes/               # .json palette definitions
    scripts/                # .lua game scripts
  data/                     # OPTIONAL — Custom document registry
    registry.json           # Document kind registry
    *.json                  # Individual custom documents
```

## project.json Schema

The root manifest follows the DJ-Engine `Project` struct schema:

```json
{
  "id": "uuid-v4-string",
  "name": "Project Name",
  "version": "0.1.0",
  "settings": {
    "platforms": ["pc"],
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
      "assets": "assets",
      "data": "data"
    },
    "startup": {
      "default_scene_id": "starter",
      "default_story_graph_id": "intro",
      "entry_script": null
    },
    "autosave": {
      "enabled": true,
      "interval_seconds": 300,
      "max_backups": 10
    }
  },
  "editor_preferences": {
    "theme": "dark",
    "ui_scale": 1.0,
    "font_size": 14,
    "grid_size": { "width": 32, "height": 32 },
    "snap": {
      "position": 16.0,
      "rotation": 15.0,
      "scale": 0.25,
      "enabled": true
    },
    "default_gizmo_mode": "move",
    "keybindings": {},
    "layout_preset": "jrpg_mapping"
  },
  "scenes": [
    { "id": "scene_id", "path": "scenes/scene_id.json" }
  ],
  "story_graphs": [
    { "id": "graph_id", "path": "story_graphs/graph_id.json" }
  ]
}
```

## Validation Rules

1. `project.json` MUST exist at the archive root
2. `project.json` MUST be valid JSON conforming to the `Project` schema
3. Every `SceneRef.path` in `scenes` MUST reference an existing file in the archive
4. Every `StoryGraphRef.path` in `story_graphs` MUST reference an existing file in the archive
5. `settings.startup.default_scene_id` (if set) MUST match an `id` in `scenes`
6. `settings.startup.default_story_graph_id` (if set) MUST match an `id` in `story_graphs`
7. `settings.startup.entry_script` (if set) MUST reference an existing file in the archive
8. All JSON files MUST be UTF-8 encoded
9. File paths MUST use forward slashes (`/`) as separators
10. File and directory names MUST be snake_case

## How the Engine Loads a `.djproj`

1. Detect `.djproj` extension on the `--open` CLI argument
2. Extract the ZIP archive to a temporary directory
3. Load `project.json` via the standard `loader::load_project()` path
4. Mount the extracted directory as a `MountedProject`
5. On save, re-pack the directory back to the `.djproj` file

## Packaging a `.djproj`

```bash
# From a project directory:
scripts/package-djproj.sh /path/to/project/dir output.djproj
```

The packaging script:
1. Validates `project.json` exists and is valid JSON
2. Validates all referenced scenes and story graphs exist
3. Creates a ZIP archive of the entire project tree
4. Renames the extension to `.djproj`
