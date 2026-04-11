#!/usr/bin/env bash
# package-djproj.sh — Package a DJ-Engine project directory into a .djproj archive.
#
# Usage:
#   ./scripts/package-djproj.sh <project-dir> [output.djproj]
#
# The project directory must contain a valid project.json manifest.
# If no output path is given, the archive is written to <project-name>.djproj
# in the current directory.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

usage() {
    echo "Usage: $0 <project-dir> [output.djproj]"
    echo ""
    echo "Package a DJ-Engine project directory into a .djproj archive."
    echo ""
    echo "Arguments:"
    echo "  project-dir    Path to the project directory (must contain project.json)"
    echo "  output.djproj  Output file path (default: <project-name>.djproj)"
    exit 1
}

log_info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# --- Argument parsing ---

if [[ $# -lt 1 ]]; then
    usage
fi

PROJECT_DIR="$(realpath "$1")"
OUTPUT="${2:-}"

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

# Validate JSON is parseable
if ! python3 -c "import json; json.load(open('$MANIFEST'))" 2>/dev/null; then
    log_error "project.json is not valid JSON"
    exit 1
fi

# Extract project name for default output filename
PROJECT_NAME=$(python3 -c "import json; print(json.load(open('$MANIFEST')).get('name', 'project'))" 2>/dev/null || echo "project")
PROJECT_SLUG=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd '[:alnum:]_')

if [[ -z "$OUTPUT" ]]; then
    OUTPUT="${PROJECT_SLUG}.djproj"
fi

# --- Validate scene and story graph references ---

log_info "Validating project structure..."

ERRORS=0

# Check that referenced scenes exist
SCENE_PATHS=$(python3 -c "
import json
project = json.load(open('$MANIFEST'))
for scene in project.get('scenes', []):
    print(scene.get('path', ''))
" 2>/dev/null || true)

while IFS= read -r scene_path; do
    [[ -z "$scene_path" ]] && continue
    if [[ ! -f "$PROJECT_DIR/$scene_path" ]]; then
        log_error "Referenced scene not found: $scene_path"
        ERRORS=$((ERRORS + 1))
    fi
done <<< "$SCENE_PATHS"

# Check that referenced story graphs exist
GRAPH_PATHS=$(python3 -c "
import json
project = json.load(open('$MANIFEST'))
for graph in project.get('story_graphs', []):
    print(graph.get('path', ''))
" 2>/dev/null || true)

while IFS= read -r graph_path; do
    [[ -z "$graph_path" ]] && continue
    if [[ ! -f "$PROJECT_DIR/$graph_path" ]]; then
        log_error "Referenced story graph not found: $graph_path"
        ERRORS=$((ERRORS + 1))
    fi
done <<< "$GRAPH_PATHS"

if [[ $ERRORS -gt 0 ]]; then
    log_error "$ERRORS validation error(s) found. Aborting."
    exit 1
fi

log_info "Validation passed."

# --- Package ---

log_info "Packaging $PROJECT_NAME -> $OUTPUT"

# Create the ZIP archive from inside the project directory so paths are relative
ABSOLUTE_OUTPUT="$(realpath -m "$OUTPUT")"

# Remove existing output if present
rm -f "$ABSOLUTE_OUTPUT"

(cd "$PROJECT_DIR" && zip -r -q "$ABSOLUTE_OUTPUT" . \
    -x ".git/*" \
    -x "target/*" \
    -x "node_modules/*" \
    -x "*.swp" \
    -x "*.swo" \
    -x ".DS_Store" \
    -x "Thumbs.db" \
    -x "logs/*" \
    -x "test-results/*" \
)

# Verify the output was created
if [[ ! -f "$ABSOLUTE_OUTPUT" ]]; then
    log_error "Failed to create archive"
    exit 1
fi

SIZE=$(stat -c%s "$ABSOLUTE_OUTPUT" 2>/dev/null || stat -f%z "$ABSOLUTE_OUTPUT" 2>/dev/null || echo "unknown")
FILE_COUNT=$(unzip -l "$ABSOLUTE_OUTPUT" 2>/dev/null | tail -1 | awk '{print $2}')

log_info "Package created successfully:"
log_info "  Output:     $ABSOLUTE_OUTPUT"
log_info "  Size:       $SIZE bytes"
log_info "  Files:      $FILE_COUNT"
log_info "  Project:    $PROJECT_NAME"
