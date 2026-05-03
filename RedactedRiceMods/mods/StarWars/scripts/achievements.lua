local mod = mod_loader.mods[modApi.currentMod]
local path = mod.scriptPath

StarWarsAchievements = {
	kesselRunStartPos = nil,
	protonTorpedoActive = false,
	protonTorpedoKills = 0,
	protonTorpedoKillsThreshold = 3,
	protonTordepoName = "StarWars_ProtonTorpedo",
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
		name = "Almost as many",
		tooltip = "Get " .. StarWarsAchievements.protonTorpedoKillsThreshold .. " kills from a single proton torpedo",
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

local function resetKessleRunSaveData(mission)
	if mission.starwars == nil then
		mission.starwars = {}
	end
	
	mission.starwars.achiev_kesselRunStartPos = {}
	for i = 0, 2 do
		if Board:GetPawn(i) then
			table.insert(mission.starwars.achiev_kesselRunStartPos, Board:GetPawn(i):GetSpace())
		end
	end
end

local function crossedBoard(mission, pawn)
	if not mission.starwars or not mission.starwars.achiev_kesselRunStartPos then
		return false
	end
	
	local startPos = mission.starwars.achiev_kesselRunStartPos[pawn:GetId()]
	local endPos = pawn:GetSpace()
	local size = Board:GetSize()
	if not startPos or not endPos or not size then
		LOG("NIL arg")
		return false
	end
	
	local crossedHorizontal = (startPos.x == 0 and endPos.x == size.x - 1) or (startPos.x == size.x - 1 and endPos.x == 0)
	local crossedVertical = (startPos.y == 0 and endPos.y == size.y - 1) or (startPos.y == size.y - 1 and endPos.y == 0)
	
	return crossedHorizontal or crossedVertical
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
				GAME and GAME.starwars and GAME.starwars.tow_cabled and
				GAME.starwars.tow_cabled[pawn:GetId()] then
			achievements.realoriginal:trigger()
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
		if crossedBoard(mission, pawn) then
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
