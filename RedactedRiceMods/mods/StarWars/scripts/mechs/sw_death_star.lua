local resourcePath = mod_loader.mods[modApi.currentMod].resourcePath
local mechPath = resourcePath .. "img/mechs/"

local scriptPath = mod_loader.mods[modApi.currentMod].scriptPath
local mod = modApi:getCurrentMod()

local squadColors = modApi:getPaletteImageOffset("starwars_empire_color")

-- Temporarily use Millennium Falcon images
local files = {
	"sw_melfalcon.png",
	"sw_melfalcon_a.png",
	"sw_melfalcon_w_broken.png",
	"sw_melfalcon_broken.png",
	"sw_melfalcon_ns.png",
	"sw_melfalcon_h.png"
}

-- -x = left, +x = right
-- -y = up, +y - down
local a = ANIMS
a.sw_deathstar =         a.MechUnit:new{Image = "units/player/sw_melfalcon.png",          PosX = -19, PosY = -11 }
a.sw_deathstara =        a.MechUnit:new{Image = "units/player/sw_melfalcon_a.png",        PosX = -19, PosY = -11, NumFrames = 5 }
a.sw_deathstar_broken =  a.MechUnit:new{Image = "units/player/sw_melfalcon_broken.png",   PosX = -19, PosY = 1 }
a.sw_deathstarw_broken = a.MechUnit:new{Image = "units/player/sw_melfalcon_w_broken.png", PosX = -18, PosY = 4 }
a.sw_deathstar_ns =      a.MechIcon:new{Image = "units/player/sw_melfalcon_ns.png" }

-- Add orbital launch animation (reuse timetravel effect)
a.StarWars_DeathStarLaunch = Animation:new{
	Image = "effects/timetravel.png",
	NumFrames = 19,
	Loop = false,
	PosX = -32,
	Time = 0.02,
	PosY = -145,
}

-- Death Star custom repair: Orbital Strike that recharges weapons
StarWars_DeathStarRepair = Skill:new{
	Name = "Orbital Strike",
	Description = "Deal 1 damage to any tile on the board and recharge the Auxiliary Superlaser.",
	Icon = "weapons/repair.png",
	Class = "Science",
	PowerCost = 0,
	Upgrades = 0,
	TipImage = {
		CustomPawn = "StarWars_DeathStarMech",
		Unit = Point(2, 2),
		Enemy = Point(2, 1),
		Target = Point(2, 1),
	},
	LaunchSound = "/weapons/artillery_volley",
	ImpactSound = "/impact/generic/explosion",
	Projectile = "effects/shot_sw_superlaser",
}

function StarWars_DeathStarRepair:GetTargetArea(point)
	local ret = PointList()
	
	-- Can target any valid space on the board
	local size = Board:GetSize()
	for x = 0, size.x - 1 do
		for y = 0, size.y - 1 do
			local p = Point(x, y)
			if Board:IsValid(p) and p ~= point then
				ret:push_back(p)
			end
		end
	end
	
	return ret
end

function StarWars_DeathStarRepair:GetSkillEffect(p1, p2)
	local ret = SkillEffect()
	local pawn = Board:GetPawn(p1)
	
	if not pawn then
		return ret
	end
	
	-- Deal 1 damage to the target
	local damage = SpaceDamage(p2, 1)
	ret:AddArtillery(damage, self.Projectile, FULL_DELAY)
	ret:AddBounce(p2, 2)
	
	-- Recharge the Auxiliary Superlaser
	local weapons = pawn:GetBaseWeaponTypes()
	for wIdx = 1, 2 do
		local weaponId = weapons[wIdx]
		if weaponId and weaponId:find("StarWars_AuxiliarySuperlaser") then
			local maxUses = _G[weaponId].Limited or 1
			ret:AddScript(string.format([[
				local pawn = Board:GetPawn(%s)
				if pawn then
					pawn:SetWeaponLimitedRemaining(%d, %d)
					Board:AddAlert(%s, "RECHARGED")
					Board:Ping(%s, GL_Color(0, 255, 255))
				end
			]], p1:GetString(), wIdx, maxUses, p1:GetString(), p1:GetString()))
			break
		end
	end
	
	return ret
end

-- Register the custom repair skill for Death Star
ReplaceRepair:addSkill{
	name = "Orbital Strike",
	description = "Deal 1 damage to any tile and recharge weapons.",
	weapon = "StarWars_DeathStarRepair",
	icon = "weapons/repair",
	mechType = "StarWars_DeathStarMech",
}

StarWars_DeathStarMech = Pawn:new{
	Name = "Death Star",
	Class = "Science",
	Health = 10,
	MoveSpeed = 0,
	Image = "sw_deathstar",
	ImageOffset = squadColors,
	SkillList = { "StarWars_AuxiliarySuperlaser", "StarWars_EmpireOfTerror" },
	SoundLocation = "/mech/distance/artillery/",
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
	SpaceColor = false,
	Massive = true,
	Flying = true,
	Orbital = true,
	OrbitalAnim = "StarWars_DeathStarLaunch",
	OrbitalSound = "/weapons/enhanced_tractor",
	OrbitalIcon = true,
}
