# GearDuck media kit - 0.6.4-release

This package contains release-ready copy and in-game screenshots for GearDuck, a
World of Warcraft: Forever addon. It is a publishing/media kit, not the
installable addon archive.

## Package contents

- `CURSEFORGE.md` - description text for the CurseForge project page.
- `RELEASE-NOTES.md` - release announcement text for version 0.6.4-release.
- `docs/SCREENSHOTS.md` - ordered gallery, upload titles/captions, and optional
  additional capture guidance.
- `docs/screenshots/` - four cropped, native-resolution PNG screenshots.

The four supplied game-client screenshots have been cropped and checked for
readability. They cover upgrade comparisons, multiple tooltip profiles, bag
upgrade arrows, profile/weight settings, and the setup guide. The original
uncropped JPEGs have been removed. No UI elements or values were fabricated,
and the images have not been upscaled.

## Publishing

1. Use `CURSEFORGE.md` for project description copy and `RELEASE-NOTES.md` for
   the release announcement.
2. Upload the four PNGs to the CurseForge image gallery in the order listed in
   `docs/SCREENSHOTS.md`; use the supplied titles and captions.
3. Markdown image links work within this media kit. For the CurseForge page,
   upload images through its editor/gallery rather than pasting local paths.
4. Publish the installable addon archive separately. This media folder is
   excluded from addon packaging by the repository's `.pkgmeta`.

## Product facts

- Game: WoW: Forever Beta 1.60.1 (`Interface: 16001`).
- Addon: GearDuck, version 0.6.4-release.
- Required companion addon: GearDuck Weights.
- Main features: item Power Level comparisons, editable class/activity
  weights, Questing/Raid/PvP tooltip profiles, onboarding, and bag upgrade
  indicators.

Use the game-client screenshots for the CurseForge gallery. These are actual
in-game captures, not website or desktop images or redesigned mockups.
