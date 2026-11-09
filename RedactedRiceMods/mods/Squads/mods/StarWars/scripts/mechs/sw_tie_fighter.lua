local resourcePath = mod_loader.mods[modApi.currentMod].resourcePath
local mechPath = resourcePath .. "img/mechs/"

local mod = modApi:getCurrentMod()
local modTable = mod_loader.mods[modApi.currentMod]
local customEmitter = modTable.libs.customEmitter

local squadColors = modApi:getPaletteImageOffset("starwars_empire_color")

-- Temporarily use X-Wing images
local files = {
	"sw_tie_fighter.png",
	"sw_tie_fighter_a.png",
	"sw_tie_fighterw_broken.png",
	"sw_tie_fighter_broken.png",
	"sw_tie_fighter_ns.png",
	"sw_tie_fighter_h.png",
}

for _, file in ipairs(files) do
	modApi:appendAsset("img/units/player/" .. file, mechPath .. file)
end

-- -x = left, +x = right
-- -y = up, +y - down
local a = ANIMS
a.sw_tiefighter =         a.MechUnit:new{Image = "units/player/sw_tie_fighter.png", PosX = -19, PosY = -15 }
a.sw_tiefightera =        a.MechUnit:new{Image = "units/player/sw_tie_fighter_a.png", PosX = -19, PosY = -15, NumFrames = 6 }
a.sw_tiefighter_broken =  a.MechUnit:new{Image = "units/player/sw_tie_fighter_broken.png", PosX = -20, PosY = -12 }
a.sw_tiefighterw_broken = a.MechUnit:new{Image = "units/player/sw_tie_fighterw_broken.png", PosX = -21, PosY = -4 }
a.sw_tiefighter_ns =      a.MechIcon:new{Image = "units/player/sw_tie_fighter_ns.png" }

-- Create an animation for the tie fighter wreck on the ground
-- TODO later: update when I make the image
modApi:appendAsset(
	"img/combat/sw_tie_fighter_rubble.png",
	mod.resourcePath .. "img/combat/sw_tie_fighter_rubble.png"
)
modApi:createAnimations{
	sw_tie_fighter_rubble_anim = {
		Image = "combat/sw_tie_fighter_rubble.png",
		NumFrames = 1,
		Loop = true,
		Layer = LAYER_FLOOR,
		PosX = -18,
		PosY = -5,
	},
}

-- Smoke from wreck
Emitter_TIEWreck = Emitter:new{
	image = "combat/pod/pod_smoke.png",
	max_alpha = 0.1,
	x = 0,
	y = 15,
	variance_x = 1,
	variance_y = 5,
	angle = 255,
	angle_variance = 10,
	timer = 1,
	birth_rate = 0.6,
	burst_count = 0,
	max_particles = 32,
	speed = 0.50,
	lifespan = 2.5,
	rot_speed = 10,
	gravity = false,
	fade_in = true,
	layer = LAYER_FRONT,
}

local baseType = "StarWars_TIEFighterMech"

StarWars_TIEFighterMech = Pawn:new{
	Name = "TIE Fighter",
	Class = "Brute",
	Health = 1,
	MoveSpeed = 3,
	Image = "sw_tiefighter",
	ImageOffset = squadColors,
	SkillList = { "StarWars_DualCannons", "StarWars_TieOverdrive" },
	SoundLocation = "/mech/prime/punch_mech/",
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
	Massive = true,
	Flying = true,
}

Weapon_Texts.StarWars_TIEFighter_AssemblyLineA_Tooltip =
		"When powered, When the TIE Fighter is killed, deploy a new TIE Fighter with a clone of the same pilot to a random space. Stacks"
Weapon_Texts.StarWars_TIEFighter_AssemblyLineB_Tooltip =
		Weapon_Texts.StarWars_TIEFighter_AssemblyLineA_Tooltip

mech_forge:registerMechUpgrade(baseType, mech_forge.VANILLA_UPGRADES.HEALTH, {
	label = "Cloning Bay A",
	tooltip = "StarWars_TIEFighter_AssemblyLineA_Tooltip",
})
mech_forge:registerMechUpgrade(baseType, mech_forge.VANILLA_UPGRADES.MOVE, {
	label = "Cloning Bay B",
	tooltip = "StarWars_TIEFighter_AssemblyLineB_Tooltip",
})

function StarWars_TIEFighterMech.isTieFighter(pawn)
	return pawn and pawn:GetType() == baseType
end

function StarWars_TIEFighterMech.initGameSaveData()
	GAME = GAME or {}
	GAME.starwars = GAME.starwars or {}
	GAME.starwars.assembly_line = GAME.starwars.assembly_line or {}
	GAME.starwars.assembly_line.uses = GAME.starwars.assembly_line.uses or {}
end

function StarWars_TIEFighterMech.resetAssemblyLineUses()
	StarWars_TIEFighterMech.initGameSaveData()
	GAME.starwars.assembly_line.uses = {}
end

function StarWars_TIEFighterMech.determinMaxAssemblyLineUses(pawn)
	if not StarWars_TIEFighterMech.isTieFighter(pawn) then
		return 0
	end
	local max = 0
	if mech_forge:isMechUpgradePowered(pawn, mech_forge.VANILLA_UPGRADES.HEALTH) then
		max = max + 1
	end
	if mech_forge:isMechUpgradePowered(pawn, mech_forge.VANILLA_UPGRADES.MOVE) then
		max = max + 1
	end
	return max
end

