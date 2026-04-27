local customSkill = cplus_plus_ex.baseClasses.SkillEffectModifier:new{
	id = "RrCalculatedShot",
	name = "Calculated Shot",
	description = "+1 damage to enemies with movement <= to half (rounded up) the piloted mech's movement.",
	reusability = cplus_plus_ex.REUSABLILITY.REUSABLE,
	constraints = {
		groups = {more_plus.GROUPS.ADD_DAMAGE},
	},
	priority = 80 -- go after doubling
}

-- Initialize logger
customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "CalculatedShot", customSkill.DEBUG)

customSkill:addCustomTrait()

function customSkill:modifySpaceDamage(source, attackingPawn, phase, spaceDamage, indexes, targetPawn)
	if source ~= self.SOURCE_ATTACKER then
		return nil
	end

	local mechMoveSpeed = attackingPawn:GetMoveSpeed()
	local moveThreshold = math.ceil(mechMoveSpeed / 2)

	if targetPawn and targetPawn:IsEnemy() and targetPawn:GetMoveSpeed() <= moveThreshold and spaceDamage.iDamage > 0 and
			spaceDamage.iDamage ~= DAMAGE_DEATH and spaceDamage.iDamage ~= DAMAGE_ZERO then
		local moveSpeed = targetPawn:GetMoveSpeed()
		for _, idx in ipairs(indexes) do
			logger.logDebug(SUBMODULE, "Adding icon for %s with idx %d", spaceDamage.loc:GetString(), idx)
			more_plus.libs.weaponPreview.ExecuteWithState(more_plus.convertPhase(phase),
					function()
						more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc,
								more_plus.commonIcons.extraDamage.key.."_"..idx)
					end)
			spaceDamage.iDamage = spaceDamage.iDamage + 1
			logger.logDebug(SUBMODULE, "Added +1 damage to slow target at %s (enemy move: %d, mech move: %d, threshold: %d)",
					spaceDamage.loc:GetString(), moveSpeed, mechMoveSpeed, moveThreshold)
		end
	end
	return nil
end

return customSkill