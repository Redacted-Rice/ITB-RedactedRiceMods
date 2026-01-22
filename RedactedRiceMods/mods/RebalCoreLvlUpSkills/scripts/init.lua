local mod = {
	id = "redactedrice_RebalCorePlus",
	name = "Rebalanced Core Lvl Up Skills",
	description = "Rebalances the core (none AE) level up skills to be more inline with AE skills",
	icon = "mod_icon.png",
	version = "1.0.0",
	modApiVersion = "2.9.4",
	gameVersion = "1.2.93",
	dependencies = {
        redactedrice_memhack = "0.5.0", -- TBD
        redactedrice_cplus_plus = "0.5.0", -- TBD
    },
	cplusCategory = "RrVanillaPlus",
	-- TODO: Align description with vanilla texts
	HealthPlus = {id = "HealthPlus", shortName = "Health+", fullName = "Pilot_HealthName",
			description = "Increase Health by 3.",
			bonuses = {health = 3}, saveVal = 0, reusability = cplus_plus_ex.REUSABLILITY.REUSABLE
	},
	MovePlus = {id = "MovePlus", shortName = "Move+", fullName = "Pilot_MoveName",
			description = "Increase Move by 1 and Grid DEF by 4.",
			bonuses = {move = 1, grid = 4}, saveVal = 1, reusability = cplus_plus_ex.REUSABLILITY.REUSABLE
	},
	GridPlus = {id = "GridPlus", shortName = "Grid DEF+", fullName = "Pilot_GridName",
			description = "Grid Defense increased by 8",
			bonuses = {grid = 8}, saveVal = 2, reusability = cplus_plus_ex.REUSABLILITY.REUSABLE
	},
}

function mod:init()
	-- register on init
	cplus_plus_ex:registerSkill(self.cplusCategory, self.HealthPlus)
	cplus_plus_ex:registerSkill(self.cplusCategory, self.MovePlus)
	cplus_plus_ex:registerSkill(self.cplusCategory, self.GridPlus)
end

function mod:load(options, version)
	-- Do config changes on load
	cplus_plus_ex:disableSkill("Health")
	cplus_plus_ex:disableSkill("Move")
	cplus_plus_ex:disableSkill("Grid")
end

return mod