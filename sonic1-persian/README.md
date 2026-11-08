# Sonic 1 Persian Android project

The isolated branch `sonic1-persian-port` contains an Android ARM64 app project under `android/`.

## Implemented in this branch
- Persian-language app screen and Android document picker for the user's own Mega Drive ROM.
- LibretroDroid frontend with a PicoDrive ARM64 core fetched during GitHub Actions builds.
- Touch controls for movement and the two action buttons.
- Local save and system-data directories.
- The ROM is not committed, embedded, or redistributed by this repository.

## Build
Open **Actions → Build Sonic Persian Android APK → Run workflow** on branch `sonic1-persian-port`. After a successful run, download the `Sonic-Persian-Android-ARM64` artifact.

## Localization status — not complete yet
This is currently an emulator-based Android runner with Persian app controls, not yet a fully translated Sonic 1 ROM. Sonic 1's HUD and title graphics are tile-based artwork rather than ordinary text; replacing those safely requires a verified ROM patch and in-game testing. The runner leaves the user's original ROM untouched.

## ROM
The user must select their own legally obtained ROM on the device. No Sega commercial game ROM, BIOS, music, or graphics are included in the repository or build.
