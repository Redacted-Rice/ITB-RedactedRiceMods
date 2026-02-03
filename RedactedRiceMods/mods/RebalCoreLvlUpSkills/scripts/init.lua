local mod = {
	id = "redactedrice_RebalCorePlus",
	name = "Rebalanced Core Lvl Up Skills",
	icon = "mod_icon.png",
	version = "1.0.0",
	modApiVersion = "2.9.4",
	gameVersion = "1.2.93",
	dependencies = {
        redactedrice_cplus_plus = "0.7.0",
    }
}

function mod:init()
	-- use the set text approach so other can override these if they want to for some reason
	-- such as localization
	modApi:setText("RebalCorePlus_HealthPlus_ShortName", "Health+")
	modApi:setText("RebalCorePlus_HealthPlus_FullName", "Health +3")
	modApi:setText("RebalCorePlus_HealthPlus_Description", "Increase Health by 3.")

	modApi:setText("RebalCorePlus_MovePlus_ShortName", "Move+")
	modApi:setText("RebalCorePlus_MovePlus_FullName", "Move +1, Grid DEF +4")
	modApi:setText("RebalCorePlus_MovePlus_Description", "Increase Move by 1 and Grid DEF by 4.")

	modApi:setText("RebalCorePlus_GridPlus_ShortName", "Grid DEF+")
	modApi:setText("RebalCorePlus_GridPlus_FullName", "Grid DEF +8")
	modApi:setText("RebalCorePlus_GridPlus_Description", "Grid Defense increased by 8")

	local cplusCategory = "Vanilla+"

	local healthPlus = {
		id = "HealthPlus",
		shortName = "RebalCorePlus_HealthPlus_ShortName",
		fullName = "RebalCorePlus_HealthPlus_FullName",
		description = "RebalCorePlus_HealthPlus_Description",
		bonuses = {health = 3},
		saveVal = 0,
		reusability = cplus_plus_ex.REUSABLILITY.REUSABLE
	}

	local movePlus = {
		id = "MovePlus",
		shortName = "RebalCorePlus_MovePlus_ShortName",
		fullName = "RebalCorePlus_MovePlus_FullName",
		description = "RebalCorePlus_MovePlus_Description",
		bonuses = {move = 1, grid = 4},
		saveVal = 1,
		reusability = cplus_plus_ex.REUSABLILITY.REUSABLE
	}

	local gridPlus = {
		id = "GridPlus",
		shortName = "RebalCorePlus_GridPlus_ShortName",
		fullName = "RebalCorePlus_GridPlus_FullName",
		description = "RebalCorePlus_GridPlus_Description",
		bonuses = {grid = 8},
		saveVal = 2,
		reusability = cplus_plus_ex.REUSABLILITY.REUSABLE
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