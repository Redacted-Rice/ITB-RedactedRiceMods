StarWars_Stomp = Skill:new{
	Name = "Stomp",
	Description = "Cracks all adjacent tiles, dealing 1 damage and reducing terrain stability.",
	Class = "Brute",
	Damage = 1,
	PowerCost = 0,
	Upgrades = 2,
	UpgradeCost = {2, 1},
	Icon = "weapons/brute_sw_stomp.png",
	LaunchSound = "/impact/generic/mech",
	ImpactSound = "/impact/generic/explosion",
	TipImage = {
		Unit = Point(2, 2),
		Enemy = Point(2, 1),
		Enemy2 = Point(3, 2),
		Target = Point(2, 2),
	},
	Crack = false
}

Weapon_Texts.StarWars_Stomp_Upgrade1 = "+ Damage"
Weapon_Texts.StarWars_Stomp_A_UpgradeDescription = "+1 damage"
StarWars_Stomp_A = StarWars_Stomp:new{
	Damage = 2,
}

Weapon_Texts.StarWars_Stomp_Upgrade2 = "Heavy Stomp"
Weapon_Texts.StarWars_Stomp_B_UpgradeDescription = "Cracks adjacent tiles"
StarWars_Stomp_B = StarWars_Stomp:new{
	Crack = true,
}

StarWars_Stomp_AB = StarWars_Stomp_A:new{
	Crack = true,
}

function StarWars_Stomp:GetTargetArea(point)
	local ret = PointList()
	ret:push_back(point)
	for dir = DIR_START, DIR_END do
		local target = point + DIR_VECTORS[dir]
		if Board:IsValid(target) then
			ret:push_back(target)
		end
	end
	return ret
end

function StarWars_Stomp:GetSkillEffect(p1, p2)
	local ret = SkillEffect()

	ret:AddBounce(p1, 3)
	ret:AddDelay(0.1)

	-- Damage and crack all adjacent tiles
	for dir = DIR_START, DIR_END do
		local target = p1 + DIR_VECTORS[dir]
		if Board:IsValid(target) then
			local damage = SpaceDamage(target, self.Damage)
			damage.sAnimation = "ExploAir1"

			-- Crack the tile
			-- TODO Also not liquid tile
			if self.Crack and not Board:IsTerrain(target, TERRAIN_HOLE) then
				damage.iCrack = EFFECT_CREATE
			end

			ret:AddDamage(damage)
			ret:AddBounce(target, -1)
		end
	end
	return ret
end
