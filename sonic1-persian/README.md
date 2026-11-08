# Sonic 1 Persian — native Android port (work in progress)

## Non-negotiable project direction
This project is intended to become a **native Android port of the 1991 Mega Drive Sonic 1 game**, not:
- a launcher,
- a Libretro/RetroArch frontend,
- a Mega Drive emulator packaged in an APK,
- a web wrapper.

The previous PicoDrive/Libretro runner does not meet the requested goal and is deprecated. Its build workflow has been removed so it cannot be mistaken for the requested deliverable.

## Input supplied for the project
The supplied file was identified as a 512 KiB Mega Drive ROM with the `SEGA MEGA DRIVE` header and Sonic 1 title metadata. The ROM itself is not committed to this repository and must not be redistributed.

## Current status — not a playable port
There is **no finished APK** and no claim that gameplay has been ported. A real native port requires implementing/reconstructing the Mega Drive game's runtime systems in Android-native code: level/object logic, collision and physics, animation/tile rendering, palette handling, sound/music playback, input, save/state handling, and the game's timing. It also requires extracting or patching only user-supplied game data locally and testing against the original game.

## Persian localization requirements
Persian text must be rendered in-game with correct right-to-left shaping and a custom glyph atlas/font. Sonic 1's title/HUD labels are primarily tile artwork, not ordinary Android strings, so they need in-game asset-level replacement and validation. The original gameplay graphics, music, sound and stages must remain intact.

## Build policy
Do not publish an APK artifact until the native game runtime actually runs the game and has been tested. Do not include Sega ROMs or copyrighted game assets in GitHub Actions or repository files.

## Next engineering milestones
1. Replace the deprecated emulator frontend with a native Android rendering/audio/input runtime.
2. Implement ROM data inspection and asset extraction locally, without uploading the ROM.
3. Recreate game timing, level/object systems, collision and physics.
4. Add Persian RTL glyph rendering and patch in-game title/HUD assets.
5. Validate original stages, music, sound and touch controls, then build and test an offline APK.
