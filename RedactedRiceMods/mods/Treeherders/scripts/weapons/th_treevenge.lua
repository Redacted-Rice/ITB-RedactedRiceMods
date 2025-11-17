Treeherders_Treevenge = Skill:new
{
	Name = "Tree-venge",
	Class = "Prime",
	Description = "Smash an adjacent tile pushing surrounding tiles and damaging them by half. Target damage increases by forest fires / 2 (rounded up) to a max of 5",
	Icon = "weapons/prime_th_treevenge.png",
	Rarity = 2,
	
	Explosion = "",
	LaunchSound = "/weapons/titan_fist",
	
	Range = 1,
	PathSize = 1,
	Projectile = false,
    Damage = 1,
    PowerCost = 1,
    Upgrades = 2,
    UpgradeCost = { 1, 2 },
	
	--custom
	BouncePerDamage = 2,
	ShakePerDamage = 0.1,
	DoesSplashDamage = true,
	GenForestTarget = false,
	ForestsPerDamage = 2,
	DamageCap = 5,
	BuildingImmune = false,
	
    TipImage = {
		Unit = Point(2,3),
		Target = Point(2,2),
		Enemy = Point(2,2),
		Enemy2 = Point(2,1),
		Building = Point(3,2),
		Forest = Point(3,1),
		Fire = Point(3,1),
		Forest2 = Point(3,0),
		Fire2 = Point(3,0),
	},
}

Weapon_Texts.Treeherders_Treevenge_Upgrade1 = "Building Immune"
Treeherders_Treevenge_A = Treeherders_Treevenge:new
{
	UpgradeDescription = "Buildings do not take damage from this attack",
	BuildingImmune = true,
    TipImage = {
		Unit = Point(2,3),
		Target = Point(2,2),
		Enemy = Point(3,2),
		Enemy2 = Point(2,1),
		Building = Point(2,2),
		Forest = Point(3,1),
		Fire = Point(3,1),
		Forest2 = Point(3,0),
		Fire2 = Point(3,0),
	},
}

Weapon_Texts.Treeherders_Treevenge_Upgrade2 = "Short Tempered"
Treeherders_Treevenge_B = Treeherders_Treevenge:new
{
	UpgradeDescription = "Damage increases for every forest fire",
	ForestsPerDamage = 1,
}

Treeherders_Treevenge_AB = Treeherders_Treevenge_B:new
{
	BuildingImmune = true,
}

function Treeherders_Treevenge:GetSkillEffect(p1, p2)
	local ret = SkillEffect()
	
	--determine the damage
	local damage = self.Damage + math.ceil(forestUtils.arrayLength(forestUtils:getSpaces(forestUtils.isAForestFire)) / self.ForestsPerDamage)
	
	--cap it
	if damage > self.DamageCap then
		damage = self.DamageCap
	end
	
	--detemine the splash damage
	local splashDamage = 0
	if self.DoesSplashDamage then
		splashDamage = math.floor(damage / 2)
	end
	
	--do the main damage
	local currDamage = nil
	if self.GenForestTarget then
		currDamage = forestUtils:getFloraformSpaceDamage(p2, damage, nil, false, self.BuildingImmune)
	else
		currDamage = forestUtils:getSpaceDamageWithoutSettingFire(p2, damage, nil, false, self.BuildingImmune)
	end
	
	ret:AddDamage(currDamage)
	ret:AddBounce(p2, damage * self.BouncePerDamage)
	ret:AddBoardShake(damage * self.ShakePerDamage)
	ret:AddDelay(0.2)
	
	--do the splash damage
	local attackDir = GetDirection(p2 - p1)
	for i = -1, 1 do
		local splashPoint = p2 + DIR_VECTORS[(attackDir + i) % 4]
	
		--in case we have building immune
		local currDamage = splashDamage
	
		--for some reason this won't work if i put (attackDir + i) % 4 in a variable and try to use that
		local splash = forestUtils:getSpaceDamageWithoutSettingFire(splashPoint, currDamage, (attackDir + i) % 4, false, self.BuildingImmune)
		splash.sAnimation = "airpush_"..((attackDir + i) % 4)
		if splashDamage > 0 then
			ret:AddBounce(splashPoint, splashDamage * self.BouncePerDamage)
		else
			--So that it doesn't display on the tiles
			splash.iDamage = 0
		end
		ret:AddDamage(splash) 
	end
	
	return ret
end