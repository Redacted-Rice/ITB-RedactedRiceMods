local customSkill = more_plus.SkillEffectModifier:new{
	id = "RrReflect",
	name = "Reflect",
	description = "If damaged by an enemy, deals half (rounded up) back to the attacker.",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
}

customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Reflect", customSkill.DEBUG)

customSkill:addCustomTrait()

function customSkill:modifySpaceDamage(pawn, isFinalEffect, spaceDamage, indexes, spacePawn)
	-- Check if this is damage to a mech with the reflect skill
	if spacePawn and spacePawn:IsMech() and spaceDamage.iDamage > 0 and spaceDamage.iDamage ~= DAMAGE_ZERO then
		local pilot = spacePawn:GetPilot()
		if pilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) then
			if pawn and pawn:IsEnemy() then
				local attackerLoc = pawn:GetSpace()
				local defenderLoc = spacePawn:GetSpace()
				
				-- Determine preview state for animations
				local previewState = isFinalEffect and more_plus.libs.weaponPreview.STATE_FINAL_EFFECT or
						more_plus.libs.weaponPreview.STATE_SKILL_EFFECT
				
				-- Add reflect animation icons
				for _, idx in ipairs(indexes) do
					-- Show damage icon on attacker (where reflect damage will hit)
					logger.logDebug(SUBMODULE, "Adding reflect damage icon at attacker %s with idx %d", 
						attackerLoc:GetString(), idx)
					more_plus.libs.weaponPreview.ExecuteWithState(previewState,
							function()
								more_plus.libs.weaponPreview:AddAnimation(attackerLoc,
										more_plus.commonIcons.extraDamage.key.."_"..idx)
							end)
				end

				-- Add a pause before reflect damage for visual clarity
				local reflectPause = SpaceDamage(attackerLoc, DAMAGE_ZERO)
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
				
				local reflectSpaceDamage = SpaceDamage(attackerLoc, reflectDamage)

				return {reflectPause, reflectSpaceDamage}
			end
		end
	end

	-- Return nil if no reflection should occur
	return nil
end

return customSkill
