local resourcePath = mod_loader.mods[modApi.currentMod].resourcePath
local mechPath = resourcePath .. "img/mechs/"

local scriptPath = mod_loader.mods[modApi.currentMod].scriptPath
local mod = modApi:getCurrentMod()

local squadColors = modApi:getPaletteImageOffset("starwars_empire_color")

-- Temporarily use Snow Speeder images
local files = {
	"sw_atat.png",
	"sw_atat_a.png",
	"sw_atat_ns.png",
	"sw_atat_h.png",
}

for _, file in ipairs(files) do
	modApi:appendAsset("img/units/player/" .. file, mechPath .. file)
end

-- -x = left, +x = right
-- -y = up, +y - down
local a = ANIMS
a.sw_atat =         a.MechUnit:new{Image = "units/player/sw_atat.png", PosX = -14, PosY = -8 }
a.sw_atata =        a.MechUnit:new{Image = "units/player/sw_atat_a.png", PosX = -14, PosY = -8, NumFrames = 6 }
a.sw_atat_broken =  a.MechUnit:new{Image = "units/player/sw_atat.png", PosX = -14, PosY = -8 }
a.sw_atatw_broken = a.MechUnit:new{Image = "units/player/sw_atat.png", PosX = -14, PosY = -8 }
a.sw_atat_ns =      a.MechIcon:new{Image = "units/player/sw_atat_ns.png" }


StarWars_ATATMech = Pawn:new{
	Name = "AT-AT Walker",
	Class = "Ranged",
	Health = 3,
	MoveSpeed = 2,
	Image = "sw_atat",
	ImageOffset = squadColors,
	SkillList = { "StarWars_HeavyCannons", "StarWars_Stomp" },
	SoundLocation = "/mech/science/pulse_mech/",
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
	Massive = true,
	Armor = true,
	Flying = false,
}
