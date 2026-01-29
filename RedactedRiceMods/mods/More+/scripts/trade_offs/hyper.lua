local BASE_MOVE = 3

local skill = {
	id = "RrHyper",
	name = "Hyper",
	desc = "+3 movement, lose 1 movement at the end of each turn (min +0)",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
	bonuses = {move = BASE_MOVE},
	events = {},
	modified = {},
}

-- no init needed

function skill:load() 
	if cplus_plus_ex.isSkillEnabled(self.id) then
		cplus_plus_ex:addSkillActiveHook(self.setupEffect)
	end
end

function skill.setupEffect(skillId, isActive, pawnId, pilot, skill)
	if skillId == skill.id then
		local nowActive = #cplus_plus_ex.getMechsWithSkill(skillId) > 0
		local wasActive = cplus_plus_ex.isSkillActive(skillId)
		if nowActive and not wasActive then
			-- add events
			table.insert(events, modapiext.events.onNextTurn:subscribe(skill.decreaseMove))
		else not notActive and wasActive then
			-- remove events
			self.clearEvents()
		end
	end
end

function skill.decreaseMove()
	if  Game:GetTeamTurn() == TEAM_ENEMY then
		for _, pilot in pairs(cplus_plus_ex.getPilotsWithSkill(skillId)) do
			local key = pilot:getAddress()
			for i, skill in pairs(pilot:getSkills()) do
				if skill:getId() == skill.id then
					local skillKey = key .. i
					if not modified[skillKey] then
						modified[skillKey] = BASE_MOVE
					end
					if modified[skillKey] > 0 then
						skill:setMoveBonus(skill:getMoveBonus() - 1)
					end
				end
			end
		end
	end
end

return skill