local PASS_DELAY = 0.06
StarWars_AuxiliarySuperlaser = Skill:new{
	Name = "Aux. Superlaser",
	Description = "Instakills center tile and turns it to lava. Deals 3 damage adjacent, 1 damage beyond. Recharged by repair.",
	Class = "Science",
	PowerCost = 2,
	Upgrades = 2,
	UpgradeCost = {3, 2},
	Orbital = true,
	Limited = 1,
	SplashDamage = 3,
	SplashFurtherDamage = 1,
	ShakeBaseVal = 0.4,
	BounceBaseVal = 30,
	BounceDecay = 0.80,
	IntroFrames = 5,
	PassDelay = PASS_DELAY,
	TotalPasses = 16,
	Icon = "weapons/science_sw_auxiliary_laser.png",
	Explosion = "explo_fire1",
	LaunchSound = "/weapons/laser_burst",
	ImpactSound = "/impact/generic/explosion",
	Projectile = "effects/shot_sw_superlaser",
	TipImage = {
		Target = Point(2, 1),
		Enemy = Point(2, 1),
		Mountain = Point(2, 2),
	}
}

ANIMS.StarWars_AuxSuperlaser_Anim = Animation:new{
	Image = "effects/superlaser_core.png",
	NumFrames = 11,
	Loop = false,
	PosX = -40,
	PosY = -360,
	Lengths = {
		PASS_DELAY, PASS_DELAY, PASS_DELAY, PASS_DELAY, PASS_DELAY, 
		0.3, 
		PASS_DELAY, PASS_DELAY, PASS_DELAY, PASS_DELAY, PASS_DELAY},
}

local mod = mod_loader.mods[modApi.currentMod]

Weapon_Texts.StarWars_AuxiliarySuperlaser_Upgrade1 = "+1 Damage"
Weapon_Texts.StarWars_AuxiliarySuperlaser_A_UpgradeDescription = "+1 damage to all spaces"
StarWars_AuxiliarySuperlaser_A = StarWars_AuxiliarySuperlaser:new{
	SplashDamage = 4,
	SplashFurtherDamage = 2,
}

Weapon_Texts.StarWars_AuxiliarySuperlaser_Upgrade2 = "Extra Capacitors"
Weapon_Texts.StarWars_AuxiliarySuperlaser_B_UpgradeDescription = "Starts with two charges"
StarWars_AuxiliarySuperlaser_B = StarWars_AuxiliarySuperlaser:new{
	Limited = 2,
}

StarWars_AuxiliarySuperlaser_AB = StarWars_AuxiliarySuperlaser_A:new{
	Limited = 2,
}

function StarWars_AuxiliarySuperlaser:GetTargetArea(point)
	local ret = PointList()
	local size = Board:GetSize()
	for x = 0, size.x - 1 do
		for y = 0, size.y - 1 do
			ret:push_back(Point(x, y))
		end
	end
	return ret
end

local function getValidSpacesAtDistance(center, distance)
	local tiles = {}
	if distance == 0 then
		table.insert(tiles, center)
	else
		for x = -distance, distance do
			for y = -distance, distance do
				local space = center + Point(x, y)
				if Board:IsValid(space) and center:Manhattan(space) == distance then
					table.insert(tiles, space)
				end
			end
		end
	end
	return tiles
end

local function addCenterEffect(ret, center, damage)
	if damage and not Board:IsTerrain(center, TERRAIN_HOLE) then
		sd = SpaceDamage(center, damage)
		sd.iTerrain = TERRAIN_LAVA
		ret:AddDamage(sd)
	else
		ret:AddDamage(SpaceDamage(center))
	end
end

local function addExplosionEffects(ret, spaces, damage, isAdj)
	for _, space in ipairs(spaces) do
		if damage then
			local sd = SpaceDamage(space, damage)
			local terrain = Board:GetTerrain(space)
			if isAdj then
				if terrain ~= TERRAIN_ICE and terrain ~= TERRAIN_LAVA and terrain ~= TERRAIN_WATER and terrain ~= TERRAIN_HOLE then
					sd.iTerrain = TERRAIN_RUBBLE
					sd.sScript = [[Board:SetRubbleType(]]..space:GetString()..[[, RUBBLE_MOUNTAIN)]]
					sd.iFire = EFFECT_CREATE
				end
			end
			-- melt ice for funsies
			if Board:GetTerrain(space) == TERRAIN_ICE then
				sd.iTerrain = TERRAIN_WATER
			end
			ret:AddDamage(sd)
		else
			ret:AddDamage(SpaceDamage(space))
		end
	end
end

function StarWars_AuxiliarySuperlaser:GetSkillEffect(p1, p2)
	local ret = SkillEffect()
	local explosion = self.Explosion

	ret:AddScript([[
		Board:AddAnimation(]] .. p2:GetString() .. [[, "StarWars_AuxSuperlaser_Anim", 1)
	]])
	ret:AddDelay(self.IntroFrames * self.PassDelay)
	ret:AddBoardShake(self.ShakeBaseVal * self.SplashDamage)

	local bounce = self.BounceBaseVal

	local adjacentSpaces = getValidSpacesAtDistance(p2, 1)
	local furtherSpaces = getValidSpacesAtDistance(p2, 2)

	local CENTER = 1
	local ADJACENT = 2
	local FURTHER = 3
	local addDamageInPass = {1, 3, 5}
	local explosionsInPasses = {{1,3,5,7,9}, {3,5,7}, {5}}

	for pass = 1, self.TotalPasses do
		if list_contains(explosionsInPasses[CENTER], pass) then
			local damage = nil
			if pass == addDamageInPass[CENTER] then
				damage = DAMAGE_DEATH
			end
			addCenterEffect(ret, p2, damage)
		end
		if list_contains(explosionsInPasses[ADJACENT], pass) then
			local damage = nil
			if pass == addDamageInPass[ADJACENT] then
				damage = self.SplashDamage
			end
			addExplosionEffects(ret, adjacentSpaces, damage, true)
		end
		if list_contains(explosionsInPasses[FURTHER], pass) then
			local damage = nil
			if pass == addDamageInPass[FURTHER] then
				damage = self.SplashFurtherDamage
			end
			addExplosionEffects(ret, furtherSpaces, damage, false)
		end

		-- Add shockwave
		for _, space in ipairs(getValidSpacesAtDistance(p2, pass - 1)) do
			ret:AddBounce(space, bounce)
		end
		bounce = bounce * self.BounceDecay

		ret:AddDelay(self.PassDelay)
	end

	return ret
end
