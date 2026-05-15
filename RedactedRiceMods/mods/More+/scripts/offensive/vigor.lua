local customSkill = cplus_plus_ex.baseClasses.SkillEffectModifier:new{
	id = "RrVigor",
	name = "Vigor",
	description = "Gain Boost when piloted mech is healed (even if already at full health).",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
	constraints = {
		groups = {more_plus.GROUPS.BOOST},
		-- Despite not being able to heal, zoltan can still be healed by an effect and get this
		pilotExclusions = {"Pilot_Arrogant", "Pilot_Chemical"},
	},
	priority = 180, -- Go after everything else including vampire
}

customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Vigor", customSkill.DEBUG)

more_plus:addCustomTraitIcon(customSkill)

function customSkill:modifySpaceDamage(source, attackingPawn, phase, spaceDamage, indexes, targetPawn)
	if source == self.SOURCE_TARGET and
			spaceDamage.iDamage < 0 and spaceDamage.iDamage ~= DAMAGE_ZERO and
			spaceDamage.iDamage ~= DAMAGE_DEATH then
		if not targetPawn:IsBoosted() then
			local targetId = targetPawn:GetId()
			logger.logDebug(SUBMODULE, "Adding boost icon for healed mech at %s",
					spaceDamage.loc:GetString())
			more_plus.libs.weaponPreview.ExecuteWithState(more_plus.convertPhase(phase),
				function()
					more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc, more_plus.commonIcons.boost.key, nil,  -- delay
							more_plus.WEAPON_PREVIEW_GROUP_ID, customSkill.name .. ": " .. customSkill.description)
				end, targetId
			)

			spaceDamage.sScript = spaceDamage.sScript .. string.format(
					"modApi:runLater(function() Board:GetPawn(%d):SetBoosted(true) end)", targetId)
			logger.logDebug(SUBMODULE, "Will grant boosted to healed mech %d at %s (heal amount: %d)",
					targetId, spaceDamage.loc:GetString(), -spaceDamage.iDamage)
		else
			logger.logDebug(SUBMODULE, "Mech %d at %s already boosted, skipping",
					targetPawn:GetId(), spaceDamage.loc:GetString())
		end
	end
end

return customSkill
