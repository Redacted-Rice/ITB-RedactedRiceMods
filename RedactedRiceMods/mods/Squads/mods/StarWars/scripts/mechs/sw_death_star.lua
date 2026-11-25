local resourcePath = mod_loader.mods[modApi.currentMod].resourcePath
local mechPath = resourcePath .. "img/mechs/"

local scriptPath = mod_loader.mods[modApi.currentMod].scriptPath
local mod = modApi:getCurrentMod()

local squadColors = modApi:getPaletteImageOffset("starwars_empire_color")

local files = {
	"sw_death_star_ns.png",
	"sw_death_star_h.png",
}

for _, file in ipairs(files) do
	modApi:appendAsset("img/units/player/" .. file, mechPath .. file)
end

-- -x = left, +x = right
-- -y = up, +y - down
local a = ANIMS
-- These shouldn't matter
a.sw_deathstar =         a.MechUnit:new{Image = "units/player/sw_death_star_ns.png", PosX = -22, PosY = -8 }
a.sw_deathstara =        a.MechUnit:new{Image = "units/player/sw_death_star_ns.png", PosX = -22, PosY = -8 }
a.sw_deathstar_broken =  a.MechUnit:new{Image = "units/player/sw_death_star_ns.png", PosX = -22, PosY = -8 }
a.sw_deathstarw_broken = a.MechUnit:new{Image = "units/player/sw_death_star_ns.png", PosX = -22, PosY = -8 }
a.sw_deathstar_ns =      a.MechIcon:new{Image = "units/player/sw_death_star_ns.png" }

-- Add orbital launch animation (reuse timetravel effect)
a.StarWars_DeathStarLaunch = Animation:new{
	Image = "effects/timetravel.png",
	NumFrames = 19,
	Loop = false,
	PosX = -32,
	Time = 0.02,
	PosY = -145,
}

local PASS_DELAY = 0.06
local INTRO_FRAMES = 6
ANIMS.StarWars_PrimingLaser_Anim = Animation:new{
	Image = "effects/satellite_sw_priming_laser.png",
	NumFrames = 11,
	Loop = false,
	PosX = -11,
	PosY = -370,
	Lengths = {
		PASS_DELAY, PASS_DELAY, PASS_DELAY, PASS_DELAY, PASS_DELAY,
		PASS_DELAY,
		PASS_DELAY, PASS_DELAY, PASS_DELAY, PASS_DELAY, PASS_DELAY},
}

StarWars_DeathStarMech = Pawn:new{
	Name = "Death Star",
	Class = "Science",
	Health = 10,
	MoveSpeed = 0,
	Image = "sw_deathstar",
	ImageOffset = squadColors,
	SkillList = { "StarWars_AuxiliarySuperlaser", "StarWars_EmpireOfTerror" },
	SoundLocation = "/mech/distance/artillery/",
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
	SpaceColor = false,
	Massive = true,
	Flying = true,
	Orbital = true,
	OrbitalAnim = "StarWars_DeathStarLaunch",
	OrbitalSound = "/weapons/enhanced_tractor",
	OrbitalIcon = true,

	BASE_ALLY_RANGE = 2,
}

modApi:setText("StarWars_DeathStar_Capacitors_Tooltip",
		"When powered, Priming Laser recharges the Aux. Superlaser by 2 instead of 1")
modApi:setText("StarWars_DeathStar_Detectors_Tooltip",
		"When powered, doubles Priming Laser range from allies. Applied after move bonuses")

mech_forge:registerMechUpgrade("StarWars_DeathStarMech", mech_forge.VANILLA_UPGRADES.HEALTH, {
		label = "Force Drain",
		tooltip = "StarWars_DeathStar_Capacitors_Tooltip",
		coreSlots = 2,
})
mech_forge:registerMechUpgrade("StarWars_DeathStarMech", mech_forge.VANILLA_UPGRADES.MOVE, {
		label = "Detectors",
		tooltip = "StarWars_DeathStar_Detectors_Tooltip",
})

