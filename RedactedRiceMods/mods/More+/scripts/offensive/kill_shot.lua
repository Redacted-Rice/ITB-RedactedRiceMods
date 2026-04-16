local customSkill = more_plus.SkillEffectModifier:new{
	id = "RrKillShot",
	name = "Kill Shot",
	description = "+1 damage to enemies that would be killed by the extra damage.",
	reusability = cplus_plus_ex.REUSABLILITY.REUSABLE,
	groups = {more_plus.GROUPS.ADD_DAMAGE},
}

-- Initialize logger
customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "KillShot", customSkill.DEBUG)

customSkill:addCustomTrait()

function customSkill:modifySpaceDamage(source, attackingPawn, previewState, spaceDamage, indexes, targetPawn)
	local numInstances = #indexes

	if source == self.SOURCE_ATTACKER and targetPawn and
			targetPawn:IsEnemy() and spaceDamage.iDamage > 0 and
			spaceDamage.iDamage ~= DAMAGE_DEATH and spaceDamage.iDamage ~= DAMAGE_ZERO then
		local currentHealth = targetPawn:GetHealth()
		local totalBonusDamage = numInstances
		local wouldKillWithExtra = (currentHealth - (spaceDamage.iDamage + totalBonusDamage)) <= 0

		if wouldKillWithExtra then
			for _, idx in ipairs(indexes) do
				logger.logDebug(SUBMODULE, "Adding icon for %s with idx %d", spaceDamage.loc:GetString(), idx)
				more_plus.libs.weaponPreview.ExecuteWithState(previewState,
						function()
							more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc,
									more_plus.commonIcons.extraDamage.key.."_"..idx)
						end)
			end

			spaceDamage.iDamage = spaceDamage.iDamage + totalBonusDamage
			logger.logDebug(SUBMODULE, "Added +%d damage to finish off vek at %s (health: %d, base damage: %d, instances: %d)",
				totalBonusDamage, spaceDamage.loc:GetString(), currentHealth, spaceDamage.iDamage - totalBonusDamage, numInstances)
		else
			logger.logDebug(SUBMODULE, "No bonus damage - vek at %s would survive (health: %d, damage: %d)",
				spaceDamage.loc:GetString(), currentHealth, spaceDamage.iDamage)
		end
	end
	return nil
end

return customSkill
