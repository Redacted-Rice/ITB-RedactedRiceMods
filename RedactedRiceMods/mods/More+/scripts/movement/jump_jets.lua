local customSkill = more_plus.SkillTrait:new{
	id = "RrJumpJets",
	name = "Jump Jets",
	description = "Pilot Mech leaps instead of typical movement",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT
}

function customSkill:applyTrait(pawnId, pawn, isActive)
	if isActive then
		if not pawn:IsJumper() then
			pawn:SetJumper(true)
			customSkill.modified[pawnId] = pawn
		end
	else
		if customSkill.modified[pawnId] then
			pawn:SetJumper(false)
			customSkill.modified[pawnId] = nil
		end
	end
end

return customSkill