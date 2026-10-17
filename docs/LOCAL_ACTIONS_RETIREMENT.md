# Local release validation

Run `python3 scripts/validate-packages-local.py`. This preserves the synthetic `.djproj` / `.djpak` packaging and integrity checks formerly embedded in Validate Packages, makes ShellCheck blocking, and uses an owned temporary directory. It never builds or launches a game, signs an artifact, uploads a release, uses credentials or deploys.

Release preparation remains in the existing Makefile and scripts: `make build-engine`, `make package-djproj`, `make package-djpak` and `make verify`. Supply explicit owned project/engine paths and review platform/toolchain requirements. Windows cross-compilation and real-product packaging are separate unrun qualification gates for this source-only change. No release is performed as a test.

All former workflow definitions remain under `.github/workflows-archive/` as non-runnable history. Do not dispatch or restore them. Repository Actions permissions and CodeQL configuration are verified separately from YAML absence. Existing GitHub Apps, webhooks and stored security alerts are untouched.
