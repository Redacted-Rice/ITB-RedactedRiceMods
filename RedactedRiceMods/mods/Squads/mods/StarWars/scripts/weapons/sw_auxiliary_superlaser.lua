local PASS_DELAY = 0.06

-- Outward shockwave (center -> board edge)
local PRIMARY_BOUNCE_BASE = 30

-- Inward ripple (edge -> center)
local SECONDARY_BOUNCE_BASE = -12

modApi:setText("StarWars_AuxiliarySuperlaser_Description", memhack.getTextWrappers.basedOnSelectedPawn(function(pawn)
	local hp = 10
	if pawn then
		hp = pawn:GetMaxHealth()
	end
	return "Instakills center tile and turns it to lava dealing splashdamage in a large area. Can be recharged by"
			.. " Priming Laser when equipped on Death Star. Splash damage scales with Mech's HP."
			.. " Adjacent splash damage is HP/3 (".. math.floor(hp / 3) .."), outer splash damage is HP/7 (".. math.floor(hp / 7) ..")"
end))

StarWars_AuxiliarySuperlaser = Skill:new{
	Name = "Aux. Superlaser",
	Class = "Science",
	PowerCost = 1,
	Upgrades = 2,
	UpgradeCost = {2, 2},
	Orbital = true,
	Limited = 1,
	SplashBonus = 0,
	ShakeBaseVal = 0.7,
	BounceBaseVal = 30,
	BounceDecay = 0.92,
	-- Some magic numbers to make it line up nicely with sfx
	ExplosionSfxDelay = PASS_DELAY * 35,
	SecondaryShockwaveSfxDelay = PASS_DELAY * 10,
	TertiaryShockwaveSfxDelay = PASS_DELAY * 12,
	IntroFrames = 6,
	PassDelay = PASS_DELAY,
	TotalPasses = 16,
	Icon = "weapons/science_sw_auxiliary_laser.png",
	Explosion = "explo_fire1",
	LaunchSound = "/weapons/raining_fire",
	MainImpactSound = "/props/final_bomb_explode",
	ImpactSounds = {"/impact/generic/explosion_large", "/impact/generic/explosion", "/weapons/localized_explosion"},
	Projectile = "effects/shot_sw_superlaser",
	TipImage = {
		Unit = Point(5, 5),
		Target = Point(2, 1),
		Enemy = Point(2, 1),
		Mountain = Point(2, 2),
	}
}

StarWars_AuxiliarySuperlaser.cachedPreviewRings = nil
StarWars_AuxiliarySuperlaser.cachedRings = {}
StarWars_AuxiliarySuperlaser.cachedSecondaryAndTertiaryShockwaves = {}
StarWars_AuxiliarySuperlaser.MAX_DISTANCE = 14

ANIMS.StarWars_AuxSuperlaser_Anim = Animation:new{
	Image = "effects/satellite_sw_aux_superlaser.png",
	NumFrames = 11,
	Loop = false,
	PosX = -40,
	PosY = -360,
	Lengths = {
		PASS_DELAY, PASS_DELAY, PASS_DELAY, PASS_DELAY, PASS_DELAY,
		PASS_DELAY * 5,
		PASS_DELAY, PASS_DELAY, PASS_DELAY, PASS_DELAY, PASS_DELAY},
}

local mod = mod_loader.mods[modApi.currentMod]

