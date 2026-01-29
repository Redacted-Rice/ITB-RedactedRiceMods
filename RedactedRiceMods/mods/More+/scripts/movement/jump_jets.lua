local skill = {
	id = "RrJumpJets",
	name = "Jump Jets",
	desc = "Mech uses jump jets to leap instead of typical movement"
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT
}

-- no init needed

function skill:load() 
	if cplus_plus_ex.isSkillEnabled(self.id) then
		cplus_plus_ex:addSkillActiveHook(self.applyJumper)
	end
end

function skill.applyJumper(skillId, isActive, pawnId, pilot, skill)
	if skillId == skill.id then
		Game:GetPawn(pawnId):SetJumper(isActive)
	end
end

return skill