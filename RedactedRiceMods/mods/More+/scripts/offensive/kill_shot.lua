local customSkill = more_plus.SkillEffectModifier:new{
	id = "RrKillShot",
	name = "Kill Shot",
	description = "+1 damage if the vek would be killed",
	reusability = cplus_plus_ex.REUSABLILITY.REUSABLE,
}

customSkill:addCustomTrait()

function customSkill:modifySpaceDamage(pawn, spaceDamage, indexes)
	local numInstances = #indexes
	local spacePawn = Board:GetPawn(spaceDamage.loc)
	
	if spacePawn and spacePawn:IsEnemy() and
			spaceDamage.iDamage > 0 and spaceDamage.iDamage ~= DAMAGE_DEATH and
			spaceDamage.iDamage ~= DAMAGE_ZERO then

		local currentHealth = spacePawn:GetHealth()
		local totalBonusDamage = numInstances
		local wouldKillWithExtra = (currentHealth - (spaceDamage.iDamage + totalBonusDamage)) <= 0

		if wouldKillWithExtra then
			for _, idx in ipairs(indexes) do
				more_plus.libs.weaponPreview.ExecuteWithState(more_plus.libs.weaponPreview.STATE_SKILL_EFFECT,
						function()
							more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc,
									more_plus.commonIcons.extraDamage.key.."_"..idx)
						end)
			end

			spaceDamage.iDamage = spaceDamage.iDamage + totalBonusDamage
			LOG("Kill Shot: Added +" .. totalBonusDamage .. " damage to finish off vek at ".. spaceDamage.loc:GetString() .. " (" .. numInstances .. " instances)")
		end
	end
end

return customSkill
