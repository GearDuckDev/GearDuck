local _, addon = ...
local data = addon.data

-- Supplied starter estimates; percentage weights are converted to rating weights
-- using the level-60 Forever conversion. Unsupported fields are omitted.
local presets = {
    WARRIOR = {
        TREE_1 = {
            QUEST = {str=2,agi=1,sta=.8,ap=1,hit=16,crit=16,wskill=2.5,wdps=8},
            PVP = {str=2.2,agi=1.2,sta=2,ap=1,hit=18,crit=24,wdps=14,armor=.1},
            RAID = {str=2.2,agi=1.3,ap=1,hit=28,crit=24,wskill=18,wdps=15},
        },
        TREE_2 = {
            QUEST = {str=2,agi=1.1,sta=.7,ap=1,hit=20,crit=18,wskill=3,wdps=9},
            PVP = {str=2.1,agi=1.2,sta=1.8,ap=1,hit=20,crit=24,wdps=13,armor=.1},
            RAID = {str=2.2,agi=1.4,ap=1,hit=32,crit=28,wskill=22,wdps=16},
        },
        TREE_3 = {
            QUEST = {sta=1,str=.9,agi=.6,ap=.4,hit=8,crit=6,def=1,armor=.08,wdps=5},
            PVP = {sta=1.5,str=.8,agi=.7,ap=.4,hit=10,crit=10,def=.5,armor=.15},
            RAID = {sta=1,str=.6,agi=.8,hit=18,crit=10,wskill=14,def=1.8,dodge=14,parry=14,armor=.12},
        },
    },
    ROGUE = {
        TREE_1 = {
            QUEST = {agi=1.9,str=1,sta=.6,ap=1,hit=18,crit=17,wskill=2.5,wdps=7.5},
            PVP = {agi=2.1,str=1,sta=1.6,ap=1,hit=16,crit=24,wdps=12},
            RAID = {agi=2.2,str=1,ap=1,hit=28,crit=26,wskill=18,wdps=14},
        },
        TREE_2 = {
            QUEST = {agi=2,str=1,sta=.6,ap=1,hit=20,crit=16,wskill=3,wdps=8.5},
            PVP = {agi=2,str=1,sta=1.6,ap=1,hit=16,crit=22,wdps=12.5},
            RAID = {agi=2.2,str=1,ap=1,hit=30,crit=25,wskill=20,wdps=16},
        },
        TREE_3 = {
            QUEST = {agi=2,str=1,sta=.6,ap=1,hit=16,crit=18,wskill=2,wdps=8},
            PVP = {agi=2.3,str=1,sta=1.8,ap=1,hit=15,crit=26,wdps=13.5},
            RAID = {agi=2.3,str=1,ap=1,hit=28,crit=26,wskill=18,wdps=14.5},
        },
    },
    HUNTER = {
        TREE_1 = {
            QUEST = {agi=2,int=1.1,sta=.5,ap=1,rap=1,hit=16,crit=16},
            PVP = {agi=2.1,int=1.2,sta=1.6,ap=1,rap=1,hit=16,crit=24},
            RAID = {agi=2.2,int=1.1,ap=1,rap=1,hit=28,crit=26},
        },
        TREE_2 = {
            QUEST = {agi=2.1,int=1.2,sta=.5,ap=1,rap=1,hit=18,crit=18},
            PVP = {agi=2.2,int=1.2,sta=1.6,ap=1,rap=1,hit=18,crit=26},
            RAID = {agi=2.3,int=1.2,ap=1,rap=1,hit=30,crit=28},
        },
        TREE_3 = {
            QUEST = {agi=2.2,str=1,int=1,sta=.7,ap=1,rap=.8,hit=18,crit=18,wdps=8},
            PVP = {agi=2.4,str=.8,int=1.1,sta=1.8,ap=1,rap=.9,hit=16,crit=26,wdps=11},
            RAID = {agi=2.5,str=1,int=1,ap=1,rap=.8,hit=28,crit=26,wdps=14},
        },
    },
    MAGE = {
        TREE_1 = {
            QUEST = {sp=1,int=.9,spi=.5,sta=.4,hit=10,crit=9,mp5=1.2},
            PVP = {sp=1,int=1,sta=1.3,hit=10,crit=14},
            RAID = {sp=1,int=.9,spi=.4,hit=16,crit=12,mp5=1},
        },
        TREE_2 = {
            QUEST = {sp=1,int=.7,spi=.4,sta=.4,hit=10,crit=11,mp5=1},
            PVP = {sp=1,int=.7,sta=1.3,hit=10,crit=16},
            RAID = {sp=1,int=.5,spi=.2,hit=17,crit=15},
        },
        TREE_3 = {
            QUEST = {sp=1,int=.8,spi=.5,sta=.5,hit=9,crit=9,mp5=1.1},
            PVP = {sp=1,int=.8,sta=1.4,hit=10,crit=14},
            RAID = {sp=1,int=.5,spi=.2,hit=16,crit=12},
        },
    },
    WARLOCK = {
        TREE_1 = {
            QUEST = {sp=1,sta=.7,int=.5,spi=.4,hit=10,crit=8},
            PVP = {sp=1,sta=1.6,int=.6,hit=10,crit=12},
            RAID = {sp=1,sta=.1,int=.4,hit=17,crit=12},
        },
        TREE_2 = {
            QUEST = {sp=1,sta=.8,int=.6,spi=.4,hit=10,crit=9},
            PVP = {sp=1,sta=1.7,int=.6,hit=10,crit=13},
            RAID = {sp=1,sta=.2,int=.5,hit=16,crit=12},
        },
        TREE_3 = {
            QUEST = {sp=1,sta=.6,int=.6,spi=.3,hit=10,crit=11},
            PVP = {sp=1,sta=1.5,int=.6,hit=10,crit=16},
            RAID = {sp=1,sta=.1,int=.4,hit=17,crit=15},
        },
    },
    PRIEST = {
        TREE_1 = {
            QUEST = {sp=.9,hp=.7,int=.8,spi=.8,sta=.5,hit=8,crit=8,mp5=1.5},
            PVP = {hp=1,sp=.6,sta=1.6,int=.9,spi=.6,crit=10,mp5=2},
            RAID = {hp=1,int=.8,spi=.8,crit=9,mp5=2.2},
        },
        TREE_2 = {
            QUEST = {hp=.8,sp=.8,int=.8,spi=.9,sta=.5,crit=8,mp5=1.5},
            PVP = {hp=1,sta=1.5,int=.8,spi=.7,crit=10,mp5=2},
            RAID = {hp=1,int=.7,spi=.9,crit=9,mp5=2.4},
        },
        TREE_3 = {
            QUEST = {sp=1,spi=.7,int=.6,sta=.6,hit=10,crit=9,mp5=1},
            PVP = {sp=1,sta=1.6,int=.7,spi=.4,hit=10,crit=13},
            RAID = {sp=1,int=.5,spi=.4,hit=17,crit=13,mp5=1.2},
        },
    },
    DRUID = {
        TREE_1 = {
            QUEST = {sp=1,int=.8,spi=.6,sta=.5,hit=10,crit=10,mp5=1.2},
            PVP = {sp=1,sta=1.5,int=.8,spi=.4,hit=10,crit=15,armor=.08},
            RAID = {sp=1,int=.6,spi=.4,hit=17,crit=14,mp5=1},
        },
        FERAL_CAT = {
            QUEST = {str=2,agi=2.1,sta=.6,ap=1,hit=18,crit=18,wdps=9},
            PVP = {str=2,agi=2.2,sta=1.6,ap=1,hit=15,crit=24,wdps=14},
            RAID = {str=2.2,agi=2.3,ap=1,hit=28,crit=26,wdps=15},
        },
        FERAL_BEAR = {
            QUEST = {sta=1,agi=.9,str=.8,ap=.4,hit=8,crit=8,armor=.12,wdps=5.5},
            PVP = {sta=1.5,agi=1,str=.7,hit=10,crit=10,armor=.18,wdps=7},
            RAID = {sta=1,agi=1.1,str=.6,hit=18,crit=12,def=1.2,dodge=14,armor=.16,wdps=6},
        },
        TREE_3 = {
            QUEST = {hp=.9,sp=.6,int=.8,spi=.9,sta=.5,crit=8,mp5=1.5},
            PVP = {hp=1,sta=1.6,int=.8,spi=.7,crit=11,mp5=2,armor=.08},
            RAID = {hp=1,int=.7,spi=.9,crit=11,mp5=2.3},
        },
    },
    PALADIN = {
        TREE_1 = {
            QUEST = {hp=.9,sp=.6,int=.9,spi=.5,sta=.5,crit=10,mp5=1.6},
            PVP = {hp=1,sta=1.6,int=1,crit=14,mp5=2,armor=.08},
            RAID = {hp=1,int=.9,spi=.4,crit=13,mp5=2.4},
        },
        TREE_2 = {
            QUEST = {sta=1,str=.7,int=.6,sp=.6,hit=8,def=1,armor=.08},
            PVP = {sta=1.5,sp=.8,int=.7,hit=10,crit=10,armor=.14},
            RAID = {sta=1,sp=.8,int=.5,str=.5,hit=18,def=1.8,dodge=13,parry=13,armor=.12},
        },
        TREE_3 = {
            QUEST = {str=2,int=1.2,agi=1,sta=.7,ap=1,sp=.8,hit=18,crit=18,wdps=9},
            PVP = {str=2.1,int=1.2,agi=1.1,sta=1.8,ap=1,sp=.9,hit=16,crit=25,wdps=14},
            RAID = {str=2.2,int=1.3,agi=1.2,ap=1,sp=1,hit=28,crit=26,wskill=18,wdps=15},
        },
    },
    SHAMAN = {
        TREE_1 = {
            QUEST = {sp=1,int=.8,spi=.5,sta=.6,hit=10,crit=11,mp5=1.2},
            PVP = {sp=1,sta=1.6,int=.8,hit=10,crit=16,armor=.08},
            RAID = {sp=1,int=.6,spi=.3,hit=17,crit=15,mp5=1},
        },
        TREE_2 = {
            QUEST = {str=2,int=1.3,agi=1.2,sta=.7,ap=1,sp=.7,hit=18,crit=18,wdps=9},
            PVP = {str=2.1,int=1.2,agi=1.3,sta=1.8,ap=1,sp=.8,hit=16,crit=26,wdps=14},
            RAID = {str=2.2,int=1.4,agi=1.4,ap=1,sp=.9,hit=30,crit=26,wskill=18,wdps=16},
        },
        TREE_3 = {
            QUEST = {hp=.9,sp=.6,int=.8,spi=.6,sta=.5,crit=9,mp5=1.7},
            PVP = {hp=1,sta=1.6,int=.8,crit=11,mp5=2.2,armor=.08},
            RAID = {hp=1,int=.7,spi=.5,crit=10,mp5=2.6},
        },
    },
}

