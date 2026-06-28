-- Pilots+ Mod
-- Test mod for CPLUS+ virtual skills system
-- Contains pilots with more than 2 level-up skills using virtual skills

local mod = {
	id = "redactedrice_Pilots+",
	name = "Pilots+",
	version = "1.0.0",
	modApiVersion = "2.9.5",
	gameVersion = "1.2.93",
	icon = "mod_icon.png",
	dependencies = {
		redactedrice_cplus_plus = "1.2.0",
		redactedrice_memhack = "1.2.0",
	}
}

function mod:metadata()
end

function mod:init()
	LOG("Pilots+ initializing...")
	LOG("CPLUS+ Extension found - virtual skills enabled")

	-- Load all pilot portrait images from the portraits/pilots directory
	modApi:appendAssets("img/portraits/pilots/", "img/portraits/pilots/")

	-- Pilots
	local pilots = require(self.scriptPath .. "pilots/init")
	pilots:init()
	self.pilots = pilots

	LOG("Pilots+ initialized successfully")
end

function mod:load(options, version)
	-- Load pilots
	self.pilots:load(options, version)
end

return mod
