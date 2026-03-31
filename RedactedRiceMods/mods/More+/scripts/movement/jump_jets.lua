local customSkill = more_plus.SkillTrait:new{
	id = "RrJumpJets",
	name = "Jump Jets",
	description = "Piloted Mech leaps instead of typical movement.",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT
}

-- Initialize logger
customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "JumpJets", customSkill.DEBUG)

-- Exclude prospero as he has flying and Henry as he already moves through enemies
cplus_plus_ex:registerPilotSkillExclusions("Pilot_Recycler", customSkill.id)
cplus_plus_ex:registerPilotSkillExclusions("Pilot_Hotshot", customSkill.id)
 
customSkill:addCustomTrait()

function customSkill:applyTrait(pawnId, pawn, isActive)
	if isActive then
		if not pawn:IsJumper() then
			logger.logDebug(SUBMODULE, "Setting pawn %d as jumper", pawnId)
			pawn:SetJumper(true)
			customSkill.modified[pawnId] = pawn
		end
	else
		if customSkill.modified[pawnId] then
			logger.logDebug(SUBMODULE, "Removing jumper from pawn %d", pawnId)
			pawn:SetJumper(false)
			customSkill.modified[pawnId] = nil
		end
	end
end

return customSkill