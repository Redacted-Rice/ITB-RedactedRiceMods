StarWars_HeavyCannons = Skill:new{
	Name = "Heavy Cannons",
	Description = "Artillery shot dealing 2 damage to center, 1 splash damage in T-shape around target.",
	Class = "Brute",
	Damage = 2,
	SideSplashDamage = 1,
	BehindSplashDamage = 1,
	PowerCost = 1,
	Upgrades = 2,
	UpgradeCost = {2, 2},
	Icon = "weapons/brute_sw_heavy_turbocannons.png",
	LaunchSound = "/weapons/cannon_volley",
	ImpactSound = "/impact/generic/explosion",
	TipImage = {
		CustomPawn = "StarWars_ATATMech",
		Unit = Point(2, 3),
		Enemy = Point(2, 1),
		Enemy2 = Point(1, 1),
		Enemy3 = Point(3, 1),
		Enemy4 = Point(2, 0),
		Target = Point(2, 1),
	},
	BouncePerDamage = 1,
	ExtraRange = false,
	MinRange = 1,
	MaxRange = 16,

	ArtilleryHeight = 0,
	ArtilleryHeightLock = true,
	Projectile1 = "effects/shot_sw_dual_heavy_red_split_1",
	Projectile2 = "effects/shot_sw_dual_heavy_red_split_2",
	Shots = 2,
	ShotsDelay = 0.15,
}

Weapon_Texts.StarWars_HeavyCannons_Upgrade1 = "Quality Gas"
Weapon_Texts.StarWars_HeavyCannons_A_UpgradeDescription = "+1 damage to center and far tile"
StarWars_HeavyCannons_A = StarWars_HeavyCannons:new{
	Damage = 3,
	BehindSplashDamage = 2,
	Projectile1 = "effects/shot_sw_dual_heavy_green_split_1",
	Projectile2 = "effects/shot_sw_dual_heavy_green_split_2",
}

Weapon_Texts.StarWars_HeavyCannons_Upgrade2 = "Extra Range"
Weapon_Texts.StarWars_HeavyCannons_B_UpgradeDescription = "Can fire in a 180 degree arc"
StarWars_HeavyCannons_B = StarWars_HeavyCannons:new{
	ExtraRange = true,
}

StarWars_HeavyCannons_AB = StarWars_HeavyCannons_A:new{
	ExtraRange = true,
}

-- Calculate manhattan distance between two points
local function manhattanDistance(p1, p2)
	return math.abs(p1.x - p2.x) + math.abs(p1.y - p2.y)
end

-- Check if a point is within range constraints
local function isInRange(origin, target, minRange, maxRange)
	local distance = manhattanDistance(origin, target)
	return distance >= minRange and distance <= maxRange
end

local function addConeToList(pointsList, origin, direction, startWidth, minRange, maxRange)
	local basePoint = origin + DIR_VECTORS[direction]
	local currDepth = startWidth or 1

	-- A cone includes the main direction and both diagonal directions adjacent to it
	local leftDir = (direction + 1) % 4
	local rightDir = (direction + 3) % 4

	local leftVec = DIR_VECTORS[leftDir]
	local rightVec = DIR_VECTORS[rightDir]

	-- Check if the target can be reached by going forward, forward-left, or forward-right
	-- We allow any combination of forward movement with left or right diagonal movement
	while Board:IsValid(basePoint) do
		local baseDistance = manhattanDistance(origin, basePoint)
		if baseDistance > maxRange then
			-- Stop if we've exceeded max range even on the main axis as this will be the "furthest" point
			-- in our algorithm
			break
		elseif baseDistance >= minRange then
			-- Otherwise add this point as long as its in range
			pointsList:push_back(basePoint)
		end

		for i = 1, currDepth do
			local leftTarget = basePoint + leftVec * i
			local rightTarget = basePoint + rightVec * i
			local sidewaysDistance = manhattanDistance(origin, leftTarget)
			-- Only try to add if this point is above our min range
			if sidewaysDistance >= minRange then
				if sidewaysDistance > maxRange then
					-- Stop if we've exceeded max range even on the main axis as this will be the "furthest" point
					-- in our algorithm
					break
				end
				if Board:IsValid(leftTarget) then
					pointsList:push_back(leftTarget)
				end
				if Board:IsValid(rightTarget) then
					break
				end
				if Board:IsValid(leftTarget) then
					pointsList:push_back(leftTarget)
				end
				if Board:IsValid(rightTarget) then
					pointsList:push_back(rightTarget)
				end
			end
		end

		basePoint = basePoint + DIR_VECTORS[direction]
		currDepth = currDepth + 1
	end
end

local function create3QuartersArc(origin, direction, minRange, maxRange)
	local ret = PointList()
	local basePoint = origin + DIR_VECTORS[direction]

	-- A 3/4 arc includes the main direction and both diagonal directions adjacent to it
	local leftDir = (direction + 1) % 4
	local rightDir = (direction + 3) % 4

	addConeToList(ret, basePoint, leftDir, 3, minRange, maxRange)
	addConeToList(ret, basePoint, rightDir, 3, minRange, maxRange)
	addConeToList(ret, basePoint, direction, 1, minRange, maxRange)
	return ret
end

local function createCone(origin, direction, startWidth, minRange, maxRange)
	local ret = PointList()
	addConeToList(ret, origin, direction, startWidth, minRange, maxRange)
	return ret
end

function StarWars_HeavyCannons:GetTargetArea(point)
	local ret = PointList()

	-- Get the mech's facing direction
	local pawn = Board:GetPawn(point)
	local direction = DIR_RIGHT

	if not self.ExtraRange then
		return createCone(point, direction, math.max(Board:GetSize().x, Board:GetSize().y), self.MinRange, self.MaxRange)
	else
		return create3QuartersArc(point, direction, self.MinRange, self.MaxRange)
	end
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
