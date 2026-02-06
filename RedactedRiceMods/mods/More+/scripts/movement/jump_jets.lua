local skill = more_plus.SkillTrait:new{
	id = "RrJumpJets",
	name = "Jump Jets",
	description = "Mech uses jump jets to leap instead of typical movement",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT
}

function skill.applyTrait(pawnId, pawn, isActive)
	if isActive then
		if not pawn:IsJumper() then
			pawn:SetJumper(true)
			skill.modified[pawnId] = pawn
		end
	else
		if skill.modified[pawnId] then
			pawn:SetJumper(false)
			skill.modified[pawnId] = nil
		end
	end
end

return skill