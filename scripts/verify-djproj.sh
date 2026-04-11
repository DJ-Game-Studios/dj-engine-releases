#!/usr/bin/env bash
# verify-djproj.sh — Verify the integrity and structure of a .djproj archive.
#
# Usage:
#   ./scripts/verify-djproj.sh <file.djproj>
#
# Checks:
#   1. Archive is a valid ZIP
#   2. project.json exists and is valid JSON
#   3. All scene refs point to existing files
#   4. All story_graph refs point to existing files
#   5. startup.default_scene_id matches a scene id
#   6. startup.default_story_graph_id matches a story_graph id
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

# --- Check 2: project.json exists and is valid JSON ---

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
print(f\"  Project:  {p.get('name', '?')}\")
print(f\"  ID:       {p.get('id', '?')}\")
print(f\"  Version:  {p.get('version', '?')}\")
" 2>/dev/null || true
    else
        log_fail "project.json is not valid JSON"
        ERRORS=$((ERRORS + 1))
    fi
fi

# --- Check 3: Scene refs point to existing files ---

echo "[3/8] Scene reference validation..."
if [[ -f "$EXTRACT/project.json" ]]; then
    SCENE_ERRORS=0
    SCENE_COUNT=0
    while IFS= read -r spath; do
        [[ -z "$spath" ]] && continue
        SCENE_COUNT=$((SCENE_COUNT + 1))
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

    if [[ $SCENE_COUNT -eq 0 ]]; then
        log_warn "No scenes defined in project.json"
        WARNINGS=$((WARNINGS + 1))
    elif [[ $SCENE_ERRORS -gt 0 ]]; then
        ERRORS=$((ERRORS + SCENE_ERRORS))
    fi
fi

# --- Check 4: Story graph refs point to existing files ---

echo "[4/8] Story graph reference validation..."
if [[ -f "$EXTRACT/project.json" ]]; then
    GRAPH_ERRORS=0
    GRAPH_COUNT=0
    while IFS= read -r gpath; do
        [[ -z "$gpath" ]] && continue
        GRAPH_COUNT=$((GRAPH_COUNT + 1))
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

    if [[ $GRAPH_COUNT -eq 0 ]]; then
        log_warn "No story graphs defined in project.json"
        WARNINGS=$((WARNINGS + 1))
    elif [[ $GRAPH_ERRORS -gt 0 ]]; then
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
    print('NOT_SET')
    sys.exit(0)
scene_ids = [s.get('id') for s in p.get('scenes', [])]
if default_scene_id in scene_ids:
    print('MATCH')
else:
    print('MISMATCH')
" 2>/dev/null || echo "ERROR")

    case "$STARTUP_SCENE_RESULT" in
        MATCH)
            log_pass "startup.default_scene_id references a valid scene"
            ;;
        NOT_SET)
            log_pass "startup.default_scene_id not set (optional)"
            ;;
        MISMATCH)
            log_fail "startup.default_scene_id does not match any scene id"
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
    print('NOT_SET')
    sys.exit(0)
graph_ids = [g.get('id') for g in p.get('story_graphs', [])]
if default_graph_id in graph_ids:
    print('MATCH')
else:
    print('MISMATCH')
" 2>/dev/null || echo "ERROR")

    case "$STARTUP_GRAPH_RESULT" in
        MATCH)
            log_pass "startup.default_story_graph_id references a valid story graph"
            ;;
        NOT_SET)
            log_pass "startup.default_story_graph_id not set (optional)"
            ;;
        MISMATCH)
            log_fail "startup.default_story_graph_id does not match any story graph id"
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
SNAKE_ERRORS=0
# Common convention files that are allowed to use non-snake_case names.
# These are standard in Rust/polyglot projects and are not game content.
SNAKE_CASE_EXCEPTIONS="Cargo.toml|Cargo.lock|README.md|LICENSE|LICENSE-MIT|LICENSE-APACHE|CHANGELOG.md|CONTRIBUTING.md|Makefile|Dockerfile|Justfile|BUILD|WORKSPACE"
while IFS= read -r filepath; do
    [[ -z "$filepath" ]] && continue
    # Get just the filename or directory name
    basename_part=$(basename "$filepath")
    # Skip hidden files and project.json (already validated)
    [[ "$basename_part" == .* ]] && continue
    # Skip known convention files (Cargo.toml, README.md, etc.)
    if echo "$basename_part" | grep -qE "^($SNAKE_CASE_EXCEPTIONS)$"; then
        continue
    fi
    # Skip .md files in docs/ directories — documentation often uses UPPER_CASE
    if [[ "$filepath" == docs/* ]] && [[ "$basename_part" == *.md ]]; then
        continue
    fi
    # snake_case check: allow lowercase letters, digits, underscores, dots, hyphens
    # The key rule: no uppercase letters, no spaces
    if [[ "$basename_part" =~ [A-Z] ]] || [[ "$basename_part" =~ [[:space:]] ]]; then
        log_fail "Non-snake_case name: $filepath"
        SNAKE_ERRORS=$((SNAKE_ERRORS + 1))
    fi
done < <(cd "$EXTRACT" && find . -mindepth 1 | sed 's|^\./||')

if [[ $SNAKE_ERRORS -eq 0 ]]; then
    log_pass "All file/directory names follow snake_case convention"
else
    log_fail "$SNAKE_ERRORS naming violation(s)"
    ERRORS=$((ERRORS + SNAKE_ERRORS))
fi

# --- Check 8: All paths use forward slashes ---

echo "[8/8] Forward slash path convention..."
if [[ -f "$EXTRACT/project.json" ]]; then
    SLASH_RESULT=$(python3 -c "
import json
p = json.load(open('$EXTRACT/project.json'))
errors = 0
for s in p.get('scenes', []):
    path = s.get('path', '')
    if '\\\\' in path:
        print(f'Backslash in scene path: {path}')
        errors += 1
for g in p.get('story_graphs', []):
    path = g.get('path', '')
    if '\\\\' in path:
        print(f'Backslash in story_graph path: {path}')
        errors += 1
startup = p.get('settings', {}).get('startup', {})
entry = startup.get('entry_script', '')
if entry and '\\\\' in entry:
    print(f'Backslash in entry_script: {entry}')
    errors += 1
paths = p.get('settings', {}).get('paths', {})
for key, val in paths.items():
    if isinstance(val, str) and '\\\\' in val:
        print(f'Backslash in paths.{key}: {val}')
        errors += 1
if errors == 0:
    print('OK')
" 2>/dev/null || echo "ERROR")

    if [[ "$SLASH_RESULT" == "OK" ]]; then
        log_pass "All paths use forward slashes"
    elif [[ "$SLASH_RESULT" == "ERROR" ]]; then
        log_warn "Could not validate path separators"
        WARNINGS=$((WARNINGS + 1))
    else
        echo "$SLASH_RESULT" | while IFS= read -r line; do
            log_fail "$line"
        done
        ERRORS=$((ERRORS + 1))
    fi
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
