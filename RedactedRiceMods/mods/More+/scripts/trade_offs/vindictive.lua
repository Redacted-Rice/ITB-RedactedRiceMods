local customSkill = cplus_plus_ex.baseClasses.SkillEffectModifier:new{
	id = "RrVindictive",
	name = "Vindictive",
	description = "+1 damage to enemies for each negative status effect on piloted mech.",
	reusability = cplus_plus_ex.REUSABLILITY.REUSABLE,
	constraints = {
		groups = {more_plus.GROUPS.ADD_DAMAGE, more_plus.GROUPS.STATUS_BASED},
		pilotExclusions = {"Pilot_Rock", "Pilot_Zoltan"},
	},
	priority = 80, -- go after doubling
	modifiesKillDamage = true,
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

local function countAdverseStatuses(attackingPawn)
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
		local pawnId = attackingPawn:GetId()
		for _, statusName in ipairs(adverseStatuses) do
			if Status.GetStatus(pawnId, statusName) then
				statusCount = statusCount + 1
				table.insert(activeStatuses, statusName)
			end
		end
	end
	return statusCount, activeStatuses
end

function customSkill:modifyKillDamage(source, attackingPawn, spaceDamage, indexes, targetPawn, currentDamage)
	-- Check if attacker is dealing damage to enemy
	if source ~= customSkill.SOURCE_ATTACKER or not targetPawn or not targetPawn:IsEnemy() or
			not (currentDamage > 0 and currentDamage ~= DAMAGE_DEATH and currentDamage ~= DAMAGE_ZERO) then
		return currentDamage
	end

	local statusCount = countAdverseStatuses(attackingPawn)
	if statusCount > 0 then
		return currentDamage + statusCount
	end
	return currentDamage
end

function customSkill:modifySpaceDamage(source, attackingPawn, phase, spaceDamage, indexes, targetPawn)
	local newDamage = self:modifyKillDamage(source, attackingPawn, spaceDamage, indexes, targetPawn, spaceDamage.iDamage)
	if newDamage == spaceDamage.iDamage then
		return
	end

	local statusCount = newDamage - spaceDamage.iDamage
	local _, activeStatuses = countAdverseStatuses(attackingPawn)
	-- Add vindictive damage icon with group ID
	more_plus.libs.weaponPreview.ExecuteWithState(more_plus.convertPhase(phase),
		function()
			more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc, more_plus.commonIcons.extraDamage.key, nil,  -- delay
					more_plus.WEAPON_PREVIEW_GROUP_ID, GetText(customSkill.name) .. ": " .. GetText(customSkill.description))
		end, attackingPawn:GetId()
	)
	spaceDamage.iDamage = newDamage
	logger.logDebug(SUBMODULE, "Added +%d vindictive damage (pawn %d has %d statuses: %s)",
			statusCount, attackingPawn:GetId(), statusCount, table.concat(activeStatuses, ", "))
end

return customSkill
