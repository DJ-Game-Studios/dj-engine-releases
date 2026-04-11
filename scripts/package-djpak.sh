#!/usr/bin/env bash
# package-djpak.sh — Package a DJ-Engine project directory into a sealed .djpak archive.
#
# Usage:
#   ./scripts/package-djpak.sh <project-dir> [output.djpak] [--engine-version <ver>]
#
# The project directory must contain a valid project.json manifest.
# The .djpak format strips editor metadata, minifies JSON, and includes
# integrity checksums. It is designed for end-user distribution.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

usage() {
    echo "Usage: $0 <project-dir> [output.djpak] [--engine-version <ver>]"
    echo ""
    echo "Package a DJ-Engine project directory into a sealed .djpak archive."
    echo ""
    echo "Arguments:"
    echo "  project-dir          Path to the project directory (must contain project.json)"
    echo "  output.djpak         Output file path (default: <project-name>.djpak)"
    echo "  --engine-version     Engine version to embed in manifest (default: 0.1.0)"
    exit 1
}

log_info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# --- Argument parsing ---

PROJECT_DIR=""
OUTPUT=""
ENGINE_VERSION="0.1.0"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --engine-version)
            ENGINE_VERSION="$2"
            shift 2
            ;;
        --help|-h)
            usage
            ;;
        *)
            if [[ -z "$PROJECT_DIR" ]]; then
                PROJECT_DIR="$1"
            elif [[ -z "$OUTPUT" ]]; then
                OUTPUT="$1"
            else
                log_error "Unexpected argument: $1"
                usage
            fi
            shift
            ;;
    esac
done

if [[ -z "$PROJECT_DIR" ]]; then
    usage
fi

PROJECT_DIR="$(realpath "$PROJECT_DIR")"

# --- Validation ---

if [[ ! -d "$PROJECT_DIR" ]]; then
    log_error "Project directory does not exist: $PROJECT_DIR"
    exit 1
fi

MANIFEST="$PROJECT_DIR/project.json"
if [[ ! -f "$MANIFEST" ]]; then
    log_error "No project.json found in $PROJECT_DIR"
    exit 1
fi

if ! python3 -c "import json; json.load(open('$MANIFEST'))" 2>/dev/null; then
    log_error "project.json is not valid JSON"
    exit 1
fi

PROJECT_NAME=$(python3 -c "import json; print(json.load(open('$MANIFEST')).get('name', 'project'))" 2>/dev/null || echo "project")
PROJECT_SLUG=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd '[:alnum:]_')

if [[ -z "$OUTPUT" ]]; then
    OUTPUT="${PROJECT_SLUG}.djpak"
fi

ABSOLUTE_OUTPUT="$(realpath -m "$OUTPUT")"

# --- Build staging directory ---

STAGING=$(mktemp -d)
trap 'rm -rf "$STAGING"' EXIT

log_info "Packaging $PROJECT_NAME as .djpak (engine $ENGINE_VERSION)"
log_info "Staging in: $STAGING"

# --- Generate runtime manifest.json ---

log_info "Generating runtime manifest..."

python3 - "$MANIFEST" "$STAGING/manifest.json" "$ENGINE_VERSION" << 'PYTHON_SCRIPT'
import json
import sys
from datetime import datetime, timezone

source_path = sys.argv[1]
output_path = sys.argv[2]
engine_version = sys.argv[3]

with open(source_path) as f:
    project = json.load(f)

settings = project.get("settings", {})
paths = settings.get("paths", {})
startup = settings.get("startup", {})

manifest = {
    "format_version": "1.0.0",
    "name": project.get("name", "Unknown"),
    "version": project.get("version", "0.1.0"),
    "engine_version": engine_version,
    "default_resolution": settings.get("default_resolution", {"width": 1280, "height": 720}),
    "target_fps": settings.get("target_fps", 60),
    "vsync": settings.get("vsync", True),
    "pixel_perfect": settings.get("pixel_perfect", True),
    "input_profile": settings.get("input_profile", "jrpg"),
    "localization": settings.get("localization", {"languages": ["en"], "default_language": "en"}),
    "paths": {
        "scenes": paths.get("scenes", "scenes"),
        "story_graphs": paths.get("story_graphs", "story_graphs"),
        "database": paths.get("database", "database"),
        "assets": paths.get("assets", "assets"),
    },
    "startup": {
        "default_scene_id": startup.get("default_scene_id"),
        "default_story_graph_id": startup.get("default_story_graph_id"),
        "entry_script": startup.get("entry_script"),
    },
    "scenes": project.get("scenes", []),
    "story_graphs": project.get("story_graphs", []),
    "packed_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "source_project_id": project.get("id", "unknown"),
}

with open(output_path, "w") as f:
    json.dump(manifest, f, separators=(",", ":"))

print(f"  manifest.json written ({len(json.dumps(manifest, separators=(',', ':')))} bytes)")
PYTHON_SCRIPT

