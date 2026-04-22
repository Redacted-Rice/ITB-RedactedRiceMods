StarWars_PairedCannons = TankDefault:new{
	Name = "Paired Cannons",
	Description = "",
	Class = "Brute",
	Damage = 1,
	PowerCost = 0,
	Upgrades = 2,
	UpgradeCost = {1,1},
	
	HitBehind = false,
	Push = false,
	
	Icon = "weapons/brute_tankmech.png",
	Explosion = "",
	ProjectileArt = "effects/shot_sw_dual_red",
	LaunchSound = "/weapons/ricochet",
	ImpactSound = "/impact/generic/ricochet",
	
    TipImage = {
		Unit = Point(3,3),
		Enemy = Point(3,2),
		Enemy2 = Point(3,1),
		Building = Point(1,2),
		Target = Point(3,2),
	},
}

Weapon_Texts.StarWars_PairedCannons_Upgrade1 = "Hit Behind"
StarWars_PairedCannons_A = StarWars_PairedCannons:new{
	UpgradeDescription = "",
	HitBehind = true,
}

Weapon_Texts.StarWars_PairedCannons_Upgrade2 = "Push"
StarWars_PairedCannons_B = StarWars_PairedCannons:new{
	UpgradeDescription = "",
	Push = true,
}

StarWars_PairedCannons_AB = StarWars_PairedCannons_A:new{
	Push = true,
}

function StarWars_PairedCannons:MakeSpaceDamage(p, pushDir) 
	if self.Push then
		return SpaceDamage(p, self.Damage, pushDir)
	else
		return SpaceDamage(p, self.Damage)
	end
end

function StarWars_PairedCannons:GetSkillEffect(p1, p2)
	local ret = SkillEffect()
	
	local attackDir = GetDirection(p2 - p1)
	if self.HitBehind then
		local pBehind = p2 + DIR_VECTORS[attackDir]
		ret:AddProjectile(self:MakeSpaceDamage(pBehind, attackDir), self.ProjectileArt, NO_DELAY)
		ret:AddDelay(0.2)
	end
	ret:AddProjectile(self:MakeSpaceDamage(p2, attackDir), self.ProjectileArt)
	return ret
end