local skill = SkillTrait.new(
		"RrGuarded",
		"Guarded",
		"Mech is guarding and cannot be pushed",
		cplus_plus_ex.REUSABLILITY.PER_PILOT
)

function skill.applyTrait(pawnId, pawn, isActive)
	if isActive then
		if not pawn:IsGuarding() then
			pawn:SetPushable(true)
			skill.modified[pawnId] = pawn
		end
	else
		if skill.modified[pawnId] then
			pawn:SetPushable(false)
			skill.modified[pawnId] = nil
		end
	end
end

return skill