local resourcePath = mod_loader.mods[modApi.currentMod].resourcePath
local mechPath = resourcePath .. "img/mechs/"

local scriptPath = mod_loader.mods[modApi.currentMod].scriptPath
local mod = modApi:getCurrentMod()

local squadColors = modApi:getPaletteImageOffset("worldbuilders_color")

local files = {
	"wb_maker.png",
	"wb_maker_a.png",
	"wb_maker_w.png",
	"wb_maker_w_broken.png",
	"wb_maker_broken.png",
	"wb_maker_ns.png",
	"wb_maker_h.png"
}

for _, file in ipairs(files) do
	modApi:appendAsset("img/units/player/" .. file, mechPath .. file)
end

-- -x = left, +x = right
-- -y = up, +y - down
local a = ANIMS
a.wb_maker =         a.MechUnit:new{Image = "units/player/wb_maker.png",          PosX = -18, PosY = -12 }
a.wb_makera =        a.MechUnit:new{Image = "units/player/wb_maker_a.png",        PosX = -18, PosY = -12, NumFrames = 4 }
a.wb_makerw =        a.MechUnit:new{Image = "units/player/wb_maker_w.png",        PosX = -20, PosY = -6 }
a.wb_maker_broken =  a.MechUnit:new{Image = "units/player/wb_maker_broken.png",   PosX = -18, PosY = -14 }
a.wb_makerw_broken = a.MechUnit:new{Image = "units/player/wb_maker_w_broken.png", PosX = -21, PosY = -7 }
a.wb_maker_ns =      a.MechIcon:new{Image = "units/player/wb_maker_ns.png" }


WorldBuilders_MakerMech = Pawn:new{	
	Name = "Maker",
	Class = "Prime",
	Health = 3,
	MoveSpeed = 3,
	Image = "wb_maker",
	ImageOffset = squadColors,
	SkillList = { "WorldBuilders_Mold" },
	SoundLocation = "/mech/prime/punch_mech/",
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
	Massive = true,
}