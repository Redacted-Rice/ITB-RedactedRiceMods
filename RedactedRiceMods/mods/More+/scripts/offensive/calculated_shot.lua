local customSkill = more_plus.SkillEffectModifier:new{
	id = "RrCalculatedShot",
	name = "Calculated Shot",
	description = "+1 damage to enemies with two or less move.",
	reusability = cplus_plus_ex.REUSABLILITY.REUSABLE,
}

-- Initialize logger
customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "CalculatedShot", customSkill.DEBUG)

customSkill:addCustomTrait()

function customSkill:modifySpaceDamage(pawn, isFinalEffect, spaceDamage, indexes)
	local handled = false
	local spacePawn = Board:GetPawn(spaceDamage.loc)
	
	if spacePawn and spacePawn:IsEnemy() and spacePawn:GetMoveSpeed() <= 2 and spaceDamage.iDamage > 0 and 
			spaceDamage.iDamage ~= DAMAGE_DEATH and spaceDamage.iDamage ~= DAMAGE_ZERO then
		handled = true
		local moveSpeed = spacePawn:GetMoveSpeed()
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
			logger.logDebug(SUBMODULE, "Added +1 damage to slow target at %s (move speed: %d) for idx %d",
				spaceDamage.loc:GetString(), moveSpeed, idx)
		end
	end
	return handled
end

return customSkill