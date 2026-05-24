local resourcePath = mod_loader.mods[modApi.currentMod].resourcePath
local mechPath = resourcePath .. "img/units/player/"

local scriptPath = mod_loader.mods[modApi.currentMod].scriptPath
local mod = modApi:getCurrentMod()

local squadColors = modApi:getPaletteImageOffset("moonstriders_color")

local files = {
	"mech_falconet.png",
	"mech_falconet_a.png",
	"mech_falconet_w.png",
	"mech_falconet_w_broken.png",
	"mech_falconet_broken.png",
	"mech_falconet_ns.png",
	"mech_falconet_h.png"
}

for _, file in ipairs(files) do
	modApi:appendAsset("img/units/player/" .. file, mechPath .. file)
end

-- -x = left, +x = right
-- -y = up, +y - down
local a = ANIMS
a.mech_falconet =         a.MechUnit:new{Image = "units/player/mech_falconet.png",          PosX = -18, PosY = -12 }
a.mech_falconeta =        a.MechUnit:new{Image = "units/player/mech_falconet_a.png",        PosX = -18, PosY = -12, NumFrames = 4 }
a.mech_falconetw =        a.MechUnit:new{Image = "units/player/mech_falconet_w.png",        PosX = -20, PosY = -6 }
a.mech_falconet_broken =  a.MechUnit:new{Image = "units/player/mech_falconet_broken.png",   PosX = -18, PosY = -14 }
a.mech_falconetw_broken = a.MechUnit:new{Image = "units/player/mech_falconet_w_broken.png", PosX = -21, PosY = -7 }
a.mech_falconet_ns =      a.MechIcon:new{Image = "units/player/mech_falconet_ns.png" }


MoonStriders_FalconetMech = Pawn:new{	
	Name = "Falconet",
	Class = "Brute",
	Health = 3,
	Image = "mech_falconet",
	ImageOffset = 0,
	MoveSpeed = 3,
	SkillList = { "MoonStriders_ScorpioFalconet" },
	SoundLocation = "/mech/brute/tank/",
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
	Massive = true,
}