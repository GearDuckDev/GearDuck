local _, addon = ...

addon.data = {
    STAT_ORDER = {
        "Strength", "Agility", "Stamina", "Intellect", "Spirit", "Hit", "Crit",
        "AttackPower", "RangedAttackPower", "SpellPower", "Healing", "ManaRegen",
        "Defense", "Dodge", "Parry", "Armor", "WeaponDPS", "WeaponSpeed", "WeaponSkill",
        "WeaponCritPercent", "WeaponExtraAttackPercent",
    },

    STAT_LABELS = {
        AttackPower = "Attack Power",
        RangedAttackPower = "Ranged Attack Power",
        SpellPower = "Spell Power / Damage",
        ManaRegen = "Mana Regeneration",
        WeaponDPS = "Weapon DPS",
        WeaponSpeed = "Weapon Speed Preference",
        WeaponSkill = "Weapon Skill",
        WeaponCritPercent = "Weapon-Specific Crit %",
        WeaponExtraAttackPercent = "Weapon-Specific Extra Attack %",
    },

    CLASS_OPTIONS = {
        { file = "WARRIOR", name = "Warrior" },
        { file = "PALADIN", name = "Paladin" },
        { file = "HUNTER", name = "Hunter" },
        { file = "ROGUE", name = "Rogue" },
        { file = "PRIEST", name = "Priest" },
        { file = "SHAMAN", name = "Shaman" },
        { file = "MAGE", name = "Mage" },
        { file = "WARLOCK", name = "Warlock" },
        { file = "DRUID", name = "Druid" },
    },

    EQUIP_SLOTS = {
        INVTYPE_HEAD = { 1 },
        INVTYPE_NECK = { 2 },
        INVTYPE_SHOULDER = { 3 },
        INVTYPE_BODY = { 4 },
        INVTYPE_CHEST = { 5 },
        INVTYPE_ROBE = { 5 },
        INVTYPE_WAIST = { 6 },
        INVTYPE_LEGS = { 7 },
        INVTYPE_FEET = { 8 },
        INVTYPE_WRIST = { 9 },
        INVTYPE_HAND = { 10 },
        INVTYPE_FINGER = { 11, 12 },
        INVTYPE_TRINKET = { 13, 14 },
        INVTYPE_CLOAK = { 15 },
        INVTYPE_WEAPON = { 16, 17 },
        INVTYPE_2HWEAPON = { 16, 17 },
        INVTYPE_WEAPONMAINHAND = { 16 },
        INVTYPE_WEAPONOFFHAND = { 17 },
        INVTYPE_SHIELD = { 17 },
        INVTYPE_HOLDABLE = { 17 },
        INVTYPE_RANGED = { 18 },
        INVTYPE_RANGEDRIGHT = { 18 },
        INVTYPE_THROWN = { 18 },
        INVTYPE_RELIC = { 18 },
    },

    EQUIP_SLOT_LABELS = {
        [1] = "Head",
        [2] = "Neck",
        [3] = "Shoulder",
        [4] = "Shirt",
        [5] = "Chest",
        [6] = "Waist",
        [7] = "Legs",
        [8] = "Feet",
        [9] = "Wrist",
        [10] = "Hands",
        [11] = "Ring 1",
        [12] = "Ring 2",
        [13] = "Trinket 1",
        [14] = "Trinket 2",
        [15] = "Back",
        [16] = "Main Hand",
        [17] = "Off Hand",
        [18] = "Ranged",
    },
}

local data = addon.data

