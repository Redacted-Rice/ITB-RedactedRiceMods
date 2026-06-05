StarWars_AuxiliarySuperlaser = Skill:new{
	Name = "Aux. Superlaser",
	Description = "Instakills center tile and turns it to lava. Deals 3 damage adjacent, 1 damage beyond. Recharged by repair.",
	Class = "Science",
	PowerCost = 2,
	Upgrades = 2,
	UpgradeCost = {3, 2},
	Orbital = true,
	Limited = 1,
	SplashDamage = 3,
	SplashFurtherDamage = 1,
	ShakeBaseVal = 0.4,
	BounceBaseVal = 30,
	BounceDecay = 0.80,
	ShockwaveDelay = 0.1,
	Icon = "weapons/science_sw_auxiliary_laser.png",
	Explosion = "explo_fire1",
	LaunchSound = "/weapons/laser_burst",
	ImpactSound = "/impact/generic/explosion",
	Projectile = "effects/shot_sw_superlaser",
	TipImage = {
		Target = Point(2, 1),
		Enemy = Point(2, 1),
		Mountain = Point(2, 2),
	}
}

-- Add orbital launch animation (reuse timetravel effect)
ANIMS.StarWars_AuxSuperlaser_Anim = Animation:new{
	Image = "effects/superlaser_core.png",
	NumFrames = 14,
	Loop = false,
	PosX = -40,
	Time = 0.05,
	PosY = -360,
}

local mod = mod_loader.mods[modApi.currentMod]

Weapon_Texts.StarWars_AuxiliarySuperlaser_Upgrade1 = "+1 Damage"
Weapon_Texts.StarWars_AuxiliarySuperlaser_A_UpgradeDescription = "+1 damage to all spaces"
StarWars_AuxiliarySuperlaser_A = StarWars_AuxiliarySuperlaser:new{
	SplashDamage = 4,
	SplashFurtherDamage = 2,
}

Weapon_Texts.StarWars_AuxiliarySuperlaser_Upgrade2 = "Extra Capacitors"
Weapon_Texts.StarWars_AuxiliarySuperlaser_B_UpgradeDescription = "Starts with two charges"
StarWars_AuxiliarySuperlaser_B = StarWars_AuxiliarySuperlaser:new{
	Limited = 2,
}

StarWars_AuxiliarySuperlaser_AB = StarWars_AuxiliarySuperlaser_A:new{
	Limited = 2,
}

-- No longer auto-charges - recharge now happens via Death Star's repair action

function StarWars_AuxiliarySuperlaser:GetTargetArea(point)
	local ret = PointList()

	-- Can target any valid space on the board
	local size = Board:GetSize()
	for x = 0, size.x - 1 do
		for y = 0, size.y - 1 do
			local p = Point(x, y)
			ret:push_back(p)
		end
	end
	return ret
end

local function addSplashDamage(ret, splashSpace, damage)
	if Board:IsValid(splashSpace) then
		local splashDamage = SpaceDamage(splashSpace, damage)

		-- Terrain changes
		if Board:GetTerrain(splashSpace) == TERRAIN_ICE then
			splashDamage.iTerrain = TERRAIN_WATER
		elseif Board:GetTerrain(splashSpace) == TERRAIN_MOUNTAIN then
			-- Scorched earth effect: Turn mountain to rubble and set it on fire
			splashDamage.iTerrain = TERRAIN_RUBBLE
			splashDamage.iFire = EFFECT_CREATE
		end
		ret:AddDamage(splashDamage)
	end
end

function StarWars_AuxiliarySuperlaser:GetSkillEffect(p1, p2)
	local ret = SkillEffect()

	ret:AddScript([[
		Board:AddAnimation(]] .. p2:GetString().. [[, "StarWars_AuxSuperlaser_Anim", 1)
	]])
	ret:AddDelay(0.3)

	-- Center tile - instant kill and turn to lava
	local centerDamage = SpaceDamage(p2, DAMAGE_DEATH)
	if not Board:IsTerrain(p2, TERRAIN_HOLE) then
		centerDamage.iTerrain = TERRAIN_LAVA
	end
	
	ret:AddDamage(centerDamage)
	ret:AddBoardShake(self.ShakeBaseVal * self.SplashDamage)
	ret:AddDelay(self.ShockwaveDelay)

	-- Add shockwave effect using bounce - emanates from center
	local bounce = self.BounceBaseVal
	ret:AddBounce(p2, bounce)
	bounce = bounce * self.BounceDecay

	-- Adjacent tiles
	for dir = DIR_START, DIR_END do
		local adjacentPos = p2 + DIR_VECTORS[dir]
		addSplashDamage(ret, adjacentPos, self.SplashDamage)
		-- Add bounce to adjacent tiles for shockwave effect
		if Board:IsValid(adjacentPos) then
			ret:AddBounce(adjacentPos, bounce)
		end
	end
	bounce = bounce * self.BounceDecay
	ret:AddDelay(self.ShockwaveDelay)

	-- Two away straight line
	for dir = DIR_START, DIR_END do
		local adjacentPos = p2 + DIR_VECTORS[dir] * 2
		addSplashDamage(ret, adjacentPos, self.SplashFurtherDamage)
		-- Add bounce to further tiles for diminishing shockwave effect
		if Board:IsValid(adjacentPos) then
			ret:AddBounce(adjacentPos, bounce)
		end
	end
	-- Two away corners
	for dir = DIR_START, DIR_END do
		local adjacentCornerPos = p2 + DIR_VECTORS[dir] + DIR_VECTORS[(dir + 1) % 4]
		addSplashDamage(ret, adjacentCornerPos, self.SplashFurtherDamage)
		-- Add bounce to corner tiles for diminishing shockwave effect
		if Board:IsValid(adjacentCornerPos) then
			ret:AddBounce(adjacentCornerPos, bounce)
		end
	end
	bounce = bounce * self.BounceDecay
	ret:AddDelay(self.ShockwaveDelay)

	-- Continue the shockwave out to end of board
	local maxDistance = Board:GetSize().x + Board:GetSize().y
	for distance = 3, maxDistance do
		local hasValidTile = false
		-- Diagonals
		for dir = DIR_START, DIR_END do
			for diagIdx = 0, (distance - 1) do
				local diagonalPos = p2 + DIR_VECTORS[dir] * (distance - diagIdx) + DIR_VECTORS[(dir + 1) % 4] * diagIdx
				if Board:IsValid(diagonalPos) then
					hasValidTile = true
					ret:AddBounce(diagonalPos, bounce)
				end
			end
		end
		if hasValidTile then
			bounce = bounce * self.BounceDecay
			ret:AddDelay(self.ShockwaveDelay)
		end
	end

	return ret
end
