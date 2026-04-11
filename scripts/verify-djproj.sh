#!/usr/bin/env bash
# verify-djproj.sh — Verify the integrity and structure of a .djproj archive.
#
# Usage:
#   ./scripts/verify-djproj.sh <file.djproj>
#
# Checks:
#   1. Archive is a valid ZIP
#   2. project.json exists at archive root and is valid JSON
#   3. All scene refs in project.json point to existing files in the archive
#   4. All story_graph refs point to existing files in the archive
#   5. startup.default_scene_id matches a scene id (if set)
#   6. startup.default_story_graph_id matches a story_graph id (if set)
#   7. File/directory names are snake_case
#   8. All paths use forward slashes

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_pass()  { echo -e "  ${GREEN}PASS${NC}  $*"; }
log_fail()  { echo -e "  ${RED}FAIL${NC}  $*"; }
log_warn()  { echo -e "  ${YELLOW}WARN${NC}  $*"; }
log_info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <file.djproj>"
    exit 1
fi

DJPROJ="$(realpath "$1")"
ERRORS=0
WARNINGS=0

if [[ ! -f "$DJPROJ" ]]; then
    log_error "File not found: $DJPROJ"
    exit 1
fi

echo "=== DJ-Engine .djproj Verification ==="
echo "  File: $DJPROJ"
echo ""

# --- Check 1: Valid ZIP ---

echo "[1/8] ZIP integrity..."
if unzip -t "$DJPROJ" > /dev/null 2>&1; then
    log_pass "Valid ZIP archive"
else
    log_fail "Not a valid ZIP archive"
    exit 1
fi

# --- Extract to temp dir ---

EXTRACT=$(mktemp -d)
trap 'rm -rf "$EXTRACT"' EXIT
unzip -q "$DJPROJ" -d "$EXTRACT"

# --- Check 2: project.json ---

echo "[2/8] Project manifest validation..."
if [[ ! -f "$EXTRACT/project.json" ]]; then
    log_fail "project.json not found at archive root"
    ERRORS=$((ERRORS + 1))
else
    if python3 -c "import json; json.load(open('$EXTRACT/project.json'))" 2>/dev/null; then
        log_pass "project.json is valid JSON"

        # Print project info
        python3 -c "