Weapon_Texts.StarWars_AuxiliarySuperlaser_Upgrade1 = "+1 Damage"
Weapon_Texts.StarWars_AuxiliarySuperlaser_A_UpgradeDescription = "+1 damage to all spaces"
StarWars_AuxiliarySuperlaser_A = StarWars_AuxiliarySuperlaser:new{
	SplashBonus = 1,
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

function StarWars_AuxiliarySuperlaser.calculateRings(center)
	local rings = {}
	for dist = 0, StarWars_AuxiliarySuperlaser.MAX_DISTANCE do
		rings[dist] = {}
	end

	local size = Board:GetSize()
	for x = 0, size.x - 1 do
		for y = 0, size.y - 1 do
			local space = Point(x, y)
			table.insert(rings[BoardUtils.getManhattanDistance(center, space)], space)
		end
	end
	return rings
end

function StarWars_AuxiliarySuperlaser.addShockwaveRing(ret, spaces, bounce)
	for _, space in ipairs(spaces) do
		ret:AddBounce(space, bounce)
	end
end

function StarWars_AuxiliarySuperlaser.addCenterEffect(ret, center, damage)
	if damage and not Board:IsTerrain(center, TERRAIN_HOLE) then
		local sd = SpaceDamage(center, damage)
		sd.iTerrain = TERRAIN_LAVA
		ret:AddDamage(sd)
	else
		ret:AddDamage(SpaceDamage(center))
	end
end

function StarWars_AuxiliarySuperlaser.addExplosionEffects(ret, spaces, damage, isAdj)
	for _, space in ipairs(spaces) do
		if damage then
			local sd = SpaceDamage(space, damage)
			local terrain = Board:GetTerrain(space)
			if isAdj then
				-- if its not liquid, ice or a hole, we likely will make it rubble
				if not BoardUtils.isLiquid(terrain) and terrain ~= TERRAIN_ICE and terrain ~= TERRAIN_HOLE then
					-- If its not a building, then make it mountain rubble. Either way make it have fire now
					if terrain ~= TERRAIN_BUILDING then
						sd.iTerrain = TERRAIN_RUBBLE
						sd.sScript = [[Board:SetRubbleType(]]..space:GetString()..[[, RUBBLE_MOUNTAIN)]]
					end
				end
				sd.iFire = EFFECT_CREATE
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

function StarWars_AuxiliarySuperlaser:getSuperlaserSplashDamages(pawn)
	local hp = pawn and pawn:GetMaxHealth() or 3
	local bonus = self.SplashBonus
	return math.floor(hp / 3) + bonus, math.floor(hp / 7) + bonus
end

function StarWars_AuxiliarySuperlaser:addSecondaryAndTertiaryShockwaves(ret, center)
	if Board:IsTipImage() then return end
	if not self.cachedSecondaryAndTertiaryShockwaves[center] then
		self.cachedSecondaryAndTertiaryShockwaves[center] = [[
			local ret = SkillEffect()
			local center = ]]..center:GetString()..[[	
			local rings = StarWars_AuxiliarySuperlaser.cachedRings[center:GetString()]
			local bounceDecay = StarWars_AuxiliarySuperlaser.BounceDecay
			ret:AddDelay(StarWars_AuxiliarySuperlaser.SecondaryShockwaveSfxDelay)
			ret:AddBoardShake(StarWars_AuxiliarySuperlaser.ShakeBaseVal)
			ret:AddDamage(SpaceDamage(center, 0))

			local secondaryBounce = ]]..SECONDARY_BOUNCE_BASE..[[	
			for ring = StarWars_AuxiliarySuperlaser.MAX_DISTANCE, 0, -1 do
				StarWars_AuxiliarySuperlaser.addShockwaveRing(ret, rings[ring], secondaryBounce)
				secondaryBounce = math.min(-1, secondaryBounce * bounceDecay)
				ret:AddDelay(StarWars_AuxiliarySuperlaser.PassDelay)
			end

			-- Let bounces finish before we start the next
			ret:AddDelay(StarWars_AuxiliarySuperlaser.TertiaryShockwaveSfxDelay)

			local tertiaryBounce = math.min(-1, secondaryBounce * bounceDecay)
			for ring = 0, StarWars_AuxiliarySuperlaser.MAX_DISTANCE do
				StarWars_AuxiliarySuperlaser.addShockwaveRing(ret, rings[ring], tertiaryBounce)
				tertiaryBounce = math.min(-1, tertiaryBounce * bounceDecay)
				ret:AddDelay(StarWars_AuxiliarySuperlaser.PassDelay)
			end

			-- Pause after for effect
			ret:AddDelay(StarWars_AuxiliarySuperlaser.IntroFrames * StarWars_AuxiliarySuperlaser.PassDelay)
			Board:AddEffect(ret)
		]]
	end
	ret:AddScript(self.cachedSecondaryAndTertiaryShockwaves[center])
end

function StarWars_AuxiliarySuperlaser:GetSkillEffect(p1, p2)
	local ret = SkillEffect()
	local pawn = Board:GetPawn(p1)
	local splashAdj, splashFar = self:getSuperlaserSplashDamages(pawn)

	-- Delay firing for effect
	ret:AddSound(self.LaunchSound)
	ret:AddSound(self.MainImpactSound)
	ret:AddDelay(self.ExplosionSfxDelay)

	ret:AddScript([[
		Board:AddAnimation(]] .. p2:GetString() .. [[, "StarWars_AuxSuperlaser_Anim", 1)
	]])
	ret:AddDelay(self.IntroFrames * self.PassDelay)
	ret:AddBoardShake(self.ShakeBaseVal * 2)

	-- compute the rings once and reuse them for optimization
	local rings = nil
	if Board:IsTipImage() then
		if not self.cachedPreviewRings then
			self.cachedPreviewRings = self.calculateRings(p2)
		end
		rings = self.cachedPreviewRings
	else
		if not self.cachedRings[p2:GetString()] then
			self.cachedRings[p2:GetString()] = self.calculateRings(p2)
		end
		rings = self.cachedRings[p2:GetString()]
	end

	local CENTER = 1
	local ADJACENT = 2
	local FURTHER = 3
	local addDamageInPass = {1, 3, 5}
	local explosionsInPasses = {{1,3,5,7,9}, {3,5,7}, {5}}
	local maxExplosionPass = 9

	local primaryBounce = PRIMARY_BOUNCE_BASE
	for pass = 1, StarWars_AuxiliarySuperlaser.MAX_DISTANCE + 1 do
		if pass <= maxExplosionPass and list_contains(explosionsInPasses[CENTER], pass) then
			local damage = nil
			if pass == addDamageInPass[CENTER] then
				damage = DAMAGE_DEATH
			end
			self.addCenterEffect(ret, p2, damage)
		end
		if pass <= maxExplosionPass and list_contains(explosionsInPasses[ADJACENT], pass) then
			local damage = nil
			if pass == addDamageInPass[ADJACENT] then
				damage = splashAdj
			end
			self.addExplosionEffects(ret, rings[1], damage, true)
		end
		if pass <= maxExplosionPass and list_contains(explosionsInPasses[FURTHER], pass) then
			local damage = nil
			if pass == addDamageInPass[FURTHER] then
				damage = splashFar
			end
			self.addExplosionEffects(ret, rings[2], damage, false)
		end

		self.addShockwaveRing(ret, rings[pass - 1], primaryBounce)
		primaryBounce = primaryBounce * self.BounceDecay
		
		if pass <= maxExplosionPass then
			ret:AddSound(self.ImpactSounds[math.random(1, #self.ImpactSounds)])
		end
		ret:AddDelay(self.PassDelay)
	end

	-- Game seems to cut off delays if we don't add this
	ret:AddDamage(SpaceDamage(p2, 0))

	self:addSecondaryAndTertiaryShockwaves(ret, p2)

	return ret
end
