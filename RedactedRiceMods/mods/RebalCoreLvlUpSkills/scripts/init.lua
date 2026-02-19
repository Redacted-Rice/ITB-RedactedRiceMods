local mod = {
	id = "redactedrice_RebalCorePlus",
	name = "Rebalanced Core Lvl Up Skills",
	icon = "mod_icon.png",
	version = "1.0.0",
	modApiVersion = "2.9.4",
	gameVersion = "1.2.93",
	dependencies = {
        redactedrice_cplus_plus = "0.9.0",
    }
}

function mod:init(options)
	gridDef = options["rr_vplus_grid"].value
	local halfRounded = math.floor(gridDef / 2.0)

	-- use the set text approach so other can override these if they want to for some reason
	-- such as localization
	modApi:setText("RebalCorePlus_HealthPlus_ShortName", "Health+")
	modApi:setText("RebalCorePlus_HealthPlus_FullName", "Health +3")
	modApi:setText("RebalCorePlus_HealthPlus_Description", "Piloted Mech health is increased by 3.")

	modApi:setText("RebalCorePlus_MovePlus_ShortName", "Move+")
	modApi:setText("RebalCorePlus_MovePlus_FullName", "Move +1, Grid DEF +"..halfRounded)
	modApi:setText("RebalCorePlus_MovePlus_Description", "Piloted Mech movement is increased by 1 and Grid Defense increased by "..halfRounded..".")

	modApi:setText("RebalCorePlus_GridPlus_ShortName", "Grid DEF+")
	modApi:setText("RebalCorePlus_GridPlus_FullName", "Grid DEF +"..gridDef)
	modApi:setText("RebalCorePlus_GridPlus_Description", "Grid Defense increased by "..gridDef..".")

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
		bonuses = {move = 1, grid = halfRounded},
		saveVal = 1,
		reusability = cplus_plus_ex.REUSABLILITY.REUSABLE
	}

	local gridPlus = {
		id = "GridPlus",
		shortName = "RebalCorePlus_GridPlus_ShortName",
		fullName = "RebalCorePlus_GridPlus_FullName",
		description = "RebalCorePlus_GridPlus_Description",
		bonuses = {grid = gridDef},
		saveVal = 2,
		reusability = cplus_plus_ex.REUSABLILITY.REUSABLE
	}

	-- register on init
	cplus_plus_ex:registerSkill(cplusCategory, healthPlus)
	cplus_plus_ex:registerSkill(cplusCategory, movePlus)
	cplus_plus_ex:registerSkill(cplusCategory, gridPlus)

	-- Respect the vanilla health exclusions
	cplus_plus_ex:registerPilotSkillExclusions("Pilot_Rock", healthPlus.id)
	cplus_plus_ex:registerPilotSkillExclusions("Pilot_Zoltan", healthPlus.id)
end

function mod:load(options, version)
	-- Do config changes on load
	cplus_plus_ex:disableSkill("Health")
	cplus_plus_ex:disableSkill("Move")
	cplus_plus_ex:disableSkill("Grid")

end

function mod:metadata()
	local option_values = {
		gridDef = {4, 5, 6, 7, 8, 9, 10, 11, 12},
	}

	modApi:addGenerationOption(
		"rr_vplus_grid", "Grid+ Increase Amount",
		"Changes the Grid DEF % increas for the Grid+ skill and the Move+ skill. Grid DEF will use this value. Move+ will use this value / 2 (round down).\nREQUIRES RESTART TO TAKE EFFECT!",
		{
			values = option_values.gridDef,
			value = 8
		}
	)
end

return mod