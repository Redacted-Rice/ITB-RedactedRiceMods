local customSkill = cplus_plus_ex.baseClasses.SkillActive:new{
	id = "RrPontoons",
	name = "Pontoons",
	description = "Piloted mech floats on top of liquid tiles without being affected by them.",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
	modified = {},
	-- Prospero already has flying so it doesn't help at all
	-- Flying cyborgs (Hornet) also don't benefit from pontoons
	constraints = {
		groups = {more_plus.GROUPS.MOVE_TYPE},
		pilotExclusions = {"Pilot_Recycler", cplus_plus_ex.isFlyingCyborg},
		squadExclusions = {"knight_ChessPawns"},
	}
}

-- Initialize logger
customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Amphibious", customSkill.DEBUG)

more_plus:addCustomTraitIcon(customSkill)

function customSkill:setupEffect()
	table.insert(customSkill.events, modapiext.events.onTargetAreaBuild:subscribe(customSkill.moveTargetArea))
	table.insert(customSkill.events, modapiext.events.onPawnPositionChanged:subscribe(customSkill.addFlyingIfNeeded))
	table.insert(customSkill.events, modapiext.events.onPawnSelected:subscribe(customSkill.addFlyingIfNeeded))
	table.insert(customSkill.events, modApi.events.onMissionEnd:subscribe(customSkill.clearFlying))
end

function customSkill.isLiquidTerrain(terrain)
	return terrain == TERRAIN_WATER or terrain == TERRAIN_LAVA or terrain == TERRAIN_ACID
end

function customSkill.moveTargetArea(mission, pawn, weaponId, p1, targetArea)
	if weaponId == "Move" then
		local pilot = pawn:GetPilot()
		if pilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) and more_plus.libs.boardUtils.isPawnHijackedFlying(pawn) then
			-- First time, unset flying and get a new set of points without flying
			-- Note other things that change path must use isPawnFlying in BoardUtils
			-- To work right on the second pass or else it could see the pawn as flying
			-- when in shouldn't be
			if pawn:IsFlying() then
				logger.logDebug(SUBMODULE, "Recalculating move target area for amphibious pawn %d at %s", pawn:GetId(), p1:GetString())
				pawn:SetFlying(false)
				while not targetArea:empty() do
					targetArea:erase(0)
				end
				local newPoints = Move:GetTargetArea(p1)
				for idx = 1, newPoints:size() do
					targetArea:push_back(newPoints:index(idx))
				end
				pawn:SetFlying(true)
			end
		end
	end
end

function customSkill.applyOnMissionEnter()
	for _, mechInfo in pairs(cplus_plus_ex:getMechsWithSkill(customSkill.id)) do
		local pawn = Board:GetPawn(mechInfo.pawnId)
		local terrain = Board:GetTerrain(pawn:GetSpace())
		if customSkill.isLiquidTerrain(terrain) then
			logger.logDebug(SUBMODULE, "Setting flying for pawn %d on liquid terrain", mechInfo.pawnId)
			more_plus.libs.boardUtils.setHijackedFlying(pawn, true)
		end
	end
end

function customSkill.addFlyingIfNeeded(mission, pawn)
	if cplus_plus_ex:isSkillOnPawn(customSkill.id, pawn) then
		local terrain = Board:GetTerrain(pawn:GetSpace())
		if customSkill.isLiquidTerrain(terrain) then
			logger.logDebug(SUBMODULE, "Setting flying for pawn %d on liquid terrain", pawn:GetId())
			more_plus.libs.boardUtils.setHijackedFlying(pawn, true)
		else
			logger.logDebug(SUBMODULE, "Removing flying for pawn %d on solid terrain", pawn:GetId())
			more_plus.libs.boardUtils.setHijackedFlying(pawn, false)
		end
	end
end

function customSkill.clearFlying(mission, pawn)
	if cplus_plus_ex:isSkillOnPawn(customSkill.id, pawn) then
		logger.logDebug(SUBMODULE, "Clearing flying for pawn %d", pawn:GetId())
		more_plus.libs.boardUtils.setHijackedFlying(pawn, false)
	end
end

return customSkill