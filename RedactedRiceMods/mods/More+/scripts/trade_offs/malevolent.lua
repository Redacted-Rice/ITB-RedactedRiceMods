local customSkill = more_plus.SkillEffectModifier:new{
	id = "RrMalevolent",
	name = "Malevolent",
	description = "If piloted mech has a negative status, apply it to attacks that damage enemies.",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
}

customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Malevolent", customSkill.DEBUG)

customSkill:addCustomTrait()

-- Adverse status effects that should be spread to targets
local adverseStatuses = {
	"Blind", "Chill", "Confusion", "Doomed", "Dry", "Hemorrhage",
	"Infested", "LeechSeed", "Necrosis", "Powder", "Rooted",
	"Shatterburst", "Shocked", "Sleep", "Toxin", "Weaken", "Wet", "Insanity"
}

function customSkill:modifySpaceDamage(attackingPawn, previewState, spaceDamage, indexes, targetPawn)
	-- Check if attacker is dealing damage to an enemy
	if attackingPawn and targetPawn and targetPawn:IsEnemy() and spaceDamage.iDamage > 0 and
			spaceDamage.iDamage ~= DAMAGE_ZERO then

		local pawnId = attackingPawn:GetId()
		local appliedStatuses = {}

		-- Check vanilla fire and acid status
		if attackingPawn:IsFire() then
			spaceDamage.iFire = EFFECT_CREATE
			table.insert(appliedStatuses, "Fire")
			logger.logDebug(SUBMODULE, "Applied fire to target at %s", spaceDamage.loc:GetString())
		end
		if attackingPawn:IsAcid() then
			spaceDamage.iAcid = EFFECT_CREATE
			table.insert(appliedStatuses, "Acid")
			logger.logDebug(SUBMODULE, "Applied acid to target at %s", spaceDamage.loc:GetString())
		end

		-- Check Status library adverse effects if available
		if Status and Status.GetStatus then
			for _, statusName in ipairs(adverseStatuses) do
				local hasStatus = Status.GetStatus(pawnId, statusName)
				if hasStatus then
					-- Apply the status to the target using the iXxx metatable syntax
					spaceDamage["i"..statusName] = EFFECT_CREATE
					table.insert(appliedStatuses, statusName)
					logger.logDebug(SUBMODULE, "Applied %s to target at %s", statusName, spaceDamage.loc:GetString())
				end
			end
		end

		if #appliedStatuses > 0 then
			logger.logDebug(SUBMODULE, "Malevolent applied %d statuses: %s",
				#appliedStatuses, table.concat(appliedStatuses, ", "))
		end
	end

	return nil
end

return customSkill
