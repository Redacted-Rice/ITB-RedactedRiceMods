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

-- Death Star custom repair: Orbital Strike that recharges weapons
StarWars_DeathStar_Repair = Skill:new{
	Name = "Priming Laser",
	Description = "Deal 1 damage to any tile on the board and gain a charge for the Auxiliary Superlaser.",
	Icon = "weapons/repair.png",
	Class = "Science",
	PowerCost = 0,
	Upgrades = 0,
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

	-- Can target any valid space on the board
	local size = Board:GetSize()
	for x = 0, size.x - 1 do
		for y = 0, size.y - 1 do
			local p = Point(x, y)
			if Board:IsValid(p) then
				ret:push_back(p)
			end
		end
	end
	return ret
end

function StarWars_DeathStar_Repair:GetSkillEffect(p1, p2)
	local ret = SkillEffect()

	-- pause for effect

	-- Turbo cannon
	--mech_prime_skill_burst_beam.wav
	--mech_brute_skill_ricochet.wav
	-- TODO: Continue here
	--mech_science_push_beam.wav
	
	--mech_brute_bulk_move_01.wav (overdrive)
	-- mech_science_skill_area_shield.wav

	-- Priming laser
	--damage.sSound = "/impact/generic/tractor_beam"
	--mech_science_skill_enhanced_tractor.wav
	-- forceswap
	--mech_support_skill_confusion.wav

	--mech_science_skill_fire_beam.wav
	--mech_science_skill_rainingfire.wav

	--mech_support_skill_refrigerate.wav
	--prop_final_ground_break.wav


	ret:AddSound("/weapons/confusion")
	ret:AddDelay(INTRO_FRAMES / 2 * PASS_DELAY)
	ret:AddScript([[
		Board:AddAnimation(]] .. p2:GetString() .. [[, "StarWars_PrimingLaser_Anim", 1)
	]])
	ret:AddDelay(INTRO_FRAMES * PASS_DELAY)

	-- Deal 1 damage to the target
	ret:AddSound(self.ImpactSound)
	local damage = SpaceDamage(p2, 1)
	damage.sAnimation = "ExploArt1"
	ret:AddDamage(damage)
	ret:AddBounce(p2, 2)
	-- Recharge the Auxiliary Superlaser
	for pId = 0, 2 do
		-- Board:GetPawn() is nil here for some reason
		local pawn = Game:GetPawn(pId)
		-- for some reason this is nil sometimes in a mission?
		if pawn then
			LOG("PID "..pId .. ", pawn " .. tostring(pawn:GetType()))
			local weapons = pawn:GetBaseWeaponTypes()
			for wIdx = 1, 2 do
				local weaponId = weapons[wIdx]
				if weaponId and weaponId:find("StarWars_AuxiliarySuperlaser") then
					LOG("FOUND WEAPOIN ID " .. weaponId .. " for pawn " .. pId)
					ret:AddScript(string.format([[
						local pawn = Board:GetPawn(%d)
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
					]], pId, wIdx))
					break
				end
			end
		else
			LOG("PID "..pId .. ", pawn is nil")
		end
	end
	-- Pause for effect
	ret:AddDelay(INTRO_FRAMES * PASS_DELAY)
	return ret
end

-- Register the custom repair skill for Death Star
ReplaceRepair:addSkill{
	name = "Priming Laser",
	description = "Deal 1 damage to any tile and recharge weapons.",
	weapon = "StarWars_DeathStar_Repair",
	icon = "img/weapons/deathstar_repair.png",
	mechType = "StarWars_DeathStarMech",
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
}
