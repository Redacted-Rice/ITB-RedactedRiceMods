-- Pilots+ Mod
-- Test mod for CPLUS+ virtual skills system
-- Contains pilots with more than 2 level-up skills using virtual skills

local mod = {
	id = "PilotsPlus",
	name = "Pilots+",
	version = "1.0.0",
	modApiVersion = "2.9.5",
	gameVersion = "1.2.93",
	icon = "img/icon.png",
	dependencies = {
		redactedrice_cplus_plus = "1.2.0",
		redactedrice_memhack = "1.1.0",
	}
}

function mod:metadata()
end

function mod:init()
	LOG("Pilots+ initializing...")
	LOG("CPLUS+ Extension found - virtual skills enabled")

	-- Get mod paths
	local scriptPath = self.scriptPath
	local resourcePath = self.resourcePath

	-- Load and initialize Warbot pilot
	local pilot_warbot = require(scriptPath .. "pilots/pilot_warbot")
	pilot_warbot:init(self)

	LOG("Pilots+ initialized successfully")
end

function mod:load(options, version)
	LOG("Pilots+ loading...")

	-- Load pilot hooks
	local scriptPath = self.scriptPath
	local pilot_warbot = require(scriptPath .. "pilots/pilot_warbot")
	pilot_warbot:load(options, version)

	LOG("Pilots+ loaded successfully")
end

return mod
