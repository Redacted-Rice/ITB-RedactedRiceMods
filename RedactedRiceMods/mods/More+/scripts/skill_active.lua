local SkillActive = {}
SkillActive.skills = {}

SkillActive.__index = SkillActive

function SkillActive:new(tbl)
	tbl = tbl or {}
	tbl.events = {}
	setmetatable(tbl, self)
	self.skills[tbl.id] = tbl
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

function SkillActive:base_load()
	cplus_plus_ex:addSkillActiveHook(self.clearAndReSetUpEffect)
end

function SkillActive.clearAndReSetUpEffect(skillId, isActive, pawnId, pilot, skillStruct)
	local skillClass = SkillActive.skills[skillId]
	if skillClass then
		-- Clear events
		skillClass:clearEvents()

		-- Then add them back if any are active
		if cplus_plus_ex:isSkillActive(skillId) then
			skillClass:setupEffect()
		end
	end
end

return SkillActive