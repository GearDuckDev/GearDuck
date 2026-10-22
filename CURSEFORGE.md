# GearDuck: Item Comparisons for WoW: Forever

**See item upgrades at a glance, with weights you can tune to your character.**

GearDuck calculates an item's **Power Level** from editable stat weights and
compares it with your equipped gear, helping you spot an **Upgrade**,
**Sidegrade**, or **Downgrade** at a glance. It automatically detects your class
and active talent tree, then uses independent Questing, Raid, and PvP profiles.

Built for **WoW: Forever Beta 1.60.1** (`Interface: 16001`) by **GearDuckDev**.

***

## Core features

- **At-a-glance upgrades:** optional up arrows mark equippable upgrades on
  supported bag, quest reward, mail, and vendor item icons. Supports default
  Blizzard bags and Baganator.
- **Class, tree, and activity weights:** automatically selects starter weights
  for your class and active talent tree. Questing, Raid, and PvP each have
  editable weights and hit caps.
- **Useful out of the box:** starter weights cover the nine original Classic
  classes and their major talent trees.
- **Slot-aware comparisons:** rings, trinkets, and eligible one-handed weapons
  compare against the applicable equipped slots. Two-handed weapons compare
  against both equipped weapon slots together.
- **Eligibility checks:** explicit Classic rules include level-20 polearm
  training, level-40 armor unlocks, and the Shaman two-handed weapon talent.
  Item-specific class restrictions are also checked, such as Shaman-only gear.
  Items you cannot equip show `Cannot Use` and never receive upgrade arrows.
- **Weapon calculations:** accounts for supported racial weapon skills,
  weapon-specific talent effects, weapon DPS and speed, and separate weapon
  comparisons with and without enchants.
- **First-time setup:** a per-character guide introduces Power Level and asks
  about stat weights, tooltip profiles, and upgrade arrows. Reopen it with
  `/gd setup`.

Power Level is a configurable comparison score, **not a DPS simulation**.
Starter weights are broad level-60 Classic-style estimates, not exact rankings.
Gear, role, encounter, talents, and playstyle can change what is best; treat
defaults as a baseline and customize them for your character.

***

## Configuration and tuning

Use `/gd options` or open **Options > AddOns > GearDuck**.

- **Custom weights:** edit Strength, Agility, Stamina, Intellect, Spirit, Hit,
  Crit, Attack Power, Ranged Attack Power, Spell Power, Healing, Mana
  Regeneration, defensive stats, Weapon DPS, Weapon Speed Preference, and more.
  Positive speed weights favor slower weapons; negative values favor faster
  weapons.
- **Activity profiles:** show any combination of Questing, Raid, and PvP
  comparisons, each with its own class/talent-tree weights.
- **Hit caps:** configure separate physical and spell hit caps for each
  activity. Recognized talent hit bonuses and applicable dual-wielding caps are
  accounted for.
- **Restore defaults:** reset the selected class/activity/talent-tree profile.
  Custom weights are not overwritten just because the addon updates.

### Advanced: manual effects and set bonuses

Tooltip text cannot always provide a reliable average value for unique procs
or use effects. Assign a manual Power Level value when needed:

- **Item effects:** hover an item and use `/gd itembonus 12` to add 12 Power
  Level. Clear it with `/gd itembonus clear`.
- **Enchant procs:** hover an enchanted weapon and use `/gd enchantbonus 12`
  to assign a proc-only value.
- **Set bonuses:** hover a set item and use `/gd debug` to inspect its set
  information. `/gd setbonus 2 15` assigns 15 Power Level at the two-piece
  threshold for that set.

***

## Requirements and installation

Install **GearDuck** and its required **GearDuck Weights** companion addon in
your WoW: Forever client's `Interface/AddOns` directory as sibling folders:

```text
Interface\AddOns\GearDuck\GearDuck.toc
Interface\AddOns\GearDuckWeights\GearDuckWeights.toc
```

Enable both addons, then restart the client or run `/reload`. GearDuck Weights
stores your persistent weight profiles separately from the addon code.

**[Source and downloads on GitHub](https://github.com/GearDuckDev/GearDuck).**

***

## Commands

- `/gd` or `/gd help` - show available commands.
- `/gd options` - open GearDuck settings.
- `/gd setup` - reopen the setup guide.
- `/gd profile raid|quest|pvp` - select a single tooltip profile.
- `/gd hitcap <value>` - set physical and spell hit caps for the current
  class/activity.
- `/gd hitcap physical|spell <value>` - set only the specified hit cap.
- `/gd itembonus <value|clear>` - set or clear a manual item value.
- `/gd enchantbonus <value|clear>` - set or clear an enchanted weapon's
  proc-only value.
- `/gd setbonus <pieces> <value|clear>` - set or clear a set threshold value.
- `/gd debug` - print details for the most recently hovered item.

`/gearduck` is also available as an alias for `/gd`.

***

## Screenshots: in-game addon

Actual in-game captures supplied by the developer, cropped at native resolution.
The profile example shows Questing and Raid giving the same result for this
item; other items and custom weights can produce different results.

### Spot upgrades in your bags

![Item tooltip showing a Questing upgrade and a green bag upgrade arrow](https://raw.githubusercontent.com/GearDuckDev/GearDuck/main/docs/screenshots/01-tooltip-upgrade.png)

### Compare multiple activities

![Item tooltip showing separate Questing and Raid upgrade comparisons](https://raw.githubusercontent.com/GearDuckDev/GearDuck/main/docs/screenshots/02-tooltip-profiles.png)

### Customize weights and display preferences

![GearDuck settings showing profile choices, upgrade arrows, hit caps, and editable stat weights](https://raw.githubusercontent.com/GearDuckDev/GearDuck/main/docs/screenshots/03-options-weights.png)

### Get started in game

![GearDuck setup guide welcome page](https://raw.githubusercontent.com/GearDuckDev/GearDuck/main/docs/screenshots/04-setup-guide.png)

[Browse the full screenshot gallery](https://github.com/GearDuckDev/GearDuck/blob/main/docs/SCREENSHOTS.md).
