# Security Policy

## Reporting Vulnerabilities

If you discover a security vulnerability in the DJ-Engine release pipeline, packaging scripts, or distributed binaries, please report it responsibly:

1. **Do not** open a public issue
2. Email: djmsqrvve@gmail.com with subject line `[SECURITY] dj-engine-releases`
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

We will acknowledge receipt within 48 hours and provide a timeline for a fix.

## Scope

This policy covers:
- Packaging scripts (`scripts/`)
- GitHub Actions workflows (`.github/workflows/`)
- Distributed binaries and packages
- Format specifications (`spec/`)

For vulnerabilities in the DJ-Engine runtime itself (e.g., Lua sandbox escapes, memory safety issues), report them to the [DJ-Engine repository](https://github.com/djmsqrvve/DJ-Engine).

## Package Integrity

### `.djpak` Checksums

Every `.djpak` package includes a `checksum.sha256` file with SHA-256 hashes for all contained files. The engine verifies these checksums on load and refuses to run packages with mismatched hashes.

### Verifying Downloads

Release artifacts on GitHub include SHA-256 hashes in the release notes. Verify downloaded files:

```bash
sha256sum -c checksums.txt
```

### Lua Sandboxing

`.djpak` packages may contain Lua scripts in `assets/scripts/`. These are executed in a sandboxed environment via the engine's `mlua` integration. The sandbox:
- Restricts filesystem access
- Limits available standard library functions
- Prevents arbitrary system command execution

## Supported Versions

| Version | Supported |
|---------|-----------|
| Format 1.0.x | Yes |

Only the latest format version receives security fixes.
