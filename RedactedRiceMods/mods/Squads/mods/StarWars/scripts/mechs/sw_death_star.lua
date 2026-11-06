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

Weapon_Texts.StarWars_DeathStar_Capacitors_Tooltip =
	"+1 damage to Priming Laser"
Weapon_Texts.StarWars_DeathStar_Detectors_Tooltip =
	"Doubles Priming Laser range from allies"

mech_forge:registerMechUpgrade("StarWars_DeathStarMech", mech_forge.VANILLA_UPGRADES.HEALTH, {
	label = "Capacitors",
	tooltip = "StarWars_DeathStar_Capacitors_Tooltip",
})
mech_forge:registerMechUpgrade("StarWars_DeathStarMech", mech_forge.VANILLA_UPGRADES.MOVE, {
	label = "Detectors",
	tooltip = "StarWars_DeathStar_Detectors_Tooltip",
})

function StarWars_DeathStarMech.getPrimingDamage(pawn)
	local damage = 1
	if mech_forge:isMechUpgradePowered(pawn, mech_forge.VANILLA_UPGRADES.HEALTH) then
		damage = damage + 1
	end
	return damage
end

function StarWars_DeathStarMech.getPrimingRange(pawn)
	local move = 0
	if pawn then
		move = math.max(0, pawn:GetMoveSpeed())
	end
	local range = StarWars_DeathStarMech.BASE_ALLY_RANGE + move
	if  mech_forge:isMechUpgradePowered(pawn, mech_forge.VANILLA_UPGRADES.MOVE) then
		range = range * 2
	end
	return range
end

function StarWars_DeathStarMech.isTargetThatWillRecharge(point)
	return Board:IsBuilding(point) or Board:IsPawnSpace(point)
end

StarWars_DeathStar_Repair = Skill:new{
	Name = "Priming Laser",
	Description = "Damage an object within 2 spaces of an ally (+ move) to recharge the Aux. Superlaser.",
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
		if ally and allySpace and Board:IsValid(allySpace) and not ally:IsDead() then
			for _, p in pairs(extract_table(general_DiamondTarget(allySpace, range))) do
				BoardUtils.pushUniquePoint(ret, seen, p)
			end
		end
	end
	return ret
end

function StarWars_DeathStarMech.rechargeSuperlaserScript(pawnId, weaponIdx)
	return string.format([[
			local pawn = Board:GetPawn(%d)
			if pawn then
				local wIdx = %d
				pawn:SetWeaponLimitedRemaining(wIdx, pawn:GetWeaponLimitedRemaining(wIdx) + 1)
				for i = 0, 7 do
					for j = 0, 7  do
						local point = Point(i,j)
						if Board:IsBuilding(point) and Board:GetHealth(point) > 0 then
							Board:Ping(point, GL_Color(100, 100, 255))
						end
					end
				end
			end
	]], pawnId, weaponIdx)
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
				ret:AddScript(StarWars_DeathStarMech.rechargeSuperlaserScript(pawn:GetId(), wIdx))
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
	description = "Hit an object near an ally to recharge the Aux. Superlaser.",
	weapon = "StarWars_DeathStar_Repair",
	icon = "img/weapons/deathstar_repair.png",
	mechType = "StarWars_DeathStarMech",
}
