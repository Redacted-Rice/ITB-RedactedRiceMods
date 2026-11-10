local mod = mod_loader.mods[modApi.currentMod]
local path = mod.scriptPath
local pawnTypeUtils = mod_loader.mods.redactedrice_libs.libs.pawnTypeUtils

StarWarsAchievements = {
	rebelSquad = "starwars_rebels",
	empireSquad = "starwars_empire",
	protonTorpedoActive = false,
	protonTorpedoKills = 0,
	protonTorpedoKillsThreshold = 3,
	protonTordepoName = "StarWars_ProtonTorpedo",
	kesselRunThreshold = 8,

	dualCannonsWeaponPrefix = "StarWars_DualCannons",
	primingLaserWeaponPrefix = "StarWars_DeathStar_Repair",
	primingLaserActive = false,
	dualCannonsWillHit = false,
}

local achievements = {
	realoriginal = modApi.achievements:add{
		id = "realoriginal",
		name = "Real Original...",
		tooltip = "Use a tow cable on a boss and then kill it",
		image = mod.resourcePath .. "img/achievements/realoriginal.png",
		squad = StarWarsAchievements.rebelSquad,
	},

	kesselrun = modApi.achievements:add{
		id = "kesselrun",
		name = "Kessel Run",
		tooltip = "Move from one side of the board to the other in a single turn",
		image = mod.resourcePath .. "img/achievements/kesselrun.png",
		squad = StarWarsAchievements.rebelSquad,
	},

	almostmany = modApi.achievements:add{
		id = "almostmany",
		name = "Almost as Impressive",
		tooltip = "Get " .. StarWarsAchievements.protonTorpedoKillsThreshold .. " (enemy) kills from a single proton torpedo",
		image = mod.resourcePath .. "img/achievements/almostasmany.png",
		squad = StarWarsAchievements.rebelSquad,
	},

	nosurvivors = modApi.achievements:add{
		id = "nosurvivors",
		name = "No Survivors",
		tooltip = "Destroy all buildings in a mission",
		image = mod.resourcePath .. "img/achievements/nosurvivors.png",
		squad = StarWarsAchievements.empireSquad,
	},

	pathetic = modApi.achievements:add{
		id = "pathetic",
		name = "Pathetic",
		tooltip = "Kill a boss with the Death Star's Priming Laser",
		image = mod.resourcePath .. "img/achievements/pathetic.png",
		squad = StarWarsAchievements.empireSquad,
	},

	justlikemovies = modApi.achievements:add{
		id = "justlikemovies",
		name = "Just like the Movies",
		tooltip = "Fire the TIE Fighter's Dual Cannons without dealing any damage",
		image = mod.resourcePath .. "img/achievements/justlikemovies.png",
		squad = StarWarsAchievements.empireSquad,
	},
}

local function isGame()
	return Game ~= nil and GAME ~= nil
end

local function isRightRebelSquadInMission()
	return isGame() and GAME.additionalSquadData.squad == StarWarsAchievements.rebelSquad and not IsTestMechScenario()
end

local function isRightEmpireSquadInMission()
	return isGame() and GAME.additionalSquadData.squad == StarWarsAchievements.empireSquad and not IsTestMechScenario()
end

local function resetWeaponActiveFlags()
	StarWarsAchievements.protonTorpedoActive = false
	StarWarsAchievements.primingLaserActive = false
	StarWarsAchievements.dualCannonsWillHit = false
end

local function weaponIdStartsWith(weaponId, prefix)
	if type(weaponId) == "table" then
		weaponId = weaponId.__Id
	end
	return weaponId ~= nil and string.sub(weaponId, 1, string.len(prefix)) == prefix
end

local function patheticSkillIsPrimingLaser(weaponId, pawn)
	if not weaponIdStartsWith(weaponId, "Skill_Repair") then
		return false
	end

	local repairSkill = ReplaceRepair:getCurrentSkill()
	if repairSkill then
		weaponId = repairSkill.weapon or repairSkill.Weapon
	end
	LOG("patheticSkillIsPrimingLaser:  resolved " .. tostring(weaponId))
	return weaponIdStartsWith(weaponId, StarWarsAchievements.primingLaserWeaponPrefix)
