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
		if pilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) and customSkill.modified[pawn:GetId()] then
			return Board:GetReachable(point, Pawn:GetMoveSpeed(), bit32.band(Pawn:GetPathProf(), bit32.bnot(PATH_FLYER)))
		end
	end
end

function customSkill.applyOnMissionEnter()
	for _, mechInfo in pairs(cplus_plus_ex:getMechsWithSkill(customSkill.id)) do
		local pawn = Board:GetPawn(mechInfo.pawnId)
		local terrain = Board:GetTerrain(pawn:GetSpace())
		if terrain == TERRAIN_WATER or terrain == TERRAIN_LAVA then
			pawn:SetFlying(true)
			customSkill.modified[pawn:GetId()] = true
		end
	end
end

function customSkill.addFlyingIfNeeded(mission, pawn)
	if cplus_plus_ex:isSkillOnPawn(customSkill.id, pawn) then
		local terrain = Board:GetTerrain(pawn:GetSpace())
		if terrain == TERRAIN_WATER or terrain == TERRAIN_LAVA then
			pawn:SetFlying(true)
			customSkill.modified[pawn:GetId()] = true
		elseif customSkill.modified[pawn:GetId()] then
			pawn:SetFlying(false)
			customSkill.modified[pawn:GetId()] = false
		end
	end
end

return customSkill