StarWars_EmpireOfTerror = PassiveSkill:new{
	Name = "Empire of Terror",
	Description = "The first 4 grid lost from buildings will be restored. Building populations are halved during player turns.",
	Class = "Science",
	PowerCost = 3,
	Upgrades = 2,
	UpgradeCost = {2, 1},
	MaxGridRestored = 4,
	HalvePopulation = false,
	MitigateVek = false, -- not upgrade changeable ATM
	Icon = "weapons/science_sw_empire_of_terror.png",
	TipImage = {
		CustomPawn = "StarWars_DeathStarMech",
		Unit = Point(2, 2),
		Building = Point(2, 3),
	},
	TraitIcon = "icon_sw_empire_of_terror",
	GridBoostTo = 6,
	GridBoostParticle = "Emitter_Burst_Heal",
	GridBoostColor = GL_Color(0, 255, 0),
	GridReturnParticle = "Emitter_Burst_Heal",
	GridReturnColor = GL_Color(255, 0, 0),
}

local mod = mod_loader.mods[modApi.currentMod]
passiveEffect = mod_loader.mods[modApi.currentMod].libs.passiveEffect
weaponPreview = mod_loader.mods[modApi.currentMod].libs.weaponPreview

-- Initialize GAME save data structure
local function initGameSaveData()
	if GAME == nil then
		GAME = {}
	end
	if GAME.starwars == nil then
		GAME.starwars = {}
	end
	if GAME.starwars.empire_of_terror == nil then
		GAME.starwars.empire_of_terror = {}
	end
	if GAME.starwars.empire_of_terror.uses_remaining == nil then
		GAME.starwars.empire_of_terror.uses_remaining = 0
	end
	if GAME.starwars.empire_of_terror.prev_grid == nil then
		GAME.starwars.empire_of_terror.prev_grid = -1
	end
	if GAME.starwars.empire_of_terror.original_populations == nil then
		GAME.starwars.empire_of_terror.original_populations = {}
	end
	if GAME.starwars.empire_of_terror.player_acting == nil then
		GAME.starwars.empire_of_terror.player_acting = false
	end
end

-- Register Force Focus Icon animation
local function registerTraitIcons()
	ANIMS[StarWars_EmpireOfTerror.TraitIcon] = ANIMS.Animation:new{
		Image = "combat/icons/"..StarWars_EmpireOfTerror.TraitIcon..".png",
		NumFrames = 1,
		Time = 1,
		Loop = true,
		PosX = 4,
		PosY = 8
	}
end

-- Helper function to check if a pawn has Empire of Terror equipped
local function pawnHasEmpireOfTerror(pawn)
	if not pawn or not pawn:IsMech() then return false end
	return mod.libs.passiveEffect:countAnyVersionOfPassiveActive("StarWars_EmpireOfTerror") > 0
end

-- Add stateful trait Icon
mod.libs.traitReplace:addStateful{
	targetTrait = "massive",
	func = function(trait, pawn)
		if not pawnHasEmpireOfTerror(pawn) then
			return 0  -- Don't display
		end
		initGameSaveData()
		if GAME.starwars.empire_of_terror.uses_remaining > 0 then
			return 1  -- Ready
		else
			return 2  -- Exhausted
		end
	end,
	states = {
		{
			icon = "img/combat/icons/"..StarWars_EmpireOfTerror.TraitIcon..".png",
			desc_title = "Empire of Terror",
			desc_text = function(pawn)
				initGameSaveData()
				local gridLeft = GAME.starwars.empire_of_terror.uses_remaining or 0
				return gridLeft .. " uses remaining"
			end,
		},
		{
			icon = "img/combat/icons/"..StarWars_EmpireOfTerror.TraitIcon.."_used.png",
			desc_title = "Empire of Terror (Exhausted)",
			desc_text = "No remaining uses",
		},
	}
}

-- Weapon text definitions
Weapon_Texts.StarWars_EmpireOfTerror_Upgrade1 = "Show of Force"
Weapon_Texts.StarWars_EmpireOfTerror_A_UpgradeDescription = "Up to 6 grid can be restored without loss"
StarWars_EmpireOfTerror_A = StarWars_EmpireOfTerror:new{
	MaxGridRestored = 6,
}