data.STAT_KEYS = {
    Strength = { "ITEM_MOD_STRENGTH_SHORT" },
    Agility = { "ITEM_MOD_AGILITY_SHORT" },
    Stamina = { "ITEM_MOD_STAMINA_SHORT" },
    Intellect = { "ITEM_MOD_INTELLECT_SHORT" },
    Spirit = { "ITEM_MOD_SPIRIT_SHORT" },
    Hit = {
        "ITEM_MOD_HIT_RATING_SHORT",
        "ITEM_MOD_HIT_MELEE_RATING_SHORT",
        "ITEM_MOD_HIT_SPELL_RATING_SHORT",
    },
    Crit = {
        "ITEM_MOD_CRIT_RATING_SHORT",
        "ITEM_MOD_CRIT_MELEE_RATING_SHORT",
        "ITEM_MOD_CRIT_SPELL_RATING_SHORT",
    },
    AttackPower = { "ITEM_MOD_ATTACK_POWER_SHORT", "ITEM_MOD_ATTACK_POWER" },
    RangedAttackPower = { "ITEM_MOD_RANGED_ATTACK_POWER_SHORT" },
    SpellPower = { "ITEM_MOD_SPELL_POWER_SHORT", "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT" },
    Healing = { "ITEM_MOD_SPELL_HEALING_DONE_SHORT" },
    ManaRegen = { "ITEM_MOD_MANA_REGENERATION_SHORT" },
    Defense = { "ITEM_MOD_DEFENSE_SKILL_RATING_SHORT" },
    Dodge = { "ITEM_MOD_DODGE_RATING_SHORT" },
    Parry = { "ITEM_MOD_PARRY_RATING_SHORT" },
    Armor = { "RESISTANCE0_NAME" },
    WeaponDPS = {},
    WeaponSpeed = {},
    WeaponSkill = {},
    WeaponCritPercent = {},
    WeaponExtraAttackPercent = {},
}

-- Rough level-60 Classic starting weights, not simulation-derived values.
data.CLASS_WEIGHTS = {
    WARRIOR = {
        Strength = 2.0, Agility = 0.7, Stamina = 0.7, Hit = 1.3,
        Crit = 1.0, AttackPower = 0.8, Defense = 0.6, Dodge = 0.4,
        Parry = 0.4, Armor = 0.05, WeaponDPS = 2.0, WeaponSkill = 0.7,
        WeaponCritPercent = 3.0, WeaponExtraAttackPercent = 4.0,
    },
    PALADIN = {
        Strength = 1.3, Agility = 0.3, Stamina = 0.7, Intellect = 0.8,
        Spirit = 0.3, Hit = 0.7, Crit = 0.6, AttackPower = 0.8,
        SpellPower = 0.6, Healing = 0.5, ManaRegen = 0.4,
        Defense = 0.5, Armor = 0.05, WeaponDPS = 1.5, WeaponSkill = 0.5,
    },
    HUNTER = {
        Agility = 2.0, Stamina = 0.6, Intellect = 0.5, Spirit = 0.2,
        Hit = 1.2, Crit = 1.1, AttackPower = 0.8, RangedAttackPower = 1.3,
        WeaponDPS = 1.8, WeaponSkill = 0.5,
    },
    ROGUE = {
        Agility = 2.0, Stamina = 0.5, Hit = 1.5, Crit = 1.0,
        AttackPower = 1.0, WeaponDPS = 2.0, WeaponSkill = 0.7,
        WeaponCritPercent = 3.0, WeaponExtraAttackPercent = 4.0,
    },
    PRIEST = {
        Stamina = 0.6, Intellect = 1.2, Spirit = 0.9, Hit = 0.3,
        Crit = 0.4, SpellPower = 1.2, Healing = 1.0, ManaRegen = 0.7,
    },
    SHAMAN = {
        Strength = 0.7, Agility = 0.8, Stamina = 0.7, Intellect = 0.9,
        Spirit = 0.3, Hit = 0.8, Crit = 0.7, AttackPower = 0.7,
        SpellPower = 0.8, Healing = 0.6, ManaRegen = 0.5, WeaponDPS = 1.2,
        WeaponSkill = 0.4,
    },
    MAGE = {
        Stamina = 0.6, Intellect = 1.4, Spirit = 0.5, Hit = 1.0,
        Crit = 0.8, SpellPower = 1.4, ManaRegen = 0.4,
    },
    WARLOCK = {
        Stamina = 0.7, Intellect = 1.1, Spirit = 0.3, Hit = 1.0,
        Crit = 0.7, SpellPower = 1.5, ManaRegen = 0.3,
    },
    DRUID = {
        Strength = 0.7, Agility = 0.9, Stamina = 0.7, Intellect = 0.9,
        Spirit = 0.5, Hit = 0.6, Crit = 0.6, AttackPower = 0.6,
        SpellPower = 0.8, Healing = 0.7, ManaRegen = 0.5,
        Defense = 0.2, Dodge = 0.2, Armor = 0.03, WeaponDPS = 1.0,
        WeaponSkill = 0.3,
    },
}

