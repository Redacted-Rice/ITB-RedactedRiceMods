local GRID_DEF_BONUS = 12

local customSkill = more_plus.SkillActive:new{
	id = "RrFoolhardy",
	name = "Foolhardy",
	description = "+"..GRID_DEF_BONUS.." grid defense if no buildings are damaged.",
	reusability = cplus_plus_ex.REUSABLILITY.REUSABLE,
}

customSkill:addCustomTrait()

function customSkill:setupEffect()
	table.insert(customSkill.events, modApi.events.onMissionStart:subscribe(
		function()
			customSkill.checkAndSetGridDefense()
		end))
		
	table.insert(customSkill.events, modApi.events.onMissionStart:subscribe(
		function()
			customSkill.checkAndSetGridDefense()
		end))
		
	table.insert(customSkill.events, BoardEvents.onBuildingDamaged:subscribe(
		function()
			customSkill.buildingDamaged()
		end))

 	-- fire now on load/on earn
	customSkill.checkAndSetGridDefense()
end

function customSkill.buildingDamaged()
	for _, skill in ipairs(cplus_plus_ex:getSkillObjsActive(customSkill.id)) do
		skill:setGridBonus(0)
		--LOG("Foolhardy: Grid defense set to 0 (damaged buildings detected)")
	end
end

function customSkill.checkAndSetGridDefense()
	local anyBuildingDamaged = false
	local buildings = extract_table(Board:GetBuildings())

	for _, point in ipairs(buildings) do
		if Board:IsDamaged(point) then
			anyBuildingDamaged = true
			break
		end
	end

	if anyBuildingDamaged then
		customSkill.buildingDamaged()
	else
		for _, skill in ipairs(cplus_plus_ex:getSkillObjsActive(customSkill.id)) do
			skill:setGridBonus(GRID_DEF_BONUS)
			--LOG("Foolhardy: Set grid defense to " .. GRID_DEF_BONUS)
		end
	end
end

return customSkill
