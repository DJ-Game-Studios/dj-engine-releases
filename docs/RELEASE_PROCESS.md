# DJ-Engine Releases — Local Release Process

This is the public distribution repository for [DJ-Engine](https://github.com/DJ-Game-Studios/DJ-Engine) and its games. GitHub Actions execution is retired, including manual and tag-triggered release jobs. The archived definitions are reference material only.

## Validate this repository

Run `make validate-local` with Python 3, Bash, ShellCheck, `zip`, `unzip` and `sha256sum` available. The gate rejects runnable Actions and Dependabot definitions, makes ShellCheck blocking, and packages an owned synthetic project as both `.djproj` and `.djpak`. It runs the existing five-stage `.djpak` verifier and removes its temporary fixtures afterward.

This validates the packaging scripts against that fixture. It does not compile an engine, qualify a game or platform, create a tag, upload an artifact or publish a release. See [the validation scope](LOCAL_ACTIONS_RETIREMENT.md).

## Prepare owned project artifacts

Real-product preparation requires the release owner to pin the product source, engine version and game version first. Use an explicit project path and an owned staging directory:

```bash
make package-djproj PROJECT_DIR=/absolute/path/to/owned-project OUTPUT_DIR=/absolute/path/to/release-staging GAME_NAME=game GAME_VERSION=0.1.0
make package-djpak PROJECT_DIR=/absolute/path/to/owned-project OUTPUT_DIR=/absolute/path/to/release-staging GAME_NAME=game GAME_VERSION=0.1.0 ENGINE_VERSION=0.1.0
make verify PACKAGE=/absolute/path/to/release-staging/game-0.1.0.djpak
```

The release owner must qualify the actual artifacts and target platforms separately. `make build-engine DJ_ENGINE_DIR=... OUTPUT_DIR=... ENGINE_VERSION=...` remains the existing engine build entry point; follow the engine owner's toolchain and build-admission rules before running it. No engine, Windows or gameplay qualification follows from `make validate-local`.

| Product form | Artifacts | Existing tag convention |
|--------------|-----------|-------------------------|
| Engine | Qualified platform engine binaries | `v${version}` |
| Editable/playable game package | `${game}-${version}.djproj` and `.djpak` | `${game}-v${version}` |
| Standalone game | Separately qualified platform archives | `${game}-v${version}` |

There is no maintained local standalone-game release driver in this repository. Its archived workflow describes historical build inputs; it is not a runnable substitute or proof that a platform build works.

## Review and publish

Coordinate through [Release Agent Coordination](../RELEASE_AGENT_COORDINATION.md). Give the release owner the exact source revisions, versions, artifact names, SHA-256 checksums and product/platform test evidence. Resolve package or engine issues with the relevant owner before publication; gameplay implementation stays with the Helix agent.

Publication requires DJ's separate release approval. After approval, the release owner publishes the reviewed local artifacts to [DJ-Game-Studios/dj-engine-releases](https://github.com/DJ-Game-Studios/dj-engine-releases/releases) through the approved manual release route. Maintenance approval does not authorize tags, uploads, signing, storefront changes, new credentials or expanded token scopes. Existing releases and assets remain append-only.

After publication, verify the downloadable artifact hashes and platform behavior, then record the release through the existing `master-track/releases` owner and release log. Never infer a successful release from a package check or an archived workflow.

## Historical source

- [Engine release](../.github/workflows-archive/release-engine.yml)
- [Game packages](../.github/workflows-archive/release-game.yml)
- [Standalone game binaries](../.github/workflows-archive/release-game-exe.yml)
- [Package validation](../.github/workflows-archive/validate-packages.yml)

All four files are preserved outside `.github/workflows`. Do not restore them, dispatch them or arm their former release secrets. Repository Actions permissions and CodeQL configuration are checked independently from source retirement.
