local customSkill = cplus_plus_ex.baseClasses.SkillEffectModifier:new{
	id = "RrVampire",
	name = "Vampire",
	description = "Repair (regardless of pilot repair skill) piloted mech when you kill a vek.",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
	-- Zoltan only has 1 health
	constraints = {
		pilotExclusions = {"Pilot_Zoltan"},
	},
	priority = 180, -- go after kill shot
}

customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Vampire", customSkill.DEBUG)

more_plus:addCustomTraitIcon(customSkill)

function customSkill:modifySpaceDamage(source, attackingPawn, phase, spaceDamage, indexes, targetPawn)
	if source == self.SOURCE_ATTACKER and targetPawn and
			targetPawn:IsEnemy() and spaceDamage.iDamage > 0 and
			spaceDamage.iDamage ~= DAMAGE_ZERO then
		local wouldKill = false
		if spaceDamage.iDamage == DAMAGE_DEATH then
			wouldKill = true
			logger.logDebug(SUBMODULE, "Repair added - instakill vek at %s",
					spaceDamage.loc:GetString())
		else
			local currentHealth = targetPawn:GetHealth()
			local baseDamage = spaceDamage.iDamage
			local hasBoosted = attackingPawn:IsBoosted()
			local hasAcid = targetPawn:IsAcid()
			local hasArmor = targetPawn:IsArmor()
			local resultDamage = baseDamage

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

			if currentHealth <= resultDamage then
				wouldKill = true
				logger.logDebug(SUBMODULE, "Repair added - will kill vek at %s ("..
						"health: %d, base damage: %d, final %d, boost: %s, armor: %s, acid: %s)",
						spaceDamage.loc:GetString(), currentHealth, baseDamage, resultDamage, tostring(hasBoosted), tostring(hasArmor), tostring(hasAcid))
			else
				logger.logDebug(SUBMODULE, "No repair - vek at %s would survive ("..
						"health: %d, base damage: %d, final %d, boost: %s, armor: %s, acid: %s)",
						spaceDamage.loc:GetString(), currentHealth, baseDamage, resultDamage, tostring(hasBoosted), tostring(hasArmor), tostring(hasAcid))
			end
		end

		if wouldKill then
			local attackerLoc = self:getPawnSpace(attackingPawn)
			local targetLoc = self:getPawnSpace(targetPawn)

			-- Add vampire animation icons
			for _, idx in ipairs(indexes) do
				-- Show damage icon on attacker and target
				logger.logDebug(SUBMODULE, "Adding vampire damage icon from %s to attacker %s with idx %d",
						targetLoc:GetString(), attackerLoc:GetString(), idx)
				more_plus.libs.weaponPreview.ExecuteWithState(more_plus.convertPhase(phase),
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
