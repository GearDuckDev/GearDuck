# GearDuck

GearDuck is a lightweight World of Warcraft: Forever addon that estimates item upgrades from editable, class-based stat weights. It adds a Power Level comparison to item tooltips and provides an in-game options panel for tuning weights.

> **Compatibility:** Built for WoW: Forever Beta 1.60.1 (`Interface: 16001`). The addon uses the modern item tooltip post-call API.

## Features

- Detects your current class and selects its weight profile automatically. Profiles are provided for the nine original WoW Classic classes.
- Detects your active talent tree automatically and uses a separate editable weight profile for it. Talent data is cached and refreshed on talent/group changes.
- Factors supported racial weapon skill and weapon-specific talent effects into matching weapon subclasses.
- Compares an item against each applicable equipped slot. Rings, trinkets, and one-handed weapons show separate comparisons; two-handed weapons compare against both weapon slots together.
- Checks weapon and armor eligibility using explicit rules for all nine Classic classes; unusable items show `Cannot Use` instead of upgrade comparisons. Includes level-20 polearm training, level-40 mail/plate unlocks, Shaman's two-handed weapon talent, and item required-level checks.
- Labels comparisons as upgrades, sidegrades, or downgrades.
- Includes weapon DPS and weapon speed in scoring when the item tooltip exposes damage and speed values.
- Shows separate Power Level comparisons for an enchanted weapon with and without its enchant.
- Supports switchable raid, questing, and PvP contexts, with a configurable hit cap for each context.
- Supports manual Power Level values for proc/use effects and set-bonus thresholds.
- Lets you edit class stat weights in the AddOns settings panel. Settings are saved in `GearDuckDB`.
- Includes `/gd debug` to print item stats, weighted contributions, and comparison math to chat.

## Install

1. In your WoW: Forever installation, open `Interface/AddOns`.
2. Create a folder named `GearDuck` if it does not already exist.
3. Copy `GearDuck.toc` and `GearDuck.lua` from this repository's `GearDuck` folder into that folder.
4. Restart the client or type `/reload` if it is already running.

The installed path should look like this:

```text
Interface/
└── AddOns/
    └── GearDuck/
        ├── GearDuck.lua
        └── GearDuck.toc
```

## Commands

| Command | Description |
| --- | --- |
| `/gd help` | Show the addon command list. This is also shown by `/gd` with no argument. |
| `/gd debug` | Print the most recently hovered item's raw stats, weighted math, and slot comparisons. |
| `/gd options` | Open the GearDuck settings panel. |
| `/gd profile raid\|quest\|pvp` | Select the activity context used for comparisons. |
| `/gd hitcap <value>` | Set the current context's hit cap in raw item-stat units. Use `0` to disable hit capping. |
| `/gd itembonus <value\|clear>` | Set or clear a manual Power Level value for the currently hovered item. |
| `/gd enchantbonus <value\|clear>` | Set or clear a proc-only Power Level value for the hovered weapon enchant. |
| `/gd setbonus <pieces> <value\|clear>` | Set or clear a manual value for a hovered item's set at a piece-count threshold. |

`/gearduck` is an alias for `/gd`, so the same subcommands work with either prefix.

## Configure Weights

Use `/gd options` or open **Options → AddOns → GearDuck**. Select a class, then edit its numeric weights. The active character's talent tree is detected automatically; the tree picker is not needed. Press Enter or move focus away from a field to save its value. Set a weight to `0` to ignore that stat. **Reset this class** restores the addon's starting values for the selected profile.

Available weights include Strength, Agility, Stamina, Intellect, Spirit, Hit, Crit, Attack Power, Ranged Attack Power, Spell Power / Damage, Healing, Mana Regeneration, Defense, Dodge, Parry, Armor, Weapon DPS, Weapon Speed Preference, Weapon Skill, Weapon-Specific Crit %, and Weapon-Specific Extra Attack %. Each class/talent profile can be edited independently. Positive weapon-speed weights favor slower weapons; negative values favor faster weapons. Weapon-skill, crit, and extra-attack weights are heuristic Power Level units, not exact DPS simulations.

The activity selector stores a separate hit cap for raid, questing, and PvP. Enter the cap in the same raw units returned for Hit by the item API. A value of `0` leaves Hit uncapped; the defaults are `0` because Forever's exact rating-to-cap conversion can vary by ruleset and character level. Current cap calculations count equipped-item Hit only; account for hit from talents or buffs yourself when choosing a cap.

### Manual Effects

GearDuck cannot derive a reliable average value for every proc or use effect from tooltip text alone. Set an item-specific value while its tooltip is visible with `/gd itembonus 12`; clear it with `/gd itembonus clear`. The example value is added as 12 Power Level to that item's score.

Enchanted weapons show one comparison with the enchant field removed from the item link and one with the enchant intact. Static enchant stats returned by the item API are scored automatically. Proc-only enchant effects can be valued with `/gd enchantbonus 12` while hovering the enchanted weapon, and cleared with `/gd enchantbonus clear`.

For set bonuses, hover an item from the set and use `/gd debug` to find its set ID. Then enter the effect's estimated value at its threshold, for example `/gd setbonus 2 15` for a 15-point value when the equipped count reaches two pieces. GearDuck tracks equipped set counts and applies the value only when an item comparison crosses that threshold. Use `/gd setbonus 2 clear` to remove it.

## How Power Level Works

The addon reads item stats through the WoW item API and multiplies them by the selected class/talent profile's weights. For weapons, it reads damage and speed from localized tooltip formats and derives DPS as average damage divided by speed. The result is a relative estimate, not an in-game character rating.

The initial profiles are editable, level-60 Classic-style placeholders, not simulation-derived weights. Talent-tree profiles begin with their class defaults and can be tuned independently. The scan recognizes Classic racial skill bonuses; Warrior/Rogue weapon-specific crit and sword extra-attack talents; Hunter ranged-weapon damage specialization; and Warrior/Paladin one- and two-handed damage specializations. Weapon skill affects its own term; crit and extra attacks use their separate profile weights; damage talents scale the parsed weapon DPS contribution. These are simplified expected-value heuristics and do not model rotations, proc interactions, or encounter-specific uptime. Stun/control talents are not counted as direct DPS. Other proc/use effects and set bonuses require manual values; proc-only enchant value can be set separately. Hit caps require a raw stat threshold for each context. Check `/gd debug` to inspect the active class/talent profile, item stats, and comparison math.

Equipability uses hard-coded Classic class proficiency rules rather than the client equipability API. It assumes a character has trained weapon types that their class can learn; the addon does not inspect the character's learned weapon-skill lines or parse item-specific class restrictions. Polearm, armor-level, Shaman talent, and item required-level gates are checked explicitly.
