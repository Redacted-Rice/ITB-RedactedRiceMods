local GRID_DEF_BONUS = 12

local customSkill = more_plus.SkillActive:new{
	id = "RrFoolhardy",
	name = "Foolhardy",
	description = "+"..GRID_DEF_BONUS.." grid defense until a building is damaged",
	reusability = cplus_plus_ex.REUSABLILITY.REUSABLE,
}

customSkill:addCustomTrait()

function customSkill:setupEffect()
	-- TODO: ADD on load as well
	
	-- Set grid defense on mission start
	table.insert(customSkill.events, modApi.events.onMissionStart:subscribe(
		function()
			for _, skill in ipairs(cplus_plus_ex:getSkillObjsActive(customSkill.id)) do
				skill:setGridBonus(GRID_DEF_BONUS)
				LOG("Foolhardy: Set grid defense to " .. GRID_DEF_BONUS)
			end
		end))

	-- Watch for building damage and reset grid defense
	table.insert(customSkill.events, modapiext.events.onBuildingDamaged:subscribe(
		function(mission, building, damageType)
			for _, skill in ipairs(cplus_plus_ex:getSkillObjsActive(customSkill.id)) do
				skill:setGridBonus(0)
				LOG("Foolhardy: Reset grid defense to 0")
			end
			LOG("Foolhardy: Deactivated due to building damage")
		end))	
		
	-- TODO: Implement on load behavior - search for destroyed buildings?
end

return customSkill