function StarWars_DeathStarMech.getPrimingDamage(pawn)
	return 1
end

function StarWars_DeathStarMech.getSuperlaserRechargeAmount(pawn)
	local charges = 1
	if pawn and mech_forge:isMechUpgradePowered(pawn, mech_forge.VANILLA_UPGRADES.HEALTH) then
		charges = 2
	end
	return charges
end

function StarWars_DeathStarMech.getPrimingRange(pawn)
	local move = 0
	if pawn then
		move = math.max(0, pawn:GetMoveSpeed())
	end
	local range = StarWars_DeathStarMech.BASE_ALLY_RANGE + move
	if pawn and mech_forge:isMechUpgradePowered(pawn, mech_forge.VANILLA_UPGRADES.MOVE) then
		range = range * 2
	end
	return range
end

function StarWars_DeathStarMech.isTargetThatWillRecharge(point)
	return Board:IsBuilding(point) or Board:IsPawnSpace(point)
end

modApi:setText("StarWars_DeathStar_Repair_Description", memhack.getTextWrappers.basedOnSelectedPawn(function(pawn)
	local damage = 1
	local range = 2
	local forceDrain = false
	local detectors = false
	local recharge = 1
	if pawn then
		damage = StarWars_DeathStarMech.getPrimingDamage(pawn)
		range = StarWars_DeathStarMech.getPrimingRange(pawn)
		recharge = StarWars_DeathStarMech.getSuperlaserRechargeAmount(pawn)
		forceDrain = mech_forge:isMechUpgradePowered(pawn, mech_forge.VANILLA_UPGRADES.HEALTH)
		detectors = mech_forge:isMechUpgradePowered(pawn, mech_forge.VANILLA_UPGRADES.MOVE)
	end
	local desc = "Deal " .. damage .. " damage to a target within " .. range .. " spaces of an ally, draining"
			.. " energy if its a pawn or building to recharge the Aux. Superlaser by " .. recharge .. "."
			.. " Range scales with Mech's Move Speed."

	if forceDrain then
		if detectors then
			desc = desc .. " Currently boosted by Force Drain and Detectors."
		else
			desc = desc .. " Currently boosted by Force Drain."
		end
	elseif detectors then
		desc = desc .. " Currently boosted by Detectors."
	end
	return desc
end))

StarWars_DeathStar_Repair = Skill:new{
	Name = "Priming Laser",
	Icon = "weapons/repair.png",
	Class = "Science",
	PowerCost = 0,
	Upgrades = 0,
	-- Not sure it matters but do it anyways
	Orbital = true,
	TipImage = {
		CustomPawn = "StarWars_DeathStarMech",
		Unit = Point(2, 2),
		Enemy = Point(2, 1),
		Target = Point(2, 1),
	},
	LaunchSound = "/weapons/confusion",
	ImpactSound = "/weapons/localized_explosion",
}

function StarWars_DeathStar_Repair:GetTargetArea(point)
	local ret = PointList()
	local pawn = Board:GetPawn(point)
	if not pawn then
		return ret
	end

	-- Go through each ally and add any spaces within the range that aren't already present in the list
	local range = StarWars_DeathStarMech.getPrimingRange(pawn)
	local seen = {}
	for _, allyId in ipairs(extract_table(Board:GetPawns(TEAM_PLAYER))) do
		local ally = Board:GetPawn(allyId)
		local allySpace = ally and ally:GetSpace()
		if ally and ally:GetId() ~= pawn:GetId() and allySpace and Board:IsValid(allySpace) and not ally:IsDead() then
			for _, p in pairs(extract_table(general_DiamondTarget(allySpace, range))) do
				BoardUtils.pushUniquePoint(ret, seen, p)
			end
		end
	end
	return ret
end