data.CLASS_TALENT_TREE_NAMES = {
    WARRIOR = { TREE_1 = "Arms", TREE_2 = "Fury", TREE_3 = "Protection" },
    PALADIN = { TREE_1 = "Holy", TREE_2 = "Protection", TREE_3 = "Retribution" },
    HUNTER = { TREE_1 = "Beast Mastery", TREE_2 = "Marksmanship", TREE_3 = "Survival" },
    ROGUE = { TREE_1 = "Assassination", TREE_2 = "Combat", TREE_3 = "Subtlety" },
    PRIEST = { TREE_1 = "Discipline", TREE_2 = "Holy", TREE_3 = "Shadow" },
    SHAMAN = { TREE_1 = "Elemental", TREE_2 = "Enhancement", TREE_3 = "Restoration" },
    MAGE = { TREE_1 = "Arcane", TREE_2 = "Fire", TREE_3 = "Frost" },
    WARLOCK = { TREE_1 = "Affliction", TREE_2 = "Demonology", TREE_3 = "Destruction" },
    DRUID = { TREE_1 = "Balance", TREE_2 = "Feral Combat", TREE_3 = "Restoration" },
}

-- Sparse adjustments to the class baselines above. These are broad tree/role
-- heuristics intended to be useful before a player has custom weights.
data.CLASS_TALENT_WEIGHT_OVERRIDES = {
    WARRIOR = {
        TREE_1 = { Strength = 2.2, Agility = 0.8, Hit = 1.4, Crit = 1.1 },
        TREE_2 = { Strength = 2.1, Agility = 0.8, Hit = 1.5, AttackPower = 0.9 },
        TREE_3 = {
            Strength = 1.6, Agility = 0.5, Stamina = 1.1, Hit = 1.0, Crit = 0.6,
            Defense = 1.2, Dodge = 0.8, Parry = 0.8, Armor = 0.08,
        },
    },
    PALADIN = {
        TREE_1 = {
            Strength = 0.6, Intellect = 1.4, Spirit = 0.5, SpellPower = 1.2,
            Healing = 1.4, ManaRegen = 0.8, WeaponDPS = 0.6,
        },
        TREE_2 = {
            Strength = 1.2, Stamina = 1.0, Intellect = 0.6, Hit = 0.7,
            SpellPower = 0.5, Healing = 0.5, Defense = 1.1, Armor = 0.08,
        },
        TREE_3 = {
            Strength = 1.7, Agility = 0.5, Hit = 1.0, Crit = 0.9,
            AttackPower = 1.0, SpellPower = 0.4, Healing = 0.3, WeaponDPS = 1.8,
        },
    },
    HUNTER = {
        TREE_1 = { Agility = 2.1, Stamina = 0.7, RangedAttackPower = 1.4, WeaponDPS = 1.9 },
        TREE_2 = { Agility = 2.2, Hit = 1.3, Crit = 1.2, RangedAttackPower = 1.5 },
        TREE_3 = {
            Agility = 2.0, Stamina = 0.8, Hit = 1.2, Crit = 1.2,
            AttackPower = 0.9, RangedAttackPower = 1.2, WeaponDPS = 1.6,
        },
    },
    ROGUE = {
        TREE_1 = { Agility = 2.1, Hit = 1.4, Crit = 1.2, AttackPower = 1.1 },
        TREE_2 = { Agility = 2.0, Hit = 1.6, Crit = 1.0, WeaponDPS = 2.1, WeaponSkill = 0.8 },
        TREE_3 = { Agility = 2.1, Stamina = 0.6, Hit = 1.3, Crit = 1.2, AttackPower = 1.0 },
    },
    PRIEST = {
        TREE_1 = { Intellect = 1.3, Spirit = 1.0, SpellPower = 1.0, Healing = 1.1, ManaRegen = 0.9 },
        TREE_2 = { Intellect = 1.2, Spirit = 1.0, SpellPower = 1.0, Healing = 1.4, ManaRegen = 0.9 },
        TREE_3 = { Intellect = 1.3, Spirit = 0.7, Hit = 0.8, Crit = 0.6, SpellPower = 1.5, Healing = 0.3 },
    },
    SHAMAN = {
        TREE_1 = {
            Strength = 0.3, Agility = 0.4, Intellect = 1.2, Spirit = 0.4, Hit = 0.8,
            Crit = 0.8, SpellPower = 1.4, Healing = 0.3, ManaRegen = 0.6, WeaponDPS = 0.5,
        },
        TREE_2 = {
            Strength = 1.0, Agility = 1.0, Intellect = 0.7, Hit = 1.0, Crit = 0.9,
            AttackPower = 0.9, SpellPower = 0.5, Healing = 0.3, WeaponDPS = 1.6,
        },
        TREE_3 = {
            Strength = 0.3, Agility = 0.4, Intellect = 1.2, Spirit = 0.7, Hit = 0.4,
            Crit = 0.4, SpellPower = 0.8, Healing = 1.4, ManaRegen = 0.8, WeaponDPS = 0.4,
        },
    },
    MAGE = {
        TREE_1 = { Intellect = 1.5, Spirit = 0.6, Hit = 1.0, Crit = 0.7, SpellPower = 1.4, ManaRegen = 0.6 },
        TREE_2 = { Intellect = 1.3, Spirit = 0.4, Hit = 1.1, Crit = 1.0, SpellPower = 1.6, ManaRegen = 0.3 },
        TREE_3 = { Intellect = 1.4, Spirit = 0.6, Hit = 1.0, Crit = 0.8, SpellPower = 1.5, ManaRegen = 0.5 },
    },
    WARLOCK = {
        TREE_1 = { Stamina = 0.8, Intellect = 1.2, Spirit = 0.4, Hit = 1.0, Crit = 0.6, SpellPower = 1.6 },
        TREE_2 = { Stamina = 0.9, Intellect = 1.2, Spirit = 0.3, Hit = 0.9, Crit = 0.6, SpellPower = 1.4 },
        TREE_3 = { Stamina = 0.7, Intellect = 1.1, Hit = 1.1, Crit = 0.9, SpellPower = 1.7 },
    },
    DRUID = {
        TREE_1 = {
            Strength = 0.2, Agility = 0.4, Intellect = 1.2, Spirit = 0.6, Hit = 0.9,
            Crit = 0.8, AttackPower = 0.2, SpellPower = 1.4, Healing = 0.5, ManaRegen = 0.6,
        },
        TREE_2 = {
            Strength = 1.1, Agility = 1.3, Stamina = 0.9, Intellect = 0.4, Hit = 1.0,
            Crit = 1.0, AttackPower = 1.0, SpellPower = 0.1, Healing = 0.1,
            Defense = 0.7, Dodge = 0.7, Armor = 0.06, WeaponDPS = 1.3,
        },
        TREE_3 = {
            Strength = 0.2, Agility = 0.4, Intellect = 1.1, Spirit = 0.8, Hit = 0.3,
            Crit = 0.3, AttackPower = 0.2, SpellPower = 0.8, Healing = 1.3, ManaRegen = 0.7,
        },
    },
}

