# Release Agent Coordination

This repo is a **public release channel** for DJ-Game-Studios. Cross-repo release work — pipeline wiring, secret arming, stale-URL cleanup, storefront identity, PAT scoping — is coordinated by **`agent-release`**, whose workspace is at `~/dev/master-track/releases/`.

## Where to look first

- Agent workspace: `~/dev/master-track/releases/`
- Agent brief: `~/dev/master-track/releases/RELEASE_AGENT_BRIEF.md`
- Operating rules: `~/dev/master-track/releases/CLAUDE.md`
- Release state (canonical): `~/dev/master-track/data/releases.json` (products: `dj-engine`, `doomexe`)
- **Latest discovery audit: `~/dev/master-track/releases/docs/audits/2026-04-17-discovery.md`** — read the sections tagged to this repo below.

## Items flagged for this repo (2026-04-17 audit)

From the audit's gap-map. Each item names the audit section for the full context.

### Must close before Phase 3 (DoomExe first release)

- [ ] **~20 stale `djmsqrvve/*` URLs** across `README.md`, `INTEGRATION.md`, `ENGINE_AGENT_HANDOFF.md`, `AGENT_PROMPT_DJ_ENGINE.md`, `docs/RELEASE_PROCESS.md`, `docs/agents/sprint-batch-prompts.md`. Post-GHE migration (2026-04-16) left these pointing at the pre-migration owner. Shipping a release while README points at a dead URL is a footgun. (Audit §5.3)
- [ ] **`DJENGINE_RELEASE_PAT` secret not armed** on this repo. All three release workflows (`release-engine.yml`, `release-game.yml`, `release-game-exe.yml`) depend on it. (Audit §3.3, §4)
- [ ] **0 releases shipped** — `gh release list -R DJ-Game-Studios/dj-engine-releases` returns empty. Phase 3 target is `doomexe-v0.1.0` through `release-game-exe.yml`. (Audit §1)

### Relevant context (no action in this repo)

- `DJ-Game-Studios/DJ-Engine` has an unlogged public release `v0.1.0` from 2026-03-25 that predates the release pipeline. Release body contains a stale `djmsqrvve/` clone URL. Decision pending from DJ — see audit §5.1.
- Workflows in this repo (`.github/workflows/release-*.yml`) are **load-bearing**. Do not edit without producing a diff for DJ first — same rule as `helix_3d`'s `release-viewer.yml`. (Audit §3.2)
- Tag-namespace pattern for games in this umbrella is `${game}-v${ver}` (e.g. `doomexe-v0.1.0`), already wired into `release-game-exe.yml`. (Audit §3.2)

## How to coordinate

- Need a workflow change? Produce a diff, drop it in `~/dev/master-track/releases/handoffs/YYYY-MM-DD-<topic>.md`, tag `agent-release`.
- Need to ship a release from this repo? That's a Phase 3 activity — don't cut the tag without walking through `~/dev/master-track/releases/runbooks/clone-dj-engine-releases.md` + the Phase 3 plan in `~/dev/master-track/releases/planning/ROADMAP.md`. Note: that clone-runbook is currently **stale** (this repo is already cloned at `/home/dj/dev/engines/dj-engine-releases/`).
- Need to update `releases.json`? Append to `~/dev/master-track/data/releases.json` via `make log-release` in `~/dev/master-track/releases/`. Never force-push.

## Non-negotiable

- **Append-only artifacts.** No force-pushes to tags or release assets. Unpublishing requires an issue + DJ eyeball pass.
- **No credentials in markdown.** `DJENGINE_RELEASE_PAT` lives in GitHub repo secrets + `~/dev/studio-ops/team/wggs-vault.kdbx` only.
- **Scope matrix, not values.** Any PAT scope documentation goes in `~/dev/master-track/releases/secrets/RELEASE_SECRETS.md`.

---

*This file is a pointer, not a source of truth. For anything substantive, the canonical document is the latest audit in `~/dev/master-track/releases/docs/audits/`.*
