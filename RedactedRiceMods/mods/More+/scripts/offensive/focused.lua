local customSkill = more_plus.SkillEffectModifier:new{
	id = "RrFocused",
	name = "Focused",
	description = "Deal +1 Damage if you have not moved yet",
	reusability = cplus_plus_ex.REUSABLILITY.REUSABLE,
}

customSkill:addCustomTrait()

function customSkill:modifySpaceDamage(pawn, isFinalEffect, spaceDamage, indexes)
	-- If the pawn has used its movement, then return
	if pawn:IsMovementSpent() then
		--LOG("Pawn ".. pawn:GetId().." already moved")
		return
	end
	
	if spaceDamage.iDamage > 0 and spaceDamage.iDamage ~= DAMAGE_DEATH and 
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
			--LOG("Focused: Added +1 damage enemy at ".. spaceDamage.loc:GetString())
		end
	end
end

return customSkill

