local resourcePath = mod_loader.mods[modApi.currentMod].resourcePath
local mechPath = resourcePath .. "img/mechs/"

local scriptPath = mod_loader.mods[modApi.currentMod].scriptPath
local mod = modApi:getCurrentMod()

local treeherdersColor = modApi:getPaletteImageOffset("treeherders_color")

local files = {
	"th_arbiformer.png",
	"th_arbiformer_a.png",
	"th_arbiformer_w.png",
	"th_arbiformer_w_broken.png",
	"th_arbiformer_broken.png",
	"th_arbiformer_ns.png",
	"th_arbiformer_h.png"
}

for _, file in ipairs(files) do
	modApi:appendAsset("img/units/player/" .. file, mechPath .. file)
end

local a = ANIMS
a.th_arbiformer =         a.MechUnit:new{Image = "units/player/th_arbiformer.png",          PosX = -22, PosY = -7 }
a.th_arbiformera =        a.MechUnit:new{Image = "units/player/th_arbiformer_a.png",        PosX = -22, PosY = -7, NumFrames = 4 }
a.th_arbiformerw =        a.MechUnit:new{Image = "units/player/th_arbiformer_w.png",        PosX = -22, PosY =  2 }
a.th_arbiformer_broken =  a.MechUnit:new{Image = "units/player/th_arbiformer_broken.png",   PosX = -22, PosY =  -5 }
a.th_arbiformerw_broken = a.MechUnit:new{Image = "units/player/th_arbiformer_w_broken.png", PosX = -22, PosY =  5 }
a.th_arbiformer_ns =      a.MechIcon:new{Image = "units/player/th_arbiformer_ns.png" }


Treeherders_ArbiformerMech = Pawn:new{
	Name = "Arbiformer",
	Class = "Science",
	Health = 2,
	MoveSpeed = 3,
	Image = "th_arbiformer",
	ImageOffset = treeherdersColor,
	SkillList = { "Treeherders_ViolentGrowth", "Treeherders_Passive_WakeTheForest" },
	SoundLocation = "/mech/science/pulse_mech/",
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
	Massive = true,
}