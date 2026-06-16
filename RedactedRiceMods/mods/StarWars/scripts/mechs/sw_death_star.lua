local resourcePath = mod_loader.mods[modApi.currentMod].resourcePath
local mechPath = resourcePath .. "img/mechs/"

local scriptPath = mod_loader.mods[modApi.currentMod].scriptPath
local mod = modApi:getCurrentMod()

local squadColors = modApi:getPaletteImageOffset("starwars_empire_color")

local files = {
	"sw_death_star_ns.png",
}

for _, file in ipairs(files) do
	modApi:appendAsset("img/units/player/" .. file, mechPath .. file)
end

-- -x = left, +x = right
-- -y = up, +y - down
local a = ANIMS
-- These shouldn't matter
a.sw_deathstar =         a.MechUnit:new{Image = "units/player/sw_death_star_ns.png", PosX = -18, PosY = 4 }
a.sw_deathstara =        a.MechUnit:new{Image = "units/player/sw_death_star_ns.png", PosX = -18, PosY = 4 }
a.sw_deathstar_broken =  a.MechUnit:new{Image = "units/player/sw_death_star_ns.png", PosX = -18, PosY = 4 }
a.sw_deathstarw_broken = a.MechUnit:new{Image = "units/player/sw_death_star_ns.png", PosX = -18, PosY = 4 }
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

-- Death Star custom repair: Orbital Strike that recharges weapons
StarWars_DeathStarRepair = Skill:new{
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
	LaunchSound = "/weapons/artillery_volley",
	ImpactSound = "/impact/generic/explosion",
	Projectile = "effects/shot_sw_superlaser",
}

function StarWars_DeathStarRepair:GetTargetArea(point)
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

function StarWars_DeathStarRepair:GetSkillEffect(p1, p2)
	local ret = SkillEffect()

	-- Deal 1 damage to the target
	local damage = SpaceDamage(p2, 1)
	ret:AddDamage(damage)
	ret:AddBounce(p2, 2)

	-- Recharge the Auxiliary Superlaser
	for pId = 0, 2 do
		local pawn = Board:GetPawn(pId)
		-- for some reason this is nil sometimes in a mission?
		LOG("PID "..pId .. ", pawn " .. tostring(pawn))
		local weapons = pawn:GetBaseWeaponTypes()
		for wIdx = 1, 2 do
			local weaponId = weapons[wIdx]
			if weaponId and weaponId:find("StarWars_AuxiliarySuperlaser") then
				LOG("FOUND WEAPOIN ID " .. weaponId .. " for pawn " .. pId)
				ret:AddScript(string.format([[
					local pawn = Board:GetPawn(%d)
					local wIdx = %d
					pawn:SetWeaponLimitedRemaining(wIdx, pawn:GetWeaponLimitedRemaining(wIdx) + 1)
					LOG("SET WEAPON LIMITED REMAINING TO " .. pawn:GetWeaponLimitedRemaining(wIdx) .. " for pawn " .. pId)
				]], pId, wIdx))
				break
			end
		end
	end
	return ret
end

-- Register the custom repair skill for Death Star
ReplaceRepair:addSkill{
	name = "Priming Laser",
	description = "Deal 1 damage to any tile and recharge weapons.",
	weapon = "StarWars_DeathStarRepair",
	icon = "weapons/repair",
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
