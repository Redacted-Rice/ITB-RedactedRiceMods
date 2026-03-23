local customSkill = more_plus.SkillEffectModifier:new{
	id = "RrBigGameHunter",
	name = "Big Game Hunter",
	description = "Doubles damage to boss vek",
	reusability = cplus_plus_ex.REUSABLILITY.REUSABLE,
}

customSkill:addCustomTrait()

function customSkill:modifySpaceDamage(pawn, spaceDamage, indexes)
	local spacePawn = Board:GetPawn(spaceDamage.loc)
	
	if spacePawn and more_plus.libs.pawnTypeUtils.isSpawnCategory(spacePawn, "Boss") and
			spaceDamage.iDamage > 0 and spaceDamage.iDamage ~= DAMAGE_DEATH and
			spaceDamage.iDamage ~= DAMAGE_ZERO then

		for _, idx in ipairs(indexes) do
			more_plus.libs.weaponPreview.ExecuteWithState(more_plus.libs.weaponPreview.STATE_SKILL_EFFECT,
					function()
						more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc, 
								more_plus.commonIcons.crit.key.."_"..idx)
					end)
		end

		spaceDamage.iDamage = spaceDamage.iDamage * 2
	end
end

return customSkill