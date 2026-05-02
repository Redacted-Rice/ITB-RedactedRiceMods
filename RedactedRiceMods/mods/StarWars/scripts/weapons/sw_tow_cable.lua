StarWars_TowCable = TankDefault:new{
	Name = "Tow Cable",
	Description = "Fire a tow cable up to 2 spaces in a line to stop an enemy from moving.",
	Class = "Brute",
	Damage = 0,
	PowerCost = 0,
	Upgrades = 2,
	UpgradeCost = {2, 1},
	Icon = "weapons/brute_sw_tow_cable.png",
	PathSize = 2,
	SetFire = false,
	CancelAttack = false,
	Limited = 2,
	LaunchSound = "/weapons/grapple",
	ImpactSound = "/impact/generic/grapple",
	ProjectileArt = "effects/shot_tow_cable",
	TipImage = {
		CustomPawn = "StarWars_SnowSpeederMech",
		Unit = Point(2,3),
		Enemy = Point(2,1),
		Target = Point(2,1),
	}
}

-- Weapon text definitions
Weapon_Texts.StarWars_TowCable_Upgrade1 = "+Fire"
Weapon_Texts.StarWars_TowCable_A_UpgradeDescription = "Sets the target space on fire."
StarWars_TowCable_A = StarWars_TowCable:new{
	SetFire = true,
}

Weapon_Texts.StarWars_TowCable_Upgrade2 = "Cancel Attack"
Weapon_Texts.StarWars_TowCable_B_UpgradeDescription = "Cancels target's attack"
StarWars_TowCable_B = StarWars_TowCable:new{
	CancelAttack = true,
}

StarWars_TowCable_AB = StarWars_TowCable_A:new{
	CancelAttack = true,
}

-- Uses base TankDefault targetting

function StarWars_TowCable:GetSkillEffect(p1, p2)
	local ret = SkillEffect()

	-- bHidePath seems odd but its how its done in vanilla grapple
	local projectileDamage = SpaceDamage(p2, self.Damage)
	projectileDamage.bHidePath = true

	-- Set fire if upgraded
	if self.SetFire then
		projectileDamage.iFire = EFFECT_CREATE
	end
	
	-- Set speed to 0
	if Board:IsPawnSpace(p2) then
		projectileDamage.sScript = projectileDamage.sScript .. [[
				local pawn = Board:GetPawn(]].. p2:GetString() ..[[)
					Board:Ping(pawn:GetSpace(), GL_Color(255, 0, 0))
					pawn:SetMoveSpeed(0)
				]]
	end
	ret:AddProjectile(projectileDamage, self.ProjectileArt)
	
	if self.CancelAttack then
		BoardUtils.addCancelEffect(p2, ret)
	end
	
	-- TODO: Probably need to reapply fire
	return ret
end
