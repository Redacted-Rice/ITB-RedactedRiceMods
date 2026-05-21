local resourcePath = mod_loader.mods[modApi.currentMod].resourcePath
local mechPath = resourcePath .. "img/mechs/"

local scriptPath = mod_loader.mods[modApi.currentMod].scriptPath
local mod = modApi:getCurrentMod()

local squadColors = modApi:getPaletteImageOffset("starwars_empire_color")

-- Temporarily use Millennium Falcon images
local files = {
	"sw_melfalcon.png",
	"sw_melfalcon_a.png",
	"sw_melfalcon_w_broken.png",
	"sw_melfalcon_broken.png",
	"sw_melfalcon_ns.png",
	"sw_melfalcon_h.png"
}

-- -x = left, +x = right
-- -y = up, +y - down
local a = ANIMS
a.sw_deathstar =         a.MechUnit:new{Image = "units/player/sw_melfalcon.png",          PosX = -19, PosY = -11 }
a.sw_deathstara =        a.MechUnit:new{Image = "units/player/sw_melfalcon_a.png",        PosX = -19, PosY = -11, NumFrames = 5 }
a.sw_deathstar_broken =  a.MechUnit:new{Image = "units/player/sw_melfalcon_broken.png",   PosX = -19, PosY = 1 }
a.sw_deathstarw_broken = a.MechUnit:new{Image = "units/player/sw_melfalcon_w_broken.png", PosX = -18, PosY = 4 }
a.sw_deathstar_ns =      a.MechIcon:new{Image = "units/player/sw_melfalcon_ns.png" }


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
	Massive = true,
	Flying = true,
}
