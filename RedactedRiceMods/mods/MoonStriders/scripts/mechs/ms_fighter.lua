local resourcePath = mod_loader.mods[modApi.currentMod].resourcePath
local mechPath = resourcePath .. "img/units/player/"

local scriptPath = mod_loader.mods[modApi.currentMod].scriptPath
local mod = modApi:getCurrentMod()

local squadColors = modApi:getPaletteImageOffset("moonstriders_color")

local files = {
	"mech_fighter.png",
	"mech_fighter_a.png",
	"mech_fighter_w_broken.png",
	"mech_fighter_broken.png",
	"mech_fighter_ns.png",
	"mech_fighter_h.png"
}

for _, file in ipairs(files) do
	modApi:appendAsset("img/units/player/" .. file, mechPath .. file)
end

-- -x = left, +x = right
-- -y = up, +y - down
local a = ANIMS
a.mech_fighter =         a.MechUnit:new{Image = "units/player/mech_fighter.png",          PosX = -21, PosY = -10 }
a.mech_fightera =        a.MechUnit:new{Image = "units/player/mech_fighter_a.png",        PosX = -21, PosY = -10, NumFrames = 5 }
a.mech_fighter_broken =  a.MechUnit:new{Image = "units/player/mech_fighter_broken.png",   PosX = -22, PosY = -13 }
a.mech_fighterw_broken = a.MechUnit:new{Image = "units/player/mech_fighter_w_broken.png", PosX = -22, PosY = -5 }
a.mech_fighter_ns =      a.MechIcon:new{Image = "units/player/mech_fighter_ns.png" }


MoonStriders_FighterMech = Pawn:new{	
	Name = "Fighter",
	Class = "Prime",
	Health = 3,
	MoveSpeed = 3,
	Image = "mech_fighter",
	ImageOffset = 0,
	SkillList = { "MoonStriders_ColossusHook" }, --Prime_Punchmech
	SoundLocation = "/mech/prime/punch_mech/",
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
	Massive = true,
}