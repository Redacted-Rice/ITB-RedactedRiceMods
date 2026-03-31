local BASE_MOVE = 2
local MOVE_REDUCE_COLOR = GL_Color(255, 255, 50)

local customSkill = more_plus.SkillActive:new{
	id = "RrHyper",
	name = "Hyper",
	description = "+2 movement for the first 2 turns, +1 movement for the 3rd turn, then +0",
	reusability = cplus_plus_ex.REUSABLILITY.REUSABLE,
	-- Not strictly needed but makes more sense
	bonuses = {move = BASE_MOVE},
}

-- Initialize logger
customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Hyper", customSkill.DEBUG)

customSkill:addCustomTrait()

function customSkill:setupEffect()
	table.insert(customSkill.events, modApi.events.onNextTurn:subscribe(customSkill.setMoveBonus))
	table.insert(customSkill.events, modApi.events.onMissionEnd:subscribe(customSkill.setDefaultMoveBonus))
	table.insert(customSkill.events, modApi.events.onMissionStart:subscribe(customSkill.setDefaultMoveBonus))

	-- Fire now on load/earn/reset
	self.setCurrentMoveBonus()
end

function customSkill:_internalSetMoveBonus(moveBonus, doPing)
	for _, skillInfo in pairs(cplus_plus_ex:getMechsWithSkill(customSkill.id)) do
		logger.logDebug(SUBMODULE, "setMoveBonus found %s", skillInfo.pilot:getIdStr())
		local pilot = skillInfo.pilot
		local idxes = skillInfo.skillIndices
		for _, idx in ipairs(idxes) do
			local skill = pilot:getLvlUpSkill(idx)
			logger.logDebug(SUBMODULE, "setMoveBonus for %s at idx %d to %d", skillInfo.pilot:getIdStr(), idx, moveBonus)
			skill:setMoveBonus(moveBonus)
			if Board and doPing then
				local pawn = Board:GetPawn(skillInfo.pawnId)
				Board:AddAlert(pawn:GetSpace(), "HYPER")
				Board:Ping(pawn:GetSpace(), MOVE_REDUCE_COLOR)
			end
		end
	end
end

function customSkill.setDefaultMoveBonus()
	logger.logDebug(SUBMODULE, "Setting default move bonus to %d", BASE_MOVE)
	customSkill:_internalSetMoveBonus(BASE_MOVE, false)
end

function customSkill:calculateMoveBonus(turnCount)
	if turnCount <= 2 then
		return BASE_MOVE
	elseif turnCount == 3 then
		return 1
	else
		return 0
	end
end

function customSkill.setCurrentMoveBonus()
	local turnCount = math.max(Game:GetTurnCount(), 1)
	local moveBonus = customSkill:calculateMoveBonus(turnCount)
	logger.logDebug(SUBMODULE, "Setting current move bonus to %d (turn: %d)", moveBonus, turnCount)
	customSkill:_internalSetMoveBonus(moveBonus, false)
end

function customSkill.setMoveBonus()
	local turnCount = Game:GetTurnCount()
	logger.logDebug(SUBMODULE, "Turn %d (team: %d)", turnCount, Game:GetTeamTurn())
	if Game:GetTeamTurn() == TEAM_PLAYER and turnCount > 1 then
		local moveBonus = customSkill:calculateMoveBonus(turnCount + 1)
		logger.logDebug(SUBMODULE, "Setting move bonus to %d for next turn (current turn: %d)", moveBonus, turnCount)
		customSkill:_internalSetMoveBonus(moveBonus, true)
	end
end

return customSkill