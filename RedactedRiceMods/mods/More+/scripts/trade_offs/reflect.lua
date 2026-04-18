local customSkill = more_plus.SkillEffectModifier:new{
	id = "RrReflect",
	name = "Reflect",
	description = "If damaged by an enemy, deals half (rounded up) damage back to the attacker.",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
}

customSkill.DEBUG = true
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Reflect", customSkill.DEBUG)

customSkill:addCustomTrait()

function customSkill:modifySpaceDamage(source, attackingPawn, previewState, spaceDamage, indexes, targetPawn)
	-- Check if this is damage from an enemy to a mech
	if source == self.SOURCE_TARGET and attackingPawn and 
			attackingPawn:IsEnemy() and spaceDamage.iDamage > 0 and 
			spaceDamage.iDamage ~= DAMAGE_ZERO then
		local attackerLoc = attackingPawn:GetSpace()
		local targetLoc = targetPawn:GetSpace()
		
		-- Add reflect animation icons
		for _, idx in ipairs(indexes) do
			-- Show damage icon on attacker (where reflect damage will hit)
			logger.logDebug(SUBMODULE, "Adding reflect damage icon from %s to attacker %s with idx %d", 
					targetLoc:GetString(), attackerLoc:GetString(), idx)
			more_plus.libs.weaponPreview.ExecuteWithState(previewState,
					function()
						-- add to attacker and target
						more_plus.libs.weaponPreview:AddAnimation(attackerLoc,
								more_plus.commonIcons.reflect.key.."_"..idx)
						more_plus.libs.weaponPreview:AddAnimation(targetLoc,
								more_plus.commonIcons.reflect.key.."_"..idx)
					end)
		end

		-- Add a pause before reflect damage for visual clarity
		local reflectPause = SpaceDamage(attackerLoc)
		reflectPause.fDelay = 0.3

		-- Handle DAMAGE_DEATH case
		local reflectDamage = 0
		if spaceDamage.iDamage == DAMAGE_DEATH then
			reflectDamage = DAMAGE_DEATH
			logger.logDebug(SUBMODULE, "Reflecting DAMAGE_DEATH back to attacker at %s", attackerLoc:GetString())
		else
			reflectDamage = math.ceil(spaceDamage.iDamage / 2)
			logger.logDebug(SUBMODULE, "Reflecting %d damage back to attacker at %s (original: %d)",
					reflectDamage, attackerLoc:GetString(), spaceDamage.iDamage)
		end
		return {reflectPause, SpaceDamage(attackerLoc, reflectDamage)}
	end

	-- Return nil if no reflection should occur
	return nil
end

return customSkill
