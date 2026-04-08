local customSkill = more_plus.SkillEffectModifier:new{
	id = "RrVindictive",
	name = "Vindictive",
	description = "+1 damage for each negative status effect on piloted mech.",
	reusability = cplus_plus_ex.REUSABLILITY.REUSABLE,
}

customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Vindictive", customSkill.DEBUG)

customSkill:addCustomTrait()

function customSkill:modifySpaceDamage(pawn, isFinalEffect, spaceDamage, indexes, spacePawn)
	-- Check if this is actual damage being dealt
	if spacePawn and spacePawn:IsEnemy() and spaceDamage.iDamage > 0 and
			spaceDamage.iDamage ~= DAMAGE_DEATH and spaceDamage.iDamage ~= DAMAGE_ZERO then
		local damage = 0
		local hasFire = pawn:IsFire()
		local hasAcid = pawn:IsAcid()
		if hasFire then
			damage = damage + 1
		end
		if hasAcid then
			damage = damage + 1
		end

		-- Check if the attacking pawn has any status effect
		if damage > 0 then
			local previewState = isFinalEffect and more_plus.libs.weaponPreview.STATE_FINAL_EFFECT or
					more_plus.libs.weaponPreview.STATE_SKILL_EFFECT

			for _, idx in ipairs(indexes) do
				logger.logDebug(SUBMODULE, "Adding vindictive damage icon for %s with idx %d",
						spaceDamage.loc:GetString(), idx)
				more_plus.libs.weaponPreview.ExecuteWithState(previewState,
						function()
							more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc,
									more_plus.commonIcons.extraDamage.key.."_"..idx)
						end)
			end

			spaceDamage.iDamage = spaceDamage.iDamage + damage
			logger.logDebug(SUBMODULE, "Added +%d vindictive damage (pawn %d is statused: fire=%s, acid=%s)",
					damage, pawn:GetId(), tostring(hasFire), tostring(hasAcid))
		end
	end

	return nil
end

return customSkill
