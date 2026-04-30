StarWars_CannonArray = Skill:new{
	Name = "Cannon Array",
	Description = "Move up to 2 spaces straight firing at all enemies on one side.",
	Class = "Brute",
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
	local pawn = Board:GetPawn(point)
	if not pawn then return ret end
	
	-- Temporarily set the pawn's move speed to our weapon range
	local originalMoveSpeed = pawn:GetMoveSpeed()
	pawn:SetMoveSpeed(self.MoveRange)
	
	-- Get all tiles reachable by the Move skill and fire the skill build manually
	-- for things like nimble
	local moveTargets = Move:GetTargetArea(point)
	modApiExt_internal.fireTargetAreaBuildHooks(
		modApiExt_internal.mission,
		pawn, "Move", point, moveTargets
	)
	
	-- Restore original move speed
	pawn:SetMoveSpeed(originalMoveSpeed)
	
	-- Filter to only straight line moves in 4 directions
	for dir = DIR_START, DIR_END do
		for i = 1, self.MoveRange do
			local target = point + DIR_VECTORS[dir] * i
			if Board:IsValid(target) then
				-- Check if this tile is reachable by the Move skill
				for j = 1, moveTargets:size() do
					if moveTargets:index(j) == target then
						ret:push_back(target)
						break
					end
				end
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

	-- Show the line of targets on each side along the entire move path
	local current = p1
	while true do
		-- Add targets on both sides of current position
		local side1 = current
		local side2 = current
		for i = 1, self.TargetRange do
			side1 = side1 + DIR_VECTORS[perpDir1]
			side2 = side2 + DIR_VECTORS[perpDir2]
			if Board:IsValid(side1) then
				ret:push_back(side1)
			end
			if Board:IsValid(side2) then
				ret:push_back(side2)
			end
		end

		-- Move to next position along path
		if current == p2 then
			break
		end
		current = current + DIR_VECTORS[moveDir]
	end

	return ret
end

function StarWars_CannonArray:GetSkillEffect(p1, p2)
	local pawn = Board:GetPawn(p1)
	if not pawn then return SkillEffect() end
	
	local ret = SkillEffect()
	
	-- Build straight line path from p1 to p2
	local path = PointList()
	local moveDir = GetDirection(p2 - p1)
	local current = p1
	path:push_back(current)
	while current ~= p2 do
		current = current + DIR_VECTORS[moveDir]
		path:push_back(current)
	end
	
	-- Show the path with no delay for preview
	BoardUtils.addForcedMove(ret, path, NO_DELAY)
	
	return ret
end

function StarWars_CannonArray:GetFinalEffect(p1, p2, p3)
	local pawn = Board:GetPawn(p1)
	if not pawn then return SkillEffect() end
	
	local ret = SkillEffect()
	
	-- Determine which side to fire based on p3
	local moveDir = GetDirection(p2 - p1)
	local perpDir1 = (moveDir + 1) % 4
	local perpDir2 = (moveDir + 3) % 4
	local fireDir = perpDir1
	
	-- Build straight line path from p1 to p2
	local path = PointList()
	
	-- Check the first p
	local current = p1
	path:push_back(current)
	
	-- See which side its on while constructing the path
	local testSide = current
	for i = 1, self.TargetRange do
		testSide = testSide + DIR_VECTORS[perpDir2]
		if p3 == testSide then
			fireDir = perpDir2
		end
	end
	
	-- Check the rest of the ps
	while current ~= p2 do
		current = current + DIR_VECTORS[moveDir]
		path:push_back(current)
		
		testSide = current
		for i = 1, self.TargetRange do
			testSide = testSide + DIR_VECTORS[perpDir2]
			if p3 == testSide then
				fireDir = perpDir2
			end
		end
	end
	
	-- Show the path with no delay for preview
	BoardUtils.addForcedMove(ret, path, NO_DELAY)
	
	-- Move through path one space at a time, firing at each position
	local pawnId = pawn:GetId()
	for i = 1, path:size() do
		local newPos = path:index(i)
		
		-- Move to this position
		BoardUtils.addForcedSigleMove(ret, pawnId, newPos)
		
		-- Fire from current position
		self:FireFromPositionInDirection(ret, newPos, fireDir)
		
		-- Add small delay between positions
		if i < path:size() then
			ret:AddDelay(0.1)
		end
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
