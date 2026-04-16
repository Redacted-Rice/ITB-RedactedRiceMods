local customSkill = more_plus.SkillEffectModifier:new{
	id = "RrFirstBlood",
	name = "First Blood",
	description = "+1 damage to undamaged enemies with 4+ health.",
	reusability = cplus_plus_ex.REUSABLILITY.REUSABLE,
	groups = {more_plus.GROUPS.ADD_DAMAGE},
}

-- Initialize logger
customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "FirstBlood", customSkill.DEBUG)

customSkill:addCustomTrait()

function customSkill:modifySpaceDamage(source, attackingPawn, previewState, spaceDamage, indexes, targetPawn)
	if source == self.SOURCE_ATTACKER and targetPawn and
			targetPawn:IsEnemy() then
		local maxHealth = _G[targetPawn:GetType()].Health
		if targetPawn:GetHealth() == maxHealth and maxHealth >= 4 and spaceDamage.iDamage > 0 and
				spaceDamage.iDamage ~= DAMAGE_DEATH and spaceDamage.iDamage ~= DAMAGE_ZERO then
			for _, idx in ipairs(indexes) do
				logger.logDebug(SUBMODULE, "Adding icon for %s with idx %d", spaceDamage.loc:GetString(), idx)
				more_plus.libs.weaponPreview.ExecuteWithState(previewState,
						function()
							more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc,
									more_plus.commonIcons.extraDamage.key.."_"..idx)
						end)
				spaceDamage.iDamage = spaceDamage.iDamage + 1
				logger.logDebug(SUBMODULE, "Added +1 damage to undamaged vek at %s (health: %d/%d)",
					spaceDamage.loc:GetString(), targetPawn:GetHealth(), maxHealth)
			end
		end
	end
	return nil
end

return customSkill
