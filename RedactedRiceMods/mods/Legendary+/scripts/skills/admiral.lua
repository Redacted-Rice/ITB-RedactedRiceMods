local customSkill = cplus_plus_ex.baseClasses.SkillEffectModifier:new{
	id = "RrAdmiral",
	name = "Admiral",
	description = "Piloted mech floats on top of liquid tiles and deal +1 damage while on a one.",
	modified = {},
	-- Prospero already has flying so it doesn't help at all
	-- Flying cyborgs (Hornet) also don't benefit from amphibious
	constraints = {
		groups = {legendary_plus.GROUPS.MOVE_TYPE, legendary_plus.GROUPS.ADD_DAMAGE},
		pilotExclusions = {"Pilot_Recycler", cplus_plus_ex.isFlyingCyborg},
		squadExclusions = {"knight_ChessPawns"},
	},
	priority = 80,
	reusabilityLimit = cplus_plus_ex.REUSABLILITY.REUSABLE,
}

customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("Legendary+", "Admiral", customSkill.DEBUG)

-- Tell board utils this allows moving on (and through) water
BoardUtils.CanMoveOnWater = BoardUtils.makeAllowIfHasSkill(BoardUtils.CanMoveOnWater, customSkill.id)

legendary_plus:addCustomTraitIcon(customSkill)

function customSkill:setupEffect()
	cplus_plus_ex.baseClasses.SkillEffectModifier.setupEffect(self)

	table.insert(customSkill.events, modapiext.events.onTargetAreaBuild:subscribe(customSkill.moveTargetArea))
	table.insert(customSkill.events, modapiext.events.onSkillBuild:subscribe(customSkill.moveSkillBuild))
	table.insert(customSkill.events, modapiext.events.onPawnPositionChanged:subscribe(customSkill.addFlyingIfNeeded))
	table.insert(customSkill.events, modapiext.events.onPawnSelected:subscribe(customSkill.addFlyingIfNeeded))
	table.insert(customSkill.events, modApi.events.onMissionStart:subscribe(customSkill.applyOnMissionEnter))
	table.insert(customSkill.events, modApi.events.onMissionNextPhaseCreated:subscribe(customSkill.applyOnMissionEnter))
	table.insert(customSkill.events, modApi.events.onMissionEnd:subscribe(customSkill.clearFlying))
end

function customSkill.moveTargetArea(mission, pawn, weaponId, p1, targetArea)
	-- customSkill.recalculating guards against re entering this block from our own
	-- manual fireTargetAreaBuildHooks call below.
	if weaponId == "Move" and not customSkill.recalculating then
		local pilot = pawn:GetPilot()
		if pilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot)
				and legendary_plus.libs.boardUtils.isPawnHijackedFlying(pawn) then
			-- First time, manually calcualte our reachable points to avoid recalling getTargetArea
			-- as this messes with the weapon preview state
			if pawn:IsFlying() then
				logger.logDebug(SUBMODULE, "Recalculating move target area for amphibious pawn %d at %s",
						pawn:GetId(), p1:GetString())
				while not targetArea:empty() do
					targetArea:erase(0)
				end
				local groundedPoints = legendary_plus.libs.boardUtils.getMoveReachableInRange(
						pawn, pawn:GetMoveSpeed(), p1, "default")
				for idx = 1, groundedPoints:size() do
					targetArea:push_back(groundedPoints:index(idx))
				end

				-- Call the fireTargetAreaBuildHooks so other skills (e.g. nimble or supporter)
				-- can add to it as appropriate
				customSkill.recalculating = true
				modApiExt_internal.fireTargetAreaBuildHooks(mission, pawn, weaponId, p1, targetArea)
				customSkill.recalculating = false
			end
		end
	end
end

-- Override move skill to allow for building the "correct" path based on what is allowed
function customSkill.moveSkillBuild(mission, pawn, weaponId, p1, p2, skillEffect)
	if weaponId == "Move" then
		local pilot = pawn:GetPilot()
		if pilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot) then
			if legendary_plus.libs.boardUtils.skillEffectUsesPathMovement(skillEffect) then
				local path = legendary_plus.libs.boardUtils.findMovePath(pawn, p1, p2, "default", true)
				if path then
					legendary_plus.libs.boardUtils.addForcedMove(skillEffect, path)
				end
			end
		end
	end
end

function customSkill.applyOnMissionEnter()
	for _, mechInfo in pairs(cplus_plus_ex:getMechsWithSkill(customSkill.id)) do
		local pawn = Board:GetPawn(mechInfo.pawnId)
		local terrain = Board:GetTerrain(pawn:GetSpace())
		if legendary_plus.libs.boardUtils.isLiquid(terrain) then
			logger.logDebug(SUBMODULE, "Setting flying for pawn %d on liquid terrain", mechInfo.pawnId)
			legendary_plus.libs.boardUtils.setHijackedFlying(pawn, true)
		end
	end
end

function customSkill.addFlyingIfNeeded(mission, pawn)
	if cplus_plus_ex:isSkillOnPawn(customSkill.id, pawn) then
		local terrain = Board:GetTerrain(pawn:GetSpace())
		if legendary_plus.libs.boardUtils.isLiquid(terrain) then
			logger.logDebug(SUBMODULE, "Setting flying for pawn %d on liquid terrain", pawn:GetId())
			legendary_plus.libs.boardUtils.setHijackedFlying(pawn, true)
		else
			logger.logDebug(SUBMODULE, "Removing flying for pawn %d on solid terrain", pawn:GetId())
			legendary_plus.libs.boardUtils.setHijackedFlying(pawn, false)
		end
	end
end

function customSkill.clearFlying()
	for _, mechInfo in pairs(cplus_plus_ex:getMechsWithSkill(customSkill.id)) do
		local pawn = Board and Board:GetPawn(mechInfo.pawnId)
		if pawn then
			logger.logDebug(SUBMODULE, "Clearing flying for pawn %d", pawn:GetId())
			legendary_plus.libs.boardUtils.setHijackedFlying(pawn, false)
		end
	end
end

-- +1 damage while on water/lava
function customSkill.shouldBonus(source, attackingPawn, damage)
	if source ~= customSkill.SOURCE_ATTACKER or not attackingPawn or not damage
			or damage <= 0 or damage == DAMAGE_DEATH or damage == DAMAGE_ZERO then
		return false
	end
	return legendary_plus.libs.boardUtils.isLiquid(Board:GetTerrain(attackingPawn:GetSpace()))
end

function customSkill:modifyKillDamage(source, attackingPawn, spaceDamage, indexes, targetPawn, currentDamage)
	if targetPawn and targetPawn:IsEnemy() and self.shouldBonus(source, attackingPawn, currentDamage) then
		return currentDamage + 1
	end
	return currentDamage
end

function customSkill:modifySpaceDamage(source, attackingPawn, phase, spaceDamage, indexes, targetPawn)
	if targetPawn and targetPawn:IsEnemy() and self.shouldBonus(source, attackingPawn, spaceDamage.iDamage) then
		legendary_plus:previewExtraDamage(phase, spaceDamage.loc, attackingPawn:GetId(), customSkill)
		spaceDamage.iDamage = spaceDamage.iDamage + 1
		logger.logDebug(SUBMODULE, "Admiral +1 on liquid at %s", spaceDamage.loc:GetString())
	end
end

return customSkill
