MoonStriders_ApolloMortar = ArtilleryDefault:new{
	Name = "Apollo Mortar",
	Description = "Powerful artillery strike, damaging a single tile and pulling adjacent tiles. If multiple pawns are targetted, the first in attack order will be pulled in.", 
	Class = "Ranged",
	Icon = "weapons/ranged_mortar.png",
	Rarity = 3,
	UpShot = "effects/shotup_tribomb_missile.png",
	ArtilleryStart = 2,
	ArtillerySize = 8,
	BuildingDamage = true,
	Push = 1,
	ShieldBuildings = false,
	DamageOuter = 0,
	DamageCenter = 1,
	PowerCost = 0, --AE Change
	Damage = 1,---USED FOR TOOLTIPS
	BounceAmount = 1,
	Explosion = "",
	ExplosionCenter = "ExploArt1",
	ExplosionOuter = "",
	Upgrades = 2,
	UpgradeCost = {2,3},
	--UpgradeList = { "+1 Damage", "+1 Damage"  },
	LaunchSound = "/weapons/artillery_volley",
	ImpactSound = "/impact/generic/explosion",
	TipImage = {
		Unit = Point(2,4),
		Enemy = Point(2,2),
		Enemy2 = Point(3,2),
		Enemy3 = Point(2,1),
		Target = Point(2,2),
		Mountain = Point(2,3)
	}
}
		
Weapon_Texts.MoonStriders_ApolloMortar_Upgrade1 = "Shield Buildings"
MoonStriders_ApolloMortar_A = MoonStriders_ApolloMortar:new{
	UpgradeDescription = "This attack will shield Grid Buildings (both primary target and adjacent spaces)",
	--DamageCenter = 2,
	--Damage = 2,---USED FOR TOOLTIPS
	ShieldBuildings = true,
	ExplosionCenter = "ExploArt2",
	BounceAmount = 2.5,
	BuildingDamage = false,
	TipImage = {
		Unit = Point(2,4),
		Building = Point(2,2),
		Enemy2 = Point(3,2),
		Enemy3 = Point(2,1),
		Target = Point(2,2),
		Mountain = Point(2,3)
	}
}
	
Weapon_Texts.MoonStriders_ApolloMortar_Upgrade2 = "+2 Damage"
MoonStriders_ApolloMortar_B = MoonStriders_ApolloMortar:new{
	UpgradeDescription = "Increases damage by 2.",
	DamageCenter = 3,
	Damage = 3,---USED FOR TOOLTIPS
	ExplosionCenter = "ExploArt2",
	BounceAmount = 3,
}
			
MoonStriders_ApolloMortar_AB = MoonStriders_ApolloMortar:new{
		DamageCenter = 3,
		Damage = 3,---USED FOR TOOLTIPS
		ExplosionCenter = "ExploArt3",
		BuildingDamage = false,
		BounceAmount = 3,
	}			

-- DefaultArtillery overrident to pull instead of push
function MoonStriders_ApolloMortar:GetSkillEffect(p1, p2)	
	local ret = SkillEffect()
	local direction = GetDirection(p2 - p1)
	
	local sDamage = (self.ShieldBuildings and Board:GetTerrain(p2) == TERRAIN_BUILDING and 0) or self.DamageCenter
	local damage = SpaceDamage(p2, sDamage)
	damage.sAnimation = self.ExplosionCenter
	if self.ShieldBuildings and Board:GetTerrain(p2) == TERRAIN_BUILDING then damage.iShield = EFFECT_CREATE end
	
	if not self.BuildingDamage and Board:IsBuilding(p2) then		-- Target Buildings - 
		damage.iDamage = DAMAGE_ZERO
	end
	
	ret:AddBounce(p1, 1)
	ret:AddArtillery(damage, self.UpShot)
	
	if self.BounceAmount ~= 0 then	ret:AddBounce(p2, self.BounceAmount) end
	
	-- far, left, right, close
	local hasFoundPawn = Board:GetPawn(p2) ~= nil
	for _, relDir in ipairs({0,1,3,2}) do
		local dir = (direction + relDir) % 4
		local space = p2 + DIR_VECTORS[dir]
		damage = SpaceDamage(space,  self.DamageOuter)
		if self.ShieldBuildings and Board:GetTerrain(p2 + DIR_VECTORS[dir]) == TERRAIN_BUILDING then damage.iShield = EFFECT_CREATE end
		
		if self.Push == 1 then
			damage.iPush = (dir + 2) % 4
		end
		damage.sAnimation = self.OuterAnimation..dir
		
		if not self.BuildingDamage and Board:IsBuilding(p2 + DIR_VECTORS[dir]) then	
			damage.iDamage = 0
			damage.sAnimation = "airpush_"..dir
		end
		-- See if we need to add in delay
		if Board:GetPawn(space) ~= nil and not Board:GetPawn(space):IsGuarding() then
			if hasFoundPawn then
				ret:AddDelay(1.25)
			end
			hasFoundPawn = true
		end
		damage.fDelay = 0.05
		
		ret:AddDamage(damage)
		if self.BounceOuterAmount ~= 0 then	ret:AddBounce(p2 + DIR_VECTORS[dir], self.BounceOuterAmount) end  
	end

	return ret
end		