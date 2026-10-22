# GearDuck - item comparisons for WoW: Forever

**See item upgrades at a glance, with weights you can tune to your character.**

GearDuck compares item stats against your equipped gear and displays a
Power Level comparison on item tooltips. It automatically detects your class
and active talent tree, then uses editable weights for Questing, Raid, and PvP.

Built for **WoW: Forever Beta 1.60.1** (`Interface: 16001`).

## Features

- See whether an item is an **Upgrade**, **Sidegrade**, or **Downgrade**.
- Compare rings, trinkets, and weapons against the applicable equipped slots.
- View separate comparisons for Questing, Raid, and PvP profiles.
- Tune class/activity stat weights and physical/spell hit caps in the options.
- Automatically account for class and item eligibility; unusable items show
  `Cannot Use`.
- Spot equippable upgrades with optional arrows on bag item icons.
- Reopen the first-login setup guide at any time with `/gd setup`.
- Add manual Power Level values for item effects, weapon enchant procs, and
  set-bonus thresholds.

Power Level is a configurable comparison score, not a DPS simulation. Starter
weights are provided as a baseline and can be customized for your character.

## Requirements

- WoW: Forever Beta 1.60.1 (`Interface: 16001`).
- **GearDuck Weights** companion addon. Install it alongside GearDuck; it
  stores persistent class/activity weight profiles.

## Installation

Install both `GearDuck` and `GearDuckWeights` in your game's
`Interface/AddOns` directory as sibling folders, then restart the client or
run `/reload`.

## Commands

- `/gd` or `/gd help` - show available commands.
- `/gd options` - open GearDuck settings.
- `/gd setup` - reopen the setup guide.
- `/gd profile raid|quest|pvp` - select a single tooltip profile.
- `/gd hitcap <value>` - set physical and spell hit caps for the current
  class/activity.
- `/gd itembonus <value|clear>` - set or clear a manual item value.
- `/gd enchantbonus <value|clear>` - set or clear an enchanted weapon's
  proc-only value.
- `/gd setbonus <pieces> <value|clear>` - set or clear a set threshold value.
- `/gd debug` - print details for the most recently hovered item.

`/gearduck` is also available as an alias for `/gd`.

## Screenshots

See [`docs/SCREENSHOTS.md`](docs/SCREENSHOTS.md) for the capture checklist.
Only genuine in-game captures should be used in the addon gallery. The media
package currently contains no screenshots.
