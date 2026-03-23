local customSkill = more_plus.SkillEffectModifier:new{
	id = "RrStreetwise",
	name = "Streetwise",
	description = "Prevents non-fatal damage to buildings from weapon attacks",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
}

customSkill:addCustomTrait()

function customSkill:modifySpaceDamage(pawn, spaceDamage, indexes)
	if Board:IsBuilding(spaceDamage.loc) and
	   spaceDamage.iDamage > 0 and
	   spaceDamage.iDamage ~= DAMAGE_DEATH then
	   
		for _, idx in ipairs(indexes) do
			more_plus.libs.weaponPreview.ExecuteWithState(more_plus.libs.weaponPreview.STATE_SKILL_EFFECT,
					function()
						more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc,
								more_plus.commonIcons.noDamage.key.."_"..idx)
					end)

			spaceDamage.iDamage = DAMAGE_ZERO
		end
	end
end

return customSkill
