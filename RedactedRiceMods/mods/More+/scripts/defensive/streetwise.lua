local customSkill = more_plus.SkillEffectModifier:new{
	id = "RrStreetwise",
	name = "Streetwise",
	description = "Prevents (not-instakill) damage to buildings from piloted mech's attacks (direct damage from attack only).",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
}

-- Initialize logger
customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Streetwise", customSkill.DEBUG)

customSkill:addCustomTrait()

function customSkill:modifySpaceDamage(source, attackingPawn, previewState, spaceDamage, indexes, targetPawn)
	if source == self.SOURCE_ATTACKER then
		return nil
	end
	
	if Board:IsBuilding(spaceDamage.loc) and spaceDamage.iDamage > 0 and
			spaceDamage.iDamage ~= DAMAGE_DEATH then

		for _, idx in ipairs(indexes) do
			logger.logDebug(SUBMODULE, "Adding icon for building at %s with idx %d", spaceDamage.loc:GetString(), idx)
			more_plus.libs.weaponPreview.ExecuteWithState(previewState,
					function()
						more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc,
								more_plus.commonIcons.noDamage.key.."_"..idx)
					end)
		end

		spaceDamage.iDamage = DAMAGE_ZERO
		logger.logDebug(SUBMODULE, "Prevented damage to building at %s", spaceDamage.loc:GetString())
	end
	return nil
end

return customSkill
