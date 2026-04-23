local resourcePath = mod_loader.mods[modApi.currentMod].resourcePath
local mechPath = resourcePath .. "img/mechs/"

local scriptPath = mod_loader.mods[modApi.currentMod].scriptPath
local mod = modApi:getCurrentMod()

local squadColors = modApi:getPaletteImageOffset("starwars_rebels_color")

local files = {
	"sw_xwing.png",
	"sw_xwing_a.png",
	"sw_xwing_w_broken.png",
	"sw_xwing_broken.png",
	"sw_xwing_ns.png",
	"wb_maker_h.png"
}

for _, file in ipairs(files) do
	modApi:appendAsset("img/units/player/" .. file, mechPath .. file)
end

-- -x = left, +x = right
-- -y = up, +y - down
local a = ANIMS
a.sw_xwing =         a.MechUnit:new{Image = "units/player/sw_xwing.png",          PosX = -19, PosY = -9 }
a.sw_xwinga =        a.MechUnit:new{Image = "units/player/sw_xwing_a.png",        PosX = -19, PosY = -9, NumFrames = 4 }
a.sw_xwing_broken =  a.MechUnit:new{Image = "units/player/sw_xwing_broken.png",   PosX = -19, PosY = 0 }
a.sw_xwingw_broken = a.MechUnit:new{Image = "units/player/sw_xwing_w_broken.png", PosX = -21, PosY = 6 }
a.sw_xwing_ns =      a.MechIcon:new{Image = "units/player/sw_xwing_ns.png" }


StarWars_XWingMech = Pawn:new{	
	Name = "X-Wing",
	Class = "Brute",
	Health = 2,
	MoveSpeed = 3,
	Image = "sw_xwing",
	ImageOffset = squadColors,
	SkillList = { "StarWars_ProtonTorpedo" },
	SoundLocation = "/mech/prime/punch_mech/",
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
	Massive = true,
	Flying = true,
}