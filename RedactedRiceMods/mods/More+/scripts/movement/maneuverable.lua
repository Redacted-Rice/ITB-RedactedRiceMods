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
			
			-- Remove the other points
			while not targetArea:empty() do
				targetArea:erase(0)
			end
			-- makeAllTerrainMatcher (.., "friendly") == pass through friendly pawns
			-- makeAllTerrainMatcher (.., "any") == can't land on any pawns
			more_plus.libs.boardUtils.getReachableInRange(targetArea, pawn:GetBaseMove(), p1,
					more_plus.libs.boardUtils.makeAllTerrainMatcher(pawn, "friendly"),
					more_plus.libs.boardUtils.makeAllTerrainMatcher(pawn, "any"))
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