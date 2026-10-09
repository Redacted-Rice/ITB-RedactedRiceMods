MoonStriders_ScorpioFalconet = TankDefault:new	{
	Name = "Scorpio Falconet",
	Description = "Fires a powerful projectile that damages and pulls its target.", 
	Class = "Brute",
	Damage = 1,
	Icon = "weapons/brute_falconet.png",
	Explosion = "",
	Sound = "/general/combat/explode_small",
	Damage = 1,
	Push = 1,
	PowerCost = 0, --AE Change
	Upgrades = 2,
	UpgradeCost = {2,2},
	LaunchSound = "/weapons/modified_cannons",
	ImpactSound = "/impact/generic/explosion",
	TipImage = StandardTips.Ranged,
	ZoneTargeting = ZONE_DIR,
}

Weapon_Texts.MoonStriders_ScorpioFalconet_Upgrade1 = "+1 Damage"
MoonStriders_ScorpioFalconet_A = MoonStriders_ScorpioFalconet:new{
	UpgradeDescription = "Increases damage by 1.",
	Damage = 2,
}

Weapon_Texts.MoonStriders_ScorpioFalconet_Upgrade2 = "+1 Damage"
MoonStriders_ScorpioFalconet_B = MoonStriders_ScorpioFalconet:new{
	UpgradeDescription = "Increases damage by 1.",
	Damage = 2,
}

MoonStriders_ScorpioFalconet_AB = MoonStriders_ScorpioFalconet:new{
	UpgradeDescription = "Increases damage by 1.",
	Damage = 3,
	Explo = "explopush2_",
}

--
function MoonStriders_ScorpioFalconet:GetSkillEffect(p1,p2)
	local ret = SkillEffect()
	local direction = GetDirection(p2 - p1)

	if self.PushBack == 1 then
		local selfDam = SpaceDamage(p1, self.SelfDamage, GetDirection(p1 - p2))
		ret:AddDamage(selfDam)
	end

	local pathing = self.Phase and PATH_PHASING or PATH_PROJECTILE
	local target = GetProjectileEnd(p1,p2,pathing)  
	
	local damage = SpaceDamage(target, self.Damage)
	if self.Flip == 1 then
		damage = SpaceDamage(target,self.Damage,DIR_FLIP)
	end
	if self.Push == 1 then
		damage.iPush = (direction - 2)%4
	end
	damage.iAcid = self.Acid
	damage.iFrozen = self.Freeze
	damage.iFire = self.Fire
	damage.iShield = self.Shield
	damage.sAnimation = self.Explo..direction
	
	if self.Phase and Board:IsBuilding(target) then
		damage.sAnimation = ""
		damage.iDamage = 0
	end
	
	ret:AddProjectile(damage, self.ProjectileArt, NO_DELAY)--"effects/shot_mechtank")
		
	if self.BackShot == 1 then
		local backdir = GetDirection(p1 - p2)
		local target2 = GetProjectileEnd(p1,p1 + DIR_VECTORS[backdir])

		if target2 ~= p1 then
			damage = SpaceDamage(target2, self.Damage, backdir)
			damage.sAnimation = self.Explo..backdir
			ret:AddProjectile(damage,self.ProjectileArt)
		end
	end
	
	if self.PhaseShield then
		local temp = p1 + DIR_VECTORS[direction]
		while true do
			if Board:IsBuilding(temp) then
				damage = SpaceDamage(temp, 0)
				damage.iShield = 1
				ret:AddDamage(damage)
			end
		
			if temp == target then
				break
			end
			
			temp = temp + DIR_VECTORS[direction]
		end
	end
	
	return ret
end