Weapon_Texts.StarWars_EmpireOfTerror_Upgrade2 = "Early Warning"
Weapon_Texts.StarWars_EmpireOfTerror_B_UpgradeDescription = "Buildings destroyed by this squad only lose half their population"
StarWars_EmpireOfTerror_B = StarWars_EmpireOfTerror:new{
	HalvePopulation = true,
}

StarWars_EmpireOfTerror_AB = StarWars_EmpireOfTerror_A:new{
	HalvePopulation = true,
}

-- Function just for showing in the tool tip
function StarWars_EmpireOfTerror:GetSkillEffect(p1, p2)
	local ret = SkillEffect()

	-- Show building taking damage (but not dying)
	local buildingDamage = SpaceDamage(Point(2, 3), 2)
	ret:AddDamage(buildingDamage)

	ret:AddDelay(0.3)

	-- Visual indication of Empire protection - green burst showing grid restoration
	local protectEffect = SpaceDamage(Point(2, 3), 0)
	protectEffect.sScript = [[
		local fx = SkillEffect()
		fx:AddBurst(Point(2, 3), "Emitter_Burst_Heal", DIR_NONE)
		Board:AddEffect(fx)
		Board:Ping(Point(2, 3), GL_Color(0, 255, 0))
	]]
	ret:AddDamage(protectEffect)

	ret:AddDelay(0.2)

	-- Show text alert indicating grid restoration
	local alertEffect = SpaceDamage(Point(2, 2), 0)
	alertEffect.sScript = [[
		Board:AddAlert(Point(2, 3), "GRID SAVED")
	]]
	ret:AddDamage(alertEffect)

	return ret
end

local function getAliveBuildings()
	local points = {}
	for i = 0, 7 do
		for j = 0, 7  do
			local point = Point(i,j)
			if Board:IsBuilding(point) and Board:GetHealth(point) > 0 then
				table.insert(points, point)
			end
		end
	end
	return points
end

local function fxOnAllAliveBuildings(particle, selfColorVarName)
	buildings = getAliveBuildings()
	if #buildings > 0 then
		local script = [[
			local points = {]]
		local fx = SkillEffect()
		for _, building in ipairs(buildings) do
			fx:AddBurst(building, particle, DIR_NONE)
			script = script..building:GetString()..","
		end
		script = script..[[}
			for _, point in ipairs(points) do
				Board:Ping(point, StarWars_EmpireOfTerror.]] .. selfColorVarName .. [[)
			end
		]]
		fx:AddScript(script)
		Board:AddEffect(fx)
	end
end

-- Mission start hook - Initialize mission data
function StarWars_EmpireOfTerror:GetPassiveSkillEffect_MissionStartHook(mission)
	if not Board then
		return
	end

	LOG("=== MISSION START ===")
	initGameSaveData()
	GAME.starwars.empire_of_terror.prev_grid = -1
	GAME.starwars.empire_of_terror.uses_remaining = self.MaxGridRestored
	GAME.starwars.empire_of_terror.player_acting = true

	if not self.HalvePopulation then
		return
	end
	GAME.starwars.empire_of_terror.original_populations = {}

	-- Store original populations for all buildings
	local boardSize = Board:GetSize()
	for x = 0, boardSize.x - 1 do
		for y = 0, boardSize.y - 1 do
			local point = Point(x, y)
			if Board:IsBuilding(point) then
				local key = point:GetString()
				GAME.starwars.empire_of_terror.original_populations[key] = Board:GetPeoplePopulated(point)
				LOG(string.format("Stored original population for %s: %d", key, GAME.starwars.empire_of_terror.original_populations[key]))
			end
		end
	end
end

