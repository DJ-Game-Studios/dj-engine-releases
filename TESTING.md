# Testing & Verification Guide

> Bug testing, verification procedures, and tracking for dj-engine-releases.

## Quick Verification

Run this to verify the full pipeline is working:

```bash
# From the dj-engine-releases repo root:
DJ_ENGINE=/home/ubuntu/repos/DJ-Engine  # Devin VM path (or /home/dj/dev/DJ-Engine locally)

# 1. Package DoomExe as .djpak
bash scripts/package-djpak.sh "$DJ_ENGINE/games/dev/doomexe" /tmp/doomexe-test.djpak --engine-version 0.1.0

# 2. Verify the .djpak
bash scripts/verify-djpak.sh /tmp/doomexe-test.djpak

# 3. Package DoomExe as .djproj
bash scripts/package-djproj.sh "$DJ_ENGINE/games/dev/doomexe" /tmp/doomexe-test.djproj

# 4. Lint all scripts
shellcheck scripts/*.sh
```

All 4 steps should pass with zero errors.

## Script Test Matrix

| Script | Input | Expected Output | Pass Criteria |
|--------|-------|-----------------|---------------|
| `package-djproj.sh` | Game project dir | `.djproj` ZIP | Contains `project.json` at root, all scenes/story_graphs present |
| `package-djpak.sh` | Game project dir | `.djpak` ZIP | Contains `manifest.json`, `checksum.sha256`, minified JSON, no editor metadata |
| `verify-djpak.sh` | `.djpak` file | Exit 0 (pass) or 1 (fail) | 5-step verification: ZIP validity, manifest, checksums, file completeness, asset refs |
| `generate-project-json.py` | Game asset dir | `project.json` | Valid JSON with UUID, discovered scenes, story graphs, correct paths |

## Verification Script: 5-Step Breakdown

`verify-djpak.sh` runs these checks in order:

1. **[1/5] ZIP integrity** — Is it a valid ZIP archive?
2. **[2/5] Manifest validation** — Does `manifest.json` exist with required fields (`format_version`, `name`, `engine_version`)?
3. **[3/5] Checksum verification** — Does `checksum.sha256` exist? Do all SHA-256 hashes match?
4. **[4/5] File completeness** — Is every file in the archive listed in checksums? Is every checksum entry present in the archive?
5. **[5/5] Asset reference validation** — Do all scene/story_graph paths in the manifest point to real files?

## Regression Tests

### Test: Tampered .djpak fails verification

```bash
# Create a valid .djpak
bash scripts/package-djpak.sh "$DJ_ENGINE/games/dev/doomexe" /tmp/tamper-test.djpak --engine-version 0.1.0

# Tamper: remove a scene file from the archive
zip -d /tmp/tamper-test.djpak "scenes/overworld.json"

# Verify should fail (exit code 1)
bash scripts/verify-djpak.sh /tmp/tamper-test.djpak
echo "Exit code: $?"  # Should be 1
```

### Test: Empty project dir fails packaging

```bash
mkdir -p /tmp/empty-project
bash scripts/package-djpak.sh /tmp/empty-project /tmp/should-fail.djpak --engine-version 0.1.0
echo "Exit code: $?"  # Should be non-zero (no project.json)
```

### Test: Checksum mismatch detection

```bash
# Create valid .djpak
bash scripts/package-djpak.sh "$DJ_ENGINE/games/dev/doomexe" /tmp/checksum-test.djpak --engine-version 0.1.0

# Extract, corrupt a file, re-zip
mkdir -p /tmp/checksum-extract
cd /tmp/checksum-extract && unzip -o /tmp/checksum-test.djpak
echo "corrupted" > scenes/overworld.json
zip -r /tmp/checksum-test.djpak . -x checksum.sha256
cd -

# Verify should fail on checksum mismatch
bash scripts/verify-djpak.sh /tmp/checksum-test.djpak
echo "Exit code: $?"  # Should be 1
```

## Known Bugs (Fixed)

### verify-djpak.sh subshell variable loss (Fixed in PR #1)

**Symptom**: Missing scene/story_graph references silently passed verification.

**Root cause**: Scene and story_graph reference checks ran inside piped `while` loops (`python3 | while read`), which execute in subshells. Error count increments were lost when the subshell exited.

**Fix**: Replaced piped `while` loops with process substitution (`while read ... done < <(python3 ...)`) so the loop runs in the current shell and error counts propagate correctly.

**Verification**: Tampered `.djpak` with missing scene reference now correctly fails with exit code 1.

## Bug Tracking

When you find a bug:

1. **Reproduce** — Write a minimal test case (see regression tests above)
2. **Fix** — Fix in a feature branch (`devin/<timestamp>-<slug>`)
3. **Verify** — Run the full verification pipeline plus your regression test
4. **Lint** — `shellcheck scripts/*.sh` must pass clean
5. **PR** — Create a PR targeting `main` with the fix and regression test description
6. **Document** — Add the bug to the "Known Bugs" section above with symptom, root cause, and fix

## CI Workflows

All workflows are `workflow_dispatch` only (manual trigger). No automatic triggers.

| Workflow | What It Tests | When to Run |
|----------|--------------|-------------|
| `validate-packages.yml` | Full .djpak/.djproj validation | After script changes or format spec updates |
| `release-engine.yml` | Engine compilation | Before cutting a release |
| `release-game.yml` | Game packaging pipeline | Before distributing a game |

## Cross-Repo Testing

### Testing with DJ-Engine changes

If the DJ-Engine agent modifies `project.json` schema or game asset structure:

1. Pull the latest DJ-Engine source
2. Re-run the full verification pipeline against the updated game dirs
3. If packaging fails, the format specs or scripts may need updating
4. Coordinate via PR comments or issues

### Testing engine loaders (Engine Agent's responsibility)

The engine agent should test their `.djpak`/`.djproj` loaders against packages generated by our scripts:

```bash
# Generate test packages for the engine agent
bash scripts/package-djpak.sh /path/to/DJ-Engine/games/dev/doomexe /tmp/doomexe.djpak --engine-version 0.1.0
bash scripts/package-djproj.sh /path/to/DJ-Engine/games/dev/doomexe /tmp/doomexe.djproj

# Engine agent then tests:
# cargo test -p dj_engine -- test_djpak
# ./target/debug/dj_engine --play /tmp/doomexe.djpak
```

## Ecosystem-Wide Validation

As the Helix ecosystem grows, the release pipeline should validate:

| Check | What | How |
|-------|------|-----|
| Format compliance | All `.djpak`/`.djproj` files match specs | `verify-djpak.sh` |
| Version compat | Engine version matches format version | `VERSION_COMPAT.md` matrix |
| Asset integrity | All referenced assets exist | Checksum + manifest validation |
| Schema alignment | `project.json` matches engine Rust structs | Compare against DJ-Engine PR reviews |
| Cross-platform | Packages work on Linux + Windows | E2E test with cross-compiled binary |

## Local Dev Paths

| Resource | Devin VM | DJ's Machine |
|----------|----------|-------------|
| This repo | `/home/ubuntu/repos/dj-engine-releases` | `/home/dj/dev/dj-engine-releases` |
| DJ-Engine | `/home/ubuntu/repos/DJ-Engine` | `/home/dj/dev/DJ-Engine` |
| DoomExe game | `DJ-Engine/games/dev/doomexe` | Same relative path |
| Helix monorepo | N/A | `/home/dj/dev/helix/` |
