local customSkill = more_plus.SkillEffectModifier:new{
	id = "RrAnger",
	name = "Anger",
	description = "Gain boosted when piloted mech is directly damaged by an enemy.",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
}

customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Anger", customSkill.DEBUG)

-- Exclude Kai and Morgan as they give boosted already
cplus_plus_ex:registerPilotSkillExclusions("Pilot_Arrogant", customSkill.id)
cplus_plus_ex:registerPilotSkillExclusions("Pilot_Chemical", customSkill.id)

customSkill:addCustomTrait()

function customSkill:modifySpaceDamage(attackingPawn, previewState, spaceDamage, indexes, targetPawn)
	-- Check if target is being damaged by an enemy
	if source == self.SOURCE_TARGET and attackingPawn and attackingPawn:IsEnemy() and
			spaceDamage.iDamage > 0 and spaceDamage.iDamage ~= DAMAGE_ZERO and spaceDamage.iDamage ~= DAMAGE_DEATH then
		if not targetPawn:IsBoosted() then
			for _, idx in ipairs(indexes) do
				logger.logDebug(SUBMODULE, "Adding boost icon for damaged mech at %s with idx %d",
						spaceDamage.loc:GetString(), idx)
				more_plus.libs.weaponPreview.ExecuteWithState(previewState,
						function()
							more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc,
									more_plus.commonIcons.boost.key.."_"..idx)
						end)
			end

			spaceDamage.sScript = spaceDamage.sScript .. string.format("Board:GetPawn(%d):SetBoosted(true)", targetPawn:GetId())
			logger.logDebug(SUBMODULE, "Will grant boosted to damaged mech %d at %s (damage: %d)",
					targetPawn:GetId(), spaceDamage.loc:GetString(), spaceDamage.iDamage)
		else
			logger.logDebug(SUBMODULE, "Mech %d at %s already boosted, skipping",
					targetPawn:GetId(), spaceDamage.loc:GetString())
		end
	end
	return nil
end

return customSkill
