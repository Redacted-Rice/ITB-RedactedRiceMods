WorldBuilders_Mold = Skill:new{
	Name = "Mold",
	Description = "Uplift the terrain to deal damage, throw the target and create a barrier",
	Class = "Prime",
	Icon = "weapons/prime_wb_mold.png",
	Rarity = 1,

	Explosion = "",
	LaunchSound = "/weapons/titan_fist",

	Range = 1,
	ThrowRange = 1,
	PathSize = 1,
	Projectile = false,
    Damage = 1,
    SplashDamage = 0,
    PowerCost = 0,
    Upgrades = 2,
    UpgradeCost = { 2, 1 },

	TwoClick = true,

	-- custom
	MakeMountains = false,
	Erupt = false,
	AdjRocks = false,

    TipImage = {
		Unit = Point(2,3),
		Target = Point(2,2),
		Enemy = Point(2,2),
		Second_Click = Point(1,2),
	},
}

Weapon_Texts.WorldBuilders_Mold_Upgrade1 = "Permanence"
WorldBuilders_Mold_A = WorldBuilders_Mold:new
{
	UpgradeDescription = "Create mountains instead of rocks",
	MakeMountains = true,
	Damage = 2,
}

Weapon_Texts.WorldBuilders_Mold_Upgrade2 = "Greater Uplift"
WorldBuilders_Mold_B = WorldBuilders_Mold:new
{
	UpgradeDescription = "Create rocks on adjacent, unoccupied tiles to the target",
	AdjRocks = true
}

WorldBuilders_Mold_AB = WorldBuilders_Mold_B:new
{
	MakeMountains = true,
	Damage = 2,
}

-- not used. We handle the cases in damage effect
function WorldBuilders_Mold:CanTargetSpace(space, damage)
	-- if its not a pawn, if the pawn is pushable, or if the pawn would die, we can target it
	local pushablePawn = not Board:IsPawnSpace(space) or not Board:GetPawn(space):IsGuarding() or damage >= Board:GetPawn(space):GetHealth()
	local okTerrain = not Board:IsTerrain(space, TERRAIN_BUILDING)
	return okTerrain and pushablePawn
end

function WorldBuilders_Mold:GetTargetArea(p1)
	local ret = PointList()
	for dir = DIR_START, DIR_END do
		local targetSpace = p1 + DIR_VECTORS[dir]
		if Board:IsValid(targetSpace) then
			ret:push_back(targetSpace)
		end
	end

	return ret
end

function WorldBuilders_Mold:GetSecondTargetArea(p1,p2)
	local ret = PointList()

	-- "borrowed" from general_DiamondTarget and modified to not
	-- include point
	local size = self.ThrowRange
	local corner = p2 - Point(size, size)

	local p = Point(corner)
	local isPawnTargetted = Board:IsPawnSpace(p2)

	for i = 0, ((size*2+1)*(size*2+1)) do
		local diff = p2 - p
		local dist = math.abs(diff.x) + math.abs(diff.y)
		-- If the space is not an invalid target (multispace, non pushable pawn)
		if dist <= size and Board:IsValid(p) and
				(not isPawnTargetted or not Board:IsBlocked(p, PATH_FLYER)) then
			ret:push_back(p)
		end
		p = p + VEC_RIGHT
		if math.abs(p.x - corner.x) == (size*2+1) then
			p.x = p.x - (size*2+1)
			p = p + VEC_DOWN
		end
	end

	return ret
end

function WorldBuilders_Mold:GetSkillEffect(p1, p2)
	return self:GetFinalEffect(p1, p2, p2)
end

function WorldBuilders_Mold:AddRock(effect, point)
	-- automagically does the animation
	effect.sPawn = "Wall"
	local terrain = Board:GetTerrain(point)
	LOG(point:GetString().." TERRAIN "..terrain.. " WTAER "..TERRAIN_WATER)
	if terrain == TERRAIN_HOLE or terrain == TERRAIN_WATER or terrain == TERRAIN_ACID or terrain == TERRAIN_LAVA then
		LOG("NEW TERRAIN")
		effect.iTerrain = TERRAIN_ROAD
	end
end

function WorldBuilders_Mold:GetFinalEffect(p1,p2,p3)
	local ret = SkillEffect()

	local damage = SpaceDamage(p2, self.Damage)
	local terrain = SpaceDamage(p2, 0)
	local isPawnTargetted = Board:IsPawnSpace(p2)
	-- is it a building or is it an unpushable pawn that won
	local isUnpushablePawn = isPawnTargetted and Board:GetPawn(p2):IsGuarding()
	local pawnWillDie = isPawnTargetted and self.Damage >= Board:GetPawn(p2):GetHealth()
	local unTerraformable = Board:IsTerrain(p2, TERRAIN_BUILDING) or
			(isUnpushablePawn and not pawnWillDie)
	local bounce = -3
	if self.MakeMountains then
		if not unTerraformable then
			terrain.iTerrain = TERRAIN_MOUNTAIN
		end
		bounce = -6
	elseif not unTerraformable then
		self:AddRock(terrain, p2)
	end

	ret:AddDamage(damage)
	ret:AddBounce(p2, bounce)

	if isPawnTargetted and not isUnpushablePawn then
		local move = PointList()
		move:push_back(p2)
		move:push_back(p3)
		ret:AddLeap(move, NO_DELAY)
	end

	ret:AddDamage(terrain)
	ret:AddDelay(0.3)
	ret:AddBounce(p1, 1)

	if self.AdjRocks then
		for dir = DIR_START, DIR_END do
			local adjSpace = p2 + DIR_VECTORS[dir]
			local adjDamage = SpaceDamage(adjSpace, 0)
			local terrain = Board:GetTerrain(adjSpace)
			if (not isPawnTargetted or p3 ~= adjSpace) and terrain ~= TERRAIN_BUILDING and terrain ~= TERRAIN_MOUNTAIN and Board:GetPawn(adjSpace) == nil then
				self:AddRock(adjDamage, adjSpace)
				ret:AddBounce(adjSpace, -3)
			end
			ret:AddDamage(adjDamage)
		end
	end

	return ret
end

-- Remove
function WorldBuilders_Mold:TerrainCanBeOccupied(terrain)
	return terrain ~= TERRAIN_BUILDING and terrain ~= TERRAIN_MOUNTAIN
end
