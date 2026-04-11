#!/usr/bin/env python3
"""Generate a project.json manifest from a DJ-Engine game's asset structure.

Usage:
    python3 generate-project-json.py <game-dir> --name <name> --version <version>

Scans the game directory for scenes, story graphs, database files, and assets,
then writes a project.json manifest that the packaging scripts can use.
"""

import argparse
import json
import os
import sys
import uuid
from pathlib import Path


def find_json_files(base_dir: Path, subdir: str) -> list[dict]:
    """Find all JSON files in a subdirectory and return references."""
    target = base_dir / subdir
    refs = []
    if target.is_dir():
        for f in sorted(target.glob("*.json")):
            file_id = f.stem  # filename without extension
            refs.append({
                "id": file_id,
                "path": f"{subdir}/{f.name}",
            })
    return refs


def detect_assets(base_dir: Path, assets_dir: str = "assets") -> dict:
    """Detect what kinds of assets exist."""
    target = base_dir / assets_dir
    asset_info = {
        "audio": [],
        "music": [],
        "sprites": [],
        "scripts": [],
    }
    if not target.is_dir():
        return asset_info

    for root, _dirs, files in os.walk(target):
        rel_root = Path(root).relative_to(target)
        for f in sorted(files):
            rel_path = str(rel_root / f)
            ext = Path(f).suffix.lower()
            if ext in (".ogg", ".wav", ".mp3"):
                if "music" in rel_path.lower() or "bgm" in rel_path.lower():
                    asset_info["music"].append(rel_path)
                else:
                    asset_info["audio"].append(rel_path)
            elif ext in (".mid", ".midi"):
                asset_info["music"].append(rel_path)
            elif ext in (".png", ".jpg", ".bmp"):
                asset_info["sprites"].append(rel_path)
            elif ext in (".lua",):
                asset_info["scripts"].append(rel_path)

    return asset_info


def generate_project(game_dir: Path, name: str, version: str) -> dict:
    """Generate a project.json structure from the game directory."""
    scenes = find_json_files(game_dir, "scenes")
    story_graphs = find_json_files(game_dir, "story_graphs")

    # Determine startup defaults
    default_scene_id = scenes[0]["id"] if scenes else None
    default_story_graph_id = story_graphs[0]["id"] if story_graphs else None

    # Check which standard directories exist
    has_database = (game_dir / "database").is_dir()
    has_assets = (game_dir / "assets").is_dir()
    has_data = (game_dir / "data").is_dir()

    project = {
        "id": str(uuid.uuid4()),
        "name": name,
        "version": version,
        "settings": {
            "platforms": ["pc"],
            "default_resolution": {"width": 1280, "height": 720},
            "target_fps": 60,
            "vsync": True,
            "pixel_perfect": True,
            "input_profile": "jrpg",
            "localization": {
                "languages": ["en"],
                "default_language": "en",
            },
            "paths": {
                "scenes": "scenes",
                "story_graphs": "story_graphs",
                "database": "database",
                "assets": "assets",
                "data": "data",
            },
            "startup": {
                "default_scene_id": default_scene_id,
                "default_story_graph_id": default_story_graph_id,
                "entry_script": None,
            },
            "autosave": {
                "enabled": True,
                "interval_seconds": 300,
                "max_backups": 10,
            },
        },
        "editor_preferences": {
            "theme": "dark",
            "ui_scale": 1.0,
            "font_size": 14,
            "grid_size": {"width": 32, "height": 32},
            "snap": {
                "position": 16.0,
                "rotation": 15.0,
                "scale": 0.25,
                "enabled": True,
            },
            "default_gizmo_mode": "move",
            "keybindings": {},
            "layout_preset": "jrpg_mapping",
        },
        "scenes": scenes,
        "story_graphs": story_graphs,
    }

    return project


def main():
    parser = argparse.ArgumentParser(
        description="Generate project.json for a DJ-Engine game"
    )
    parser.add_argument("game_dir", type=Path, help="Path to the game directory")
    parser.add_argument("--name", required=True, help="Game name")
    parser.add_argument("--version", default="0.1.0", help="Game version")
    parser.add_argument(
        "--output",
        type=Path,
        default=None,
        help="Output path (default: <game_dir>/project.json)",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Overwrite existing project.json",
    )

    args = parser.parse_args()

    if not args.game_dir.is_dir():
        print(f"Error: {args.game_dir} is not a directory", file=sys.stderr)
        sys.exit(1)

    output = args.output or (args.game_dir / "project.json")

    if output.exists() and not args.force:
        print(f"project.json already exists at {output}")
        print("Use --force to overwrite")
        sys.exit(0)

    project = generate_project(args.game_dir, args.name, args.version)

    with open(output, "w") as f:
        json.dump(project, f, indent=2)

    scene_count = len(project["scenes"])
    graph_count = len(project["story_graphs"])
    print(f"Generated {output}")
    print(f"  Name:         {args.name}")
    print(f"  Version:      {args.version}")
    print(f"  Scenes:       {scene_count}")
    print(f"  Story graphs: {graph_count}")
    print(f"  ID:           {project['id']}")


if __name__ == "__main__":
    main()
