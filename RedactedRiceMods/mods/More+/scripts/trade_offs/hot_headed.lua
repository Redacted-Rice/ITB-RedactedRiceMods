local XP_LOSS = 2
local XP_LOSS_PING_COLOR = GL_Color(200, 50, 50)

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
	--[[LOG("PAWN KILLED! "..pawn:GetId())
	if more_plus.lastActed then
		LOG("KILLER! "..more_plus.lastActed:GetId())
	end]]--
	if more_plus.lastActed and pawn:IsEnemy() then
		local pilot = more_plus.lastActed:GetPilot()
		if pilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) then
			-- Decrease the XP but only if you don't level down
			local xp = pilot:getXp()
			if xp ~= 0 then
				Board:Ping(more_plus.lastActed:GetSpace(), XP_LOSS_PING_COLOR)
				pilot:setXp(math.max(0, xp - XP_LOSS))
			end
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