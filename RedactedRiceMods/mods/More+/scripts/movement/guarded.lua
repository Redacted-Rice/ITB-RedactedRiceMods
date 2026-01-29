local skill = {
	id = "RrGuarded",
	name = "Guarded",
	desc = "Mech is guarding and cannot be pushed"
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT
}

-- no init needed

function skill:load() 
	if cplus_plus_ex.isSkillEnabled(self.id) then
		cplus_plus_ex:addSkillActiveHook(self.applyGuarding)
	end
end

function skill.applyGuarding(skillId, isActive, pawnId, pilot, skill)
	if skillId == skill.id then
		Game:GetPawn(pawnId):SetPushable(not isActive)
	end
end

return skill