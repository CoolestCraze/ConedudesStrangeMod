# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **ConedudesStrangeMod**, a GameMaker Studio 2 (GMS2) mod of Pizza Tower (a commercial indie 2D platformer). The project is large (~764 MB, 1,229 objects, 849 rooms, 10,600+ GML script files).

The git repository root is the working directory itself — `PizzaTower_GM2.yyp` and all asset folders are at the top level.

## Building & Running

- **Open the project** by loading `PizzaTower_GM2.yyp` in GameMaker Studio 2.
- **Run in IDE:** Use the Run button in GMS2 (F5).
- **Create Executable:** Build → Create Executable — requires **debug mode enabled on the Steamworks extension** or the compiled build will not work.
- There are no standalone CLI build commands; all builds go through the GMS2 IDE.

## Architecture

### Object System
GameMaker uses an event-driven, instance-based object system. Each object in `objects/` has:
- A `.yy` descriptor file (JSON metadata)
- One `.gml` file per event (e.g., `Create_0.gml`, `Step_0.gml`, `Draw_0.gml`, `Alarm_0.gml`)

Key objects:
- `obj_player` — player character, state machine, movement, attacks
- `obj_PTG` — likely a global game controller
- `obj_actor` — base for NPCs/enemies

### Scripts
`scripts/` contains standalone GML functions, organized by prefix convention:
- `scr_player_*` — player mechanics (movement states, attacks, dash, hookshot, etc.)
- `scr_savesystem` — save/load logic
- `scr_menu` — menu logic
- `scr_do_rank` — rank/scoring system
- `cutscene_*` — cutscene control scripts
- `boss_states*` — boss state machines

### Rooms
`rooms/` contains level and scene definitions. Notable groupings:
- Title/menu: `Titlescreen`, `Realtitlescreen`, `Mainmenu`, `characterselect`
- Hub/levels: `hub_room*`, `badland_*`, `PP_room*`
- Transitions/cutscenes: `leveltransitioncutscene`, `Scootertransition`, `Finalintro`

### Shaders
`shaders/` contains GLSL shader pairs (`.fsh`/`.vsh`):
- `shd_outline`, `shd_hit`, `shd_rainbow`, `shd_afterimage*`, `shd_pal_swapper`, `shd_rank`, `shd_panicbg`

### Extensions
- **Steamworks** — Steam API (note: must be in debug mode for compiled builds)
- **fmod_gms** — FMOD audio engine
- **gameframe_native** — native window/frame handling

## Important Quirks

- **Disabled instances in rooms:** GMS2 still increments instance IDs for disabled instances, which can cause ID gaps. Don't be alarmed by non-sequential IDs.
- **Unused folders/rooms:** Assets in unused rooms are still referenced in code — do not delete them.
- **Localization:** `datafiles/` contains language files for 10+ locales; text changes may need updating across multiple files.
