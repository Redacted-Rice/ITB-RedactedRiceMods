local MIN_DISTANCE = 4

local customSkill = cplus_plus_ex.baseClasses.SkillActive:new{
	id = "RrMomentum",
	name = "Momentum",
	description = "Gain boosted after moving at least 4 tiles.",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
	reentrant = false,
	constraints = {
		groups = {more_plus.GROUPS.BOOST},
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
		local path = nil

		-- Check if there's a hijacked path and use it if so
		path = boardUtils.getHijackedPath()
		if path then
			pathSource = "hijacked"
		else
			-- Otherwise use vanilla pathfinding
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
				more_plus.libs.weaponPreview:AddAnimation(p2, more_plus.commonIcons.boost.key, nil,  -- delay
						more_plus.WEAPON_PREVIEW_GROUP_ID, GetText(customSkill.name) .. ": " .. GetText(customSkill.description))
			end, pawnId
		)
		effect:AddScript([[
				GAME.more_plus.momentum.boosted_by_effect[]].. pawnId ..[[] = true
				Board:GetPawn(]].. pawnId ..[[):SetBoosted(true)]])
		logger.logDebug(SUBMODULE, "Will apply boosted to pawn %d moving %d tiles", pawnId, distance)
	end
end

function customSkill.checkMove(mission, pawn, weaponId, p1, p2, skillEffect)
	if weaponId == "Move" then
		local pilot = pawn:GetPilot()
		if pilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) then
			if not customSkill.reentrant then
				logger.logDebug(SUBMODULE, "First calculation pass, will recalculate pathing", pawn:GetId())
				customSkill.reentrant = true
				-- Recalculate so hijacked paths and skill-granted movement are resolved
				local builtEffect = Move:GetSkillEffect(p1, p2)
				customSkill:momentumTriggered(pawn:GetId(), p1, p2, skillEffect, builtEffect)
				customSkill.reentrant = false
			else
				logger.logDebug(SUBMODULE, "Second calculation pass - skipping logic", pawn:GetId())
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

