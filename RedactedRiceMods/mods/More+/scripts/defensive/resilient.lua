local customSkill = cplus_plus_ex.baseClasses.SkillActive:new{
	id = "RrResilient",
	name = "Resilient",
	description = "Gain a shield each time the piloted mech is damaged after the attack completes.",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
	constraints = {
		groups = {more_plus.GROUPS.SHIELD},
		pilotExclusions = {"Pilot_Zoltan"},
	}
}

-- Initialize logger
customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Resilient", customSkill.DEBUG)

more_plus:addCustomTraitIcon(customSkill)

-- Initialize GAME save data structure
local function initGameSaveData()
	if GAME == nil then
		GAME = {}
	end

	if GAME.more_plus == nil then
		GAME.more_plus = {}
	end

	if GAME.more_plus.resilient == nil then
		GAME.more_plus.resilient = {}
	end

	if GAME.more_plus.resilient.shielded_by_effect == nil then
		GAME.more_plus.resilient.shielded_by_effect = {}
	end
end

local function resetShieldTracking()
	logger.logDebug(SUBMODULE, "Resetting shield tracking")
	initGameSaveData()
	GAME.more_plus.resilient.shielded_by_effect = {}
end

function customSkill:setupEffect()
	table.insert(customSkill.events, modapiext.events.onPawnDamaged:subscribe(
		function(mission, pawn, damageTaken)
			if pawn and pawn:IsMech() and damageTaken > 0 then
				local pilot = pawn:GetPilot()
				if pilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) then
					initGameSaveData()
					local pawnId = pawn:GetId()
					
					-- Track that this effect applied the shield
					GAME.more_plus.resilient.shielded_by_effect[pawnId] = true
					
					logger.logDebug(SUBMODULE, "Pawn %d took %d damage, adding shield", 
						pawnId, damageTaken)
					pawn:SetShield(true)
					Board:AddAlert(pawn:GetSpace(), "RESILIENT")
				end
			end
		end))
	
	-- Add undo move handler
	table.insert(customSkill.events, modapiext.events.onPawnUndoMove:subscribe(customSkill.undoShield))
	
	-- Reset tracking on mission start and each turn
	table.insert(customSkill.events, modApi.events.onMissionStart:subscribe(resetShieldTracking))
	table.insert(customSkill.events, modApi.events.onNextTurn:subscribe(resetShieldTracking))
end

function customSkill.undoShield(mission, pawn, undonePosition)
	initGameSaveData()
	local pawnId = pawn:GetId()
	
	local pilot = pawn:GetPilot()
	if pilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) then
		-- If we added shield, then remove it
		if GAME.more_plus.resilient.shielded_by_effect[pawnId] then
			logger.logDebug(SUBMODULE, "Pawn %d was not shielded before Resilient, removing shield on undo", pawnId)
			pawn:SetShield(false)
			GAME.more_plus.resilient.shielded_by_effect[pawnId] = nil
		end
	end
end

return customSkill
