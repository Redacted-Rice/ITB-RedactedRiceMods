local skill = {
	id = "RrJumpJets",
	name = "Jump Jets",
	desc = "Mech uses jump jets to leap instead of typical movement",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
	modified = {},
}

-- no init needed

function skill:load() 
	if cplus_plus_ex.isSkillEnabled(self.id) then
		cplus_plus_ex:addSkillActiveHook(self.applyEffect)
	end
end

function skill.applyEffect(skillId, isActive, pawnId, pilot, skill)
	if skillId == skill.id then
		local pawn = Game:GetPawn(pawnId)
		if isActive then
			if not pawn:IsJumper() then
				Game:GetPawn(pawnId):SetJumper(true)
				modified[pawnId] = pawn
			end
		else
			if modified[pawnId] then
				Game:GetPawn(pawnId):SetJumper(false)
			end
		end
	end
end

return skill