data.ACTIVITY_WEIGHT_MULTIPLIERS = {
    QUEST = {},
    RAID = { Hit = 1.1, Spirit = 1.05, ManaRegen = 1.1, Stamina = 0.9 },
    PVP = {
        Stamina = 1.35, Hit = 0.85, Defense = 1.2, Dodge = 1.2, Parry = 1.2,
        Spirit = 0.9, ManaRegen = 1.1,
    },
}

data.CLASS_ACTIVITY_HIT_CAPS = {
    QUEST = { physical = 5, spell = 3 },
    RAID = { physical = 9, spell = 16 },
    PVP = { physical = 5, spell = 3 },
}

data.CLASSIC_DEFAULT_WEIGHTS = {
    Strength = 0.8, Agility = 0.8, Stamina = 0.5, Intellect = 0.5,
    Spirit = 0.3, Hit = 0.8, Crit = 0.7, AttackPower = 0.7,
    RangedAttackPower = 0.7, SpellPower = 0.7, Healing = 0.7,
    ManaRegen = 0.3, Defense = 0.2, Dodge = 0.2, Parry = 0.2,
    Armor = 0.02, WeaponSkill = 0.4,
    WeaponCritPercent = 0, WeaponExtraAttackPercent = 0,
}

data.SCORING_CONTEXTS = {
    RAID = "Raid",
    QUEST = "Questing",
    PVP = "PvP",
}

data.SCORING_CONTEXT_ORDER = {
    { key = "QUEST", name = "Questing" },
    { key = "RAID", name = "Raid" },
    { key = "PVP", name = "PvP" },
}

