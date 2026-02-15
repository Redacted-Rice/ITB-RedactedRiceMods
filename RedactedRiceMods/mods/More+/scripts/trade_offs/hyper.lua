local BASE_MOVE = 3

local customSkill = more_plus.SkillActive:new{
	id = "RrHyper",
	name = "Hyper",
	description = "+3 movement, lose 1 movement at the end of each turn (min +0)",
	reusability = cplus_plus_ex.REUSABLILITY.REUSABLE,
	bonuses = {move = BASE_MOVE},
}

function customSkill:setupEffect()
	table.insert(customSkill.events, modApi.events.onNextTurn:subscribe(customSkill.decreaseMove))
end

function customSkill.decreaseMove()
	if  Game:GetTeamTurn() == TEAM_ENEMY then
		for _, pilotAndSkills in pairs(cplus_plus_ex:getPilotsWithSkill(customSkill.id)) do
			local pilot = pilotAndSkills.pilot
			local idxes = pilotAndSkills.skillIndices
			local key = pilot:getAddress()
			for _, idx in ipairs(idxes) do
				local skill = pilot:getLvlUpSkill(idx)
				skill:setMoveBonus(math.max(0, BASE_MOVE - Game:GetTurnCount()))
			end
		end
	end
end

return customSkill