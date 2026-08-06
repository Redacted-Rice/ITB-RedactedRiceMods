legendary_plus.moveDrop = legendary_plus.moveDrop or {}

local moveDrop = legendary_plus.moveDrop

moveDrop.DEBUG = legendary_plus.DEBUG
local logger = memhack.logger
local SUBMODULE = logger.register("Legendary+", "MoveDrop", moveDrop.DEBUG)

local MARKER_COLOR = GL_Color(220, 220, 220, 0.25)

local function initGameSaveData()
	GAME = GAME or {}
	GAME.legendary_plus = GAME.legendary_plus or {}
	GAME.legendary_plus.move_drop = GAME.legendary_plus.move_drop or {}
	GAME.legendary_plus.move_drop.pending = GAME.legendary_plus.move_drop.pending or {}
end

-- Terrain/building checks only. Ignore pawns so move origin can be marked while
-- the moving mech is still standing on it.
function moveDrop:canMarkDropTile(loc)
	if not Board:IsValid(loc)
			or Board:IsItem(loc)
			or Board:IsBuilding(loc)
			or Board:IsPod(loc) then
		return false
	end

	local terrain = Board:GetTerrain(loc)
	if terrain == TERRAIN_HOLE or terrain == TERRAIN_WATER
			or terrain == TERRAIN_LAVA or terrain == TERRAIN_ACID
			or terrain == TERRAIN_MOUNTAIN then
		return false
	end

	return true
end

function moveDrop:markSpace(loc, markerIcon, markerTooltip)
	if not Board or not Board:IsValid(loc) then
		return
	end
	Board:MarkSpaceImage(loc, markerIcon, MARKER_COLOR)
	Board:MarkSpaceDesc(loc, markerTooltip)
end

-- MarkSpaceImage needs to be applied each mission update.
function moveDrop:remarkPending()
	if not Board then
		return
	end

	initGameSaveData()
	for _, data in pairs(GAME.legendary_plus.move_drop.pending) do
		self:markSpace(data.loc, data.markerIcon, data.markerTooltip)
	end
end

function moveDrop:clearPendingForPawn(pawnId)
	initGameSaveData()
	local pending = GAME.legendary_plus.move_drop.pending[pawnId]
	if not pending then
		return
	end

	GAME.legendary_plus.move_drop.pending[pawnId] = nil
	logger.logDebug(SUBMODULE, "Cleared pending drop for pawn %d at %s", pawnId, pending.loc:GetString())
end

function moveDrop:queueDrop(pawnId, loc, itemId, markerIcon, markerTooltip)
	initGameSaveData()
	self:clearPendingForPawn(pawnId)

	GAME.legendary_plus.move_drop.pending[pawnId] = {
		loc = loc,
		itemId = itemId,
		markerIcon = markerIcon,
		markerTooltip = markerTooltip,
	}

	self:markSpace(loc, markerIcon, markerTooltip)
	logger.logDebug(SUBMODULE, "Queued %s at %s for pawn %d", itemId, loc:GetString(), pawnId)
end

function moveDrop:undoPending(pawnId)
	self:clearPendingForPawn(pawnId)
end

-- Whether a tile can receive a move origin item drop at end of turn.
function moveDrop:canPlaceMoveDrop(loc)
	if not Board:IsValid(loc)
			or Board:IsItem(loc)
			or Board:IsPod(loc)
			or Board:IsCracked(loc) then
		return false
	end

	local terrain = Board:GetTerrain(loc)
	if terrain == TERRAIN_HOLE or terrain == TERRAIN_WATER
			or terrain == TERRAIN_LAVA or terrain == TERRAIN_ACID
			or terrain == TERRAIN_MOUNTAIN or terrain == TERRAIN_BUILDING then
		return false
	end

	return true
end

function moveDrop:placePendingDrops()
	if not Board then
		return
	end

	initGameSaveData()
	local pending = GAME.legendary_plus.move_drop.pending
	local effect = SkillEffect()
	local any = false

	for pawnId, data in pairs(pending) do
		if self:canPlaceMoveDrop(data.loc) then
			local damage = SpaceDamage(data.loc, 0)
			damage.sItem = data.itemId
			effect:AddDamage(damage)
			any = true
			logger.logDebug(SUBMODULE, "Placing %s at %s for pawn %d",
					data.itemId, data.loc:GetString(), pawnId)
		else
			logger.logDebug(SUBMODULE, "Skipped %s at %s for pawn %d (space no longer valid)",
					data.itemId, data.loc:GetString(), pawnId)
		end
	end

	GAME.legendary_plus.move_drop.pending = {}

	if any then
		Board:AddEffect(effect)
	end
end

function moveDrop:reset()
	initGameSaveData()
	GAME.legendary_plus.move_drop.pending = {}
	logger.logDebug(SUBMODULE, "Reset pending move drops")
end

function moveDrop:handleMove(pawn, origin, dest, skillEffect, config)
	if not origin or not dest or origin == dest then
		return false
	end

	if not self:canMarkDropTile(origin) then
		logger.logDebug(SUBMODULE, "Cannot mark origin %s for pawn %d",
				origin:GetString(), pawn:GetId())
		return false
	end

	local pawnId = pawn:GetId()
	local markDamage = SpaceDamage(origin, 0)
	markDamage.sScript = string.format([[
		legendary_plus.moveDrop:queueDrop(%d, %s, %q, %q, %q)
	]], pawnId, origin:GetString(), config.itemId, config.markerIcon, config.markerTooltip)
	skillEffect:AddDamage(markDamage)
	logger.logDebug(SUBMODULE, "Will mark origin %s for pawn %d (%s)",
			origin:GetString(), pawnId, config.itemId)
	return true
end

function moveDrop:setupSkillEffect(customSkill, config)
	table.insert(customSkill.events, modapiext.events.onSkillBuild:subscribe(function(mission, pawn, weaponId, p1, p2, skillEffect)
		if weaponId ~= "Move" then
			return
		end

		local pilot = pawn:GetPilot()
		if not pilot or not cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) then
			return
		end

		moveDrop:handleMove(pawn, p1, p2, skillEffect, config)
	end))

	table.insert(customSkill.events, modapiext.events.onPawnUndoMove:subscribe(function(mission, pawn)
		local pilot = pawn:GetPilot()
		if not pilot or not cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) then
			return
		end
		moveDrop:undoPending(pawn:GetId())
	end))
end

function moveDrop:init()
	if self.initialized then
		return
	end
	self.initialized = true

	modApi.events.onMissionStart:subscribe(function()
		self:reset()
	end)
	modApi.events.onMissionNextPhaseCreated:subscribe(function()
		self:reset()
	end)
	modApi.events.onMissionEnd:subscribe(function()
		self:reset()
	end)
	-- Place after players end their turn - NextTurn is fired after queued attacks
	modApi.events.onPostEnvironment:subscribe(function()
		self:placePendingDrops()
	end)
	modapiext.events.onResetTurn:subscribe(function()
		self:reset()
	end)
	-- Env-style marks must be reapplied every frame
	modApi.events.onMissionUpdate:subscribe(function()
		self:remarkPending()
	end)
end

return moveDrop
