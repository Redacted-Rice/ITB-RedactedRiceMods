local resourcePath = mod_loader.mods[modApi.currentMod].resourcePath
local mechPath = resourcePath .. "img/units/player/"

local scriptPath = mod_loader.mods[modApi.currentMod].scriptPath
local mod = modApi:getCurrentMod()

local squadColors = modApi:getPaletteImageOffset("moonstriders_color")

local files = {
	"mech_mortar.png",
	"mech_mortar_a.png",
	"mech_mortar_w.png",
	"mech_mortar_w_broken.png",
	"mech_mortar_broken.png",
	"mech_mortar_ns.png",
	"mech_mortar_h.png"
}

for _, file in ipairs(files) do
	modApi:appendAsset("img/units/player/" .. file, mechPath .. file)
end

-- -x = left, +x = right
-- -y = up, +y - down
local a = ANIMS
a.mech_mortar =         a.MechUnit:new{Image = "units/player/mech_mortar.png",          PosX = -22, PosY = -9 }
a.mech_mortara =        a.MechUnit:new{Image = "units/player/mech_mortar_a.png",        PosX = -22, PosY = -9, NumFrames = 6 }
a.mech_mortarw =        a.MechUnit:new{Image = "units/player/mech_mortar_w.png",        PosX = -22, PosY = -3 }
a.mech_mortar_broken =  a.MechUnit:new{Image = "units/player/mech_mortar_broken.png",   PosX = -21, PosY =  -9 }
a.mech_mortarw_broken = a.MechUnit:new{Image = "units/player/mech_mortar_w_broken.png", PosX = -26, PosY =  -3 }
a.mech_mortar_ns =      a.MechIcon:new{Image = "units/player/mech_mortar_ns.png" }


MoonStriders_MortarMech = Pawn:new{
	Name = "Mortar",
	Class = "Ranged",
	Health = 2,
	ImageOffset = 0,
	MoveSpeed = 3,
	Image = "mech_mortar",
	ImageOffset = squadColors,
	SkillList = { "MoonStriders_ApolloMortar" },
	SoundLocation = "/mech/distance/artillery/",
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
	Massive = true,
}