local customSkill = cplus_plus_ex.baseClasses.SkillEffectModifier:new{
	id = "RrAnger",
	name = "Anger",
	description = "Gain boosted when piloted mech is directly damaged by an enemy.",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
	constraints = {
		groups = {more_plus.GROUPS.BOOST},
		pilotExclusions = {"Pilot_Arrogant", "Pilot_Chemical", "Pilot_Zoltan"},
	},
	priority = 200 -- go after any adjustments
}

customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Anger", customSkill.DEBUG)

more_plus:addCustomTraitIcon(customSkill)

function customSkill:modifySpaceDamage(source, attackingPawn, phase, spaceDamage, indexes, targetPawn)
	-- Check if target is being damaged by an enemy
	if source == self.SOURCE_TARGET and attackingPawn and attackingPawn:IsEnemy() and
			spaceDamage.iDamage > 0 and spaceDamage.iDamage ~= DAMAGE_ZERO and spaceDamage.iDamage ~= DAMAGE_DEATH then
		if not targetPawn:IsBoosted() then
			local targetId = targetPawn:GetId()

			-- Add boost icon with group ID for automatic consolidation
			more_plus.libs.weaponPreview.ExecuteWithState(more_plus.convertPhase(phase),
				function()
					more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc, more_plus.commonIcons.boost.key, nil,  -- delay
							more_plus.WEAPON_PREVIEW_GROUP_ID)
				end, targetId
			)

			spaceDamage.sScript = spaceDamage.sScript .. string.format("Board:GetPawn(%d):SetBoosted(true)", targetId)
			logger.logDebug(SUBMODULE, "Will grant boosted to damaged mech %d at %s (damage: %d)",
					targetId, spaceDamage.loc:GetString(), spaceDamage.iDamage)
		else
			logger.logDebug(SUBMODULE, "Mech %d at %s already boosted, skipping",
					targetPawn:GetId(), spaceDamage.loc:GetString())
		end
	end
end

return customSkill
