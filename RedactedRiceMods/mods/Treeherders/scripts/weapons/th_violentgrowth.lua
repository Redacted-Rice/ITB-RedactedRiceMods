Treeherders_ViolentGrowth = Skill:new
{
	Name = "Violent Growth",
    Class = "Science",
    Description = "Grows a forest in an unforested tile otherwise cancels target's attack. Expands connected forest one tile towards the closest enemy or closest spot to current position. Forest growth damages enemies",
	Icon = "weapons/science_th_violentGrowth.png",
	Rarity = 1,
	
	Explosion = "",
	--TODO sounds
--	LaunchSound = "/weapons/titan_fist",
--	ImpactSound = "/impact/generic/tractor_beam",
	
	Range = 1,
	PathSize = 1,
    Damage = 1,
	
    PowerCost = 0,
    Upgrades = 2,
    UpgradeCost = { 1, 2 },
	
	TwoClick = true,
	
	-- custom options
	ForestDamageBounce = -2,
	NonForestBounce = 2,
	ForestGenBounce = forestUtils.floraformBounce,
	
	ForestToExpand = 0,
	SlowEnemy = false,
	SlowEnemyAmount = 3,
	MinEnemyMove = 1,
	
    TipImage = {
		Unit = Point(2,3),
		Target = Point(2,2),
		Enemy = Point(2,2),
		Enemy2 = Point(1,1),
		Forest = Point(2,2),
		Forest2 = Point(1,2),
		Second_Click = Point(1,1),
	},
}

Weapon_Texts.Treeherders_ViolentGrowth_Upgrade1 = "Ensnare"
Treeherders_ViolentGrowth_A = Treeherders_ViolentGrowth:new
{
	UpgradeDescription = "For one turn all vek in the targetted forest lose three movement (minimum of 1)",
	SlowEnemy = true,
}

Weapon_Texts.Treeherders_ViolentGrowth_Upgrade2 = "+2 Expansion"
Treeherders_ViolentGrowth_B = Treeherders_ViolentGrowth:new
{
	UpgradeDescription = "Expand the targeted forest two extra tiles",
	ForestToExpand = 2,
}

Treeherders_ViolentGrowth_AB = Treeherders_ViolentGrowth_B:new
{	
	SlowEnemy = true,
}


-------- Use default target area -----------------


function Treeherders_ViolentGrowth:GetSecondTargetArea(p1,p2)
	local ret = PointList()
	
	local forestGroup = forestUtils:getGroupingOfSpaces(p2, forestUtils.isAForest)
	for _, p in pairs(forestGroup.group) do
		ret:push_back(p)
	end
	for _, p in pairs(forestGroup.boardering) do
		ret:push_back(p)
	end
	
	return ret
end

function Treeherders_ViolentGrowth:GetSkillEffect(p1, p2)
	local ret = SkillEffect()
	local attackDir = GetDirection(p2 - p1)
	
	----- For the main target ------
	local pushDir = nil
	if self.PushTarget then
		pushDir = attackDir
	end
		
	--if it is a forest, cancel the target's attack
	if forestUtils.isAForest(p2) then
		ret:AddDamage(forestUtils:getSpaceDamageWithoutSettingFire(p2, self.Damage, pushDir, true, true))
		forestUtils:addCancelEffect(p2, ret)
		ret:AddBounce(p2, self.NonForestBounce)
	
	--if it can be floraformed, do so
	elseif forestUtils.isSpaceFloraformable(p2) then
		forestUtils:floraformSpace(ret, p2, self.Damage, pushDir, false, true)
		
	--otherwise just damage it
	else
		ret:AddDamage(SpaceDamage(p2, self.Damage))
		ret:AddBounce(p2, self.NonForestBounce)
	end
	
	return ret
end

function Treeherders_ViolentGrowth:GetFinalEffect(p1,p2,p3)
	-- start with the primary effect
	local ret = self:GetSkillEffect(p1, p2)
	
	--small break to make the animation and move make more sense
	ret:AddDelay(0.4)
	
	----- For expansion ------
	
	-- Player now selects second tile
	local expansionFocus = p3
	forestUtils:floraformSpace(ret, expansionFocus, self.Damage, nil, true, true)
	
	--Get all spaces in the grouping
	local forestPoints = {}
	forestPoints[forestUtils:getSpaceHash(p2)] = p2
	forestPoints[forestUtils:getSpaceHash(p3)] = p3
	local forestGroup = forestUtils:getGroupingOfSpacesMultiple(forestPoints, forestUtils.isAForest)
	
	--ensure the space we just formed is not in the boarding list - it will be in the group list
	forestGroup.boardering[forestUtils:getSpaceHash(p2)] = nil
	forestGroup.boardering[forestUtils:getSpaceHash(p3)] = nil
	
	local candidates = {}
	for k, v in pairs(forestGroup.boardering) do
		if forestUtils.isSpaceFloraformable(v) and v ~= p2 then
			candidates[k] = v
		end
	end
	
	local newForests = {}
	for i = 1, self.ForestToExpand do
		if forestUtils.arrayLength(candidates) > 0 then
			--get the nearest point, and remove it from the candidates
			local expansion = forestUtils:getClosestOfSpaces(expansionFocus, candidates)
			candidates[forestUtils:getSpaceHash(expansion)] = nil
			newForests[forestUtils:getSpaceHash(expansion)] = expansion
			
			--floraform it
			forestUtils:floraformSpace(ret, expansion, self.Damage, nil, true, true)
		end
	end
	newForests[forestUtils:getSpaceHash(p2)] = p2
	
	
	----- For slowing enemies -----
	
	--any enemy in the forest, slow down temporarily if the powerup is enabled
	if self.SlowEnemy then
		for _, v in pairs(forestGroup.group) do
			local pawn = Board:GetPawn(v)
			if pawn and pawn:IsEnemy() then
				local slow = -self.SlowEnemyAmount
				
				if (pawn:GetMoveSpeed() - self.SlowEnemyAmount) < self.MinEnemyMove then
					slow = self.MinEnemyMove - pawn:GetMoveSpeed()
				end 
				
				ret:AddScript([[Board:GetPawn(]]..pawn:GetId()..[[):AddMoveBonus(]]..slow..[[)]])
			end
		end
	end
	
	return ret
end