local resourcePath = mod_loader.mods[modApi.currentMod].resourcePath
local mechPath = resourcePath .. "img/mechs/"

local scriptPath = mod_loader.mods[modApi.currentMod].scriptPath
local mod = modApi:getCurrentMod()

local squadColors = modApi:getPaletteImageOffset("starwars_empire_color")

-- Temporarily use Snow Speeder images
local files = {
	"sw_atat.png",
	"sw_atat_a.png",
	"sw_atat_broken.png",
	"sw_atatw_broken.png",
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
a.sw_atat_broken =  a.MechUnit:new{Image = "units/player/sw_atat_broken.png", PosX = -14, PosY = -8 }
a.sw_atatw_broken = a.MechUnit:new{Image = "units/player/sw_atatw_broken.png", PosX = -14, PosY = -8 }
a.sw_atat_ns =      a.MechIcon:new{Image = "units/player/sw_atat_ns.png" }


local baseType = "StarWars_ATATMech"
local armoredSuffix = "_Armored"
local insulatedSuffix = "_Insulated"
local forgeTypes = {
	Base = baseType,
	Armored = baseType .. armoredSuffix,
	Insulated = baseType .. insulatedSuffix,
	Both = baseType .. armoredSuffix .. insulatedSuffix,
}

_G[baseType] = Pawn:new{
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
	Armor = false,
	Flying = false,
	IgnoreLiquid = true,
	IgnoreSmoke = true,

	FORGE_PAWN_TYPES = forgeTypes,
	ARMORED_SUFFIX = armoredSuffix,
	INSULATED_SUFFIX = insulatedSuffix,
}

-- Create the variations as the same as the original just with the
-- specific flags set to true. Note this points to the original pawn still so
-- when we add the functions below, they will also be available to this
-- copy
_G[forgeTypes.Armored] = _G[baseType]:new{
	Armor = true,
}

_G[forgeTypes.Insulated] = _G[baseType]:new{
	IgnoreFire = true,
}

_G[forgeTypes.Both] = _G[forgeTypes.Armored]:new{
	IgnoreFire = true,
}

Weapon_Texts.StarWars_ATAT_Armored_Tooltip = "When Powered, AT-AT gains Armor"
Weapon_Texts.StarWars_ATAT_Insulated_Tooltip = "When Powered, AT-AT is immune to fire"

_G[baseType].isATATPawnType = function(mechType)
	return mechType and mechType:sub(1, #baseType) == baseType
end

_G[baseType].ApplyForgePawnType = function(pawn)
	if not pawn or not _G[baseType].isATATPawnType(pawn:GetType()) then
		return
	end

	local mechType = baseType
	if mech_forge:isMechUpgradePowered(pawn, mech_forge.VANILLA_UPGRADES.HEALTH) then
		mechType = mechType .. armoredSuffix
	end
	if mech_forge:isMechUpgradePowered(pawn, mech_forge.VANILLA_UPGRADES.MOVE) then
		mechType = mechType .. insulatedSuffix
	end

	pawn:SetType(mechType)
end

_G[baseType].RegisterForgeUpgrades = function(mechType)
	mech_forge:registerMechUpgrade(mechType, mech_forge.VANILLA_UPGRADES.MOVE, {
		label = "Thermal Venting",
		tooltip = "StarWars_ATAT_Insulated_Tooltip",
		onPowered = function(_, pawn)
			_G[baseType].ApplyForgePawnType(pawn)
		end,
		onUnpowered = function(_, pawn)
			_G[baseType].ApplyForgePawnType(pawn)
		end,
	})
	mech_forge:registerMechUpgrade(mechType, mech_forge.VANILLA_UPGRADES.HEALTH, {
		label = "Heavy Plating",
		tooltip = "StarWars_ATAT_Armored_Tooltip",
		onPowered = function(_, pawn)
			_G[baseType].ApplyForgePawnType(pawn)
		end,
		onUnpowered = function(_, pawn)
			_G[baseType].ApplyForgePawnType(pawn)
		end,
	})
end

for _, mechType in pairs(_G[baseType].FORGE_PAWN_TYPES) do
	_G[baseType].RegisterForgeUpgrades(mechType)
end
