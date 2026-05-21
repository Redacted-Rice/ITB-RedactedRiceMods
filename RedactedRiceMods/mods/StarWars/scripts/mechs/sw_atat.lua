local resourcePath = mod_loader.mods[modApi.currentMod].resourcePath
local mechPath = resourcePath .. "img/mechs/"

local scriptPath = mod_loader.mods[modApi.currentMod].scriptPath
local mod = modApi:getCurrentMod()

local squadColors = modApi:getPaletteImageOffset("starwars_empire_color")

-- Temporarily use Snow Speeder images
local files = {
	"sw_snowspeeder.png",
	"sw_snowspeeder_a.png",
	"sw_snowspeeder_w_broken.png",
	"sw_snowspeeder_broken.png",
	"sw_snowspeeder_ns.png",
	"sw_snowspeeder_h.png"
}

-- -x = left, +x = right
-- -y = up, +y - down
local a = ANIMS
a.sw_atat =         a.MechUnit:new{Image = "units/player/sw_snowspeeder.png",          PosX = -20, PosY = -6 }
a.sw_atata =        a.MechUnit:new{Image = "units/player/sw_snowspeeder_a.png",        PosX = -20, PosY = -6, NumFrames = 6 }
a.sw_atat_broken =  a.MechUnit:new{Image = "units/player/sw_snowspeeder_broken.png",   PosX = -18, PosY = -1 }
a.sw_atatw_broken = a.MechUnit:new{Image = "units/player/sw_snowspeeder_w_broken.png", PosX = -18, PosY = 6 }
a.sw_atat_ns =      a.MechIcon:new{Image = "units/player/sw_snowspeeder_ns.png" }


StarWars_ATATMech = Pawn:new{
	Name = "AT-AT Walker",
	Class = "Brute",
	Health = 3,
	MoveSpeed = 2,
	Image = "sw_atat",
	ImageOffset = squadColors,
	SkillList = { "StarWars_HeavyCannons", "StarWars_Stomp" },
	SoundLocation = "/mech/science/pulse_mech/",
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
	Massive = true,
	Armor = true,
	Flying = false,
}