end

local function isInMission()
	local mission = GetCurrentMission()
	return isGame() and mission ~= nil and mission ~= Mission_Test
end

local function tileHasPawnOrTerrainHealth(loc)
	if not Board or not Board:IsValid(loc) then
		return false
	end
	local targetPawn = Board:GetPawn(loc)
	if targetPawn and not targetPawn:IsDead() then
		return true
	end
	local terrain = Board:GetTerrain(loc)
	return terrain == TERRAIN_BUILDING or terrain == TERRAIN_MOUNTAIN or terrain == TERRAIN_ICE 
			or terrain == TERRAIN_FOREST or terrain == TERRAIN_SAND
end

local function getBuildingHealthRemaining()
	if not Board then
		return 0
	end
	local total = 0
	local size = Board:GetSize()
	for x = 0, size.x - 1 do
		for y = 0, size.y - 1 do
			local point = Point(x, y)
			if Board:IsBuilding(point) then
				local health = Board:GetHealth(point)
				if health > 0 then
					total = total + health
				end
			end
		end
	end
	return total
end

local function spacesOffset(mission, pawn)
	if not mission.starwars or not mission.starwars.achiev_kesselRunStartPos then
		return 0
	end
	--GetCurrentMission.starwars.achiev_kesselRunStartPos[2]
	local startPos = mission.starwars.achiev_kesselRunStartPos[pawn:GetId()]
	local endPos = pawn:GetSpace()
	if not startPos or not endPos then
		return 0
	end

	if not Board:IsValid(startPos) then
		return 0
	end

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

	local bossTangled = false
	if (not achievements.realoriginal:isComplete()) and isInMission() then
		if GAME and GAME.starwars and GAME.starwars.tow_cabled then
			for _, pawnId in ipairs(GAME.starwars.tow_cabled) do
				if Board:GetPawn(pawnId) and Board:GetPawn(pawnId):IsEnemy() and
						pawnTypeUtils.isBoss(Board:GetPawn(pawnId)) then
					return result .. "\n\nBoss is tangled up in a tow cable - kill it before the mission ends!"
				end
			end
		end

		for _, pawnId in ipairs(extract_table(Board:GetPawns(TEAM_ANY))) do
			if Board:GetPawn(pawnId) and Board:GetPawn(pawnId):IsEnemy() and
					pawnTypeUtils.isBoss(Board:GetPawn(pawnId)) then
				return result .. "\n\nBoss is not tangled by a tow cable yet"
			end
		end

		return result .. "\n\nNo boss in this mission"
	end

	return result
end

local baseTooltip = achievements.nosurvivors.getTooltip
achievements.nosurvivors.getTooltip = function(self)
	local result = baseTooltip(self)

	if (not achievements.nosurvivors:isComplete()) and isInMission() and isRightEmpireSquadInMission() then
		result = result .. "\n\nBuilding health remaining: " .. getBuildingHealthRemaining()
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
	resetWeaponActiveFlags()

	if isRightRebelSquadInMission() then
		resetKessleRunSaveData(mission)
	end
end

-- Just to be sure it doesn't carry over
function StarWarsAchievements.onMissionEndHook(mission)
	resetWeaponActiveFlags()

	if isRightRebelSquadInMission() then
		resetKessleRunSaveData(mission)
	end

	-- Check for no survivors
	if isRightEmpireSquadInMission() and not achievements.nosurvivors:isComplete() then
		if getBuildingHealthRemaining() == 0 then
			achievements.nosurvivors:trigger()
		end
	end
end

function StarWarsAchievements.onNextTurnHook(mission)
	resetWeaponActiveFlags()

	if isRightRebelSquadInMission() then
		resetKessleRunSaveData(mission)
	end
end

