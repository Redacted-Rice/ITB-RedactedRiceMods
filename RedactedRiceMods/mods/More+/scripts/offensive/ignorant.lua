local customSkill = more_plus.SkillActive:new{
	id = "RrIgnorant",
	name = "Ignorant",
	description = "Pilot gains boosted each turn but loses 2 XP per kill",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT
}

function customSkill.setupEffect()
	table.insert(customSkill.events, modapiext.events.onPawnKilled:subscribe(customSkill.killedPawn))
	table.insert(customSkill.events, modapiext.events.onNextTurn:subscribe(customSkill.boostOnTurn))
end

function customSkill.killedPawn(mission, pawn, killer)
	if killer and pawn:isEnemy() then
		local pilot = killer:GetPilot()
		if cplus_plus_ex.isSkillOnPilot(customSkill.id, pilot) then
			pilot:addXp(-2)
		end
	end
end

function customSkill.boostOnTurn()
	if  Game:GetTeamTurn() == TEAM_PLAYER then
		for _, mech in pairs(cplus_plus_ex.getMechsWithSkill(customSkill.id)) do
			mech:SetBoosted(true)
		end
	end
end

return customSkill