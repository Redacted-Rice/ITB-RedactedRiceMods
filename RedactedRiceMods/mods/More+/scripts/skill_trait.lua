local SkillTrait = {}
SkillTrait.skills = {}

SkillTrait.__index = SkillTrait

-- Initialize logger
SkillTrait.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "SkillTrait", SkillTrait.DEBUG)

function SkillTrait:new(tbl)
	tbl = tbl or {}
	tbl.modified = {}
	setmetatable(tbl, self)
	self.skills[tbl.id] = tbl
	return tbl
end

function SkillTrait:addCustomTrait()
	local iconImg = "img/combat/icons/icon_mp_"..self.id..".png"
	self.icon = iconImg
	logger.logDebug(SUBMODULE, "Adding trait icon %s at %s", self.id, iconImg)
	more_plus.libs.traitReplace:add{
		targetTrait = "massive",
		func = function(trait, pawn)
			if cplus_plus_ex:isSkillOnPawn(self.id, pawn) then
				return true
			end
			return false
		end,
		icon = iconImg,
		--icon_offset = Point(0,9),
		desc_title = self.fullName or self.name,
		desc_text = self.description,
	}
end

function SkillTrait:applyTrait(pawn, isActive)
	logger.logError(SUBMODULE, string.format("SkillTrait applyTrait not implemented for skill %s", self.id))
end

function SkillTrait:baseInit()
	cplus_plus_ex.events.onSkillActive:subscribe(self.checkAndApplyTrait)
end

function SkillTrait.checkAndApplyTrait(skillId, isActive, pawnId, pilot, skill)
	logger.logDebug(SUBMODULE, "Checking trait skill %s", skillId)
	local skillClass = SkillTrait.skills[skillId]
	if skillClass then
		local pawn = Game:GetPawn(pawnId)
		logger.logDebug(SUBMODULE, "Applying trait %s for pawn id %d (isActive: %s)", skillId, pawnId, tostring(isActive))
		skillClass:applyTrait(pawnId, pawn, isActive)
	end
end

return SkillTrait