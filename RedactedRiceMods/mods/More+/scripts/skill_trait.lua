local Skills = {}

local SkillTrait = {
	modified = {}
}
SkillTrait.__index = SkillTrait

function SkillTrait:new(tbl)
	tbl = tbl or {}
	setmetatable(tbl, self)
	Skills[tbl.id] = tbl
	return tbl
end

-- no init needed

function SkillTrait:applyTrait(pawn, isActive)
	LOG("ERROR: SkillTrait applyTrait not implemented for skill %s", self.id)
end

function SkillTrait:load()
	if cplus_plus_ex:isSkillEnabled(self.id) then
		cplus_plus_ex:addSkillActiveHook(self.checkAndApplyTrait)
	end
end

function SkillTrait.checkAndApplyTrait(skillId, isActive, pawnId, pilot, skill)
	LOG("Skill "..skillId)
	local skillClass = Skills[skillId]
	if skillClass then
		LOG("Skill FOUND TRAIT")
		local pawn = Game:GetPawn(pawnId)
		skillClass:applyTrait(pawnId, pawn, isActive)
	end
end

return SkillTrait