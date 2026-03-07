local customSkill = more_plus.SkillActive:new{
	id = "RrManeuverable",
	name = "Maneuverable",
	description = "Mech can move through and over buildings and mountains",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
}

customSkill:addCustomTrait()

function customSkill:setupEffect()
	table.insert(customSkill.events, modapiext.events.onTargetAreaBuild:subscribe(customSkill.moveTargetArea))
	table.insert(customSkill.events, modapiext.events.onSkillBuild:subscribe(customSkill.moveSkillBuild))
end

function customSkill.moveTargetArea(mission, pawn, weaponId, p1, targetArea)
	if weaponId == "Move" then
		local pilot = pawn:GetPilot()
		if pilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) then
			-- TODO: Make this additive instead of removing and recreate
			-- This will play nicer with other movement changing things?

			-- makeAllTerrainMatcher (.., "friendly") == pass through friendly pawns
			-- makeAllTerrainMatcher (.., "any") == can't land on any pawns
			local newPoints = PointList()
			more_plus.libs.boardUtils.getReachableInRange(newPoints, pawn:GetMoveSpeed(), p1,
					more_plus.libs.boardUtils.makeAllTerrainMatcher(pawn, "friendly"),
					more_plus.libs.boardUtils.makeAllTerrainMatcher(pawn, "any"))
					
			local hashedPoints = {}
			for oldIdx = 1, targetArea:size() do
				hashedPoints[more_plus.libs.boardUtils.getSpaceHash(targetArea:index(oldIdx))] = true
			end
			for newIdx = 1, newPoints:size() do
				if not hashedPoints[more_plus.libs.boardUtils.getSpaceHash(newPoints:index(newIdx))] then
					targetArea:push_back(newPoints:index(newIdx))
				end
			end
		end
	end
end

function customSkill.moveSkillBuild(mission, pawn, weaponId, p1, p2, skillEffect)
	if weaponId == "Move" then
		local pilot = pawn:GetPilot()
		if pilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) then
			if not (pawn:IsJumper() or pawn:IsTeleporter() or pawn:IsBurrower()) then
				-- makeAllTerrainMatcher (.., "friendly") == pass through friendly pawns
				-- findBfsPath (.., true) == as point list
				local path = more_plus.libs.boardUtils.findBfsPath(p1, p2,
						more_plus.libs.boardUtils.makeAllTerrainMatcher(pawn, "friendly"), true)
				more_plus.libs.boardUtils.addForcedMove(skillEffect, path)
			end
		end
	end
end

return customSkill