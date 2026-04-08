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

function customSkill:modifySpaceDamage(pawn, isFinalEffect, spaceDamage, indexes, spacePawn)
	-- Check if this is damage to an enemy
	if spacePawn and spacePawn:IsEnemy() and spaceDamage.iDamage > 0 and
			spaceDamage.iDamage ~= DAMAGE_ZERO then

		-- Check if the attacking pawn has fire or acid status
		if pawn:IsFire() then
			spaceDamage.iFire = EFFECT_CREATE
			logger.logDebug(SUBMODULE, "Applied fire to target at %s", spaceDamage.loc:GetString())
		end

		if pawn:IsAcid() then
			spaceDamage.iAcid = EFFECT_CREATE
			logger.logDebug(SUBMODULE, "Applied acid to target at %s", spaceDamage.loc:GetString())
		end
	end

	return nil
end

return customSkill
