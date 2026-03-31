local customSkill = more_plus.SkillActive:new{
	id = "RrResilient",
	name = "Resilient",
	description = "Gain a shield after taking damage.",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
}

-- Initialize logger
customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Resilient", customSkill.DEBUG)

cplus_plus_ex:registerPilotSkillExclusions("Pilot_Zoltan", customSkill.id)

customSkill:addCustomTrait()

function customSkill:setupEffect()
	table.insert(customSkill.events, modapiext.events.onPawnDamaged:subscribe(
		function(mission, pawn, damageTaken)
			if pawn and pawn:IsMech() and damageTaken > 0 then
				local pilot = pawn:GetPilot()
				if pilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) then
					logger.logDebug(SUBMODULE, "Pawn %d took %d damage, adding shield", pawn:GetId(), damageTaken)
					pawn:SetShield(true)
				end
			end
		end))
end

return customSkill
