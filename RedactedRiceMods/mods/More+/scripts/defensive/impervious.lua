local customSkill = more_plus.SkillEffectModifier:new{
	id = "RrImpervious",
	name = "Impervious",
	description = "Cannot take non-instakill damage from self or allies.",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
}

customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Impervious", customSkill.DEBUG)

customSkill:addCustomTrait()

function customSkill:modifySpaceDamage(attackingPawn, previewState, spaceDamage, indexes, targetPawn)
	-- Only process if attacker is an ally (but not self) and target is taking damage
	if attackingPawn and attackingPawn:GetTeam() == TEAM_MECH and
	    	spaceDamage.iDamage > 0 and spaceDamage.iDamage ~= DAMAGE_DEATH and spaceDamage.iDamage ~= DAMAGE_ZERO then

		-- Show icon
		for _, idx in ipairs(indexes) do
			more_plus.libs.weaponPreview.ExecuteWithState(previewState,
					function()
						more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc,
								more_plus.commonIcons.noDamage.key.."_"..idx)
					end)
		end
		local oldDamage = spaceDamage.iDamage
		spaceDamage.iDamage = DAMAGE_ZERO
		logger.logDebug(SUBMODULE, "Blocked ally damage from pawn %d to pawn %d (damage: %d -> DAMAGE_ZERO)",
				attackingPawn:GetId(), targetPawn:GetId(), oldDamage)
	end
	return nil
end

return customSkill
