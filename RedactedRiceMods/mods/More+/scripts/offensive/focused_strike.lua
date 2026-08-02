local customSkill = cplus_plus_ex.baseClasses.SkillEffectModifier:new{
	id = "RrFocused",
	name = "Focused Strike",
	description = "Doubles damage to enemies if the piloted mech has not used its movement.",
	reusability = cplus_plus_ex.REUSABLILITY.REUSABLE,
	constraints = {
		groups = {more_plus.GROUPS.ADD_DAMAGE},
	},
	priority = 50, -- go earlier before + dmgs
	modifiesKillDamage = true,
}

-- Initialize logger
customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "FocusedStrike", customSkill.DEBUG)

more_plus:addCustomTraitIcon(customSkill)

function customSkill:modifyKillDamage(source, attackingPawn, spaceDamage, indexes, targetPawn, currentDamage)
	-- If the pawn has used its movement, then return
	if source ~= customSkill.SOURCE_ATTACKER or attackingPawn:IsMovementSpent() then
		return currentDamage
	end
	if targetPawn and targetPawn:IsEnemy() and currentDamage > 0 and currentDamage ~= DAMAGE_DEATH and currentDamage ~= DAMAGE_ZERO then
		return currentDamage * 2
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
			more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc, more_plus.commonIcons.crit.key, nil,  -- delay
					more_plus.WEAPON_PREVIEW_GROUP_ID, GetText(customSkill.name) .. ": " .. GetText(customSkill.description))
		end, attackingPawn:GetId()
	)
	local originalDamage = spaceDamage.iDamage
	spaceDamage.iDamage = newDamage
	logger.logDebug(SUBMODULE, "Doubled damage to enemy at %s from %d to %d (not moved yet)",
			spaceDamage.loc:GetString(), originalDamage, spaceDamage.iDamage)
end

return customSkill
