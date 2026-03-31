local SkillEffectModifier = {}

-- Extend SkillActive class
setmetatable(SkillEffectModifier, { __index = more_plus.SkillActive })
SkillEffectModifier.__index = SkillEffectModifier

function SkillEffectModifier:new(tbl)
	tbl = tbl or {}
	tbl.processedDamages = {}
	local obj = more_plus.SkillActive:new(tbl)
	setmetatable(obj, self)
	return obj
end

function SkillEffectModifier:setupEffect()
	table.insert(self.events, modapiext.events.onSkillBuild:subscribe(
		function(mission, pawn, weaponId, p1, p2, skillEffect)
			self:processEffects(pawn, false, skillEffect.effect, p2)
			self:processEffects(pawn, false, skillEffect.q_effect, p2)
		end))
	table.insert(self.events, modapiext.events.onFinalEffectBuild:subscribe(
		function(mission, pawn, weaponId, p1, p2, p3, skillEffect)
			self:processEffects(pawn, true, skillEffect.effect, p2)
			self:processEffects(pawn, true, skillEffect.q_effect, p2)
		end))
end

function SkillEffectModifier:hashSpaceDamage(pawnId, spaceDmg, p2)
	if p2 then
		return "p_"..pawnId.."_"..more_plus.libs.boardUtils.getSpaceHash(spaceDmg.loc)..
				"_"..more_plus.libs.boardUtils.getSpaceHash(p2)
	else
		return "p_"..pawnId.."_"..more_plus.libs.boardUtils.getSpaceHash(spaceDmg.loc)
	end
end

-- Handles keying based on space and only calls the modify function
-- if it hasn't been seen yet
function SkillEffectModifier:processEffects(pawn, isFinalEffect, effects, p2)
	if not pawn then
		return
	end
	local pilot = pawn:GetPilot()
	if pilot and not effects:empty() and cplus_plus_ex:isSkillOnPilot(self.id, pilot) then
		local indexes = cplus_plus_ex:getPilotSkillIndices(self.id, pilot)

		for _, spaceDamage in pairs(extract_table(effects)) do
			local spaceDamageKey = self:hashSpaceDamage(pawn:GetId(), spaceDamage, p2)
			if not self.processedDamages[spaceDamageKey] then
				self.processedDamages[spaceDamageKey] = true

				modApi:runLater(function()
					more_plus.SkillActive.skills[self.id].processedDamages = {}
				end)

				self:modifySpaceDamage(pawn, isFinalEffect, spaceDamage, indexes)
			end
		end
	end
end

function SkillEffectModifier:modifySpaceDamage(pawn, isFinalEffect, spaceDamage, indexes)
	LOG("ERROR: SkillEffectModifier modifySpaceDamage not implemented for skill %s", self.id)
end

return SkillEffectModifier
