local customSkill = more_plus.SkillEffectModifier:new{
	id = "RrFocused",
	name = "Focused",
	description = "+1 Damage to enemies if the mech has not used its movement yet.",
	reusability = cplus_plus_ex.REUSABLILITY.REUSABLE,
}

-- Initialize logger
customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Focused", customSkill.DEBUG)

customSkill:addCustomTrait()

-- Exclude Kai and Morgan as they give boosted already
cplus_plus_ex:registerPilotSkillExclusions("Pilot_Arrogant", customSkill.id)
cplus_plus_ex:registerPilotSkillExclusions("Pilot_Chemical", customSkill.id)

function customSkill:modifySpaceDamage(pawn, isFinalEffect, spaceDamage, indexes)
	-- If the pawn has used its movement, then return
	if pawn:IsMovementSpent() then
		logger.logDebug(SUBMODULE, "Pawn %d already moved, no bonus damage", pawn:GetId())
		return
	end
	local spacePawn = Board:GetPawn(spaceDamage.loc)
	if spacePawn and spacePawn:IsEnemy() and
			spaceDamage.iDamage > 0 and spaceDamage.iDamage ~= DAMAGE_DEATH and
			spaceDamage.iDamage ~= DAMAGE_ZERO then
		local previewState = isFinalEffect and more_plus.libs.weaponPreview.STATE_FINAL_EFFECT or
				more_plus.libs.weaponPreview.STATE_SKILL_EFFECT
		for _, idx in ipairs(indexes) do
			logger.logDebug(SUBMODULE, "Adding icon for %s with idx %d", spaceDamage.loc:GetString(), idx)
			more_plus.libs.weaponPreview.ExecuteWithState(previewState,
					function()
						more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc,
								more_plus.commonIcons.extraDamage.key.."_"..idx)
					end)

			spaceDamage.iDamage = spaceDamage.iDamage + 1
			logger.logDebug(SUBMODULE, "Added +1 damage to enemy at %s (not moved yet) for idx %d",
					spaceDamage.loc:GetString(), idx)
		end
	end
end

return customSkill

