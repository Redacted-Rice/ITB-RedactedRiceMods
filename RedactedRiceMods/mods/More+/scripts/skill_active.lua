local SkillActive = {}
SkillActive.skills = {}

SkillActive.__index = SkillActive

-- Initialize logger
SkillActive.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "SkillActive", SkillActive.DEBUG)

function SkillActive:new(tbl)
	tbl = tbl or {}
	tbl.events = {}
	setmetatable(tbl, self)
	self.skills[tbl.id] = tbl
	return tbl
end

function SkillActive:addCustomTrait()
	local iconImg = "img/combat/icons/icon_mp_"..self.id..".png"
	self.icon = iconImg
	logger.logDebug(SUBMODULE, "Adding active icon %s at %s", self.id, iconImg)
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

function SkillActive:setupEffect()
	logger.logError(SUBMODULE, string.format("SkillActive setupEffect not implemented for skill %s", self.id))
end

function SkillActive:clearEvents()
	logger.logDebug(SUBMODULE, "Clearing events for %s", self.id)
	for _, event in pairs(self.events) do
		event:unsubscribe()
	end
	self.events = {}
end

function SkillActive:baseInit()
	cplus_plus_ex.events.onSkillActive:subscribe(self.clearAndReSetUpEffect)
end

function SkillActive.clearAndReSetUpEffect(skillId, isActive, pawnId, pilot, skillStruct)
	logger.logDebug(SUBMODULE, "Checking skill %s", skillId)
	local skillClass = SkillActive.skills[skillId]
	if skillClass then
		-- Clear events
		skillClass:clearEvents()

		-- Then add them back if any are active
		if cplus_plus_ex:isSkillActive(skillId) then
			logger.logDebug(SUBMODULE, "Setting up skill %s for pawn id %d", skillId, pawnId)
			skillClass:setupEffect()
		end
	end
end

return SkillActive