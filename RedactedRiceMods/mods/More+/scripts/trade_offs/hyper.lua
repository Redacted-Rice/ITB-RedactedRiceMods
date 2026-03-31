local BASE_MOVE = 3
local MOVE_REDUCE_COLOR = GL_Color(255, 255, 50)

local customSkill = more_plus.SkillActive:new{
	id = "RrHyper",
	name = "Hyper",
	description = "+3 movement but lose 1 movement at the end of each turn (min +0)",
	reusability = cplus_plus_ex.REUSABLILITY.REUSABLE,
	-- Not strictly needed but makes more sense
	bonuses = {move = BASE_MOVE},
}

customSkill:addCustomTrait()

function customSkill:setupEffect()
	table.insert(customSkill.events, modApi.events.onNextTurn:subscribe(customSkill.setMoveBonus))
	table.insert(customSkill.events, modApi.events.onMissionEnd:subscribe(customSkill.setDefaultMoveBonus))
	table.insert(customSkill.events, modApi.events.onMissionStart:subscribe(customSkill.setDefaultMoveBonus))
	self.setCurrentMoveBonus()
end

function customSkill:_internalSetMoveBonus(moveBonus, doPing)
	for _, skillInfo in pairs(cplus_plus_ex:getMechsWithSkill(customSkill.id)) do
		--LOG("setMoveBonus found "..skillInfo.pilot:getIdStr())
		local pilot = skillInfo.pilot
		local idxes = skillInfo.skillIndices
		for _, idx in ipairs(idxes) do
			local skill = pilot:getLvlUpSkill(idx)
			--LOG("setMoveBonus for "..skillInfo.pilot:getIdStr().." at idx "..idx.. " to "..moveBonus)
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
	customSkill:_internalSetMoveBonus(BASE_MOVE, false)
end

function customSkill.setCurrentMoveBonus()
	-- Ensure turn count is always at least 1 to avoid deployment oddities
	local turnCount = math.max(Game:GetTurnCount(), 1)
	customSkill:_internalSetMoveBonus(math.max(0, BASE_MOVE - turnCount + 1), false)
end

function customSkill.setMoveBonus()
	--LOG("TURN "..Game:GetTeamTurn())
	local turnCount = Game:GetTurnCount()
	if Game:GetTeamTurn() == TEAM_PLAYER and turnCount > 1 then
		customSkill:_internalSetMoveBonus(math.max(0, BASE_MOVE - turnCount + 1), true)
	end
end

return customSkill