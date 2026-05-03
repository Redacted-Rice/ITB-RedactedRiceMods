local mod = mod_loader.mods[modApi.currentMod]
local path = mod.scriptPath

StarWarsAchievements = {
	protonTorpedoActive = false,
	protonTorpedoKills = 0,
	protonTorpedoKillsThreshold = 3,
	protonTordepoName = "StarWars_ProtonTorpedo",
	kesselRunThreshold = 8,
}

local squad = "starwars_rebels"
local achievements = {
	realoriginal = modApi.achievements:add{
		id = "realoriginal",
		name = "Real Original...",
		tooltip = "Use a tow cable on a boss and then kill it",
		image = mod.resourcePath .. "img/achievements/utilitarian.png",
		squad = squad,
	},

	kesselrun = modApi.achievements:add{
		id = "kesselrun",
		name = "Kessel Run",
		tooltip = "Move from one side of the board to the other in a single turn",
		image = mod.resourcePath .. "img/achievements/greatwall.png",
		squad = squad,
	},

	almostmany = modApi.achievements:add{
		id = "almostmany",
		name = "Almost as Impressive",
		tooltip = "Get " .. StarWarsAchievements.protonTorpedoKillsThreshold .. " (enemy) kills from a single proton torpedo",
		image = mod.resourcePath .. "img/achievements/spleef.png",
		squad = squad,
	},
}

local function isGame()
	return Game ~= nil and GAME ~= nil
end

local function isRightSquadInMission()
	return isGame() and GAME.additionalSquadData.squad == squad and not IsTestMechScenario()
end

local function isInMission()
	local mission = GetCurrentMission()
	return isGame() and mission ~= nil and mission ~= Mission_Test
end

local function spacesOffset(mission, pawn)
	if not mission.starwars or not mission.starwars.achiev_kesselRunStartPos then
		return 0
	end
	--GetCurrentMission.starwars.achiev_kesselRunStartPos[2]
	local startPos = mission.starwars.achiev_kesselRunStartPos[pawn:GetId()]
	local endPos = pawn:GetSpace()
	if not startPos or not endPos then
		LOG("NIL arg")
		return 0
	end
	
	LOG("KESSEL CHECK ".. startPos:GetString() .. endPos:GetString())
	return math.max(math.abs(startPos.x - endPos.x), math.abs(startPos.y - endPos.y))
end

local baseTooltip = achievements.almostmany.getTooltip
achievements.almostmany.getTooltip = function(self)
	local result = baseTooltip(self)
	
	if (not achievements.almostmany:isComplete()) and isInMission() and StarWarsAchievements.protonTorpedoActive then
		result = result .. "\n\nProton Torpedo Kills: " .. 
				StarWarsAchievements.protonTorpedoKills .. " / " .. 
				StarWarsAchievements.protonTorpedoKillsThreshold
	end

	return result
end

local baseTooltip = achievements.kesselrun.getTooltip
achievements.kesselrun.getTooltip = function(self)
	local result = baseTooltip(self)
	
	if (not achievements.kesselrun:isComplete()) and isInMission() then
		local mission = GetCurrentMission()
		if mission and mission.starwars and mission.starwars.achiev_kesselRunStartPos then
			local farthest = 0
			for i = 0, 2 do
				if Board:GetPawn(i) then
					farthest = math.max(farthest, spacesOffset(mission, Board:GetPawn(i)))
				end
			end
			result = result .. "\n\nFurthest traveled since last turn: " .. farthest
		end
	end

	return result
end

local baseTooltip = achievements.realoriginal.getTooltip
achievements.realoriginal.getTooltip = function(self)
	local result = baseTooltip(self)
	
	local foundBoss = false
	if (not achievements.realoriginal:isComplete()) and isInMission() then
		if GAME and GAME.starwars and GAME.starwars.tow_cabled then
			for _, pawnId in ipairs(GAME.starwars.tow_cabled) do
				if Board:GetPawn(pawnId) and
						mod_loader.mods.redactedrice_libs.libs.pawnTypeUtils.isBoss(Board:GetPawn(pawnId)) then
					result = result .. "\n\nBoss is grappled"
					foundBoss = true
					break
				end
			end
		end
	end

	if not foundBoss then
		result = result .. "\n\nNo boss or its not grappled"
	end
	return result
end

local function resetKessleRunSaveData(mission)
	if mission.starwars == nil then
		mission.starwars = {}
	end
	
	mission.starwars.achiev_kesselRunStartPos = {}
	for i = 0, 2 do
		if Board:GetPawn(i) then
			mission.starwars.achiev_kesselRunStartPos[i] = Board:GetPawn(i):GetSpace()
		end
	end
end

function StarWarsAchievements.onMissionStartHook(mission)
	if isRightSquadInMission() then
		StarWarsAchievements.protonTorpedoActive = false
		resetKessleRunSaveData(mission)
	end
end

function StarWarsAchievements.onNextTurnHook(mission)
	if isRightSquadInMission() then
		StarWarsAchievements.protonTorpedoActive = false
		resetKessleRunSaveData(mission)
	end
end

function StarWarsAchievements.onSkillStartHook(mission, pawn, weaponId, p1, p2)
	if not isRightSquadInMission() then
		return
	end
	
	if not achievements.almostmany:isComplete() then
		StarWarsAchievements.protonTorpedoActive = 
				string.sub(weaponId, 1, string.len(StarWarsAchievements.protonTordepoName)) == 
				StarWarsAchievements.protonTordepoName
		if StarWarsAchievements.protonTorpedoActive then
			StarWarsAchievements.protonTorpedoKills = 0
		end
	end
end

function StarWarsAchievements.onPawnKilledHook(mission, pawn)
	if not isRightSquadInMission() then
		return
	end
	
	if not achievements.realoriginal:isComplete() then
		if pawn:IsEnemy() and mod_loader.mods.redactedrice_libs.libs.pawnTypeUtils.isBoss(pawn) and
				GAME and GAME.starwars and GAME.starwars.tow_cabled then
			for _, pawnId in ipairs(GAME.starwars.tow_cabled) do
				if pawnId == pawn:GetId() then
					achievements.realoriginal:trigger()
					break
				end
			end
		end
	end
	
	if not achievements.almostmany:isComplete() then
		if pawn:IsEnemy() and StarWarsAchievements.protonTorpedoActive then
			StarWarsAchievements.protonTorpedoKills = StarWarsAchievements.protonTorpedoKills + 1
			if StarWarsAchievements.protonTorpedoKills >= StarWarsAchievements.protonTorpedoKillsThreshold then
				achievements.almostmany:trigger()
			end
		end
	end
end
	
function StarWarsAchievements.onPawnPositionChangedHook(mission, pawn, oldPos)
	if not isRightSquadInMission() then
		return
	end
	
	if not achievements.kesselrun:isComplete() then
		LOG("KESSEL CHECK")
		if spacesOffset(mission, pawn) >= (StarWarsAchievements.kesselRunThreshold - 1) then
			achievements.kesselrun:trigger()
		end
	end
end

function StarWarsAchievements:addHooks()
	modApi.events.onMissionStart:subscribe(self.onMissionStartHook)
	modApi.events.onNextTurn:subscribe(self.onNextTurnHook)
	
	modapiext:addSkillStartHook(self.onSkillStartHook)
	modapiext:addPawnKilledHook(self.onPawnKilledHook)
	modapiext:addPawnPositionChangedHook(self.onPawnPositionChangedHook)
end
