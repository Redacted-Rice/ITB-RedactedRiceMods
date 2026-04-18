local customSkill = more_plus.SkillEffectModifier:new{
	id = "RrVampire",
	name = "Vampire",
	description = "Repair when you kill a vek.",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
	-- Zoltan only has 1 health
	constraints = {
		pilotExclusions = {"Pilot_Zoltan"},
	}
}

customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Vampire", customSkill.DEBUG)

customSkill:addCustomTrait()

function customSkill:modifySpaceDamage(source, attackingPawn, previewState, spaceDamage, indexes, targetPawn)
	if source == self.SOURCE_ATTACKER and targetPawn and
			targetPawn:IsEnemy() and spaceDamage.iDamage > 0 and
			spaceDamage.iDamage ~= DAMAGE_ZERO then
		local wouldKill = false
		if spaceDamage.iDamage == DAMAGE_DEATH then
			wouldKill = true
		else
			local currentHealth = targetPawn:GetHealth()
			wouldKill = (currentHealth - spaceDamage.iDamage) <= 0
		end

		if wouldKill then
			local attackerLoc = attackingPawn:GetSpace()
			local targetLoc = targetPawn:GetSpace()
		
			-- Add vampire animation icons
			for _, idx in ipairs(indexes) do
				-- Show damage icon on attacker (where reflect damage will hit)
				logger.logDebug(SUBMODULE, "Adding reflect damage icon from %s to attacker %s with idx %d", 
						targetLoc:GetString(), attackerLoc:GetString(), idx)
				more_plus.libs.weaponPreview.ExecuteWithState(previewState,
						function()
							-- add to attacker and target
							more_plus.libs.weaponPreview:AddAnimation(attackerLoc,
									more_plus.commonIcons.vampire.key.."_"..idx)
							more_plus.libs.weaponPreview:AddAnimation(targetLoc,
									more_plus.commonIcons.vampire.key.."_"..idx)
						end)
			end
		
			-- Call repair skill and return array of all the space damages from it
			local repairEffect = _G["Skill_Repair"]:GetSkillEffect(attackerLoc, attackerLoc)
			local repairEffectTable = extract_table(repairEffect.effect)

			logger.logDebug(SUBMODULE, "Getting repair effect for pawn %d at %s (killed vek at %s)",
					attackingPawn:GetId(), attackerLoc:GetString(), spaceDamage.loc:GetString())
			return repairEffectTable
		end
	end
	return nil
end

return customSkill
