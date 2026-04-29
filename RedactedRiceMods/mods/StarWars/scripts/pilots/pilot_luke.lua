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

-- Register Force Focus icon animation
local function registerForceFocusIcon()
	ANIMS["sw_force_focus_repair"] = ANIMS.Animation:new{
		Image = "combat/icons/icon_sw_force_focus_glow.png",
		NumFrames = 1,
		Time = 1,
		Loop = true,
		PosX = -24,
		PosY = 18
	}
	ANIMS["sw_force_focus_dmg"] = ANIMS.Animation:new{
		Image = "combat/icons/icon_sw_force_focus_glow.png",
		NumFrames = 1,
		Time = 1,
		Loop = true,
		PosX = 4,
		PosY = 8
	}
end

function this:GetPilot()
	return pilot
end

-- Initialize GAME save data structure
function this:initGameSaveData()
	if GAME == nil then
		GAME = {}
	end

	if GAME.starwars_luke == nil then
		GAME.starwars_luke = {}
	end

	if GAME.starwars_luke.force_focused == nil then
		GAME.starwars_luke.force_focused = {}
	end
	if GAME.starwars_luke.force_focused_last == nil then
		GAME.starwars_luke.force_focused_last = {}
	end
end

-- Luke's Force Focus Repair Skill
Luke_ForceFocus_Repair = Skill_Repair:new{
	Name = "Force Focus",
	Description = "Repair, gain boost, and deal double damage (before boost) next turn",
	TipImage = {
		Unit = Point(2, 2),
		Target = Point(2, 2),
	}
}

function Luke_ForceFocus_Repair:GetSkillEffect(p1, p2)
	-- We can't use the base repair effect so manually
	-- create it
	local ret = SkillEffect()
	local repairDamage = SpaceDamage(p2, -1)
	if Board:IsAcid(p1) then
		repairDamage.iFire = EFFECT_REMOVE
	end
	if Board:IsAcid(p1) then
		repairDamage.iAcid = EFFECT_REMOVE
	end

	-- Add Force Focus icon animation
	WeaponPreview:AddAnimation(p1, "sw_force_focus_repair")

	-- This causes crashes in tool tip and we don't to set the
	-- save value so just do something real simple in tool tip
	if not Board:IsTipImage() then
		repairDamage.sScript = repairDamage.sScript .. [[
				local pawnId = ]] .. Board:GetPawn(p1):GetId() .. [[
				-- Initialize data
				Pilot_Luke_Ref:initGameSaveData()

				GAME.starwars_luke.force_focused[pawnId] = true

				-- trigger a dialog
				local cast = { main = pawnId }
				modapiext.dialog:triggerRuledDialog("Luke_ForceFocused", cast)
				modApi:runLater(function()
					Board:GetPawn(]]..p1:GetString()..[[):SetBoosted(true)
				end)
		]]
	else
		repairDamage.sScript = repairDamage.sScript .. [[
				Board:GetPawn(]]..p1:GetString()..[[):SetBoosted(true)
		]]
	end
	ret:AddDamage(repairDamage)

	return ret
end

-- Helper to double damage in a damage list
local function doubleDamageInEffect(damageList, pawnId, previewState)
	local hasDoubledDamage = false

	for i = 1, damageList:size() do
		local spaceDamage = damageList:index(i)

		if spaceDamage.iDamage > 0 and
				spaceDamage.iDamage ~= DAMAGE_DEATH and
				spaceDamage.iDamage ~= DAMAGE_ZERO then
			spaceDamage.iDamage = spaceDamage.iDamage * 2
			hasDoubledDamage = true

			WeaponPreview.ExecuteWithState(previewState,
					function()
						WeaponPreview:AddAnimation(spaceDamage.loc,"sw_force_focus_dmg")
					end)
		end
	end

	return hasDoubledDamage
end

-- Skill build hook to double damage when force focused
local function processSkills(pawn, previewState, skillEffect)
	-- Skip nested calls to prevent modifying more than once
	if modApiExt_internal.nestedCall_GetSkillEffect or modApiExt_internal.nestedCall_GetFinalEffect then
		return
	end

	-- If luke is not the pilot, then return
	if not pawn or not pawn:IsAbility(pilot.Skill) then
		return
	end

	Pilot_Luke_Ref:initGameSaveData()
	local pawnId = pawn:GetId()

	-- Check if this pawn is force focused last turn
	if GAME.starwars_luke.force_focused_last[pawnId] then
		-- Double all damage in the skill effect and add Force Focus icon
		local hasDoubledDamage = doubleDamageInEffect(skillEffect.effect, pawnId, previewState)

		-- Trigger dialog if we actually doubled some damage
		if hasDoubledDamage then
			local firstDamage = skillEffect.effect:index(1)
			if firstDamage then
				firstDamage.sScript = (firstDamage.sScript or "") .. [[
					local cast = { main = ]]..pawnId..[[ }
					modapiext.dialog:triggerRuledDialog("Luke_ForceFocus_Used", cast)
				]]
			end
		end
	end
end

function this:init(mod)
	-- Register Force Focus icon animation
	registerForceFocusIcon()

	-- Create the pilot
	CreatePilot(pilot)

	-- Add skill tooltip if pilotSkill_tooltip library is available
	mod.libs.pilotSkill_tooltip.Add(
		pilot.Skill,
		PilotSkill(
			"Force Focus",
			"When repairing, gain boosted and next turn your attacks deal double damage (before boost)."
		)
	)

	-- Add the modified repair skill
	ReplaceRepair:addSkill({
		weapon = "Luke_ForceFocus_Repair",
		icon = "img/weapons/luke_repair.png",
		IsActive = function(pawn)
			return pawn:IsAbility("Luke_ForceFocus")
		end
	})
end

function this:load(modApiExt, options)
	-- Add ruled dialogs for Luke
	modApiExt.dialog:addRuledDialog("Luke_ForceFocused", {
			Odds = 75,
			{ main = "Luke_ForceFocused" },
	})
	modApiExt.dialog:addRuledDialog("Luke_ForceFocus_Used", {
			Odds = 75,
			{ main = "Luke_ForceFocus_Used" },
	})
end

local function onModsLoaded()
	-- Hook into mission start to reset tracking
	modApi:addMissionStartHook(function(mission)
		Pilot_Luke_Ref:initGameSaveData()
		GAME.starwars_luke.force_focused = {}
		GAME.starwars_luke.force_focused_last = {}
	end)

	modApi:addNextTurnHook(function(mission)
		if Game:GetTeamTurn() == TEAM_PLAYER then
			Pilot_Luke_Ref:initGameSaveData()
			GAME.starwars_luke.force_focused_last = GAME.starwars_luke.force_focused
			-- Clear force focus flags at start of turn
			GAME.starwars_luke.force_focused = {}
		end
	end)

	-- Hook to modify damage output in both skill effect and final effect
	modapiext:addSkillBuildHook(function(mission, pawn, weaponId, p1, p2, skillEffect)
		processSkills(pawn, WeaponPreview.STATE_SKILL_EFFECT, skillEffect)
	end)
	modapiext.events.onFinalEffectBuild:subscribe(function(mission, pawn, weaponId, p1, p2, p3, skillEffect)
		processSkills(pawn, WeaponPreview.STATE_FINAL_EFFECT, skillEffect)
	end)
end

-- Add personality with dialog
local personality = mod.libs.personality:new{ Label = "Luke" }
personality:AddDialog(dialog)
Personality[pilot.Personality] = personality

-- Subscribe to events
modApi.events.onModsLoaded:subscribe(onModsLoaded)

Pilot_Luke_Ref = this
return Pilot_Luke_Ref
