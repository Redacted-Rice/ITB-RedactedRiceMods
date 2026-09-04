local customSkill = cplus_plus_ex.baseClasses.SkillActive:new{
	id = "RrNimble",
	name = "Nimble",
	description = "Piloted mech can move onto and through buildings and mountains.",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
	constraints = {
		groups = {more_plus.GROUPS.MOVE_TYPE},
		squadExclusions = {"knight_ChessPawns"},
	}
}

-- Initialize logger
customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Nimble", customSkill.DEBUG)

more_plus:addCustomTraitIcon(customSkill)

local boardUtils = more_plus.libs.boardUtils

BoardUtils.CanMoveOnMountains = BoardUtils.makeAllowIfHasSkill(BoardUtils.CanMoveOnMountains, customSkill.id)
BoardUtils.CanMoveOnBuildings = BoardUtils.makeAllowIfHasSkill(BoardUtils.CanMoveOnBuildings, customSkill.id)

function customSkill:setupEffect()
	table.insert(customSkill.events, modapiext.events.onTargetAreaBuild:subscribe(customSkill.moveTargetArea))
	table.insert(customSkill.events, modapiext.events.onSkillBuild:subscribe(customSkill.moveSkillBuild))
end

function customSkill.moveTargetArea(mission, pawn, weaponId, p1, targetArea)
	if weaponId == "Move" then
		local pilot = pawn:GetPilot()
		if pilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) then
			logger.logDebug(SUBMODULE, "Calculating nimble target area for pawn %d from %s",
					pawn:GetId(), p1:GetString())

			-- This will respect and check the can move on/through functions included what we
			-- set above so no special handling is needed
			local newPoints = more_plus.libs.boardUtils.getMoveReachableInRange(
					pawn, pawn:GetMoveSpeed(), p1, "default")

			local hashedPoints = {}
			local addedCount = 0
			local addedPoints = {}
			for oldIdx = 1, targetArea:size() do
				hashedPoints[more_plus.libs.boardUtils.getSpaceHash(targetArea:index(oldIdx))] = true
			end
			for newIdx = 1, newPoints:size() do
				local point = newPoints:index(newIdx)
				if not hashedPoints[more_plus.libs.boardUtils.getSpaceHash(point)] then
					targetArea:push_back(point)
					table.insert(addedPoints, point:GetString())
					addedCount = addedCount + 1
				end
			end
			if addedCount > 0 then
				logger.logDebug(SUBMODULE, "Added %d additional move targets for pawn %d: [%s]",
					addedCount, pawn:GetId(), table.concat(addedPoints, ", "))
			else
				logger.logDebug(SUBMODULE, "No additional move targets added for pawn %d", pawn:GetId())
			end
		end
	end
end

function customSkill.moveSkillBuild(mission, pawn, weaponId, p1, p2, skillEffect)
	if weaponId == "Move" then
		local pilot = pawn:GetPilot()
		if pilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) then
			-- Path based movement (walk, burrow). Skip leap/teleport/charge
			if boardUtils.skillEffectUsesPathMovement(skillEffect) then
				logger.logDebug(SUBMODULE, "Calculating custom path for pawn %d from %s to %s",
						pawn:GetId(), p1:GetString(), p2:GetString())

				local path = more_plus.libs.boardUtils.findMovePath(pawn, p1, p2, "default", true)
				if path then
					more_plus.libs.boardUtils.addForcedMove(skillEffect, path)
				end
				logger.logDebug(SUBMODULE, "Custom path calculated with %d steps", path and path:size() or 0)
			end
		end
	end
end

return customSkill