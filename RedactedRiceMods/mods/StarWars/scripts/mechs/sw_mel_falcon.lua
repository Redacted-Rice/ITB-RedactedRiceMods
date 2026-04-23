local resourcePath = mod_loader.mods[modApi.currentMod].resourcePath
local mechPath = resourcePath .. "img/mechs/"

local scriptPath = mod_loader.mods[modApi.currentMod].scriptPath
local mod = modApi:getCurrentMod()

local squadColors = modApi:getPaletteImageOffset("starwars_rebels_color")

local files = {
	"sw_melfalcon.png",
	"sw_melfalcon_a.png",
	"sw_melfalcon_w_broken.png",
	"sw_melfalcon_broken.png",
	"sw_melfalcon_ns.png",
	"sw_melfalcon_h.png"
}

for _, file in ipairs(files) do
	modApi:appendAsset("img/units/player/" .. file, mechPath .. file)
end

-- -x = left, +x = right
-- -y = up, +y - down
local a = ANIMS
a.sw_melfalcon =         a.MechUnit:new{Image = "units/player/sw_melfalcon.png",          PosX = -19, PosY = -11 }
a.sw_melfalcona =        a.MechUnit:new{Image = "units/player/sw_melfalcon_a.png",        PosX = -19, PosY = -11, NumFrames = 5 }
a.sw_melfalcon_broken =  a.MechUnit:new{Image = "units/player/sw_melfalcon_broken.png",   PosX = -19, PosY = 1 }
a.sw_melfalconw_broken = a.MechUnit:new{Image = "units/player/sw_melfalcon_w_broken.png", PosX = -18, PosY = 4 }
a.sw_melfalcon_ns =      a.MechIcon:new{Image = "units/player/sw_melfalcon_ns.png" }


StarWars_MelFalconMech = Pawn:new{	
	Name = "Millennium Falcon",
	Class = "Science",
	Health = 3,
	MoveSpeed = 3,
	Image = "sw_melfalcon",
	ImageOffset = squadColors,
	SkillList = { "StarWars_CannonTurrets","Support_Missiles" },
	SoundLocation = "/mech/distance/artillery/",
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
	Massive = true,
	Flying = true,
}