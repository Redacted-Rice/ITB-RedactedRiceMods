local Skills = {}

local SkillActive = {
	events = {}
}
SkillActive.__index = SkillActive

function SkillActive:new(tbl)
	tbl = tbl or {}
	setmetatable(tbl, self)
	Skills[tbl.id] = tbl
	return tbl
end

function SkillActive:setupEffect()
	LOG("ERROR: SkillActive setupEffect not implemented for skill %s", self.id)
end

function SkillActive:clearEvents()
	for _, event in pairs(self.events) do
		event:unsubscribe()
	end
end

function SkillActive:load()
	if cplus_plus_ex:isSkillEnabled(self.id) then
		cplus_plus_ex:addSkillActiveHook(self.clearAndResetupEffect)
	else
		self:clearEvents()
	end
end

function SkillActive.clearAndResetupEffect(skillId, isActive, pawnId, pilot, skillStruct)
	LOG("Skill "..skillId)
	local skillClass = Skills[skillId]
	if skillClass then
		LOG("Skill FOUND ACTIVE")
		-- Clear events
		skillClass:clearEvents()

		-- Then add them back if any are active
		if cplus_plus_ex.isSkillActive(skillId) then
			skillClass:setupEffect()
		end
	end
end

return SkillActive