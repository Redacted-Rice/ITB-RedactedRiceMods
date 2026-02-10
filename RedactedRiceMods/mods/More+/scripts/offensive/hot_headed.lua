local customSkill = more_plus.SkillActive:new{
	id = "RrHotHeaded",
	name = "Hot Headed",
	description = "Gains boosted each turn but loses 2 XP per kill",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT
}

function customSkill:setupEffect()
	table.insert(customSkill.events, modapiext.events.onPawnKilled:subscribe(customSkill.killedPawn))
	table.insert(customSkill.events, modApi.events.onNextTurn:subscribe(customSkill.boostOnTurn))
end

function customSkill.killedPawn(mission, pawn, killerId)
	if killerId and pawn:IsEnemy() then
		local pilot = Board:GetPawn(killerId):GetPilot()
		if pilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) then
			-- TODO: Add effect
			pilot:addXp(-2)
		end
	end
end

function customSkill.boostOnTurn()
	-- TODO: Nerf to every other turn
	if  Game:GetTeamTurn() == TEAM_PLAYER then
		for _, mechInfo in pairs(cplus_plus_ex:getMechsWithSkill(customSkill.id)) do
			Board:GetPawn(mechInfo.pawnId):SetBoosted(true)
		end
	end
end

return customSkill