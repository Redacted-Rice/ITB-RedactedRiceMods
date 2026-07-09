StarWars_TowCable = TankDefault:new{
	Name = "Tow Cable",
	Description = "Fire a tow cable up to 2 spaces in a line, wrapping around an enemy to prevent them from moving.",
	Class = "Brute",
	Damage = 0,
	PowerCost = 0,
	Upgrades = 2,
	UpgradeCost = {2, 1},
	Icon = "weapons/brute_sw_tow_cable.png",
	PathSize = 2,
	SetFire = false,
	CancelAttack = false,
	Limited = 2,
	LaunchSound = "/weapons/grapple",
	ImpactSound = "/impact/generic/grapple",
	ProjectileArt = "effects/shot_tow_cable",
	TipImage = {
		CustomPawn = "StarWars_SnowSpeederMech",
		Unit = Point(2,3),
		Enemy = Point(2,1),
		Target = Point(2,1),
	},
	Debug = false,
}

-- Weapon text definitions
Weapon_Texts.StarWars_TowCable_Upgrade1 = "+ Fire"
Weapon_Texts.StarWars_TowCable_A_UpgradeDescription = "Sets the target space on fire."
StarWars_TowCable_A = StarWars_TowCable:new{
	SetFire = true,
}

Weapon_Texts.StarWars_TowCable_Upgrade2 = "Cancel Attack"
Weapon_Texts.StarWars_TowCable_B_UpgradeDescription = "Cancels target's attack"
StarWars_TowCable_B = StarWars_TowCable:new{
	CancelAttack = true,
}

StarWars_TowCable_AB = StarWars_TowCable_A:new{
	CancelAttack = true,
}

-- Uses base TankDefault targetting

-- Initialize GAME save data structure
function StarWars_TowCable:initGameSaveData()
	if GAME == nil then
		GAME = {}
	end

	if GAME.starwars == nil then
		GAME.starwars = {}
	end

	if GAME.starwars.tow_cabled == nil then
		GAME.starwars.tow_cabled = {}
	end
end

function StarWars_TowCable:isTowCabled(pawnId)
	self:initGameSaveData()
	return GAME.starwars.tow_cabled[pawnId] ~= nil
end

function StarWars_TowCable:removeTowCabledPawn(pawnId)
	self:initGameSaveData()
	if self.Debug then LOG("Removing cable from pawn " .. pawnId) end
	GAME.starwars.tow_cabled[pawnId] = nil
end

function StarWars_TowCable:clearTowCabled()
	self:initGameSaveData()
	if self.Debug then LOG("Removing all cables") end
	GAME.starwars.tow_cabled = {}
end

-- Player mechs persist between missions so we need to reset move speed to base at mission end.
function StarWars_TowCable:restorePlayerMoveSpeeds()
	if not Board then
		return
	end

	self:initGameSaveData()
	for _, pawnId in ipairs(extract_table(Board:GetPawns(TEAM_PLAYER))) do
		if self.Debug then LOG("Checking pawn " .. pawnId) end
		local pawn = Board:GetPawn(pawnId)
		if pawn and pawn:IsMech() and GAME.starwars.tow_cabled[pawnId] then
			pawn:SetMoveSpeed(GAME.starwars.tow_cabled[pawnId])
		end
	end
end

function StarWars_TowCable:loadTowCabled()
	modApi:runLater(function()
		self:initGameSaveData()
		for pawnId, _ in pairs(GAME.starwars.tow_cabled) do
			local pawn = Board:GetPawn(pawnId)
			if pawn then
				pawn:SetMoveSpeed(0)
			end
		end
	end)
end

function StarWars_TowCable:load(options, version)
	modApi:addMissionStartHook(function(mission)
		self:clearTowCabled()
	end)

	modApi:addMissionEndHook(function(mission)
		self:restorePlayerMoveSpeeds()
		self:clearTowCabled()
	end)

	modapiext:addPawnKilledHook(function(mission, pawn)
		self:removeTowCabledPawn(pawn:GetId())
	end)

	modapiext:addGameLoadedHook(function() self:loadTowCabled() end)
	modapiext:addResetTurnHook(function() self:loadTowCabled() end)
end

function StarWars_TowCable:GetSkillEffect(p1, p2)
	local ret = SkillEffect()

	-- bHidePath seems odd but its how its done in vanilla grapple
	local projectileDamage = SpaceDamage(p2, self.Damage)
	projectileDamage.bHidePath = true

	-- Set fire if upgraded
	if self.SetFire then
		projectileDamage.iFire = EFFECT_CREATE
	end

	-- Set speed to 0
	if Board:IsPawnSpace(p2) then
		projectileDamage.sScript = projectileDamage.sScript .. [[
				local pawn = Board:GetPawn(]].. p2:GetString() ..[[)
					Board:Ping(pawn:GetSpace(), GL_Color(255, 0, 0))
					StarWars_TowCable:initGameSaveData()
					GAME.starwars.tow_cabled[pawn:GetId()] = pawn:GetMoveSpeed()
					pawn:SetMoveSpeed(0)
				]]
	end
	ret:AddProjectile(projectileDamage, self.ProjectileArt)

	if self.CancelAttack then
		BoardUtils.addCancelEffect(p2, ret)
	end

	-- cancel will put out the fire since its part of the same attack
	-- so apply it here so it displays (first one) and also takes effect
	if self.SetFire then
		local reapplyFire = SpaceDamage(p2)
		reapplyFire.iFire = EFFECT_CREATE
		ret:AddDamage(reapplyFire)
	end
	return ret
end
