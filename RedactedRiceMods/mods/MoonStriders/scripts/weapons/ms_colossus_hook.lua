MoonStriders_ColossusHook = Skill:new{  
	Class = "Prime",
	Icon = "weapons/prime_colossus.png",
	Rarity = 3,
	Explosion = "",
	LaunchSound = "/weapons/titan_fist",
	MinRange = 2, 
	PathSize = 1,
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
	UpgradeCost = { 2 , 3 },
	TipImage = StandardTips.Melee
}		
			
MoonStriders_ColossusHook_A = MoonStriders_ColossusHook:new{
	PathSize = INT_MAX, 
	Dash = true,
	ZoneTargeting = ZONE_DIR,
	TipImage = {
		Unit = Point(2,4),
		Enemy = Point(2,1),
		Target = Point(2,1)
	}
}

MoonStriders_ColossusHook_B = MoonStriders_ColossusHook:new{	
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
			
			if Board:IsBlocked(curr,PATH_GROUND) then
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
	local push_damage = self.Flip and DIR_FLIP or direction
	local damage = SpaceDamage(target, self.Damage, push_damage)
	damage.sAnimation = "explopunch1_"..direction
	if self.Flip then damage.sAnimation = "SwipeClaw2" end  -- Change the animation if it's a flip
    
	if self.Shield then
		local shield = SpaceDamage(p1,0)
		shield.iShield = EFFECT_CREATE
		ret:AddDamage(shield)
	end
	
    if self.Dash then
       
        if not Board:IsBlocked(target,PATH_PROJECTILE) then -- dont attack an empty edge square, just run to the edge
	    	doDamage = false
		    target = target + DIR_VECTORS[direction]
    	end
    	
    	ret:AddCharge(Board:GetSimplePath(p1, target - (DIR_VECTORS[direction] * 2)), FULL_DELAY)
    elseif self.Projectile and target:Manhattan(p1) ~= 1 then
		damage.loc = target
		ret:AddDamage(SpaceDamage(p1,0,(direction+2)%4))
		ret:AddProjectile(damage, "effects/shot_fist")
		doDamage = false--damage covered here
	else
		target = p2
	end

	
	if doDamage then
		damage.loc = target
		ret:AddMelee(p2 - DIR_VECTORS[direction], damage)
	end
	
	if self.PushBack then
		ret:AddDamage(SpaceDamage(p1, 0, GetDirection(p1 - p2)))
	end
	return ret
end	