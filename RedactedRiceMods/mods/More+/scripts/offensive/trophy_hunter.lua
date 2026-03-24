local customSkill = more_plus.SkillEffectModifier:new{
	id = "RrTrophyHunter",
	name = "Trophy Hunter",
	description = "+1 damage to unique vek",
	reusability = cplus_plus_ex.REUSABLILITY.REUSABLE,
}

customSkill:addCustomTrait()

function customSkill:modifySpaceDamage(pawn, isFinalEffect, spaceDamage, indexes)
	local spacePawn = Board:GetPawn(spaceDamage.loc)
	
	if spacePawn and more_plus.libs.pawnTypeUtils.isSpawnCategory(spacePawn, "Unique") and
			spaceDamage.iDamage > 0 and spaceDamage.iDamage ~= DAMAGE_DEATH and
			spaceDamage.iDamage ~= DAMAGE_ZERO then

		local previewState = isFinalEffect and more_plus.libs.weaponPreview.STATE_FINAL_EFFECT or
				more_plus.libs.weaponPreview.STATE_SKILL_EFFECT
		for _, idx in ipairs(indexes) do
			more_plus.libs.weaponPreview.ExecuteWithState(previewState,
					function() 
						more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc, 
								more_plus.commonIcons.extraDamage.key.."_"..idx)
					end)

			spaceDamage.iDamage = spaceDamage.iDamage + 1
		end
	end
end

return customSkill