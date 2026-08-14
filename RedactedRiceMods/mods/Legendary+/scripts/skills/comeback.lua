local GRID_DEF_BONUS = 33
local COMEBACK_PING_COLOR = GL_Color(80, 255, 120)

local customSkill = cplus_plus_ex.baseClasses.SkillActive:new{
	id = "RrComeback",
	name = "Comeback",
	description = "+".. GRID_DEF_BONUS.. " Grid Defense after the first building is damaged each mission.",
	constraints = {
		groups = {legendary_plus.GROUPS.ADD_GRID_DEF},
	},
	reusabilityLimit = cplus_plus_ex.REUSABLILITY.REUSABLE,
}

customSkill.DEBUG = false
local logger = memhack.logger
local SUBMODULE = logger.register("Legendary+", "Comeback", customSkill.DEBUG)

legendary_plus:addCustomTraitIcon(customSkill)

local function initGameSaveData()
	GAME = GAME or {}
	GAME.legendary_plus = GAME.legendary_plus or {}
	GAME.legendary_plus.comeback = GAME.legendary_plus.comeback or {}
	if GAME.legendary_plus.comeback.building_damaged == nil then
		GAME.legendary_plus.comeback.building_damaged = false
	end
end

local function isBuildingDamaged()
	initGameSaveData()
	return GAME.legendary_plus.comeback.building_damaged == true
end

local function foreachActiveInstance(fn)
	for _, mechInfo in ipairs(cplus_plus_ex:getMechsWithSkill(customSkill.id)) do
		local pilot = mechInfo.pilot
		local pilotId = pilot and pilot:getIdStr()
		if pilot and pilotId then
			for _, skillIndex in ipairs(mechInfo.skillIndices) do
				local skill = pilot:getLvlUpSkill(skillIndex)
				if skill then
					fn(pilot, pilotId, skillIndex, skill)
				end
			end
		end
	end
end

local function applyGridBonuses()
	foreachActiveInstance(function(pilot, pilotId, skillIndex, skill)
		if isBuildingDamaged() then
			skill:setGridBonus(GRID_DEF_BONUS)
		else
			skill:setGridBonus(0)
		end
	end)
end

local function clearAllGridBonuses()
	foreachActiveInstance(function(pilot, pilotId, skillIndex, skill)
		skill:setGridBonus(0)
	end)
end

local function pingComebackPawn(pawnId)
	if not Board then
		return
	end

	local pawn = Board:GetPawn(pawnId)
	if pawn then
		local loc = pawn:GetSpace()
		Board:AddAlert(loc, "COMEBACK")
		Board:Ping(loc, COMEBACK_PING_COLOR)
		logger.logDebug(SUBMODULE, "Comeback alert/ping on pawn %d at %s", pawnId, loc:GetString())
	end
end

local function pingComebackPawns()
	for _, mechInfo in ipairs(cplus_plus_ex:getMechsWithSkill(customSkill.id)) do
		pingComebackPawn(mechInfo.pawnId)
	end
end

local function onBuildingDamaged(point, damage)
	logger.logDebug(SUBMODULE, "Building damaged at %s (damage %s)",
			point and point:GetString() or "?", tostring(damage))

	initGameSaveData()
	if GAME.legendary_plus.comeback.building_damaged then
		return
	end

	GAME.legendary_plus.comeback.building_damaged = true
	applyGridBonuses()
	logger.logDebug(SUBMODULE, "Comeback triggered from building at %s",
			point and point:GetString() or "?")
	pingComebackPawns()
end

local function resetComeback()
	initGameSaveData()
	GAME.legendary_plus.comeback.building_damaged = false
	clearAllGridBonuses()
	logger.logDebug(SUBMODULE, "Comeback reset for new mission")
end

function customSkill:init()
	cplus_plus_ex.events.onSkillActive:subscribe(function(skillId, isActive, pawnId)
		if skillId ~= customSkill.id or not isActive or not isBuildingDamaged() then
			return
		end
		pingComebackPawn(pawnId)
	end)
end

function customSkill:setupEffect()
	table.insert(customSkill.events, modApi.events.onMissionStart:subscribe(resetComeback))
	table.insert(customSkill.events, modApi.events.onMissionNextPhaseCreated:subscribe(resetComeback))
	table.insert(customSkill.events, modApi.events.onMissionEnd:subscribe(clearAllGridBonuses))
	table.insert(customSkill.events, BoardEvents.onBuildingDamaged:subscribe(onBuildingDamaged))

	initGameSaveData()
	applyGridBonuses()
end

return customSkill
