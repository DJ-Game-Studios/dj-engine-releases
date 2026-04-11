# Contributing to DJ-Engine Releases

Thank you for your interest in contributing to the DJ-Engine release pipeline.

## What This Repo Contains

This is the **distribution** repository, not the engine source. It contains:
- Format specifications (`.djproj` and `.djpak`)
- Packaging and build scripts
- GitHub Actions workflows for automated releases
- Documentation for end-users and release managers

For engine development, see [DJ-Engine](https://github.com/djmsqrvve/DJ-Engine).

## Quick Start

```bash
git clone https://github.com/djmsqrvve/dj-engine-releases.git
cd dj-engine-releases
make help    # see all available commands
```

## What You Can Contribute

### Documentation
- Improve end-user guides (`docs/HOW_TO_PLAY.md`, `README.md`)
- Clarify format specifications (`spec/`)
- Add examples or troubleshooting guides

### Scripts
- Fix bugs in packaging scripts (`scripts/`)
- Improve error handling or output formatting
- Add support for new platforms or packaging options

### CI/CD Workflows
- Fix workflow issues (`.github/workflows/`)
- Add new validation checks or release targets

### Format Specifications
- Propose extensions to `.djproj` or `.djpak` formats
- Add validation rules or compatibility notes

## Development Workflow

1. **Fork & clone** the repository
2. **Branch** from the default branch: `git checkout -b feature/my-change`
3. **Make your changes** following the conventions below
4. **Test** your changes:
   - For scripts: run them against a test project directory
   - For docs: review for accuracy and clarity
   - For workflows: test with `act` locally if possible (workflows are `workflow_dispatch` only)
5. **Commit** with a clear message (see format below)
6. **Push** and open a Pull Request

## Commit Message Format

```
type: short description

[optional body]
```

Types: `feat`, `fix`, `docs`, `ci`, `chore`

Examples:
- `docs: add troubleshooting section to HOW_TO_PLAY`
- `fix: handle spaces in project paths in package-djpak.sh`
- `ci: add macOS build target to release-engine.yml`

## Script Conventions

- Shell scripts use `bash` with `set -euo pipefail`
- Scripts include a header comment with usage, purpose, and requirements
- Error messages go to stderr with colored output (`[ERROR]`, `[WARN]`, `[INFO]`)
- Scripts validate inputs before doing any work
- All file paths should handle spaces correctly (quote variables)

## CI/CD Note

All GitHub Actions workflows use `workflow_dispatch` (manual trigger only) to avoid billing costs. Do **not** add automatic `push` or `pull_request` triggers. Leave comments in workflow files explaining how to re-enable them when credits are available.

## File Naming

- Scripts: `kebab-case.sh` or `kebab-case.py`
- Specs: `UPPER_SNAKE_CASE.md` in `spec/`
- Docs: `UPPER_SNAKE_CASE.md` in `docs/`
- Workflows: `kebab-case.yml` in `.github/workflows/`

## Getting Help

- Open an issue for bugs or questions
- Check existing issues before creating new ones
- For engine-level questions, open issues on [DJ-Engine](https://github.com/djmsqrvve/DJ-Engine)

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
