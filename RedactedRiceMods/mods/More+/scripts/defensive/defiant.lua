local GRID_DEF_PER_ENEMY = 3

local customSkill = more_plus.SkillActive:new{
	id = "RrDefiant",
	name = "Defiant",
	description = "+"..GRID_DEF_PER_ENEMY.." grid defense per enemy on the board",
	reusability = cplus_plus_ex.REUSABLILITY.REUSABLE,
}

customSkill:addCustomTrait()

function customSkill:setupEffect()
	table.insert(customSkill.events, modapiext.events.onPawnTracked:subscribe(
		function(mission, pawn)
			customSkill.updateGridDefense()
		end))
	table.insert(customSkill.events, modapiext.events.onPawnUntracked:subscribe(
		function(mission, pawn)
			customSkill.updateGridDefense()
		end))
	table.insert(customSkill.events, modApi.events.onMissionStart:subscribe(
		function()
			customSkill.updateGridDefense()
		end))
	table.insert(customSkill.events, modApi.events.onMissionEnd:subscribe(
		function()
			customSkill.resetGridDefense()
		end))
	-- update on load
	self.updateGridDefense()
end

function customSkill.updateGridDefense()
	if not Game or not Board then return end

	-- Count enemies on the board using proper board size
	-- IsEnemy returns true for all hostile units including bots, bosses, and regular vek
	local enemyCount = 0
	local boardSize = Board:GetSize()
	for x = 0, boardSize.x - 1 do
		for y = 0, boardSize.y - 1 do
			local point = Point(x, y)
			local pawn = Board:GetPawn(point)
			if pawn and pawn:IsEnemy() then
				enemyCount = enemyCount + 1
			end
		end
	end

	-- Update grid defense for all active skill instances
	local gridDefBonus = enemyCount * GRID_DEF_PER_ENEMY
	for _, skill in ipairs(cplus_plus_ex:getSkillObjsActive(customSkill.id)) do
		skill:setGridBonus(gridDefBonus)
		LOG("Defiant: Set grid defense to " .. gridDefBonus .. " (enemies: " .. enemyCount .. ")")
	end
end

function customSkill.resetGridDefense()
	for _, skill in ipairs(cplus_plus_ex:getSkillObjsActive(customSkill.id)) do
		skill:setGridBonus(0)
		LOG("Defiant: Reset grid defense to 0")
	end
end

return customSkill
