local SkillActive = {}
SkillActive.__index = SkillActive

function SkillActive.new(id, name, desc, reusability)
	local self = setmetatable({}, SkillActive)
	self.id = id
	self.name = name
	self.desc = desc
	self.reusability = reusability
	self.events = {}
	return self
end

function SkillActive.setupEffect()
	LOG("ERROR: SkillActive setupEffect not implemented for skill %s", self.id)
end

function SkillActive.clearEvents()
	for _, event in pairs(SkillActive.events) do
		event:unsubscribe()
	end
end

function SkillActive:load()
	if cplus_plus_ex.isSkillEnabled(self.id) then
		cplus_plus_ex:addSkillActiveHook(self.clearAndResetupEffect)
	else
		self.clearEvents()
	end
end

function SkillActive.clearAndResetupEffect(skillId, isActive, pawnId, pilot, skillStruct)
	if skill.id == skillId then
		-- Clear events
		self.clearEvents()

		-- Then add them back if any are active
		if cplus_plus_ex.isSkillActive(skillId) then
			self.setupEffect()
		end
	end
end

return CustomSkill