local SkillTrait = {}
SkillTrait.skills = {}

SkillTrait.__index = SkillTrait

function SkillTrait:new(tbl)
	tbl = tbl or {}
	tbl.modified = {}
	setmetatable(tbl, self)
	self.skills[tbl.id] = tbl
	return tbl
end

-- no init needed

function SkillTrait:applyTrait(pawn, isActive)
	LOG("ERROR: SkillTrait applyTrait not implemented for skill %s", self.id)
end

function SkillTrait:baseInit()
	cplus_plus_ex.events.onSkillActive:subscribe(self.checkAndApplyTrait)
end

function SkillTrait.checkAndApplyTrait(skillId, isActive, pawnId, pilot, skill)
	--LOG("CHECKING T SKILL "..skillId)
	local skillClass = SkillTrait.skills[skillId]
	if skillClass then
		local pawn = Game:GetPawn(pawnId)
		skillClass:applyTrait(pawnId, pawn, isActive)
	end
end

return SkillTrait