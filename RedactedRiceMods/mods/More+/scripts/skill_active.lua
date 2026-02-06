local SkillActive = {
	events = {}
}
SkillActive.__index = SkillActive

--[[ TODO: take table instead
function CreateClass(newclass)
	local members = {}
	
	for i,v in pairs(newclass) do
		members[#members + 1] = i 
	end
	
	for i = 1, #members do
		newclass["Get" .. members[i] ] = function (self, pawn) return self[members[i] ] end
	end
	
	newclass.new = 	function(self,o)
						o = o or {} -- create table if user does not provide one
						setmetatable(o, self)
						self.__index = self
						return o
					end
end]]--

function SkillActive:new(tbl)
	tbl = tbl or {}
	setmetatable(tbl, self)
	return tbl
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
	LOG("LOAD ".. self.id)
	if cplus_plus_ex.isSkillEnabled(self.id) then
		LOG("SETTING HOOKS")
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

return SkillActive