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
