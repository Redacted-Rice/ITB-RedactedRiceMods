local customSkill = more_plus.SkillEffectModifier:new{
	id = "RrTrophyHunter",
	name = "Trophy Hunter",
	description = "+1 damage to \"unique\" (non-common) enemies.",
	reusability = cplus_plus_ex.REUSABLILITY.REUSABLE,
	groups = {more_plus.GROUPS.ADD_DAMAGE},
}

-- Initialize logger
customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "TrophyHunter", customSkill.DEBUG)

customSkill:addCustomTrait()

function customSkill:modifySpaceDamage(source, attackingPawn, previewState, spaceDamage, indexes, targetPawn)
	if source == self.SOURCE_ATTACKER and targetPawn and
			targetPawn:IsEnemy() and more_plus.libs.pawnTypeUtils.isSpawnCategory(targetPawn, "Unique") and
			spaceDamage.iDamage > 0 and spaceDamage.iDamage ~= DAMAGE_DEATH and
			spaceDamage.iDamage ~= DAMAGE_ZERO then
		for _, idx in ipairs(indexes) do
			logger.logDebug(SUBMODULE, "Adding icon for %s with idx %d", spaceDamage.loc:GetString(), idx)
			more_plus.libs.weaponPreview.ExecuteWithState(previewState,
					function()
						more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc,
								more_plus.commonIcons.extraDamage.key.."_"..idx)
					end)
			spaceDamage.iDamage = spaceDamage.iDamage + 1
			logger.logDebug(SUBMODULE, "Added +1 damage to unique vek at %s", spaceDamage.loc:GetString())
		end
	end
	return nil
end

return customSkill