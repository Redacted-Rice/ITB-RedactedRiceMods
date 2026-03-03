local BASE_MOVE = 3

local customSkill = more_plus.SkillActive:new{
	id = "RrHyper",
	name = "Hyper",
	description = "+3 movement, lose 1 movement at the end of each turn (min +0)",
	reusability = cplus_plus_ex.REUSABLILITY.REUSABLE,
	-- Not strictly needed but makes more sense
	bonuses = {move = BASE_MOVE},
}

customSkill:addCustomTrait()

function customSkill:setupEffect()
	table.insert(customSkill.events, modApi.events.onNextTurn:subscribe(customSkill.setMoveBonus))
	table.insert(customSkill.events, modApi.events.onMissionEnd:subscribe(customSkill.setDefaultMoveBonus))
	table.insert(customSkill.events, modApi.events.onMissionStart:subscribe(customSkill.setDefaultMoveBonus))
	self.setMoveBonus()
end

function customSkill:_internalSetMoveBonus(moveBonus)
	for _, pilotAndSkills in pairs(cplus_plus_ex:getPilotsWithSkill(customSkill.id)) do
		LOG("setMoveBonus found "..pilotAndSkills.pilot:getIdStr())
		local pilot = pilotAndSkills.pilot
		local idxes = pilotAndSkills.skillIndices
		for _, idx in ipairs(idxes) do
			local skill = pilot:getLvlUpSkill(idx)
			LOG("setMoveBonus for "..pilotAndSkills.pilot:getIdStr().." at idx "..idx.. " to "..moveBonus)
			skill:setMoveBonus(moveBonus)
		end
	end
end

function customSkill.setDefaultMoveBonus()
	customSkill:_internalSetMoveBonus(BASE_MOVE)
end

function customSkill.setMoveBonus()
	-- Ensure turn count is always at least 1 to avoid deployment oddities
	local turnCount = math.max(Game:GetTurnCount(), 1)
	customSkill:_internalSetMoveBonus(math.max(0, BASE_MOVE - turnCount + 1))
end

return customSkill