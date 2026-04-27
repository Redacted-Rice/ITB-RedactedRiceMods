local customSkill = cplus_plus_ex.baseClasses.SkillEffectModifier:new{
	id = "RrCheapPlating",
	name = "Cheap Plating",
	description = "The first attack each mission that would damage the piloted mech does -3 damage.",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT
}

customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Cheap Plating", customSkill.DEBUG)

customSkill:addCustomTrait()

-- Initialize GAME save data structure
local function initGameSaveData()
	if GAME == nil then
		GAME = {}
	end

	if GAME.more_plus == nil then
		GAME.more_plus = {}
	end

	if GAME.more_plus.cheap_plating == nil then
		GAME.more_plus.cheap_plating = {}
	end

	if GAME.more_plus.cheap_plating.used == nil then
		GAME.more_plus.cheap_plating.used = {}
	end
end

function customSkill:setupEffect()
	-- Call parent setupEffect to subscribe to skill build events
	cplus_plus_ex.baseClasses.SkillEffectModifier.setupEffect(self)

	-- Reset first attack tracking on mission start
	table.insert(customSkill.events, modApi.events.onMissionStart:subscribe(function()
		logger.logDebug(SUBMODULE, "Mission start, resetting first attack tracking")
		initGameSaveData()
		GAME.more_plus.cheap_plating.used = {}
	end))
end

function customSkill:modifySpaceDamage(source, attackingPawn, phase, spaceDamage, indexes, targetPawn)
	-- Check if the target is taking damage
	if source == self.SOURCE_TARGET and
			spaceDamage.iDamage > 0 and spaceDamage.iDamage ~= DAMAGE_DEATH and
			spaceDamage.iDamage ~= DAMAGE_ZERO then

		initGameSaveData()
		local pawnId = targetPawn:GetId()

		-- Check if this pawn hasn't used their first attack reduction yet
		if not GAME.more_plus.cheap_plating.used[pawnId] then
			for _, idx in ipairs(indexes) do
				more_plus.libs.weaponPreview.ExecuteWithState(more_plus.convertPhase(phase),
						function()
							more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc,
									more_plus.commonIcons.armor3.key.."_"..idx)
						end)
			end

			-- Reduce damage by 3 (minimum DAMAGE_ZERO)
			local oldDamage = spaceDamage.iDamage
			spaceDamage.iDamage = math.max(0, oldDamage - 3)
			-- If it no longer does damage, switch to damage zero to display right
			if spaceDamage.iDamage == 0 then
				spaceDamage.iDamage = DAMAGE_ZERO
			end
			-- Mark that this pawn has used their first attack reduction
			spaceDamage.sScript = spaceDamage.sScript .. [[
					GAME.more_plus.cheap_plating.used[]].. pawnId ..[[] = true
			]]
			logger.logDebug(SUBMODULE, "Pawn %d using first attack reduction, reducing damage from %d to %d",
					pawnId, oldDamage, spaceDamage.iDamage)
		else
			logger.logDebug(SUBMODULE, "Pawn %d has already used their first attack reduction, skipping", pawnId)
		end
	end

	return nil
end

return customSkill
