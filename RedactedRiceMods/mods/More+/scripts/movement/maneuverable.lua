local customSkill = more_plus.SkillActive:new{
	id = "RrManeuverable",
	name = "Maneuverable",
	description = "Piloted mech can move through and over buildings and mountains.",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
}

-- Initialize logger
customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Maneuverable", customSkill.DEBUG)

customSkill:addCustomTrait()

-- Doesn't work as expected with Henry ATM
cplus_plus_ex:registerPilotSkillExclusions("Pilot_Hotshot", customSkill.id)

function customSkill:setupEffect()
	table.insert(customSkill.events, modapiext.events.onTargetAreaBuild:subscribe(customSkill.moveTargetArea))
	table.insert(customSkill.events, modapiext.events.onSkillBuild:subscribe(customSkill.moveSkillBuild))
end

function customSkill.moveTargetArea(mission, pawn, weaponId, p1, targetArea)
	if weaponId == "Move" then
		local pilot = pawn:GetPilot()
		if pilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) then
			logger.logDebug(SUBMODULE, "Calculating maneuverable target area for pawn %d from %s", pawn:GetId(), p1:GetString())
			-- makeAllTerrainMatcher (.., "friendly") == pass through friendly pawns
			-- makeAllTerrainMatcher (.., "any") == can't land on any pawns
			local newPoints = PointList()
			more_plus.libs.boardUtils.getReachableInRange(newPoints, pawn:GetMoveSpeed(), p1,
					more_plus.libs.boardUtils.makeAllTerrainMatcher(pawn, "friendly"),
					more_plus.libs.boardUtils.makeAllTerrainMatcher(pawn, "any"))

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
			-- Only apply custom pathing for ground-based units
			-- Jumpers and teleporters use point-to-point movement
			-- Burrowers follow a path but already have special pathing
			if not (pawn:IsJumper() or pawn:IsTeleporter() or pawn:IsBurrower()) then
				logger.logDebug(SUBMODULE, "Calculating custom path for pawn %d from %s to %s", pawn:GetId(), p1:GetString(), p2:GetString())
				-- makeAllTerrainMatcher (.., "friendly") == pass through friendly pawns
				-- findBfsPath (.., true) == as point list
				local path = more_plus.libs.boardUtils.findBfsPath(p1, p2,
						more_plus.libs.boardUtils.makeAllTerrainMatcher(pawn, "friendly"), true)
				more_plus.libs.boardUtils.addForcedMove(skillEffect, path)
				logger.logDebug(SUBMODULE, "Custom path calculated with %d steps", path and path:size() or 0)
			end
		end
	end
end

return customSkill