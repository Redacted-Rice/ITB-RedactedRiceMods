local customSkill = cplus_plus_ex.baseClasses.SkillActive:new{
	id = "RrRally",
	name = "Rally",
	description = "Boost adjacent allies when you move next to them or they move next to you.",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
}

customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Rally", customSkill.DEBUG)

more_plus:addCustomTraitIcon(customSkill)

-- Initialize GAME save data structure
local function initGameSaveData()
	if GAME == nil then
		GAME = {}
	end

	if GAME.more_plus == nil then
		GAME.more_plus = {}
	end

	if GAME.more_plus.rally == nil then
		GAME.more_plus.rally = {}
	end

	if GAME.more_plus.rally.boosted_by_effect == nil then
		GAME.more_plus.rally.boosted_by_effect = {}
	end
end

local function resetBoostTracking()
	logger.logDebug(SUBMODULE, "Resetting boost tracking")
	initGameSaveData()
	GAME.more_plus.rally.boosted_by_effect = {}
end

function customSkill.setBoostings(pawnId, setSelf, adjId)
	logger.logDebug(SUBMODULE, "Setting boost tracking")

	initGameSaveData()
	if not GAME.more_plus.rally.boosted_by_effect[pawnId] then
		GAME.more_plus.rally.boosted_by_effect[pawnId] = {adjPawns = {}, self = setSelf or false}
	end
	if adjId then
		GAME.more_plus.rally.boosted_by_effect[pawnId].adjPawns[adjId] = true
	end
end

function customSkill:setupEffect()
	table.insert(customSkill.events, modapiext.events.onSkillBuild:subscribe(customSkill.moveSkillBuild))
	table.insert(customSkill.events, modapiext.events.onPawnUndoMove:subscribe(customSkill.undoBoosted))

	-- Reset tracking on mission start and each turn
	table.insert(customSkill.events, modApi.events.onMissionStart:subscribe(resetBoostTracking))
	table.insert(customSkill.events, modApi.events.onNextTurn:subscribe(resetBoostTracking))
end

function customSkill.moveSkillBuild(mission, pawn, weaponId, p1, p2, skillEffect)
	if weaponId == "Move" then
		initGameSaveData()

		-- Check if the moving pawn has Rally skill
		local movingPilot = pawn:GetPilot()
		if movingPilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, movingPilot) then
			-- Moving pawn with Rally - check for adjacent allies at destination
			local adjacentMechs = more_plus.libs.boardUtils.getAdjacent(p2, function(adjacentLoc)
					local adjacentPawn = Board:GetPawn(adjacentLoc)
					return adjacentPawn and adjacentPawn:GetId() ~= pawn:GetId() and
							adjacentPawn:GetTeam() == TEAM_PLAYER and not adjacentPawn:IsBoosted()
			end)

			for _, adjacentLoc in ipairs(adjacentMechs) do
				local adjacentPawn = Board:GetPawn(adjacentLoc)
				local adjacentId = adjacentPawn:GetId()
				logger.logDebug(SUBMODULE, "Rally pawn %d moving to %s, boosting adjacent ally %d at %s",
						pawn:GetId(), p2:GetString(), adjacentId, adjacentLoc:GetString())

				more_plus.libs.weaponPreview.ExecuteWithState(more_plus.libs.weaponPreview.STATE_SKILL_EFFECT,
						function()
							more_plus.libs.weaponPreview:AddAnimation(adjacentLoc,
									more_plus.commonIcons.boost.key.."_1")
						end)

				local boostDamage = SpaceDamage(adjacentLoc, 0)
				boostDamage.sScript = [[
						cplus_plus_ex.baseClasses.SkillActive.skills.RrRally.setBoostings(]] .. pawn:GetId() .. [[, false, ]] .. adjacentId .. [[)]
						Board:GetPawn(]].. adjacentId ..[[):SetBoosted(true)]]
				skillEffect:AddDamage(boostDamage)
			end
		end

		-- Check if moving pawn is moving adjacent to a pawn with Rally
		local hasAdjacentRally = more_plus.libs.boardUtils.isAdjacent(p2, function(adjacentLoc)
			local adjacentPawn = Board:GetPawn(adjacentLoc)
			if adjacentPawn and adjacentPawn:GetId() ~= pawn:GetId() and
					adjacentPawn:GetTeam() == TEAM_PLAYER then
				local adjacentPilot = adjacentPawn:GetPilot()
				return adjacentPilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, adjacentPilot)
			end
			return false
		end)

		-- Boost the moving pawn if not already boosted and found a Rally pilot
		if hasAdjacentRally and not pawn:IsBoosted() then
			local pawnId = pawn:GetId()
			logger.logDebug(SUBMODULE, "Pawn %d moving adjacent to Rally pawn, boosting",
				pawnId)

			more_plus.libs.weaponPreview.ExecuteWithState(more_plus.libs.weaponPreview.STATE_SKILL_EFFECT,
					function()
						more_plus.libs.weaponPreview:AddAnimation(p2,
								more_plus.commonIcons.boost.key.."_1")
					end)

			local boostDamage = SpaceDamage(p2, 0)
			boostDamage.sScript = [[
					cplus_plus_ex.baseClasses.SkillActive.skills.RrRally.setBoostings(]]..pawnId..[[, true)
					Board:GetPawn(]]..pawnId..[[):SetBoosted(true)]]
			skillEffect:AddDamage(boostDamage)
		end
	end
end

function customSkill.undoBoosted(mission, pawn, undonePosition)
	initGameSaveData()
	local pawnId = pawn:GetId()

	-- If we added shield, then remove it
	if GAME.more_plus.rally.boosted_by_effect[pawnId] then
		if GAME.more_plus.rally.boosted_by_effect[pawnId].selfPawn then
			logger.logDebug(SUBMODULE, "Pawn %d (self) was not boosted before Rally, removing boosted on undo", pawnId)
			pawn:SetShield(false)
		end
		for adjPawnId, _ in pairs(GAME.more_plus.rally.boosted_by_effect[pawnId].adjPawns) do
			logger.logDebug(SUBMODULE, "Pawn %d (adj) was not boosted before Rally, removing boosted on undo", pawnId)
			Board:GetPawn(adjPawnId):SetShield(false)
		end
	end
	GAME.more_plus.rally.boosted_by_effect[pawnId] = nil
end

return customSkill
