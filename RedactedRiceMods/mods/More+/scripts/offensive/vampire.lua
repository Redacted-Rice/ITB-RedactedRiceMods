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

function customSkill:modifySpaceDamage(pawn, isFinalEffect, spaceDamage, indexes, spacePawn)
	if spacePawn and spacePawn:IsEnemy() and spaceDamage.iDamage > 0 and spaceDamage.iDamage ~= DAMAGE_ZERO then
		local wouldKill = false
		if spaceDamage.iDamage == DAMAGE_DEATH then
			wouldKill = true
		else
			local currentHealth = spacePawn:GetHealth()
			wouldKill = (currentHealth - spaceDamage.iDamage) <= 0
		end

		if wouldKill then
			local pilot = pawn:GetPilot()
			if pilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) then
				local pawnLoc = pawn:GetSpace()

				-- Call repair skill and return array of all the space damages from it
				local repairEffect = _G["Skill_Repair"]:GetSkillEffect(pawnLoc, pawnLoc)
				local repairEffectTable = extract_table(repairEffect.effect)

				logger.logDebug(SUBMODULE, "Getting repair effect for pawn %d at %s (killed vek at %s)",
						pawn:GetId(), pawnLoc:GetString(), spaceDamage.loc:GetString())
				return repairEffectTable
			end
		end
	end

	return nil
end

return customSkill
