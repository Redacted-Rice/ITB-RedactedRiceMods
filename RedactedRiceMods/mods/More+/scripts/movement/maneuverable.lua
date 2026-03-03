local customSkill = more_plus.SkillActive:new{
	id = "RrManeuverable",
	name = "Maneuverable",
	description = "Mech can move through and over buildings and mountains",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
}

customSkill:addCustomTrait()

function customSkill:setupEffect()
	table.insert(customSkill.events, modapiext.events.onTargetAreaBuild:subscribe(customSkill.moveTargetArea))
	table.insert(customSkill.events, modapiext.events.onTargetAreaBuild:subscribe(customSkill.onSkillBuild))
end

function customSkill:moveTargetArea(mission, pawn, weaponId, p1, targetArea)
	if weaponId == "Move" then
		local pilot = pawn:GetPilot()
		if pilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) then
			-- Remove the other points
			while not targetArea:empty() do
				targetArea:erase(0)
			end
			-- makeAllTerrainMatcher (.., "friendly") == pass through friendly pawns
			-- makeAllTerrainMatcher (.., "any") == can't land on any pawns
			self.boardUtils.getReachableInRange(targetArea, pawn:GetMoveSpeed(), p1, self.boardUtils.makeAllTerrainMatcher(pawn, "friendly"), self.boardUtils.makeAllTerrainMatcher(pawn, "any"))
		end
	end
end

function customSkill:moveSkillBuild(mission, pawn, weaponId, p1, p2, skillEffect)
	if weaponId == "Move" then
		local pilot = pawn:GetPilot()
		if pilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) then
			-- makeAllTerrainMatcher (.., "friendly") == pass through friendly pawns
			-- findBfsPath (.., true) == as point list
			local path = self.boardUtils.findBfsPath(p1, p2, self.boardUtils.makeAllTerrainMatcher(pawn, "friendly"), true)
			self.boardUtils.addForcedMove(skillEffect, path)
		end
	end
end

return customSkill