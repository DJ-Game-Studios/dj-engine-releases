# Version Compatibility Matrix

## Format Versions

| Format Version | Engine Version | Bevy Version | Notes |
|---------------|----------------|--------------|-------|
| 1.0.0 | 0.1.0+ | 0.18 | Initial release — `.djproj` and `.djpak` formats |

## Compatibility Rules

1. **Format version** follows [SemVer](https://semver.org/):
   - **Major**: Breaking changes to archive structure or manifest schema
   - **Minor**: New optional fields or features (backward compatible)
   - **Patch**: Documentation or tooling fixes only

2. **Engine version** in `.djpak` manifests:
   - The engine SHOULD warn if `engine_version` doesn't match but still attempt to load
   - The engine MUST refuse to load if the format `major` version differs

3. **Forward compatibility**: Newer engines SHOULD load older format versions
4. **Backward compatibility**: Older engines MAY fail on newer format versions (with a clear error message)

## Engine Binary Naming

Release binaries follow this naming convention:

```
dj_engine-{version}-{platform}.{ext}

Examples:
  dj_engine-0.1.0-windows-x86_64.exe
  dj_engine-0.1.0-linux-x86_64
```

## Game Package Naming

```
{game_name}-{version}.djpak
{game_name}-{version}.djproj

Examples:
  doomexe-0.1.0.djpak
  doomexe-0.1.0.djproj
```
