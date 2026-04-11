# Changelog

All notable changes to DJ-Engine releases will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- Initial release repository structure
- `.djproj` format specification (editable project archive)
- `.djpak` format specification (playable package archive)
- Packaging scripts (`package-djproj.sh`, `package-djpak.sh`, `verify-djpak.sh`)
- Engine build script (`build-engine.sh`)
- GitHub Actions workflows (all `workflow_dispatch` only):
  - `release-engine.yml` — Build and release DJ-Engine binaries
  - `release-game.yml` — Package and release games
  - `validate-packages.yml` — Validate package format compliance
- Makefile with unified command interface
- DoomExe as first `.djpak` release target
- `docs/VISION.md` — Project vision, release strategy, current status, ecosystem context
- `docs/HOW_TO_PLAY.md` — End-user guide for downloading and playing games
- `docs/RELEASE_PROCESS.md` — Step-by-step release workflow for maintainers
- `CONTRIBUTING.md` — Contribution guidelines for the release pipeline
- `SECURITY.md` — Security policy and vulnerability reporting
- Expanded README with status section, DoomExe description, documentation index, and ecosystem links
