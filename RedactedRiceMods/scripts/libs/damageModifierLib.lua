--[[
DamageModifierLib - Modify weapon SpaceDamage during skill builds and Board:IsDeadly.

Libs Wiki: https://github.com/Redacted-Rice/ITB-RedactedRiceMods/wiki

Author: Das Keifer of Redacted Rice
Discord Server: https://discord.gg/CNjTVrpN4v

Overview:
Walks skill/final effect lists (requires modapiext) while tracking pawn moves
and pushes, then dispatches priority events so subscribers can mutate each
SpaceDamage. The same modifiers can also run for Board:IsDeadly preview
checks via onEvaluatingDeadly.

API:
  DamageModifierLib.events.onSkillEffectModify:subscribe(fn, priority)
      fn(spaceDamage, attackingPawn, targetPawn, phase)
        spaceDamage   - mutable SpaceDamage from the skill effect
        attackingPawn - pawn building the skill effect
        targetPawn    - pawn currently on spaceDamage.loc after push/move
                        tracking (may be nil)
        phase         - one of DamageModifierLib.PHASE_*
      Fired once per non-movement SpaceDamage during skill/final builds.

  DamageModifierLib.events.onSkillEffectEvaluated:subscribe(fn, priority)
      fn(phase, outEffects)
        phase      - one of DamageModifierLib.PHASE_*
        outEffects - mutable array; append SpaceDamage entries to add to the
                     skill effect. Appended effects are processed in a new
                     pass (avoid infinite loops).
      Fired once after all SpaceDamages in a pass have been processed.
      Use this to emit aggregated/derived effects after seeing the full list
      (e.g. one heal for N kills). Priority alone is not enough for that.

  DamageModifierLib.events.onEvaluatingDeadly:subscribe(fn, priority)
      fn(spaceDamage, attackingPawn, targetPawn)
        spaceDamage   - mutable SpaceDamage COPY (mutate this)
        attackingPawn - pawn passed to Board:IsDeadly
        targetPawn    - pawn on spaceDamage.loc (may be nil)
      Fired from Board:IsDeadly / GetModifiedDamage. No side effects
      (icons, sScript, etc.).

  DamageModifierLib:GetModifiedDamage(spaceDamage, attackingPawn) -> number
  DamageModifierLib:GetDamageDelta(spaceDamage, attackingPawn) -> number
  DamageModifierLib:GetPawnSpace(pawn) / :GetPawnAt(loc)
      Position helpers that respect in-progress push/move tracking during
      a skill-effect walk. Outside a walk, fall back to Board/pawn APIs.

  subscription:unsubscribe()

Priority guidance (lower runs first):
  INTERNAL_PRIORITY (0) - framework use only
  30-50  - early transformations / blocks
  80     - additive bonuses after doubling interactions
  100    - default
  150    - near-final finishers (kill shot)
  180-200 - late follow-ups / post pass (skill effect evaluated)
]]

local VERSION = "1.0.0"

local DEBUG = true

local DEFAULT_PRIORITY = 100
local INTERNAL_PRIORITY = 0

local function logDebug(fmt, ...)
	if DEBUG then
		LOG("DamageModifierLib: " .. string.format(fmt, ...))
	end
end

local function describePawn(pawn)
	if not pawn then
		return "nil"
	end
	return string.format("id=%s type=%s team=%s",
			tostring(pawn:GetId()), tostring(pawn:GetType()), tostring(pawn:GetTeam()))
end

local function resolvePriority(priority)
	if priority ~= nil then
		assert(type(priority) == "number", "Event priority must be a number")
		return priority
	end
	return DEFAULT_PRIORITY
end

-- Priority-aware Event wrapper around modloader Event.
-- Functionally equivalent to Event:subscribe/dispatch; adds optional priority.
local function createPriorityEvent(eventName)
	local event = Event({ eventName = eventName })
	local subscriberPriorities = {}
	local originalSubscribe = event.subscribe
	local originalUnsubscribe = event.unsubscribe

	event.subscribe = function(eventSelf, fn, priority)
		local sub = originalSubscribe(eventSelf, fn)
		subscriberPriorities[sub] = resolvePriority(priority)
		table.sort(eventSelf.subscribers, function(a, b)
			local priorityA = subscriberPriorities[a] or DEFAULT_PRIORITY
			local priorityB = subscriberPriorities[b] or DEFAULT_PRIORITY
			return priorityA < priorityB
		end)
		return sub
	end

	event.unsubscribe = function(eventSelf, subscription)
		local result = originalUnsubscribe(eventSelf, subscription)
		if result and type(subscription) == "table" then
			subscriberPriorities[subscription] = nil
		end
		return result
	end

	return event
