# dj-engine-releases — Vision, Roadmap, Gaps, Blockers & Planning

> Original planning snapshot: 2026-04-11. Engine tasks, package readiness and historical blockers below are not current product evidence. Reconcile them with the active Helix agent before assigning work.
>
> Maintenance update, 2026-10-17: GitHub Actions execution is retired, including manual and tag-triggered jobs. `make validate-local` now provides blocking ShellCheck and synthetic packaging/integrity checks. See [the current local release process](RELEASE_PROCESS.md); platform qualification and release publication remain separate owner gates.

## Vision

**One-click game distribution for DJ-Engine.** A user downloads two files — `dj_engine.exe` + `doomexe.djpak` — runs a single command, and plays the game. Modders download `doomexe.djproj` and open it in the editor. The release pipeline handles everything from source to sealed package to GitHub Release.

Long-term: this repo becomes the central release hub for all DJ-Engine games and the engine itself, with verified packages, automated validation, and integration into the broader Helix ecosystem's distribution workflow.

---

## Original planned state (historical)

| Component | Status | Notes |
|-----------|--------|-------|
| `.djpak` format spec | Done | `spec/DJPAK_FORMAT.md` |
| `.djproj` format spec | Done | `spec/DJPROJ_FORMAT.md` |
| Version compatibility matrix | Done | `spec/VERSION_COMPAT.md` |
| `package-djproj.sh` | Done, tested | Works against DoomExe |
| `package-djpak.sh` | Done, tested | Works against DoomExe (minified, checksummed) |
| `verify-djpak.sh` | Done, tested, bug fixed (PR #1) | 5-step verification passes |
| `generate-project-json.py` | Done, tested | Scans game dirs, generates manifest |
| `build-engine.sh` | Written, untested | Needs Rust 1.94.0 + cross-compile deps |
| Historical workflows (all 4) | Retired | `.github/workflows-archive/`; no execution |
| Local package validation | Maintained | `make validate-local`; synthetic fixture only |
| Makefile | Done | Unified interface for all commands |
| DoomExe `project.json` | Done (in DJ-Engine) | 4 scenes, 2 story graphs |
| Documentation | Done (PR #2) | AGENTS, INTEGRATION, TESTING, ENGINE_AGENT_HANDOFF, CHANGELOG |
| Environment config | Done | Shellcheck, scripts, knowledge |

---

## Gaps

### 1. Engine-Side Loaders (Blocked on DJ-Engine Agent)

The sprint goal is `dj_engine.exe --play doomexe.djpak`. The releases side is ready, but the engine can't load our packages yet.

| Missing Piece | Owner | Dependency |
|---------------|-------|------------|
| CLI `--play` / `--open` flags | Engine agent | None — can start now |
| `.djpak` loader (`djpak.rs`) | Engine agent | CLI flags |
| `.djproj` loader (`djproj.rs`) | Engine agent | CLI flags |
| `LaunchMode` resource | Engine agent | None |
| Integration tests | Engine agent | Loaders |

**Impact**: Without these, we can build packages but nobody can run them. This is the single biggest blocker to the sprint goal.

### 2. Engine Build Not Validated

`build-engine.sh` and `release-engine.yml` are written but never actually run. We don't know if they produce working binaries.

**What's needed**:
- Rust 1.94.0 toolchain installed on the VM
- Linux build dependencies (`libasound2-dev`, `libudev-dev`, etc.)
- `gcc-mingw-w64-x86-64` for Windows cross-compile
- A successful `make build-engine DJ_ENGINE_DIR=/home/ubuntu/repos/DJ-Engine`

**Risk**: The build script may have issues (wrong cargo flags, missing deps, path problems) that we won't discover until we actually try.

### 3. Hosted CI retired

The previous plan to prove GitHub-hosted execution is superseded. All four definitions are preserved as non-runnable history. Run `make validate-local` for source and synthetic packaging checks; use separately scoped product/platform validation before a release. Do not dispatch archived jobs or restore their triggers.

### 4. No `.djproj` Verification Script

We have `verify-djpak.sh` (5-step verification) but no equivalent `verify-djproj.sh`. A `.djproj` is simpler (no checksums, no manifest stripping), but should still be validated:
- Is it a valid ZIP?
- Does `project.json` exist and parse?
- Do all scene/story_graph refs point to real files?
- Are paths snake_case with forward slashes?

### 5. No Automated Release Notes / Changelog Generation

CHANGELOG.md is manually maintained. For a real release pipeline, we should auto-generate release notes from git history between tags.

### 6. No Multi-Game Support Tested

Everything is tested against DoomExe only. The pipeline should work for any game under `DJ-Engine/games/dev/`, but this hasn't been validated. Future games (helix_rpg, rpg_demo) should also package cleanly.

### 7. No Save Data Spec

The `.djpak` spec says "save data goes to a user-scoped save directory (not back into the .djpak)" but there's no spec for where saves go or what format they use. This matters when the engine implements the loader.

---

## Blockers

| Blocker | Severity | Owner | Action |
|---------|----------|-------|--------|
| Engine can't load `.djpak`/`.djproj` | **Critical** | Engine agent | Implement Tasks 1-3 from AGENT_PROMPT_DJ_ENGINE.md |
| Devin API can't find this repo | Medium | Devin/Infra | Repo rename cache is stale — should resolve in new sessions |
| Engine build not validated | Medium | Release agent (me) | Install Rust 1.94.0 + deps, attempt build |
| Hosted execution | Retired | Maintenance owner | Keep definitions archived and maintain local checks |

---

## Roadmap

### Phase 1: Prove the Build (Now → Next Sprint)

**Goal**: Validate that we can actually build the engine and produce working binaries.

- [ ] Install Rust 1.94.0 + all build deps on the Devin VM
- [ ] Run `make build-engine DJ_ENGINE_DIR=/home/ubuntu/repos/DJ-Engine` 
- [ ] Fix any build script issues
- [ ] Verify the Linux binary launches (even if it can't load `.djpak` yet)
- [ ] Attempt Windows cross-compile and verify `.exe` is produced

### Phase 2: Close the Verification Gap

**Goal**: Full validation coverage for both formats.

- [ ] Write `verify-djproj.sh` (ZIP check, project.json validation, ref checks, path conventions)
- [ ] Add `verify-djproj` target to Makefile
- [ ] Extend the local package gate if a separately reviewed `.djproj` verifier is added
- [ ] Add tamper-detection regression tests for `.djproj`

### Phase 3: Engine Integration (Coordinated with Engine Agent)

**Goal**: The sprint goal — `dj_engine.exe --play doomexe.djpak` works.

- [ ] Engine agent implements CLI flags (Task 1)
- [ ] Engine agent implements `.djpak` loader (Task 2)
- [ ] We provide test `.djpak` artifacts for their development
- [ ] We validate the engine loads our packages correctly (E2E test)
- [ ] Engine agent implements `.djproj` loader (Task 3)
- [ ] Full round-trip: package → load → play → verify

### Phase 4: First Real Release

**Goal**: Cut v0.1.0 release on GitHub with downloadable artifacts.

- [ ] Prepare and qualify engine binaries locally under the engine owner
- [ ] Prepare owned game packages locally, then publish only after DJ's separate release approval
- [ ] Verify GitHub Release page has all expected artifacts
- [ ] Test download → run → play flow on a clean machine
- [ ] Update CHANGELOG.md with v0.1.0 release

### Phase 5: Multi-Game & Polish

**Goal**: Pipeline handles multiple games and is robust.

- [ ] Test packaging `helix_rpg` and `rpg_demo` (if they have content)
- [ ] Auto-generate release notes from git log
- [ ] Add save data path spec to format docs
- [ ] Consider `verify-djproj.sh` for completeness
- [ ] Asset size reporting (track package sizes over time)
- [ ] Explore code signing for `.djpak` integrity beyond SHA-256

---

## Agent Coordination

### Release Agent (Me) — Responsibilities
- Maintain and fix all packaging/verification scripts
- Maintain format specs and version compatibility
- Maintain the blocking local package gate; preserve archived CI source
- Validate engine builds compile correctly
- Cut releases when engine + game packages are ready
- Bug triage for anything related to packaging, distribution, integrity

### Engine Agent — Dependencies on Us
- Needs: format specs (done), test artifacts (can generate on demand), schema reference (done)
- Provides: engine source (for building), `project.json` schema (for packaging), bug reports on our packages

### DJ (User) — Needs From
- Decision on the next release after current product/platform qualification
- Separate publication approval for reviewed local artifacts
- Required review of source PRs; no change to branch protection or credential scope is implied

---

## Original next actions (historical; reconcile with owners)

1. **Validate engine build** — Install Rust 1.94.0, attempt `make build-engine`
2. **Write `verify-djproj.sh`** — Close the verification gap
3. **Coordinate with engine agent** — Ensure they have `ENGINE_AGENT_HANDOFF.md` and test artifacts
4. **Review DJ-Engine PR #16** — Still pending (schema fixes)
