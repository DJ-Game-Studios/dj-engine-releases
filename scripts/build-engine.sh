#!/usr/bin/env bash
# build-engine.sh — Build DJ-Engine binaries for release distribution.
#
# Usage:
#   ./scripts/build-engine.sh <dj-engine-dir> [--output-dir <dir>] [--windows-only] [--linux-only]
#
# Builds release-optimized binaries with LTO, single codegen unit, and stripping.
# Requires:
#   - Rust 1.94.0 (or whatever is pinned in DJ-Engine's rust-toolchain.toml)
#   - For Windows cross-compile: gcc-mingw-w64-x86-64
#   - Linux build deps: libasound2-dev libudev-dev libwayland-dev libxkbcommon-dev
#     libx11-dev libvulkan-dev clang lld cmake

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

usage() {
    echo "Usage: $0 <dj-engine-dir> [options]"
    echo ""
    echo "Build DJ-Engine binaries for release distribution."
    echo ""
    echo "Arguments:"
    echo "  dj-engine-dir    Path to the DJ-Engine source repo"
    echo ""
    echo "Options:"
    echo "  --output-dir     Directory for built binaries (default: ./releases/)"
    echo "  --windows-only   Build only Windows .exe"
    echo "  --linux-only     Build only Linux binary"
    echo "  --version        Version tag for output filenames (default: timestamp)"
    exit 1
}

log_info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# --- Argument parsing ---

DJ_ENGINE_DIR=""
OUTPUT_DIR="./releases"
BUILD_WINDOWS=true
BUILD_LINUX=true
VERSION=$(date +%Y%m%d-%H%M%S)

while [[ $# -gt 0 ]]; do
    case "$1" in
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --windows-only)
            BUILD_LINUX=false
            shift
            ;;
        --linux-only)
            BUILD_WINDOWS=false
            shift
            ;;
        --version)
            VERSION="$2"
            shift 2
            ;;
        --help|-h)
            usage
            ;;
        *)
            if [[ -z "$DJ_ENGINE_DIR" ]]; then
                DJ_ENGINE_DIR="$1"
            else
                log_error "Unexpected argument: $1"
                usage
            fi
            shift
            ;;
    esac
done

if [[ -z "$DJ_ENGINE_DIR" ]]; then
    usage
fi

DJ_ENGINE_DIR="$(realpath "$DJ_ENGINE_DIR")"

# --- Validation ---

if [[ ! -f "$DJ_ENGINE_DIR/Cargo.toml" ]]; then
    log_error "Not a valid DJ-Engine directory (no Cargo.toml): $DJ_ENGINE_DIR"
    exit 1
fi

if [[ ! -f "$DJ_ENGINE_DIR/engine/Cargo.toml" ]]; then
    log_error "engine/ crate not found in $DJ_ENGINE_DIR"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

# Use the cargo target dir from DJ-Engine's Makefile convention
export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-$HOME/.cargo-targets/dj_engine_bevy18}"

WINDOWS_TARGET="x86_64-pc-windows-gnu"

echo "=== DJ-Engine Release Build ==="
echo "  Source:     $DJ_ENGINE_DIR"
echo "  Output:     $OUTPUT_DIR"
echo "  Version:    $VERSION"
echo "  Windows:    $BUILD_WINDOWS"
echo "  Linux:      $BUILD_LINUX"
echo ""

# --- Build Linux binary ---

if [[ "$BUILD_LINUX" == "true" ]]; then
    log_info "Building Linux binary (release, stripped, LTO)..."

    (cd "$DJ_ENGINE_DIR" && cargo build -p dj_engine --bin dj_engine --release --no-default-features)

    LINUX_BIN="$CARGO_TARGET_DIR/release/dj_engine"
    if [[ -f "$LINUX_BIN" ]]; then
        cp "$LINUX_BIN" "$OUTPUT_DIR/dj_engine"
        cp "$LINUX_BIN" "$OUTPUT_DIR/dj_engine-$VERSION-linux-x86_64"
        chmod +x "$OUTPUT_DIR/dj_engine"
        chmod +x "$OUTPUT_DIR/dj_engine-$VERSION-linux-x86_64"
        LINUX_SIZE=$(stat -c%s "$OUTPUT_DIR/dj_engine" 2>/dev/null || echo "?")
        log_info "Linux binary: $OUTPUT_DIR/dj_engine ($LINUX_SIZE bytes)"
    else
        log_error "Linux build produced no binary at $LINUX_BIN"
        exit 1
    fi
fi

# --- Build Windows .exe ---

if [[ "$BUILD_WINDOWS" == "true" ]]; then
    log_info "Building Windows .exe (cross-compile, release, stripped, LTO)..."

    # Check for mingw cross-compiler
    if ! command -v x86_64-w64-mingw32-gcc &> /dev/null; then
        log_warn "x86_64-w64-mingw32-gcc not found — skipping Windows build"
        log_warn "Install with: sudo apt-get install gcc-mingw-w64-x86-64"
    else
        # Ensure the Rust target is installed
        rustup target add "$WINDOWS_TARGET" 2>/dev/null || true

        (cd "$DJ_ENGINE_DIR" && cargo build -p dj_engine --bin dj_engine --release --no-default-features --target "$WINDOWS_TARGET")

        WINDOWS_BIN="$CARGO_TARGET_DIR/$WINDOWS_TARGET/release/dj_engine.exe"
        if [[ -f "$WINDOWS_BIN" ]]; then
            cp "$WINDOWS_BIN" "$OUTPUT_DIR/dj_engine.exe"
            cp "$WINDOWS_BIN" "$OUTPUT_DIR/dj_engine-$VERSION-windows-x86_64.exe"
            WINDOWS_SIZE=$(stat -c%s "$OUTPUT_DIR/dj_engine.exe" 2>/dev/null || echo "?")
            log_info "Windows binary: $OUTPUT_DIR/dj_engine.exe ($WINDOWS_SIZE bytes)"
        else
            log_error "Windows build produced no binary at $WINDOWS_BIN"
            exit 1
        fi
    fi
fi

# --- Summary ---

echo ""
log_info "=== Build Complete ==="
ls -lh "$OUTPUT_DIR"/dj_engine* 2>/dev/null || true
