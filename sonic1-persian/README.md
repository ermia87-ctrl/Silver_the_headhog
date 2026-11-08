# Sonic 1 Persian Android port

This is an isolated work area for the user's legally obtained Sonic the Hedgehog (1991) Mega Drive/Genesis ROM.

## Separation and safety
- This branch is separate from the Silver prototype and does not modify the `main` branch.
- Do not commit or publish the commercial ROM, BIOS files, game assets, or extracted copyrighted content.
- The Android app must load a ROM supplied by the user on-device; the APK/repository must not contain the ROM.

## Confirmed input
The supplied file was inspected previously: 524,288 bytes (512 KiB), with the Mega Drive signature `SEGA MEGA DRIVE ` and Sonic the Hedgehog identification in its header.

## Current status
This folder is a project work area, not a finished Android port. No APK is claimed or attached yet. The existing repository's Android workflow builds the separate Silver Godot prototype; it does not build Sonic 1.

## Required implementation before an APK can be called complete
1. Integrate a legally distributable Mega Drive emulator runtime for Android.
2. Add an in-app ROM picker and load the user's local ROM without copying it into the repository.
3. Implement Persian UI/text rendering and right-to-left shaping where applicable, while preserving the original game presentation and audio.
4. Add a dedicated Android build workflow for this subproject.
5. Build and test the APK, then publish the APK as a workflow artifact only after a successful build.

## ROM inspection
The helper in `tools/inspect_rom_header.py` can inspect a local ROM header. It does not modify or translate the game.
