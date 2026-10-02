MoonStriders_ColossusHook = Skill:new{  
	Name = "Colossus Hook",
	Description = "Punch a tile up to two away, damaging and pulling it.", 
	Class = "Prime",
	Icon = "weapons/prime_colossus.png",
	Rarity = 3,
	Explosion = "",
	LaunchSound = "/weapons/titan_fist",
	MinRange = 1, 
	PathSize = 2,
	Damage = 2,
	PushBack = false,
	Flip = false,
	Dash = false,
	Shield = false,
	Projectile = false,
	Push = 1,
	PowerCost = 0, --AE Change
	Upgrades = 2,
	--UpgradeList = { "Dash",  "+2 Damage"  },
	UpgradeCost = { 1 , 3 },
	TipImage = {
		Unit = Point(2,4),
		Enemy = Point(2,2),
		Target = Point(2,2)
	}
}	
			
Weapon_Texts.MoonStriders_ColossusHook_Upgrade1 = "Lasso"
MoonStriders_ColossusHook_A = MoonStriders_ColossusHook:new{
	UpgradeDescription = "Pull target any distance before hitting and pulling the target. Will pull over water and holes.",
	PathSize = INT_MAX, 
	Dash = true,
	ZoneTargeting = ZONE_DIR,
	TipImage = {
		Unit = Point(2,4),
		Enemy = Point(2,1),
		Target = Point(2,1)
	}
}

Weapon_Texts.MoonStriders_ColossusHook_Upgrade2 = "+2 Damage"
MoonStriders_ColossusHook_B = MoonStriders_ColossusHook:new{	
	UpgradeDescription = "Increases damage by 2.",
	Damage = 4, 
}

MoonStriders_ColossusHook_AB = MoonStriders_ColossusHook:new{
	PathSize = INT_MAX, 
	Dash = true,
	ZoneTargeting = ZONE_DIR,
	Damage = 4,
	TipImage = MoonStriders_ColossusHook_A.TipImage
}

function MoonStriders_ColossusHook:GetTargetArea(point)
	local ret = PointList()
	
	for dir = DIR_START, DIR_END do
		local done = false
		for i = self.MinRange, self.PathSize do
			local curr = Point(point + DIR_VECTORS[dir] * i)
			if not Board:IsValid(curr) then
				break
			end
			
			ret:push_back(curr)
			
			if Board:GetTerrain(curr) == TERRAIN_BUILDING or Board:GetTerrain(curr) == TERRAIN_MOUNTAIN or Board:GetPawn(curr) then
				break
			end
		end
	end
	
	return ret
end
	
function MoonStriders_ColossusHook:GetSkillEffect(p1, p2)
	local ret = SkillEffect()
	local direction = GetDirection(p2 - p1)

	local doDamage = true
	local target = GetProjectileEnd(p1,p2,PATH_PROJECTILE)
	local push_damage = self.Flip and DIR_FLIP or (direction + 2) % 4
    
	if self.Shield then
		local shield = SpaceDamage(p1,0)
		shield.iShield = EFFECT_CREATE
		ret:AddDamage(shield)
	end
	
    if self.Dash and p1:Manhattan(p2) > 2 then
		target = p1 + (DIR_VECTORS[direction] * 2)
    	ret:AddCharge(Board:GetSimplePath(p2, target), FULL_DELAY)
	else
		target = p2
	end

	local damage = SpaceDamage(target, self.Damage, push_damage)
	damage.sAnimation = "explopunch1_"..direction
	if self.Flip then damage.sAnimation = "SwipeClaw2" end  -- Change the animation if it's a flip
	
	if doDamage then
		damage.loc = target
		local origin = p1
		if p1:Manhattan(p2) ~= 1 then
			origin = p2 - (DIR_VECTORS[direction] * 2)
		end
		ret:AddMelee(origin, damage)
	end
	
	if self.PushBack then
		ret:AddDamage(SpaceDamage(p1, 0, GetDirection(p1 - p2)))
	end
	return ret
end	