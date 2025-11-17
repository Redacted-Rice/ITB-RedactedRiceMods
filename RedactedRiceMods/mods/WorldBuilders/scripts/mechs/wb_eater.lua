local resourcePath = mod_loader.mods[modApi.currentMod].resourcePath
local mechPath = resourcePath .. "img/mechs/"

local scriptPath = mod_loader.mods[modApi.currentMod].scriptPath
local mod = modApi:getCurrentMod()

local squadColors = modApi:getPaletteImageOffset("worldbuilders_color")

local files = {
	"wb_eater.png",
	"wb_eater_a.png",
	"wb_eater_w_broken.png",
	"wb_eater_broken.png",
	"wb_eater_ns.png",
	"wb_eater_h.png"
}

for _, file in ipairs(files) do
	modApi:appendAsset("img/units/player/" .. file, mechPath .. file)
end

-- -x = left, +x = right
-- -y = up, +y - down
local a = ANIMS
a.wb_eater =         a.MechUnit:new{Image = "units/player/wb_eater.png",          PosX = -21, PosY = -10 }
a.wb_eatera =        a.MechUnit:new{Image = "units/player/wb_eater_a.png",        PosX = -21, PosY = -10, NumFrames = 5 }
a.wb_eater_broken =  a.MechUnit:new{Image = "units/player/wb_eater_broken.png",   PosX = -22, PosY = -13 }
a.wb_eaterw_broken = a.MechUnit:new{Image = "units/player/wb_eater_w_broken.png", PosX = -22, PosY = -5 }
a.wb_eater_ns =      a.MechIcon:new{Image = "units/player/wb_eater_ns.png" }


WorldBuilders_EaterMech = Pawn:new{	
	Name = "Eater",
	Class = "Brute",
	Health = 2,
	MoveSpeed = 3,
	Image = "wb_eater",
	ImageOffset = squadColors,
	SkillList = { "WorldBuilders_Consume" },
	SoundLocation = "/mech/distance/artillery/",
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
	Massive = true,
	Flying = true,
}