function StarWars_DeathStarMech.rechargeSuperlaserScript(pawnId, weaponIdx, chargeAmount)
	return string.format([[
			local pawn = Board:GetPawn(%d)
			if pawn then
				local wIdx = %d
				pawn:SetWeaponLimitedRemaining(wIdx, pawn:GetWeaponLimitedRemaining(wIdx) + %d)
				for i = 0, 7 do
					for j = 0, 7  do
						local point = Point(i,j)
						if Board:IsBuilding(point) and Board:GetHealth(point) > 0 then
							Board:Ping(point, GL_Color(100, 100, 255))
						end
					end
				end
			end
	]], pawnId, weaponIdx, chargeAmount)
end

function StarWars_DeathStar_Repair:GetSkillEffect(p1, p2)
	local ret = SkillEffect()
	local pawn = Board:GetPawn(p1)
	local damageAmount = StarWars_DeathStarMech.getPrimingDamage(pawn)

	ret:AddSound("/weapons/confusion")
	ret:AddDelay(INTRO_FRAMES / 2 * PASS_DELAY)
	ret:AddScript([[
		Board:AddAnimation(]] .. p2:GetString() .. [[, "StarWars_PrimingLaser_Anim", 1)
	]])
	ret:AddDelay(INTRO_FRAMES * PASS_DELAY)

	ret:AddSound(self.ImpactSound)
	local damage = SpaceDamage(p2, damageAmount)
	damage.sAnimation = "ExploArt1"
	ret:AddDamage(damage)
	ret:AddBounce(p2, 2)

	if StarWars_DeathStarMech.isTargetThatWillRecharge(p2) then
		local weapons = pawn:GetBaseWeaponTypes()
		for wIdx = 1, 2 do
			local weaponId = weapons[wIdx]
			if weaponId and weaponId:find("StarWars_AuxiliarySuperlaser") then
				local chargeAmount = StarWars_DeathStarMech.getSuperlaserRechargeAmount(pawn)
				ret:AddScript(StarWars_DeathStarMech.rechargeSuperlaserScript(pawn:GetId(), wIdx, chargeAmount))
			end
		end
	end
	-- Pause for effect

	ret:AddDelay(INTRO_FRAMES * PASS_DELAY)
	return ret
end

-- Register the custom repair skill for Death Star
ReplaceRepair:addSkill{
	name = "Priming Laser",
	description = "StarWars_DeathStar_Repair_Description",
	weapon = "StarWars_DeathStar_Repair",
	icon = "img/weapons/deathstar_repair.png",
	mechType = "StarWars_DeathStarMech",
}

-- IN test mode, spawn a TIE Fighter near an enemy for testing replace reapir
function StarWars_DeathStarMech.spawnTestHangarAllyNearEnemy()
	if not IsTestMechScenario() or not Board or Board:IsTipImage() then
		return
	end

	-- Test mode is wonky with ids and what is nil or not. This will get the
	-- test pawn and ensure its the death star
	local testMech = Game:GetPawn(0) or Game:GetPawn(1) or Game:GetPawn(2)
	if not testMech or testMech:GetType() ~= "StarWars_DeathStarMech" then
		return
	end

	-- Find the safe locations to spawn near an enemy
	local nearEnemy = {}
	for _, point in ipairs(BoardUtils.getSafeSpawnTiles(PATH_FLYER)) do
		for _, enemyId in ipairs(extract_table(Board:GetPawns(TEAM_ENEMY))) do
			local enemy = Board:GetPawn(enemyId)
			local enemySpace = enemy and enemy:GetSpace()
			-- if an enemy is in range, add the space and continue to the next one
			if BoardUtils.getManhattanDistance(point, enemySpace) <= StarWars_DeathStarMech.BASE_ALLY_RANGE then
				table.insert(nearEnemy, point)
				break
			end
		end
	end

	-- Spawn the tie fighter in a random safe spot near an enemy (if we found one)
	if #nearEnemy > 0 then
		Board:SpawnPawn("StarWars_TIEFighterMech", nearEnemy[math.random(#nearEnemy)])
	end
end

modApi.events.onTestMechEntered:subscribe(function()
	-- We seem to need to delay it a frame for the board to set up and enemies
	-- to be on it
	modApi:runLater(StarWars_DeathStarMech.spawnTestHangarAllyNearEnemy)
end)