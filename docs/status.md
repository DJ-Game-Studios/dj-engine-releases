# dj-engine-releases — Setup & Sprint Status Report

## Repo Health

**All 4 packaging/verification scripts tested and working** against real DoomExe source from DJ-Engine:

| Script | Status | Notes |
|--------|--------|-------|
| `package-djproj.sh` | Working | Packaged DoomExe (182KB, 98 files) |
| `package-djpak.sh` | Working | Packaged DoomExe (53KB, 38 files, 29 checksums) |
| `verify-djpak.sh` | **Bug found & fixed** | Subshell bug: missing scene/story_graph refs silently passed. Fixed in branch `devin/1775945660-fix-verify-and-setup` |
| `generate-project-json.py` | Working | Correctly scans dirs and generates manifest |
| `build-engine.sh` | Not tested (needs Rust 1.94.0 + cross-compile toolchain) | Structure looks correct |

**Shellcheck**: All scripts pass clean after the fix.

**DoomExe project.json**: Already exists in DJ-Engine with 4 scenes (overworld, cellar, corrupted_grove, haunted_crypt) and 2 story graphs (intro, hamster_narrator).

## Bug Fixed

`verify-djpak.sh` step [5/5] (asset reference validation) ran scene/story_graph checks inside piped `while` loops (`python3 | while`), which execute in subshells. Error counts were lost, so verification always reported PASS even with missing references. Fixed using process substitution (`< <(...)`) so error counts propagate correctly.

## Blockers

1. **Repo name still has trailing hyphen** on GitHub (`dj-engine-releases-`). Git operations work via redirect, but API-based PR creation fails. Needs manual fix in GitHub Settings > General > Repository name.

2. **Default branch** is `devin/1775942993-initial-release-repo` — user mentioned wanting to rename to `main` via Settings > Default branch.

## Sprint Deliverables (from AGENT_PROMPT_DJ_ENGINE.md)

The AGENT_PROMPT defines 7 tasks. Most are for the **DJ-Engine agent** (engine-side Rust code), not the releases repo. Here's the breakdown of what's whose:

### Releases repo (my responsibility):
| Task | Status |
|------|--------|
| Packaging scripts (djproj, djpak, verify) | Done, working |
| Format specs (DJPROJ_FORMAT.md, DJPAK_FORMAT.md) | Done |
| CI workflows (release-engine, release-game, validate-packages) | Done, all workflow_dispatch |
| Makefile (build-engine, package-*, verify, generate-project, clean) | Done |
| generate-project-json.py | Done |
| verify-djpak.sh bug fix | Done (pending PR merge) |
| VERSION_COMPAT.md | Done |

### DJ-Engine repo (other agent's responsibility):
| Task | Status | Notes |
|------|--------|-------|
| Task 1: CLI args (`--play`, `--open`) | Not started | Engine-side Rust code |
| Task 2: .djpak loader (`engine/src/data/djpak.rs`) | Not started | Engine-side Rust code |
| Task 3: .djproj loader (`engine/src/data/djproj.rs`) | Not started | Engine-side Rust code |
| Task 4: Makefile export commands (DJ-Engine side) | Not started | Engine-side |
| Task 5: DoomExe project.json | **Done** | Already exists in DJ-Engine |
| Task 6: Integration tests | Not started | Engine-side Rust tests |
| Task 7: E2E validation | Blocked on Tasks 1-3 | Needs engine loader support |

### Summary
The releases repo side is **complete and functional**. The remaining sprint work is all engine-side (CLI flags, .djpak/.djproj loaders, tests). The sprint goal — `dj_engine.exe --play doomexe.djpak` — is blocked on the DJ-Engine agent implementing Tasks 1-3.

## Environment Config
Suggested environment config for future Devin sessions (pending your approval in the timeline).
