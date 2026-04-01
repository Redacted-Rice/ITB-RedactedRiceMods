local SkillEffectModifier = {}

-- Extend SkillActive class
setmetatable(SkillEffectModifier, { __index = more_plus.SkillActive })
SkillEffectModifier.__index = SkillEffectModifier

-- Initialize logger
SkillEffectModifier.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "SkillEffectModifier", SkillEffectModifier.DEBUG)

function SkillEffectModifier:new(tbl)
	tbl = tbl or {}
	local obj = more_plus.SkillActive:new(tbl)
	setmetatable(obj, self)
	return obj
end

function SkillEffectModifier:setupEffect()
	logger.logDebug(SUBMODULE, "Setting up effect modifier for %s", self.id)
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

function SkillEffectModifier:modifySpaceDamage(pawn, isFinalEffect, spaceDamage, indexes)
	logger.logError(SUBMODULE, "SkillEffectModifier modifySpaceDamage not implemented for skill %s", self.id)
end

-- Handles re-entrant skills that call the single click version and stuff like that
function SkillEffectModifier:processEffects(pawn, isFinalEffect, effects, p2)
	if modApiExt_internal.nestedCall_GetSkillEffect or modApiExt_internal.nestedCall_GetFinalEffect then
		logger.logDebug(SUBMODULE, "Skipping nested call for %s (GetSkillEffect: %s, GetFinalEffect: %s)",
			self.id, tostring(modApiExt_internal.nestedCall_GetSkillEffect), tostring(modApiExt_internal.nestedCall_GetFinalEffect))
		return
	end

	if not pawn then
		logger.logDebug(SUBMODULE, "No pawn found for %s", self.id)
		return
	end

	local pilot = pawn:GetPilot()
	if pilot and not effects:empty() and cplus_plus_ex:isSkillOnPilot(self.id, pilot) then
		local indexes = cplus_plus_ex:getPilotSkillIndices(self.id, pilot)
		logger.logDebug(SUBMODULE, "Processing space damages for %s", self.id)

		for _, spaceDamage in pairs(extract_table(effects)) do
			self:modifySpaceDamage(pawn, isFinalEffect, spaceDamage, indexes)
		end
	end
end

return SkillEffectModifier
