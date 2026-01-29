local skill = {
	id = "RrIgnorant",
	name = "Ignorant",
	desc = "Pilot gains boosted each turn but loses 2 xp per kill",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
	events = {},
}

-- no init needed

function skill.clearEvents()
	for _, event in pairs(skill.events) do
		event:unsubscribe()
	end
end

function skill:load() 
	self.clearEvents()
	
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
			table.insert(events, modapiext.events.onPawnKilled:subscribe(skill.killedPawn))
			table.insert(events, modapiext.events.onSkillStart:subscribe(skill.setAttackingMech))
			table.insert(events, modapiext.events.onFinalEffectStart:subscribe(skill.setAttackingMech))
			table.insert(events, modapiext.events.onSkillEnd:subscribe(skill.unsetAttackingMech))
			table.insert(events, modapiext.events.onFinalEffectend:subscribe(skill.unsetAttackingMech))
			table.insert(events, modapiext.events.onNextTurn:subscribe(skill.boostOnTurn))
		elseif not notActive and wasActive then
			-- remove events
			self.clearEvents()
		end
	end
end

local trackedMech

function skill.setAttackingMech(mission, pawn)
	if pawn:isMech() and pawn:IsSkillActive(skill.id) then
		trackedMech = pawn
	end
end

function skill.unsetAttackingMech()
	trackedMech = nil
end

function skill.killedPawn(mission, pawn)
	if trackedMech ~= nil and pawn:isEnemy() then
		trackedMech:GetPilot():addXp(-2)
	end
end

function skill.boostOnTurn()
	if  Game:GetTeamTurn() == TEAM_PLAYER then
		for _, mech in pairs(cplus_plus_ex.getMechsWithSkill(skillId)) do
			mech:SetBoosted(true)
		end
	end
end

return skill