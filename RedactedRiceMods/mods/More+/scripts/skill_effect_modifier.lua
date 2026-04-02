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

function SkillEffectModifier:modifySpaceDamage(pawn, isFinalEffect, spaceDamage, indexes, spacePawn)
	logger.logError(SUBMODULE, string.format("SkillEffectModifier modifySpaceDamage not implemented for skill %s", self.id))
end

-- Helper to get pawn at a location, checking temp positions first then board
function SkillEffectModifier:getPawnAt(loc, pawnPositions)
	local hash = more_plus.libs.boardUtils.getSpaceHash(loc)
	if pawnPositions[hash] ~= nil then
		return pawnPositions[hash]
	end
	return Board:GetPawn(loc)
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

		local pawnPositions = {}
		local pendingMoves = {}
		local effectsTable = extract_table(effects)

		for i, spaceDamage in ipairs(effectsTable) do
			-- If this is a movement, we need to track and update the temporary pawn posistions
			if spaceDamage:IsMovement() then
				local moveStart = spaceDamage:MoveStart()
				local moveEnd = spaceDamage:MoveEnd()
				local movingPawn = self:getPawnAt(moveStart, pawnPositions)

				if movingPawn then
					table.insert(pendingMoves, {
						pawn = movingPawn,
						pawnId = movingPawn:GetId(),
						from = moveStart,
						to = moveEnd
					})
					logger.logDebug(SUBMODULE, "Tracked move for pawn %d from %s to %s",
						movingPawn:GetId(), moveStart:GetString(), moveEnd:GetString())
				end

				-- If there is a delay or its the last one, we add the pending to
				-- the updated positions. Otherwise it stays in pending as it will not
				-- be considered executed yet. This allows for swapping two pawns for
				-- example
				if spaceDamage.fDelay ~= 0 or i == #effectsTable then
					for _, moveData in ipairs(pendingMoves) do
						local fromHash = more_plus.libs.boardUtils.getSpaceHash(moveData.from)
						local toHash = more_plus.libs.boardUtils.getSpaceHash(moveData.to)
						pawnPositions[fromHash] = false
						pawnPositions[toHash] = moveData.pawn
					end
					pendingMoves = {}
				end
			-- if its not a movement, apply any pending moves and then call into our modify fn
			else
				if #pendingMoves > 0 then
					for _, moveData in ipairs(pendingMoves) do
						local fromHash = more_plus.libs.boardUtils.getSpaceHash(moveData.from)
						local toHash = more_plus.libs.boardUtils.getSpaceHash(moveData.to)
						pawnPositions[fromHash] = false
						pawnPositions[toHash] = moveData.pawn
					end
					pendingMoves = {}
				end

				local spacePawn = self:getPawnAt(spaceDamage.loc, pawnPositions)
				self:modifySpaceDamage(pawn, isFinalEffect, spaceDamage, indexes, spacePawn)
			end
		end
	end
end

return SkillEffectModifier
