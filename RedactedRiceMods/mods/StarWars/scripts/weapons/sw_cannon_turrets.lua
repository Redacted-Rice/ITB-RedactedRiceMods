StarWars_CannonTurrets = TankDefault:new{
	Name = "Cannon Turrets",
	Description = "",
	Class = "Science",
	Damage = 1,
	PowerCost = 1,
	Upgrades = 2,
	UpgradeCost = {2,2},
	
	Icon = "weapons/brute_tankmech.png",
	Explosion = "",
	UpShot = "effects/shotup_missileswarm.png",
	FireSound = "/weapons/ricochet",
	ImpactSound = "/impact/generic/ricochet",
	-- seems to  be the value that gets them pretty flat in all cases
	ArtilleryHeight = -5, 
	Range = 2,
	SpecialTargets = false,
	
    TipImage = {
		Unit = Point(2,2),
		Enemy = Point(2,1),
		Enemy2 = Point(1,1),
		Enemy3 = Point(2,3),
		Enemy4 = Point(1,0),
		Building = Point(1,2),
		Target = Point(2,1),
		Second_Click = Point(1,2),
	},
}
			
Weapon_Texts.StarWars_CannonTurrets_Upgrade1 = "+1 Range"
StarWars_CannonTurrets_A = StarWars_CannonTurrets:new{
	UpgradeDescription = "",
	Range = 3
}

Weapon_Texts.StarWars_CannonTurrets_Upgrade2 = "Focus Fire"
StarWars_CannonTurrets_B = StarWars_CannonTurrets:new{
	UpgradeDescription = "",
	TwoClick = true,
}

StarWars_CannonTurrets_AB = StarWars_CannonTurrets_B:new{
	Range = 3
}

function StarWars_CannonTurrets:MakeTargetArea(p1, p2)
	local pointList = PointList()
	for _, p in pairs(extract_table(general_DiamondTarget(p1, self.Range))) do
		if p ~= p1 and p ~= p2 then
			pointList:push_back(p)
		end
	end
	return pointList
end

function StarWars_CannonTurrets:GetTargetArea(p1)
	return self:MakeTargetArea(p1)
end

function StarWars_CannonTurrets:GetSecondTargetArea(p1, p2)
	return self:MakeTargetArea(p1, p2)
end

function StarWars_CannonTurrets:MakeSkillEffect(p1, p2, p3)
	local ret = SkillEffect()
	local targets = self:GetTargetArea(p1)
	
	local extraHitDone = false
	for _, p in ipairs(extract_table(targets)) do
		if p ~= p3 and Board:IsValid(p) and Board:GetPawn(p) and Board:GetPawn(p):IsEnemy() then
			if self.TwoClick and p == p2 then
				local sd = SpaceDamage(p, self.Damage * 2)
				sd.bHidePath = true
				--sd.sAnimation = self.Explo..backdir
				ret:AddSound(self.FireSound)
				ret:AddArtillery(sd, self.UpShot, 0.1)
				ret:AddSound(self.FireSound)
				local sd2 = SpaceDamage(p)
				sd2.bHidePath = true
				ret:AddArtillery(sd2, self.UpShot, 0.1)
				extraHitDone = true
			else
				local sd = SpaceDamage(p, self.Damage)
				sd.bHidePath = true
				--sd.sAnimation = self.Explo..backdir
				ret:AddSound(self.FireSound)
				ret:AddArtillery(sd, self.UpShot, 0.1)
			end
		end
	end
	if self.TwoClick and not extraHitDone then
		local sd = SpaceDamage(p2, self.Damage)
				sd.bHidePath = true
		--sd.sAnimation = self.Explo..backdir
		ret:AddSound(self.FireSound)
		ret:AddArtillery(sd, self.UpShot, 0.1)
	end
	return ret
end

function StarWars_CannonTurrets:GetSkillEffect(p1,p2)
	return self:MakeSkillEffect(p1,p2)
end

function StarWars_CannonTurrets:GetFinalEffect(p1,p2,p3)
	return self:MakeSkillEffect(p1,p2,p3)
end