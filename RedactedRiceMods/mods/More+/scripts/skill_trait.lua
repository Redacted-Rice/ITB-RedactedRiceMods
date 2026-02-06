local SkillTrait = {
	modified = {}
}
SkillTrait.__index = SkillTrait

function SkillTrait:new(tbl)
	tbl = tbl or {}
	setmetatable(tbl, self)
	return tbl
end

-- no init needed

function SkillTrait.applyTrait(pawn, isActive)
	LOG("ERROR: SkillTrait applyTrait not implemented for skill %s", self.id)
end

function SkillTrait:load()
	LOG("LOAD ".. self.id)
	if cplus_plus_ex.isSkillEnabled(self.id) then
		LOG("SETTING HOOKS")
		cplus_plus_ex:addSkillActiveHook(self.applyTrait)
	end
end

function SkillTrait.checkAndApplyTrait(skillId, isActive, pawnId, pilot, skill)
	if skillId == skill.id then
		local pawn = Game:GetPawn(pawnId)
		SkillTrait.applyTrait(pawnId, pawn, isActive)
	end
end

return SkillTrait