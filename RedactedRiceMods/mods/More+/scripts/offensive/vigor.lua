local customSkill = more_plus.SkillEffectModifier:new{
	id = "RrVigor",
	name = "Vigor",
	description = "Gain boosted when healed.",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
	-- Despite not being able to heal, zoltan can still be healed by an effect and get this
	groups = {more_plus.GROUPS.BOOST},
}

customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Vigor", customSkill.DEBUG)

customSkill:addCustomTrait()

function customSkill:modifySpaceDamage(source, attackingPawn, previewState, spaceDamage, indexes, targetPawn)
	if source == self.SOURCE_TARGET and
			spaceDamage.iDamage < 0 and spaceDamage.iDamage ~= DAMAGE_ZERO and
			spaceDamage.iDamage ~= DAMAGE_DEATH then
		if not targetPawn:IsBoosted() then
			for _, idx in ipairs(indexes) do
				logger.logDebug(SUBMODULE, "Adding boost icon for healed mech at %s with idx %d",
						spaceDamage.loc:GetString(), idx)
				more_plus.libs.weaponPreview.ExecuteWithState(previewState,
						function()
							more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc,
									more_plus.commonIcons.boost.key.."_"..idx)
						end)
			end

			spaceDamage.sScript = spaceDamage.sScript .. string.format(
					"modApi:runLater(function() Board:GetPawn(%d):SetBoosted(true) end)", targetPawn:GetId())
			logger.logDebug(SUBMODULE, "Will grant boosted to healed mech %d at %s (heal amount: %d)",
					targetPawn:GetId(), spaceDamage.loc:GetString(), -spaceDamage.iDamage)
		else
			logger.logDebug(SUBMODULE, "Mech %d at %s already boosted, skipping",
					targetPawn:GetId(), spaceDamage.loc:GetString())
		end
	end
	return nil
end

return customSkill
