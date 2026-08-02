local customSkill = cplus_plus_ex.baseClasses.SkillEffectModifier:new{
	id = "RrKillShot",
	name = "Kill Shot",
	description = "+1 damage to enemies that would be killed by the extra damage.",
	reusability = cplus_plus_ex.REUSABLILITY.REUSABLE,
	constraints = {
		groups = {more_plus.GROUPS.ADD_DAMAGE},
	},
	priority = 150, -- go after other calculations
	modifiesKillDamage = true,
}

-- Initialize logger
customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "KillShot", customSkill.DEBUG)

more_plus:addCustomTraitIcon(customSkill)

function customSkill:modifyKillDamage(source, attackingPawn, spaceDamage, indexes, targetPawn, currentDamage)
	if source ~= customSkill.SOURCE_ATTACKER or not targetPawn or not targetPawn:IsEnemy() then
		return currentDamage
	end
	if not (currentDamage > 0 and currentDamage ~= DAMAGE_DEATH and currentDamage ~= DAMAGE_ZERO) then
		return currentDamage
	end

	local currentHealth = targetPawn:GetHealth()
	local totalBonusDamage = #indexes
	local hasBoosted = attackingPawn:IsBoosted()
	local hasAcid = targetPawn:IsAcid()
	local hasArmor = targetPawn:IsArmor()
	local resultDamage = currentDamage + totalBonusDamage
	if attackingPawn:IsBoosted() then
		resultDamage = resultDamage + 1
	end
	if targetPawn:IsAcid() then
		-- Acid doubles ALL damage
		resultDamage = resultDamage * 2
	-- Armor only applies if not acid
	elseif targetPawn:IsArmor() then
		resultDamage = resultDamage - 1
	end
	if currentHealth > resultDamage then
		logger.logDebug(SUBMODULE, "No bonus damage - vek at %s would survive ("..
				"health: %d, base damage: %d, final %d, boost: %s, armor: %s, acid: %s)",
				spaceDamage and spaceDamage.loc:GetString() or "?", currentHealth, currentDamage, resultDamage,
				tostring(hasBoosted), tostring(hasArmor), tostring(hasAcid))
		return currentDamage
	end
	return currentDamage + totalBonusDamage
end

function customSkill:modifySpaceDamage(source, attackingPawn, phase, spaceDamage, indexes, targetPawn)
	local newDamage = self:modifyKillDamage(source, attackingPawn, spaceDamage, indexes, targetPawn, spaceDamage.iDamage)
	if newDamage == spaceDamage.iDamage then
		return
	end

	logger.logDebug(SUBMODULE, "Adding icon for %s", spaceDamage.loc:GetString())
	more_plus.libs.weaponPreview.ExecuteWithState(more_plus.convertPhase(phase),
		function()
			more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc, more_plus.commonIcons.extraDamage.key, nil,  -- delay
					more_plus.WEAPON_PREVIEW_GROUP_ID, GetText(customSkill.name) .. ": " .. GetText(customSkill.description))
		end, attackingPawn:GetId()
	)

	spaceDamage.iDamage = newDamage
	local currentHealth = targetPawn:GetHealth()
	local hasBoosted = attackingPawn:IsBoosted()
	local hasAcid = targetPawn:IsAcid()
	local hasArmor = targetPawn:IsArmor()
	local resultDamage = spaceDamage.iDamage
	if attackingPawn:IsBoosted() then
		resultDamage = resultDamage + 1
	end
	if targetPawn:IsAcid() then
		-- Acid doubles ALL damage
		resultDamage = resultDamage * 2
	-- Armor only applies if not acid
	elseif targetPawn:IsArmor() then
		resultDamage = resultDamage - 1
	end
	logger.logDebug(SUBMODULE, "Added %d damage to finish off vek at %s ("..
			"health: %d, base damage: %d, final %d, boost: %s, armor: %s, acid: %s)",
			#indexes, spaceDamage.loc:GetString(), currentHealth, spaceDamage.iDamage - #indexes, resultDamage,
			tostring(hasBoosted), tostring(hasArmor), tostring(hasAcid))
end

return customSkill
