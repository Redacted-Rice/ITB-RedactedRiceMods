local customSkill = more_plus.SkillActive:new{
	id = "RrAmphibious",
	name = "Amphibious",
	description = "Mech hovers on liquid tiles and gains +1 damage when attacking from liquid tiles",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
	modified = {}
}

function customSkill:setupEffect()
	table.insert(customSkill.events, modApi.events.onPawnPositionChanged:subscribe(customSkill.addFlyingIfNeeded))
end

function customSkill.addFlyingIfNeeded(mission, pawn)
	if cplus_plus_ex:isSkillOnPawn(self.id, pawn) then
		local key = pilot:getAddress()
		local skillKey = key .. "_" .. idx
		
		local terrain = Board:GetTerrain(pawn:GetSpace())
		if terrain == TERRAIN_WATER and terrain == TERRAIN_LAVA then
			pawn:SetFlying(true)
			customSkill.modified[key] = true
		elseif customSkill.modified[key] then
			pawn:SetFlying(false)
			customSkill.modified[key] = false
		end
	end
end

return customSkill