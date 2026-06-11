local this = {}
local mod = mod_loader.mods[modApi.currentMod]
local scriptPath = mod.scriptPath
local pilotPath = scriptPath .. "pilots/"

-- List of available pilots
local pilotnames = {
	["Pilot_Warbot"] = "Warbot",
	["Pilot_Sgt_Drake"] = "Sgt. Drake",
	["Pilot_Instructor_Hale"] = "Instructor Hale",
}

function this:init()
	-- Initialize each pilot
	for id, name in pairs(pilotnames) do
		self[id] = require(pilotPath .. string.lower(id))
		self[id]:init(mod)
	end
end

function this:load(options, version)
	-- Load each pilot's custom load function if it exists
	for id, name in pairs(pilotnames) do
		if self[id] and self[id]["load"] ~= nil then
			self[id]:load(options, version)
		end
	end
end

return this
