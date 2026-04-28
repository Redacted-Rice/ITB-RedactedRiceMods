local XP_LOSS = 2
local XP_LOSS_PING_COLOR = GL_Color(200, 50, 50)

local customSkill = cplus_plus_ex.baseClasses.SkillActive:new{
	id = "RrHotHeaded",
	name = "Hot Headed",
	description = "Gain Boost every other turn but loses 2 XP per kill (can't level down from this).",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
	slotRestriction = cplus_plus_ex.SLOT_RESTRICTION.FIRST,
	pawnWasKilled = false,
	constraints = {
		groups = {more_plus.GROUPS.BOOST},
		pilotExclusions = {"Pilot_Arrogant", "Pilot_Chemical"},
	}
}

customSkill:addCustomTrait()

function customSkill:setupEffect()
	table.insert(customSkill.events, modapiext.events.onPawnKilled:subscribe(customSkill.killedPawn))
	table.insert(customSkill.events, memhack.events.onPilotChanged:subscribe(customSkill.xpAwarded))
	table.insert(customSkill.events, modApi.events.onNextTurn:subscribe(customSkill.boostOnTurn))
end

function customSkill.killedPawn(mission, pawn)
	--[[LOG("PAWN KILLED! "..pawn:GetId())
	if BoardUtils.lastActed then
		LOG("KILLER! "..BoardUtils.lastActed:GetId())
	end]]--
	if BoardUtils.lastActed and pawn:IsEnemy() then
		customSkill.pawnWasKilled = true
	end
end

function customSkill.xpAwarded(pilot, changes)
	if changes.xp and customSkill.pawnWasKilled and BoardUtils.lastActed then
		if BoardUtils.lastActed:GetPilot() == pilot then
			--LOG("PILOT MATCH!")
			if pilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) then
				customSkill.pawnWasKilled = false
				-- Decrease the XP but only if you don't level down
				local xp = changes.xp.new
				xpLoss = math.min(xp, XP_LOSS)
				if xpLoss > 0 and pilot:getLevel() ~= 2 then
					Board:AddAlert(BoardUtils.lastActed:GetSpace(), "HOT HEADED -".. xpLoss.." XP")
					Board:Ping(BoardUtils.lastActed:GetSpace(), XP_LOSS_PING_COLOR)
					pilot:setXp(xp - xpLoss)
				end
			end
		--[[else
			LOG("PILOT NO MATCH!")]]--
		end
	end
end

function customSkill.boostOnTurn()
	-- Do odd turns - first turn and evey other after it
	if  Game:GetTeamTurn() == TEAM_PLAYER and Game:GetTurnCount() % 2 == 1 then
		for _, mechInfo in pairs(cplus_plus_ex:getMechsWithSkill(customSkill.id)) do
			local pawn = Board:GetPawn(mechInfo.pawnId)
			pawn:SetBoosted(true)
			Board:AddAlert(pawn:GetSpace(), "HOT HEADED")
		end
	end
end

return customSkill