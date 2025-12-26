local mod = {
	id = "redactedrice_bettergriddef",
	name = "+3 -> +8 Grid DEF",
	icon = "mod_icon.png",
	version = "0.1.0",
	modApiVersion = "2.9.4",
	gameVersion = "1.2.93",
	dependencies = {
        redactedrice_memhack = "0.1.0",
        redactedrice_cplus_plus = "0.1.0",
    },
	cplusCategory = "RrBetterGrid",
	betterGrid = {id = "BetterGrid", shortName = "+8 Grid DEF", fullName = "Pilot_GridName", description = "Grid Defense increased by 8. This affects the chance of resisting Building Damage in combat.", bonuses = {grid = 100}, saveVal = 2 },
}

function mod:init()
	cplus_plus_ex.plus_manager:registerSkill(self.cplusCategory, self.betterGrid)
end

function mod:load(options, version)
	-- Replace grid with better grid
	cplus_plus_ex.plus_manager:disableSkill("Grid")
	-- Just enable by category even though we have only one
	cplus_plus_ex.plus_manager:enableCategory(self.cplusCategory)
end

return mod