local customSkill = cplus_plus_ex.baseClasses.SkillEffectModifier:new{
	id = "RrBigGameHunter",
	name = "Big Game Hunter",
	description = "Doubles damage to boss vek.",
	reusability = cplus_plus_ex.REUSABLILITY.REUSABLE,
	constraints = {
		groups = {more_plus.GROUPS.ADD_DAMAGE},
	},
	priority = 50 -- go earlier before + dmgs
}

-- Initialize logger
customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "BigGameHunter", customSkill.DEBUG)

more_plus:addCustomTraitIcon(customSkill)

function customSkill:modifySpaceDamage(source, attackingPawn, phase, spaceDamage, indexes, targetPawn)
	if source == self.SOURCE_ATTACKER and targetPawn and
			more_plus.libs.pawnTypeUtils.isSpawnCategory(targetPawn, "Boss") and
			spaceDamage.iDamage > 0 and spaceDamage.iDamage ~= DAMAGE_DEATH and
			spaceDamage.iDamage ~= DAMAGE_ZERO then
		local originalDamage = spaceDamage.iDamage
		logger.logDebug(SUBMODULE, "Adding icon for %s", spaceDamage.loc:GetString())
		more_plus.libs.weaponPreview.ExecuteWithState(more_plus.convertPhase(phase),
			function()
				more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc, more_plus.commonIcons.crit.key, nil,  -- delay
						more_plus.WEAPON_PREVIEW_GROUP_ID, GetText(customSkill.name) .. ": " .. GetText(customSkill.description))
			end, attackingPawn:GetId()
		)
		spaceDamage.iDamage = spaceDamage.iDamage * 2
		logger.logDebug(SUBMODULE, "Doubled damage to boss at %s from %d to %d",
				spaceDamage.loc:GetString(), originalDamage, spaceDamage.iDamage)
	end
end

return customSkill