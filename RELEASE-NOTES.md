# GearDuck 1.2.0-release

## WoW: Forever stat profiles

- Adds editable starter profiles for all class talent trees across Questing,
  PvP, and Raid, with a choice between Feral Cat and Feral Bear.
- Adds separate melee and ranged weapon DPS weights, including weapon DPS for
  Feral profiles and ranged DPS for Hunter profiles.
- Adds Expertise, Haste, Block, and Block Value weights. Expertise recognizes
  supported tooltip percentages and item rating; recognized weapon-skill
  bonuses are evaluated against the equipped weapon types.
- Updates Hit rating conversion and selected talent and trait detection for
  WoW: Forever. Supported new set-bonus stats are included in comparisons.
- Preserves existing numeric weights and hit caps. Newly added weight fields
  receive defaults when absent; review ranged DPS if you customized the old
  shared weapon DPS weight. Restore defaults also resets the selected
  class/activity's hit caps.

Power Level is a configurable estimate, not a DPS simulation. Starter weights
are unvalidated estimates. Expertise is uncapped, and tooltip wording,
weapon-skill bonuses, set effects, and talent detection have limitations.
Live WoW-client validation is still needed. See [README.md](README.md) for
details.

## Compatibility and installation

Built for WoW: Forever Beta 1.60.1 (`Interface: 16001`). Install GearDuck and
the required GearDuck Weights companion as sibling folders in
`Interface/AddOns`, then enable both addons.

See [CURSEFORGE.md](CURSEFORGE.md) for the full feature description and
[docs/SCREENSHOTS.md](docs/SCREENSHOTS.md) for the prepared release images and
upload captions.
