local resourcePath = mod_loader.mods[modApi.currentMod].resourcePath
local mechPath = resourcePath .. "img/mechs/"

local scriptPath = mod_loader.mods[modApi.currentMod].scriptPath
local mod = modApi:getCurrentMod()

local treeherdersColor = modApi:getPaletteImageOffset("treeherders_color")

local files = {
	"th_entborg.png",
	"th_entborg_a.png",
	"th_entborg_w.png",
	"th_entborg_w_broken.png",
	"th_entborg_broken.png",
	"th_entborg_ns.png",
	"th_entborg_h.png"
}

for _, file in ipairs(files) do
	modApi:appendAsset("img/units/player/" .. file, mechPath .. file)
end

local a = ANIMS
a.th_entborg =         a.MechUnit:new{Image = "units/player/th_entborg.png",          PosX = -17, PosY = -8 }
a.th_entborga =        a.MechUnit:new{Image = "units/player/th_entborg_a.png",        PosX = -17, PosY = -8, NumFrames = 4 }
a.th_entborgw =        a.MechUnit:new{Image = "units/player/th_entborg_w.png",        PosX = -17, PosY = 5 }
a.th_entborg_broken =  a.MechUnit:new{Image = "units/player/th_entborg_broken.png",   PosX = -17, PosY =  -8 }
a.th_entborgw_broken = a.MechUnit:new{Image = "units/player/th_entborg_w_broken.png", PosX = -17, PosY =  1 }
a.th_entborg_ns =      a.MechIcon:new{Image = "units/player/th_entborg_ns.png" }


Treeherders_EntborgMech = Pawn:new{	
	Name = "Entborg",
	Class = "Prime",
	Health = 3,
	MoveSpeed = 4,
	Image = "th_entborg",
	ImageOffset = treeherdersColor,
	SkillList = { "Treeherders_Treevenge" },
	SoundLocation = "/mech/prime/punch_mech/",
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
	Massive = true,
}