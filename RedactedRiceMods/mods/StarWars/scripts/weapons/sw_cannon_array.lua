StarWars_CannonArray = Skill:new{
	Name = "Cannon Array",
	Description = "Move up to 2 spaces straight firing at all enemies on one side.",
	Class = "Brute",
	Description = "",
	Damage = 2,
	PowerCost = 1,
	Upgrades = 2,
	UpgradeCost = {2, 2},
	Icon = "weapons/brute_sw_cannon_array.png",
	TwoClick = true,
	MoveRange = 2,
	TargetRange = 1,
	LaunchSound = "/weapons/ricochet",
	ImpactSound = "/impact/generic/ricochet",
	Projectile1 = "effects/shot_sw_dual_red_split_1",
	Projectile2 = "effects/shot_sw_dual_red_split_2",
	TipImage = {
		CustomPawn = "StarWars_XWingMech",
		Unit = Point(2,3),
		Enemy = Point(3,2),
		Enemy2 = Point(4,2),
		Target = Point(2,1),
		Second_Click = Point(3,1),
	}
}

StarWars_CannonArray.boardUtils = mod_loader.mods[modApi.currentMod].libs.boardUtils

-- Weapon text definitions
Weapon_Texts.StarWars_CannonArray_Upgrade1 = "+1 Move Range"
Weapon_Texts.StarWars_CannonArray_A_UpgradeDescription = "Increases movement range to 3."
StarWars_CannonArray_A = StarWars_CannonArray:new{
	MoveRange = 3,
}

Weapon_Texts.StarWars_CannonArray_Upgrade2 = "+1 Attack Range"
Weapon_Texts.StarWars_CannonArray_B_UpgradeDescription = "Attacks enemies up to 2 tiles away."
StarWars_CannonArray_B = StarWars_CannonArray:new{
	TargetRange = 2,
}

StarWars_CannonArray_AB = StarWars_CannonArray_A:new{
	TargetRange = 2,
}

function StarWars_CannonArray:GetTargetArea(point)
	local ret = PointList()

	-- Show straight line movement options in all 4 directions
	for dir = DIR_START, DIR_END do
		for i = 1, self.MoveRange do
			local target = point + DIR_VECTORS[dir] * i
			if Board:IsValid(target) and not Board:IsBlocked(target, PATH_FLYER) then
				ret:push_back(target)
			else
				break
			end
		end
	end

	return ret
end

function StarWars_CannonArray:GetSecondTargetArea(p1, p2)
	local ret = PointList()
	local moveDir = GetDirection(p2 - p1)

	-- Get perpendicular directions
	local perpDir1 = (moveDir + 1) % 4
	local perpDir2 = (moveDir + 3) % 4

	-- Add an indicator for each side
	local side1 = p2 + DIR_VECTORS[perpDir1]
	local side2 = p2 + DIR_VECTORS[perpDir2]

	if Board:IsValid(side1) then
		ret:push_back(side1)
	end
	if Board:IsValid(side2) then
		ret:push_back(side2)
	end

	return ret
end

function StarWars_CannonArray:GetSkillEffect(p1, p2)
	local ret = SkillEffect()
	local moveDir = GetDirection(p2 - p1)

	-- Build the path with all the points
	local movePath = PointList()
	local pLast = p1
	while pLast ~= p2 do
		movePath:push_back(pLast)
		pLast = pLast + DIR_VECTORS[moveDir]
	end
	-- Add the last point too
	movePath:push_back(pLast)

	ret:AddMove(movePath, FULL_DELAY)
	return ret
end

function StarWars_CannonArray:GetFinalEffect(p1, p2, p3)
	local ret = SkillEffect()
	local moveDir = GetDirection(p2 - p1)
	local pawn = Board:GetPawn(p1)

	-- Determine which side to fire based on p3
	local fireDir = GetDirection(p3 - p2)

	-- Temporarily enable flying for movement
	local wasFlying = pawn:IsFlying()
	if not wasFlying then
		self.boardUtils.setHijackedFlying(pawn, true)
	end

	-- Fire from starting position first
	self:FireFromPositionInDirection(ret, p1, fireDir)

	local prev = p1
	local current = p1
	while current ~= p2 do
		current = current + DIR_VECTORS[moveDir]

		-- Move one space
		local movePath = PointList()
		movePath:push_back(prev)
		movePath:push_back(current)
		ret:AddMove(movePath, NO_DELAY)

		-- Add small delay for moving
		ret:AddDelay(0.1)

		-- Fire at targets on the chosen side from new position
		self:FireFromPositionInDirection(ret, current, fireDir)
		prev = current
	end

	-- Restore flying state
	if not wasFlying then
		ret:AddScript(string.format([[
			BoardUtils.setHijackedFlying(Board:GetPawn(%d), false)
		]], pawn:GetId()))
	end

	return ret
end

-- Helper function to fire in a specific direction
function StarWars_CannonArray:FireFromPositionInDirection(ret, fromPos, fireDir)
	-- Fire along the specified direction up to TargetRange
	for distance = 1, self.TargetRange do
		local target = fromPos + DIR_VECTORS[fireDir] * distance

		if not Board:IsValid(target) then
			break
		end

		if Board:IsPawnSpace(target) and Board:GetPawn(target):GetTeam() == TEAM_ENEMY then
			-- Fire 4 lasers alternating between projectile images
			for laser = 1, 4 do
				local projectile = (laser % 2 == 1) and self.Projectile1 or self.Projectile2
				-- Only do damage on the last laser
				local damage = SpaceDamage(target, laser == 4 and self.Damage or 0)
				ret:AddProjectile(fromPos, damage, projectile, laser == 1 and NO_DELAY or 0.05)
			end

			-- Pause between shots
			ret:AddDelay(0.1)
		end
	end
end
