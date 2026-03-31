local customSkill = more_plus.SkillTrait:new{
	id = "RrGuarded",
	icon = "img/combat/icons/icon_guard.png",
	name = "Guarded",
	description = "Piloted Mech is stable and cannot be moved by weapon effects.",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT
}

-- Initialize logger
customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Guarded", customSkill.DEBUG)

function customSkill:applyTrait(pawnId, pawn, isActive)
	if isActive then
		if not pawn:IsGuarding() then
			logger.logDebug(SUBMODULE, "Setting pawn %d unpushable (guarded)", pawnId)
			pawn:SetPushable(false)
			customSkill.modified[pawnId] = pawn
		end
	elseif customSkill.modified[pawnId] then
		logger.logDebug(SUBMODULE, "Removing guarded from pawn %d", pawnId)
		pawn:SetPushable(true)
		customSkill.modified[pawnId] = nil
	end
end

return customSkill