import json
p = json.load(open('$EXTRACT/project.json'))
print(f\"  Project:        {p.get('name', '?')}\")
print(f\"  Version:        {p.get('version', '?')}\")
print(f\"  ID:             {p.get('id', '?')}\")
scenes = p.get('scenes', [])
graphs = p.get('story_graphs', [])
print(f\"  Scenes:         {len(scenes)}\")
print(f\"  Story graphs:   {len(graphs)}\")
" 2>/dev/null || true
    else
        log_fail "project.json is not valid JSON"
        ERRORS=$((ERRORS + 1))
    fi
fi

# --- Check 3: Scene references ---

echo "[3/8] Scene reference validation..."
if [[ -f "$EXTRACT/project.json" ]]; then
    SCENE_ERRORS=0
    while IFS= read -r spath; do
        [[ -z "$spath" ]] && continue
        if [[ ! -f "$EXTRACT/$spath" ]]; then
            log_fail "Referenced scene missing: $spath"
            SCENE_ERRORS=$((SCENE_ERRORS + 1))
        else
            log_pass "Scene: $spath"
        fi
    done < <(python3 -c "
import json
p = json.load(open('$EXTRACT/project.json'))
for s in p.get('scenes', []):
    print(s.get('path', ''))
" 2>/dev/null)

    if [[ $SCENE_ERRORS -gt 0 ]]; then
        ERRORS=$((ERRORS + SCENE_ERRORS))
    fi
fi

# --- Check 4: Story graph references ---

echo "[4/8] Story graph reference validation..."
if [[ -f "$EXTRACT/project.json" ]]; then
    GRAPH_ERRORS=0
    while IFS= read -r gpath; do
        [[ -z "$gpath" ]] && continue
        if [[ ! -f "$EXTRACT/$gpath" ]]; then
            log_fail "Referenced story graph missing: $gpath"
            GRAPH_ERRORS=$((GRAPH_ERRORS + 1))
        else
            log_pass "Story graph: $gpath"
        fi
    done < <(python3 -c "
import json
p = json.load(open('$EXTRACT/project.json'))
for g in p.get('story_graphs', []):
    print(g.get('path', ''))
" 2>/dev/null)

    if [[ $GRAPH_ERRORS -gt 0 ]]; then
        ERRORS=$((ERRORS + GRAPH_ERRORS))
    fi
fi

# --- Check 5: startup.default_scene_id matches a scene id ---

echo "[5/8] Startup scene ID validation..."
if [[ -f "$EXTRACT/project.json" ]]; then
    STARTUP_SCENE_RESULT=$(python3 -c "
import json, sys
p = json.load(open('$EXTRACT/project.json'))
startup = p.get('settings', {}).get('startup', {})
default_scene_id = startup.get('default_scene_id')
if default_scene_id is None:
    print('SKIP')
    sys.exit(0)
scene_ids = [s.get('id') for s in p.get('scenes', [])]
if default_scene_id in scene_ids:
    print(f'PASS {default_scene_id}')
else:
    print(f'FAIL {default_scene_id}')
" 2>/dev/null || echo "ERROR")

    case "$STARTUP_SCENE_RESULT" in
        SKIP)
            log_pass "startup.default_scene_id not set (optional)"
            ;;
        PASS*)
            SCENE_ID="${STARTUP_SCENE_RESULT#PASS }"
            log_pass "startup.default_scene_id '$SCENE_ID' matches a scene"
            ;;
        FAIL*)
            SCENE_ID="${STARTUP_SCENE_RESULT#FAIL }"
            log_fail "startup.default_scene_id '$SCENE_ID' does not match any scene id"
            ERRORS=$((ERRORS + 1))
            ;;
        *)
            log_warn "Could not validate startup.default_scene_id"
            WARNINGS=$((WARNINGS + 1))
            ;;
    esac
fi

# --- Check 6: startup.default_story_graph_id matches a story_graph id ---

echo "[6/8] Startup story graph ID validation..."
if [[ -f "$EXTRACT/project.json" ]]; then
    STARTUP_GRAPH_RESULT=$(python3 -c "
import json, sys
p = json.load(open('$EXTRACT/project.json'))
startup = p.get('settings', {}).get('startup', {})
default_graph_id = startup.get('default_story_graph_id')
if default_graph_id is None:
    print('SKIP')
    sys.exit(0)
graph_ids = [g.get('id') for g in p.get('story_graphs', [])]
if default_graph_id in graph_ids:
    print(f'PASS {default_graph_id}')
else:
    print(f'FAIL {default_graph_id}')
" 2>/dev/null || echo "ERROR")

    case "$STARTUP_GRAPH_RESULT" in
        SKIP)
            log_pass "startup.default_story_graph_id not set (optional)"
            ;;
        PASS*)
            GRAPH_ID="${STARTUP_GRAPH_RESULT#PASS }"
            log_pass "startup.default_story_graph_id '$GRAPH_ID' matches a story graph"
            ;;
        FAIL*)
            GRAPH_ID="${STARTUP_GRAPH_RESULT#FAIL }"
            log_fail "startup.default_story_graph_id '$GRAPH_ID' does not match any story_graph id"
            ERRORS=$((ERRORS + 1))
            ;;
        *)
            log_warn "Could not validate startup.default_story_graph_id"
            WARNINGS=$((WARNINGS + 1))
            ;;
    esac
fi

# --- Check 7: File/directory names are snake_case ---

echo "[7/8] Snake_case naming convention..."
NAMING_ERRORS=0
while IFS= read -r filepath; do
    # Get the basename of each path component
    # Skip hidden files (like .gitkeep)
    [[ "$filepath" == .* ]] && continue
    basename_file=$(basename "$filepath")
    # Skip hidden files inside directories
    [[ "$basename_file" == .* ]] && continue
    # Check if filename matches snake_case (allow dots for extensions, digits, hyphens in filenames)
    # snake_case: lowercase letters, digits, underscores; extensions allowed
    name_no_ext="${basename_file%.*}"
    if [[ -n "$name_no_ext" ]] && ! echo "$name_no_ext" | grep -qE '^[a-z0-9_]+$'; then
        log_warn "Non-snake_case name: $filepath"
        NAMING_ERRORS=$((NAMING_ERRORS + 1))
    fi
done < <(cd "$EXTRACT" && find . -mindepth 1 -not -path './.git/*' -not -name '.git' | sed 's|^\./||' | sort)

if [[ $NAMING_ERRORS -eq 0 ]]; then
    log_pass "All file/directory names follow snake_case convention"
else
    log_warn "$NAMING_ERRORS file(s) with non-snake_case names"
    WARNINGS=$((WARNINGS + NAMING_ERRORS))
fi

# --- Check 8: All paths use forward slashes ---

echo "[8/8] Path separator validation..."
# Check the ZIP listing for backslashes
BACKSLASH_PATHS=$(unzip -l "$DJPROJ" 2>/dev/null | awk 'NR>3 && NF>=4 && /\\/{print $4}' || true)
if [[ -z "$BACKSLASH_PATHS" ]]; then
    log_pass "All paths use forward slashes"
else
    log_fail "Paths with backslashes found:"
    echo "$BACKSLASH_PATHS" | while read -r p; do
        echo "    $p"
    done
    ERRORS=$((ERRORS + 1))
fi

# --- Summary ---

echo ""
if [[ $ERRORS -eq 0 ]]; then
    log_info "=== VERIFICATION PASSED ($WARNINGS warning(s)) ==="
    exit 0
else
    log_error "=== VERIFICATION FAILED ($ERRORS error(s), $WARNINGS warning(s)) ==="
    exit 1
fi
