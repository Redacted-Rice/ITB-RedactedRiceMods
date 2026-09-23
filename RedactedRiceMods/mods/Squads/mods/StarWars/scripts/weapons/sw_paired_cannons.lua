StarWars_PairedCannons = TankDefault:new{
	Name = "Paired Cannons",
	Description = "Fires two laser cannons at once, damaging and pushing the target",
	Class = "Brute",
	Damage = 1,
	PowerCost = 0,
	Upgrades = 2,
	UpgradeCost = {1,1},

	ExtraHitSpaces = 0,
	Push = true,

	Icon = "weapons/brute_sw_paired_cannons.png",
	Explosion = "",
	ProjectileArt = "effects/shot_sw_dual_red",
	LaunchSound = "/weapons/ricochet",
	ImpactSound = "/impact/generic/ricochet",

    TipImage = {
		CustomPawn = "StarWars_SnowSpeederMech",
		Unit = Point(3,3),
		Enemy = Point(3,2),
		Enemy2 = Point(3,1),
		Building = Point(1,2),
		Target = Point(3,2),
	},
}

Weapon_Texts.StarWars_PairedCannons_Upgrade1 = "+1 Space"
StarWars_PairedCannons_A = StarWars_PairedCannons:new{
	UpgradeDescription = "Damages and pushes an additional space behind the target",
	ExtraHitSpaces = 1,
}

Weapon_Texts.StarWars_PairedCannons_Upgrade2 = "+1 Space"
StarWars_PairedCannons_B = StarWars_PairedCannons:new{
	UpgradeDescription = "Damages and pushes an additional space behind the target",
	ExtraHitSpaces = 1,
}

StarWars_PairedCannons_AB = StarWars_PairedCannons_A:new{
	ExtraHitSpaces = 2,
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
	for i = 1, self.ExtraHitSpaces do 
		-- Start from furthest back and go forward
		local pBehind = p2 + DIR_VECTORS[attackDir] * (self.ExtraHitSpaces + 1 - i)
		if Board:IsValid(pBehind) then
			ret:AddProjectile(self:MakeSpaceDamage(pBehind, attackDir), self.ProjectileArt, NO_DELAY)
			ret:AddDelay(0.2)
		end
	end
	ret:AddProjectile(self:MakeSpaceDamage(p2, attackDir), self.ProjectileArt)
	return ret
end