end

-- The real target is whatever pawn stands on the damaged tile.
-- Board:IsDeadly's pawn arg is the acting/attacking pawn.
local function resolveTargetPawn(spaceDamage)
	if Board and spaceDamage.loc and Board:IsValid(spaceDamage.loc) then
		return Board:GetPawn(spaceDamage.loc)
	end
	return nil
end

local function copySpaceDamage(spaceDamage)
	return SpaceDamage(
			Point(spaceDamage.loc.x, spaceDamage.loc.y),
			spaceDamage.iDamage,
			spaceDamage.iPush or DIR_NONE
	)
end

-- Runs onEvaluatingDeadly against a copy of spaceDamage.
-- Returns originalDamage, modifiedDamage, modifiedCopy.
local function evaluate(spaceDamage, attackingPawn)
	Assert.Equals("userdata", type(spaceDamage), "Argument #1")

	local originalDamage = spaceDamage.iDamage
	local event = DamageModifierLib.events.onEvaluatingDeadly

	if not spaceDamage.loc or #event.subscribers == 0 then
		return originalDamage, originalDamage, spaceDamage
	end

	local modified = copySpaceDamage(spaceDamage)
	local targetPawn = resolveTargetPawn(spaceDamage)

	logDebug("Evaluating at %s: baseDamage=%s target={%s} attacker={%s} subscribers=%d",
			spaceDamage.loc:GetString(), tostring(originalDamage),
			describePawn(targetPawn), describePawn(attackingPawn),
			#event.subscribers)

	event:dispatch(modified, attackingPawn, targetPawn)

	logDebug("Evaluated at %s: baseDamage=%s modifiedDamage=%s delta=%s",
			spaceDamage.loc:GetString(), tostring(originalDamage),
			tostring(modified.iDamage), tostring(modified.iDamage - originalDamage))

	return originalDamage, modified.iDamage, modified
end

local function getModifiedDamage(self, spaceDamage, attackingPawn)
	local _, modifiedDamage = evaluate(spaceDamage, attackingPawn)
	return modifiedDamage
end

local function getDamageDelta(self, spaceDamage, attackingPawn)
	local originalDamage, modifiedDamage = evaluate(spaceDamage, attackingPawn)
	return modifiedDamage - originalDamage
end

local function onBoardClassInitialized(BoardClass, board)
	local previousIsDeadly = board.IsDeadly

	BoardClass.IsDeadly = function(self, spaceDamage, attackingPawn)
		if not spaceDamage or not spaceDamage.loc
				or #DamageModifierLib.events.onEvaluatingDeadly.subscribers == 0 then
			return previousIsDeadly(self, spaceDamage, attackingPawn)
		end

		local originalDamage, usedDamage, modified = evaluate(spaceDamage, attackingPawn)
		local damageChanged = usedDamage ~= originalDamage
		local toCheck = damageChanged and modified or spaceDamage

		local result = previousIsDeadly(self, toCheck, attackingPawn)
		logDebug("IsDeadly result at %s: baseDamage=%s modifiedDamage=%s changed=%s deadly=%s",
				spaceDamage.loc:GetString(), tostring(originalDamage),
				tostring(usedDamage), tostring(damageChanged), tostring(result))
		return result
	end
end

--------------------------------------------------------------------------
-- Skill effect walk: push/move tracking + onSkillEffectModify /
-- onSkillEffectEvaluated
--------------------------------------------------------------------------

-- Aligns with the WeaponPreview Lib enums
local PHASE_NONE = 0
local PHASE_SKILL_EFFECT = 1
local PHASE_TARGET_AREA = 2
local PHASE_QUEUED_SKILL = 3
local PHASE_SECOND_TARGET_AREA = 4
local PHASE_FINAL_EFFECT = 5
local PHASE_QUEUED_FINAL_EFFECT = 6

-- Pawn position/push tracking state - reset per effect-processing pass
local spacesWithPawns = {}
local pawnPositions = {}
local pendingMoves = {}

local function getSpaceHash(spaceOrX, y)
	local pX = spaceOrX
	local pY = y
	if not y then
		pX = spaceOrX.x
		pY = spaceOrX.y
	end
	return pY * 10 + pX
end

local function getPawnSpace(pawn)
	if pawnPositions[pawn:GetId()] ~= nil then
		return pawnPositions[pawn:GetId()]
	end
	return pawn:GetSpace()
end

local function getPawnAt(loc)
	local hash = getSpaceHash(loc)
	if spacesWithPawns[hash] ~= nil then
		return spacesWithPawns[hash]
	end
	return Board:GetPawn(loc)
end

local function accountForMove(moveStart, moveEnd)
	local movingPawn = getPawnAt(moveStart)
	if movingPawn then
		table.insert(pendingMoves, {
			pawn = movingPawn,
			pawnId = movingPawn:GetId(),
			from = moveStart,
			to = moveEnd
		})
		logDebug("Tracked move for pawn %d from %s to %s",
				movingPawn:GetId(), moveStart:GetString(), moveEnd:GetString())
	end
end

local function applyAndClearPendingMoves()
	for _, moveData in ipairs(pendingMoves) do
		local fromHash = getSpaceHash(moveData.from)
		local toHash = getSpaceHash(moveData.to)
		spacesWithPawns[fromHash] = false
		spacesWithPawns[toHash] = moveData.pawn
		pawnPositions[moveData.pawn:GetId()] = moveData.to
	end
	pendingMoves = {}
end

-- Process damage list effect by effect, dispatching onSkillEffectModify per
-- space damage. Positions stay current so targetPawn is accurate.
local function processEffectByEffect(attackingPawn, effectsTable, phase)
	if #effectsTable == 0 then
		return
	end

	spacesWithPawns = {}
	pawnPositions = {}
	pendingMoves = {}

	local i = 1
	-- Arbitrary max space damage processing
	local maxIterations = 250
	local iterations = 0
	local initialTableSize = #effectsTable

	while i <= #effectsTable and iterations < maxIterations do
		iterations = iterations + 1
		local spaceDamage = effectsTable[i]

		if spaceDamage:IsMovement() then
			accountForMove(spaceDamage:MoveStart(), spaceDamage:MoveEnd())

			if spaceDamage.fDelay ~= 0 or i == #effectsTable then
				applyAndClearPendingMoves()
			end
		else
			applyAndClearPendingMoves()

			local targetPawn = getPawnAt(spaceDamage.loc)
			DamageModifierLib.events.onSkillEffectModify:dispatch(
					spaceDamage, attackingPawn, targetPawn, phase)

			if spaceDamage.iPush ~= DIR_NONE and spaceDamage.iPush >= 0 and spaceDamage.iPush <= 3 and
					getPawnAt(spaceDamage.loc + DIR_VECTORS[spaceDamage.iPush]) == nil then
				accountForMove(spaceDamage.loc, spaceDamage.loc + DIR_VECTORS[spaceDamage.iPush])

				if spaceDamage.fDelay ~= 0 or i == #effectsTable then
					applyAndClearPendingMoves()
				end
			end
		end

		i = i + 1
	end

	if iterations >= maxIterations then
		logDebug("Hit max iterations in processEffectByEffect! Possible infinite loop. "..
				"i=%d, #effectsTable=%d, initialSize=%d, iterations=%d",
				i, #effectsTable, initialTableSize, iterations)
	end

	-- Post-pass: subscribers append derived/aggregated effects to outEffects
	local newEffects = {}
	DamageModifierLib.events.onSkillEffectEvaluated:dispatch(phase, newEffects)
	return newEffects
end

local function processEffectsWithQueuedFlag(attackingPawn, skillEffect, effectsTable, isFinalEffect, isQueued)
	local phase = isFinalEffect and PHASE_FINAL_EFFECT or PHASE_SKILL_EFFECT
	if isQueued then
		phase = isFinalEffect and PHASE_QUEUED_FINAL_EFFECT or PHASE_QUEUED_SKILL
	end

	if #effectsTable == 0 then
		return
	end

	local damagesToProcess = effectsTable
	-- Arbitrary max number of new space damages that can be added to prevent infinite loops
	local maxPasses = 25
	local currentPass = 0

	while damagesToProcess and #damagesToProcess > 0 and currentPass < maxPasses do
		local newEffects = processEffectByEffect(attackingPawn, damagesToProcess, phase)

		if newEffects and #newEffects > 0 then
			for _, newEffect in ipairs(newEffects) do
				if isQueued then
					skillEffect:AddQueuedDamage(newEffect)
				else
					skillEffect:AddDamage(newEffect)
				end
			end

			damagesToProcess = newEffects
			currentPass = currentPass + 1
		else
			break
		end
	end

	if currentPass >= maxPasses and damagesToProcess and #damagesToProcess > 0 then
		logDebug("Chaining effect limit reached (%d passes, phase=%s) with %d damages remaining. Attacker pawn %d",
				maxPasses, tostring(phase), #damagesToProcess, attackingPawn:GetId())
	end
end

local function processSkillEffects(attackingPawn, isFinalEffect, skillEffect)
	if modApiExt_internal and (modApiExt_internal.nestedCall_GetSkillEffect
			or modApiExt_internal.nestedCall_GetFinalEffect) then
		return
	end

	if not attackingPawn then
		return
	end

	local modifyEvent = DamageModifierLib.events.onSkillEffectModify
	local evaluatedEvent = DamageModifierLib.events.onSkillEffectEvaluated
	if #modifyEvent.subscribers == 0 and #evaluatedEvent.subscribers == 0 then
		return
	end

	local regularEffects = extract_table(skillEffect.effect)
	if #regularEffects > 0 then
		processEffectsWithQueuedFlag(attackingPawn, skillEffect, regularEffects, isFinalEffect, false)
	end

	if not skillEffect.q_effect:empty() then
		local queuedEffects = extract_table(skillEffect.q_effect)
		if #queuedEffects > 0 then
			processEffectsWithQueuedFlag(attackingPawn, skillEffect, queuedEffects, isFinalEffect, true)
		end
	end
end

local function onModsInitialized()
	if VERSION < DamageModifierLib.version then
		return
	end

	if DamageModifierLib.initialized then
		return
	end

	DamageModifierLib:finalizeInit()
	DamageModifierLib.initialized = true
end

modApi.events.onModsInitialized:subscribe(onModsInitialized)

local isNewestVersion = DamageModifierLib == nil
	or modApi:isVersionAbove(VERSION, DamageModifierLib.version)

if isNewestVersion then
	DamageModifierLib = DamageModifierLib or {}
	DamageModifierLib.version = VERSION
	DamageModifierLib.DEFAULT_PRIORITY = DEFAULT_PRIORITY
	DamageModifierLib.INTERNAL_PRIORITY = INTERNAL_PRIORITY

	DamageModifierLib.PHASE_NONE = PHASE_NONE
	DamageModifierLib.PHASE_SKILL_EFFECT = PHASE_SKILL_EFFECT
	DamageModifierLib.PHASE_TARGET_AREA = PHASE_TARGET_AREA
	DamageModifierLib.PHASE_QUEUED_SKILL = PHASE_QUEUED_SKILL
	DamageModifierLib.PHASE_SECOND_TARGET_AREA = PHASE_SECOND_TARGET_AREA
	DamageModifierLib.PHASE_FINAL_EFFECT = PHASE_FINAL_EFFECT
	DamageModifierLib.PHASE_QUEUED_FINAL_EFFECT = PHASE_QUEUED_FINAL_EFFECT

	DamageModifierLib.events = DamageModifierLib.events or {}
	DamageModifierLib.events.onEvaluatingDeadly = createPriorityEvent("onEvaluatingDeadly")
	DamageModifierLib.events.onSkillEffectModify = createPriorityEvent("onSkillEffectModify")
	DamageModifierLib.events.onSkillEffectEvaluated = createPriorityEvent("onSkillEffectEvaluated")

	function DamageModifierLib:finalizeInit()
		self.GetModifiedDamage = getModifiedDamage
		self.GetDamageDelta = getDamageDelta
		self.GetPawnSpace = function(_, pawn) return getPawnSpace(pawn) end
		self.GetPawnAt = function(_, loc) return getPawnAt(loc) end

		-- Skill effect walk events
		if modapiext and modapiext.events then
			modapiext.events.onSkillBuild:subscribe(function(mission, pawn, weaponId, p1, p2, skillEffect)
				processSkillEffects(pawn, false, skillEffect)
			end)
			modapiext.events.onFinalEffectBuild:subscribe(function(mission, pawn, weaponId, p1, p2, p3, skillEffect)
				processSkillEffects(pawn, true, skillEffect)
			end)
		else
			logDebug("modapiext not available; skill effect walk disabled (IsDeadly still works)")
		end

		logDebug("Finalized DamageModifierLib %s (onEvaluatingDeadly=%d onSkillEffectModify=%d onSkillEffectEvaluated=%d)",
				VERSION,
				#self.events.onEvaluatingDeadly.subscribers,
				#self.events.onSkillEffectModify.subscribers,
				#self.events.onSkillEffectEvaluated.subscribers)
	end

	-- Available immediately for callers that need them before finalizeInit.
	DamageModifierLib.GetModifiedDamage = getModifiedDamage
	DamageModifierLib.GetDamageDelta = getDamageDelta
	DamageModifierLib.GetPawnSpace = function(_, pawn) return getPawnSpace(pawn) end
	DamageModifierLib.GetPawnAt = function(_, loc) return getPawnAt(loc) end

	modApi.events.onBoardClassInitialized:subscribe(onBoardClassInitialized)
end

return DamageModifierLib
