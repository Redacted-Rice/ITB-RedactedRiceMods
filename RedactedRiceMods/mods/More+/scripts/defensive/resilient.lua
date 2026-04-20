local customSkill = more_plus.SkillActive:new{
	id = "RrResilient",
	name = "Resilient",
	description = "Gain a shield each time the piloted mech is damaged after the attack completes.",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
	constraints = {
		groups = {more_plus.GROUPS.SHIELD},
		pilotExclusions = {"Pilot_Zoltan"},
	}
}

-- Initialize logger
customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Resilient", customSkill.DEBUG)

customSkill:addCustomTrait()

function customSkill:setupEffect()
	table.insert(customSkill.events, modapiext.events.onPawnDamaged:subscribe(
		function(mission, pawn, damageTaken)
			if pawn and pawn:IsMech() and damageTaken > 0 then
				local pilot = pawn:GetPilot()
				if pilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) then
					logger.logDebug(SUBMODULE, "Pawn %d took %d damage, adding shield", pawn:GetId(), damageTaken)
					pawn:SetShield(true)
					Board:AddAlert(pawn:GetSpace(), "RESILIENT")
				end
			end
		end))
end

return customSkill
