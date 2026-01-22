local mod = {
	id = "redactedrice_RebalCorePlus",
	name = "Rebalanced Core Lvl Up Skills",
	icon = "mod_icon.png",
	version = "1.0.0",
	modApiVersion = "2.9.4",
	gameVersion = "1.2.93",
	dependencies = {
        redactedrice_memhack = "0.1.0", -- TBD
        redactedrice_cplus_plus = "0.1.0", -- TBD
    }
}

function mod:init()
	local cplusCategory = "RrVanillaPlus"
	-- TODO: Align description with vanilla texts
	local healthPlus = {id = "HealthPlus", shortName = "Health+", fullName = "Pilot_HealthName",
			description = "Increase Health by 3.",
			bonuses = {health = 3}, saveVal = 0, reusability = cplus_plus_ex.REUSABLILITY.REUSABLE
	}
	local movePlus = {id = "MovePlus", shortName = "Move+", fullName = "Pilot_MoveName",
			description = "Increase Move by 1 and Grid DEF by 4.",
			bonuses = {move = 1, grid = 4}, saveVal = 1, reusability = cplus_plus_ex.REUSABLILITY.REUSABLE
	}
	local gridPlus = {id = "GridPlus", shortName = "Grid DEF+", fullName = "Pilot_GridName",
			description = "Grid Defense increased by 8",
			bonuses = {grid = 8}, saveVal = 2, reusability = cplus_plus_ex.REUSABLILITY.REUSABLE
	}
	
	-- register on init
	cplus_plus_ex:registerSkill(cplusCategory, healthPlus)
	cplus_plus_ex:registerSkill(cplusCategory, movePlus)
	cplus_plus_ex:registerSkill(cplusCategory, gridPlus)
	
	-- Respect the vanilla health exclusions
	cplus_plus_ex:registerPilotSkillExclusions("Pilot_Rock", healthPlus)
	cplus_plus_ex:registerPilotSkillExclusions("Pilot_Zoltan", healthPlus)
end

function mod:load(options, version)
	-- Do config changes on load
	cplus_plus_ex:disableSkill("Health")
	cplus_plus_ex:disableSkill("Move")
	cplus_plus_ex:disableSkill("Grid")
	
end

return mod