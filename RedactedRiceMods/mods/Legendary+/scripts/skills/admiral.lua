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

legendary_plus:addCustomTraitIcon(customSkill)

function customSkill:setupEffect()
	cplus_plus_ex.baseClasses.SkillEffectModifier.setupEffect(self)

	table.insert(customSkill.events, modapiext.events.onTargetAreaBuild:subscribe(customSkill.moveTargetArea))
	table.insert(customSkill.events, modapiext.events.onPawnPositionChanged:subscribe(customSkill.addFlyingIfNeeded))
	table.insert(customSkill.events, modapiext.events.onPawnSelected:subscribe(customSkill.addFlyingIfNeeded))
	table.insert(customSkill.events, modApi.events.onMissionStart:subscribe(customSkill.applyOnMissionEnter))
	table.insert(customSkill.events, modApi.events.onMissionNextPhaseCreated:subscribe(customSkill.applyOnMissionEnter))
	table.insert(customSkill.events, modApi.events.onMissionEnd:subscribe(customSkill.clearFlying))
end

function customSkill.moveTargetArea(mission, pawn, weaponId, p1, targetArea)
	if weaponId == "Move" then
		local pilot = pawn:GetPilot()
		if pilot and cplus_plus_ex:isSkillOnPilot(customSkill.id, pilot)
				and legendary_plus.libs.boardUtils.isPawnHijackedFlying(pawn) then
			-- First time, unset flying and get a new set of points without flying
			-- Note other things that change path must use isPawnFlying in BoardUtils
			-- To work right on the second pass or else it could see the pawn as flying
			-- when it shouldn't be
			if pawn:IsFlying() then
				logger.logDebug(SUBMODULE, "Recalculating move target area for amphibious pawn %d at %s",
						pawn:GetId(), p1:GetString())
				pawn:SetFlying(false)
				while not targetArea:empty() do
					targetArea:erase(0)
				end
				local newPoints = Move:GetTargetArea(p1)
				for idx = 1, newPoints:size() do
					targetArea:push_back(newPoints:index(idx))
				end
				pawn:SetFlying(true)
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