function StarWarsAchievements.onSkillStartHook(mission, pawn, weaponId, p1, p2)
	resetWeaponActiveFlags()
	LOG("onSkillStartHook: " .. tostring(weaponId))

	if isRightEmpireSquadInMission() and not achievements.pathetic:isComplete() then
		if patheticSkillIsPrimingLaser(weaponId, pawn) then
			LOG("onSkillStartHook: primingLaserWeaponPrefix set active")
			StarWarsAchievements.primingLaserActive = true
		end
	end

	if isRightRebelSquadInMission() and not achievements.almostmany:isComplete() then
		StarWarsAchievements.protonTorpedoActive =
				weaponIdStartsWith(weaponId, StarWarsAchievements.protonTordepoName)
		if StarWarsAchievements.protonTorpedoActive then
			StarWarsAchievements.protonTorpedoKills = 0
		end
	end
end

function StarWarsAchievements.onSkillEndHook(mission, pawn, weaponId, p1, p2)
	resetWeaponActiveFlags()
end

function StarWarsAchievements.onFinalEffectBuildHook(mission, pawn, weaponId, p1, p2, p3, skillEffect)
	StarWarsAchievements.dualCannonsWillHit = false
	if isRightEmpireSquadInMission() and not achievements.justlikemovies:isComplete() then
		if not weaponIdStartsWith(weaponId, StarWarsAchievements.dualCannonsWeaponPrefix) then
			return
		end

		for _, damage in pairs(extract_table(skillEffect.effect)) do
			if damage.iDamage and damage.iDamage > 0 and damage.loc and tileHasPawnOrTerrainHealth(damage.loc) then
				StarWarsAchievements.dualCannonsWillHit = true
				break
			end
		end
	end
end

function StarWarsAchievements.onFinalEffectEndHook(mission, pawn, weaponId, p1, p2, p3)
	if isRightEmpireSquadInMission() and not achievements.justlikemovies:isComplete() then
		if not weaponIdStartsWith(weaponId, StarWarsAchievements.dualCannonsWeaponPrefix) then
			return
		end
		if not StarWarsAchievements.dualCannonsWillHit then
			achievements.justlikemovies:trigger()
		end
	end
end

function StarWarsAchievements.onPawnKilledHook(mission, pawn)
	if isRightEmpireSquadInMission() and not achievements.pathetic:isComplete() then
		LOG("onPawnKilledHook: " .. tostring(StarWarsAchievements.primingLaserActive) .. " " .. tostring(pawn:IsEnemy()) .. " " .. tostring(pawnTypeUtils.isBoss(pawn)))
		if StarWarsAchievements.primingLaserActive and pawn:IsEnemy() and pawnTypeUtils.isBoss(pawn) then
			LOG("pathetic:trigger")
			achievements.pathetic:trigger()
		end
	end

	if not isRightRebelSquadInMission() then
		return
	end

	if not achievements.realoriginal:isComplete() then
		if pawn:IsEnemy() and mod_loader.mods.redactedrice_libs.libs.pawnTypeUtils.isBoss(pawn) and
				StarWars_TowCable:isTowCabled(pawn:GetId()) then
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
	if isRightRebelSquadInMission() then
		if not achievements.kesselrun:isComplete() then
			if spacesOffset(mission, pawn) >= (StarWarsAchievements.kesselRunThreshold - 1) then
				achievements.kesselrun:trigger()
			end
		end
	end
end

function StarWarsAchievements:addHooks()
	modApi.events.onMissionStart:subscribe(self.onMissionStartHook)
	modApi.events.onMissionEnd:subscribe(self.onMissionEndHook)
	modApi.events.onNextTurn:subscribe(self.onNextTurnHook)

	modapiext:addSkillStartHook(self.onSkillStartHook)
	modapiext:addSkillEndHook(self.onSkillEndHook)
	modapiext:addFinalEffectBuildHook(self.onFinalEffectBuildHook)
	modapiext:addFinalEffectEndHook(self.onFinalEffectEndHook)
	modapiext:addPawnKilledHook(self.onPawnKilledHook)
	modapiext:addPawnPositionChangedHook(self.onPawnPositionChangedHook)
end
