local this = {}

local mod = mod_loader.mods[modApi.currentMod]
local path = mod.resourcePath
local scriptPath = mod.scriptPath

local pilot = {
	Id = "Pilot_Luke",
	Personality = "Luke_Personality",
	Name = "Luke Skywalker",
	Sex = SEX_MALE,
	Skill = "Luke_ForceFocus",
	Voice = "/voice/ralph",
}

local dialog = require(path .. "scripts/pilots/dialog_luke")

function this:GetPilot()
	return pilot
end

function this:init(mod)
	-- Create the pilot
	CreatePilot(pilot)

	-- Add skill tooltip if pilotSkill_tooltip library is available
	mod.libs.pilotSkill_tooltip.Add(
		pilot.Skill,
		PilotSkill(
			"Force Focus",
			"First attack deals double damage if they did not attack last turn."
		)
	)
end

function this:load(modApiExt, options)
	-- Add ruled dialogs for Luke specific situations if needed
	modApiExt.dialog:addRuledDialog("Luke_ForceFocus_Used", {
			Odds = 75,
			{ main = "Luke_ForceFocus_Used" },
	})
end

-- Initialize GAME save data structure
local function initGameSaveData()
	if GAME == nil then
		GAME = {}
	end

	if GAME.starwars_luke == nil then
		GAME.starwars_luke = {}
	end

	if GAME.starwars_luke.attacked_this_turn == nil then
		GAME.starwars_luke.attacked_this_turn = {}
	end

	if GAME.starwars_luke.attacked_last_turn == nil then
		GAME.starwars_luke.attacked_last_turn = {}
	end
end

local function onModsLoaded()
	-- Hook into mission start to reset tracking
	modApi:addMissionStartHook(function(mission)
		initGameSaveData()
		GAME.starwars_luke.attacked_this_turn = {}
		GAME.starwars_luke.attacked_last_turn = {}
		for id = 0, 2 do
			GAME.starwars_luke.attacked_this_turn[id] = true
		end
	end)

	modApi:addNextTurnHook(function(mission)
		if Game:GetTeamTurn() == TEAM_PLAYER then
			initGameSaveData()
			-- Copy current turn's attack status to last turn
			GAME.starwars_luke.attacked_last_turn = {}
			for pawnId, attacked in pairs(GAME.starwars_luke.attacked_this_turn) do
				GAME.starwars_luke.attacked_last_turn[pawnId] = attacked
			end
			-- Reset this turn's tracking
			GAME.starwars_luke.attacked_this_turn = {}
		end
	end)

	modapiext:addSkillStartHook(function(mission, pawn, weaponId, p1, p2)
		if weaponId == "Move" or not pawn or not pawn:IsAbility(pilot.Skill) then
			return
		end

		initGameSaveData()
		local pawnId = pawn:GetId()

		-- Mark that this pawn attacked this turn
		GAME.starwars_luke.attacked_this_turn[pawnId] = true
	end)

	-- Hook to modify damage output (double damage if didn't attack last turn)
	modapiext:addSkillBuildHook(function(mission, pawn, weaponId, p1, p2, skillEffect)
		if weaponId  == "Move" or not pawn or not pawn:IsAbility(pilot.Skill) then
			return
		end
		
		initGameSaveData()
		local pawnId = pawn:GetId()
		
		-- Check if this pawn didn't attack last turn
		if not GAME.starwars_luke.attacked_last_turn[pawnId] then
			-- Double all damage in the skill effect
			local hasDoubledDamage = false

			for i = 1, skillEffect.effect:size() do
				local spaceDamage = skillEffect.effect:index(i)
				if spaceDamage.iDamage > 0 and spaceDamage.iDamage ~= DAMAGE_DEATH and 
						spaceDamage.iDamage ~= DAMAGE_ZERO then
					spaceDamage.iDamage = spaceDamage.iDamage * 2
					hasDoubledDamage = true
				end
			end
			
			-- Trigger dialog if we actually doubled some damage
			if hasDoubledDamage then
				-- Add script to trigger the dialog during execution
				-- Use AddScript on the first damage space to trigger it
				local firstDamage = skillEffect.effect:index(1)
				if firstDamage then
					firstDamage.sScript = firstDamage.sScript .. [[
						local cast = { main = ]]..pawnId..[[ }
						modapiext.dialog:triggerRuledDialog("Luke_ForceFocus_Used", cast)
					]]
				end
			end
		end
	end)
end

-- Add personality with dialog
local personality = mod.libs.personality:new{ Label = "Luke" }
personality:AddDialog(dialog)
Personality[pilot.Personality] = personality

-- Subscribe to events
modApi.events.onModsLoaded:subscribe(onModsLoaded)

return this
