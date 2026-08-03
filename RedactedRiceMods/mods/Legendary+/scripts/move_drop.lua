legendary_plus.moveDrop = legendary_plus.moveDrop or {}

local moveDrop = legendary_plus.moveDrop

moveDrop.DEBUG = legendary_plus.DEBUG
local logger = memhack.logger
local SUBMODULE = logger.register("Legendary+", "MoveDrop", moveDrop.DEBUG)

local MARKER_COLOR = GL_Color(255, 226, 88, 0.75)

local function initGameSaveData()
	GAME = GAME or {}
	GAME.legendary_plus = GAME.legendary_plus or {}
	GAME.legendary_plus.move_drop = GAME.legendary_plus.move_drop or {}
	GAME.legendary_plus.move_drop.pending = GAME.legendary_plus.move_drop.pending or {}
end

function moveDrop:markSpace(loc, markerIcon, markerTooltip)
	Board:MarkSpaceImage(loc, markerIcon, MARKER_COLOR)
	Board:MarkSpaceDesc(loc, markerTooltip)
end

function moveDrop:unmarkSpace(loc)
	if Board and Board:IsValid(loc) then
		Board:ClearSpace(loc)
	end
end

function moveDrop:clearPendingForPawn(pawnId)
	initGameSaveData()
	local pending = GAME.legendary_plus.move_drop.pending[pawnId]
	if not pending then
		return
	end

	self:unmarkSpace(pending.loc)
	GAME.legendary_plus.move_drop.pending[pawnId] = nil
	logger.logDebug(SUBMODULE, "Cleared pending drop for pawn %d at %s", pawnId, pending.loc:GetString())
end

function moveDrop:queueDrop(pawnId, loc, itemId, markerIcon, markerTooltip)
	initGameSaveData()
	self:clearPendingForPawn(pawnId)

	GAME.legendary_plus.move_drop.pending[pawnId] = {
		loc = loc,
		itemId = itemId,
	}

	self:markSpace(loc, markerIcon, markerTooltip)
	logger.logDebug(SUBMODULE, "Queued %s at %s for pawn %d", itemId, loc:GetString(), pawnId)
end

function moveDrop:undoPending(pawnId)
	self:clearPendingForPawn(pawnId)
end

function moveDrop:placePendingDrops()
	if not Board then
		return
	end

	initGameSaveData()
	local pending = GAME.legendary_plus.move_drop.pending

	for pawnId, data in pairs(pending) do
		self:unmarkSpace(data.loc)
		if legendary_plus.canPlaceMoveDrop(data.loc) then
			Board:SetItem(data.loc, data.itemId)
			logger.logDebug(SUBMODULE, "Placed %s at %s for pawn %d",
					data.itemId, data.loc:GetString(), pawnId)
		else
			logger.logDebug(SUBMODULE, "Skipped %s at %s for pawn %d (space no longer valid)",
					data.itemId, data.loc:GetString(), pawnId)
		end
	end

	GAME.legendary_plus.move_drop.pending = {}
end

function moveDrop:reset()
	initGameSaveData()
	if Board then
		for _, data in pairs(GAME.legendary_plus.move_drop.pending) do
			self:unmarkSpace(data.loc)
		end
	end
	GAME.legendary_plus.move_drop.pending = {}
	logger.logDebug(SUBMODULE, "Reset pending move drops")
end

function moveDrop:handleMove(pawn, origin, dest, skillEffect, config)
	if not origin or not dest or origin == dest then
		return false
	end

	if not legendary_plus.canPlaceMoveDrop(origin) then
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
	modApi.events.onNextTurn:subscribe(function()
		if Game:GetTeamTurn() == TEAM_ENEMY then
			self:placePendingDrops()
		end
	end)
	modapiext.events.onResetTurn:subscribe(function()
		self:reset()
	end)
end

return moveDrop
