# How to Play a DJ-Engine Game

This guide walks you through downloading and playing a game built with DJ-Engine.

## What You Need

1. **A DJ-Engine binary** for your platform:
   - `dj_engine.exe` (Windows x86_64)
   - `dj_engine` (Linux x86_64)

2. **A game package** (`.djpak` file):
   - Example: `doomexe.djpak` — a dark-fantasy horror JRPG with a hamster narrator

## Step-by-Step

### 1. Download

Download both files from the [Releases page](https://github.com/djmsqrvve/dj-engine-releases/releases) and put them in the same folder:

```
/dev/dj-games/          (or any folder you choose)
  dj_engine.exe         (or dj_engine on Linux)
  doomexe.djpak
```

### 2. Run the Game

**Windows:**
Open a terminal (Command Prompt or PowerShell) in the folder and run:
```
dj_engine.exe --play doomexe.djpak
```

Or double-click `dj_engine.exe` and use the file picker to open `doomexe.djpak`.

**Linux:**
```bash
chmod +x dj_engine    # make it executable (first time only)
./dj_engine --play doomexe.djpak
```

### 3. Play

The game launches directly into its title screen. Use:
- **Arrow keys** or **WASD** — Move
- **Enter** or **Space** — Confirm / interact
- **Escape** — Pause menu
- **F1** — Debug console (if enabled)

## What is a `.djpak`?

A `.djpak` is a sealed game package. It contains everything the game needs to run:
- Scenes, story graphs, and game data (minified for performance)
- Audio, sprites, and other assets
- An integrity checksum so you know the package hasn't been tampered with

You don't need to unzip it — the engine reads it directly.

See [spec/DJPAK_FORMAT.md](../spec/DJPAK_FORMAT.md) for the full technical specification.

## Opening a Project in the Editor

If you have an **editable** project (`.djproj` file) instead, you can open it in the DJ-Engine Editor:

```bash
# Windows
dj_engine.exe --open doomexe.djproj

# Linux
./dj_engine --open doomexe.djproj
```

This lets you view and modify the game's scenes, story graphs, database, and assets. See [spec/DJPROJ_FORMAT.md](../spec/DJPROJ_FORMAT.md) for details.

## Troubleshooting

| Problem | Fix |
|---------|-----|
| "Permission denied" on Linux | Run `chmod +x dj_engine` |
| "Checksum mismatch" error | Re-download the `.djpak` — the file may be corrupted |
| Game won't start | Make sure you're using a compatible engine version (check the release notes) |
| Black screen | Ensure your system has OpenGL/Vulkan support and up-to-date GPU drivers |

## Save Data

Your save files are stored in a user-scoped directory, NOT inside the `.djpak`:
- **Linux:** `~/.local/share/dj_engine/saves/`
- **Windows:** `%APPDATA%/dj_engine/saves/`

Deleting or re-downloading a `.djpak` does not affect your save data.
