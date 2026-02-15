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
	self.events = {}
end

function SkillActive:baseInit()
	cplus_plus_ex.events.onSkillActive:subscribe(self.clearAndReSetUpEffect)
end

function SkillActive.clearAndReSetUpEffect(skillId, isActive, pawnId, pilot, skillStruct)
	--LOG("CHECKING A SKILL "..skillId)
	local skillClass = SkillActive.skills[skillId]
	if skillClass then
		-- Clear events
		skillClass:clearEvents()

		-- Then add them back if any are active
		if cplus_plus_ex:isSkillActive(skillId) then
			--LOG("Setting up "..skillId)
			skillClass:setupEffect()
		end
	end
end

return SkillActive