function StarWars_EmpireOfTerror:skillStartBoostGrid(weaponId, self)
	if weaponId == "Move" then return end

	initGameSaveData()

	-- Check if we should apply the effect based on turn phase and MitigateVek flag
	if not (GAME.starwars.empire_of_terror.player_acting or
			(self.MitigateVek and Game:GetTeamTurn() == TEAM_PLAYER))
		return
	end

	if GAME.starwars.empire_of_terror.uses_remaining > 0 and
			GAME.starwars.empire_of_terror.prev_grid <= 0 then
		local currPower = Game:GetPower():GetValue()
		local diff = StarWars_EmpireOfTerror.GridBoostTo - currPower
		GAME.starwars.empire_of_terror.prev_grid = currPower
		LOG("Skill start boosting grid from " .. currPower .. " to " .. StarWars_EmpireOfTerror.GridBoostTo)
		-- Increment one by one to ensure it works as expected for unfair difficulty
		while diff > 0 do
			diff = diff - 1
			Game:ModifyPowerGrid(SERIOUSLY_JUST_ONE)
		end

		fxOnAllAliveBuildings(StarWars_EmpireOfTerror.GridBoostParticle, "GridBoostColor")
	else
		LOG("Skipping start hook (remaining: ".. GAME.starwars.empire_of_terror.uses_remaining ..
				", prevGrid: "..GAME.starwars.empire_of_terror.prev_grid .. ")")
	end
end

function StarWars_EmpireOfTerror:skillEndRevertGrid(weaponId, self)
	if weaponId == "Move" then return end

	initGameSaveData()

	-- Check if we should apply the effect based on MitigateVek flag
	if not (GAME.starwars.empire_of_terror.player_acting or
			(self.MitigateVek and Game:GetTeamTurn() == TEAM_PLAYER))
		return
	end

	if GAME.starwars.empire_of_terror.uses_remaining > 0 and
			GAME.starwars.empire_of_terror.prev_grid > 0 then
		local currPower = Game:GetPower():GetValue()
		local prevPower = GAME.starwars.empire_of_terror.prev_grid
		GAME.starwars.empire_of_terror.prev_grid = -1
		local gridLost = StarWars_EmpireOfTerror.GridBoostTo - currPower
		if gridLost < 0 then
			-- we restored grid via a weapon without damaging grid
			-- An edge case but at least somewhat handle it since vanilla
			-- gain grid on kill is a thing. This won't handle if grid is
			-- destroyed AND gained as expected though but I think its
			-- okay as that is not possible in vanilla and would be quite niche
			LOG("Grid was restored during attack! Doing nothing")
			return
		end

		local gridLostAdj = 0
		if gridLost >= GAME.starwars.empire_of_terror.uses_remaining then
			gridLostAdj = gridLost - GAME.starwars.empire_of_terror.uses_remaining
			LOG("Grid lost(".. gridLost ..") is >= uses remaining ("..
					GAME.starwars.empire_of_terror.uses_remaining.."), adjusting grid lost to " .. gridLostAdj)
			GAME.starwars.empire_of_terror.uses_remaining = 0
		else
			LOG("Grid lost(".. gridLost ..") is < uses remaining ("..
					GAME.starwars.empire_of_terror.uses_remaining.."). Reducing gridlost to " .. gridLostAdj)
			GAME.starwars.empire_of_terror.uses_remaining = GAME.starwars.empire_of_terror.uses_remaining - gridLost
		end

		local targetGrid = prevPower - gridLostAdj
		local diff = targetGrid - currPower
		LOG("current grid is " .. currPower .. ", original grid was " .. prevPower .. ", adjusted lost grid is " ..
				gridLostAdj .. ", target grid is " .. targetGrid .. ", diff is " .. diff)
		Game:ModifyPowerGrid(diff)

		fxOnAllAliveBuildings(StarWars_EmpireOfTerror.GridReturnParticle, "GridReturnColor")
	else
		LOG("Skipping end hook (remaining: ".. GAME.starwars.empire_of_terror.uses_remaining ..
				", prevGrid: "..GAME.starwars.empire_of_terror.prev_grid .. ")")
	end
end

-- Regular skill hooks
function StarWars_EmpireOfTerror:GetPassiveSkillEffect_SkillStartHook(mission, pawn, weaponId)
	self:skillStartBoostGrid(weaponId)
end

