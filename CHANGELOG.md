# Changelog

All notable changes to DJ-Engine releases will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Changed — 2026-10-17
- Retired all four GitHub Actions definitions as byte-preserved history outside the runnable directory.
- Added `make validate-local` with blocking ShellCheck, owned synthetic fixtures and the existing package integrity checks.
- Replaced workflow-dispatch and release-secret setup instructions with local preparation and separately approved manual publication.

### Added
- Initial release repository structure
- `.djproj` format specification (editable project archive)
- `.djpak` format specification (playable package archive)
- Packaging scripts (`package-djproj.sh`, `package-djpak.sh`, `verify-djpak.sh`)
- Project manifest generator (`generate-project-json.py`)
- Engine build script (`build-engine.sh`)
- GitHub Actions workflows (all `workflow_dispatch` only):
  - `release-engine.yml` — Build and release DJ-Engine binaries
  - `release-game.yml` — Package and release games
  - `validate-packages.yml` — Validate package format compliance
- Makefile with unified command interface
- DoomExe as first `.djpak` release target
- Version compatibility matrix (`spec/VERSION_COMPAT.md`)
- Documentation:
  - `AGENTS.md` — Release agent guide for Devin and future agents
  - `INTEGRATION.md` — Helix ecosystem integration map
  - `ENGINE_AGENT_HANDOFF.md` — Handoff spec for the DJ-Engine agent
  - `TESTING.md` — Bug testing, verification, and tracking procedures
  - `AGENT_PROMPT_DJ_ENGINE.md` — Full engine-side implementation spec

### Fixed
- `verify-djpak.sh`: Subshell variable loss in scene/story_graph reference checks — missing references now correctly fail verification (PR #1)
