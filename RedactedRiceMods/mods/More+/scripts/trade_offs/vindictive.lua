local customSkill = cplus_plus_ex.baseClasses.SkillEffectModifier:new{
	id = "RrVindictive",
	name = "Vindictive",
	description = "+1 damage to enemies for each negative status effect on piloted mech.",
	reusability = cplus_plus_ex.REUSABLILITY.REUSABLE,
	constraints = {
		groups = {more_plus.GROUPS.ADD_DAMAGE, more_plus.GROUPS.STATUS_BASED},
		pilotExclusions = {"Pilot_Rock"},
	},
	priority = 80, -- go after doubling
}

customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Vindictive", customSkill.DEBUG)

more_plus:addCustomTraitIcon(customSkill)

-- Adverse status effects that should increase damage
local adverseStatuses = {
	"Blind", "Chill", "Confusion", "Doomed", "Dry", "Hemorrhage",
	"Infested", "LeechSeed", "Necrosis", "Powder", "Rooted",
	"Shatterburst", "Shocked", "Sleep", "Toxin", "Weaken", "Wet", "Insanity"
}

function customSkill:modifySpaceDamage(source, attackingPawn, phase, spaceDamage, indexes, targetPawn)
	-- Check if attacker is dealing damage to enemy
	if source == self.SOURCE_ATTACKER and targetPawn and
			targetPawn:IsEnemy() and spaceDamage.iDamage > 0 and
			spaceDamage.iDamage ~= DAMAGE_DEATH and spaceDamage.iDamage ~= DAMAGE_ZERO then

		local pawnId = attackingPawn:GetId()
		local statusCount = 0
		local activeStatuses = {}

		-- Count vanilla fire and acid status
		if attackingPawn:IsFire() then
			statusCount = statusCount + 1
			table.insert(activeStatuses, "Fire")
		end
		if attackingPawn:IsAcid() then
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
			for _, idx in ipairs(indexes) do
				logger.logDebug(SUBMODULE, "Adding vindictive damage icon for %s with idx %d",
						spaceDamage.loc:GetString(), idx)
				more_plus.libs.weaponPreview.ExecuteWithState(more_plus.convertPhase(phase),
						function()
							more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc,
									more_plus.commonIcons.extraDamage.key.."_"..idx)
						end)
			end

			spaceDamage.iDamage = spaceDamage.iDamage + statusCount
			logger.logDebug(SUBMODULE, "Added +%d vindictive damage (pawn %d has %d statuses: %s)",
					statusCount, attackingPawn:GetId(), statusCount, table.concat(activeStatuses, ", "))
		end
	end

end

return customSkill
