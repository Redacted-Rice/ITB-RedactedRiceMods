local customSkill = cplus_plus_ex.baseClasses.SkillEffectModifier:new{
	id = "RrKillShot",
	name = "Kill Shot",
	description = "+1 damage to enemies that would be killed by the extra damage.",
	reusability = cplus_plus_ex.REUSABLILITY.REUSABLE,
	constraints = {
		groups = {more_plus.GROUPS.ADD_DAMAGE},
	},
	priority = 150, -- go after other calculations
}

-- Initialize logger
customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "KillShot", customSkill.DEBUG)

more_plus:addCustomTraitIcon(customSkill)

function customSkill:modifySpaceDamage(source, attackingPawn, phase, spaceDamage, indexes, targetPawn)
	local numInstances = #indexes

	if source == self.SOURCE_ATTACKER and targetPawn and
			targetPawn:IsEnemy() and spaceDamage.iDamage > 0 and
			spaceDamage.iDamage ~= DAMAGE_DEATH and spaceDamage.iDamage ~= DAMAGE_ZERO then
		local currentHealth = targetPawn:GetHealth()
		local baseDamage = spaceDamage.iDamage
		local totalBonusDamage = numInstances
		local hasBoosted = attackingPawn:IsBoosted()
		local hasAcid = targetPawn:IsAcid()
		local hasArmor = targetPawn:IsArmor()

		local resultDamage = baseDamage + totalBonusDamage

		if hasBoosted then
			resultDamage = resultDamage + 1
		end
		if hasAcid then
			-- Acid doubles ALL damage
			resultDamage = resultDamage * 2
		-- Armor only applies if not acid
		elseif hasArmor then
			resultDamage = resultDamage - 1
		end

		local wouldKillWithExtra = currentHealth <= resultDamage
		if wouldKillWithExtra then
			for _, idx in ipairs(indexes) do
				logger.logDebug(SUBMODULE, "Adding icon for %s with idx %d", spaceDamage.loc:GetString(), idx)
				more_plus.libs.weaponPreview.ExecuteWithState(more_plus.convertPhase(phase),
						function()
							more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc,
									more_plus.commonIcons.extraDamage.key.."_"..idx)
						end)
			end

			spaceDamage.iDamage = spaceDamage.iDamage + totalBonusDamage
			logger.logDebug(SUBMODULE, "Added %d damage to finish off vek at %s ("..
					"health: %d, base damage: %d, final %d, boost: %s, armor: %s, acid: %s)",
					totalBonusDamage, spaceDamage.loc:GetString(), currentHealth, baseDamage, resultDamage, tostring(hasBoosted), tostring(hasArmor), tostring(hasAcid))
		else
			logger.logDebug(SUBMODULE, "No bonus damage - vek at %s would survive ("..
					"health: %d, base damage: %d, final %d, boost: %s, armor: %s, acid: %s)",
					spaceDamage.loc:GetString(), currentHealth, baseDamage, resultDamage, tostring(hasBoosted), tostring(hasArmor), tostring(hasAcid))
		end
	end
end

return customSkill
