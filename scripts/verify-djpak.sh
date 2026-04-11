#!/usr/bin/env bash
# verify-djpak.sh — Verify the integrity and structure of a .djpak archive.
#
# Usage:
#   ./scripts/verify-djpak.sh <file.djpak>
#
# Checks:
#   1. Archive is a valid ZIP
#   2. manifest.json exists and is valid
#   3. checksum.sha256 exists
#   4. All checksums match
#   5. All referenced scenes and story graphs exist

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
    echo "Usage: $0 <file.djpak>"
    exit 1
fi

DJPAK="$(realpath "$1")"
ERRORS=0
WARNINGS=0

if [[ ! -f "$DJPAK" ]]; then
    log_error "File not found: $DJPAK"
    exit 1
fi

echo "=== DJ-Engine .djpak Verification ==="
echo "  File: $DJPAK"
echo ""

# --- Check 1: Valid ZIP ---

echo "[1/5] ZIP integrity..."
if unzip -t "$DJPAK" > /dev/null 2>&1; then
    log_pass "Valid ZIP archive"
else
    log_fail "Not a valid ZIP archive"
    exit 1
fi

# --- Extract to temp dir ---

EXTRACT=$(mktemp -d)
trap 'rm -rf "$EXTRACT"' EXIT
unzip -q "$DJPAK" -d "$EXTRACT"

# --- Check 2: manifest.json ---

echo "[2/5] Manifest validation..."
if [[ ! -f "$EXTRACT/manifest.json" ]]; then
    log_fail "manifest.json not found"
    ERRORS=$((ERRORS + 1))
else
    if python3 -c "import json; json.load(open('$EXTRACT/manifest.json'))" 2>/dev/null; then
        log_pass "manifest.json is valid JSON"

        # Check required fields
        for field in format_version name engine_version; do
            if python3 -c "import json,sys; d=json.load(open('$EXTRACT/manifest.json')); sys.exit(0 if '$field' in d else 1)" 2>/dev/null; then
                log_pass "manifest contains '$field'"
            else
                log_fail "manifest missing required field '$field'"
                ERRORS=$((ERRORS + 1))
            fi
        done

        # Print manifest info
        python3 -c "
import json
m = json.load(open('$EXTRACT/manifest.json'))
print(f\"  Game:           {m.get('name', '?')}\")
print(f\"  Version:        {m.get('version', '?')}\")
print(f\"  Engine:         {m.get('engine_version', '?')}\")
print(f\"  Format:         {m.get('format_version', '?')}\")
print(f\"  Packed at:      {m.get('packed_at', '?')}\")
" 2>/dev/null || true
    else
        log_fail "manifest.json is not valid JSON"
        ERRORS=$((ERRORS + 1))
    fi
fi

# --- Check 3: checksum.sha256 ---

echo "[3/5] Checksum file..."
if [[ ! -f "$EXTRACT/checksum.sha256" ]]; then
    log_fail "checksum.sha256 not found"
    ERRORS=$((ERRORS + 1))
else
    CHECKSUM_LINES=$(wc -l < "$EXTRACT/checksum.sha256")
    log_pass "checksum.sha256 found ($CHECKSUM_LINES entries)"
fi

# --- Check 4: Verify checksums ---

echo "[4/5] Checksum verification..."
if [[ -f "$EXTRACT/checksum.sha256" ]]; then
    CHECKSUM_ERRORS=0
    while IFS= read -r line; do
        expected_hash=$(echo "$line" | awk '{print $1}')
        file_path=$(echo "$line" | awk '{print $2}')

        if [[ ! -f "$EXTRACT/$file_path" ]]; then
            log_fail "Missing file: $file_path"
            CHECKSUM_ERRORS=$((CHECKSUM_ERRORS + 1))
            continue
        fi

        actual_hash=$(sha256sum "$EXTRACT/$file_path" | awk '{print $1}')
        if [[ "$expected_hash" != "$actual_hash" ]]; then
            log_fail "Checksum mismatch: $file_path"
            CHECKSUM_ERRORS=$((CHECKSUM_ERRORS + 1))
        fi
    done < "$EXTRACT/checksum.sha256"

    if [[ $CHECKSUM_ERRORS -eq 0 ]]; then
        log_pass "All $CHECKSUM_LINES checksums verified"
    else
        log_fail "$CHECKSUM_ERRORS checksum error(s)"
        ERRORS=$((ERRORS + CHECKSUM_ERRORS))
    fi

    # Check for files not in checksum list
    UNLISTED=$(cd "$EXTRACT" && find . -type f -not -name "checksum.sha256" | sort | while read -r file; do
        relative="${file#./}"
        if ! grep -q "  $relative$" checksum.sha256 2>/dev/null; then
            echo "$relative"
        fi
    done)
    if [[ -n "$UNLISTED" ]]; then
        log_warn "Files not in checksum.sha256:"
        echo "$UNLISTED" | while read -r f; do
            echo "    $f"
        done
        WARNINGS=$((WARNINGS + 1))
    fi
else
    log_warn "Skipping checksum verification (no checksum.sha256)"
    WARNINGS=$((WARNINGS + 1))
fi

# --- Check 5: Scene and story graph references ---

echo "[5/5] Asset reference validation..."
if [[ -f "$EXTRACT/manifest.json" ]]; then
    REF_ERRORS=0

    # Check scenes (use process substitution to avoid subshell variable loss)
    while IFS= read -r spath; do
        [[ -z "$spath" ]] && continue
        if [[ ! -f "$EXTRACT/$spath" ]]; then
            log_fail "Referenced scene missing: $spath"
            REF_ERRORS=$((REF_ERRORS + 1))
        else
            log_pass "Scene: $spath"
        fi
    done < <(python3 -c "
import json
m = json.load(open('$EXTRACT/manifest.json'))
for s in m.get('scenes', []):
    print(s.get('path', ''))
" 2>/dev/null)

    # Check story graphs (use process substitution to avoid subshell variable loss)
    while IFS= read -r gpath; do
        [[ -z "$gpath" ]] && continue
        if [[ ! -f "$EXTRACT/$gpath" ]]; then
            log_fail "Referenced story graph missing: $gpath"
            REF_ERRORS=$((REF_ERRORS + 1))
        else
            log_pass "Story graph: $gpath"
        fi
    done < <(python3 -c "
import json
m = json.load(open('$EXTRACT/manifest.json'))
for g in m.get('story_graphs', []):
    print(g.get('path', ''))
" 2>/dev/null)

    if [[ $REF_ERRORS -gt 0 ]]; then
        ERRORS=$((ERRORS + REF_ERRORS))
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
