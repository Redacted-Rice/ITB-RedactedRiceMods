local customSkill = more_plus.SkillEffectModifier:new{
	id = "RrStreetwise",
	name = "Streetwise",
	description = "Prevents (not-instakill) damage to buildings from mech attacks.",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
}

-- Initialize logger
customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Streetwise", customSkill.DEBUG)

customSkill:addCustomTrait()

function customSkill:modifySpaceDamage(pawn, isFinalEffect, spaceDamage, indexes)
	if Board:IsBuilding(spaceDamage.loc) and
	   spaceDamage.iDamage > 0 and
	   spaceDamage.iDamage ~= DAMAGE_DEATH then
	   
		local previewState = isFinalEffect and more_plus.libs.weaponPreview.STATE_FINAL_EFFECT or
				more_plus.libs.weaponPreview.STATE_SKILL_EFFECT
		for _, idx in ipairs(indexes) do
			logger.logDebug(SUBMODULE, "Adding icon for building at %s with idx %d", spaceDamage.loc:GetString(), idx)
			more_plus.libs.weaponPreview.ExecuteWithState(previewState,
					function()
						more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc,
								more_plus.commonIcons.noDamage.key.."_"..idx)
					end)

			spaceDamage.iDamage = DAMAGE_ZERO
		end
		logger.logDebug(SUBMODULE, "Prevented damage to building at %s", spaceDamage.loc:GetString())
	end
end

return customSkill
