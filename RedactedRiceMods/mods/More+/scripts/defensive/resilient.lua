local customSkill = more_plus.SkillActive:new{
	id = "RrResilient",
	name = "Resilient",
	description = "Gain a shield when damaged",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
}

customSkill:addCustomTrait()

function customSkill:setupEffect()
	table.insert(customSkill.events, modapiext.events.onPawnDamaged:subscribe(
		function(mission, pawn, damageTaken)
			if pawn and pawn:IsMech() and damageTaken > 0 then
				local pilot = pawn:GetPilot()
				if pilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) then
					-- Add shield to the pawn
					pawn:SetShield(true)
					--LOG("Resilient: Added shield to mech at ".. pawn:GetSpace():GetString())
				end
			end
		end))
end

return customSkill
