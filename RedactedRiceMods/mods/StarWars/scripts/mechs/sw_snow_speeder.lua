local resourcePath = mod_loader.mods[modApi.currentMod].resourcePath
local mechPath = resourcePath .. "img/mechs/"

local scriptPath = mod_loader.mods[modApi.currentMod].scriptPath
local mod = modApi:getCurrentMod()

local squadColors = modApi:getPaletteImageOffset("starwars_rebels_color")

local files = {
	"sw_snowspeeder.png",
	"sw_snowspeeder_a.png",
	"wb_shaper_w_broken.png",
	"wb_shaper_broken.png",
	"sw_snowspeeder_ns.png",
	"wb_shaper_h.png"
}

for _, file in ipairs(files) do
	modApi:appendAsset("img/units/player/" .. file, mechPath .. file)
end

-- -x = left, +x = right
-- -y = up, +y - down
local a = ANIMS
a.sw_snowspeeder =         a.MechUnit:new{Image = "units/player/sw_snowspeeder.png",     PosX = -20, PosY = -6 }
a.sw_snowspeedera =        a.MechUnit:new{Image = "units/player/sw_snowspeeder_a.png",   PosX = -20, PosY = -6, NumFrames = 6 }
a.sw_snowspeeder_broken =  a.MechUnit:new{Image = "units/player/wb_shaper_broken.png",   PosX = -21, PosY =  -9 }
a.sw_snowspeederw_broken = a.MechUnit:new{Image = "units/player/wb_shaper_w_broken.png", PosX = -26, PosY =  -3 }
a.sw_snowspeeder_ns =      a.MechIcon:new{Image = "units/player/sw_snowspeeder_ns.png" }


StarWars_SnowSpeederMech = Pawn:new{	
	Name = "Snow Speeder",
	Class = "Brute",
	Health = 2,
	MoveSpeed = 4,
	Image = "sw_snowspeeder",
	ImageOffset = squadColors,
	SkillList = { "StarWars_PairedCannons" },
	SoundLocation = "/mech/science/pulse_mech/",
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
	Massive = true,
	Flying = true,
}