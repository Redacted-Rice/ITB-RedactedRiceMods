local BASE_MOVE = 0
local MOVE_BOOST_COLOR = GL_Color(50, 255, 50)

local customSkill = more_plus.SkillActive:new{
	id = "RrAccelerator",
	name = "Accelerator",
	description = "+1 Move at the end of each turn.",
	reusability = cplus_plus_ex.REUSABLILITY.REUSABLE,
	-- Not strictly needed but makes more sense
	bonuses = {move = BASE_MOVE},
}

-- Initialize logger
customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Accelerator", customSkill.DEBUG)

customSkill:addCustomTrait()

function customSkill:setupEffect()
	table.insert(customSkill.events, modApi.events.onPreEnvironment:subscribe(customSkill.setMoveBonus))
	table.insert(customSkill.events, modApi.events.onMissionEnd:subscribe(customSkill.setDefaultMoveBonus))
	table.insert(customSkill.events, modApi.events.onMissionStart:subscribe(customSkill.setDefaultMoveBonus))
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
				Board:AddAlert(pawn:GetSpace(), "ACCELERATOR")
				Board:Ping(pawn:GetSpace(), MOVE_BOOST_COLOR)
			end
		end
	end
end

function customSkill.setDefaultMoveBonus()
	logger.logDebug(SUBMODULE, "SET BASE MOVE")
	customSkill:_internalSetMoveBonus(BASE_MOVE, false)
end

function customSkill.setCurrentMoveBonus()
	-- when we load, turn count is one higher so we need to account for that
	local turnCount = Game:GetTurnCount()
	logger.logDebug(SUBMODULE, "TURN COUNT setCurrentMoveBonus %d", Game:GetTurnCount())
	customSkill:_internalSetMoveBonus(turnCount - 1, false)
end

function customSkill.setMoveBonus()
	logger.logDebug(SUBMODULE, "TURN COUNT setMoveBonus %d", Game:GetTurnCount())
	if Game:GetTurnCount() > 0 then
		customSkill:_internalSetMoveBonus(Game:GetTurnCount(), true)
	end
end

return customSkill