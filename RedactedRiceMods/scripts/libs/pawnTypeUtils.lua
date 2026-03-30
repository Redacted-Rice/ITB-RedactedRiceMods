--[[
PawnTypeUtils - functions to allow determining more detailed pawn types

Author: Das Keifer of Redacted Rice
Version: 1.0.0
Discord Server: https://discord.gg/CNjTVrpN4v

Builds on top of easy edit to allow determining in game what spawn
category a pawn belongs to
]]

local VERSION = "1.0.0"

-- Version check
local isNewestVersion = false
	or PawnTypeUtils == nil
	or modApi:isVersionAbove(VERSION, PawnTypeUtils.version)

if isNewestVersion then
	LOG("PawnTypeUtils: Loading version " .. VERSION .. " (previous: " .. tostring(PawnTypeUtils and PawnTypeUtils.version or "none") .. ")")
	
	-- Initialize global singleton
	PawnTypeUtils = PawnTypeUtils or {}
	PawnTypeUtils.version = VERSION
	
	-- Easy edit defines these locally so we have to redefine
	PawnTypeUtils.EASY_EDIT_CATEGORIES = PawnTypeUtils.EASY_EDIT_CATEGORIES or { "Core", "Leaders", "Unique", "Bots" }
	PawnTypeUtils.SPAWN_CATEGORIES_STRS = PawnTypeUtils.SPAWN_CATEGORIES_STRS or { "Core", "Leader", "Unique", "Bots", "Boss" }
	PawnTypeUtils.SPAWN_CATEGORIES = PawnTypeUtils.SPAWN_CATEGORIES or { CORE = 1, LEADER = 2, UNIQUE = 3, BOTS = 4, BOSS = 5 }

	-- Helper functions (part of the object, version-guarded)
	
	--- Check if the current mission is a finale mission.
	function PawnTypeUtils.isFinaleMission()
		local mission = GetCurrentMission()
		return mission and (mission.ID == "Mission_Final" or mission.ID == "Mission_Final_Cave")
	end

	--- Convert pawn type to base ID for enemy list lookup.
	-- Strips trailing digit: Beetle1 -> Beetle, BeetleBoss -> BeetleBoss
	function PawnTypeUtils.pawnTypeToBaseId(pawnType)
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
	function PawnTypeUtils.isInSpawnCategory(enemyList, baseId, category)
		for _, id in ipairs(enemyList.enemies[category]) do
			if id == baseId then
				return true
			end
		end
		return false
	end

	--- Check if a pawn is the current mission's boss.
	function PawnTypeUtils.isBoss(pawn)
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
	function PawnTypeUtils.checkAllEnemyLists(baseId, targetCategory)
		for _, enemyList in pairs(easyEdit.enemyList._children) do
			if PawnTypeUtils.isInSpawnCategory(enemyList, baseId, targetCategory) then
				return true
			end
		end
		return false
	end

	--- Check if pawn is in a category for current island's enemy list.
	function PawnTypeUtils.checkIslandEnemyList(baseId, targetCategory)
		local islandSlot = easyEdit:getCurrentIslandSlot()
		if islandSlot > 0 then
			if easyEdit.world[islandSlot] then
				local enemyListId = easyEdit.world[islandSlot].enemyList
				local enemyList = easyEdit.enemyList:get(enemyListId)
				if enemyList and PawnTypeUtils.isInSpawnCategory(enemyList, baseId, targetCategory) then
					return true
				end
			end
		else
			LOG("Failed to find current island slot")
		end
		return false
	end

	--- Check if a pawn matches a specific spawn category
	function PawnTypeUtils.isSpawnCategory(pawn, spawnCategory)
		if not pawn then
			return false
		end

		-- Convert to id if string is passed
		if type(spawnCategory) == "string" then
			spawnCategory = list_indexof(PawnTypeUtils.SPAWN_CATEGORIES_STRS, spawnCategory)
		end

		-- First check if its a boss since it needs special handling
		if spawnCategory == PawnTypeUtils.SPAWN_CATEGORIES.BOSS then
			return PawnTypeUtils.isBoss(pawn)
		end

		-- Get the Easy Edit category name for this spawn category
		local targetCategory = PawnTypeUtils.EASY_EDIT_CATEGORIES[spawnCategory]
		if not targetCategory then
			return false
		end

		-- Otherwise check spawn pool categories
		local pawnType = pawn:GetType()
		local baseId = PawnTypeUtils.pawnTypeToBaseId(pawnType)

		-- For finale missions, check all enemy lists
		if PawnTypeUtils.isFinaleMission() then
			return PawnTypeUtils.checkAllEnemyLists(baseId, targetCategory)
		end

		-- For regular missions, use current island's enemy list
		return PawnTypeUtils.checkIslandEnemyList(baseId, targetCategory)
	end
else
	LOG("PawnTypeUtils: Skipping version " .. VERSION .. " (already have " .. PawnTypeUtils.version .. ")")
end

return PawnTypeUtils
