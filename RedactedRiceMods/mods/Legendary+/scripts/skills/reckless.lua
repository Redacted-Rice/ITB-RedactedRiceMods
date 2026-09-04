local customSkill = cplus_plus_ex.baseClasses.SkillEffectModifier:new{
	id = "RrReckless",
	name = "Reckless",
	description = "+1 damage dealt and +1 damage taken.",
	constraints = {
		groups = {legendary_plus.GROUPS.ADD_DAMAGE},
	},
	priority = 80,
	reusabilityLimit = cplus_plus_ex.REUSABLILITY.REUSABLE,
}

customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("Legendary+", "Reckless", customSkill.DEBUG)

legendary_plus:addCustomTraitIcon(customSkill)

function customSkill.isDamageable(damage)
	return damage > 0 and damage ~= DAMAGE_DEATH and damage ~= DAMAGE_ZERO
end

function customSkill:modifyKillDamage(source, attackingPawn, spaceDamage, indexes, targetPawn, currentDamage)
	if not self.isDamageable(currentDamage) then
		return currentDamage
	end

	if source == self.SOURCE_ATTACKER and targetPawn and targetPawn:IsEnemy() then
		return currentDamage + 1
	end
	if source == self.SOURCE_TARGET and attackingPawn and attackingPawn:IsEnemy() then
		return currentDamage + 1
	end
	return currentDamage
end

function customSkill:modifySpaceDamage(source, attackingPawn, phase, spaceDamage, indexes, targetPawn)
	if not self.isDamageable(spaceDamage.iDamage) then
		return
	end

	if source == self.SOURCE_ATTACKER and targetPawn and targetPawn:IsEnemy() then
		legendary_plus:previewExtraDamage(phase, spaceDamage.loc, attackingPawn:GetId(), customSkill)
		spaceDamage.iDamage = spaceDamage.iDamage + 1
		logger.logDebug(SUBMODULE, "Reckless +1 dealt at %s", spaceDamage.loc:GetString())
	elseif source == self.SOURCE_TARGET and attackingPawn and attackingPawn:IsEnemy() and targetPawn then
		-- Use attacker id so queued enemy previews attach marks to the acting pawn's queue
		legendary_plus:previewExtraDamage(phase, spaceDamage.loc, attackingPawn:GetId(), customSkill)
		spaceDamage.iDamage = spaceDamage.iDamage + 1
		logger.logDebug(SUBMODULE, "Reckless +1 taken at %s", spaceDamage.loc:GetString())
	end
end

return customSkill
