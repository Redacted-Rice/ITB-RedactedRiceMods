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

function customSkill.decreaseMove()
	if  Game:GetTeamTurn() == TEAM_ENEMY then
		for _, pilotAndSkills in pairs(cplus_plus_ex:getPilotsWithSkill(customSkill.id)) do
			local pilot = pilotAndSkills.pilot
			local idxes = pilotAndSkills.skillIndices
			local key = pilot:getAddress()
			for _, idx in ipairs(idxes) do
				local skill = pilot:getLvlUpSkill(idx)
				local skillKey = key .. "_" .. idx
				if not customSkill.modified[skillKey] then
					customSkill.modified[skillKey] = BASE_MOVE
				end
				if customSkill.modified[skillKey] > 0 then
					skill:setMoveBonus(skill:getMoveBonus() - 1)
				end
			end
		end
	end
end

return customSkill