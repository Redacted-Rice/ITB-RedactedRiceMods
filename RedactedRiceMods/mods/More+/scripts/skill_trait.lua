local SkillTrait = {}
SkillTrait.__index = SkillTrait

function SkillTrait.new(id, name, desc, reusability)
	local self = setmetatable({}, SkillTrait)
	self.id = id
	self.name = name
	self.desc = desc
	self.reusability = reusability
	modified = {},
	return self
end

-- no init needed

function SkillTrait.applyTrait(pawn, isActive)
	LOG("ERROR: SkillTrait applyTrait not implemented for skill %s", self.id)
end

function SkillTrait:load()
	if cplus_plus_ex.isSkillEnabled(self.id) then
		cplus_plus_ex:addSkillActiveHook(self.applyEffect)
	end
end

function SkillTrait.checkAndApplyTrait(skillId, isActive, pawnId, pilot, skill)
	if skillId == skill.id then
		local pawn = Game:GetPawn(pawnId)
		SkillTrait.applyTrait(pawnId, pawn, isActive)
	end
end

return SkillTrait