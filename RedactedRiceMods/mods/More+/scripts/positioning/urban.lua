local customSkill = cplus_plus_ex.baseClasses.SkillActive:new{
	id = "RrUrban",
	name = "Urban",
	description = "Gain a shield when moving adjacent to a building.",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
	constraints = {
		groups = {more_plus.GROUPS.SHIELD},
		pilotExclusions = {"Pilot_Zoltan"},
	}
}

customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Urban", customSkill.DEBUG)

more_plus:addCustomTraitIcon(customSkill)

-- Initialize GAME save data structure
local function initGameSaveData()
	if GAME == nil then
		GAME = {}
	end

	if GAME.more_plus == nil then
		GAME.more_plus = {}
	end

	if GAME.more_plus.urban == nil then
		GAME.more_plus.urban = {}
	end

	if GAME.more_plus.urban.shielded_by_effect == nil then
		GAME.more_plus.urban.shielded_by_effect = {}
	end
end

local function resetShieldTracking()
	logger.logDebug(SUBMODULE, "Resetting shield tracking")
	initGameSaveData()
	GAME.more_plus.urban.shielded_by_effect = {}
end

function customSkill:setupEffect()
	table.insert(customSkill.events, modapiext.events.onSkillBuild:subscribe(customSkill.moveSkillBuild))
	table.insert(customSkill.events, modapiext.events.onPawnUndoMove:subscribe(customSkill.undoShield))
	
	-- Reset tracking on mission start and each turn
	table.insert(customSkill.events, modApi.events.onMissionStart:subscribe(resetShieldTracking))
	table.insert(customSkill.events, modApi.events.onNextTurn:subscribe(resetShieldTracking))
end

function customSkill.moveSkillBuild(mission, pawn, weaponId, p1, p2, skillEffect)
	if weaponId == "Move" then
		initGameSaveData()
		
		local pilot = pawn:GetPilot()
		if pilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) then
			-- Check if p2 (destination) is adjacent to any building
			local isAdjacentToBuilding = more_plus.libs.boardUtils.isAdjacent(p2, function(adjacentLoc)
					return Board:IsBuilding(adjacentLoc)
			end)

			if isAdjacentToBuilding and not pawn:IsShield() then
				local pawnId = pawn:GetId()
				logger.logDebug(SUBMODULE, "Pawn %d moving to %s adjacent to building, will add shield",
						pawnId, p2:GetString())

				local shieldDamage = SpaceDamage(p2, 0)
				shieldDamage.iShield = EFFECT_CREATE
				shieldDamage.sScript = string.format([[
						GAME.more_plus.urban.shielded_by_effect[%d] = true]],
						pawnId)
				skillEffect:AddDamage(shieldDamage)
			else
				logger.logDebug(SUBMODULE, "No shield - not adjacent to building or already shielded")
			end
		end
	end
end

function customSkill.undoShield(mission, pawn, undonePosition)
	initGameSaveData()
	local pawnId = pawn:GetId()
	
	local pilot = pawn:GetPilot()
	if pilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) then
		-- If we added shield, then remove it
		if GAME.more_plus.urban.shielded_by_effect[pawnId] then
			logger.logDebug(SUBMODULE, "Pawn %d was not shielded before Urban, removing shield on undo", pawnId)
			pawn:SetShield(false)
			GAME.more_plus.urban.shielded_by_effect[pawnId] = nil
		end
	end
end

return customSkill
