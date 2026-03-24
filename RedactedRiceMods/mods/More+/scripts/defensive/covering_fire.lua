local customSkill = more_plus.SkillEffectModifier:new{
	id = "RrCoveringFire",
	name = "Covering Fire",
	description = "Damaged targets have movement reduced to half base movement (rounded down)",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
}

customSkill:addCustomTrait()

function customSkill:modifySpaceDamage(pawn, isFinalEffect, spaceDamage, indexes)
	local targetPawn = Board:GetPawn(spaceDamage.loc)
	
	if targetPawn and targetPawn:IsEnemy() and
			spaceDamage.iDamage > 0 and spaceDamage.iDamage ~= DAMAGE_DEATH and
			spaceDamage.iDamage ~= DAMAGE_ZERO then

		local previewState = isFinalEffect and more_plus.libs.weaponPreview.STATE_FINAL_EFFECT or
				more_plus.libs.weaponPreview.STATE_SKILL_EFFECT
		for _, idx in ipairs(indexes) do
			more_plus.libs.weaponPreview.ExecuteWithState(previewState,
					function()
						more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc,
								more_plus.commonIcons.shackle.key.."_"..idx)
					end)
		end

		local baseMoveSpeed = _G[targetPawn:GetType()].MoveSpeed
		local targetMoveSpeed = math.floor(baseMoveSpeed / 2)
		local moveReduction = targetPawn:GetMoveSpeed() - targetMoveSpeed
		
		spaceDamage.sScript = "Board:GetPawn("..targetPawn:GetId().."):AddMoveBonus(-"..moveReduction..")"
		LOG("Covering Fire: Will reduce movement of enemy at " .. spaceDamage.loc:GetString() .. " to " .. targetMoveSpeed .. " (base: " .. baseMoveSpeed .. ", reduction: " .. moveReduction .. ")")
	end
end

return customSkill