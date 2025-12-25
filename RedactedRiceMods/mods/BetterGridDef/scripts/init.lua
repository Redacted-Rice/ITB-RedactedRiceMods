local mod = {
	id = "redactedrice_bettergriddef",
	name = "+3 -> +8 Grid Def",
	icon = "mod_icon.png",
	version = "0.1.0",
	modApiVersion = "2.9.4",
	gameVersion = "1.2.93",
	dependencies = {
        redactedrice_memhack = "0.1.0",
        redactedrice_cplus_plus = "0.1.0",
    },
}

function mod:init()
	cplus_plus_ex.plus_manager:registerSkill("RrBetterGrid", "BetterGrid", "+8 Grid Def", "+8 Grid Def", "Increase grid defence by 8%", {grid = 8}, skillType, saveVal = 2)
end

function mod:load(options, version)
	-- Replace grid with better grid
	cplus_plus_ex.plus_manager:disableSkill("Grid")
	cplus_plus_ex.plus_manager:enableCategory("RrBetterGrid")
end

return mod