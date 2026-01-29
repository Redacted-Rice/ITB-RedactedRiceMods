local skill = {
	id = "RrGuarded",
	name = "Guarded",
	desc = "Mech is guarding and cannot be pushed",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
	modified = {}
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
			if not pawn:IsGuarding() then
				Game:GetPawn(pawnId):SetPushable(true)
				modified[pawnId] = pawn
			end
		else
			if modified[pawnId] then
				Game:GetPawn(pawnId):SetPushable(false)
			end
		end
	end
end

return skill