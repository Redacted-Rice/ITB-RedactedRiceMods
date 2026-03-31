local customSkill = more_plus.SkillActive:new{
	id = "RrAmphibious",
	name = "Amphibious",
	description = "Mech hovers on liquid tiles",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
	modified = {}
}

customSkill:addCustomTrait()

function customSkill:setupEffect()
	table.insert(customSkill.events, modapiext.events.onTargetAreaBuild:subscribe(customSkill.moveTargetArea))
	table.insert(customSkill.events, modapiext.events.onPawnPositionChanged:subscribe(customSkill.addFlyingIfNeeded))
	table.insert(customSkill.events, modapiext.events.onPawnSelected:subscribe(customSkill.addFlyingIfNeeded))
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
		if terrain == TERRAIN_WATER or terrain == TERRAIN_LAVA then
			more_plus.libs.boardUtils.setHijackedFlying(pawn, true)
		end
	end
end

function customSkill.addFlyingIfNeeded(mission, pawn)
	if cplus_plus_ex:isSkillOnPawn(customSkill.id, pawn) then
		local terrain = Board:GetTerrain(pawn:GetSpace())
		if terrain == TERRAIN_WATER or terrain == TERRAIN_LAVA then
			more_plus.libs.boardUtils.setHijackedFlying(pawn, true)
		else
			more_plus.libs.boardUtils.setHijackedFlying(pawn, false)
		end
	end
end

return customSkill