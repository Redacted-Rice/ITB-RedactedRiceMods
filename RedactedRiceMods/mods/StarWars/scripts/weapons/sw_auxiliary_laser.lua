StarWars_AuxiliaryLaser = Skill:new{
	Name = "Aux. Superlaser",
	Description = "Instakills center tile and turns it to lava. Deals 3 damage adjacent, 1 damage beyond.",
	Class = "Science",
	PowerCost = 2,
	Upgrades = 2,
	UpgradeCost = {3, 2},
	Limited = 2,
	SplashDamage = 3,
	SplashFurtherDamage = 1,
	ShakeBaseVal = 0.4,
	Icon = "weapons/science_sw_auxiliary_laser.png",
	LaunchSound = "/weapons/laser_burst",
	ImpactSound = "/impact/generic/explosion",
	Projectile = "effects/shot_laser_death",
	TipImage = {
		Target = Point(2, 1),
		Enemy = Point(2, 1),
		Mountain = Point(2, 2),
	}
}

-- TODO: Add shockwave effect

Weapon_Texts.StarWars_AuxiliaryLaser_Upgrade1 = "+1 Damage"
Weapon_Texts.StarWars_AuxiliaryLaser_A_UpgradeDescription = "+1 damage to all spaces"
StarWars_AuxiliaryLaser_A = StarWars_AuxiliaryLaser:new{
	SplashDamage = 4,
	SplashFurtherDamage = 2,
}

Weapon_Texts.StarWars_AuxiliaryLaser_Upgrade2 = "Quick Charge"
Weapon_Texts.StarWars_AuxiliaryLaser_B_UpgradeDescription = "+1 use"
StarWars_AuxiliaryLaser_B = StarWars_AuxiliaryLaser:new{
	Limited = 3,
}

StarWars_AuxiliaryLaser_AB = StarWars_AuxiliaryLaser_A:new{
	Limited = 3,
}

function StarWars_AuxiliaryLaser:GetTargetArea(point)
	local ret = PointList()

	-- Can target any valid space on the board
	local size = Board:GetSize()
	for x = 0, size.x - 1 do
		for y = 0, size.y - 1 do
			local p = Point(x, y)
			if Board:IsValid(p) and p ~= point then
				ret:push_back(p)
			end
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

function StarWars_AuxiliaryLaser:GetSkillEffect(p1, p2)
	local ret = SkillEffect()

	-- Center tile - instant kill and turn to lava
	local centerDamage = SpaceDamage(p2, DAMAGE_DEATH)
	if not Board:IsTerrain(p2, TERRAIN_HOLE) then
		centerDamage.iTerrain = TERRAIN_LAVA
	end
	ret:AddDamage(centerDamage)
	ret:AddBoardShake(self.ShakeBaseVal * self.SplashDamage)
	ret:AddDelay(0.1)

	-- Adjacent tiles
	for dir = DIR_START, DIR_END do
		local adjacentPos = p2 + DIR_VECTORS[dir]
		addSplashDamage(ret, adjacentPos, self.SplashDamage)
	end
	ret:AddDelay(0.1)

	-- Two away straight line
	for dir = DIR_START, DIR_END do
		local adjacentPos = p2 + DIR_VECTORS[dir] * 2
		addSplashDamage(ret, adjacentPos, self.SplashFurtherDamage)
	end
	-- Two away corners
	for dir = DIR_START, DIR_END do
		local adjacentCornerPos = p2 + DIR_VECTORS[dir] + DIR_VECTORS[(dir + 1) % 4]
		addSplashDamage(ret, adjacentCornerPos, self.SplashFurtherDamage)
	end

	return ret
end
