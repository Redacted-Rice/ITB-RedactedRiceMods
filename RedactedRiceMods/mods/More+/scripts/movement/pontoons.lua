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

-- Tell board utils this allows moving on (and through) water
BoardUtils.CanMoveOnWater = BoardUtils.makeAllowIfHasSkill(BoardUtils.CanMoveOnWater, customSkill.id)

more_plus:addCustomTraitIcon(customSkill)

function customSkill:setupEffect()
	table.insert(customSkill.events, modapiext.events.onTargetAreaBuild:subscribe(customSkill.moveTargetArea))
	table.insert(customSkill.events, modapiext.events.onSkillBuild:subscribe(customSkill.moveSkillBuild))
	table.insert(customSkill.events, modapiext.events.onPawnPositionChanged:subscribe(customSkill.addFlyingIfNeeded))
	table.insert(customSkill.events, modapiext.events.onPawnSelected:subscribe(customSkill.addFlyingIfNeeded))
	table.insert(customSkill.events, modApi.events.onMissionEnd:subscribe(customSkill.clearFlying))
end

function customSkill.moveTargetArea(mission, pawn, weaponId, p1, targetArea)
	-- customSkill.recalculating guards against re entering this block from our own
	-- manual fireTargetAreaBuildHooks call below.
	if weaponId == "Move" and not customSkill.recalculating then
		local pilot = pawn:GetPilot()
		if pilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) and more_plus.libs.boardUtils.isPawnHijackedFlying(pawn) then
			-- First time, manually calcualte our reachable points to avoid recalling getTargetArea
			-- as this messes with the weapon preview state
			if pawn:IsFlying() then
				logger.logDebug(SUBMODULE, "Recalculating move target area for amphibious pawn %d at %s", 
						pawn:GetId(), p1:GetString())
				while not targetArea:empty() do
					targetArea:erase(0)
				end
				local groundedPoints = more_plus.libs.boardUtils.getMoveReachableInRange(
						pawn, pawn:GetMoveSpeed(), p1, "default")
				for idx = 1, groundedPoints:size() do
					targetArea:push_back(groundedPoints:index(idx))
				end

				-- Call the fireTargetAreaBuildHooks so other skills (e.g. nimble or supporter)
				-- can add to it as appropriate
				customSkill.recalculating = true
				modApiExt_internal.fireTargetAreaBuildHooks(mission, pawn, weaponId, p1, targetArea)
				customSkill.recalculating = false
			end
		end
	end
end

-- Override move skill to allow for building the "correct" path based on what is allowed
function customSkill.moveSkillBuild(mission, pawn, weaponId, p1, p2, skillEffect)
	if weaponId == "Move" then
		local pilot = pawn:GetPilot()
		if pilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) then
			if more_plus.libs.boardUtils.skillEffectUsesPathMovement(skillEffect) then
				local path = more_plus.libs.boardUtils.findMovePath(pawn, p1, p2, "default", true)
				if path then
					more_plus.libs.boardUtils.addForcedMove(skillEffect, path)
				end
			end
		end
	end
end

function customSkill.applyOnMissionEnter()
	for _, mechInfo in pairs(cplus_plus_ex:getMechsWithSkill(customSkill.id)) do
		local pawn = Board:GetPawn(mechInfo.pawnId)
		local terrain = Board:GetTerrain(pawn:GetSpace())
		if more_plus.libs.boardUtils.isLiquid(terrain) then
			logger.logDebug(SUBMODULE, "Setting flying for pawn %d on liquid terrain", mechInfo.pawnId)
			more_plus.libs.boardUtils.setHijackedFlying(pawn, true)
		end
	end
end

function customSkill.addFlyingIfNeeded(mission, pawn)
	if cplus_plus_ex:isSkillOnPawn(customSkill.id, pawn) then
		local terrain = Board:GetTerrain(pawn:GetSpace())
		if more_plus.libs.boardUtils.isLiquid(terrain) then
			logger.logDebug(SUBMODULE, "Setting flying for pawn %d on liquid terrain", pawn:GetId())
			more_plus.libs.boardUtils.setHijackedFlying(pawn, true)
		else
			logger.logDebug(SUBMODULE, "Removing flying for pawn %d on solid terrain", pawn:GetId())
			more_plus.libs.boardUtils.setHijackedFlying(pawn, false)
		end
	end
end

function customSkill.clearFlying()
	for _, mechInfo in pairs(cplus_plus_ex:getMechsWithSkill(customSkill.id)) do
		local pawn = Board and Board:GetPawn(mechInfo.pawnId)
		if pawn then
			logger.logDebug(SUBMODULE, "Clearing flying for pawn %d", pawn:GetId())
			more_plus.libs.boardUtils.setHijackedFlying(pawn, false)
		end
	end
end

return customSkill