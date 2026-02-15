local BASE_MOVE = 3

local customSkill = more_plus.SkillActive:new{
	id = "RrHyper",
	name = "Hyper",
	description = "+3 movement, lose 1 movement at the end of each turn (min +0)",
	reusability = cplus_plus_ex.REUSABLILITY.REUSABLE,
	-- Not strictly needed but makes more sense
	bonuses = {move = BASE_MOVE},
}

function customSkill:setupEffect()
	table.insert(customSkill.events, modApi.events.onNextTurn:subscribe(customSkill.setMoveBonus))
	self.setMoveBonus()
end

function customSkill.setMoveBonus()
	for _, pilotAndSkills in pairs(cplus_plus_ex:getPilotsWithSkill(customSkill.id)) do
		LOG("setMoveBonus found "..pilotAndSkills.pilot:getIdStr())
		local pilot = pilotAndSkills.pilot
		local idxes = pilotAndSkills.skillIndices
		for _, idx in ipairs(idxes) do
			local skill = pilot:getLvlUpSkill(idx)
			-- First turn is 1 so add 1 so its BASE_MOVE on the first turn
			skill:setMoveBonus(math.max(0, BASE_MOVE - Game:GetTurnCount() + 1))
		end
	end
end

return customSkill