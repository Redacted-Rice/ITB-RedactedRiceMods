--[[
pawnTypeUtils - functions to allow determining more detailed pawn types

Author: Das Keifer of Redacted Rice
Version: 1.0.0
Discord Server: https://discord.gg/CNjTVrpN4v

Builds on top of easy edit to allow determining in game what spawn
category a pawn belongs to
]]

local pawnTypeUtils = {
	Version = "1.0.0",
}

-- Easy edit defines these locally so we have to redefine
pawnTypeUtils.EASY_EDIT_CATEGORIES = { "Core", "Leaders", "Unique", "Bots" }
pawnTypeUtils.SPAWN_CATEGORIES_STRS = { "Core", "Leader", "Unique", "Bots", "Boss" }
pawnTypeUtils.SPAWN_CATEGORIES = { CORE = 1, LEADER = 2, UNIQUE = 3, BOTS = 4, BOSS = 5 }

--- Check if the current mission is a finale mission.
local function isFinaleMission()
	local mission = GetCurrentMission()
	return mission and (mission.ID == "Mission_Final" or mission.ID == "Mission_Final_Cave")
end

--- Convert pawn type to base ID for enemy list lookup.
-- Strips trailing digit: Beetle1 -> Beetle, BeetleBoss -> BeetleBoss
local function pawnTypeToBaseId(pawnType)
	if type(pawnType) ~= "string" or pawnType == "" then
		return pawnType
	end

	local withoutDigit = pawnType:match("^(.+)%d$")
	if withoutDigit then
		return withoutDigit
	end
	return pawnType
end

--- Check if a base ID is in a specific category of an enemy list.
local function isInSpawnCategory(enemyList, baseId, category)
	for _, id in ipairs(enemyList.enemies[category]) do
		if id == baseId then
			return true
		end
	end
	return false
end


--- Check if a pawn is the current mission's boss.
local function isBoss(pawn)
	local pawnType = pawn:GetType()

	-- First check if the mission has a boss pawn
	local mission = GetCurrentMission()
	if mission and mission.BossPawn then
		return pawnType == mission.BossPawn
	end

	-- Or check if its in any of the easy edit missions bosses
	if easyEdit and easyEdit.missions and easyEdit.missions._children then
		for _, missionData in pairs(easyEdit.missions._children) do
			if missionData.BossPawn == pawnType then
				return true
			end
		end
	end

	return false
end

--- Check if pawn is in a category across all enemy lists (for finale).
local function checkAllEnemyLists(baseId, targetCategory)
	for _, enemyList in pairs(easyEdit.enemyList._children) do
		if isInSpawnCategory(enemyList, baseId, targetCategory) then
			return true
		end
	end

	return false
end

--- Check if pawn is in a category for current island's enemy list.
local function checkIslandEnemyList(baseId, targetCategory)
	local islandSlot = easyEdit:getCurrentIslandSlot()
	if islandSlot > 0 then
		if easyEdit.world[islandSlot] then
			local enemyListId = easyEdit.world[islandSlot].enemyList
			local enemyList = easyEdit.enemyList:get(enemyListId)
			if enemyList and isInSpawnCategory(enemyList, baseId, targetCategory) then
				return true
			end
		end
	else
		LOG("Failed to find current island slot")
	end
	return false
end

--- Check if a pawn matches a specific spawn category
function pawnTypeUtils.isSpawnCategory(pawn, spawnCategory)
	if not pawn then
		return false
	end

	-- Convert to id if string is passed
	if type(spawnCategory) == "string" then
		spawnCategory = list_indexof(pawnTypeUtils.SPAWN_CATEGORIES_STRS, spawnCategory)
	end

	-- First check if its a boss since it needs special handling
	if spawnCategory == pawnTypeUtils.SPAWN_CATEGORIES.BOSS then
		return isBoss(pawn)
	end

	-- Get the Easy Edit category name for this spawn category
	local targetCategory = pawnTypeUtils.EASY_EDIT_CATEGORIES[spawnCategory]
	if not targetCategory then
		return false
	end

	-- Otherwise check spawn pool categories
	local pawnType = pawn:GetType()
	local baseId = pawnTypeToBaseId(pawnType)

	-- For finale missions, check all enemy lists
	if isFinaleMission() then
		return checkAllEnemyLists(baseId, targetCategory)
	end

	-- For regular missions, use current island's enemy list
	return checkIslandEnemyList(baseId, targetCategory)
end

return pawnTypeUtils
