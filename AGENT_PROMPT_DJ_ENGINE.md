# Agent Prompt: DJ-Engine — Project Format Support & Release Pipeline Integration

> This prompt is for the DJ-Engine repo agent to implement `.djproj` and `.djpak` format support,
> CLI flags for loading packaged projects, and integration with the `dj-engine-releases` repo.

## Context

DJ-Engine now has a companion release repository (`djmsqrvve/dj-engine-releases`) that handles:
- Building and distributing compiled engine binaries (`.exe` / Linux)
- Packaging games into two new `.dj` project formats

The engine needs to support loading these formats at runtime. This is the sprint scope.

## Sprint Goal

Two files that run together:
1. `dj_engine.exe` — The compiled editor + runtime player
2. `doomexe.djpak` — DoomExe packaged as a playable project

A user downloads both, runs `dj_engine.exe --play doomexe.djpak`, and plays the game.

---

## Task 1: CLI Argument Support

**File:** `engine/src/main.rs` (or wherever the engine binary's main lives)

Add these CLI flags using `clap` or manual `std::env::args` parsing:

```
dj_engine --play <path.djpak>     # Load a sealed .djpak and launch Runtime Preview
dj_engine --open <path.djproj>    # Extract a .djproj and open in the Editor
dj_engine                          # Launch editor with no project (current behavior)
```

Implementation:
1. Parse CLI args before `App::new()` in main
2. If `--play <path>`: set a resource `LaunchMode::Play(PathBuf)` 
3. If `--open <path>`: set a resource `LaunchMode::Edit(PathBuf)`
4. If no args: set `LaunchMode::Editor` (default)
5. The `LaunchMode` resource drives what happens after `App::run()` starts

## Task 2: .djpak Loader

**New file:** `engine/src/data/djpak.rs`

Implement loading a `.djpak` ZIP archive into the engine's runtime:

```rust
use std::path::{Path, PathBuf};
use std::fs;
use zip::ZipArchive;

pub struct DjpakManifest {
    pub format_version: String,
    pub name: String,
    pub version: String,
    pub engine_version: String,
    pub default_resolution: (u32, u32),
    pub target_fps: u32,
    pub pixel_perfect: bool,
    pub input_profile: String,
    pub startup: StartupConfig,
    pub scenes: Vec<SceneRef>,
    pub story_graphs: Vec<StoryGraphRef>,
    pub packed_at: String,
    pub source_project_id: String,
}

pub struct StartupConfig {
    pub default_scene_id: Option<String>,
    pub default_story_graph_id: Option<String>,
    pub entry_script: Option<String>,
}
```

Steps:
1. Open the ZIP archive
2. Read and verify `checksum.sha256` against all files
3. Parse `manifest.json` into `DjpakManifest`
4. Extract to a **read-only temp directory** (use `tempfile::TempDir`)
5. Convert `DjpakManifest` into the engine's existing `Project` struct
6. Mount the extracted directory as a `MountedProject` via `project_mount.rs`
7. Launch the Runtime Preview state machine (Title → Dialogue → Overworld)

**Checksum verification:**
```rust
fn verify_checksums(extract_dir: &Path) -> Result<(), DataError> {
    let checksum_path = extract_dir.join("checksum.sha256");
    let content = fs::read_to_string(&checksum_path)?;
    for line in content.lines() {
        let parts: Vec<&str> = line.splitn(2, "  ").collect();
        if parts.len() != 2 { continue; }
        let expected_hash = parts[0];
        let file_path = extract_dir.join(parts[1]);
        let actual_hash = sha256_file(&file_path)?;
        if expected_hash != actual_hash {
            return Err(DataError::Validation(format!(
                "Checksum mismatch for {}: expected {}, got {}",
                parts[1], expected_hash, actual_hash
            )));
        }
    }
    Ok(())
}
```

**Dependency:** Add `zip = "2"` and `sha2 = "0.10"` to `engine/Cargo.toml`.

## Task 3: .djproj Loader

**New file:** `engine/src/data/djproj.rs`

Similar to `.djpak` but:
1. Extract the ZIP to a **writable** temp directory
2. Load `project.json` via the existing `loader::load_project()` path (no manifest conversion needed)
3. Mount as `MountedProject` in edit mode
4. On save: re-zip the directory back to the `.djproj` path

## Task 4: Project Export Commands (Makefile)

Add to the DJ-Engine `Makefile`:

```makefile
# Package a game project directory as .djproj
package-djproj:
	@echo "Packaging project as .djproj..."
	@if [ ! -f "$(PROJECT)/project.json" ]; then \
		echo "Error: $(PROJECT)/project.json not found"; exit 1; \
	fi
	@cd "$(PROJECT)" && zip -r "$(or $(OUTPUT),$(notdir $(PROJECT)).djproj)" . \
		-x ".git/*" -x "target/*" -x "*.swp"
	@echo "Done: $(or $(OUTPUT),$(notdir $(PROJECT)).djproj)"

# Package a game project directory as .djpak (uses Python helper)
package-djpak:
	@echo "Packaging project as .djpak..."
	@python3 tools/package_djpak.py "$(PROJECT)" \
		--output "$(or $(OUTPUT),$(notdir $(PROJECT)).djpak)" \
		--engine-version "$(shell cargo metadata --format-version 1 -q | python3 -c 'import json,sys; print([p["version"] for p in json.load(sys.stdin)["packages"] if p["name"]=="dj_engine"][0])')"
```

## Task 5: DoomExe Project Manifest

Create `games/dev/doomexe/project.json` that defines DoomExe as a loadable project:

```json
{
  "id": "doomexe-001",
  "name": "DoomExe",
  "version": "0.1.0",
  "settings": {
    "platforms": ["pc"],
    "default_resolution": {"width": 1280, "height": 720},
    "target_fps": 60,
    "vsync": true,
    "pixel_perfect": true,
    "input_profile": "jrpg",
    "localization": {"languages": ["en"], "default_language": "en"},
    "paths": {
      "scenes": "scenes",
      "story_graphs": "story_graphs",
      "database": "database",
      "assets": "assets",
      "data": "data"
    },
    "startup": {
      "default_scene_id": "starter",
      "default_story_graph_id": "intro"
    }
  },
  "scenes": [
    {"id": "starter", "path": "scenes/starter.json"}
  ],
  "story_graphs": [
    {"id": "intro", "path": "story_graphs/intro.json"}
  ]
}
```

This manifest allows the release scripts to package DoomExe into `.djproj` and `.djpak` formats.

## Task 6: Integration Tests

Add tests in `engine/src/data/` (or a `tests/` module):

### 6a. Round-trip .djproj test
```rust
#[test]
fn test_djproj_round_trip() {
    // 1. Create a temp project directory with project.json + scenes + story_graphs
    // 2. Package it as .djproj using the packaging function
    // 3. Load the .djproj via the djproj loader
    // 4. Assert the loaded Project matches the original
}
```

### 6b. .djpak integrity test
```rust
#[test]
fn test_djpak_checksum_verification() {
    // 1. Create a .djpak with valid checksums
    // 2. Verify it loads successfully
    // 3. Tamper with a file inside
    // 4. Assert checksum verification fails
}
```

### 6c. CLI integration test
```rust
#[test]
fn test_cli_play_flag_parsing() {
    // Test that --play <path> correctly produces LaunchMode::Play(path)
}

#[test]
fn test_cli_open_flag_parsing() {
    // Test that --open <path> correctly produces LaunchMode::Edit(path)
}
```

### 6d. Manifest conversion test
```rust
#[test]
fn test_djpak_manifest_to_project_conversion() {
    // 1. Create a DjpakManifest
    // 2. Convert to Project
    // 3. Assert all fields map correctly
    // 4. Assert editor_preferences are default (not from .djpak)
}
```

## Task 7: E2E Validation

After implementing the above, verify the full flow:

```bash
# 1. Build the engine
make dev-exe

# 2. Create a project.json for doomexe (if not done in Task 5)
# 3. Package doomexe
make package-djpak PROJECT=games/dev/doomexe OUTPUT=dist/doomexe.djpak

# 4. Run the packaged game
./dist/dj_engine.exe --play dist/doomexe.djpak

# Expected: DoomExe title screen loads and is playable
```

## Dependencies to Add

In `engine/Cargo.toml`:
```toml
[dependencies]
zip = "2"          # ZIP archive reading/writing
sha2 = "0.10"     # SHA-256 checksum verification
tempfile = "3"     # Temporary directories for extraction
clap = { version = "4", features = ["derive"] }  # CLI argument parsing (if not already present)
```

## File Structure (New Files)

```
engine/
  src/
    data/
      djpak.rs          # .djpak loader + checksum verification
      djproj.rs         # .djproj loader + save-back
      mod.rs            # Add pub mod djpak; pub mod djproj;
    main.rs             # Add CLI arg parsing + LaunchMode resource
games/
  dev/
    doomexe/
      project.json      # DoomExe project manifest (NEW)
```

## Constraints

- **DO NOT** use automatic GitHub Actions triggers (push/pull_request). Use `workflow_dispatch` only — billing constraint.
- **DO NOT** break the existing 2,097+ tests. Run `make test` before committing.
- **DO NOT** modify the Runtime Preview state machine — just wire it to load from the extracted `.djpak` directory instead of a hardcoded path.
- **DO** keep zero clippy warnings. Run `make clippy` before committing.
- **DO** follow existing code conventions in `engine/src/data/` (error types, result patterns, module structure).
- **DO** ensure `make dev-exe` still works after changes (Windows cross-compile).

## Priority Order

1. DoomExe `project.json` (Task 5) — unblocks packaging
2. CLI args (Task 1) — small, foundational
3. `.djpak` loader (Task 2) — enables `--play`
4. `.djproj` loader (Task 3) — enables `--open`
5. Integration tests (Task 6) — validates everything
6. Makefile export commands (Task 4) — convenience
7. E2E validation (Task 7) — final proof
