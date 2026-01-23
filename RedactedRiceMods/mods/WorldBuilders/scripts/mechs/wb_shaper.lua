local resourcePath = mod_loader.mods[modApi.currentMod].resourcePath
local mechPath = resourcePath .. "img/mechs/"

local scriptPath = mod_loader.mods[modApi.currentMod].scriptPath
local mod = modApi:getCurrentMod()

local squadColors = modApi:getPaletteImageOffset("worldbuilders_color")

local files = {
	"wb_shaper.png",
	"wb_shaper_a.png",
	"wb_shaper_w.png",
	"wb_shaper_w_broken.png",
	"wb_shaper_broken.png",
	"wb_shaper_ns.png",
	"wb_shaper_h.png"
}

for _, file in ipairs(files) do
	modApi:appendAsset("img/units/player/" .. file, mechPath .. file)
end

-- -x = left, +x = right
-- -y = up, +y - down
local a = ANIMS
a.wb_shaper =         a.MechUnit:new{Image = "units/player/wb_shaper.png",          PosX = -22, PosY = -9 }
a.wb_shapera =        a.MechUnit:new{Image = "units/player/wb_shaper_a.png",        PosX = -22, PosY = -9, NumFrames = 6 }
a.wb_shaperw =        a.MechUnit:new{Image = "units/player/wb_shaper_w.png",        PosX = -22, PosY = -2 }
a.wb_shaper_broken =  a.MechUnit:new{Image = "units/player/wb_shaper_broken.png",   PosX = -21, PosY =  -9 }
a.wb_shaperw_broken = a.MechUnit:new{Image = "units/player/wb_shaper_w_broken.png", PosX = -26, PosY =  -2 }
a.wb_shaper_ns =      a.MechIcon:new{Image = "units/player/wb_shaper_ns.png" }


WorldBuilders_ShaperMech = Pawn:new{
	Name = "Shaper",
	Class = "Science",
	Health = 2,
	MoveSpeed = 4,
	Image = "wb_shaper",
	ImageOffset = squadColors,
	SkillList = { "WorldBuilders_Shift", "WorldBuilders_Passive_Move" },
	SoundLocation = "/mech/science/pulse_mech/",
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
	Massive = true,
}