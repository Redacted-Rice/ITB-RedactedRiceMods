local customSkill = more_plus.SkillEffectModifier:new{
	id = "RrFocused",
	name = "Focused Strike",
	description = "Doubles damage to enemies if the piloted mech has not used its movement.",
	reusability = cplus_plus_ex.REUSABLILITY.REUSABLE,
	groups = {more_plus.GROUPS.ADD_DAMAGE},
}

-- Initialize logger
customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "FocusedStrike", customSkill.DEBUG)

customSkill:addCustomTrait()

function customSkill:modifySpaceDamage(source, attackingPawn, previewState, spaceDamage, indexes, targetPawn)
	if source ~= self.SOURCE_ATTACKER then
		return nil
	end

	-- If the pawn has used its movement, then return
	if attackingPawn:IsMovementSpent() then
		logger.logDebug(SUBMODULE, "Pawn %d already moved, no bonus damage", attackingPawn:GetId())
		return nil
	end

	if targetPawn and targetPawn:IsEnemy() and
			spaceDamage.iDamage > 0 and spaceDamage.iDamage ~= DAMAGE_DEATH and
			spaceDamage.iDamage ~= DAMAGE_ZERO then
		for _, idx in ipairs(indexes) do
			logger.logDebug(SUBMODULE, "Adding icon for %s with idx %d", spaceDamage.loc:GetString(), idx)
			more_plus.libs.weaponPreview.ExecuteWithState(previewState,
					function()
						more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc,
								more_plus.commonIcons.crit.key.."_"..idx)
					end)
			local originalDamage = spaceDamage.iDamage
			spaceDamage.iDamage = spaceDamage.iDamage * 2
			logger.logDebug(SUBMODULE, "Doubled damage to enemy at %s from %d to %d (not moved yet)",
					spaceDamage.loc:GetString(), originalDamage, spaceDamage.iDamage)
		end
	end
	return nil
end

return customSkill

