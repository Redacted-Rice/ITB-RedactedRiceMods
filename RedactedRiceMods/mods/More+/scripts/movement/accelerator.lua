local MAX_MOVE = 4

local customSkill = more_plus.SkillActive:new{
	id = "RrAccelerator",
	name = "Accelerator",
	description = "+1 Move at the start of each turn (max +" .. MAX_MOVE .. ")",
	reusability = cplus_plus_ex.REUSABLILITY.REUSABLE,
}

-- TODO:
--customSkill:addCustomTrait()

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
			skill:setMoveBonus(math.min(MAX_MOVE, Game:GetTurnCount() + 1))
		end
	end
end

return customSkill