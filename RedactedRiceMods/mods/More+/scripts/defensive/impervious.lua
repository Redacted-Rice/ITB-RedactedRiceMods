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

function customSkill:modifySpaceDamage(pawn, isFinalEffect, spaceDamage, indexes, spacePawn)
	-- Check if the attacker is an ally
	if not pawn then return nil end

	-- Only process if attacker is an ally (including self)
	if pawn:GetTeam() ~= TEAM_MECH then return nil end

	-- Check if the target has the Impervious skill
	if spacePawn and cplus_plus_ex:isSkillOnPawn(customSkill.id, spacePawn) and
	   spaceDamage.iDamage > 0 and spaceDamage.iDamage ~= DAMAGE_DEATH and spaceDamage.iDamage ~= DAMAGE_ZERO then
		-- Show icon
		local previewState = isFinalEffect and more_plus.libs.weaponPreview.STATE_FINAL_EFFECT or
				more_plus.libs.weaponPreview.STATE_SKILL_EFFECT
		for _, idx in ipairs(indexes) do
			more_plus.libs.weaponPreview.ExecuteWithState(previewState,
					function()
						more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc,
								more_plus.commonIcons.noDamage.key.."_"..idx)
					end)
		end
		spaceDamage.iDamage = 0

		logger.logDebug(SUBMODULE, "Blocked ally damage from pawn %d to pawn %d (damage: %d -> 0)",
				pawn:GetId(), spacePawn:GetId(), spaceDamage.iDamage)
	end

	return nil
end

return customSkill