local additional = {
    WARRIOR = {
        TREE_1 = { exp={12,10,24} }, TREE_2 = { exp={14,10,28} },
        TREE_3 = { exp={8,0,22}, block={0,0,10}, bv={0,.6,.5} },
    },
    ROGUE = {
        TREE_1 = { exp={14,8,26} }, TREE_2 = { exp={15,8,28} },
        TREE_3 = { exp={12,6,26} },
    },
    HUNTER = {
        TREE_1 = { rdps={9,13,16} }, TREE_2 = { rdps={10,14,17} },
        TREE_3 = { rdps={7,11,12}, exp={0,0,20} },
    },
    MAGE = {
        TREE_1 = { haste={8,10,12} }, TREE_2 = { haste={8,10,12} },
        TREE_3 = { haste={8,11,12} },
    },
    WARLOCK = {
        TREE_1 = { haste={8,10,13} }, TREE_2 = { haste={8,9,11} },
        TREE_3 = { haste={8,10,12} },
    },
    PRIEST = {
        TREE_1 = { haste={0,0,9} }, TREE_2 = { haste={0,0,8} },
        TREE_3 = { haste={8,10,12} },
    },
    DRUID = {
        TREE_1 = { haste={8,10,12} }, TREE_3 = { haste={0,0,9} },
        FERAL_CAT = { exp={14,8,26} }, FERAL_BEAR = { exp={8,0,22} },
    },
    PALADIN = {
        TREE_1 = { haste={0,0,8} },
        TREE_2 = { exp={8,0,20}, block={0,0,12}, bv={.5,.6,.7} },
        TREE_3 = { exp={12,0,24} },
    },
    SHAMAN = {
        TREE_1 = { haste={8,10,12} }, TREE_2 = { exp={14,0,26} },
        TREE_3 = { haste={0,0,10} },
    },
}
local contexts = { "QUEST", "PVP", "RAID" }
for classFile, trees in pairs(additional) do
    for treeKey, fields in pairs(trees) do
        for key, values in pairs(fields) do
            for index, context in ipairs(contexts) do
                presets[classFile][treeKey][context][key] = values[index]
            end
        end
    end
end

local keys = {
    str = "Strength", agi = "Agility", sta = "Stamina", int = "Intellect", spi = "Spirit",
    ap = "AttackPower", rap = "RangedAttackPower", sp = "SpellPower", hp = "Healing",
    hit = "Hit", crit = "Crit", haste = "Haste", exp = "Expertise",
    wskill = "WeaponSkill", wdps = "WeaponDPS", rdps = "RangedWeaponDPS",
    mp5 = "ManaRegen", armor = "Armor", def = "Defense", dodge = "Dodge", parry = "Parry",
    block = "Block", bv = "BlockValue",
}
local divisors = { crit = 14, dodge = 12, parry = 15, haste = 10, block = 5 }
for classFile, trees in pairs(presets) do
    for treeKey, contexts in pairs(trees) do
        for contextKey, source in pairs(contexts) do
            local weights = {}
            for key, value in pairs(source) do
                weights[keys[key]] = value / (divisors[key] or 1)
            end
            data.CLASS_TALENT_DEFAULTS[classFile][contextKey][treeKey] = weights
        end
    end
end
