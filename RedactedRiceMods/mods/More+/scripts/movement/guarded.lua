local customSkill = more_plus.SkillTrait:new{
	id = "RrGuarded",
	name = "Guarded",
	description = "Piloted Mech is Stable and cannot be moved by weapon effects",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT
}

function customSkill:applyTrait(pawnId, pawn, isActive)
	if isActive then
		if not pawn:IsGuarding() then
			pawn:SetPushable(false)
			customSkill.modified[pawnId] = pawn
		end
	else
		if customSkill.modified[pawnId] then
			pawn:SetPushable(true)
			customSkill.modified[pawnId] = nil
		end
	end
end

return customSkill