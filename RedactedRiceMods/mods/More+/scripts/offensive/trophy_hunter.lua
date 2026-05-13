local customSkill = cplus_plus_ex.baseClasses.SkillEffectModifier:new{
	id = "RrTrophyHunter",
	name = "Trophy Hunter",
	description = "+1 damage to \"unique\" (non-common) enemies.",
	reusability = cplus_plus_ex.REUSABLILITY.REUSABLE,
	constraints = {
		groups = {more_plus.GROUPS.ADD_DAMAGE},
	},
	priority = 80 -- go after doubling
}

-- Initialize logger
customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "TrophyHunter", customSkill.DEBUG)

more_plus:addCustomTraitIcon(customSkill)

function customSkill:modifySpaceDamage(source, attackingPawn, phase, spaceDamage, indexes, targetPawn)
	if source == self.SOURCE_ATTACKER and targetPawn and
			targetPawn:IsEnemy() and more_plus.libs.pawnTypeUtils.isSpawnCategory(targetPawn, "Unique") and
			spaceDamage.iDamage > 0 and spaceDamage.iDamage ~= DAMAGE_DEATH and
			spaceDamage.iDamage ~= DAMAGE_ZERO then
		logger.logDebug(SUBMODULE, "Adding icon for %s", spaceDamage.loc:GetString())
		more_plus.libs.weaponPreview.ExecuteWithState(more_plus.convertPhase(phase),
			function()
				more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc, more_plus.commonIcons.extraDamage.key, nil,  -- delay
						more_plus.WEAPON_PREVIEW_GROUP_ID)
			end, attackingPawn:GetId()
		)
		spaceDamage.iDamage = spaceDamage.iDamage + 1
		logger.logDebug(SUBMODULE, "Added +1 damage to unique vek at %s", spaceDamage.loc:GetString())
	end
end

return customSkill