# CLAUDE.md

@AGENTS.md

`AGENTS.md`, imported above, holds this repository's agent instructions. Claude Code reads
`AGENTS.md` on its own only when no `CLAUDE.md` exists here or in a parent directory, and
`~/dev/CLAUDE.md` does, so without this import Claude Code sessions never load those rules.
