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
	
	-- custom options
	ForestDamageBounce = -2,
	NonForestBounce = 2,
	ForestGenBounce = forestUtils.floraformBounce,
	
	PushTarget = false,
	SeekVek = true,
	
	ForestToExpand = 1,
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
	},
}

Weapon_Texts.Treeherders_ViolentGrowth_Upgrade1 = "Ensnare"
Treeherders_ViolentGrowth_A = Treeherders_ViolentGrowth:new
{
	UpgradeDescription = "For one turn all vek in the targetted forest lose three movement (minmum of 1)",
	SlowEnemy = true,
}

Weapon_Texts.Treeherders_ViolentGrowth_Upgrade2 = "+2 Expansion"
Treeherders_ViolentGrowth_B = Treeherders_ViolentGrowth:new
{
	UpgradeDescription = "Expand the targeted forest two extra tiles",
	ForestToExpand = 3,
}

Treeherders_ViolentGrowth_AB = Treeherders_ViolentGrowth_B:new
{	
	SlowEnemy = true,
}

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
	
	--small break to make the animation and move make more sense
	ret:AddDelay(0.4)
	
	
	----- For expansion ------
	
	--pick tiles to expand to and damage if appropriate
	--get tiles closest to enemies
	local expansionFocus = p1
	if self.SeekVek then
		local vekPositions = {}
		for _, v in pairs(extract_table(Board:GetPawns(TEAM_ANY))) do
			if forestUtils.isAVek(Board:GetPawn(v)) then
				local vPos = Board:GetPawnSpace(v)
				-- exclude if the vek is the target or already is in a forest
				if (vPos ~= p2) and not forestUtils.isAForest(vPos) then
					vekPositions[forestUtils:getSpaceHash(vPos)] = vPos
				end
			end
		end
		
		if forestUtils.arrayLength(vekPositions) > 0 then
			expansionFocus = forestUtils:getClosestOfSpaces(p2, vekPositions)
		end
	end
	
	--Get all spaces in the grouping
	local forestGroup = forestUtils:getGroupingOfSpaces(p2, forestUtils.isAForest)
	--ensure the space we just formed is not in the boarding list - it will be in the group list
	forestGroup.boardering[forestUtils:getSpaceHash(p2)] = nil
	
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
	
	
	----- for pushing target -----
	
	--evaluate if we are pushing a fire unit onto a space we are floraforming because otherwise
	--we will put out the enemy
	if self.PushTarget then
		local pawn = Board:GetPawn(p2)
		
		if pawn and pawn:IsFire() and not ret.effect:empty() then
			for _, spaceDamage in pairs(extract_table(ret.effect)) do	
				if spaceDamage.loc == p2 + DIR_VECTORS[pushDir] then
					spaceDamage.iFire = EFFECT_NONE
				end
			end
		end
	end
	
	
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