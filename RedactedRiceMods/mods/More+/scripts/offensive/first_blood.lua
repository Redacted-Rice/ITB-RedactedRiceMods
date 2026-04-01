local customSkill = more_plus.SkillEffectModifier:new{
	id = "RrFirstBlood",
	name = "First Blood",
	description = "+1 damage to undamaged enemies with 4+ health.",
	reusability = cplus_plus_ex.REUSABLILITY.REUSABLE,
}

-- Initialize logger
customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "FirstBlood", customSkill.DEBUG)

customSkill:addCustomTrait()

function customSkill:modifySpaceDamage(pawn, isFinalEffect, spaceDamage, indexes)
	local spacePawn = Board:GetPawn(spaceDamage.loc)

	local maxHealth = _G[spacePawn:GetType()].Health
	if spacePawn and spacePawn:IsEnemy() and spacePawn:GetHealth() == maxHealth and
			maxHealth >= 4 and spaceDamage.iDamage > 0 and
			spaceDamage.iDamage ~= DAMAGE_DEATH and spaceDamage.iDamage ~= DAMAGE_ZERO then
		local previewState = isFinalEffect and more_plus.libs.weaponPreview.STATE_FINAL_EFFECT or
				more_plus.libs.weaponPreview.STATE_SKILL_EFFECT
		for _, idx in ipairs(indexes) do
			logger.logDebug(SUBMODULE, "Adding icon for %s with idx %d", spaceDamage.loc:GetString(), idx)
			more_plus.libs.weaponPreview.ExecuteWithState(previewState,
					function()
						more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc,
								more_plus.commonIcons.extraDamage.key.."_"..idx)
					end)

			spaceDamage.iDamage = spaceDamage.iDamage + 1
			logger.logDebug(SUBMODULE, "Added +1 damage to undamaged vek at %s (health: %d/%d) for idx %d",
				spaceDamage.loc:GetString(), spacePawn:GetHealth(), maxHealth, idx)
		end
	end
end

return customSkill
