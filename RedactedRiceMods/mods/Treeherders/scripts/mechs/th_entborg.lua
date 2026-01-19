local resourcePath = mod_loader.mods[modApi.currentMod].resourcePath
local mechPath = resourcePath .. "img/mechs/"

local scriptPath = mod_loader.mods[modApi.currentMod].scriptPath
local mod = modApi:getCurrentMod()

local treeherdersColor = modApi:getPaletteImageOffset("treeherders_color")

local cyborg = mod_loader.currentModContent[mod.id].options["th_EntborgCyborg"].value
if cyborg == 1 then
	modApi:appendAsset("img/portraits/pilots/Pilot_Treeherders_EntborgMech.png", resourcePath.."img/portraits/pilots/Pilot_Treeherders_EntborgMech.png")
	modApi:appendAsset("img/portraits/pilots/Pilot_Treeherders_EntborgMech_2.png", resourcePath.."img/portraits/pilots/Pilot_Treeherders_EntborgMech_2.png")
	modApi:appendAsset("img/portraits/pilots/Pilot_Treeherders_EntborgMech_blink.png", resourcePath.."img/portraits/pilots/Pilot_Treeherders_EntborgMech_blink.png")
	CreatePilot{
		Id = "Pilot_Treeherders_EntborgMech",
		Name = "Ironbough",
		Personality = "Vek",
		Sex = SEX_VEK,
		Rarity = 0,
		GetSkill = function() IsEnt = true; return "Survive_Death" end,
		Blacklist = {"Invulnerable", "Popular"},
	}
end
	
-- Borrowed from Meta's Pokemon mod
-- Needs to be in global space so just define it anyways. Won't
-- cause issues if Entborg is not a cyborg
local oldGetSkillInfo = GetSkillInfo
function GetSkillInfo(skill)
	if IsEnt then
		IsEnt = nil
		return PilotSkill("Ent", "Normal Pilots cannot be equipped. Revives at the end of battle.")
	end
	return oldGetSkillInfo(skill)
end
	
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

local class = "TechnoVek"
if cyborg == 0 then
	class = "Prime"
end

Treeherders_EntborgMech = Pawn:new{	
	Name = "Entborg",
	Class = class,
	Health = 3,
	MoveSpeed = 4,
	Image = "th_entborg",
	ImageOffset = treeherdersColor,
	SkillList = { "Treeherders_Treevenge", "Treeherders_Overgrowth" },
	SoundLocation = "/mech/prime/punch_mech/",
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
	Massive = true,
}