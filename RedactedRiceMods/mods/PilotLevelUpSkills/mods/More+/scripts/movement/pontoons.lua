local customSkill = cplus_plus_ex.baseClasses.SkillTrait:new{
	id = "RrPontoons",
	name = "Pontoons",
	description = "Piloted mech floats on top of liquid tiles without being affected by them.",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
	constraints = {
		groups = {PlusHelper.GROUPS.MOVE_TYPE},
		-- Prospero already has flying so it doesn't help at all
		-- Flying cyborgs (Hornet) also don't benefit from pontoons
		pilotExclusions = {
			"Pilot_Recycler",
			cplus_plus_ex.isFlyingCyborg,
			cplus_plus_ex.isBurrowerCyborg,
		},
		squadExclusions = {"knight_ChessPawns"},
	},
}

-- Initialize logger
customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Pontoons", customSkill.DEBUG)

more_plus:addCustomTraitIcon(customSkill)

function customSkill:applyTrait(pawnId, pawn, isActive)
	if isActive then
		logger.logDebug(SUBMODULE, "Setting pawn %d IgnoreLiquid (pontoons)", pawnId)
		IgnoreLiquid.set(pawn, true)
		customSkill.modified[pawnId] = pawn
	elseif customSkill.modified[pawnId] then
		logger.logDebug(SUBMODULE, "Removing IgnoreLiquid from pawn %d", pawnId)
		IgnoreLiquid.set(pawn, false)
		customSkill.modified[pawnId] = nil
	end
end

return customSkill
