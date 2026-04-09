local customSkill = more_plus.SkillEffectModifier:new{
	id = "RrCheapPlating",
	name = "Cheap Plating",
	description = "The first attack each mission does -3 damage.",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
}

customSkill.DEBUG = true
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
	more_plus.SkillEffectModifier.setupEffect(self)

	-- Reset first attack tracking on mission start
	table.insert(customSkill.events, modApi.events.onMissionStart:subscribe(function()
		logger.logDebug(SUBMODULE, "Mission start, resetting first attack tracking")
		initGameSaveData()
		GAME.more_plus.cheap_plating.used = {}
	end))
end

function customSkill:modifySpaceDamage(pawn, isFinalEffect, spaceDamage, indexes, spacePawn)
	
	logger.logDebug(SUBMODULE, "Space damage %s", spaceDamage.loc:GetString())
			
	-- Check if the target has the Cheap Plating skill
	if spacePawn and cplus_plus_ex:isSkillOnPawn(customSkill.id, spacePawn) and
	   		spaceDamage.iDamage > 0 and spaceDamage.iDamage ~= DAMAGE_DEATH and spaceDamage.iDamage ~= DAMAGE_ZERO then

		initGameSaveData()
		local pawnId = spacePawn:GetId()

		-- Check if this pawn hasn't used their first attack reduction yet
		if not GAME.more_plus.cheap_plating.used[pawnId] then
			-- TODO: Add another icon for this
			local previewState = isFinalEffect and more_plus.libs.weaponPreview.STATE_FINAL_EFFECT or
					more_plus.libs.weaponPreview.STATE_SKILL_EFFECT

			for _, idx in ipairs(indexes) do
				more_plus.libs.weaponPreview.ExecuteWithState(previewState,
						function()
							more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc,
									more_plus.commonIcons.noDamage.key.."_"..idx)
						end)
			end
			
			-- Reduce damage by 3 (minimum 0)
			local oldDamage = spaceDamage.iDamage
			spaceDamage.iDamage = math.max(0, spaceDamage.iDamage - 3)
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
