local mod = mod_loader.mods[modApi.currentMod]
local path = mod.scriptPath

MoonStridersAchievements = {
	drops = 0,
	lastAttacked = nil,
}

local squad = "moonstriders"
local achievements = {
	grave = modApi.achievements:add{
		id = "hallow_grave",
		name = "Hallow Grave",
		tooltip = "Drop 3 enemies in holes in a single battle",
		image = mod.resourcePath .. "img/achievements/grave.png",
		squad = squad,
	},

	swing = modApi.achievements:add{
		id = "far_swing",
		name = "Far Swing",
		tooltip = "Kill an enemy 5 or more tiles away with Lasso Hook",
		image = mod.resourcePath .. "img/achievements/swing.png",
		squad = squad,
	},

	secure = modApi.achievements:add{
		id = "islands_secure",
		name = "Islands Secure",
		tooltip = "Complete all four islands",
		image = mod.resourcePath .. "img/achievements/secure.png",
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

local baseTooltip = achievements.secure.getTooltip
achievements.secure.getTooltip = function(self)
	local result = baseTooltip(self)
	if (not achievements.secure:isComplete()) and isGame() then
		local islandsSecured = 0
		for i = 0, 3 do
			if RegionData and RegionData["island"..i] and RegionData["island"..i].secured then
				islandsSecured = islandsSecured + 1
			end
		end
		result = result .. "\n\nCurrent Islands Secured: " .. tostring(islandsSecured) .. " / 4"
	end
	return result
end

achievements.grave.getTooltip = function(self)
	local result = baseTooltip(self)
	if (not achievements.grave:isComplete()) and isInMission() then
		result = result .. "\n\nCurrent Veks dropped: " .. tostring(MoonStridersAchievements.drops) .. " / 3"
	end
	return result
end

function MoonStridersAchievements.checkIslandsSecured()
	if isRightSquad() and not achievements.secure:isComplete()then
		local islandsSecured = 0
		for i = 0, 3 do
			if RegionData["island"..i].secured then
				islandsSecured = islandsSecured + 1
			end
		end
		if islandsSecured >= 4 then
			achievements.secure:trigger()
		end
	end
end

-- Drops
function MoonStridersAchievements.onMissionStartHook(mission)
	if isRightSquad() and not achievements.grave:isComplete() then
		MoonStridersAchievements.drops = 0
	end
	
	-- It doesn't seem to fire at least most times on fourth island for whatever reason
	-- so call it here and it will trigger on starting the volcano
	MoonStridersAchievements.checkIslandsSecured()
end

-- Swing
function MoonStridersAchievements.onSkillStartHook(mission, pawn, weaponId, p1, p2)
	if isRightSquad() and not achievements.swing:isComplete()then
		MoonStridersAchievements.lastAttacked = nil
		
		-- make sure we have the actual weaponid
		if type(weaponId) == 'table' then
			weaponId = weaponId.__Id
		end 

		if string.sub(weaponId, 1 , string.len("MoonStriders_ColossusHook")) == "MoonStriders_ColossusHook" and
				p1:Manhattan(p2) >= 5 then
			MoonStridersAchievements.lastAttacked = Board:GetPawn(p2)
		end
	end
end

-- Swing and drops
function MoonStridersAchievements.onPawnKilledHook(mission, pawn)
	if isRightSquad() then
		if not achievements.swing:isComplete()then
			if MoonStridersAchievements.lastAttacked then
				achievements.swing:trigger()
			end
		end
		if not achievements.grave:isComplete()then
			if Board:GetTerrain(pawn:GetSpace()) == TERRAIN_HOLE then
				MoonStridersAchievements.drops = MoonStridersAchievements.drops + 1
				if MoonStridersAchievements.drops >= 3 then
					achievements.grave:trigger()
				end
			end
		end
	end
end

-- secure
-- Doesn't fire reliably
--[[function MoonStridersAchievements.onIslandLeftHook()
	MoonStridersAchievements.checkIslandsSecured()
end]]

function MoonStridersAchievements:subscribe()
	modApi.events.onIslandLeft:subscribe(self.onIslandLeftHook)
end

function MoonStridersAchievements:addHooks()
	modApi:addMissionStartHook(self.onMissionStartHook)
	modapiext:addSkillStartHook(self.onSkillStartHook)
	modapiext:addPawnKilledHook(self.onPawnKilledHook)
end