StarWars_ProtonTorpedo = TankDefault:new{
	Name = "Proton Torpedos",
	Description = "Fires a pair of proton torpedos exploding and doing damage in a plus-shaped area",
	Class = "Brute",
	Damage = 4,
	PowerCost = 1,
	Upgrades = 1,
	UpgradeCost = {2},
	Limited = 1,

	Icon = "weapons/brute_sw_proton_torpedo.png",
	Explosion = "explo_fire1",
	ProjectileArt = "effects/shot_sw_proton_torp",
	LaunchSound = "/weapons/unstable_cannon",
	ImpactSound = "/impact/generic/explosion_large",

	SplashDamage = 2,

	TipImage = StandardTips.Ranged,
	ZoneTargeting = ZONE_DIR,

	TipImage = {
		CustomPawn = "StarWars_XWingMech",
		Unit = Point(2,3),
		Enemy = Point(2,1),
		Enemy2 = Point(1,1),
		Target = Point(2,1),
	}
}

Weapon_Texts.StarWars_ProtonTorpedo_Upgrade1 = "+1 Use"
StarWars_ProtonTorpedo_A = StarWars_ProtonTorpedo:new{
	UpgradeDescription = "Add a second pair of proton torpedos",
	Limited = 2,
}

function StarWars_ProtonTorpedo:GetSkillEffect(p1, p2)
	local ret = SkillEffect()

	ret:AddProjectile(SpaceDamage(p2, self.Damage), self.ProjectileArt)
	ret:AddBounce(p2, self.Damage)

	-- Spash Damage
	for dir = DIR_START, DIR_END do
		local targetSpace = p2 + DIR_VECTORS[dir]
		if Board:IsValid(targetSpace) then
			ret:AddDamage(SpaceDamage(targetSpace, self.SplashDamage))
			ret:AddBounce(targetSpace, self.SplashDamage)
		end
	end
	return ret
end