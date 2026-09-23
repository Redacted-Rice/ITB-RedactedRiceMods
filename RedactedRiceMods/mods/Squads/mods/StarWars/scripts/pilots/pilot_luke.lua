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

	if GAME.starwars == nil then
		GAME.starwars = {}
	end

	if GAME.starwars.force_focused == nil then
		GAME.starwars.force_focused = {}
	end
end

-- Luke's Force Focus Repair Skill
Luke_ForceFocus_Repair = Skill_Repair:new{
	Name = "Force Focus",
	Description = "Repair, gain boost, and deal double damage (before boost) on next attack",
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
	local pawn = Board:GetPawn(p1)
	if pawn:IsFire() then
		repairDamage.iFire = EFFECT_REMOVE
	end
	if pawn:IsAcid() then
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

				GAME.starwars.force_focused[pawnId] = true

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
local function processSkills(pawn, weaponId, previewState, skillEffect)
	if weaponId == "Move" or weaponId == "Skill_Repair" or weaponId == "Luke_ForceFocus_Repair" then
		return
	end

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

	-- Check if this pawn has force focus active
	if GAME.starwars.force_focused[pawnId] then
		-- Double all damage in the skill effect and add Force Focus icon
		local hasDoubledDamage = doubleDamageInEffect(skillEffect.effect, pawnId, previewState)

		-- Clear force focus after use and trigger dialog
		local firstDamage = skillEffect.effect:index(1)
		if firstDamage then
			-- Clear out the force focus
			firstDamage.sScript = (firstDamage.sScript or "") .. [[
				local pawnId = ]] .. pawnId .. [[
				Pilot_Luke_Ref:initGameSaveData()
				GAME.starwars.force_focused[pawnId] = nil
			]]

			-- Only trigger dialog if we actually doubled some damage
			if hasDoubledDamage then
				firstDamage.sScript = firstDamage.sScript .. [[
					-- Trigger dialog
					local cast = { main = pawnId }
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

	-- Add the modified repair skill
	ReplaceRepair:addSkill({
		name = "Force Focus",
		description = "When repairing, gain boosted and your next attack deals double damage (before boost).",
		weapon = "Luke_ForceFocus_Repair",
		icon = "img/weapons/luke_repair.png",
		pilotSkill = pilot.Skill
	})

	-- Add trait for force focused state
	mod.libs.trait:add({
		func = function(trait, pawn, loc)
			if not pawn or not pawn:IsAbility(pilot.Skill) then
				return false
			end
			Pilot_Luke_Ref:initGameSaveData()
			return GAME.starwars.force_focused[pawn:GetId()] == true
		end,
		icon = "img/combat/icons/icon_sw_force_focus.png",
		icon_glow = "img/combat/icons/icon_sw_force_focus_glow.png",
		desc = {
			title = "Force Focused",
			text = "This unit's next attack will deal double damage (before boost)."
		}
	})
end

function this:load(options, version)
	-- Add ruled dialogs for Luke
	modapiext.dialog:addRuledDialog("Luke_ForceFocused", {
			Odds = 75,
			{ main = "Luke_ForceFocused" },
	})
	modapiext.dialog:addRuledDialog("Luke_ForceFocus_Used", {
			Odds = 75,
			{ main = "Luke_ForceFocus_Used" },
	})

	-- Hook into mission start to reset force focus tracking
	modApi:addMissionStartHook(function(mission)
		self:initGameSaveData()
		GAME.starwars.force_focused = {}
	end)

	-- Hook to modify damage output in both skill effect and final effect
	modapiext:addSkillBuildHook(function(mission, pawn, weaponId, p1, p2, skillEffect)
		processSkills(pawn, weaponId, WeaponPreview.STATE_SKILL_EFFECT, skillEffect)
	end)
	modapiext:addFinalEffectBuildHook(function(mission, pawn, weaponId, p1, p2, p3, skillEffect)
		processSkills(pawn, weaponId, WeaponPreview.STATE_FINAL_EFFECT, skillEffect)
	end)
end

-- Add personality with dialog
local personality = mod.libs.personality:new{ Label = "Luke" }
personality:AddDialog(dialog)
Personality[pilot.Personality] = personality

Pilot_Luke_Ref = this
return Pilot_Luke_Ref
