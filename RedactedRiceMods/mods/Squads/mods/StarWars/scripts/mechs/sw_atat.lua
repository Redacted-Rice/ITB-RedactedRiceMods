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
	MoveSpeed = 0,
	Image = "sw_atat",
	ImageOffset = squadColors,
	SkillList = { "StarWars_HeavyCannons", "StarWars_Stomp" },
	SoundLocation = "/mech/science/pulse_mech/",
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
	Massive = true,
	Armor = false,
	Flying = false,
	IgnoreLiquid = true,
	IgnoreSmoke = true,
	-- Used for our custom mechFORGE upgrade
	ArmoredType = "StarWars_ATATMech_Armored",
	UnarmoredType = "StarWars_ATATMech",
}

-- Create the armored variation as the same as the original just with the
-- Armor flag set to true. Note this points to the original pawn still so
-- when we add the functions below, they will also be available to this
-- copy
StarWars_ATATMech_Armored = StarWars_ATATMech:new{
	Armor = true,
}

function StarWars_ATATMech.SetArmoredPawnType(pawn, armored)
	if not pawn then
		return
	end
	pawn:SetType(armored and StarWars_ATATMech.ArmoredType or StarWars_ATATMech.UnarmoredType)
end

function StarWars_ATATMech.RegisterArmoredUpgrade(mechType)
	mech_forge:registerMechUpgrade(mechType, mech_forge.VANILLA_UPGRADES.MOVE, "Armored",
		function(_, pawn)
			StarWars_ATATMech.SetArmoredPawnType(pawn, true)
		end,
		function(_, pawn)
			StarWars_ATATMech.SetArmoredPawnType(pawn, false)
		end
	)
end

StarWars_ATATMech.RegisterArmoredUpgrade("StarWars_ATATMech")
StarWars_ATATMech.RegisterArmoredUpgrade("StarWars_ATATMech_Armored")
