# Release Agent Coordination

This repository is a public release channel for DJ-Game-Studios. Product build and packaging scripts stay here; cross-product distribution and release records stay with the existing release owner in `/home/dj/dev/master-track/releases/`.

## Current maintenance state — 2026-10-17

GitHub Actions execution is retired, including dispatch-only and tag-triggered releases. All four historical definitions are preserved under `.github/workflows-archive/`; use `make validate-local` and [the local release process](docs/RELEASE_PROCESS.md). Do not arm `DJENGINE_RELEASE_PAT`, restore workflow execution or create a tag as part of this cleanup.

The local gate covers blocking ShellCheck and synthetic `.djproj`/`.djpak` packaging with the existing `.djpak` integrity verifier. Actual engine builds, game behavior, platform binaries and publication need their own evidence and owner scope. Gameplay remains with the Helix agent.

Source retirement remains subject to this repository's required PR review. Local test success and administrative Actions disablement do not replace that review.

## Canonical owner references

- Orchestrator playbook: `/home/dj/dev/master-track/docs/AGENT00_RELEASE_PLAYBOOK.md`
- Release workspace rules: `/home/dj/dev/master-track/releases/CLAUDE.md`
- Release brief: `/home/dj/dev/master-track/releases/RELEASE_AGENT_BRIEF.md`
- Shipped-release records: `/home/dj/dev/master-track/data/releases.json`
- Historical discovery audit: `/home/dj/dev/master-track/releases/docs/audits/2026-04-17-discovery.md`

The workspace's April 25 instructions identify this as Agent 00's retained release-execution workspace. The earlier `agent-release` name and April audit are historical pointers. Reconcile current ownership and product state before future release work; the old audit's missing-secret and workflow-dispatch recommendations are superseded by the no-Actions policy.

## Release integrity

- Publish only after DJ's release approval and the release owner's review of source revisions, artifacts, checksums and platform evidence.
- Preserve append-only release history. No force pushes, replacement assets or unpublishing without the existing owner process.
- Keep credentials out of Markdown. Maintenance does not require new credentials, token scopes or account linking.
- Record an approved publication through the existing release owner; do not create a competing release ledger.
