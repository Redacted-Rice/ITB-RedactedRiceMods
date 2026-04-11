local customSkill = more_plus.SkillEffectModifier:new{
	id = "RrVampire",
	name = "Vampire",
	description = "Repair when you kill a vek.",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
}

customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Vampire", customSkill.DEBUG)

customSkill:addCustomTrait()

function customSkill:modifySpaceDamage(attackingPawn, previewState, spaceDamage, indexes, targetPawn)
	if targetPawn and targetPawn:IsEnemy() and spaceDamage.iDamage > 0 and 
			spaceDamage.iDamage ~= DAMAGE_ZERO then
		local wouldKill = false
		if spaceDamage.iDamage == DAMAGE_DEATH then
			wouldKill = true
		else
			local currentHealth = targetPawn:GetHealth()
			wouldKill = (currentHealth - spaceDamage.iDamage) <= 0
		end

		if wouldKill then
			local pawnLoc = attackingPawn:GetSpace()

			-- Call repair skill and return array of all the space damages from it
			local repairEffect = _G["Skill_Repair"]:GetSkillEffect(pawnLoc, pawnLoc)
			local repairEffectTable = extract_table(repairEffect.effect)

			logger.logDebug(SUBMODULE, "Getting repair effect for pawn %d at %s (killed vek at %s)",
					attackingPawn:GetId(), pawnLoc:GetString(), spaceDamage.loc:GetString())
			return repairEffectTable
		end
	end
	return nil
end

return customSkill
