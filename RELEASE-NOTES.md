# GearDuck 0.6.7-release

GearDuck 0.6.7-release helps you compare gear in WoW: Forever using a
customizable Power Level score.

## Bug fixes

- Fixed loot-roll upgrade arrows requiring a mouseover and disappearing after
  equipment changes. Roll icons now refresh automatically against current gear.
- Fixed item-specific class restrictions being ignored. Gear restricted to
  another class now shows `Cannot Use` and does not receive an upgrade arrow,
  even when its armor or weapon type is otherwise usable.
- Prevented incomplete class-eligibility checks from being cached while item
  tooltip data is still loading.

## Highlights

- Compare an item's score against the gear currently equipped in the relevant
  slot, with Upgrade, Sidegrade, and Downgrade labels.
- Automatically select class and talent-tree starter weights.
- Configure independent Questing, Raid, and PvP profiles, including hit caps.
- See optional upgrade arrows on eligible item icons in bags.
- Use the first-login setup guide to choose profile and display preferences.
- Add manual values for item effects, weapon enchant procs, and set bonuses.

Power Level is an estimate based on editable weights, not a DPS simulation.
The included starter weights are intended as a baseline.

## Compatibility and installation

Built for WoW: Forever Beta 1.60.1 (`Interface: 16001`). GearDuck requires the
GearDuck Weights companion addon. Install both addon folders side by side in
`Interface/AddOns`.

See [CURSEFORGE.md](CURSEFORGE.md) for the full feature description and
[docs/SCREENSHOTS.md](docs/SCREENSHOTS.md) for the four prepared release images
and upload captions.
