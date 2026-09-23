--[[
PlusHelper - Small shared helpers for Pilot Level Up Skills (PLUS)

Libs Wiki: https://github.com/Redacted-Rice/ITB-RedactedRiceMods/wiki

Author: Das Keifer of Redacted Rice
Discord Server: https://discord.gg/CNjTVrpN4v
]]

local VERSION = "1.0.0"

-- Version check
local isNewestVersion = false
	or PlusHelper == nil
	or modApi:isVersionAbove(VERSION, PlusHelper.version)

if isNewestVersion then
	LOG("PlusHelper: Loading version " .. VERSION .. " (previous: "
			.. tostring(PlusHelper and PlusHelper.version or "none") .. ")")

	-- Initialize global singleton
	PlusHelper = PlusHelper or {}
	PlusHelper.version = VERSION

	-- Shared exclusion groups for More+ / Legendary+ and related mods
	PlusHelper.GROUPS = {
		ADD_GRID_DEF = "Add Grid Def",
		ADD_REACTOR = "Add Reactor",
		BOOST = "Boost",
		STATUS_BASED = "Status Based",
		REVIVE = "Revive",
		MOVE_TYPE = "Move Type",
		SHIELD = "Shield",
		ADD_DAMAGE = "Add Damage",
		ITEM_DROP = "Item Drop",
	}

	-- Shared preview group settings (More+ / Legendary+ consolidate on these)
	PlusHelper.GROUP_ID = "more_plus_levelup_skills"
	PlusHelper.QUEUED_GROUP_ID = "more_plus_levelup_skills_queued"
	PlusHelper.GROUP_OFFSET = Point(-25, 11)
	PlusHelper.QUEUED_GROUP_OFFSET = Point(-18, -4)

	function PlusHelper.convertPhase(phase)
		local damageModifierLib = DamageModifierLib
		local weaponPreview = WeaponPreview

		if phase == damageModifierLib.PHASE_NONE then
			return weaponPreview.STATE_NONE
		elseif phase == damageModifierLib.PHASE_SKILL_EFFECT then
			return weaponPreview.STATE_SKILL_EFFECT
		elseif phase == damageModifierLib.PHASE_TARGET_AREA then
			return weaponPreview.STATE_TARGET_AREA
		elseif phase == damageModifierLib.PHASE_QUEUED_SKILL then
			return weaponPreview.STATE_QUEUED_SKILL
		elseif phase == damageModifierLib.PHASE_SECOND_TARGET_AREA then
			return weaponPreview.STATE_SECOND_TARGET_AREA
		elseif phase == damageModifierLib.PHASE_FINAL_EFFECT then
			return weaponPreview.STATE_FINAL_EFFECT
		elseif phase == damageModifierLib.PHASE_QUEUED_FINAL_EFFECT then
			return weaponPreview.STATE_QUEUED_FINAL_EFFECT
		end

		-- Phases are numeric and already aligned with STATE_*; pass through
		if type(phase) == "number" then
			return phase
		end

		LOG("[PlusHelper] Warning: Unknown phase: " .. tostring(phase))
		return weaponPreview.STATE_NONE
	end

	function PlusHelper.getWeaponPreviewGroupId(phase)
		local state = PlusHelper.convertPhase(phase)
		local weaponPreview = WeaponPreview
		if state == weaponPreview.STATE_QUEUED_SKILL
				or state == weaponPreview.STATE_QUEUED_FINAL_EFFECT then
			return PlusHelper.QUEUED_GROUP_ID
		end
		return PlusHelper.GROUP_ID
	end

	function PlusHelper.isQueuedWeaponPreview(phase)
		local state = PlusHelper.convertPhase(phase)
		local weaponPreview = WeaponPreview
		return state == weaponPreview.STATE_QUEUED_SKILL
				or state == weaponPreview.STATE_QUEUED_FINAL_EFFECT
	end

	function PlusHelper.addWeaponPreviewIcon(phase, loc, animKey, description, alwaysShow)
		WeaponPreview:AddAnimation(loc, animKey, nil,
				PlusHelper.getWeaponPreviewGroupId(phase), description, alwaysShow == true)
	end

	function PlusHelper.addWeaponPreviewIconForMod(phase, loc, animKey, description, alwaysShowQueued)
		local alwaysShow = PlusHelper.isQueuedWeaponPreview(phase) and alwaysShowQueued
		PlusHelper.addWeaponPreviewIcon(phase, loc, animKey, description, alwaysShow)
	end

	function PlusHelper.readAlwaysShowQueuedPreviewIcons(modId, defaultEnabled)
		local enabled = defaultEnabled == true
		sdlext.config("modcontent.lua", function(obj)
			if obj.modOptions and obj.modOptions[modId] then
				local option = obj.modOptions[modId].options.alwaysShowQueuedPreviewIcons
				if option then
					enabled = option.enabled == true
				end
			end
		end)
		return enabled
	end

	function PlusHelper.registerVanillaSkillGroups()
		if not cplus_plus_ex or PlusHelper.vanillaSkillGroupsRegistered then
			return
		end
		PlusHelper.vanillaSkillGroupsRegistered = true

		local groups = PlusHelper.GROUPS
		cplus_plus_ex:registerSkillToGroup("Grid", groups.ADD_GRID_DEF)
		cplus_plus_ex:registerSkillToGroup("Reactor", groups.ADD_REACTOR)
		cplus_plus_ex:registerSkillToGroup("Opener", groups.BOOST)
		cplus_plus_ex:registerSkillToGroup("Closer", groups.BOOST)
		cplus_plus_ex:registerSkillToGroup("Thick", groups.STATUS_BASED)
		cplus_plus_ex:registerSkillToGroup("Invulnerable", groups.REVIVE)
	end

	function PlusHelper.registerIconList(iconList)
		if not iconList then
			return
		end
		for _, iconData in pairs(iconList) do
			if iconData.key and iconData.img and not ANIMS[iconData.key] then
				ANIMS[iconData.key] = ANIMS.Animation:new{
					Image = iconData.img,
					NumFrames = 1,
					Time = 1,
					Loop = true,
				}
			end
		end
	end

	function PlusHelper:registerGroups()
		if not WeaponPreview then
			return
		end
		WeaponPreview:RegisterGroup(self.GROUP_ID, self.GROUP_OFFSET)
		WeaponPreview:RegisterGroup(self.QUEUED_GROUP_ID, self.QUEUED_GROUP_OFFSET)
	end

	function PlusHelper:finalizeInit()
		if not WeaponPreview then
			LOG("[PlusHelper] WeaponPreview unavailable during finalizeInit")
		end
		if not DamageModifierLib then
			LOG("[PlusHelper] DamageModifierLib unavailable during finalizeInit")
		end

		if self.loadEventsSubscribed then
			return
		end
		self.loadEventsSubscribed = true

		modApi.events.onModsLoaded:subscribe(function()
			PlusHelper:finalizeLoad()
		end)
	end

	function PlusHelper:finalizeLoad()
		PlusHelper.registerVanillaSkillGroups()
		self:registerGroups()
	end
else
	LOG("PlusHelper: Skipping version " .. VERSION .. " (already have "
			.. PlusHelper.version .. ")")
end

local function onModsInitialized()
	if VERSION < PlusHelper.version then
		return
	end

	if PlusHelper.initialized then
		return
	end

	PlusHelper:finalizeInit()
	PlusHelper.initialized = true
end

modApi:addModsInitializedHook(onModsInitialized)

return PlusHelper