# --- Copy and minify scene files ---

SCENES_DIR=$(python3 -c "import json; print(json.load(open('$MANIFEST')).get('settings',{}).get('paths',{}).get('scenes','scenes'))" 2>/dev/null || echo "scenes")

if [[ -d "$PROJECT_DIR/$SCENES_DIR" ]]; then
    log_info "Minifying scenes..."
    mkdir -p "$STAGING/$SCENES_DIR"
    for scene_file in "$PROJECT_DIR/$SCENES_DIR"/*.json; do
        [[ -f "$scene_file" ]] || continue
        basename_file=$(basename "$scene_file")
        python3 -c "import json; data=json.load(open('$scene_file')); json.dump(data, open('$STAGING/$SCENES_DIR/$basename_file','w'), separators=(',',':'))"
        echo "  $SCENES_DIR/$basename_file"
    done
fi

# --- Copy and minify story graph files ---

GRAPHS_DIR=$(python3 -c "import json; print(json.load(open('$MANIFEST')).get('settings',{}).get('paths',{}).get('story_graphs','story_graphs'))" 2>/dev/null || echo "story_graphs")

if [[ -d "$PROJECT_DIR/$GRAPHS_DIR" ]]; then
    log_info "Minifying story graphs..."
    mkdir -p "$STAGING/$GRAPHS_DIR"
    for graph_file in "$PROJECT_DIR/$GRAPHS_DIR"/*.json; do
        [[ -f "$graph_file" ]] || continue
        basename_file=$(basename "$graph_file")
        python3 -c "import json; data=json.load(open('$graph_file')); json.dump(data, open('$STAGING/$GRAPHS_DIR/$basename_file','w'), separators=(',',':'))"
        echo "  $GRAPHS_DIR/$basename_file"
    done
fi

# --- Copy and minify database files ---

DB_DIR=$(python3 -c "import json; print(json.load(open('$MANIFEST')).get('settings',{}).get('paths',{}).get('database','database'))" 2>/dev/null || echo "database")

if [[ -d "$PROJECT_DIR/$DB_DIR" ]]; then
    log_info "Minifying database..."
    mkdir -p "$STAGING/$DB_DIR"
    for db_file in "$PROJECT_DIR/$DB_DIR"/*.json; do
        [[ -f "$db_file" ]] || continue
        basename_file=$(basename "$db_file")
        python3 -c "import json; data=json.load(open('$db_file')); json.dump(data, open('$STAGING/$DB_DIR/$basename_file','w'), separators=(',',':'))"
        echo "  $DB_DIR/$basename_file"
    done
fi

# --- Copy binary assets (unchanged) ---

ASSETS_DIR=$(python3 -c "import json; print(json.load(open('$MANIFEST')).get('settings',{}).get('paths',{}).get('assets','assets'))" 2>/dev/null || echo "assets")

if [[ -d "$PROJECT_DIR/$ASSETS_DIR" ]]; then
    log_info "Copying assets..."
    cp -r "$PROJECT_DIR/$ASSETS_DIR" "$STAGING/$ASSETS_DIR"
    ASSET_COUNT=$(find "$STAGING/$ASSETS_DIR" -type f | wc -l)
    echo "  $ASSET_COUNT asset files copied"
fi

# --- Generate checksums ---

log_info "Generating checksums..."

(cd "$STAGING" && find . -type f -not -name "checksum.sha256" | sort | while read -r file; do
    # Strip leading ./
    relative_path="${file#./}"
    sha256sum "$file" | awk -v path="$relative_path" '{print $1 "  " path}'
done > checksum.sha256)

CHECKSUM_LINES=$(wc -l < "$STAGING/checksum.sha256")
log_info "  $CHECKSUM_LINES checksums written"

# --- Create the .djpak archive ---

log_info "Creating archive..."

rm -f "$ABSOLUTE_OUTPUT"
(cd "$STAGING" && zip -r -q "$ABSOLUTE_OUTPUT" .)

if [[ ! -f "$ABSOLUTE_OUTPUT" ]]; then
    log_error "Failed to create archive"
    exit 1
fi

SIZE=$(stat -c%s "$ABSOLUTE_OUTPUT" 2>/dev/null || stat -f%z "$ABSOLUTE_OUTPUT" 2>/dev/null || echo "unknown")
FILE_COUNT=$(unzip -l "$ABSOLUTE_OUTPUT" 2>/dev/null | tail -1 | awk '{print $2}')

echo ""
log_info "=== .djpak package created ==="
log_info "  Output:         $ABSOLUTE_OUTPUT"
log_info "  Size:           $SIZE bytes"
log_info "  Files:          $FILE_COUNT"
log_info "  Game:           $PROJECT_NAME"
log_info "  Engine version: $ENGINE_VERSION"
log_info "  Format version: 1.0.0"
echo ""
log_info "Play with: dj_engine --play $ABSOLUTE_OUTPUT"
