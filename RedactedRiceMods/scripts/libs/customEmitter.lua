
---------------------------------------------------------------------
-- Custom Emitter v1.0 - code library
---------------------------------------------------------------------
-- preliminary library for adding emitters that can be stopped at will.
-- possibly unfinished.

-- TODO: remove function continue because that cannot be stores in save file as it is.
-- mission Geyser is using it, so that mission needs to be redone first.

local mod = modApi:getCurrentMod()
local path = mod.resourcePath
local spaceDamageObjects = require(path .."scripts/libs/spaceDamageObjects")
local suffix = "_lmn_"
local this = {}

-- add an emitter to a location or a pawnId.
-- continually creates the emitter after it's timer is over,
-- until it is removed by Rem or pawn cannot be found.
function this:Add(mission, loc, emitter, desc, continue)
	mission = mission or GetCurrentMission()
	if not mission then return end

	assert(type(emitter) == 'string')
	assert(_G[emitter])
	assert(not continue or type(continue) == 'function')

	if _G[emitter].timer < 0 then return end

	if type(loc) == 'number' then
		-- attach emitter to pawnId
		local pawnId = loc
		mission.lmn_pawnEmitters = mission.lmn_pawnEmitters or {}
		mission.lmn_pawnEmitters[pawnId] = mission.lmn_pawnEmitters[pawnId] or {}
		mission.lmn_pawnEmitters[pawnId][emitter] = {
			t = os.clock(),
			title = desc and desc[1] or nil,
			desc = desc and desc[2] or nil,
			continue = continue
		}
	else
		-- add emitter to location
		assert(type(loc) == 'userdata')
		assert(type(loc.x) == 'number')
		assert(type(loc.y) == 'number')

		local pid = p2idx(loc)
		mission.lmn_tileEmitters = mission.lmn_tileEmitters or {}
		mission.lmn_tileEmitters[pid] = mission.lmn_tileEmitters[pid] or {}
		mission.lmn_tileEmitters[pid][emitter] = {
			t = os.clock(),
			title = desc and desc[1] or nil,
			desc = desc and desc[2] or nil,
			continue = continue
		}
	end
end

-- remove an emitter from a location or a pawnId
function this:Rem(mission, loc, emitter)
	mission = mission or GetCurrentMission()
	if not mission then return end

	assert(type(emitter) == 'string')
	assert(_G[emitter])

	if type(loc) == 'number' then
		-- rem emitter from pawnId
		local pawnId = loc
		mission.lmn_pawnEmitters = mission.lmn_pawnEmitters or {}
		mission.lmn_pawnEmitters[pawnId] = mission.lmn_pawnEmitters[pawnId] or {}
		mission.lmn_pawnEmitters[pawnId][emitter] = nil
	else
		-- rem emitter from location
		assert(type(loc) == 'userdata')
		assert(type(loc.x) == 'number')
		assert(type(loc.y) == 'number')

		local pid = p2idx(loc)
		mission.lmn_tileEmitters = mission.lmn_tileEmitters or {}
		mission.lmn_tileEmitters[pid] = mission.lmn_tileEmitters[pid] or {}
		mission.lmn_tileEmitters[pid][emitter] = nil
	end
end

local function updateEmitters(loc, emitters, t)
	t = t or os.clock()

	if Board:IsValid(loc) then
		local copy = shallow_copy(emitters)

		for emitter, v in pairs(copy) do
			if t > v.t then
				if not v.started or not v.continue or v.continue(loc, emitter) then
					-- create emitter.
					Board:DamageSpace(spaceDamageObjects.Emitter(loc, emitter))
					-- calculate time for next emitter.
					v.t = v.t + _G[emitter].timer
					v.started = true
				else
					emitters[emitter] = nil
				end
			end
		end
	end
end

local function updateDesc(loc, emitters)
	if Board:IsValid(loc) then
		for emitter, v in pairs(emitters) do
			if v.title and v.desc then

				local tooltipId = "customEmitter".. suffix .. emitter
				if not TILE_TOOLTIPS[tooltipId] then
					TILE_TOOLTIPS[tooltipId] = {v.title, v.desc}
				end

				Board:MarkSpaceDesc(loc, tooltipId)
			end
		end
	end
end

modApi.events.onFrameDrawn:subscribe(function()
	local mission = GetCurrentMission()
	if not mission or not Board then return end

	mission.lmn_pawnEmitters = mission.lmn_pawnEmitters or {}
	mission.lmn_tileEmitters = mission.lmn_tileEmitters or {}

	local t = os.clock()
	local rem = {}

	for pawnId, emitters in pairs(mission.lmn_pawnEmitters) do

		local pawn = Board:GetPawn(pawnId)
		if pawn then
			updateEmitters(pawn:GetSpace(), emitters, t)
		else
			rem[#rem+1] = pawnId
		end
	end

	for pid, emitters in pairs(mission.lmn_tileEmitters) do
		updateEmitters(idx2p(pid), emitters, t)
	end

	for _, id in ipairs(rem) do
		table.remove(mission.lmn_pawnEmitters, id)
	end
end)

modApi.events.onMissionUpdate:subscribe(function(mission)
	mission.lmn_pawnEmitters = mission.lmn_pawnEmitters or {}
	mission.lmn_tileEmitters = mission.lmn_tileEmitters or {}

	for pawnId, emitters in pairs(mission.lmn_pawnEmitters) do
		local pawn = Board:GetPawn(pawnId)
		if pawn then
			updateDesc(pawn:GetSpace(), emitters)
		end
	end

	for pid, emitters in pairs(mission.lmn_tileEmitters) do
		updateDesc(idx2p(pid), emitters)
	end
end)

modApi.events.onPostLoadGame:subscribe(function()
	modApi:runLater(function(mission)
		local t = os.clock()

		mission.lmn_pawnEmitters = mission.lmn_pawnEmitters or {}
		mission.lmn_tileEmitters = mission.lmn_tileEmitters or {}

		for _, emitters in pairs(mission.lmn_pawnEmitters) do
			for _, v in pairs(emitters) do
				v.t = t
			end
		end

		for _, emitters in pairs(mission.lmn_tileEmitters) do
			for _, v in pairs(emitters) do
				v.t = t
			end
		end
	end)
end)

return this