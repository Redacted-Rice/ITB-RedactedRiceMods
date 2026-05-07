StarWars_RebelHope = PassiveSkill:new{
	Name = "Rebel Hope",
	Description = "The first time a mech would die each mission, it is revived with 1 HP.",
	Class = "Science",
	PowerCost = 0,
	Upgrades = 1,
	UpgradeCost = {1},
	Icon = "weapons/science_sw_rebel_hope.png",
	BoostAllies = false,
	-- This doesn't work right but the image display is fine so leaving it
	TipImage = {
		CustomPawn = "StarWars_MelFalconMech",
		Unit = Point(2, 1),
		CustomPawn = "Scorpion2",
		Enemy = Point(2, 2),
	},
}

local mod = mod_loader.mods[modApi.currentMod]
passiveEffect = mod_loader.mods[modApi.currentMod].libs.passiveEffect

local REBEL_HOPE_COLOR = GL_Color(255, 0, 0)

-- Initialize GAME save data structure
local function initGameSaveData()
	if GAME == nil then
		GAME = {}
	end

	if GAME.starwars == nil then
		GAME.starwars = {}
	end

	if GAME.starwars.rebel_hope == nil then
		GAME.starwars.rebel_hope = {}
	end

	if GAME.starwars.rebel_hope.used == nil then
		GAME.starwars.rebel_hope.used = false
	end
end

-- Helper function to check if a pawn has Rebel Hope equipped
local function pawnHasRebelHope(pawn)
	if not pawn or not pawn:IsMech() then return false end
	return mod.libs.passiveEffect:countAnyVersionOfPassiveActive("StarWars_RebelHope") > 0
end

-- Add stateful trait icon showing active vs used state
mod.libs.traitReplace:addStateful{
	targetTrait = "massive",
	func = function(trait, pawn)
		if not pawnHasRebelHope(pawn) then
			return 0  -- Don't display
		end
		initGameSaveData()
		if GAME.starwars.rebel_hope.used == true then
			return 2  -- Used state
		else
			return 1  -- Active state
		end
	end,
	states = {
		{
			icon = "img/combat/icons/icon_sw_rebel_hope.png",
			desc_title = "Rebel Hope (Active)",
			desc_text = "The next time a mech would die, it is revived with 1 HP.",
		},
		{
			icon = "img/combat/icons/icon_sw_rebel_hope_used.png",
			desc_title = "Rebel Hope (Used)",
			desc_text = "A mech has already been revived this mission.",
		},
	}
}

-- Weapon text definitions
Weapon_Texts.StarWars_RebelHope_Upgrade1 = "Boost Allies"
Weapon_Texts.StarWars_RebelHope_A_UpgradeDescription = "When revived by this skill, all allies gain Boosted."
StarWars_RebelHope_A = StarWars_RebelHope:new{
	BoostAllies = true,
}

-- Function just for showing in the tool tip
function StarWars_RebelHope:GetSkillEffect(p1, p2)
	local ret = SkillEffect()

	local spaceDamage = SpaceDamage(Point(2, 2), 3)
	spaceDamage.sAnimation = "SwipeClaw2"
	spaceDamage.sSound = "/enemy/scorpion_soldier_2/attack"
	ret:AddMelee(Point(2, 1), spaceDamage)

	ret:AddDelay(0.7)

	-- Show healing
	local healDamage = SpaceDamage(Point(2, 2), -1)
	healDamage.bHide = true
	ret:AddDamage(healDamage)

	ret:AddDelay(2)

	return ret
end

-- Mission start hook
function StarWars_RebelHope:GetPassiveSkillEffect_MissionStartHook(mission)
	initGameSaveData()
	GAME.starwars.rebel_hope.used = false
end

-- Pawn killed hook - triggers revive
function StarWars_RebelHope:GetPassiveSkillEffect_PawnKilledHook(mission, pawn)
	initGameSaveData()

	-- Only trigger if not already used this mission and a player mech died
	if GAME.starwars.rebel_hope.used then
		return
	end
	if not pawn:IsMech() or pawn:GetTeam() ~= TEAM_PLAYER then
		return
	end

	-- Check if any mech has Rebel Hope active
	if passiveEffect:countAnyVersionOfPassiveActive("StarWars_RebelHope") > 0 then
		-- Mark as used
		GAME.starwars.rebel_hope.used = true

		-- Revive the pawn to 1 HP using the repair skill effect
		local pawnSpace = pawn:GetSpace()
		local repairSkill = _G["Skill_Repair"]
		-- Use repair to bring back to 1 HP
		local repair = repairSkill:GetSkillEffect(pawnSpace, pawnSpace)
		Board:AddEffect(repair)
		Board:AddAlert(pawn:GetSpace(), "REBEL HOPE")
		Board:Ping(pawn:GetSpace(), REBEL_HOPE_COLOR)

		-- Check if the upgrade is active and boost if so
		if passiveEffect:isPassiveActive("StarWars_RebelHope_A") then
			local pawns = extract_table(Board:GetPawns(TEAM_PLAYER))
			for _, id in ipairs(pawns) do
				Board:GetPawn(id):SetBoosted(true)
			end
		end
	end
end

-- Register the passive effect
passiveEffect:addPassiveEffect(
	"StarWars_RebelHope",
	{"missionStartHook", "pawnKilledHook"}
)