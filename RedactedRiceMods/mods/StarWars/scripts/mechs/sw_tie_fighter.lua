local resourcePath = mod_loader.mods[modApi.currentMod].resourcePath
local mechPath = resourcePath .. "img/mechs/"

local scriptPath = mod_loader.mods[modApi.currentMod].scriptPath
local mod = modApi:getCurrentMod()

local squadColors = modApi:getPaletteImageOffset("starwars_empire_color")

-- Temporarily use X-Wing images
local files = {
	"sw_xwing.png",
	"sw_xwing_a.png",
	"sw_xwing_w_broken.png",
	"sw_xwing_broken.png",
	"sw_xwing_ns.png",
	"sw_xwing_h.png"
}

-- -x = left, +x = right
-- -y = up, +y - down
local a = ANIMS
a.sw_tiefighter =         a.MechUnit:new{Image = "units/player/sw_xwing.png",          PosX = -19, PosY = -9 }
a.sw_tiefightera =        a.MechUnit:new{Image = "units/player/sw_xwing_a.png",        PosX = -19, PosY = -9, NumFrames = 4 }
a.sw_tiefighter_broken =  a.MechUnit:new{Image = "units/player/sw_xwing_broken.png",   PosX = -19, PosY = 0 }
a.sw_tiefighterw_broken = a.MechUnit:new{Image = "units/player/sw_xwing_w_broken.png", PosX = -21, PosY = 6 }
a.sw_tiefighter_ns =      a.MechIcon:new{Image = "units/player/sw_xwing_ns.png" }


StarWars_TIEFighterMech = Pawn:new{
	Name = "TIE Fighter",
	Class = "Ranged",
	Health = 1,
	MoveSpeed = 3,
	Image = "sw_tiefighter",
	ImageOffset = squadColors,
	SkillList = { "StarWars_DualCannons", "StarWars_TieOverdrive" },
	SoundLocation = "/mech/prime/punch_mech/",
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
	Massive = true,
	Flying = true,
}
