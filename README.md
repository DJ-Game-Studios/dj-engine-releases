# DJ-Engine Releases

Public downloads for **DJ-Engine** and games built with it.

DJ-Engine is a custom Rust game engine created by [DJ Game Studios](https://github.com/DJ-Game-Studios) for stylized 2D games, editor-driven workflows, and portable game packages.

> **Current status:** These builds are early community tests, not finished commercial releases. Expect rough edges, incomplete features, and breaking format changes.

## Download

Visit the [Releases page](https://github.com/DJ-Game-Studios/dj-engine-releases/releases) for the available builds.

| Build | Platform | Status |
| --- | --- | --- |
| DoomExe | Windows x64 | Playable community test |
| Helix Card Game | Windows x64 | Playable community test |
| Helix Fracture | Linux ARM64 | Experimental compatibility build |
| DJ-Engine Editor | Linux ARM64 | Experimental compatibility build |

Release notes identify the exact artifact, platform, and maturity of each download.

## Run a game

Extract the downloaded archive before launching it.

```text
# Windows
dj_engine.exe game.djpak

# Linux
./dj_engine game.djpak
```

Some releases bundle a game-specific executable and can be launched directly instead.

## Project formats

### `.djproj` — editable project

A directory containing source assets, game data, scenes, and project metadata. Open it in the editor:

```text
dj_engine.exe --editor path/to/game.djproj
```

### `.djpak` — playable package

A single-file packaged game intended for distribution:

```text
dj_engine.exe path/to/game.djpak
```

See the [format specification](spec/DJ_PROJECT_SPEC.md) and [integration guide](INTEGRATION.md) for technical details.

## Feedback

If a public build crashes or fails to start, [open an issue](https://github.com/DJ-Game-Studios/dj-engine-releases/issues) with:

- the release tag and downloaded filename;
- your operating system and architecture;
- the steps that reproduced the problem;
- relevant logs or screenshots, with personal information removed.

## License

Repository documentation and included code are covered by the [MIT License](LICENSE). Individual release artifacts may include their own notices.
