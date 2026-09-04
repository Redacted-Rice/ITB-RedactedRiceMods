local customSkill = cplus_plus_ex.baseClasses.SkillEffectModifier:new{
	id = "RrAce",
	name = "Ace",
	description = "Piloted mech gains Flying. +1 damage to Flying enemies.",
	constraints = {
		groups = {legendary_plus.GROUPS.MOVE_TYPE, legendary_plus.GROUPS.ADD_DAMAGE},
		pilotExclusions = {"Pilot_Recycler", cplus_plus_ex.isFlyingCyborg},
	},
	priority = 80,
	appliedFlying = {},
	reusabilityLimit = cplus_plus_ex.REUSABLILITY.REUSABLE,
}

customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("Legendary+", "Ace", customSkill.DEBUG)

legendary_plus:addCustomTraitIcon(customSkill)

local function applyFlying()
	for _, mechInfo in pairs(cplus_plus_ex:getMechsWithSkill(customSkill.id)) do
		local pawn = Board and Board:GetPawn(mechInfo.pawnId)
		if pawn and not pawn:IsFlying() then
			pawn:SetFlying(true)
			customSkill.appliedFlying[mechInfo.pawnId] = true
			logger.logDebug(SUBMODULE, "Granted flying to pawn %d", mechInfo.pawnId)
		else
			logger.logDebug(SUBMODULE, "Pawn %d not found or already has flying", mechInfo.pawnId)
		end
	end
end

local function clearAppliedFlying()
	for pawnId, _ in pairs(customSkill.appliedFlying) do
		local pawn = Board and Board:GetPawn(pawnId)
		if pawn and pawn:IsFlying() then
			pawn:SetFlying(false)
			logger.logDebug(SUBMODULE, "Removed flying from pawn %d", pawnId)
		else
			logger.logDebug(SUBMODULE, "Pawn %d not found or already is not flying", pawnId)
		end
	end
	customSkill.appliedFlying = {}
end

function customSkill:setupEffect()
	cplus_plus_ex.baseClasses.SkillEffectModifier.setupEffect(self)

	table.insert(customSkill.events, modApi.events.onMissionStart:subscribe(applyFlying))
	table.insert(customSkill.events, modApi.events.onMissionNextPhaseCreated:subscribe(
		function()
			modApi:runLater(function()
				applyFlying()
				logger.logDebug(SUBMODULE, "Later Applying flying to all mechs")
			end)
		end))
	table.insert(customSkill.events, modApi.events.onMissionEnd:subscribe(clearAppliedFlying))

	-- Apply right away if just awarded
	applyFlying()
end

function customSkill:clearEvents()
	clearAppliedFlying()
	cplus_plus_ex.baseClasses.SkillEffectModifier.clearEvents(self)
end

function customSkill.shouldBonus(source, targetPawn, damage)
	return source == customSkill.SOURCE_ATTACKER and targetPawn and
			targetPawn:IsEnemy() and targetPawn:IsFlying() and
			damage > 0 and damage ~= DAMAGE_DEATH and damage ~= DAMAGE_ZERO
end

function customSkill:modifyKillDamage(source, attackingPawn, spaceDamage, indexes, targetPawn, currentDamage)
	if self.shouldBonus(source, targetPawn, currentDamage) then
		return currentDamage + 1
	end
	return currentDamage
end

function customSkill:modifySpaceDamage(source, attackingPawn, phase, spaceDamage, indexes, targetPawn)
	if self.shouldBonus(source, targetPawn, spaceDamage.iDamage) then
		legendary_plus:previewExtraDamage(phase, spaceDamage.loc, attackingPawn:GetId(), customSkill)
		spaceDamage.iDamage = spaceDamage.iDamage + 1
		logger.logDebug(SUBMODULE, "Ace +1 vs flying at %s", spaceDamage.loc:GetString())
	end
end

return customSkill
