local mod = {
	id = "redactedrice_vanillaplus",
	name = "AE Rebalance Base Skills",
	icon = "mod_icon.png",
	version = "1.0.0",
	modApiVersion = "2.9.4",
	gameVersion = "1.2.93",
	dependencies = {
        redactedrice_memhack = "0.5.0", -- TBD
        redactedrice_cplus_plus = "0.5.0", -- TBD
    },
	cplusCategory = "RrVanillaPlus",
	HealthPlus = {id = "HealthPlus", shortName = "Health+", fullName = "Pilot_HealthName",
			description = "Increase Health by 3.",
			bonuses = {health = 3}, saveVal = 0, reusability = "reusable"
	},
	MovePlus = {id = "MovePlus", shortName = "Move+", fullName = "Pilot_MoveName",
			description = "Increase Move by 1 and Grid DEF by 4.",
			bonuses = {move = 1, grid = 4}, saveVal = 0, reusability = "reusable"
	},
	GridPlus = {id = "GridPlus", shortName = "Grid DEF+", fullName = "Pilot_GridName",
			description = "Grid Defense increased by 8",
			bonuses = {grid = 8}, saveVal = 2, reusability = "reusable"
	},
}

function mod:init()
	cplus_plus_ex.plus_manager:registerSkill(self.cplusCategory, self.GridPlus)
end

function mod:load(options, version)
	-- Replace vanilla skills with slighlty better ones
	cplus_plus_ex.plus_manager:disableSkill("Health")
	cplus_plus_ex.plus_manager:disableSkill("Move")
	cplus_plus_ex.plus_manager:disableSkill("Grid")

	cplus_plus_ex.plus_manager:enableCategory(self.cplusCategory)
end

return mod