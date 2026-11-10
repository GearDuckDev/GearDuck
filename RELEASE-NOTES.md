# GearDuck 1.1.0-release

## Set-aware gear comparisons

- Automatically reads supported unconditional set-bonus stats from item
  tooltips, with no item-specific bonus entries.
- Adds a bonus only when a swap activates its piece-count threshold, and
  subtracts it when replacing equipped gear breaks that threshold.
- Uses each Questing, Raid, and PvP profile's weights and caps set Hit
  together with the rest of the loadout.
- Remembers learned thresholds across reloads, allowing active green
  `Set: ...` lines to be scored even when they hide their piece counts.
- Preserves manual `/gd setbonus` values as full overrides at their
  thresholds. Clearing an override restores supported automatic scoring.
- Flags unsupported effects and incomplete set data, with details available
  through `/gd debug`.
- Expands Lua 5.1 regression coverage to 436 assertions, including negative
  item stats, set activation/loss, overrides, and reverse comparisons.

## First use with an active set

If a set is already active when GearDuck first encounters it, briefly unequip
enough pieces to make its bonuses gray, hover a set item, then re-equip.
GearDuck learns the numbered thresholds and saves them for future comparisons.

Conditional effects, procs, and other unsupported bonuses still require a
manual value. Existing custom weights and manual values are preserved.

Power Level is a configurable estimate, not a DPS simulation. Starter weights
are broad level-60 Classic-style baselines and can be customized in game.

## Compatibility and installation

Built for WoW: Forever Beta 1.60.1 (`Interface: 16001`). Install GearDuck and
the required GearDuck Weights companion as sibling folders in
`Interface/AddOns`, then enable both addons.

See [CURSEFORGE.md](CURSEFORGE.md) for the full feature description and
[docs/SCREENSHOTS.md](docs/SCREENSHOTS.md) for the prepared release images and
upload captions.
