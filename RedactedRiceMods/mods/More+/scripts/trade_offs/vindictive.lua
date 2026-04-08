local customSkill = more_plus.SkillEffectModifier:new{
	id = "RrVindictive",
	name = "Vindictive",
	description = "+1 damage for each negative status effect on piloted mech.",
	reusability = cplus_plus_ex.REUSABLILITY.REUSABLE,
}

customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Vindictive", customSkill.DEBUG)

customSkill:addCustomTrait()

-- Adverse status effects that should increase damage
local adverseStatuses = {
	"Blind", "Chill", "Confusion", "Doomed", "Dry", "Hemorrhage",
	"Infested", "LeechSeed", "Necrosis", "Powder", "Rooted",
	"Shatterburst", "Shocked", "Sleep", "Toxin", "Weaken", "Wet", "Insanity"
}

function customSkill:modifySpaceDamage(pawn, isFinalEffect, spaceDamage, indexes, spacePawn)
	-- Check if this is actual damage being dealt
	if spacePawn and spacePawn:IsEnemy() and spaceDamage.iDamage > 0 and
			spaceDamage.iDamage ~= DAMAGE_DEATH and spaceDamage.iDamage ~= DAMAGE_ZERO then

		local pawnId = pawn:GetId()
		local statusCount = 0
		local activeStatuses = {}

		-- Count vanilla fire and acid status
		if pawn:IsFire() then
			statusCount = statusCount + 1
			table.insert(activeStatuses, "Fire")
		end
		if pawn:IsAcid() then
			statusCount = statusCount + 1
			table.insert(activeStatuses, "Acid")
		end

		-- Count Status library adverse effects if available
		if Status and Status.GetStatus then
			for _, statusName in ipairs(adverseStatuses) do
				if Status.GetStatus(pawnId, statusName) then
					statusCount = statusCount + 1
					table.insert(activeStatuses, statusName)
				end
			end
		end

		-- Add damage for each adverse status
		if statusCount > 0 then
			local previewState = isFinalEffect and more_plus.libs.weaponPreview.STATE_FINAL_EFFECT or
					more_plus.libs.weaponPreview.STATE_SKILL_EFFECT

			for _, idx in ipairs(indexes) do
				logger.logDebug(SUBMODULE, "Adding vindictive damage icon for %s with idx %d",
						spaceDamage.loc:GetString(), idx)
				more_plus.libs.weaponPreview.ExecuteWithState(previewState,
						function()
							more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc,
									more_plus.commonIcons.extraDamage.key.."_"..idx)
						end)
			end

			spaceDamage.iDamage = spaceDamage.iDamage + statusCount
			logger.logDebug(SUBMODULE, "Added +%d vindictive damage (pawn %d has %d statuses: %s)",
					statusCount, pawn:GetId(), statusCount, table.concat(activeStatuses, ", "))
		end
	end

	return nil
end

return customSkill