local function copyWeights(weights)
    local copy = {}
    for statName, weight in pairs(weights) do
        copy[statName] = weight
    end
    return copy
end

local function buildActivityWeights(baseWeights, contextKey)
    local weights = copyWeights(baseWeights)
    local multipliers = data.ACTIVITY_WEIGHT_MULTIPLIERS[contextKey] or {}
    for statName, multiplier in pairs(multipliers) do
        if weights[statName] then
            weights[statName] = weights[statName] * multiplier
        end
    end
    return weights
end

data.CLASS_ACTIVITY_DEFAULTS = {}
for classFile, classWeights in pairs(data.CLASS_WEIGHTS) do
    data.CLASS_ACTIVITY_DEFAULTS[classFile] = {}
    for _, context in ipairs(data.SCORING_CONTEXT_ORDER) do
        data.CLASS_ACTIVITY_DEFAULTS[classFile][context.key] = {
            weights = buildActivityWeights(classWeights, context.key),
            hitCaps = {
                physical = data.CLASS_ACTIVITY_HIT_CAPS[context.key].physical,
                spell = data.CLASS_ACTIVITY_HIT_CAPS[context.key].spell,
            },
        }
    end
end

data.CLASS_TALENT_DEFAULTS = {}
for classFile, treeProfiles in pairs(data.CLASS_TALENT_WEIGHT_OVERRIDES) do
    data.CLASS_TALENT_DEFAULTS[classFile] = {}
    for _, context in ipairs(data.SCORING_CONTEXT_ORDER) do
        local contextProfiles = {}
        data.CLASS_TALENT_DEFAULTS[classFile][context.key] = contextProfiles
        for treeKey, overrides in pairs(treeProfiles) do
            local treeWeights = copyWeights(data.CLASS_WEIGHTS[classFile])
            for statName, weight in pairs(overrides) do
                treeWeights[statName] = weight
            end
            contextProfiles[treeKey] = buildActivityWeights(treeWeights, context.key)
        end
    end
end

data.RACIAL_WEAPON_SKILL = {
    Human = { [4] = 5, [5] = 5, [7] = 5, [8] = 5 },
    Dwarf = { [3] = 5 },
    Orc = { [0] = 5, [1] = 5, [13] = 5 },
    Troll = { [2] = 5, [16] = 5 },
}

data.TALENT_WEAPON_EFFECTS = {
    ["weapon expertise"] = {
        ROGUE = { skillRanks = { 3, 5 }, subclasses = { 7, 8, 13, 15 } },
    },
    ["mace specialization"] = {
        ROGUE = { skillPerRank = 1, subclasses = { 4, 5 } },
    },
    ["axe specialization"] = {
        WARRIOR = { critPerRank = 1, subclasses = { 0, 1 } },
    },
    ["polearm specialization"] = {
        WARRIOR = { critPerRank = 1, subclasses = { 6 } },
    },
    ["sword specialization"] = {
        WARRIOR = { extraAttackPerRank = 2, subclasses = { 7, 8 } },
        ROGUE = { extraAttackPerRank = 1, subclasses = { 7, 8 } },
    },
    ["dagger specialization"] = {
        ROGUE = { critPerRank = 1, subclasses = { 15 } },
    },
    ["fist weapon specialization"] = {
        ROGUE = { critPerRank = 1, subclasses = { 13 } },
    },
    ["two-handed weapon specialization"] = {
        WARRIOR = { damagePerRank = 1, subclasses = { 1, 5, 6, 8, 10 } },
        PALADIN = { damagePerRank = 2, subclasses = { 1, 5, 6, 8, 10 } },
    },
    ["one-handed weapon specialization"] = {
        WARRIOR = { damagePerRank = 2, subclasses = { 0, 4, 7, 13, 15 } },
        PALADIN = { damagePerRank = 2, subclasses = { 0, 4, 7, 13, 15 } },
    },
    ["ranged weapon specialization"] = {
        HUNTER = { damagePerRank = 1, subclasses = { 2, 3, 18 } },
    },
}

