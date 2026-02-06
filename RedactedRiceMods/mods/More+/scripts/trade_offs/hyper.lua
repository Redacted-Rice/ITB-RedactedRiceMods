local BASE_MOVE = 3

local customSkill = more_plus.SkillActive:new{
	id = "RrHyper",
	name = "Hyper",
	description = "+3 movement, lose 1 movement at the end of each turn (min +0)",
	reusability = cplus_plus_ex.REUSABLILITY.REUSABLE,
	bonuses = {move = BASE_MOVE},
	modified = {}
}

function customSkill.setupEffect()
	table.insert(customSkill.events, modapiext.events.onNextTurn:subscribe(customSkill.decreaseMove))
end

function customSkill.decreaseMove()
	if  Game:GetTeamTurn() == TEAM_ENEMY then
		for _, pilot in pairs(cplus_plus_ex.getPilotsWithSkill(customSkill.id)) do
			local key = pilot:getAddress()
			for i, skill in pairs(pilot:getSkills()) do
				if skill:getId() == customSkill.id then
					local skillKey = key .. i
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
end

return customSkill