function StarWars_EmpireOfTerror:GetPassiveSkillEffect_FinalEffectStartHook(mission, pawn, weaponId)
	self:skillStartBoostGrid(weaponId)
end

function StarWars_EmpireOfTerror:GetPassiveSkillEffect_SkillEndHook(mission, pawn, weaponId)
	self:skillEndRevertGrid(weaponId)
end

function StarWars_EmpireOfTerror:GetPassiveSkillEffect_FinalEffectEndHook(mission, pawn, weaponId)
	self:skillEndRevertGrid(weaponId)
end

-- Queued skill hooks
function StarWars_EmpireOfTerror:GetPassiveSkillEffect_QueuedSkillStartHook(mission, pawn, weaponId)
	self:skillStartBoostGrid(weaponId)
end

function StarWars_EmpireOfTerror:GetPassiveSkillEffect_QueuedFinalEffectStartHook(mission, pawn, weaponId)
	self:skillStartBoostGrid(weaponId)
end

function StarWars_EmpireOfTerror:GetPassiveSkillEffect_QueuedSkillEndHook(mission, pawn, weaponId)
	self:skillEndRevertGrid(weaponId)
end

function StarWars_EmpireOfTerror:GetPassiveSkillEffect_QueuedFinalEffectEndHook(mission, pawn, weaponId)
	self:skillEndRevertGrid(weaponId)
end

-- Use to detect start of players turn
function StarWars_EmpireOfTerror:GetPassiveSkillEffect_NextTurnHook()
	if not Board or not Game then
		return
	end

	if Game:GetTeamTurn() == TEAM_PLAYER then
		GAME.starwars.empire_of_terror.player_acting = true

		if not self.HalvePopulation then
			return
		end

		-- Player turn: Halve populations
		LOG("Player turn START - Halving populations")
		local boardSize = Board:GetSize()
		local totalRemoved = 0

		for x = 0, boardSize.x - 1 do
			for y = 0, boardSize.y - 1 do
				local point = Point(x, y)
				if Board:IsBuilding(point) then
					local key = point:GetString()
					local currentPop = Board:GetPeoplePopulated(point)
					local newPop = math.floor(currentPop / 2)
					local removed = currentPop - newPop

					Board:SetPeoplePopulated(point, newPop)
					totalRemoved = totalRemoved + removed

					LOG(string.format("  %s: %d -> %d (-%d)", key, currentPop, newPop, removed))
				end
			end
		end
	end
end

-- This will signify the transition to enemy attacks
function StarWars_EmpireOfTerror:GetPassiveSkillEffect_PreEnvironmentHook()
	if not Board or not Game then
		return
	end

	GAME.starwars.empire_of_terror.player_acting = false

	if not self.HalvePopulation then
		return
	end

	-- Vek turn: Restore populations
	LOG("Vek attacks START - Restoring populations")
	local boardSize = Board:GetSize()

	for x = 0, boardSize.x - 1 do
		for y = 0, boardSize.y - 1 do
			local point = Point(x, y)
			if Board:IsBuilding(point) then
				local key = point:GetString()
				local originalPop = GAME.starwars.empire_of_terror.original_populations[key] or 0
				Board:SetPeoplePopulated(point, originalPop)

				LOG(string.format("  %s: restored to %d", key, originalPop))
			end
		end
	end
	LOG("Populations restored")
end


-- Register the passive effect
local passiveEffects = 	{
	"missionStartHook",
	-- Next turn hook doesn't really behave as expected... Vek attacking is part of the player turn
	"nextTurnHook", "preEnvironmentHook",
	"skillStartHook", "skillEndHook", "finalEffectStartHook", "finalEffectEndHook",
}
if StarWars_EmpireOfTerror.MitigateVek then
	table.insert(passiveEffects, "queuedSkillStartHook")
	table.insert(passiveEffects, "queuedSkillEndHook")
	table.insert(passiveEffects, "queuedFinalEffectStartHook")
	table.insert(passiveEffects, "queuedFinalEffectEndHook")
end

passiveEffect:addPassiveEffect("StarWars_EmpireOfTerror", passiveEffects)
