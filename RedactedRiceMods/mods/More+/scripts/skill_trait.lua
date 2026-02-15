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

SkillTrait.trait = mod_loader.mods[modApi.currentMod].libs.trait
function SkillTrait:addCustomTrait()
	local iconImg = "img/combat/icons/icon_mp_"..self.id..".png"
	modApi:appendAsset(iconImg, mod_loader.mods[modApi.currentMod].resourcePath..iconImg)
	self.trait:add{
		func = function(trait, pawn)
			if cplus_plus_ex:isSkillOnPawn(self.id, pawn) then
				return true
			end
			return false
		end,
		icon = iconImg,
		--icon_offset = Point(0,9),
		desc_title = self.name,
		desc_text = self.description,
	}
end

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