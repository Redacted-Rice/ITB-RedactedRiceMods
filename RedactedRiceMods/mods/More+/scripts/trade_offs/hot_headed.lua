local XP_LOSS = 2

local customSkill = more_plus.SkillActive:new{
	id = "RrHotHeaded",
	name = "Hot Headed",
	description = "Gains boosted every other turn but loses 2 XP per kill (can't level down from this)",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT
}

customSkill:addCustomTrait()

function customSkill:setupEffect()
	table.insert(customSkill.events, modapiext.events.onPawnKilled:subscribe(customSkill.killedPawn))
	table.insert(customSkill.events, modApi.events.onNextTurn:subscribe(customSkill.boostOnTurn))
end

function customSkill.killedPawn(mission, pawn)
	LOG("PAWN KILLED! "..pawn:GetId())
	if GAME.trackedActingId then
		LOG("KILLER! "..GAME.trackedActingId)
	end
	if GAME.trackedActingId and pawn:IsEnemy() then
		local pilot = Board:GetPawn(GAME.trackedActingId):GetPilot()
		if pilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) then
			-- TODO: Add visual effect
			-- Decrease the XP but only if you don't level down
			local xp = pilot:getXp()
			pilot:setXp(max(0, xp - XP_LOSS))
		end
	end
end

function customSkill.boostOnTurn()
	-- Do odd turns - first turn and evey other after it
	if  Game:GetTeamTurn() == TEAM_PLAYER and Game:GetTurnCount() % 2 == 1 then
		for _, mechInfo in pairs(cplus_plus_ex:getMechsWithSkill(customSkill.id)) do
			Board:GetPawn(mechInfo.pawnId):SetBoosted(true)
		end
	end
end

return customSkill