local MAX_MOVE = 4
local BASE_MOVE = 1

local customSkill = more_plus.SkillActive:new{
	id = "RrAccelerator",
	name = "Accelerator",
	description = "+1 Move at the start of each turn (max +" .. MAX_MOVE .. ")",
	reusability = cplus_plus_ex.REUSABLILITY.REUSABLE,
	bonuses = {move = 1}, -- starts at one
}

customSkill:addCustomTrait()

function customSkill:setupEffect()
	table.insert(customSkill.events, modApi.events.onNextTurn:subscribe(customSkill.setMoveBonus))
	table.insert(customSkill.events, modApi.events.onMissionEnd:subscribe(customSkill.setDefaultMoveBonus))
	table.insert(customSkill.events, modApi.events.onMissionStart:subscribe(customSkill.setDefaultMoveBonus))
	self.setDefaultMoveBonus()
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
	customSkill:_internalSetMoveBonus(math.min(MAX_MOVE, Game:GetTurnCount()))
end

return customSkill