function StarWars_TIEFighterMech.getAssemblyUsesRemaining(pawn)
	if not pawn then
		return 0
	end
	StarWars_TIEFighterMech.initGameSaveData()
	local max = StarWars_TIEFighterMech.determinMaxAssemblyLineUses(pawn)
	local used = GAME.starwars.assembly_line.uses[pawn:GetId()] or 0
	return math.max(0, max - used)
end

-- Pilot names are only allowed to be 14. If you force it longer,
-- it just shows the "second line" 
StarWars_TIEFighterMech.MAX_PILOT_DISPLAY_NAME_LEN = 14

function StarWars_TIEFighterMech.assemblyLineRenamePilotForNewChassis(pawn)
	local pilot = pawn and pawn:GetPilot()
	if not pilot then
		return
	end
	local current = pilot:getNameStr() or ""
	local base, numStr = string.match(current, "^(.*) #(%d+)$")
	local newNum
	if numStr then
		newNum = tonumber(numStr, 10) + 1
	else
		base = current
		newNum = 2
	end

	-- Add the suffix and see if it fits
	local suffixPlain = string.format(" #%d", newNum)
	local newName = base .. suffixPlain
	if #newName <= StarWars_TIEFighterMech.MAX_PILOT_DISPLAY_NAME_LEN then
		pilot:setName(newName)
		return
	end

	-- if it doesn't fit, truncate the base down and add a "." too
	local suffixDot = string.format(". #%d", newNums)
	local maxBase = StarWars_TIEFighterMech.MAX_PILOT_DISPLAY_NAME_LEN - #suffixDot
	if maxBase < 1 then
		maxBase = 1
	end
	newName = string.sub(base, 1, maxBase) .. suffixDot
	pilot:setName(newName)
end

function StarWars_TIEFighterMech.respawnTieFighterWhenNotBusy(pawn)
	if Board:IsBusy() then
		modApi:runLater(function()
			StarWars_TIEFighterMech.respawnTieFighterWhenNotBusy(pawn)
		end)
		return
	end

	if not Board then
		return
	end

	local pawnId = pawn:GetId()
	local deadPawn = Board:GetPawn(pawnId)
	if not deadPawn or not deadPawn:IsDead() then
		return
	end
	StarWars_TIEFighterMech.initGameSaveData()
	if StarWars_TIEFighterMech.getAssemblyUsesRemaining(deadPawn) <= 0 then
		return
	end

	local dest = BoardUtils.pickRandomSafeSpawnTile(PATH_FLYER, pawnId)
	if not dest then
		return
	end

	-- Save the location so we can add a wreck there
	local deathTile = deadPawn:GetSpace()

	GAME.starwars.assembly_line.uses[pawnId] = (GAME.starwars.assembly_line.uses[pawnId] or 0) + 1
	pawn:SetSpace(dest)
	pawn:Fall(0)
	pawn:SetHealth(pawn:GetMaxHealth())
	if Game:GetTeamTurn() == TEAM_PLAYER then
		pawn:SetActive(true)
		pawn:SetMovementSpent(false)
	end
	StarWars_TIEFighterMech.assemblyLineRenamePilotForNewChassis(pawn)
	Board:AddAlert(dest, "ASSEMBLY LINE")
	Board:Ping(dest, GL_Color(180, 180, 180))

	-- Add a wreck to where it came from
	Board:AddAnimation(deathTile, "sw_tie_fighter_rubble_anim", ANIM_NO_DELAY)
	local mission = GetCurrentMission()
	customEmitter:Add(mission, deathTile, "Emitter_TIEWreck")
end

function StarWars_TIEFighterMech.tryAssemblyLineRespawn(mission, pawn)
	if not Board or Board:IsTipImage() then
		return
	end

	if not StarWars_TIEFighterMech.isTieFighter(pawn) then
		return
	end

	StarWars_TIEFighterMech.initGameSaveData()
	if StarWars_TIEFighterMech.getAssemblyUsesRemaining(pawn) <= 0 then
		return
	end

	-- Delay so other death effects can resolve first (e.g. Rebel Hope)
	modApi:runLater(function()
		StarWars_TIEFighterMech.respawnTieFighterWhenNotBusy(pawn)
	end)
end

modTable.libs.traitReplace:addStateful{
	targetTrait = "massive",
	func = function(trait, pawn)
		if not StarWars_TIEFighterMech.isTieFighter(pawn) then
			return 0
		end
		local max = StarWars_TIEFighterMech.determinMaxAssemblyLineUses(pawn)
		if max <= 0 then
			return 0
		end
		local remaining = StarWars_TIEFighterMech.getAssemblyUsesRemaining(pawn)
		if remaining <= 0 then
			return 2
		end
		return 1
	end,
	states = {
		{
			icon = "img/combat/icons/icon_sw_cloning.png",
			desc_title = "Cloning Bay",
			desc_text = function(pawn)
				local remaining = StarWars_TIEFighterMech.getAssemblyUsesRemaining(pawn)
				return string.format("%d Clones and TIE Fighters on standby", remaining)
			end,
		},
		{
			icon = "img/combat/icons/icon_sw_cloning_depleted.png",
			desc_title = "Cloning Bay (Depleted)",
			desc_text = "No more Clones and TIE Fighters remaining",
		},
	},
}

function StarWars_TIEFighterMech.RegisterHooks()
	modApi:addMissionStartHook(StarWars_TIEFighterMech.resetAssemblyLineUses)
	modApi:addMissionNextPhaseCreatedHook(StarWars_TIEFighterMech.resetAssemblyLineUses)
	modapiext:addPawnKilledHook(StarWars_TIEFighterMech.tryAssemblyLineRespawn)
end
