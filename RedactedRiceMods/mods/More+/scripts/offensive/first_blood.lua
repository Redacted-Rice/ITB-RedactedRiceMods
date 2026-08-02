local customSkill = cplus_plus_ex.baseClasses.SkillEffectModifier:new{
	id = "RrFirstBlood",
	name = "First Blood",
	description = "+1 damage to undamaged enemies with 4+ health.",
	reusability = cplus_plus_ex.REUSABLILITY.REUSABLE,
	constraints = {
		groups = {more_plus.GROUPS.ADD_DAMAGE},
	},
	priority = 80, -- go after doubling
	modifiesKillDamage = true,
}

-- Initialize logger
customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "FirstBlood", customSkill.DEBUG)

more_plus:addCustomTraitIcon(customSkill)

function customSkill:modifyKillDamage(source, attackingPawn, spaceDamage, indexes, targetPawn, currentDamage)
	if source ~= customSkill.SOURCE_ATTACKER or not targetPawn or not targetPawn:IsEnemy() then
		return currentDamage
	end
	if not (currentDamage > 0 and currentDamage ~= DAMAGE_DEATH and currentDamage ~= DAMAGE_ZERO) then
		return currentDamage
	end

	local maxHealth = _G[targetPawn:GetType()].Health
	if targetPawn:GetHealth() >= maxHealth and targetPawn:GetHealth() >= 4 then
		return currentDamage + 1
	end
	return currentDamage
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
	logger.logDebug(SUBMODULE, "Added +1 damage to undamaged vek at %s (health: %d)",
		spaceDamage.loc:GetString(), targetPawn:GetHealth())
end

return customSkill
