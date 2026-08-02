local customSkill = cplus_plus_ex.baseClasses.SkillEffectModifier:new{
	id = "RrStreetwise",
	name = "Streetwise",
	description = "Prevents (not-instakill) damage to buildings from piloted mech's attacks (direct damage from attack only).",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
	modifiesKillDamage = true,
}

-- Initialize logger
customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Streetwise", customSkill.DEBUG)

more_plus:addCustomTraitIcon(customSkill)

function customSkill:modifyKillDamage(source, attackingPawn, spaceDamage, indexes, targetPawn, currentDamage)
	if source ~= customSkill.SOURCE_ATTACKER then
		return currentDamage
	end
	if Board:IsBuilding(spaceDamage.loc) and currentDamage > 0 and currentDamage ~= DAMAGE_DEATH and currentDamage ~= DAMAGE_ZERO then
		return DAMAGE_ZERO
	end
	return currentDamage
end

function customSkill:modifySpaceDamage(source, attackingPawn, phase, spaceDamage, indexes, targetPawn)
	local newDamage = self:modifyKillDamage(source, attackingPawn, spaceDamage, indexes, targetPawn, spaceDamage.iDamage)
	if newDamage == spaceDamage.iDamage then
		return
	end

	logger.logDebug(SUBMODULE, "Adding icon for building at %s", spaceDamage.loc:GetString())
	more_plus.libs.weaponPreview.ExecuteWithState(more_plus.convertPhase(phase),
		function()
			more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc, more_plus.commonIcons.noDamage.key, nil,  -- delay
					more_plus.WEAPON_PREVIEW_GROUP_ID, GetText(customSkill.name) .. ": " .. GetText(customSkill.description))
		end, attackingPawn:GetId()
	)
	spaceDamage.iDamage = newDamage
	logger.logDebug(SUBMODULE, "Prevented damage to building at %s", spaceDamage.loc:GetString())
end

return customSkill
