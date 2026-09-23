local mod = mod_loader.mods[modApi.currentMod]
local path = mod.scriptPath

TreeherdersAchievements = {
	myfriendsSkillBuilt = false,
	treehuggerMinTrees = 15,
}

local squad = "treeherders"
local achievements = {
	myfriends = modApi.achievements:add{
		id = "myfriends",
		name = "These Trees where my Friends",
		tooltip = "Tree-venge smash a vek for max damage",
		image = mod.resourcePath .. "img/achievements/myfriends.png",
		squad = squad,
	},

	treehugger = modApi.achievements:add{
		id = "treehugger",
		name = "Tree Hugger",
		tooltip = "Complete a mission where there are at least " .. tostring(TreeherdersAchievements.treehuggerMinTrees) .. " forest and none are on fire",
		image = mod.resourcePath .. "img/achievements/treehugger.png",
		squad = squad,
	},

	naturalist = modApi.achievements:add{
		id = "naturalist",
		name = "True Naturalist",
		tooltip = "Complete a mission without a vek dying",
		image = mod.resourcePath .. "img/achievements/naturalist.png",
		squad = squad,
	},
}

local function isGame()
	return Game ~= nil and GAME ~= nil
end

local function isRightSquad()
	return isGame() and GAME.additionalSquadData.squad == squad
end

local function isInMission()
	local mission = GetCurrentMission()
	return isGame() and mission ~= nil and mission ~= Mission_Test
end

local function getAchievementSaveData()
	local mission = GetCurrentMission()
	
	if mission.treeherders == nil then
		mission.treeherders = {}
		mission.treeherders.achiev_naturalistTurnKills = 0
		mission.treeherders.achiev_naturalistMissionKills = 0
	end
	
	return mission.treeherders
end

-- Naturalist
local function totalNaturalistKills(saveData)
	return saveData.achiev_naturalistMissionKills + saveData.achiev_naturalistTurnKills
end

-- Treehuggers
local function countForestsAndForestFires()
	local forestCount = 0
	local forestFireCount = 0
	if Board then
		local size = Board:GetSize()
		for y = 0, size.y - 1 do
			for x = 0, size.x - 1 do
				local p = Point(x, y)
				if forestUtils.isAForest(p) then
					forestCount = forestCount + 1
				end
				
				if forestUtils.isAForestFire(p) then
					forestFireCount = forestFireCount + 1
				end
			end
		end
	end
	return forestCount, forestFireCount
end


local baseTooltip = achievements.naturalist.getTooltip
achievements.naturalist.getTooltip = function(self)
	local result = baseTooltip(self)
	
	if (not achievements.naturalist:isComplete()) and isInMission() then
		result = result .. "\n\nVek Killed: " .. tostring(totalNaturalistKills(getAchievementSaveData()))
	end

	return result
end

local baseTooltip = achievements.treehugger.getTooltip
achievements.treehugger.getTooltip = function(self)
	local result = baseTooltip(self)
	if (not achievements.treehugger:isComplete()) and isInMission() then
		forestCount, forestFireCount = countForestsAndForestFires()
		result = result .. "\n\nForests: " .. tostring(forestCount) .. " / " .. tostring(TreeherdersAchievements.treehuggerMinTrees) .. "\nForest Fires: " .. tostring(forestFireCount) .. "\n\nHint: Repairing on a forest fire tile will turn it into a ground tile"
	end
	return result
end

-- Treehuggers & naturalist
function TreeherdersAchievements.onMissionEndHook(mission)
	if isRightSquad() then
		if not achievements.treehugger:isComplete() then
			forestCount, forestFireCount = countForestsAndForestFires()
			if forestCount >= TreeherdersAchievements.treehuggerMinTrees and forestFireCount == 0 then
				achievements.treehugger:trigger()
			end
		end
		
		if not achievements.naturalist:isComplete() then
			if totalNaturalistKills(getAchievementSaveData()) == 0 then
				achievements.naturalist:trigger()
			end
		end
	end
end

-- Naturalist
function TreeherdersAchievements.onMissionStartHook(mission)
	if not achievements.naturalist:isComplete() and isRightSquad() then
		getAchievementSaveData().achiev_naturalistMissionKills = 0
	end
end

-- Naturalist
function TreeherdersAchievements.onNextTurnHook(mission)
	if not achievements.naturalist:isComplete() and isRightSquad() then
		saveData = getAchievementSaveData()
		-- Add the turn kills then clear the turn kills
		saveData.achiev_naturalistMissionKills = totalNaturalistKills(saveData)
		saveData.achiev_naturalistTurnKills = 0
	end
end

-- Treehuggers
function TreeherdersAchievements.onSkillBuildHook(mission, pawn, weaponId, p1, p2, skillEffect)
	if not achievements.myfriends:isComplete() and isRightSquad() then				
		-- make sure we have the actual weaponid
		if type(weaponId) == 'table' then
			weaponId = weaponId.__Id
		end 
		
		-- check the conditions to see if this built skill satisfies the requirement

		if string.sub(weaponId, 1 , string.len("Treeherders_Treevenge")) == "Treeherders_Treevenge" then
			-- reset the flag. We do this inside the check because other
			-- weapons can be called between the final skill build hook and the
			-- skill end hook
			TreeherdersAchievements.myfriendsSkillBuilt = false
		
			if Board:GetPawn(p2) ~= nil and Board:GetPawn(p2):IsEnemy() then
				for _, damage in pairs(extract_table(skillEffect.effect)) do	
					if damage.loc == p2 then
						if damage.iDamage == Treeherders_Treevenge.DamageCap then
							TreeherdersAchievements.myfriendsSkillBuilt = true
						end
						break
					end
				end
			end
		end
	end
end

-- Treehuggers
function TreeherdersAchievements.onSkillEndHook(mission, pawn, weaponId, p1, p2)
	if not achievements.myfriends:isComplete() and isRightSquad() then
		-- make sure we have the actual weaponid
		if type(weaponId) == 'table' then
			weaponId = weaponId.__Id
		end 
		
		if string.sub(weaponId, 1 , string.len("Treeherders_Treevenge")) == "Treeherders_Treevenge" and TreeherdersAchievements.myfriendsSkillBuilt then
			achievements.myfriends:trigger()
		end
	end
end

-- Naturalist
function TreeherdersAchievements.onPawnKilledHook(mission, pawn)
	if not achievements.naturalist:isComplete() and isRightSquad() then
		if forestUtils.isAVek(pawn) then
			getAchievementSaveData().achiev_naturalistTurnKills = getAchievementSaveData().achiev_naturalistTurnKills + 1
		end
	end
end


function TreeherdersAchievements:addHooks()
	modApi.events.onMissionStart:subscribe(self.onMissionStartHook)
	modApi.events.onNextTurn:subscribe(self.onNextTurnHook)
	modApi.events.onMissionEnd:subscribe(self.onMissionEndHook)
	
	modapiext:addSkillBuildHook(self.onSkillBuildHook)
	modapiext:addSkillEndHook(self.onSkillEndHook)
	modapiext:addPawnKilledHook(self.onPawnKilledHook)
end