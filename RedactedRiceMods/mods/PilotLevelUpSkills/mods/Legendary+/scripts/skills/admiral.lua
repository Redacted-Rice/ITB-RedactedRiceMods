local customSkill = cplus_plus_ex.baseClasses.SkillEffectModifier:new{
	id = "RrAdmiral",
	name = "Admiral",
	description = "Piloted mech floats on top of liquid tiles and deal +1 damage while on a one.",
	modified = {},
	constraints = {
		groups = {PlusHelper.GROUPS.MOVE_TYPE, PlusHelper.GROUPS.ADD_DAMAGE},
		-- Prospero already has flying so it doesn't help at all
		-- Flying cyborgs (Hornet) also don't benefit from amphibious
		pilotExclusions = {
			"Pilot_Recycler",
			cplus_plus_ex.isFlyingCyborg,
			cplus_plus_ex.isBurrowerCyborg,
		},
		squadExclusions = {"knight_ChessPawns"},
	},
	priority = 80,
	reusabilityLimit = cplus_plus_ex.REUSABLILITY.REUSABLE,
}

customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("Legendary+", "Admiral", customSkill.DEBUG)

legendary_plus:addCustomTraitIcon(customSkill)

function customSkill:applyTrait(pawnId, pawn, isActive)
	if isActive then
		logger.logDebug(SUBMODULE, "Setting pawn %d IgnoreLiquid (admiral)", pawnId)
		IgnoreLiquid.set(pawn, true)
		customSkill.modified[pawnId] = pawn
	elseif customSkill.modified[pawnId] then
		logger.logDebug(SUBMODULE, "Removing IgnoreLiquid from pawn %d", pawnId)
		IgnoreLiquid.set(pawn, false)
		customSkill.modified[pawnId] = nil
	end
end

-- Follow the init from skillTrait to keep the pattern similar
-- We can't do this with setup effect because 1. its too late and 2. we need to
-- undo it when it no longer applies. Setup effect is more geared towards global
-- set up than individual pawn setup like this does
function customSkill:init()
	cplus_plus_ex.events.onSkillActive:subscribe(function(skillId, isActive, pawnId)
		if skillId ~= customSkill.id then
			return
		end
		local pawn = Game:GetPawn(pawnId)
		logger.logDebug(SUBMODULE, "Applying trait %s for pawn id %d (isActive: %s)",
				customSkill.id, pawnId, tostring(isActive))
		customSkill:applyTrait(pawnId, pawn, isActive)
	end)
end

function customSkill:setupEffect()
	cplus_plus_ex.baseClasses.SkillEffectModifier.setupEffect(self)
end

function customSkill.shouldBonus(source, attackingPawn, damage)
	if source ~= customSkill.SOURCE_ATTACKER or not attackingPawn or not damage
			or damage <= 0 or damage == DAMAGE_DEATH or damage == DAMAGE_ZERO then
		return false
	end
	return BoardUtils.isLiquid(Board:GetTerrain(attackingPawn:GetSpace()))
end

function customSkill:modifyKillDamage(source, attackingPawn, spaceDamage, indexes, targetPawn, currentDamage)
	if targetPawn and targetPawn:IsEnemy() and self.shouldBonus(source, attackingPawn, currentDamage) then
		return currentDamage + 1
	end
	return currentDamage
end

function customSkill:modifySpaceDamage(source, attackingPawn, phase, spaceDamage, indexes, targetPawn)
	if targetPawn and targetPawn:IsEnemy() and self.shouldBonus(source, attackingPawn, spaceDamage.iDamage) then
		legendary_plus.libs.weaponPreview.ExecuteWithState(PlusHelper.convertPhase(phase),
			function()
				legendary_plus.addWeaponPreviewIcon(phase, spaceDamage.loc,
						legendary_plus.commonIcons.extraDamage.key,
						GetText(customSkill.name) .. ": " .. GetText(customSkill.description))
			end, attackingPawn:GetId()
		)
		spaceDamage.iDamage = spaceDamage.iDamage + 1
		logger.logDebug(SUBMODULE, "Admiral +1 on liquid at %s", spaceDamage.loc:GetString())
	end
end

return customSkill
