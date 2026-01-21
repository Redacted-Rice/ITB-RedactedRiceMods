Treeherders_ViolentGrowth = Skill:new
{
	Name = "Violent Growth",
    Class = "Science",
    Description = "If targetting an unforested tile, grows a forest tile causing damage. Otherwise cancels target's attack. Repeat on a second tile in or next to the targeted forest. Does not start fires.",
	Icon = "weapons/science_th_violentGrowth.png",
	Rarity = 1,

	Explosion = "",
	--TODO sounds
--	LaunchSound = "/weapons/titan_fist",
--	ImpactSound = "/impact/generic/tractor_beam",

	Range = 1,
	PathSize = 1,
    Damage = 1,

    PowerCost = 1,
    Upgrades = 2,
    UpgradeCost = { 1, 2 },

	TwoClick = true,

	-- custom options
	ForestDamageBounce = -2,
	NonForestBounce = 2,
	ForestGenBounce = forestUtils.floraformBounce,

	ForestToExpand = 0,
	SlowEnemy = false,
	SlowEnemyAmount = 2,
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
	UpgradeDescription = "For one turn all vek in the targeted forest lose two movement (minimum of 1)",
	SlowEnemy = true,
}

Weapon_Texts.Treeherders_ViolentGrowth_Upgrade2 = "+2 Expansion"
Treeherders_ViolentGrowth_B = Treeherders_ViolentGrowth:new
{
	UpgradeDescription = "Expand the targeted forest two extra tiles near primary target",
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
		if p ~= p2 then
			ret:push_back(p)
		end
	end
	for _, p in pairs(forestGroup.boardering) do
		if p ~= p2 then
			ret:push_back(p)
		end
	end

	return ret
end

function Treeherders_ViolentGrowth:AddPrimarySkillEffect(skillFx, p2)
	--if it is a forest, cancel the target's attack
	if forestUtils.isAForest(p2) then
		local spaceDamage = forestUtils:getSpaceDamageWithoutSettingFire(p2, self.Damage, pushDir, true, true)
		spaceDamage.sSound = "impact/generic/control"
		skillFx:AddDamage(spaceDamage)
		forestUtils:addCancelEffect(p2, skillFx)
		skillFx:AddBounce(p2, self.NonForestBounce)

	--if it can be floraformed, do so
	elseif forestUtils.isSpaceFloraformable(p2) then
		forestUtils:floraformSpace(skillFx, p2, self.Damage, pushDir, false, true)

	--otherwise just damage it
	else
		local spaceDamage = SpaceDamage(p2, self.Damage)
		spaceDamage.sSound = "mech/distance/skill/rangedcrack"
		skillFx:AddDamage(spaceDamage)
		skillFx:AddBounce(p2, self.NonForestBounce)
	end
end


function Treeherders_ViolentGrowth:GetSkillEffect(p1, p2)
	local ret = SkillEffect()
	self:AddPrimarySkillEffect(ret, p2)
	return ret
end

function Treeherders_ViolentGrowth:GetFinalEffect(p1,p2,p3)
	local ret = SkillEffect()

	-- start with the primary effect
	self:AddPrimarySkillEffect(ret, p2)

	--small break to make the animation and move make more sense
	ret:AddDelay(0.4)

	-- Player now selects second tile & we repeat
	-- Repeat on the second target
	self:AddPrimarySkillEffect(ret, p3)

	--small break to make the animation and move make more sense
	ret:AddDelay(0.4)

	----- For expansion ------

	local expansionFocus = p2

	--Get all spaces in the grouping
	local forestPoints = {}
	forestPoints[forestUtils:getSpaceHash(p2)] = p2
	forestPoints[forestUtils:getSpaceHash(p3)] = p3
	local forestGroup = forestUtils:getGroupingOfSpacesMultiple(forestPoints, forestUtils.isAForest)

	--ensure the space we just formed is not in the boarding list - it will be in the group list
	forestGroup.boardering[forestUtils:getSpaceHash(p2)] = nil
	forestGroup.boardering[forestUtils:getSpaceHash(p3)] = nil

	for i = 1, self.ForestToExpand do
		if forestUtils.arrayLength(forestGroup.boardering) > 0 then
			--get the nearest point, and remove it from the candidates
			local expansion = nil
			while expansion == nil and forestUtils.arrayLength(forestGroup.boardering) > 0 do
				expansion = forestUtils:getClosestOfSpaces(expansionFocus, forestGroup.boardering)
				forestGroup.boardering[forestUtils:getSpaceHash(expansion)] = nil
				if not forestUtils.isSpaceFloraformable(expansion) then
					expansion = nil
				end
			end

			--floraform it (if we found one)
			if expansion ~= nil then
				forestUtils:floraformSpace(ret, expansion, self.Damage, nil, true, true)
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