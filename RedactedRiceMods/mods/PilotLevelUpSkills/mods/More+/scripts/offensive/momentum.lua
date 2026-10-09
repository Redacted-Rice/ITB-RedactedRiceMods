local MIN_DISTANCE = 4

local customSkill = cplus_plus_ex.baseClasses.SkillActive:new{
	id = "RrMomentum",
	name = "Momentum",
	description = "Gain boosted after moving at least 4 tiles.",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
	constraints = {
		groups = {PlusHelper.GROUPS.BOOST},
		pilotExclusions = {"Pilot_Arrogant", "Pilot_Chemical"},
	}
}

-- Initialize logger
customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Momentum", customSkill.DEBUG)

more_plus:addCustomTraitIcon(customSkill)

-- Initialize GAME save data structure
local function initGameSaveData()
	if GAME == nil then
		GAME = {}
	end

	if GAME.more_plus == nil then
		GAME.more_plus = {}
	end

	if GAME.more_plus.momentum == nil then
		GAME.more_plus.momentum = {}
	end

	if GAME.more_plus.momentum.boosted_by_effect == nil then
		GAME.more_plus.momentum.boosted_by_effect = {}
	end
end

local function resetBoostTracking()
	logger.logDebug(SUBMODULE, "Resetting boost tracking")
	initGameSaveData()
	GAME.more_plus.momentum.boosted_by_effect = {}
end

function customSkill:setupEffect()
	table.insert(customSkill.events, modapiext.events.onSkillBuild:subscribe(customSkill.checkMove))
	table.insert(customSkill.events, modapiext.events.onPawnUndoMove:subscribe(customSkill.undoBoosted))

	-- Reset tracking on mission start and each turn
	table.insert(customSkill.events, modApi.events.onMissionStart:subscribe(resetBoostTracking))
	table.insert(customSkill.events, modApi.events.onNextTurn:subscribe(resetBoostTracking))
end

function customSkill:momentumTriggered(pawnId, p1, p2, effect, builtEffect)
	local pawn = Board:GetPawn(pawnId)
	local distance = 0
	local pathSource = "unknown"
	local boardUtils = more_plus.libs.boardUtils
	builtEffect = builtEffect or effect

	-- Leap, charge, and teleport use manhattan distance
	if boardUtils.skillEffectUsesPointToPointMovement(builtEffect) then
		distance = math.abs(p2.x - p1.x) + math.abs(p2.y - p1.y)
		pathSource = "manhattan"
	else
		local path = boardUtils.getHijackedPathForMove(pawnId, p1, p2)
		if path then
			pathSource = "hijacked"
		else
			-- Otherwise use vanilla pathfinding (respects flying, burrow, etc.)
			path = Board:GetPath(p1, p2, pawn:GetPathProf())
			pathSource = "calculated"
		end

		if path and path:size() > 0 then
			distance = path:size() - 1
		end
	end

	logger.logDebug(SUBMODULE, "Pawn %d moving %d tiles from %s to %s with source: %s",
		pawn:GetId(), distance, p1:GetString(), p2:GetString(), pathSource)

	if distance >= MIN_DISTANCE and not pawn:IsBoosted() then
		initGameSaveData()
		more_plus.libs.weaponPreview.ExecuteWithState(more_plus.libs.weaponPreview.STATE_SKILL_EFFECT,
			function()
				more_plus.addWeaponPreviewIcon(more_plus.libs.weaponPreview.STATE_SKILL_EFFECT,
						p2, more_plus.commonIcons.boost.key,
						GetText(customSkill.name) .. ": " .. GetText(customSkill.description))
			end, pawnId
		)
		-- Use AddDamage + sScript (not AddScript) so the boost survives movement
		-- skills that replace the move entry, including supporter teleports.
		local boostDamage = SpaceDamage(p2, 0)
		boostDamage.sScript = string.format([[
				GAME.more_plus.momentum.boosted_by_effect[%d] = true
				Board:GetPawn(%d):SetBoosted(true)]], pawnId, pawnId)
		effect:AddDamage(boostDamage)
		logger.logDebug(SUBMODULE, "Will apply boosted to pawn %d moving %d tiles", pawnId, distance)
	end
end

function customSkill.checkMove(mission, pawn, weaponId, p1, p2, skillEffect)
	if weaponId == "Move" then
		local pilot = pawn:GetPilot()
		if pilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) then
			local pawnId = pawn:GetId()
			if customSkill.recalculatingForPawn ~= pawnId then
				logger.logDebug(SUBMODULE, "First calculation pass, will recalculate pathing", pawnId)
				customSkill.recalculatingForPawn = pawnId
				-- Clear stale paths from other pawns, attacks, or prior move previews.
				more_plus.libs.boardUtils.clearHijackedPath()
				-- Recalculate so hijacked paths and skill granted movement are resolved.
				local builtEffect = Move:GetSkillEffect(p1, p2)
				customSkill:momentumTriggered(pawnId, p1, p2, skillEffect, builtEffect)
				customSkill.recalculatingForPawn = nil
			else
				logger.logDebug(SUBMODULE, "Second calculation pass - skipping logic", pawnId)
			end
		end
	end
end

function customSkill.undoBoosted(mission, pawn, undonePosition)
	initGameSaveData()
	local pawnId = pawn:GetId()

	local pilot = pawn:GetPilot()
	if pilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) then
		-- If we added boosted, then remove it
		if GAME.more_plus.momentum.boosted_by_effect[pawnId] then
			logger.logDebug(SUBMODULE, "Pawn %d was not boost before Momentum, removing boost on undo", pawnId)
			pawn:SetBoosted(false)
			GAME.more_plus.momentum.boosted_by_effect[pawnId] = nil
		end
	end
end

return customSkill

