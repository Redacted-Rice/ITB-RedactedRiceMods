local customSkill = more_plus.SkillEffectModifier:new{
	id = "RrBigGameHunter",
	name = "Big Game Hunter",
	description = "Doubles damage to boss vek.",
	reusability = cplus_plus_ex.REUSABLILITY.REUSABLE,
}

-- Initialize logger
customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "BigGameHunter", customSkill.DEBUG)

customSkill:addCustomTrait()

function customSkill:modifySpaceDamage(pawn, isFinalEffect, spaceDamage, indexes)
	local handled = false
	local spacePawn = Board:GetPawn(spaceDamage.loc)

	if spacePawn and more_plus.libs.pawnTypeUtils.isSpawnCategory(spacePawn, "Boss") and
			spaceDamage.iDamage > 0 and spaceDamage.iDamage ~= DAMAGE_DEATH and
			spaceDamage.iDamage ~= DAMAGE_ZERO then
		handled = true
		local originalDamage = spaceDamage.iDamage
		local previewState = isFinalEffect and more_plus.libs.weaponPreview.STATE_FINAL_EFFECT or
				more_plus.libs.weaponPreview.STATE_SKILL_EFFECT
		for _, idx in ipairs(indexes) do
			logger.logDebug(SUBMODULE, "Adding icon for %s with idx %d", spaceDamage.loc:GetString(), idx)
			more_plus.libs.weaponPreview.ExecuteWithState(previewState,
					function()
						more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc,
								more_plus.commonIcons.crit.key.."_"..idx)
					end)

			spaceDamage.iDamage = spaceDamage.iDamage * 2
			logger.logDebug(SUBMODULE, "Doubled damage to boss at %s from %d to %d for idx %d",
				spaceDamage.loc:GetString(), originalDamage, spaceDamage.iDamage, idx)
		end
	end
	return handled
end

return customSkill