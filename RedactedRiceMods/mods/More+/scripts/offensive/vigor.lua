local customSkill = more_plus.SkillEffectModifier:new{
	id = "RrVigor",
	name = "Vigor",
	description = "Gain boosted when healed.",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
}

customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Vigor", customSkill.DEBUG)

-- Exclude Kai and Morgan as they give boosted already
cplus_plus_ex:registerPilotSkillExclusions("Pilot_Arrogant", customSkill.id)
cplus_plus_ex:registerPilotSkillExclusions("Pilot_Chemical", customSkill.id)

customSkill:addCustomTrait()

function customSkill:modifySpaceDamage(pawn, isFinalEffect, spaceDamage, indexes, spacePawn)
	if spacePawn and spacePawn:IsMech() and spaceDamage.iDamage < 0 and
			spaceDamage.iDamage ~= DAMAGE_ZERO and spaceDamage.iDamage ~= DAMAGE_DEATH then
		local healedPilot = spacePawn:GetPilot()
		if healedPilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, healedPilot) then
			if not spacePawn:IsBoosted() then
				local previewState = isFinalEffect and more_plus.libs.weaponPreview.STATE_FINAL_EFFECT or
						more_plus.libs.weaponPreview.STATE_SKILL_EFFECT

				for _, idx in ipairs(indexes) do
					logger.logDebug(SUBMODULE, "Adding boost icon for healed mech at %s with idx %d",
							spaceDamage.loc:GetString(), idx)
					more_plus.libs.weaponPreview.ExecuteWithState(previewState,
							function()
								more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc,
										more_plus.commonIcons.boost.key.."_"..idx)
							end)
				end

				spaceDamage.sScript = string.format("Board:GetPawn(%d):SetBoosted(true)", spacePawn:GetId())
				logger.logDebug(SUBMODULE, "Will grant boosted to healed mech %d at %s (heal amount: %d)",
						pawnId, spaceDamage.loc:GetString(), -spaceDamage.iDamage)
			else
				logger.logDebug(SUBMODULE, "Mech %d at %s already boosted, skipping",
						spacePawn:GetId(), spaceDamage.loc:GetString())
			end
		end
	end
end

return customSkill
