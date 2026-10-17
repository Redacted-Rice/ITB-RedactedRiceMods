StarWars_HeavyCannons = Skill:new{
	Name = "Heavy Cannons",
	Description = "Artillery shot dealing 2 damage to center, 1 splash damage in T-shape around target.",
	Class = "Ranged",
	Damage = 2,
	SideSplashDamage = 1,
	BehindSplashDamage = 1,
	PowerCost = 1,
	Upgrades = 2,
	UpgradeCost = {2, 2},
	Icon = "weapons/artillery_sw_heavy_turbocannons.png",
	FireSound = "/weapons/push_beam",
	ImpactSound = "/impact/generic/explosion",
	TipImage = {
		CustomPawn = "StarWars_ATATMech",
		Unit = Point(2, 3),
		Enemy = Point(3, 1),
		Enemy2 = Point(2, 1),
		Enemy3 = Point(4, 1),
		Enemy4 = Point(3, 0),
		Target = Point(3, 1),
	},
	BouncePerDamage = 1,
	ExtraRange = false,
	MinRange = 1,
	MaxRange = 5,

	ArtilleryHeight = 0,
	ArtilleryHeightLock = true,
	Projectile1 = "effects/shot_sw_dual_heavy_red_split_1.png",
	Projectile2 = "effects/shot_sw_dual_heavy_red_split_2.png",
	Shots = 2,
	ShotsDelay = 0.15,
}

Weapon_Texts.StarWars_HeavyCannons_Upgrade1 = "Quality Gas"
Weapon_Texts.StarWars_HeavyCannons_A_UpgradeDescription = "+1 damage to center and far tile"
StarWars_HeavyCannons_A = StarWars_HeavyCannons:new{
	Damage = 3,
	BehindSplashDamage = 2,
	Projectile1 = "effects/shot_sw_dual_heavy_green_split_1.png",
	Projectile2 = "effects/shot_sw_dual_heavy_green_split_2.png",
}

Weapon_Texts.StarWars_HeavyCannons_Upgrade2 = "Extra Range"
Weapon_Texts.StarWars_HeavyCannons_B_UpgradeDescription = "Can fire in a 180 degree arc"
StarWars_HeavyCannons_B = StarWars_HeavyCannons:new{
	ExtraRange = true,
}

StarWars_HeavyCannons_AB = StarWars_HeavyCannons_A:new{
	ExtraRange = true,
}

function StarWars_HeavyCannons:GetTargetArea(point)
	local ret = PointList()
	local direction = DIR_RIGHT

	if not self.ExtraRange then
		local seen = {}
		BoardUtils.addForwardConeToList(ret, seen, point, direction, 1, self.MinRange, self.MaxRang)
	else
		local dirVec = DIR_VECTORS[direction]
		BoardUtils.getReachableInRange(ret, self.MaxRange, point, nil, function(adj)
			local diff = adj - point
			local forward = diff.x * dirVec.x + diff.y * dirVec.y
			return BoardUtils.getManhattanDistance(point, adj) >= self.MinRange and forward >= 0
		end)
	end
	return ret
end

function StarWars_HeavyCannons:GetSkillEffect(p1, p2)
	local ret = SkillEffect()
	local pDiff = p2 - p1
	-- Get direction but make diagonals go forward
	local attackDir = GetDirection(pDiff)
	--if math.abs(pDiff.x) == math.abs(pDiff.y) then
	--	attackDir = DIR_RIGHT
	--end

	-- Center tile damage - Fire 2 shots alternating projectiles, only second does damage
	for shot = 1, self.Shots do
		local projectile = (shot % 2 == 1) and self.Projectile1 or self.Projectile2
		local damage = shot == self.Shots and self.Damage or 0
		local delay = shot == self.Shots and FULL_DELAY or self.ShotsDelay
		local sd = SpaceDamage(p2, damage)
		ret:AddSound(self.FireSound)
		ret:AddArtillery(sd, projectile, delay)
	end
	ret:AddBounce(p2, self.BouncePerDamage * self.Damage)
	ret:AddDelay(0.2)

	-- T-shape splash damage: perpendicular and same direction from attack
	-- space beyond the primary target
	local behindPos = p2 + DIR_VECTORS[attackDir]
	if Board:IsValid(behindPos) then
		local splashDamage = SpaceDamage(behindPos, self.BehindSplashDamage)
		ret:AddDamage(splashDamage)
		ret:AddBounce(behindPos, self.BouncePerDamage * self.BehindSplashDamage)
	end
	ret:AddDelay(0.1)

	-- Perpendicular left
	local perpLeft = (attackDir + 1) % 4
	local leftPos = p2 + DIR_VECTORS[perpLeft]
	if Board:IsValid(leftPos) then
		local splashDamage = SpaceDamage(leftPos, self.SideSplashDamage)
		ret:AddDamage(splashDamage)
		ret:AddBounce(leftPos, self.BouncePerDamage * self.SideSplashDamage)
	end

	-- Perpendicular right
	local perpRight = (attackDir + 3) % 4
	local rightPos = p2 + DIR_VECTORS[perpRight]
	if Board:IsValid(rightPos) then
		local splashDamage = SpaceDamage(rightPos, self.SideSplashDamage)
		ret:AddDamage(splashDamage)
		ret:AddBounce(rightPos, self.BouncePerDamage * self.SideSplashDamage)
	end
	return ret
end
