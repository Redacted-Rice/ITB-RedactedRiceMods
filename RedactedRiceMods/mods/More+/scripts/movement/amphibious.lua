local customSkill = more_plus.SkillActive:new{
	id = "RrAmphibious",
	name = "Amphibious",
	description = "Mech hovers on liquid tiles",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
	modified = {}
}

customSkill:addCustomTrait()

-- TODO: This will not work as expected... We need to override move targer area as well to prevent showing
-- holes as traversable and enemies as passable

function customSkill:setupEffect()
	table.insert(customSkill.events, modapiext.events.onPawnPositionChanged:subscribe(customSkill.addFlyingIfNeeded))
	table.insert(customSkill.events, modapiext.events.onPawnSelected:subscribe(customSkill.addFlyingIfNeeded))
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