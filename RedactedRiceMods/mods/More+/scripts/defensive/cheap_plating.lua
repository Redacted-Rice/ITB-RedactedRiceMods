local customSkill = cplus_plus_ex.baseClasses.SkillEffectModifier:new{
	id = "RrCheapPlating",
	name = "Cheap Plating",
	description = "The first attack each mission that would damage the piloted mech does -3 damage.",
	reusability = cplus_plus_ex.REUSABLILITY.PER_PILOT,
	priority = 50, -- after impervious, before additive bonuses
	modifiesKillDamage = true,
}

customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("More+", "Cheap Plating", customSkill.DEBUG)

-- Adds the icon for the UI
-- Adding for trait replace handled lower
customSkill.icon = "img/combat/icons/icon_mp_"..customSkill.id..".png"

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

local function isPlatingUsed(pawnId)
	return GAME and GAME.more_plus and GAME.more_plus.cheap_plating and
			GAME.more_plus.cheap_plating.used and GAME.more_plus.cheap_plating.used[pawnId]
end

-- Change icon based on if its been used or not
more_plus.libs.traitReplace:addStateful{
	targetTrait = "massive",
	func = function(trait, pawn)
		if not cplus_plus_ex:isSkillOnPawn(customSkill.id, pawn) then
			return 0  -- Don't display
		end

		initGameSaveData()
		local pawnId = pawn:GetId()
		if GAME.more_plus.cheap_plating.used[pawnId] then
			return 2  -- Used state
		else
			return 1  -- Active state
		end
	end,
	states = {
		{
			icon = "img/combat/icons/icon_mp_RrCheapPlating.png",
			desc_title = "Cheap Plating (Active)",
			desc_text = "The next attack that would damage this mech does -3 damage.",
		},
		{
			icon = "img/combat/icons/icon_mp_RrCheapPlating_used.png",
			desc_title = "Cheap Plating (Used)",
			desc_text = "The damage reduction has been used this mission.",
		},
	}
}

function customSkill:modifyKillDamage(source, attackingPawn, spaceDamage, indexes, targetPawn, currentDamage)
	-- Check if the target is taking damage
	if source ~= customSkill.SOURCE_TARGET or not (currentDamage > 0 and currentDamage ~= DAMAGE_DEATH and currentDamage ~= DAMAGE_ZERO) then
		return currentDamage
	end

	-- Check if this pawn hasn't used their first attack reduction yet
	if isPlatingUsed(targetPawn:GetId()) then
		return currentDamage
	end

	-- Reduce damage by 3 (minimum DAMAGE_ZERO)
	local newDamage = math.max(0, currentDamage - 3)
	-- If it no longer does damage, switch to damage zero to display right
	return newDamage == 0 and DAMAGE_ZERO or newDamage
end

function customSkill:modifySpaceDamage(source, attackingPawn, phase, spaceDamage, indexes, targetPawn)
	local newDamage = self:modifyKillDamage(source, attackingPawn, spaceDamage, indexes, targetPawn, spaceDamage.iDamage)
	if newDamage == spaceDamage.iDamage then
		return
	end

	initGameSaveData()
	local pawnId = targetPawn:GetId()
	more_plus.libs.weaponPreview.ExecuteWithState(more_plus.convertPhase(phase),
		function()
			more_plus.libs.weaponPreview:AddAnimation(spaceDamage.loc, more_plus.commonIcons.armor3.key, nil,  -- delay
					more_plus.WEAPON_PREVIEW_GROUP_ID, GetText(customSkill.name) .. ": " .. GetText(customSkill.description))
		end, pawnId
	)

	local oldDamage = spaceDamage.iDamage
	spaceDamage.iDamage = newDamage
	-- Mark that this pawn has used their first attack reduction
	spaceDamage.sScript = spaceDamage.sScript .. [[
			GAME.more_plus.cheap_plating.used[]].. pawnId ..[[] = true
	]]
	logger.logDebug(SUBMODULE, "Pawn %d using first attack reduction, reducing damage from %d to %d",
			pawnId, oldDamage, spaceDamage.iDamage)
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

return customSkill