data.HIT_TALENT_EFFECTS = {
    precision = {
        WARRIOR = { physicalPerRank = 1, maxRanks = 3 },
        PALADIN = { physicalPerRank = 1, spellPerRank = 1, maxRanks = 3 },
        ROGUE = { physicalPerRank = 1, maxRanks = 3 },
    },
    surefooted = { HUNTER = { physicalPerRank = 1, maxRanks = 3 } },
    ["arcane focus"] = { MAGE = { spellPerRank = 2, maxRanks = 5 } },
    ["shadow focus"] = { PRIEST = { spellPerRank = 2, maxRanks = 5 } },
    suppression = { WARLOCK = { spellPerRank = 2, maxRanks = 5 } },
    ["balance of power"] = { DRUID = { spellPerRank = 2, maxRanks = 2 } },
    ["elemental precision"] = { SHAMAN = { spellPerRank = 1, maxRanks = 3 } },
}

data.CLASS_HIT_TYPES = {
    WARRIOR = { physical = true },
    PALADIN = { physical = true, spell = true },
    HUNTER = { physical = true },
    ROGUE = { physical = true },
    PRIEST = { spell = true },
    SHAMAN = { physical = true, spell = true },
    MAGE = { spell = true },
    WARLOCK = { spell = true },
    DRUID = { physical = true, spell = true },
}

data.WEAPON_SUBCLASS_NAMES = {
    [0] = "Axes",
    [1] = "Two-Handed Axes",
    [2] = "Bows",
    [3] = "Guns",
    [4] = "Maces",
    [5] = "Two-Handed Maces",
    [6] = "Polearms",
    [7] = "Swords",
    [8] = "Two-Handed Swords",
    [10] = "Staves",
    [13] = "Fist Weapons",
    [15] = "Daggers",
    [16] = "Thrown Weapons",
    [17] = "Spears",
    [18] = "Crossbows",
    [19] = "Wands",
    [20] = "Fishing Poles",
}

data.CLASS_WEAPON_PROFICIENCIES = {
    WARRIOR = {
        [0] = true, [1] = true, [2] = true, [3] = true, [4] = true, [5] = true,
        [6] = 20, [7] = true, [8] = true, [10] = true, [13] = true, [15] = true,
        [16] = true, [17] = 20, [18] = true, [20] = true,
    },
    PALADIN = {
        [0] = true, [1] = true, [4] = true, [5] = true, [6] = 20, [7] = true,
        [8] = true, [17] = 20, [20] = true,
    },
    HUNTER = {
        [0] = true, [1] = true, [2] = true, [3] = true, [6] = 20, [7] = true,
        [8] = true, [10] = true, [13] = true, [15] = true, [16] = true,
        [17] = 20, [18] = true, [20] = true,
    },
    ROGUE = {
        [2] = true, [3] = true, [4] = true, [7] = true, [13] = true, [15] = true,
        [16] = true, [18] = true, [20] = true,
    },
    PRIEST = { [4] = true, [10] = true, [15] = true, [19] = true, [20] = true },
    SHAMAN = {
        [0] = true, [1] = "talent", [4] = true, [5] = "talent", [10] = true,
        [13] = true, [15] = true, [20] = true,
    },
    MAGE = { [7] = true, [10] = true, [15] = true, [19] = true, [20] = true },
    WARLOCK = { [7] = true, [10] = true, [15] = true, [19] = true, [20] = true },
    DRUID = {
        [4] = true, [5] = true, [6] = 20, [10] = true, [13] = true, [15] = true,
        [17] = 20, [20] = true,
    },
}

data.CLASS_ARMOR_PROFICIENCIES = {
    WARRIOR = { [0] = true, [1] = true, [2] = true, [3] = true, [4] = true, [5] = true, [6] = true },
    PALADIN = { [0] = true, [1] = true, [2] = true, [3] = true, [4] = true, [5] = true, [6] = true, [7] = true },
    HUNTER = { [0] = true, [1] = true, [2] = true, [3] = true, [5] = true },
    ROGUE = { [0] = true, [1] = true, [2] = true, [5] = true },
    PRIEST = { [0] = true, [1] = true, [5] = true },
    SHAMAN = { [0] = true, [1] = true, [2] = true, [3] = true, [5] = true, [6] = true, [9] = true },
    MAGE = { [0] = true, [1] = true, [5] = true },
    WARLOCK = { [0] = true, [1] = true, [5] = true },
    DRUID = { [0] = true, [1] = true, [2] = true, [5] = true, [8] = true },
}
