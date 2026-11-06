# GearDuck 1.0.0-release

GearDuck 1.0.0 is the first stable release of the WoW: Forever gear-comparison
addon. It scores items with editable stat weights and compares them with
currently equipped gear, showing Upgrade, Sidegrade, or Downgrade results in
item tooltips.

## Features

- Automatically selects class and talent-tree weights, with independent
  Questing, Raid, and PvP profiles and configurable physical and spell hit caps.
- Compares applicable equipment slots, including separate ring, trinket, and
  one-handed weapon comparisons and combined two-handed weapon comparisons.
- Checks class, level, armor, weapon, and talent eligibility before showing
  comparisons or upgrade arrows.
- Marks eligible upgrades in supported bags and item panels, with configurable
  arrow placement and support for Blizzard bags and Baganator.
- Scores weapon damage, speed, supported racial skills and talent effects, and
  enchanted weapons with and without their enchants.
- Provides editable stat weights, manual values for item and enchant effects
  and set bonuses, an in-game setup guide, options, and debug commands.
- Stores persistent weights in the required GearDuck Weights companion addon,
  separately from addon code updates.

Power Level is a configurable estimate, not a DPS simulation. Starter weights
are broad level-60 Classic-style baselines and can be customized in game.

## Compatibility and installation

Built for WoW: Forever Beta 1.60.1 (`Interface: 16001`). Install GearDuck and
the required GearDuck Weights companion as sibling folders in
`Interface/AddOns`, then enable both addons.

See [CURSEFORGE.md](CURSEFORGE.md) for the full feature description and
[docs/SCREENSHOTS.md](docs/SCREENSHOTS.md) for the prepared release images and
upload captions.
